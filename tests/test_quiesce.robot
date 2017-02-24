*** Settings ***

Documentation       Test "Quiesce" state.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/rest_client.robot
Resource            ../lib/state_manager.robot

Test Setup          Open Connection And Log In
Test Teardown       Post Testcase Execution

*** Variables ***


*** Test Cases ***

Verify Quiesce State Without Auto Reboot
    # Description of template fields:
    #Auto Reboot   Host State     Expected Host Action
    no             Off            No Reboot
    [Documentation]  Validate "Quiesce" state without auto reboot.
    [Tags]  Verify_Quiesce_State_Without_Auto_Reboot
    [Template]  Verify Quiesce State

Verify Quiesce State With Auto Reboot
    # Description of template fields:
    #Auto Reboot   Host State     Expected Host Action
    yes            Off            Reboot
    [Documentation]  Validate "Quiesce" state with auto reboot.
    [Tags]  Verify_Quiesce_State_With_Auto_Reboot
    [Template]  Verify Quiesce State

Verify Quiesce State Without Auto Reboot During IPL
    # Description of template fields:
    #Auto Reboot   Host State     Expected Host Action
    no             Running        No Reboot
    [Documentation]  Validate "Quiesce" state during IPL.
    [Tags]  Verify_Quiesce_State_Without_Auto_Reboot_During_IPL
    [Template]  Verify Quiesce State

Verify Quiesce State With Auto Reboot During IPL
    # Description of template fields:
    #Auto Reboot   Host State     Expected Host Action
    yes            Running        Reboot
    [Documentation]  Validate "Quiesce" state during IPL.
    [Tags]  Verify_Quiesce_State_With_Auto_Reboot_During_IPL
    [Template]  Verify Quiesce State


*** Keywords ***

Verify Quiesce State
    [Documentation]  Inject watchdog error on host to reach "Quiesce" state.
    ...  Later recover host from this state.
    [Arguments]  ${auto_reboot}  ${state}  ${action}
    # Description of Arguments:
    # auto_reboot  auto reboot setting
    # state        state of host before injecting error
    # action       action of host due to error i.e. No Reboot or Reboot

    Set Auto Reboot  ${auto_reboot}

    Run Keyword If  '${state}' == 'Off'
    ...  Put Current And Transition Host State  Off
    ...  ELSE IF  '${state}' == 'Running'
    ...  Put Current And Transition Host State  On

    Trigger Host Watchdog Error
    ${resp}=  Run Keyword And Return Status  Is Host Rebooted

    Run Keyword If  '${action}' == 'No Reboot'
    ...  Run Keywords
    ...  Should Be Equal  ${resp}  ${False}  AND
    ...  Wait Until Keyword Succeeds  3 min  5 sec  Is Host Quiesced  AND
    ...  Recover Quiesced State
    ...  ELSE IF  '${action}' == 'Reboot'
    ...  Wait Until Keyword Succeeds  3 min  5 sec  Is Host Rebooted


Put Current And Transition Host State
    [Documentation]  Put host in given state.
    [Arguments]  ${state}
    # Description of Arguments:
    # state - expected host state

    Run Keyword If  '${state}' == 'On'
    ...  Run Keywords
    ...  Initiate Host PowerOff  AND
    ...  Initiate Host Boot
    ...  ELSE IF  '${state}' == 'Off'
    ...  Run Keywords
    ...  Initiate Host Boot  AND
    ...  Initiate Host PowerOff

    ${host_trans_state}=  Get Host Trans State
    Should Be Equal  ${host_trans_state}  ${state}


Post Testcase Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Set default value for auto reboot.
    ...  3. Close all open SSH connections.

    Run Keyword If Test Failed  FFDC On Test Case Fail
    Set Auto Reboot  yes
    Close All Connections
