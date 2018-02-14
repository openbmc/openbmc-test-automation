*** Settings ***

Documentation     Test the functions of system LEDs.

Resource          ../lib/rest_client.robot
Resource          ../lib/state_manager.robot
Resource          ../lib/resource.txt
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/utils.robot

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
    rear_power       On
    rear_power       Off
    front_power      On
    front_power      Off

    [Tags]  Test_Power_LED_And_Verify_Via_REST
    [Template]  Set System LED State

Test Fault LED And Verify Via REST
    [Documentation]  Turn On/Off fault LED and verify via REST.
    # LED Name  LED State
    rear_fault       On
    rear_fault       Off
    front_fault      On
    front_fault      Off

    [Tags]  Test_Fault_LED_And_Verify_Via_REST
    [Template]  Set System LED State

Test Rear Identify LED And Verify Via REST
    [Documentation]  Turn On/Off identify LED and verify via REST.
    #LED Name  LED State
    rear_id    On
    rear_id    Off
    front_id   On
    front_id   Off

    [Tags]  Test_Rear_Identify_LED_And_Verify_Via_REST
    [Template]  Set System LED State


Verify Rear Power LED With Host Power Off
    [Documentation]  Verify power LED state with host power off.
    [Tags]  Verify_Rear_Power_LED_With_Host_Power_Off

    Initiate Host PowerOff
    ${resp}=  Get System LED State  rear_power
    Should Be Equal  ${resp}  Blink
    ${resp}=  Get System LED State  front_power
    Should Be Equal  ${resp}  Blink


Verify Rear Power LED With Host Power On
    [Documentation]  Verify power LED state with host power on.
    [Tags]  Verify_Rear_Power_LED_With_Host_Power_On

    Initiate Host Boot
    ${resp}=  Get System LED State  rear_power
    Should Be Equal  ${resp}  On
    ${resp}=  Get System LED State  front_power
    Should Be Equal  ${resp}  On
