*** Settings ***

Documentation  Operational checks for fans.

# Test Parameters:
# OPENBMC_HOST       The BMC host name or IP address.
# OPENBMC_USERNAME   The userID to login to the BMC as.
# OPENBMC_PASSWORD   The password for OPENBMC_USERNAME.
#
# Approximate run time:   18 minutes.

Resource        ../syslib/utils_os.robot
Resource        ../lib/logging_utils.robot
Resource        ../lib/utils.robot
Resource        ../lib/fan_utils.robot
Library         ../syslib/utils_keywords.py
Library         OperatingSystem

Suite Setup     Suite Setup Execution
Test Teardown   Test Teardown Execution


*** Variables ***

# Fan state values.
${fan_functional}      ${1}
${fan_nonfunctional}   ${0}

# Criteria for a fan to be considered to be at maximum speed.
${max_speed}=  ${10400}


*** Test Cases ***

Check Number Of Fans With Power On
    [Documentation]  Verify system has the minimum number of fans.
    [Tags]  Check_Number_Of_Fans_With_Power_On

    # Determine if system is water cooled.
    ${water_coooled}=  Is Water Cooled

    Verify Minimum Number Of Fans With Cooling Type  ${number_of_fans}
    ...  ${water_coooled}


Check Number Of Fan Monitors With Power On
    [Documentation]  Verify monitors are present when power on.
    [Tags]  Check_Number_Of_Fan_Monitors_With_Power_On

    Verify Fan Monitors With State  On


Check Fan Speed
    [Documentation]  Verify fans are running at or near target speed.
    [Tags]  Check_Speed_Of_Fans

    # Set the speed tolerance criteria.
    # A tolerance value of .15 means that the fan's speed should be
    # within 15% of its set target speed.   Fans may be accelerating
    # or decelerating to meet a new target, so allow .10 extra.
    ${tolerance}=  Set Variable  .25
    Rpvars  tolerance

    # Compare the fan's speed with its target speed.
    :FOR  ${fan_name}  IN  @{fan_names}
    \  ${target_speed}  ${fan_speed}=  Get Fan Target And Speed  ${fan_name}
    \  Rpvars  fan_name  target_speed  fan_speed
    \  # Calculate tolerance, which is a % of the target speed.
    \  ${tolerance_value}=  Evaluate  ${tolerance}*${target_speed}
    \  # Calculate upper and lower speed limits.
    \  ${max_limit}=  Evaluate   ${target_speed}+${tolerance_value}
    \  ${min_limit}=  Evaluate   ${target_speed}-${tolerance_value}
    \  Run Keyword If
    ...  ${fan_speed} < ${min_limit} or ${fan_speed} > ${max_limit}
    ...  Fail  msg=${fan_name} speed of ${fan_speed} is out of range.


Check Fan Manual Control
    [Documentation]  Check direct control of fans.
    [Tags]  Fan_Manual_Speed_Test

    # Test case overview:
    # Turn off BMC's fan control daemon, then test to confirm
    # that fans can be controlled manually.
    # The app that takes data from sysfs and updates dbus is named hwmon.
    # Verify hwmon functionality by comparing with what's on dbus
    # (/xyz/openbmc_project/sensors/fan_tach/fan0_0, fan0_1, etc.)
    # with what's in the BMC's file system at
    # /sys/class/hwmon/hwmon9/fan*_input.

    # The maximum target speed that can be set.
    ${max_fan_target_setting}=  Set Variable  ${10500}

    # Speed criteria for passing, which is 85% of max_fan_target_setting.
    ${min_speed}=  Set Variable  ${8925}

    # Time allowed for the fan daemon to take control and return
    # fans to normal speed.
    ${minutes_to_stabilize}=  Set Variable  4

    # Login to BMC and disable the fan deamon. Disabling the daemon sets
    # manual mode.
    Open Connection And Log In
    Set Fan Daemon State  stop

    # For each fan, set a new target speed and wait for the fan to
    # accelerate.  Then check that the fan is running near that
    # target speed.
    :FOR  ${fan_name}  IN  @{fan_names}
    \  Set Fan Target Speed  ${fan_name}  ${max_fan_target_setting}
    \  Run Key U  Sleep \ 60s
    \  ${target_speed}  ${cw_speed}  ${ccw_speed}=
    ...  Get Target And Blade Speeds  ${fan_name}
    \  Rpvars  fan_name  target_speed  cw_speed  ccw_speed
    \  Run Keyword If
    ...  ${cw_speed} < ${min_speed} or ${ccw_speed} < ${min_speed}
    ...  Fail  msg=${fan_name} failed manual speed test.

    # Check the fan speeds in the BMC file system.

    # Get the location of the fan hwmon.
    ${controller_path}  ${stderr}  ${rc}=  BMC Execute Command
    ...  grep -ir max31785a /sys/class/hwmon/hwmon* | grep name
    # E.g., controller_path=/sys/class/hwmon/hwmon10/name:max31785a.

    ${hwmon_path}  ${file_name}=  Split Path  ${controller_path}
    # E.g.,  /sys/class/hwmon/hwmon10  or  /sys/class/hwmon/hwmon9.

    Rpvars  controller_path  hwmon_path

    # Run the BMC command which gets fan speeds from the file system.
    ${cmd}=  Catenate  cat ${hwmon_path}/fan*_input
    ${stdout}  ${stderr}  ${rc}=
    ...  BMC Execute Command  ${cmd}

    Rpvars  fan_speeds_from_BMC_file_system

    # Convert output to integer values.
    ${speeds}=  Evaluate  map(int, $stdout.split(${\n}))
    Rpvars  speeds
    # Count the number of speeds > ${min_speed}.
    ${count}=  Set Variable  ${0}
    :FOR  ${speed}  IN  @{speeds}
    \  ${count}=  Run Keyword If  ${speed} > ${min_speed}
    ...  Evaluate  ${count}+1  ELSE  Set Variable  ${count}
    # Because each fan has two rotating fan blades, the count should be
    # equual to 2*${number_of_fans}.  On water-cooled systems some
    # speeds may be reported by hwmon as 0.  That is expected,
    # and the number_of_fans reported in the system will be less.
    ${fail_test}=  Evaluate  (2*${number_of_fans})-${count}

    # Re-enable the fan daemon
    Set Fan Daemon State  restart

    Run Keyword If  ${fail_test}  Fail
    ...  msg=hwmon did not properly report fan speeds.

    # Wait for the daemon to take control and gracefully set fan speeds
    # back to normal.
    ${msg}=  Catenate  Waiting ${minutes_to_stabilize} minutes
    ...  for fan daemon to stabilize fans.
    Rprint Timen  ${msg}
    Run Key U  Sleep \ ${minutes_to_stabilize}m


