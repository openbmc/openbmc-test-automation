*** Settings ***

Documentation       This testsuite is for testing "Queisce" state.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/rest_client.robot
Resource            ../lib/state_manager.robot

Suite Setup         Open Connection And Log In

Test Teardown       Post Test Execution

*** Variables ***


*** Test Cases ***

Quiesce State Without Auto Reboot
    #Auto Reboot   Start State   Status
    no             Off           No change
    [Documentation]  Validate "Quiesce" state without auto reboot
    [Tags]  Quiesce_State_Without_Auto_Reboot
    [Template]  Inject Error For Quiesce State

Quiesce State With Auto Reboot
    #Auto Reboot   Start State   Status
    yes            Off           Reboot
    [Documentation]  Validate "Quiesce" state with auto reboot.
    [Tags]  Quiesce_State_With_Auto_Reboot
    [Template]  Inject Error For Quiesce State

Quiesce State During IPL
    #Auto Reboot   Start State   Status
    yes            Running       Reboot
    [Documentation]  Validate "Quiesce" state during IPL.
    [Tags]  Quiesce_State_During_IPL
    [Template]  Inject Error For Quiesce State


*** Keywords ***

Trigger Host Watchdog Error
    [Documentation]  Inject host watchdog error using BMC.

    Execute Command On BMC
    ...  /usr/sbin/mapper call /org/openbmc/watchdog/host0 org.openbmc.Watchdog set i 1000

    Execute Command On BMC
    ...  /usr/sbin/mapper call /org/openbmc/watchdog/host0 org.openbmc.Watchdog start


Inject Error For Quiesce State
    [Documentation]  Inject error on host to reach "Quiesce" state
    [Arguments]  ${auto_reboot}  ${start_state}  ${status}
    # auto_reboot  auto reboot setting
    # start_state  state of host before injecting error
    # status       status of host due to error i.e. No change or Reboot

    Set Auto Reboot  ${auto_reboot}

    Run Keyword If  '${start_state}' == 'Off'
    ...  Put Current And Transition Host State  Off
    ...  ELSE IF  '${start_state}' == 'Running'
    ...  Put Current And Transition Host State  On

    Start Journal Log

    Trigger Host Watchdog Error
    Sleep  1min

    ${end_state}=  Get Host State
    Run Keyword If  '${status}' == 'no change'
    ...  Should Be Equal  ${end_state}  ${start_state}
    ...  ELSE IF  '${status}' == 'Reboot'
    ...  Wait Until Keyword Succeeds  5 min  5 sec  Is Host Rebooted

    ${output}=  Stop Journal Log
    Should Contain  ${output}  Reached target Quiesce Target


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
    Initiate Host PowerOff
    Set Auto Reboot  yes
    Close All Connections
