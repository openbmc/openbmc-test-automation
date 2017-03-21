*** Settings ***
Documentation  Test power on for HW CI.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/utils.robot
Resource            ../lib/state_manager.robot

Test Setup          Start SOL Console Logging
Test Teardown       Test Exit Logs

Force Tags  chassisboot

*** Variables ***

# User may pass LOOP_COUNT.
# By default 2 cycle for CI/CT.
${LOOP_COUNT}  ${2}

*** Test Cases ***

Power On Test
    [Documentation]  Power off and on.
    [Tags]  Power_On_Test

    Repeat Keyword  ${LOOP_COUNT} times  Host Off And On

*** Keywords ***

Test Exit Logs
    [Documentation]  Collect FFDC and SOL log.
    FFDC On Test Case Fail
    ${sol_log}=    Stop SOL Console Logging
    Log   ${sol_log}

Host Off And On
    [Documentation]  Verify power off and on.

    Initiate Host PowerOff
    Wait Until Keyword Succeeds  5 min  10 sec  Is OS Off

    # Add delay to wait for mailbox to reset before powering on
    # to minimize the watchdog reset error.
    Sleep  30s

    Initiate Host Boot
    Wait Until Keyword Succeeds  10 min  10 sec  Is OS Starting
