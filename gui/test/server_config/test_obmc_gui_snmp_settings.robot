*** Settings ***

Documentation  Test OpenBMC GUI "SNMP settings" sub-menu of "Server configuration".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_add_manager_button}           //button[text()[contains(.,"Add manager")]]


*** Test Cases ***

Verify Existence Of All Sections In SNMP Page
    [Documentation]  Verify existence of all sections in SNMP page.
    [Tags]  Verify_Existence_Of_All_Sections_In_SNMP_Page

    Page Should Contain  Managers


Verify Existence Of All Buttons In SNMP Page
    [Documentation]  Verify existence of all buttons in SNMP page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_SNMP_Page

    Page Should Contain Element  ${xpath_add_manager_button}
    Page Should Contain Element  ${xpath_save_setting_button}
    Page Should Contain Element  ${xpath_cancel_button}


*** Keywords ***

Test Setup Execution
   [Documentation]  Do test case setup tasks.

    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_server_configuration}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_snmp_settings}
    Wait Until Page Contains  SNMP settings
