*** Settings ***
Documentation  Utilities for fan tests.

Library        ../lib/bmc_ssh_utils.py
Resource       ../lib/openbmc_ffdc_utils.robot
Variables      ../data/variables.py

*** Keywords ***

Is Water Cooled
    [Documentation]  Return 1 if system is water cooled, 0 othersise.

    ${water_cooled}=  Read Attribute
    ...  ${HOST_INVENTORY_URI}/system/chassis  WaterCooled
    [Return]  ${water_cooled}


Get Fan Names
    [Documentation]  Get the names of fans marked present in inventory.
    [Arguments]  ${fan_names}
    # This keyword populates the fan_names list with the names of
    # fans present in inventory e.g. fan0, fan2, fan3.

    # Description of Argument(s):
    # fan_names   The list of fan names to which new fan names are to be
    #             added to.  This list is returned to the caller.

    ${fan_uris}=  Get Endpoint Paths  ${HOST_INVENTORY_URI}/system  fan
    : FOR  ${fan_uri}  IN  @{fan_uris}
    \  ${fan_properties}=  Read Properties  ${fan_uri}
    \  Continue For Loop If  ${fan_properties['Present']} != 1
    \  ${remaining_uri}  ${fan_name}=  Split Path  ${fan_uri}
    \  Append To List  ${fan_names}  ${fan_name}

    [Return]  ${fan_names}


Verify System Error Indication Due To Fans
    [Documentation]  Verify enclosure LEDs are on and there's an error log.

    # Both enclosure LEDs should now be On.
    Verify Front And Rear LED State  On

    # An error log should now exist.
    Error Logs Should Exist


Verify Front And Rear LED State
    [Documentation]  Check state of the front and rear enclsure fault LEDs.
    [Arguments]  ${state}
    # Both LEDs should be in the specified state.  If not fail the test case.

    # Description of Argument(s):
    # state    The state to check for, either 'Off' or 'On'.

    ${front_fault}=  Get System LED State  front_fault
    ${rear_fault}=  Get System LED State  rear_fault
    Run Keyword If
    ...  '${front_fault}' != '${state}' or '${rear_fault}' != '${state}'
    ...  Fail  msg=Expecting both enclosure LEDs to be ${state}.


Set Fan State
    [Documentation]  Set the fan state, either functional or non-functional.
    [Arguments]  ${fan_name}  ${fan_state}

    # Description of Argument(s):
    # fan_name     The name of the fan, e.g. "fan2".
    # fan_state    The state to set, 1 for functional, 2 for non-functional.

    ${valueDict}=  Create Dictionary  data=${fan_state}
    Write Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${fan_name}
    ...  Functional  data=${valueDict}


Set Target Speed Of Fan
    [Documentation]  Set the target RPM speed of a fans.
    [Arguments]  ${fan_name}  ${fan_speed}

    # Description of argument(s):
    # fan_name    The name of the fan, e.g., "fan0".
    # fan_speed   The target RPM to set, e.g. "9000".

    ${valueDict}=  Create Dictionary  data=${fan_speed}
    Write Attribute
    ...  ${SENSORS_URI}fan_tach/${fan_name}_0
    ...  Target  data=${valueDict}


Get Target Speed Of Fans
    [Documentation]  Return the maximum target RPM speed of the system fans.

    ${max_target}=  Set Variable  0
    ${paths}=  Get Endpoint Paths  ${SENSORS_URI}fan_tach/  0
    :FOR  ${path}  IN  @{paths}
    \  ${response}=  OpenBMC Get Request  ${path}
    \  ${json}=  To JSON  ${response.content}
    \  ${target_speed}=  Set Variable  ${json["data"]["Target"]}
    \  ${max_target}=  Run Keyword If  ${target_speed} > ${max_target}
    ...  Set Variable  ${target_speed}  ELSE  Set Variable  ${max_target}
    [Return]  ${max_target}


