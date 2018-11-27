*** Settings ***

Documentation  Test OpenBMC GUI "Hardware status" sub-menu  of "Server health".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution

*** Variables ***

${xpath_select_server_health}  //*[@id="nav__top-level"]/li[2]/button
${xpath_select_hardware_status}  //a[@href='#/server-health/inventory-overview']
${xpath_inventory_export}  css:a.inline
${xpath_inventory_search}  //*[@id="content__search-input"]
${xpath_inventory_search_button}  //*[@id="content__search-submit"]
${xpath_inventory_search_text_clear}  class:clear-input
${xpath_bmc_expand}  //*[@id="inventory-categories"]/div[5]/button
${xpath_system_expand}  //*[@id="inventory-categories"]/div[2]/button
${xpath_motherboard_expand}  //*[@id="inventory-categories"]/div[4]/button
${xpath_chassis_expand}  //*[@id="inventory-categories"]/div[3]/button

*** Test Cases ***

Verify Select Health Status From Server Health
    [Documentation]  Verify ability to select "Hardware status" sub-menu option
    ...  of "Server health".
    [Tags]  Verify_Select_Health_Status_From_Server_Health

    Wait Until Page Contains  Hardware status
    Page should contain  All hardware in the system


Verify Inventory Export From Server Health Clickable
    [Documentation]  Verify ability to export inventory from "Hardware status"
    ...  sub-menu.
    [Tags]  Verify_Inventory_Export_From_Server_Health_Clickable

    Page Should Contain Element  ${xpath_inventory_export}
    Click Element  ${xpath_inventory_export}


Verify Search Text Enterable
    [Documentation]  Verify search text input allowed from "Hardware status"
    ...  sub-menu.
    [Tags]  Verify_Search_Text_Enterable

    Page Should Contain Element  ${xpath_inventory_search}
    Input Text  ${xpath_inventory_search}  fan
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain Element  ${xpath_inventory_search_button}
    Click Element  ${xpath_inventory_search_button}


Verify Search Text Clearable
    [Documentation]  Verify search text allowed to clear from "Hardware status"
    ...  sub-menu.
    [Tags]  Verify_Search_Text_Clearable

    Page Should Contain Element  ${xpath_inventory_search}
    Input Text  ${xpath_inventory_search}  fan
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain Element  ${xpath_inventory_search_text_clear}
    Click Element  ${xpath_inventory_search_text_clear}


Verify System Inventory Expand
    [Documentation]  Verify system inventory icon expandable from
    ...  "Hardware status" sub-menu.
    [Tags]  Verify_System_Inventory_Expand
    [Template]  Verify Hardware Inventory Expand

    # xpath_hardware_item
    ${xpath_system_expand}
    ${xpath_chassis_expand}
    ${xpath_bmc_expand}
    ${xpath_motherboard_expand}

*** Keywords ***

Test Setup Execution
   [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_select_server_health}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_hardware_status}


Verify Hardware Inventory Expand
   [Documentation]  Verify expand individual hardware inventory item.
   [Arguments]  ${xpath_hardware_item}

   # Description of argument(s):
   # xpath_hardware_item    Hardware inventory item to be expand. e.g. fan.

   Page Should Contain Element  ${xpath_hardware_item}
   Click Element  ${xpath_hardware_item}
