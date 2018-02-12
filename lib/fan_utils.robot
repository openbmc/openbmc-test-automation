*** Settings ***
Documentation     Utilities for fan tests.


*** Keywords ***

Is Water Cooled
    [Documentation]  Return 1 if system is water cooled, 0 othersise.

    ${water_cooled}=  Read Attribute
    ...  /xyz/openbmc_project/inventory/system/chassis  WaterCooled
    [Return]  ${water_cooled}


Get Number Of Fans
    [Documentation]  Get the fan count currently in inventory.

    ${count_fans}  Set Variable  ${0}
    ${list}=  Get Endpoint Paths  ${HOST_INVENTORY_URI}/system  fan

    : FOR  ${element}  IN  @{list}
    \  ${present}=  Read Properties  ${element}
    \  ${count_fans}=  Set Variable if  ${present['Present']} == 1
    \  ...  ${count_fans+1}  ${count_fans}
    [return]  ${count_fans}
