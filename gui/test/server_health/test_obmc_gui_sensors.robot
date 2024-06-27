*** Settings ***
Documentation       Test OpenBMC GUI "Sensors" sub-menu of "Server health".

Resource            ../../lib/resource.robot

Suite Setup         Launch Browser And Login OpenBMC GUI
Suite Teardown      Close Browser
Test Setup          Test Setup Execution


*** Variables ***
${xpath_select_server_health}       //*[@id="nav__top-level"]/li[2]/button
${xpath_select_sensors}             //a[@href='#/server-health/sensors-overview']
${xpath_sensors_export}             //a[contains(text(), "Export")]
${xpath_sensors_search}             //*[@id="content__search-input"]
${xpath_sensors_search_button}      //*[@id="content__search-submit"]


*** Test Cases ***
Verify Select Sensors From Server Health
    [Documentation]    Verify ability to select "Sensors" sub-menu option of
    ...    "Server health".
    [Tags]    verify_select_sensors_from_server_health

    Wait Until Page Contains    Sensors
    Page should contain    All sensors present in the system

Verify Sensors Export From Server Health Clickable
    [Documentation]    Verify ability to export sensors from "Sensors"
    ...    sub-menu of "Server health".
    [Tags]    verify_sensors_export_from_server_health_clickable

    Page Should Contain Element    ${xpath_sensors_export}
    Click Element    ${xpath_sensors_export}

Verify Search Text Enterable
    [Documentation]    Verify search text input allowed from "Sensors"
    ...    sub-menu of "Server health".
    [Tags]    verify_search_text_enterable

    Page Should Contain Element    ${xpath_sensors_search}
    Input Text    ${xpath_sensors_search}    Temperature
    Wait Until Page Does Not Contain Element    ${xpath_refresh_circle}
    Page Should Contain Element    ${xpath_sensors_search_button}
    Focus    ${xpath_sensors_search_button}
    Click Element    ${xpath_sensors_search_button}


*** Keywords ***
Test Setup Execution
    [Documentation]    Do test case setup tasks.

    Click Element    ${xpath_select_server_health}
    Wait Until Page Does Not Contain Element    ${xpath_refresh_circle}
    Click Element    ${xpath_select_sensors}
