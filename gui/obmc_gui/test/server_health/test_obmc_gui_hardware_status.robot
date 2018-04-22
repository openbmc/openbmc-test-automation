*** Settings ***

Documentation  Test Open BMC GUI server control hardware status.

Library        DateTime

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Logout And Close Browser
Test Setup      Test Setup Execution

*** Variables ***
${xpath_select_server_health}   //*[@id="nav__top-level"]/li[2]/button
${xpath_select_hardware_status}  //a[@href='#/server-health/inventory-overview']
${xpath_inventory_export}  css:a.inline
${xpath_inventory_search}  //*[@id="content__search-input"]
${xpath_inventory_search_button}  //*[@id="content__search-submit"]

*** Test Cases ***
Verify Select Health Status From Server Health
    [Documentation]  Verify ability to select hardware status option from
    ...  server health sub menu.
    [Tags]  Verify_Select_Health_Status_From_Server_Health

    Wait Until Page Contains  Hardware status
    Page should contain  All hardware in the system


Verify Inventory Export From Server Health Clickable
    [Documentation]  Verify ability to export inventory from server health
    ...  sub menu.
    [Tags]  Verify_Inventory_Export_From_Server_Health_Clickable

    Page Should Contain Element  ${xpath_inventory_export}
    Click Element  ${xpath_inventory_export}

Verify Search Text Enterable
    [Documentation]  Verify search text input allowed from server health
    ...  sub menu.
    [Tags]  Verify_Search_Text_Enterable

    Page Should Contain Element  ${xpath_inventory_search}
    Input Text  ${xpath_inventory_search}  fan
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain Element  ${xpath_inventory_search_button}
    Click Element  ${xpath_inventory_search_button}

*** Keywords ***

Test Setup Execution
   [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_select_server_health}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_hardware_status}

