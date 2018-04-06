*** Settings ***

Documentation  Operational checks for fans.

# Test Parameters:
# OPENBMC_HOST       The BMC host name or IP address.
# OPENBMC_USERNAME   The userID to login to the BMC as.
# OPENBMC_PASSWORD   The password for OPENBMC_USERNAME.
# OS_HOST            The OS host name or IP Address.
# OS_USERNAME        The OS login userid (usually root).
# OS_PASSWORD        The password for the OS login.
#
# Approximate run time:   18 minutes.

Resource        ../syslib/utils_os.robot
Resource        ../lib/logging_utils.robot
Resource        ../lib/utils.robot
Resource        ../lib/fan_utils.robot
Library         ../syslib/utils_keywords.py

Suite Setup      Suite Setup Execution
Test Teardown    Test Teardown Execution


*** Variables ***

# Allow system_response_time before checking if there was a
# response by the system to an applied fault.
${system_response_time}  30s

# Fan state values.
${fan_functional}      ${1}
${fan_nonfunctional}   ${0}

# Criteria for a fan to be considered to be at maximum RPM.
${max_rpm_criteria}=  10400


*** Test Cases ***


Check Number Of Fans With Power On
    [Documentation]  Verify system has the minimum number of fans.
    [Tags]  Check_Number_Of_Fans_With_Power_On

    ${number_of_fans}=  Get Length  ${fan_names}

    # Determine if system is water cooled.
    ${water_coooled}=  Is Water Cooled

    Verify Minimum Number Of Fans With Cooling Type  ${number_of_fans}
    ...  ${water_coooled}


Check Number Of Fan Monitors With Power On
    [Documentation]  Verify monitors are present when power on.
    [Tags]  Check_Number_Of_Fan_Monitors_With_Power_On

    Verify Fan Monitors With State  On


Check Speed Of Fans
    [Documentation]  Verify fans are running at or near target speed.
    [Tags]  Check_Speed_Of_Fans

    # Set the speed tolerance criteria.
    # A tolerance value of .15 means that the fan's speed should be
    # within 15% of its set target speed.   Fans may be accelerating
    # or decelerating to meet a new target, so allow .10 extra.
    ${tolerance}=  Set Variable  .25
    Rpvars  tolerance

    # Compare the fan's speed with its target RPM.
    :FOR  ${fan_name}  IN  @{fan_names}
    \  ${target_rpm}  ${fan_rpm}=  Get Fan Target And Speed  ${fan_name}
    \  Rpvars  fan_name  target_rpm  fan_rpm
    \  # Calculate tolerance, which is a % of the target speed.
    \  ${tolerance_value}=  Evaluate  ${tolerance}*${target_rpm}
    \  # Calculate upper and lower RPM limits.
    \  ${max_limit}=  Evaluate   ${target_rpm}+${tolerance_value}
    \  ${min_limit}=  Evaluate   ${target_rpm}-${tolerance_value}
    \  Run Keyword If
    ...  ${fan_rpm} < ${min_limit} or ${fan_rpm} > ${max_limit}
    ...  Fail  msg=${fan_name} speed of ${fan_rpm} RPM is out of range.


