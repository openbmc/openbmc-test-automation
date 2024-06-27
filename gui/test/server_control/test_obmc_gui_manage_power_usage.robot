*** Settings ***
Documentation       Test OpenBMC GUI "Manage power usage" sub-menu of "Server control".

Resource            ../../lib/resource.robot

Suite Setup         Launch Browser And Login OpenBMC GUI
Suite Teardown      Close Browser
Test Setup          Test Setup Execution


*** Variables ***
${xpath_power_cap_toggle_button}    //*[@class="toggle-container"]


*** Test Cases ***
Verify Existence Of All Sections In Manage Power Usage Page
    [Documentation]    Verify existence of all sections in manage power usage page.
    [Tags]    verify_existence_of_all_sections_in_manage_power_usage_page

    Page Should Contain    Power information
    Page Should Contain    Server power cap setting

Verify Existence Of All Buttons In Manage Power Usage Page
    [Documentation]    Verify existence of all buttons in manage power usage page.
    [Tags]    verify_existence_of_all_buttons_in_manage_power_usage_page

    Page Should Contain Element    ${xpath_power_cap_toggle_button}
    Page Should Contain Element    ${xpath_save_setting_button}
    Page Should Contain Element    ${xpath_cancel_button}


*** Keywords ***
Test Setup Execution
    [Documentation]    Do test case setup tasks.

    Wait Until Page Does Not Contain Element    ${xpath_refresh_circle}
    Click Element    ${xpath_select_server_control}
    Wait Until Page Does Not Contain Element    ${xpath_refresh_circle}
    Click Element    ${xpath_select_manage_power_usage}
    Wait Until Page Contains    Manage Power Usage
