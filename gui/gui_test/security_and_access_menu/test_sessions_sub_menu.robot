*** Settings ***

Documentation   Test OpenBMC GUI "Sessions" sub-menu of "Security and access" menu.

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution

Force Tags      Sessions_Sub_Menu

*** Variables ***

${xpath_sessions_heading}  //h1[contains(text(),'sessions')]


*** Test Cases ***

Verify Navigation To Sessions Page
    [Documentation]  Verify navigation to sessions page.
    [Tags]  Verify_Navigation_To_Sessions_Page

    Page Should Contain Element  ${xpath_sessions_heading}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_secuity_and_accesss_menu}
    Click Element  ${xpath_sessions_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  sessions
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