Fan Manual Speed Test
    [Documentation]  Check direct control of fans.
    [Tags]  Fan_Manual_Speed_Test

    # Test case overview:
    # Turn off BMC's fan control daemon, then test to confirm
    # that fans can be controlled manually.
    # Then verify hwmon functionality by comparing with what's on dbus
    # (/xyz/openbmc_project/sensors/fan_tach/fan0_0, etc..)
    # with what's in the BMC's file system (fan1_input, etc..).
    # BTW, hwmon is the app that takes data from sysfs
    # and updates dbus.

    # The target speed used in this test case.   It's the
    # maximum value that can be set.
    ${max_fan_target_setting}=  Set Variable  10500

    # Passing RPM criteria is 85% of max_fan_target_setting.
    ${low_rpm_limit}=  Set Variable  8925

    # Login to BMC and disable fan deamon. Disabling the daemon sets
    # manual mode.
    Open Connection And Log In
    Set Fan Daemon State  stop

    # For each fan, set a new target speed and wait for the fan to
    # accelerate.  Then check that the fan is running near that
    # target speed.
    :FOR  ${fan_name}  IN  @{fan_names}
    \  Set Target Speed Of Fan  ${fan_name}  ${max_fan_target_setting}
    \  Sleep  60s
    \  ${target_rpm}  ${cw_rpm}  ${ccw_rpm}=
    ...  Get Target And Blade Speeds  ${fan_name}
    \  Rpvars  fan_name  target_rpm  cw_rpm  ccw_rpm
    \  Run Keyword If
    ...  ${cw_rpm} < ${low_rpm_limit} or ${ccw_rpm} < ${low_rpm_limit}
    ...  Fail  msg=${fan_name} failed manual speed test.

    # Check the fan speeds in the BMC file system.

    # Get the location of the fan hwmon.
    ${controller_path}=  Execute Command On BMC
    ...  grep -ir max31785a /sys/class/hwmon/hwmon* | grep name
    # E.g., controller_path=/sys/class/hwmon/hwmon10/name:max31785a.

    ${hwmon_path}=  Get_Path_Dirname  ${controller_path}
    # E.g.,  /sys/class/hwmon/hwmon10  or  /sys/class/hwmon/hwmon9.

    Rpvars  controller_path  hwmon_path

    # Run the BMC command which gets the fan RPMs from the system file system.
    ${cmd}=  Catenate  cat ${hwmon_path}/fan*_input
    ${fan_speeds_from_BMC_file_system}=  Execute Command On BMC  ${cmd}

    Rpvars  fan_speeds_from_BMC_file_system

    ${rc}=  Are_Sysfs_Fan_Speeds_Correct
    ...  ${fan_names}  ${fan_speeds_from_BMC_file_system}  ${low_rpm_limit}
    Run Keyword If  ${rc} == False
    ...  Fail  msg=hwmon daemon did not properly report fan speeds.

    # Re-enable the fan daemon
    Set Fan Daemon State  restart

    # Wait 6 minutes for the daemon to take control and gracefully
    # throttle fan speeds to normal.
    Rprint Timen  Waiting 6 minutes for fan daemon to stabilize fans.
    Sleep  6m


Verify Fan RPM Increase
    [Documentation]  Verify that RPMs of working fans increase when one fan
    ...  is disabled.
    [Tags]  Verify_Fan_RPM_Increase
    #  A non-functional fan should cause an error log and
    #  an enclosure LED will light.  The other fans should speed up.

    # Choose a fan to test with, e.g., fan0.
    ${test_fan_name}=  Get From List  ${fan_names}  0

    ${initial_speed}=  Get Target Speed Of Fans
    Rpvars  test_fan_name  initial_speed

    # If initial speed is not already at maximum, set expect_increase.
    # This flag is used later to determine if speed checking is
    # to be done or not.
    ${expect_increase}=  Run Keyword If
    ...  ${initial_speed} < ${max_rpm_criteria}
    ...  Set Variable  1  ELSE  Set Variable  0

    Set Fan State  ${test_fan_name}  ${fan_nonfunctional}

    # Wait for error to be asserted.
    :FOR  ${n}  IN RANGE  30
    \  ${front_fault}=  Get System LED State  front_fault
    \  ${rear_fault}=  Get System LED State  rear_fault
    \  Sleep  1s
    \  Exit For Loop If  '${front_fault}' == 'On' and '${rear_fault}' == 'On'

    # Fail with msg= if enclosure LEDs are not on.
    Verify System Error Indication Due To Fans

    # Verify the error log is for test_fan_name.
    ${elog_entries}=  Get Logging Entry List
    :FOR  ${elog_entry}  IN  @{elog_entries}
    \  ${elog_entry_callout}=  Set Variable  ${elog_entry}/callout
    \  ${endpoint}=  Read Attribute  ${elog_entry_callout}  endpoints
    \  ${endpoint_name}=  Get From List  ${endpoint}  0
    \  Should Contain  ${endpoint_name}  ${test_fan_name}
    ...  msg=Error log present but not for ${test_fan_name}.

    Sleep  ${system_response_time}

    ${new_fan_speed}=  Get Target Speed Of Fans
    Rpvars  expect_increase  initial_speed  new_fan_speed

    # Fail if current fan speed did not increase past the initial
    # speed, but do this check only if not at maximum speed to begin with.
    Run Keyword If
    ...  ${expect_increase} == 1 and ${new_fan_speed} < ${initial_speed}
    ...  Fail  msg=Remaining fans did not increase speed with loss of one fan.

    # Recover the fan.
    Set Fan State  ${test_fan_name}  ${fan_functional}
    Sleep  ${system_response_time}

    Delete Error Logs

    # Wait for error to be removed..
    :FOR  ${n}  IN RANGE  10
    \  ${front_fault}=  Get System LED State  front_fault
    \  ${rear_fault}=  Get System LED State  rear_fault
    \  Sleep  1s
    \  Exit For Loop If  '${front_fault}' == 'Off' and '${rear_fault}' == 'Off'

    # Fail with msg= if enclosure LEDs are not off.
    Verify Front And Rear LED State  Off

    ${restored_fan_speed}=  Get Target Speed Of Fans
    Rpvars  new_fan_speed  restored_fan_speed

    # Fan speed should lower because the fan is now functional again.
    Run Keyword If
    ...  ${expect_increase} == 1 and ${new_fan_speed} < ${restored_fan_speed}
    ...  Fail  msg=Fans did not recover speed with all fans functional again.


