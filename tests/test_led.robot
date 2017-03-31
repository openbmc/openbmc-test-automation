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

Turn On Off Heartbeat LED And Verify
    [Documentation]  Turn On Off heartbeat LED and verify via REST.
    #LED Name  LED State
    heartbeat  On
    heartbeat  Off

    [Tags]  Turn_On_Off_Heartbeat_LED_And_Verify
    [Template]  Set System LED State


Turn On Off Beep LED And Verify
    [Documentation]  Turn On Off beep LED and verify via REST.
    #LED Name  LED State
    beep       On
    beep       Off

    [Tags]  Turn_On_Off_Beep_LED_And_Verify
    [Template]  Set System LED State


Turn On Off Identify LED And Verify
    [Documentation]  Turn On Off identify LED and verify via REST.
    #LED Name  LED State
    identify   On
    identify   Off

    [Tags]  Turn_On_Off_Identify_LED_And_Verify
    [Template]  Set System LED State


*** Keywords ***

Get System LED State
    [Documentation]  Returns the state of given system LED.
    [Arguments]  ${led_name}
    # Description of arguments:
    # led_name     System LED name.

    ${state}=  Read Attribute  ${LED_PHYSICAL_URI}${led_name}  State
    #${state}=  OpenBMC Get Request  ${LED_PHYSICAL_URI}${led_name}
    [Return]  ${state.rsplit('.', 1)[1]}

Set System LED State
    [Documentation]  Set given system LED via REST.
    [Arguments]  ${led_name}  ${led_state}
    # Description of arguments:
    # led_name     System LED name.
    # led_state    LED state to be set.

    ${args}=  Create Dictionary  data=xyz.openbmc_project.Led.Physical.Action.${led_state}
    Write Attribute  ${LED_PHYSICAL_URI}${led_name}  State  data=${args}

    Verify LED State  ${led_name}  ${led_state}

Verify LED State
    [Documentation]  Checks if LED is in given state.
    [Arguments]  ${led_name}  ${led_state}
    # Description of arguments:
    # led_name     System LED name.
    # led_state    LED state to be verified.

    ${state}=  Get System LED State  ${led_name}
    Should Be Equal  ${state}  ${led_state}
