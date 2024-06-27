*** Settings ***
Documentation       Test OpenBMC GUI "Power restore policy" sub-menu of "Settings" menu.

Resource            ../../lib/gui_resource.robot

Suite Setup         Launch Browser And Login GUI
Suite Teardown      Close Browser
Test Setup          Test Setup Execution

Test Tags           power_restore_policy_sub_menu


*** Variables ***
${xpath_power_restore_policy_heading}       //h1[text()="Power restore policy"]
${xpath_AlwaysOn_radio}                     //input[@value='AlwaysOn']
${xpath_AlwaysOff_radio}                    //input[@value='AlwaysOff']
${xpath_LastState_radio}                    //input[@value='LastState']
${xpath_save_settings_button}               //button[contains(text(),'Save')]


*** Test Cases ***
Verify Navigation To Power Restore Policy Page
    [Documentation]    Verify navigation to Power Restore Policy page.
    [Tags]    verify_navigation_to_power_restore_policy_page

    Page Should Contain Element    ${xpath_power_restore_policy_heading}

Verify Existence Of All Sections In Power Restore Policy Page
    [Documentation]    Verify existence of all sections in Power Restore Policy page.
    [Tags]    verify_existence_of_all_sections_in_power_restore_policy_page

    Page Should Contain    Power restore policies

Verify Existence Of All Buttons In Power Restore Policy Page
    [Documentation]    Verify existence of All Buttons.
    [Tags]    verify_existence_of_all_buttons_in_power_restore_policy_page

    Page Should Contain Element    ${xpath_AlwaysOn_radio}
    Page Should Contain Element    ${xpath_AlwaysOff_radio}
    Page Should Contain Element    ${xpath_LastState_radio}
    Page Should Contain Element    ${xpath_save_settings_button}


*** Keywords ***
Test Setup Execution
    [Documentation]    Do test case setup tasks.

    Click Element    ${xpath_settings_menu}
    Click Element    ${xpath_power_restore_policy_sub_menu}
    Wait Until Keyword Succeeds    30 sec    10 sec    Location Should Contain    power-restore-policy
    Wait Until Element Is Not Visible    ${xpath_page_loading_progress_bar}    timeout=30