Verify System Shutdown Due To Fans
    [Documentation]  Shut down when not enough fans.
    [Tags]  Verify_System_Shutdown_Due_To_Fans

    # Set fans to be non-functional.
    :FOR  ${fan_name}  IN  @{fan_names}
    \  Set Fan State  ${fan_name}  ${fan_nonfunctional}

    # System should notice the non-functional fans and power-off the
    # system.  The Wait For PowerOff keyword will time-out and report
    # an error if power off does not happen within a reasonable time.
    Wait For PowerOff

    Sleep  ${system_response_time}

    Verify System Error Indication Due To Fans

    # Verify there is an error log because of the shutdown.
    ${expect}=  Catenate
    ...  xyz.openbmc_project.State.Shutdown.Inventory.Error.Fan
    ${elog_entries}=  Get Logging Entry List
    :FOR  ${elog_entry}  IN  @{elog_entries}
    \  ${elog_message}=  Read Attribute  ${elog_entry}  Message
    \  ${found}=  Set Variable  1
    \  Run Keyword If  '${elog_message}' == '${expect}'  Exit For Loop
    \  ${found}=  Set Variable  0
    Run Keyword If  not ${found}  Fail
    ...  msg=No error log for event Shutdown.Inventory.Error.Fan.


*** Keywords ***


Reset Fans
    [Documentation]  Set the fans to functional state.
    # Set state of fans to functional by writing 1 to the Functional
    # attribute of each fan in the @{fan_names} list.  If @{fan_names}
    # is empty nothing is done.

    # Description of Argument(s):
    # fans    Suite Variable which is a list containing the
    #         names of the fans (e.g., fan0 fan2 fan3).

    :FOR  ${fan_name}  IN  @{fan_names}
    \  Set Fan State  ${fan_name}  ${fan_functional}


Suite Setup Execution
    [Documentation]  Do the pre-test setup.

    REST Power On  stack_mode=skip

    Delete Error Logs
    Set System LED State  front_fault  Off
    Set System LED State  rear_fault  Off

    # The @{fan_names} list holds the names of the fans in the system.
    @{fan_names}  Create List
    ${fan_names}=  Get Fan Names  ${fan_names}
    Set Suite Variable  ${fan_names}  children=true

    Reset Fans


Test Teardown Execution
    [Documentation]  Do the post-test teardown.

    FFDC On Test Case Fail
    Reset Fans
    Delete Error Logs
    Set System LED State  front_fault  Off
    Set System LED State  rear_fault  Off
