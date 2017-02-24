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
    [Documentation]  Validate "Quiesce" state without auto reboot
    [Tags]  Quiesce_State_Without_Auto_Reboot

    Set Auto Reboot  no

    Initiate Host PowerOff
    Wait Until Keyword Succeeds  3 min  10 sec  Is Host Off

    Start Journal Log

    Trigger Host Watchdog Error

    ${output}=  Stop Journal Log
    Should Contain  ${output}  Auto reboot disabled. Maintaining quiesce


Quiesce State With Auto Reboot
    [Documentation]  Validate "Quiesce" state with auto reboot.
    [Tags]  Quiesce_State_With_Auto_Reboot

    Set Auto Reboot  yes

    Initiate Host PowerOff
    Wait Until Keyword Succeeds  3 min  10 sec  Is Host Off

    Start Journal Log

    Trigger Host Watchdog Error

    Wait Until Keyword Succeeds  3 min  1 sec  Is Host Off
    Wait Until Keyword Succeeds  3 min  1 sec  Is Host Running

    ${output}=  Stop Journal Log
    Should Contain  ${output}  Reached target Quiesce Target


Quiesce State During IPL
    [Documentation]  Validate "Quiesce" state during IPL.
    [Tags]  Quiesce_State_During_IPL

    Set Auto Reboot  yes

    Initiate Host Boot
    Wait Until Keyword Succeeds  3 min  10 sec  Is Host Running

    Start Journal Log

    Trigger Host Watchdog Error

    Wait Until Keyword Succeeds  3 min  1 sec  Is Host Off
    Wait Until Keyword Succeeds  3 min  1 sec  Is Host Running

    ${output}=  Stop Journal Log
    Should Contain  ${output}  Reached target Quiesce Target


*** Keywords ***

Trigger Host Watchdog Error
    [Documentation]  Inject host watchdog error using BMC.

    Execute Command On BMC
    ...  /usr/sbin/mapper call /org/openbmc/watchdog/host0 org.openbmc.Watchdog set i 1000

    Execute Command On BMC
    ...  /usr/sbin/mapper call /org/openbmc/watchdog/host0 org.openbmc.Watchdog start
    Sleep  1s

Post Test Execution
    [Documentation]  Perform operations after test execution. Capture FFDC
    ...  in case of test case failure and sets default values for auto reboot.

    Run Keyword If Test Failed  FFDC On Test Case Fail

    Initiate Host PowerOff
    Wait Until Keyword Succeeds  3 min  10 sec  Is Host Off

    Set Auto Reboot  yes

    Close All Connections
