*** Settings ***

Documentation   Test OpenBMC GUI "Factory reset" sub-menu of "Control" menu.

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_factory_reset_heading}  //h1[text()="Factory reset"]
${xpath_reset_button}           //button[contains(text(),'Reset')]


*** Test Cases ***

Verify Navigation To Factory Reset Page
    [Documentation]  Verify navigation to factory reset page.
    [Tags]  Verify_Navigation_To_Factory_Reset_Page

    Page Should Contain Element  ${xpath_factory_reset_heading}


Verify Existence Of All Sections In Factory Reset Page
    [Documentation]  Verify existence of all sections in factory reset page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Factory_Reset_Page

    Page Should Contain  Reset options


Verify Existence Of All Buttons In Factory Reset Page
    [Documentation]  Verify existence of all buttons in factory reset page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Factory_Reset_Page

    Page Should Contain Element  ${xpath_reset_button}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_factory_reset_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  factory-reset
