*** Settings ***

Documentation     Test the functions of physical LEDs.

Resource          ../lib/rest_client.robot
Resource          ../lib/state_manager.robot
Resource          ../lib/resource.txt
Resource          ../lib/openbmc_ffdc.robot

Test Teardown     FFDC On Test Case Fail

*** Variables ***


*** Test Cases ***

Turn On Off Heartbeat LED And Verify
    [Documentation]  Turn On Off heartbeat LED and verify via REST.
    #LED Name  LED State
    heartbeat  On
    heartbeat  Off

    [Tags]  Turn_On_Off_Heartbeat_LED_And_Verify
    [Template]  Set Physical LED State


Turn On Off Beep LED And Verify
    [Documentation]  Turn On Off beep LED and verify via REST.
    #LED Name  LED State
    beep       On
    beep       Off

    [Tags]  Turn_On_Off_Beep_LED_And_Verify
    [Template]  Set Physical LED State


Turn On Off Identify LED And Verify
    [Documentation]  Turn On Off identify LED and verify via REST.
    #LED Name  LED State
    identify   On
    identify   Off

    [Tags]  Turn_On_Off_Identify_LED_And_Verify
    [Template]  Set Physical LED State

Verify Heartbeat LEDs On State With Host Booted
    [Documentation]  Verify heartbeat LED's "On" state with host booted.
    [Tags]  Verify_Heartbeat_LEDs_On_State_With_Host_Booted

    Initiate Host Boot
    Verify LED State  heartbeat  On

Verify Heartbeat LEDs Off State With Host Off
    [Documentation]  Verify heartbeat LED's "Off" state with host off.
    [Tags]  Verify_Heartbeat_LEDs_Off_State_With_Host_Off

    Initiate Host PowerOff
    Verify LED State  heartbeat  Off

Verify Beep LEDs Off State With BMC Ready
    [Documentation]  Verify beep LED's "Off" state with BMC Ready.
    [Tags]  Verify_Beep_LEDs_Off_State_With_BMC_Ready

    Put BMC State  Ready
    Verify LED State  beep  Off

Verify Beep LEDs On State With BMC Not Ready
    [Documentation]  Verify beep LED's "On" state with BMC Not Ready.
    [Tags]  Verify_Beep_LEDs_On_State_With_BMC_Not_Ready

    Put BMC State  NotReady
    Verify LED State  beep  On

Verify Identify LEDs Off State
    [Documentation]  Verify identify LED's "Off" state.
    [Tags]  Verify_Identify_LEDs_Off_State

    Set LED State  Off  EnclosureIdentify
    Verify LED State  identify  Off

Verify Identify LEDs Blink State
    [Documentation]  Verify identify LED's "Blink" state.
    [Tags]  Verify_Identify_LEDs_Blink_State

    Set LED State  On  EnclosureIdentify
    Verify LED State  identify  Blink

*** Keywords ***

Get Physical LED State
    [Documentation]  Returns the state of given physical LED.
    [Arguments]  ${led_name}
    # Description of arguments:
    # led_name     Physical LED name.

    ${state}=  Read Attribute  ${LED_PHYSICAL_URI}${led_name}  State
    #${state}=  OpenBMC Get Request  ${LED_PHYSICAL_URI}${led_name}
    [Return]  ${state.rsplit('.', 1)[1]}

Set Physical LED State
    [Documentation]  Set given physical LED via REST.
    [Arguments]  ${led_name}  ${led_state}
    # Description of arguments:
    # led_name     Physical LED name.
    # led_state    LED state to be set.

    ${args}=  Create Dictionary  data=xyz.openbmc_project.Led.Physical.Action.${led_state}
    Write Attribute  ${LED_PHYSICAL_URI}${led_name}  State  data=${args}

    ${state}=  Get Physical LED State  ${led_name}
    Should Be Equal  ${state}  ${led_state}

Verify LED State
    [Documentation]  Checks if LED is in given state.
    [Arguments]  ${led_name}  ${led_state}
    # Description of arguments:
    # led_name     Physical LED name.
    # led_state    LED state to be verified.

    ${state}=  Get Physical LED State  ${led_name}
    Should Be Equal  ${state}  ${led_state}
