*** Settings ***

Documentation  Fan checks that do not require a booted OS.

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
    [Documentation]  Verify minimum number of fans
    [Tags]  Verify_Minimum_Fan_Count

    @{fans}=  Create List
    ${fans}=  Check Fan Count  ${fans}


Verify Fan Monitors
    [Documentation]  Verify fan monitor daemons
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