Verify Fan Speed Increase
    [Documentation]  Verify that the speed of working fans increase when 
    ...  one fan is disabled.
    [Tags]  Verify_Fan_Speed_Increase
    #  A non-functional fan should cause an error log and
    #  an enclosure LED will light.  The other fans should speed up.

    # Allow system_response_time before checking if there was a
    # response by the system to an applied fault.
    ${system_response_time}=  Set Variable  60s

    # Choose a fan to test with, e.g., fan0.
    ${test_fan_name}=  Get From List  ${fan_names}  0

    ${initial_speed}=  Get Target Speed Of Fans
    Rpvars  test_fan_name  initial_speed

    # If initial speed is not already at maximum, set expect_increase.
    # This flag is used later to determine if speed checking is
    # to be done or not.
    ${expect_increase}=  Run Keyword If
    ...  ${initial_speed} < ${max_speed}
    ...  Set Variable  1  ELSE  Set Variable  0

    Set Fan State  ${test_fan_name}  ${fan_nonfunctional}

    # Wait for error to be asserted.

    :FOR  ${n}  IN RANGE  30
    \  ${front_fault}=  Get System LED State  front_fault
    \  ${rear_fault}=  Get System LED State  rear_fault
    \  Run Key U  Sleep \ 1s
    \  Exit For Loop If  '${front_fault}' == 'On' and '${rear_fault}' == 'On'

    Verify System Error Indication Due To Fans

    # Verify the error log is for test_fan_name.
    ${elog_entries}=  Get Logging Entry List
    :FOR  ${elog_entry}  IN  @{elog_entries}
    \  ${elog_entry_callout}=  Set Variable  ${elog_entry}/callout
    \  ${endpoint}=  Read Attribute  ${elog_entry_callout}  endpoints
    \  ${endpoint_name}=  Get From List  ${endpoint}  0
    \  Should Contain  ${endpoint_name}  ${test_fan_name}
    ...  msg=Error log present but not for ${test_fan_name}.

    Run Key U  Sleep \ ${system_response_time}

    # A heavily loaded system may have powered-off.
    ${host_state}=  Get Host State
    Rpvars  host_state
    Run Keyword If  'Running' != '${host_state}'  Pass Execution
    ...  msg=System shutdown so skipping remainder of test.

    ${new_fan_speed}=  Get Target Speed Of Fans
    Rpvars  expect_increase  initial_speed  new_fan_speed

    # Fail if current fan speed did not increase past the initial
    # speed, but do this check only if not at maximum speed to begin with.
    Run Keyword If
    ...  ${expect_increase} == 1 and ${new_fan_speed} < ${initial_speed}
    ...  Fail  msg=Remaining fans did not increase speed with loss of one fan.


Verify System Shutdown Due To Fans
    [Documentation]  Shut down when not enough fans.
    [Tags]  Verify_System_Shutdown_Due_To_Fans

    ${wait_after_poweroff}=  Set Variable  15s

    # The previous test may have shutdown the system.
    REST Power On  stack_mode=skip

    # Set fans to be non-functional.
    :FOR  ${fan_name}  IN  @{fan_names}
    \  Set Fan State  ${fan_name}  ${fan_nonfunctional}

    # System should notice the non-functional fans and power-off the
    # system.  The Wait For PowerOff keyword will time-out and report
    # an error if power off does not happen within a reasonable time.
    Wait For PowerOff

    Run Key U  Sleep \ ${wait_after_poweroff}

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

    # The @{fan_names} list holds the names of the fans in the system.
    @{fan_names}  Create List
    ${fan_names}=  Get Fan Names  ${fan_names}
    Set Suite Variable  ${fan_names}  children=true

    ${number_of_fans}=  Get Length  ${fan_names}
    Set Suite Variable  ${number_of_fans}  children=true

    Reset Fans
    Run Key U  Sleep \ 15s
    Delete Error Logs
    Set System LED State  front_fault  Off
    Set System LED State  rear_fault  Off


Test Teardown Execution
    [Documentation]  Do the post-test teardown.

    FFDC On Test Case Fail
    Reset Fans
    Run Key U  Sleep \ 15s
    Delete Error Logs
    Set System LED State  front_fault  Off
    Set System LED State  rear_fault  Off
