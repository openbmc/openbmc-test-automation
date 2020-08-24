*** Settings ***

Documentation  Test OpenBMC GUI "Server LED" sub-menu of "Server control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_server_led_heading}  //h1[text()="Server LED"]
${xpath_led_value}           //*[@data-test-id='serverLed-checkbox-switchIndicatorLed']/following-sibling::label/span
${xpath_overview_led_value}  //*[@data-test-id='overviewQuickLinks-checkbox-serverLed']/following-sibling::label/span
${xpath_led_toggle}          //*[@data-test-id='serverLed-checkbox-switchIndicatorLed']


*** Test Cases ***

Verify Navigation To Server LED Page
    [Documentation]  Verify navigation to server LED page.
    [Tags]  Verify_Navigation_To_Server_LED_Page

    Page Should Contain Element  ${xpath_server_led_heading}


Verify Existence Of All Sections In Server LED Page
    [Documentation]  Verify existence of all sections in Server LED page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Server_LED_Page

    Page Should Contain  LED light control


Verify Server Led Sync With Overview Page LED Status
    [Documentation]  Verify server LED sync with overview page LED status.
    [Tags]  Verify_Server_Led_Sync_With_Overview_Page_LED_Status

    ${gui_led_value} =  Get Text  ${xpath_led_value}
    Click Element  ${xpath_overview_menu}
    ${overview_led_value} =  Get Text  ${xpath_overview_led_value}

    Should Be Equal  ${gui_led_value}  ${overview_led_value}


Verify Server Led On
    [Documentation]  Verify Server LED Button On.
    [Tags]  Verify_Server_Led_On

    # Turn Off the server LED via Redfish.
    Redfish.Patch  /redfish/v1/Systems/system  body={"IndicatorLED":"Off"}   valid_status_codes=[200, 204]

    #Turn On the LED via GUI and sleep
    Click Element At Coordinates  ${xpath_led_toggle}  0  0
    Wait Until Element Contains  ${xpath_led_value}  On  timeout=15

    Verify Identify LED using Redfish and GUI  On


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_server_led_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  server-led


Verify Identify LED using Redfish and GUI
    [Documentation]  Verify Identify LED using Redfish and GUI
    [Arguments]  ${expected_led_status}

    ${gui_led_value} =  Get Text  ${xpath_led_value}
    ${redfish_readings}=  Redfish.Get Attribute  /redfish/v1/Systems/system  IndicatorLED

    ${redfish_led_value}=  Set Variable If  '${redfish_readings}' == 'Lit'
    ...  ${gui_led_value}
    Should Be Equal  ${gui_led_value}  ${expected_led_status}
    Should Be Equal  ${redfish_led_value}  ${expected_led_status}