*** Settings ***

Documentation  Fan Operational Checks. These tests require a booted OS.

# Test Parameters:
# OPENBMC_HOST   The BMC host name or IP address.
# OS_HOST        The OS host name or IP Address.
# OS_USERNAME    The OS login userid (usually root).
# OS_PASSWORD    The password for the OS login.
#
# Example:
#  python -m robot -v  OPENBMC_HOST:$BMC -v OS_HOST:$OS -v OS_USERNAME:root
#   -v OS_PASSWORD:abcd1234  systest/test_fans.robot
#
# Approximate run time:  10 minutes.

Resource        ../syslib/utils_os.robot
Resource        ../lib/logging_utils.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution
Suite Teardown   Suite Teardown Execution

*** Variables ***

${stack_mode}        skip
#${HTTP_OK}          200
#${HTTP_NOT_FOUND}   404

# This list holds the names of active fans, e.g., fan0  fan2  fan3
@{fans}

# Any fan at this speed or greater is considered to be at maximum RPM.
${max_rpm_designation}     10400

# The fan speed monitoring daemon usually takes less than 1 second to
# notice a fan failure.   Allow daemon_dwell_time before checking
# if the system did something in response, like changing the fan RPMs.
${daemon_dwell_time}  30s


*** Test Cases ***

Verify Minimum Fan Count At Power Off
    [Documentation]  Verify minimum number of fans with system power off.
    [Tags]  Verify_Minimum_Fan_Count_At_Power_Off

    REST Power Off  ${stack_mode}

    ${fans}=  Check Fan Count  ${fans}
    Set Suite Variable  ${fans}  children=true

    # The number of fans found with power off.
    ${num_fans_power_off}=  Get Length  ${fans}
    Set Suite Variable  ${num_fans_power_off}  children=true


Verify Fan Monitors At Power Off
    [Documentation]  Verify monitors are not present at power off.
    [Tags]  Verify_Fan_Monitors_When_Power_Off

    REST Power Off  ${stack_mode}

    # Open connection to BMC and issue systemctl command to get monitor list.
    &{bmc_connection_args}=  Create Dictionary  alias=bmc_connection
    Open Connection And Log In  &{bmc_connection_args}
    ${cmd_output}=  Execute Command On BMC
    ...  systemctl list-units | grep phosphor-fan

    # There should be no 'phosphor-fan' entries fom systemctl.
    ${output_length}=  Get Length  ${cmd_output}
    Run Keyword if  ${output_length} != 0  Fail
    ...  msg=Fan APIs phosphor-fan present with power off.


Verify Minimum Fan Count At Power On
    [Documentation]  Verify minimum number of fans with system power on.
    [Tags]  Verify_Minimum_Fan_Count_At_Power_On

    REST Power On   ${stack_mode}
    @{fans_power_on}=  Create List
    ${fans_power_on}=  Check Fan Count  ${fans_power_on}

    # The number of working fans found.
    ${num_fans_power_on}=  Get Length  ${fans_power_on}

    Run Keyword If  ${num_fans_power_off} != ${num_fans_power_on}  Fail
    ...  msg=The number of fans differs between power-on and power-off.


Verify Fan Monitors At Power On
    [Documentation]  Verify monitors are present at power on.
    [Tags]  Verify_Fan_Monitors_When_Power_On

    # Power on the system.
    REST Power On  ${stack_mode}

    # Open connection to BMC and issue systemctl command to get monitor list.
    &{bmc_connection_args}=  Create Dictionary  alias=bmc_connection
    Open Connection And Log In  &{bmc_connection_args}
    ${cmd_output}=  Execute Command On BMC
    ...  systemctl list-units | grep phosphor-fan

    # Systemctl should report fan control, fan presence, and fan monitor.
    Should Contain  ${cmd_output}  phosphor-fan-control
    ...  msg=At power-on, no phosphor-fan-control present.
    Should Contain  ${cmd_output}  phosphor-fan-presence
    ...  msg=At power-on, no phosphor-fan-presence present.
    Should Contain  ${cmd_output}  phosphor-fan-monitor
    ...  msg=At power-on, no phosphor-fan-monitor present.


