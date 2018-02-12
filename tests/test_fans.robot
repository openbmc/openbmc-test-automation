*** Settings ***

Documentation  Fan checks.

# Test Parameters:
# OPENBMC_HOST   The BMC host name or IP address.
#
# Example:
#  python -m robot -v  OPENBMC_HOST:$BMC tests/test_fans.robot
#
# Approximate run time:  15 seconds.

Resource         ../lib/state_manager.robot
Resource         ../lib/fan_utils.robot
Resource         ../lib/openbmc_ffdc.robot

Test Teardown    FFDC On Test Case Fail


*** Test Cases ***

Verify Minimum Fan Count
    [Documentation]  Verify minimum number of fans.
    [Tags]  Verify_Minimum_Fan_Count

    # For a water cooled system.
    ${min_fans_water}=  Set Variable  2

    # For an air cooled system.
    ${min_fans_air}=  Set Variable  3

    ${fan_count}=  Get Number Of Fans

    # Determine if system is water cooled.
    ${water_coooled}=  Is Water Cooled

    Rprintn
    Rpvars  water_coooled  fan_count

    # If water cooled must have at least min_fans_water fans, otherwise
    # issue Fatal Error and terminate testing.
    Run Keyword if  ${water_coooled} == 1 and ${fan_count} < ${min_fans_water}
    ...  Fatal Error
    ...  msg=Water cooled but less than ${min_fans_water} fans present.

    # If air cooled must have at least min_fans_air fans.
    Run Keyword if  ${water_coooled} == 0 and ${fan_count} < ${min_fans_air}
    ...  Fatal Error
    ...  msg=Air cooled but less than ${min_fans_air} fans present.


Verify Fan Monitors
    [Documentation]  Verify fan monitor daemons.
    [Tags]  Verify_Fan_Monitors

    # Open connection to BMC and issue systemctl command to get monitor list.
    &{bmc_connection_args}=  Create Dictionary  alias=bmc_connection
    Open Connection And Log In  &{bmc_connection_args}
    ${cmd_output}=  Execute Command On BMC
    ...  systemctl list-units | grep phosphor-fan

    ${output_length}=  Get Length  ${cmd_output}

    ${state}=  Get Chassis Power State

    # Fail if system is On and there are no fan monitors.
    Run Keyword If  '${state}' == 'On' and ${output_length} == 0
    ...  Fail  msg=No phosphor-fan monitors found at power on.

    # Fail if system is Off and the fan monitors are present.
    Run Keyword If  '${state}' == 'Off' and ${output_length} != 0
    ...  Fail  msg=Phosphor-fan monitors found at power off.
