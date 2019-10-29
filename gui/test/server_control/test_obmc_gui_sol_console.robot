*** Settings ***

Documentation  Test OpenBMC GUI "SOL console" sub-menu of "Server control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_open_in_new_tab_button}  //button[text()[contains(.,"Open in new tab")]]


*** Test Cases ***

Verify Existence Of All Sections In SOL Console Page
    [Documentation]  Verify existence of all sections in SOL console page.
    [Tags]  Verify_Existence_Of_All_Sections_In_SOL_Console_Page

    Page Should Contain  Access the Serial over LAN console


Verify Existence Of All Buttons In SOL Console Page
    [Documentation]  Verify existence of all buttons in SOL console page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_SOL_Console_Page

    Page Should Contain Element  ${xpath_open_in_new_tab_button}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_server_control}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_sol_console}
    Wait Until Page Contains  Serial over LAN console