Verify Fan RPM Increase
    [Documentation]  RPM increase when a fan is non-functional.
    [Tags]  Verify_Fan_RPM_Increase
    #  A non-functional fan should cause an error log and an enclosure LED.
    #  The other fans should speed up.

    REST Power On  stack_mode=skip

    # Pick an arbitray fan to disable.  In this case choose
    # the 2nd fan in the active fan list.
    ${test_fan}=  Get From List  ${fans}  1
    Rpvars  test_fan

    ${initial_target_speed}=  Get Max Target Speed Of Fans
    Rpvars  initial_target_speed
    # If initial target RPM is not already at maximum,
    # set the check_increase flag.
    ${check_increase}=  Run Keyword If
    ...  ${initial_target_speed} < ${max_rpm_designation}
    ...  Set Variable  1  ELSE  Set Variable  0
    Rpvars  check_increase

    # Confirm that enclosure LEDs are intially off.
    ${both_off}=  Are Front And Rear LEDs Off
    Run Keyword If  not ${both_off}  Fail
    ...  msg=Enclosure LEDs are initially on. Cannot continue with this test.

    # Error log should not exist.
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}/list  quiet=${1}
    Run Keyword If  ${resp.status_code} != ${HTTP_NOT_FOUND}  Fail
    ...  msg=Expected no initial error logs when starting fan test.

    # Set a fan to not functional by writing 0 to the Functional attribute.
    ${valueDict}=  Create Dictionary  data=${0}
    Write Attribute
    ...  /xyz/openbmc_project/inventory/system/chassis/motherboard/${test_fan}
    ...  Functional  data=${valueDict}

    # Allow the fan monitor to notice the nonfunctional fan.
    # Wait for system to respond.
    Sleep  ${daemon_dwell_time}

    # Both enclosure LEDs should now be On.
    ${both_off}=  Are Front And Rear LEDs Off
    Run Keyword If  ${both_off}  Fail
    ...  msg=One or both enclosure LEDs are off. Fan fail not detected.

    # Error log should exist.
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}/list  quiet=${1}
    Run Keyword If  ${resp.status_code} != ${HTTP_OK}  Fail
    ...  msg=Expected BMC error log due to fan fail.

    # Verify that the error log is for the fan we chose.
    ${elog_entries}=  Get Logging Entry List
    :FOR  ${individual_error_log}  IN  @{elog_entries}
    \  Rpvars  individual_error_log
    \  ${error_log_callout}=  Set Variable  ${individual_error_log}/callout
    \  ${endpoint}=  Read Attribute  ${error_log_callout}  endpoints
    \  ${endpoint_name}=  Get From List  ${endpoint}  0
    \  Rpvars  endpoint_name
    \  Should Contain  ${endpoint_name}  ${test_fan}
    ...  msg=Error log present during fan test but not for ${test_fan}.

    # Allow other fans to speed up due to the one non-functional fan.
    Sleep  ${daemon_dwell_time}

    ${speed_fan_loss}=  Get Max Target Speed Of Fans
    # Fail if current fan target speed did not increase past the
    # initial target speedr, but do this check only if we were not at maximum
    # speed to begin with.
    Rpvars  check_increase  initial_target_speed  speed_fan_loss
    Run Keyword If
    ...  ${check_increase} == 1 and ${speed_fan_loss} < ${initial_target_speed}
    ...  Fail  msg=Remaining fans did not increase speed with loss of one fan.

    # Re-enable the fan we initially set to non-functional.
    ${valueDict}=  Create Dictionary  data=${1}
    Write Attribute
    ...  /xyz/openbmc_project/inventory/system/chassis/motherboard/${test_fan}
    ...  Functional  data=${valueDict}

    # Allow system fans to respond.
    Sleep  ${daemon_dwell_time}

    Delete Error Logs

    # After deleting error logs, enclosure LEDs should go off.
    Sleep  2s
    ${both_off}=  Are Front And Rear LEDs Off
    Run Keyword If  not ${both_off}  Fail
    ...  msg=Front or rear fault LEDs are on with all fans functional.

    ${speed_fans_restored}=  Get Max Target Speed Of Fans
    # Fail if current fan target speed did not lower.
    Rpvars  check_increase   speed_fan_loss  speed_fans_restored
    Run Keyword If
    ...  ${check_increase} == 1 and ${speed_fan_loss} < ${speed_fans_restored}
    ...  Fail  msg=Fans did not recover speed with all fans functional again.


