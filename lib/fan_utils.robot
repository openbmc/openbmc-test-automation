*** Settings ***
Documentation  Utilities for fan tests.

Library        ../lib/bmc_ssh_utils.py
Variables      ../data/variables.py

*** Keywords ***


Is Water Cooled
    [Documentation]  Return 1 if system is water cooled, 0 othersise.

    ${water_cooled}=  Read Attribute
    ...  ${HOST_INVENTORY_URI}/system/chassis  WaterCooled
    [Return]  ${water_cooled}


Append Fan Names To List
    [Documentation]  Append names of fans from system inventory to the
    ...  specified list.  Return the updated list to the caller.
    # For example, start with an empty list.  This routine populates
    # the list with the names of the fans in inventory e.g.,  fan0
    # fan2  fan3.
    # This keyword calls the keyword Add Fan To List From Path.
    [Arguments]  ${fans}

    # Description of Argument(s):
    # fans    The names of the fans are appended to this list.

    ${list}=  Get Endpoint Paths  ${HOST_INVENTORY_URI}/system  fan

    : FOR  ${path}  IN  @{list}
    \  ${present}=  Read Properties  ${path}
    \  ${fans}=  Run Keyword If  ${present['Present']} == 1
    ...  Add Fan To List From Path  ${path}  ${fans}  ELSE  Copy List  ${fans}
    [return]  ${fans}


Add Fan To List From Path
    [Documentation]  Append the fan name at the end of the specified
    ...  path to the fans list.  Return the update fans list to the caller.
    [Arguments]  ${path}  ${fans}

    # Description of Argument(s):
    # path    Inventory path of the fan, for example,
    #         /xyz/openbmc_project/inventory/system/chassis/motherboard/fan0
    # fans    List to append the fan name to.  For example, append 'fan0'.

    ${remaining_path}  ${fan_name}=  Split Path  ${path}
    Append To List  ${fans}  ${fan_name}
    [Return]  ${fans}


Get Number Of Fans
    [Documentation]  Get the number of fans listed in inventory.

    ${num_fans}  Set Variable  ${0}
    ${fan_uris}=  Get Endpoint Paths  ${HOST_INVENTORY_URI}/system  fan

    : FOR  ${fan_uri}  IN  @{fan_uris}
    \  ${fan_record}=  Read Properties  ${fan_uri}
    \  Continue For Loop If  ${fan_record['Present']} != 1
    \  ${num_fans}=  Set Variable  ${num_fans+1}
    [Return]  ${num_fans}


Verify System Error Indication Due To Fans
    [Documentation]  Verify enclosure LEDs are on and there's an error log.

    # Both enclosure LEDs should now be On.
    Verify Front And Rear LED State  On

    # An error log should now exist.
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}/list  quiet=${1}
    Run Keyword If  ${resp.status_code} != ${HTTP_OK}  Fail
    ...  msg=Expected BMC error log due to fan fail.


Verify Front And Rear LED State
    [Documentation]  Check state of the front and rear enclsure fault LEDs.
    # Both LEDs should be in the specified state.  If not fail the test case.
    [Arguments]  ${state}

    # Description of Argument(s):
    # state    The state to check for, either 'Off' or 'On'.

    ${front_fault}=  Get System LED State  front_fault
    ${rear_fault}=  Get System LED State  rear_fault
    Run Keyword If
    ...  '${front_fault}' != '${state}' or '${rear_fault}' != '${state}'
    ...  Fail  msg=Both enclosure LEDs are not ${state}.


Set Fan State
    [Documentation]  Set the fan state, either functional or non-functional.
    [Arguments]  ${test_fan}  ${fanstate}

    # Description of Argument(s):
    # test_fan    The names of the fan, e.g. fan2.
    # fanstate    The state to set, 1 for functional, 2 for non-functional.

    ${valueDict}=  Create Dictionary  data=${fanstate}
    Write Attribute
    ...  /xyz/openbmc_project/inventory/system/chassis/motherboard/${test_fan}
    ...  Functional  data=${valueDict}


Get Target Speed Of Fans
    [Documentation]  Returns the maximum target RPM speed of the system fans.

    ${max_target}=  Set Variable  0
    ${paths}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/fan_tach/  0
    :FOR  ${path}  IN  @{paths}
    \  ${response}=  OpenBMC Get Request  ${path}
    \  ${json}=  To JSON  ${response.content}
    \  ${target_speed}=  Set Variable  ${json["data"]["Target"]}
    \  ${max_target}=  Run Keyword If  ${target_speed} > ${max_target}
    ...  Set Variable  ${target_speed}  ELSE  Set Variable  ${max_target}
    [Return]  ${max_target}


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
    Run Keyword If  ${water_cooled} == 1 and ${num_fans} < ${min_fans_water}
    ...  Fatal Error
    ...  msg=Water cooled but less than ${min_fans_water} fans present.

    # If air cooled must have at least min_fans_air fans.
    Run Keyword If  ${water_cooled} == 0 and ${num_fans} < ${min_fans_air}
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

    Rpvars  power_state  num_fan_daemons

    # Fail if system is On and there are no fan monitors.
    Run Keyword If  '${power_state}' == 'On' and ${num_fan_daemons} == 0
    ...  Fail  msg=No phosphor-fan monitors found at power on.

    # Fail if system is Off and the fan monitors are present.
    Run Keyword If  '${power_state}' == 'Off' and ${num_fan_daemons} != 0
    ...  Fail  msg=Phosphor-fan monitors found at power off.
