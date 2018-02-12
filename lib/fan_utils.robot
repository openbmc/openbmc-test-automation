*** Settings ***
Documentation     Utilities for fan tests.

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