Verify System Shutdown Due To Fans
    [Documentation]  Shut down when not enough fans.
    [Tags]  Verify_System_Shutdown_Due_To_Fans

    REST Power On  stack_mode=skip

    # Set state of fans to be non-functional by writing 0 to
    # the Functional Attribute.
    ${valueDict}=  Create Dictionary  data=${0}
    :FOR  ${fan}  IN  @{fans}
    \  Write Attribute
    ...  /xyz/openbmc_project/inventory/system/chassis/motherboard/${fan}
    ...  Functional  data=${valueDict}

    # System monitoring should notice the non-functional fan and
    # power off the system.  The Wait For PowerOff keyword will time-out
    # and report an error if power off does not happen within a
    # reasonable time.
    Wait For PowerOff

    # One or both enclosure LEDs should now be on.
    ${both_off}=  Are Front And Rear LEDs Off
    #Log To Console  BOTH OFF = ${both_off}
    Run Keyword If  ${both_off}  Fail
    ...  msg=Front_fault and rear_fault LEDs are not on as expected.

    # Verify that we have an error log for the shutdown.
    ${expect}=  Catenate
    ...  xyz.openbmc_project.State.Shutdown.Inventory.Error.Fan
    ${elog_entries}=  Get Logging Entry List
    :FOR  ${individual_error_log}  IN  @{elog_entries}
    \  ${errlog_message}=  Read Attribute  ${individual_error_log}  Message
    \  ${found}=  Set Variable  1
    \  Run Keyword If  '${errlog_message}' == '${expect}'  Exit For Loop
    \  ${found}=  Set Variable  0
    Run Keyword If  not ${found}  Fail
    ...  msg=No error log for event Shutdown.Inventory.Error.Fan.


*** Keywords ***

Is Fan Present And Functional
    [Documentation]  Return 1 if fan is present and functional, 0 otherwise.
    [Arguments]  ${fan}

    # Description of Argument(s):
    # fan    The name of the fan (i.e., fan0, fan1, fan2, or fan3).

    ${location}=  Catenate
    ...  /xyz/openbmc_project/inventory/system/chassis/motherboard/${fan}

    ${present}=  Read Attribute  ${location}  Present
    ${Functional}=  Read Attribute  ${location}  Functional
    Log To Console  PRESENT=${present}
    Log To Console  FUNCTIONAL=${functional}
    Run Keyword If  ${present} and ${functional}  Return From Keyword  1
    Return From Keyword  0


Is Water Cooled
    [Documentation]  Return 1 if system is water cooled, 0 othersise.

    ${water_cooled}=  Read Attribute
    ...  /xyz/openbmc_project/inventory/system/chassis  WaterCooled
    [Return]  ${water_cooled}