Get Target And Blade Speeds
    [Documentation]  Return the fan target speed setting, the RPM of the
    ...  fan's clockwise blade, and the RPM of the counter-clockwise blade.
    # Each fan unit has two counter-rotating fan blades
    # One blade is expected to be moving but the other blade may be
    # 0 RPM whenever the fan unit is transition to a new target RPM.
    [Arguments]  ${fan_name}

    # Description of argument(s):
    # fan_name       The name of a fan, e.g. "fan0"

    # Get the fan target speed and the clockwise blade speed.
    ${path}=  Catenate  ${SENSORS_URI}fan_tach/${fan_name}_0
    ${response}=  OpenBMC Get Request  ${path}
    ${json}=  To jSON  ${response.content}
    ${fan_cw_speed}=  Set Variable  ${json["data"]["Value"]}
    ${target_speed}=  Set Variable  ${json["data"]["Target"]}

    # Get the counter-clockwise blade speed.
    ${path}=  Catenate  ${SENSORS_URI}fan_tach/${fan_name}_1
    ${response}=  OpenBMC Get Request  ${path}
    ${json}=  To jSON  ${response.content}
    ${fan_ccw_speed}=  Set Variable  ${json["data"]["Value"]}

    [Return]  ${target_speed}  ${fan_cw_speed}  ${fan_ccw_speed}


Get Fan Target And Speed
    [Documentation]  Return the fan target speed setting and the RPM
    ...  of the fastest blade.
    [Arguments]  ${fan_name}

    # Description of argument(s):
    # fan_name       The name of a fan, e.g. "fan0"

    ${target_rpm}  ${cw_rpm}  ${ccw_rpm}=
    ...  Get Target And Blade Speeds  ${fan_name}
    ${blade_speed}=  Run Keyword If  ${cw_rpm} > ${ccw_rpm}
    ...  Set Variable  ${cw_rpm}  ELSE  Set Variable  ${ccw_rpm}
    [Return]  ${target_rpm}  ${blade_speed}



Set Fan Daemon State
    [Documentation]  Set the state of the fan control service.
    [Arguments]  ${state}

    # Description of argument(s):
    # state     The desired state of the service, usually
    #           "start", "stop", or "restart"

    ${cmd}=  Catenate  systemctl  ${state}  phosphor-fan-control@0.service
    Execute Command On BMC  ${cmd}


Verify Minimum Number Of Fans With Cooling Type
    [Documentation]  Verify minimum number of fans.
    [Arguments]  ${num_fans}  ${water_cooled}

    # Description of argument(s):
    # num_fans       The number of fans present in the system.
    # water_cooled   The value 1 if the system is water cooled,
    #                0 if air cooled.

    # For a water cooled system.
    ${min_fans_water}=  Set Variable  2

    # For an air cooled system.
    ${min_fans_air}=  Set Variable  3

    Rprintn
    Rpvars  num_fans  water_cooled

    # If water cooled must have at least min_fans_water fans, otherwise
    # issue Fatal Error and terminate testing.
    Run Keyword If  ${water_cooled} == 1 and ${num_fans} < ${min_fans_water}
    ...  Fatal Error
    ...  msg=Water cooled but less than ${min_fans_water} fans present.

    # If air cooled must have at least min_fans_air fans.
    Run Keyword If  ${water_cooled} == 0 and ${num_fans} < ${min_fans_air}
    ...  Fatal Error
    ...  msg=Air cooled but less than ${min_fans_air} fans present.


Verify Fan Monitors With State
    [Documentation]  Verify fan monitor daemons in the system state.
    [Arguments]  ${power_state}
    # The number of monitoring daemons is dependent upon the system
    # power state.  If power is off there should be 0, if power
    # is on there should be several.

    # Description of argument(s):
    # power_state   Power staet of the system, either "On" or "Off"

    ${cmd}=  Catenate  systemctl list-units | grep phosphor-fan | wc -l
    ${num_fan_daemons}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}

    Rpvars  power_state  num_fan_daemons

    # Fail if system is On and there are no fan monitors.
    Run Keyword If  '${power_state}' == 'On' and ${num_fan_daemons} == 0
    ...  Fail  msg=No phosphor-fan monitors found at power on.

    # Fail if system is Off and the fan monitors are present.
    Run Keyword If  '${power_state}' == 'Off' and ${num_fan_daemons} != 0
    ...  Fail  msg=Phosphor-fan monitors found at power off.
