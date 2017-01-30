*** Settings ***
Documentation  Test power on for HW CI.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/utils.robot
Resource            ../lib/state_manager.robot

Test Setup          Start SOL Console Logging
Test Teardown       Test Exit Logs

Force Tags  chassisboot

*** Test Cases ***

Power On Test
    [Documentation]  Power off and on.
    [Tags]  Power_On_Test

    Initiate Host PowerOff
    Initiate Host Boot

*** Keywords ***

Test Exit Logs
    [Documentation]  Collect FFDC and SOL log.
    FFDC On Test Case Fail
    ${sol_log}=    Stop SOL Console Logging
    Log   ${sol_log}