Check Fan Count
    [Documentation]  Verify minimum number of fans.
    [Arguments]  ${fans}

    # Description of Argument(s):
    # fans  This is a list which is built-up, consisting of
    #       the names of active fans found.

    # For a water cooled system.
    ${min_fans_water}=  Set Variable  2

    # For an air cooled system.
    ${min_fans_air}=  Set Variable  3

    # Add fan to the @{fans} list only if its a working fan.
    ${fans}=  Add To Fans List  fan0  ${fans}
    ${fans}=  Add To Fans List  fan1  ${fans}
    ${fans}=  Add To Fans List  fan2  ${fans}
    ${fans}=  Add To Fans List  fan3  ${fans}

    # The number of working fans found.
    ${num_fans}=  Get Length  ${fans}

    # Determine if system is water cooled.
    ${water_coooled}=  Is Water Cooled

    Rprintn
    Rpvars  water_coooled  num_fans

    # If water cooled must have at least min_fans_water fans, otherwise
    # issue Fatal Error and terminate testing.
    Run Keyword if  ${water_coooled} == 1 and ${num_fans} < ${min_fans_water}
    ...  Fatal Error
    ...  msg=Water cooled but less than ${min_fans_water} fans present.

    # If air cooled must have at least min_fans_air fans.
    Run Keyword if  ${water_coooled} == 0 and ${num_fans} < ${min_fans_air}
    ...  Fatal Error
    ...  msg=Air cooled but less than ${min_fans_air} fans present.

    [Return]  ${fans}


Add To Fans List
    [Documentation]  Append the fan name to the @{fans} working fans list
    ...  if the fan is present and functional. ${fans} is a suite variable.
    [Arguments]  ${fan}  ${mylist}

    # Description of Argument(s):
    # fan      The name of the fan (e.g., fan0, fan1, fan2, or fan3).
    # mylist   If the fan is active its name is added to this list.

    ${present_and_functional}=  Is Fan Present And Functional  ${fan}
    Run Keyword If  ${present_and_functional}  Append To List
    ...  ${mylist}  ${fan}
    Rpvars  fan  present_and_functional
    [Return]  ${mylist}


Reset Fans
    [Documentation]  Set system fans to functional state.
    # Set state of fans to functional by writing 1 to the
    # Functional attribute of each fan.

    # Description of Argument(s):
    # fans    Suite Variable which is a list containing the
    #         names of the fans (e.g., fan0 fan2 fan3).

    ${valueDict}=  Create Dictionary  data=${1}
    :FOR  ${fan}  IN  @{fans}
    \  Write Attribute
    ...  /xyz/openbmc_project/inventory/system/chassis/motherboard/${fan}
    ...  Functional  data=${valueDict}


Get Max Target Speed Of Fans
    [Documentation]  Returns the maximum target RPM speed of system fans.

    ${max_target}=  Set Variable  0
    ${fans}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/fan_tach/  0
    :FOR  ${entry}  IN  @{fans}
    \  ${resp}=  OpenBMC Get Request  ${entry}
    \  ${json}=  To JSON  ${resp.content}
    \  ${target_value}=  Set Variable  ${json["data"]["Target"]}
    \  ${max_target}=  Run Keyword If  ${target_value} > ${max_target}
    ...  Set Variable  ${target_value}  ELSE  Set Variable  ${max_target}
    [Return]  ${max_target}


Are Front And Rear LEDs Off
    [Documentation]  Return 1 if both enclosure LEDs are off.

    ${front_fault}=  Get System LED State  front_fault
    ${rear_fault}=  Get System LED State  rear_fault
    #Log To Console  FRONTFAULT=${front_fault} AND REARFAULT=${rear_fault}
    ${both_are_off}=  Run Keyword If
    ...  '${front_fault}' == 'Off' and '${rear_fault}' == 'Off'
    ...  Set Variable  1  ELSE  Set Variable  0
    [Return]  ${both_are_off}


Set System LED State
    [Documentation]  Set given system LED via REST.
    [Arguments]  ${led_name}  ${led_state}

    # Description of arguments:
    # led_name     System LED name (e.g. heartbeat, identify, beep).
    # led_state    LED state to be set (e.g. On, Off).

    ${args}=  Create Dictionary
    ...  data=xyz.openbmc_project.Led.Physical.Action.${led_state}
    Write Attribute  ${LED_PHYSICAL_URI}${led_name}  State  data=${args}


Test Setup Execution
    [Documentation]  Do the pre-test setup.

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
