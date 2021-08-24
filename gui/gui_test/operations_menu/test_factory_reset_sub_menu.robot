*** Settings ***

Documentation   Test suite for OpenBMC GUI "Factory reset" sub-menu of "Operation" menu.

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser


*** Variables ***

${xpath_factory_reset_heading}          //h1[text()="Factory reset"]
${xpath_reset_button}                   //button[contains(text(),'Reset')]
${xpath_reset_server_radio_button}      //*[@data-test-id='factoryReset-radio-resetBios']
${xpath_reset_bmc_server_radio_button}  //*[@data-test-id='factoryReset-radio-resetToDefaults']


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


Verify Existence Of All Radio Buttons In Factory Reset Page
     [Documentation]  Verify existence of all radio buttons in factory reset page.
     [Tags]  Verify_Existence_Of_All_Radio_Buttons_In_Factory_Reset_Page

     Page Should Contain Element  ${xpath_reset_server_radio_button}
     Page Should Contain Element  ${xpath_reset_bmc_server_radio_button}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test suite setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_operations_menu}
    Click Element  ${xpath_factory_reset_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  factory-reset
