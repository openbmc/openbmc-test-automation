*** Settings ***
Documentation       This module will test basic power on use cases for CI

Resource            ../lib/boot/boot_resource_master.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/utils.robot

Test Setup          Start SOL Console Logging
Test Teardown       Test Exit Logs

Force Tags  chassisboot

*** Test Cases ***

power on test
    [Documentation]    Power OFF and power ON
    [Tags]  power_on_test

    BMC Power Off
    BMC Power On

*** Keywords ***
Test Exit Logs
    [Documentation]    Log FFDC if failed and collect SOL
    ...                Logs for debugging purpose.
    FFDC On Test Case Fail
    ${sol_log}=    Stop SOL Console Logging
    Log   ${sol_log}
