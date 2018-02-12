*** Settings ***
Documentation     Utilities for fan tests.

Library          ../lib/bmc_ssh_utils.py
Variables    ../data/variables.py

*** Keywords ***


Is Water Cooled
    [Documentation]  Return 1 if system is water cooled, 0 othersise.

    ${water_cooled}=  Read Attribute
    ...  ${HOST_INVENTORY_URI}/system/chassis  WaterCooled
    [Return]  ${water_cooled}


Get Number Of Fans
    [Documentation]  Get the number of fans currently present in inventory.

    ${num_fans}  Set Variable  ${0}
    ${fan_uris}=  Get Endpoint Paths  ${HOST_INVENTORY_URI}/system  fan

    : FOR  ${fan_uri}  IN  @{fan_uris}
    \  ${fan_record}=  Read Properties  ${fan_uri}
    \  Continue For Loop If  ${fan_record['Present']} != 1
    \  ${num_fans}=  Set Variable  ${num_fans+1}
    [Return]  ${num_fans}


Verify Minimum Number Of Fans With Cooling Type
    [Documentation]  Verify minimum number of fans.
    [Arguments]  ${water_cooled}

    # Description of argument(s):
    # water_cooled   The value 1 if the system is water cooled,
    #                the value 0 if air cooled.

    # For a water cooled system.
    ${min_fans_water}=  Set Variable  2

    # For an air cooled system.
    ${min_fans_air}=  Set Variable  3

    ${num_fans}=  Get Number Of Fans

    Rprintn
    Rpvars  water_cooled  num_fans

    # If water cooled must have at least min_fans_water fans, otherwise
    # issue Fatal Error and terminate testing.
    Run Keyword if  ${water_cooled} == 1 and ${num_fans} < ${min_fans_water}
    ...  Fatal Error
    ...  msg=Water cooled but less than ${min_fans_water} fans present.

    # If air cooled must have at least min_fans_air fans.
    Run Keyword if  ${water_cooled} == 0 and ${num_fans} < ${min_fans_air}
    ...  Fatal Error
    ...  msg=Air cooled but less than ${min_fans_air} fans present.


Verify Fan Monitors With State
    [Documentation]  Verify fan monitor daemons in the system state.
    # The number of monitoring daemons is dependent upon the system
    # power state.  If power is off there should be 0, if power
    # is on there should be several.
    [Arguments]  ${power_state}

    # Description of argument(s):
    # power_state   Power staet of the system, either "On" or "Off"

    ${cmd}=  Catenate  systemctl list-units | grep phosphor-fan | wc -l
    ${num_fan_daemons}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}

    Rpvars  num_fan_daemons

    # Fail if system is On and there are no fan monitors.
    Run Keyword If  '${power_state}' == 'On' and ${num_fan_daemons} == 0
    ...  Fail  msg=No phosphor-fan monitors found at power on.

    # Fail if system is Off and the fan monitors are present.
    Run Keyword If  '${power_state}' == 'Off' and ${num_fan_daemons} != 0
    ...  Fail  msg=Phosphor-fan monitors found at power off.
