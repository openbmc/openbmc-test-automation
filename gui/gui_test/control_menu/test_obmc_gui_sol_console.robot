*** Settings ***

Documentation  Test OpenBMC GUI "Serial over LAN Console" sub-menu of "Control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_open_in_new_tab_button}  //button[contains(text(),'Open in new tab')]


*** Test Cases ***

Verify Navigation To SOL Console Page
    [Documentation]  Verify navigation to SOL console page.
    [Tags]  Verify_Navigation_To_SOL_Console_Page

    Page Should Contain Element  ${xpath_sol_console_heading}


Verify Existence Of All Sections In SOL Console Page
    [Documentation]  Verify existence of all sections in SOL console page.
    [Tags]  Verify_Existence_Of_All_Sections_In_SOL_Console_Page

    Page Should Contain  SOL console redirects server's serial port output to this window


Verify Existence Of All Buttons In SOL Console Page
    [Documentation]  Verify existence of all buttons in SOL console page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_SOL_Console_Page

    Page Should Contain Element  ${xpath_open_in_new_tab_button}


Verify Open In New Tab Button In SOL Page
    [Documentation]  Verify Open In New Tab Button in SOL page
    [Tags]  Verify_Open_In_New_Tab_Button_In_SOL_Page

    Click Element  ${xpath_open_in_new_tab_button}
    #To load the new window

    Sleep  10s
    Select Window    locator=NEW
    Title Should Be 	Serial over LAN (SOL) console
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  serial-over-lan-console


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_sol_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  serial-over-lan
