*** Settings ***

Documentation  Test OpenBMC GUI "Host console" sub-menu of "Operations".

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution

Test Tags      Host_Console_Sub_Menu

*** Variables ***

${xpath_open_in_new_tab_button}  //button[contains(normalize-space(.),'Open in new tab')]


*** Test Cases ***

Verify Navigation To Host Console Page
    [Documentation]  Verify navigation to Host console page.
    [Tags]  Verify_Navigation_To_Host_Console_Page

    Page Should Contain Element  ${xpath_host_console_heading}


Verify Existence Of All Buttons In Host Console Page
    [Documentation]  Verify existence of all buttons in Host console page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Host_Console_Page

    Page Should Contain Element  ${xpath_open_in_new_tab_button}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_operations_menu}
    Click Element  ${xpath_host_console_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  host-console
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
