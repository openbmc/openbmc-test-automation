*** Settings ***

Documentation       Test auto reboot functionality of host.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/rest_client.robot
Resource            ../lib/state_manager.robot

Test Setup          Open Connection And Log In
Test Teardown       Post Testcase Execution

*** Variables ***


*** Test Cases ***

Verify Host Quiesce State Without Auto Reboot During Boot
    # Description of template fields:
    # Auto Reboot   Host State     Expected Host Action
    no              Booting        No Reboot
    [Documentation]  Validate "Quiesce" state during IPL.
    [Tags]  Verify_Host_Quiesce_State_Without_Auto_Reboot_During_Boot
    [Template]  Verify Host Quiesce State


Verify Host Quiesce State With Auto Reboot During Boot
    # Description of template fields:
    # Auto Reboot   Host State     Expected Host Action
    yes             Booting        Reboot
    [Documentation]  Validate "Quiesce" state during IPL.
    [Tags]  Verify_Host_Quiesce_State_With_Auto_Reboot_During_Boot
    [Template]  Verify Host Quiesce State


*** Keywords ***

Verify Host Quiesce State
    [Documentation]  Inject watchdog error on host to reach "Quiesce" state.
    ...  Later recover host from this state.
    [Arguments]  ${auto_reboot}  ${host_state}  ${action}
    # Description of Arguments:
    # auto_reboot  Auto reboot setting ("yes" or "no").
    # host_state   State of host before injecting error.
    # action       Action of host due to error ("No Reboot" or "Reboot").

    Set Auto Reboot  ${auto_reboot}

    Run Keyword If  '${host_state}' == 'Off'  Initiate Host PowerOff
    ...  ELSE IF  '${host_state}' == 'Booting'
    ...  Run Keywords  Initiate Host PowerOff  AND  Initiate Host Boot

    Trigger Host Watchdog Error
    ${resp}=  Run Keyword And Return Status  Is Host Rebooted

    Run Keyword If  '${action}' == 'No Reboot'
    ...  Run Keywords  Should Be Equal  ${resp}  ${False}  AND
    ...  Wait Until Keyword Succeeds  3 min  5 sec  Is Host Quiesced  AND
    ...  Recover Quiesced Host
    ...  ELSE IF  '${action}' == 'Reboot'
    ...  Wait Until Keyword Succeeds  3 min  5 sec  Is Host Rebooted


Post Testcase Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Set default value for auto reboot.
    ...  3. Close all open SSH connections.

    FFDC On Test Case Fail
    Set Auto Reboot  yes
    Close All Connections
