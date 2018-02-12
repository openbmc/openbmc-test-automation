*** Settings ***

Documentation  Fan checks.

# Test Parameters:
# OPENBMC_HOST       The BMC host name or IP address.
# OPENBMC_USERNAME   The userID to login to the BMC as.
# OPENBMC_PASSWORD   The password for OPENBMC_USERNAME.
#
# Example:
#  python -m robot -v OPENBMC_HOST:$BMC -v OPENBMC_USERNAME
#  -v OPENBMC_PASSWORD tests/test_fans.robot
#
# Approximate run time:  15 seconds.

Resource         ../lib/state_manager.robot
Resource         ../lib/fan_utils.robot
Resource         ../lib/openbmc_ffdc.robot
Library          ../lib/bmc_ssh_utils.py

#Test Teardown    FFDC On Test Case Fail


*** Test Cases ***

Verify Minimum Number Of Fans
    [Documentation]  Verify minimum number of fans.
    [Tags]  Verify_Minimum_Number_Of_Fans

    # For a water cooled system.
    ${min_fans_water}=  Set Variable  2

    # For an air cooled system.
    ${min_fans_air}=  Set Variable  3

    ${num_fans}=  Get Number Of Fans

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


Verify Fan Monitors
    [Documentation]  Verify fan monitor daemons.
    [Tags]  Verify_Fan_Monitors

    ${cmd}=  Catenate  systemctl list-units | grep phosphor-fan | wc -l
    ${num_fan_daemons}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}

    ${state}=  Get Chassis Power State
    Rpvars  state  num_fan_daemons

    # Fail if system is On and there are no fan monitors.
    Run Keyword If  '${state}' == 'On' and ${num_fan_daemons} == 0
    ...  Fail  msg=No phosphor-fan monitors found at power on.

    # Fail if system is Off and the fan monitors are present.
    Run Keyword If  '${state}' == 'Off' and ${num_fan_daemons} != 0
    ...  Fail  msg=Phosphor-fan monitors found at power off.
