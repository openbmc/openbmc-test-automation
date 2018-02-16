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
Suite Teardown   Suite Teardown Execution


*** Variables ***

${stack_mode}        skip

# Any fan at this speed or greater will be considered to be at maximum RPM.
${max_rpm_designation}     10400

# The fan speed monitoring daemon takes less than one second to
# notice a fan failure.   Allow daemon_dwell_time before checking
# if there was a measurable response to the daemon, such as an increase
# in RPM of the other fans.
${daemon_dwell_time}  30s

# The @{fans} list holds the names of fans in the system.
@{fans}

# Fan state values.
${fan_functional}      ${1}
${fan_nonfunctional}   ${0}


*** Test Cases ***


Check Number Of Fans With Power On
    [Documentation]  Verify system has the minimum number of fans.
    [Tags]  Check_Number_Of_Fans_With_Power_On

    ${power_state}=  Get Chassis Power State
    Run Keyword If  '${power_state}' != 'On'  Fatal Error
    ...  msg=System should be on to run these tests.

    # Determine if system is water cooled.
    ${water_coooled}=  Is Water Cooled

    Verify Minimum Number Of Fans With Cooling Type  ${water_coooled}


Check Number Of Fan Monitors With Power On
    [Documentation]  Verify monitors are present when power on.
    [Tags]  Check_Number_Of_Fan_Monitors_With_Power_On

    Verify Fan Monitors With State  On


Verify Fan RPM Increase
    [Documentation]  RPM should increase with non-functional fan.
    [Tags]  Verify_Fan_RPM_Increase
    #  A non-functional fan should cause an error log and
    #  an enclosure LED will light.  The other fans should speed up.

    Create List Of Fans

    # Choose a fan to test with, e.g., fan1.
    ${test_fan}=  Get From List  ${fans}  1
    Rpvars  test_fan

    ${initial_speed}=  Get Target Speed Of Fans
    Rpvars  initial_speed

    # If initial speed is not already at maximum, set check_increase.
    # This flag is used later to determine if speed checking is
    # to be done or not.
    ${check_increase}=  Run Keyword If
    ...  ${initial_speed} < ${max_rpm_designation}
    ...  Set Variable  1  ELSE  Set Variable  0
    Rpvars  check_increase

    Set Fan State  ${test_fan}  ${fan_nonfunctional}
    Sleep  ${daemon_dwell_time}

    Verify System Error Indication Due To Fans

    # Verify the error log is for test_fan.
    ${elog_entries}=  Get Logging Entry List
    :FOR  ${elog_entry}  IN  @{elog_entries}
    \  ${elog_entry_callout}=  Set Variable  ${elog_entry}/callout
    \  ${endpoint}=  Read Attribute  ${elog_entry_callout}  endpoints
    \  ${endpoint_name}=  Get From List  ${endpoint}  0
    \  Should Contain  ${endpoint_name}  ${test_fan}
    ...  msg=Error log present but not for ${test_fan}.

    ${speed_fan_loss}=  Get Target Speed Of Fans
    Rpvars  check_increase  initial_speed  speed_fan_loss

    # Fail if current fan speed did not increase past the initial
    # speed, but do this check only if not at maximum speed to begin with.
    Run Keyword If
    ...  ${check_increase} == 1 and ${speed_fan_loss} < ${initial_speed}
    ...  Fail  msg=Remaining fans did not increase speed with loss of one fan.

    # Recover the fan.
    Set Fan State  ${test_fan}  ${fan_functional}
    Sleep  ${daemon_dwell_time}

    Delete Error Logs
    Sleep  2s

    # Enclosure LEDs should go off immediately after deleting the error logs.
    Verify Front And Rear LED State  Off

    ${fan_speed_restored}=  Get Target Speed Of Fans
    Rpvars  check_increase   speed_fan_loss  fan_speed_restored

    # Fan speed should lower because the fan is now functional again.
    Run Keyword If
    ...  ${check_increase} == 1 and ${speed_fan_loss} < ${fan_speed_restored}
    ...  Fail  msg=Fans did not recover speed with all fans functional again.


Verify System Shutdown Due To Fans
    [Documentation]  Shut down when not enough fans.
    [Tags]  Verify_System_Shutdown_Due_To_Fans

    # Set fans to be non-functional.
    :FOR  ${fan}  IN  @{fans}
    \  Set Fan State  ${fan}  ${fan_nonfunctional}

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


Create List Of Fans
    [Documentation]  Create list of fans in @fans.  Make the list a suite
    ...  variable.

    @{fans}  Create List
    # Populate the list with the names of fans in the system.
    ${fans}=  Append Fan Names To List  ${fans}
    Set Suite Variable  ${fans}  children=true


Reset Fans
    [Documentation]  Set the fans to functional state.
    # Set state of fans to functional by writing 1 to the Functional
    # attribute of each fan in the @{fans} list.   If @{fans}
    # is empty nothing is done.

    # Description of Argument(s):
    # fans    Suite Variable which is a list containing the
    #         names of the fans (e.g., fan0 fan2 fan3).

    :FOR  ${fan}  IN  @{fans}
    \  Set Fan State  ${fan}  ${fan_functional}


Suite Setup Execution
    [Documentation]  Do the pre-test setup.

    REST Power On   ${stack_mode}
    Delete All Error Logs
    Set System LED State   front_fault  Off
    Set System LED State   rear_fault  Off


Test Teardown Execution
    [Documentation]  Do the post-test teardown.

    FFDC On Test Case Fail
    Reset Fans
    Delete Error Logs
    Set System LED State   front_fault  Off
    Set System LED State   rear_fault  Off


Suite Teardown Execution
    REST Power Off  ${stack_mode}
    Close All Connections
