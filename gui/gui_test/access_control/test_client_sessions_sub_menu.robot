*** Settings ***

Documentation   Test OpenBMC GUI "Client sessions" sub-menu of "Access Control" menu.

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_client_sessions_heading}  //h1[text()="Client sessions"]


*** Test Cases ***

Verify Navigation To Client Sessions Page
    [Documentation]  Verify navigation to client sessions page.
    [Tags]  Verify_Navigation_To_Client_Sessions_Page

    Page Should Contain Element  ${xpath_client_sessions_heading}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_access_control_menu}
    Click Element  ${xpath_client_sessions_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  client-sessions
