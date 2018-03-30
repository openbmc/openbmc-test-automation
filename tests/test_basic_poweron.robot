*** Settings ***
Documentation  Test power on for HW CI.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/utils.robot
Resource            ../lib/state_manager.robot
Resource            ../lib/open_power_utils.robot
Resource            ../lib/ipmi_client.robot
Resource            ../lib/boot_utils.robot

Test Setup          Test Setup Execution
Test Teardown       Test Teardown Execution

Force Tags  chassisboot

*** Variables ***

# User may pass LOOP_COUNT.
# By default 2 cycle for CI/CT.
${LOOP_COUNT}  ${2}

# Error strings to check from journald.
${ERROR_REGEX}   SEGV|core-dump

*** Test Cases ***

Verify Front And Rear LED At Standby
    [Documentation]  Front and Read LED should be off at standby.
    [Tags]  Verify_Front_And_Rear_LED_At_Standby

    REST Power Off  stack_mode=skip  quiet=1
    Verify Identify LED State  Off

Power On Test
   y[Documentation]  Power off and on.
    [Tags]  Power_On_Test

    Repeat Keyword  ${LOOP_COUNT} times  Host Off And On

Check For Application Failures
    [Documentation]  Parse the journal log and check for failures.
    [Tags]  Check_For_Application_Failures

    Open Connection And Log In

    ${journal_log}=  Execute Command On BMC
    ...  journalctl --no-pager | egrep '${ERROR_REGEX}'

    Should Be Empty  ${journal_log}

Test SSH And IPMI Connections
    [Documentation]  Try SSH and IPMI commands to verify each connection.
    [Tags]  Test_SSH_And_IPMI_Connections

    Check If BMC Is Up  3 min  20 sec
    Wait Until Keyword Succeeds
    ...  3 min  30 sec  Wait for BMC state  Ready

    BMC Execute Command  true
    Run IPMI Standard Command  chassis status

*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.
    Start SOL Console Logging
    Set Auto Reboot  ${0}

Test Teardown Execution
    [Documentation]  Collect FFDC and SOL log.
    FFDC On Test Case Fail
    ${sol_log}=    Stop SOL Console Logging
    Log   ${sol_log}
    Set Auto Reboot  ${1}

Host Off And On
    [Documentation]  Verify power off and on.

    Initiate Host PowerOff

    Initiate Host Boot
    Verify OCC State

    # TODO: Host shutdown race condition.
    # Wait 30 seconds before Powering Off.
    Sleep  30s
