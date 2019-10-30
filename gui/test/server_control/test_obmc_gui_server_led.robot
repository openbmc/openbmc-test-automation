*** Settings ***

Documentation  Test OpenBMC GUI "Server LED" sub-menu of "Server control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_led_light_control}           //*[@for="toggle__switch-round"]


*** Test Cases ***

Verify Existence Of All Sections In Server LED Page
    [Documentation]  Verify existence of all sections in Server LED page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Server_LED_Page

    Page Should Contain  LED light control
    Page Should Contain  Server LED light


Verify Existence Of All Buttons In Server LED Page
    [Documentation]  Verify existence of all buttons in Server LED page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Server_LED_Page

    Page Should Contain Element  ${xpath_led_light_control}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_server_control}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_server_led}
    Wait Until Page Contains  Server LED
