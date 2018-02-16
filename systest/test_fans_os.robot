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
# Approximate run time:   8 minutes.

Resource        ../syslib/utils_os.robot
Resource        ../lib/logging_utils.robot
Resource        ../lib/utils.robot
Resource        ../lib/fan_utils.robot

Suite Setup      Suite Setup Execution
Test Teardown    Test Teardown Execution


*** Variables ***

# The fan speed-monitoring daemon takes less than one second to
# notice a fan failure.   Allow system_response_time before checking
# if there was a measurable response to the daemon, such as an increase
# in RPMs of the other fans.
${system_response_time}  30s

# The @{fan_names} list holds the names of the fans in the system.
@{fan_names}

# Fan state values.
${fan_functional}      ${1}
${fan_nonfunctional}   ${0}


*** Test Cases ***


Check Number Of Fans With Power On
    [Documentation]  Verify system has the minimum number of fans.
    [Tags]  Check_Number_Of_Fans_With_Power_On

    @{fan_names}  Create List
    # Populate the list with the names of the fans in the system.
    ${fan_names}=  Get Fan Names  ${fan_names}
    Set Suite Variable  ${fan_names}  children=true

    ${number_of_fans}=  Get Length  ${fan_names}

    # Determine if system is water cooled.
    ${water_coooled}=  Is Water Cooled

    Verify Minimum Number Of Fans With Cooling Type  ${number_of_fans}
    ...  ${water_coooled}


Check Number Of Fan Monitors With Power On
    [Documentation]  Verify monitors are present when power on.
    [Tags]  Check_Number_Of_Fan_Monitors_With_Power_On

    Verify Fan Monitors With State  On


Verify Fan RPM Increase
    [Documentation]  Verify that RPMs of working fans increase when one fan
    ...  is disabled.
    [Tags]  Verify_Fan_RPM_Increase
    #  A non-functional fan should cause an error log and
    #  an enclosure LED will light.  The other fans should speed up.

    # Any fan at this speed or greater will be considered to be at maximum RPM.
    ${max_fan_rpm}=  Set Variable  10400

    # Choose a fan to test with, e.g., fan1.
    ${test_fan_name}=  Get From List  ${fan_names}  1
    Rpvars  test_fan_name

    ${initial_speed}=  Get Target Speed Of Fans
    Rpvars  initial_speed

    # If initial speed is not already at maximum, set expect_increase.
    # This flag is used later to determine if speed checking is
    # to be done or not.
    ${expect_increase}=  Run Keyword If
    ...  ${initial_speed} < ${max_fan_rpm}
    ...  Set Variable  1  ELSE  Set Variable  0

    Set Fan State  ${test_fan_name}  ${fan_nonfunctional}
    Sleep  ${system_response_time}

    Verify System Error Indication Due To Fans

    # Verify the error log is for test_fan_name.
    ${elog_entries}=  Get Logging Entry List
    :FOR  ${elog_entry}  IN  @{elog_entries}
    \  ${elog_entry_callout}=  Set Variable  ${elog_entry}/callout
    \  ${endpoint}=  Read Attribute  ${elog_entry_callout}  endpoints
    \  ${endpoint_name}=  Get From List  ${endpoint}  0
    \  Should Contain  ${endpoint_name}  ${test_fan_name}
    ...  msg=Error log present but not for ${test_fan_name}.

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
    Sleep  2s

    # Enclosure LEDs should go off immediately after deleting the error logs.
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
    Delete All Error Logs
    Set System LED State  front_fault  Off
    Set System LED State  rear_fault  Off


Test Teardown Execution
    [Documentation]  Do the post-test teardown.

    FFDC On Test Case Fail
    Reset Fans
    Delete Error Logs
    Set System LED State  front_fault  Off
    Set System LED State  rear_fault  Off
