*** Settings ***

Documentation       This testsuite is for testing "Queisce" state.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/rest_client.robot
Resource            ../lib/state_manager.robot

Suite Setup         Open Connection And Log In

Test Teardown       Post Test Execution

*** Variables ***


*** Test Cases ***

Verify Quiesce State Without Auto Reboot
    #Auto Reboot   State     Status
    no             Off       No Reboot
    [Documentation]  Validate "Quiesce" state without auto reboot
    [Tags]  Verify_Quiesce_State_Without_Auto_Reboot
    [Template]  Inject Error For Quiesce State

Verify Quiesce State With Auto Reboot
    #Auto Reboot   State     Status
    yes            Off       Reboot
    [Documentation]  Validate "Quiesce" state with auto reboot.
    [Tags]  Verify_Quiesce_State_With_Auto_Reboot
    [Template]  Inject Error For Quiesce State

Verify Quiesce State Without Auto Reboot During IPL
    #Auto Reboot   State     Status
    yes            Running   No Reboot
    [Documentation]  Validate "Quiesce" state during IPL.
    [Tags]  Verify_Quiesce_State_Without_Auto_Reboot_During_IPL
    [Template]  Inject Error For Quiesce State

Verify Quiesce State With Auto Reboot During IPL
    #Auto Reboot   State     Status
    yes            Running   Reboot
    [Documentation]  Validate "Quiesce" state during IPL.
    [Tags]  Verify_Quiesce_State_With_Auto_Reboot_During_IPL
    [Template]  Inject Error For Quiesce State


*** Keywords ***

Trigger Host Watchdog Error
    [Documentation]  Inject host watchdog error using BMC.

    Execute Command On BMC
    ...  /usr/sbin/mapper call /org/openbmc/watchdog/host0 org.openbmc.Watchdog set i 1000
    Execute Command On BMC
    ...  /usr/sbin/mapper call /org/openbmc/watchdog/host0 org.openbmc.Watchdog start
    Sleep  5s

Inject Error For Quiesce State
    [Documentation]  Inject error on host to reach "Quiesce" state
    [Arguments]  ${auto_reboot}  ${state}  ${status}
    # auto_reboot  auto reboot setting
    # state        state of host before injecting error
    # status       status of host due to error i.e. No Reboot or Reboot

    Set Auto Reboot  ${auto_reboot}

    Run Keyword If  '${state}' == 'Off'
    ...  Put Current And Transition Host State  Off
    ...  ELSE IF  '${state}' == 'Running'
    ...  Put Current And Transition Host State  On

    Trigger Host Watchdog Error

    ${resp}=  Run Keyword And Return Status  Is Host Rebooted

    Run Keyword If  '${status}' == 'No Reboot'
    ...  Run Keywords
    ...  Should Be Equal  ${resp}  ${False}  AND
    ...  Wait Until Keyword Succeeds  5 min  5 sec  Is Host Quiesced  AND
    ...  Recover Quiesced State
    ...  ELSE IF  '${status}' == 'Reboot'
    ...  Wait Until Keyword Succeeds  5 min  5 sec  Is Host Rebooted


Put Current And Transition Host State
    [Documentation]  Put host in given state.
    [Arguments]  ${state}
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


Post Test Execution
    [Documentation]  Perform operations after test execution. Capture FFDC
    ...  in case of test case failure and sets default values for auto reboot.

    Run Keyword If Test Failed  FFDC On Test Case Fail
    Set Auto Reboot  yes
    Close All Connections
