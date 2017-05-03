*** Settings ***

Documentation     Test the functions of system LEDs.

Resource          ../lib/rest_client.robot
Resource          ../lib/state_manager.robot
Resource          ../lib/resource.txt
Resource          ../lib/openbmc_ffdc.robot

Test Teardown     FFDC On Test Case Fail

Force Tags        System_LED

*** Variables ***


*** Test Cases ***

Test Heartbeat LED And Verify Via REST
    [Documentation]  Turn On Off heartbeat LED and verify via REST.
    #LED Name  LED State
    heartbeat  On
    heartbeat  Off

    [Tags]  Test_Heartbeat_LED_And_Verify_Via_REST
    [Template]  Set System LED State

Test Beep LED And Verify Via REST
    [Documentation]  Turn On Off beep LED and verify via REST.
    #LED Name  LED State
    beep       On
    beep       Off

    [Tags]  Test_Beep_LED_And_Verify_Via_REST
    [Template]  Set System LED State

Test Identify LED And Verify Via REST
    [Documentation]  Turn On Off identify LED and verify via REST.
    #LED Name  LED State
    identify   On
    identify   Off

    [Tags]  Test_Identify_LED_And_Verify_Via_REST
    [Template]  Set System LED State

Test Power LED And Verify Via REST
    [Documentation]  Turn On/Off power LED and verify via REST.
    # LED Name  LED State
    power       On
    power       Off

    [Tags]  Test_Power_LED_And_Verify_Via_REST
    [Template]  Set System LED State

Test Fault LED And Verify Via REST
    [Documentation]  Turn On/Off fault LED and verify via REST.
    # LED Name  LED State
    fault       On
    fault       Off

    [Tags]  Test_Fault_LED_And_Verify_Via_REST
    [Template]  Set System LED State

*** Keywords ***

Set System LED State
    [Documentation]  Set given system LED via REST.
    [Arguments]  ${led_name}  ${led_state}
    # Description of arguments:
    # led_name     System LED name (e.g. heartbeat, identify, beep).
    # led_state    LED state to be set (e.g. On, Off).

    ${args}=  Create Dictionary  data=xyz.openbmc_project.Led.Physical.Action.${led_state}
    Write Attribute  ${LED_PHYSICAL_URI}${led_name}  State  data=${args}

    Verify LED State  ${led_name}  ${led_state}

Verify LED State
    [Documentation]  Checks if LED is in given state.
    [Arguments]  ${led_name}  ${led_state}
    # Description of arguments:
    # led_name     System LED name (e.g. heartbeat, identify, beep).
    # led_state    LED state to be verified (e.g. On, Off).

    ${state}=  Get System LED State  ${led_name}
    Should Be Equal  ${state}  ${led_state}
