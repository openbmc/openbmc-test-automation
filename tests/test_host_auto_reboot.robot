*** Settings ***

Documentation       Test auto reboot functionality of host.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/rest_client.robot
Resource            ../lib/state_manager.robot
Resource            ../lib/boot_utils.robot

Test Teardown       Test Teardown Execution
Suite Teardown      Suite Teardown Execution

*** Variables ***


*** Test Cases ***

Verify Host Quiesce State Without Auto Reboot During Boot
    # Description of template fields:
    # Auto Reboot   Initial Host State     Expected Host Action
    ${0}               Booting                No Reboot
    [Documentation]  Validate "Quiesce" state during IPL.
    [Tags]  Verify_Host_Quiesce_State_Without_Auto_Reboot_During_Boot
    [Template]  Verify Host Quiesce State


Verify Host Quiesce State With Auto Reboot During Boot
    # Description of template fields:
    # Auto Reboot   Initial Host State     Expected Host Action
    ${1}               Booting                Reboot
    [Documentation]  Validate "Quiesce" state during IPL.
    [Tags]  Verify_Host_Quiesce_State_With_Auto_Reboot_During_Boot
    [Template]  Verify Host Quiesce State


*** Keywords ***

Verify Host Quiesce State
    [Documentation]  Inject watchdog error on host to reach "Quiesce" state.
    ...  Later recover host from this state.
    [Arguments]  ${auto_reboot}  ${initial_host_state}  ${action}
    # Description of argument(s):
    # auto_reboot          Auto reboot setting
    #                      i.e 1 for enabling and 0 for disabling.
    # initial_host_state   State of host before injecting error.
    # action               Action of host due to error ("No Reboot" or
    #                      "Reboot").

    Set Auto Reboot  ${auto_reboot}

    Run Keyword If  '${initial_host_state}' == 'Booting'
    # Booting refers to host OS starting in progress.
    ...  Run Keywords  Get Boot Progress To OS Starting State

    Trigger Host Watchdog Error
    ${resp}=  Run Keyword And Return Status  Is Host Rebooted

    Run Keyword If  '${action}' == 'No Reboot'
    ...  Run Keywords  Should Be Equal  ${resp}  ${False}  AND
    ...  Wait Until Keyword Succeeds  3 min  5 sec  Is Host Quiesced  AND
    ...  Recover Quiesced Host
    ...  ELSE IF  '${action}' == 'Reboot'
    ...  Wait Until Keyword Succeeds  3 min  5 sec  Is Host Rebooted


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Set default value for auto reboot.
    ...  3. Close all open SSH connections.

    FFDC On Test Case Fail
    Set Auto Reboot  ${1}
    Close All Connections

Suite Teardown Execution
    [Documentation]  Do the suite test teardown.

    ${status}=  Is Host Quiesced
    Run Keyword If  ${status} == ${True}  Smart Power Off
