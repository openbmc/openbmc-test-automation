*** Settings ***

Documentation       Test reset reload functionality of BMC.

Resource            ../lib/rest_client.robot
Resource            ../lib/state_manager.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/utils.robot
Resource            ../lib/boot_utils.robot
Resource            ../lib/open_power_utils.robot
Library             ../lib/bmc_ssh_utils.py

Test Setup          Open Connection And Log In
Test Teardown       Test Teardown Execution

*** Variables ***

# Error strings to check from journald.
${ERROR_REGEX}   SEGV|core-dump

${LOOP_COUNT}  ${1}

*** Test Cases ***

Verify BMC Reset Reload With System On
    [Documentation]  Validate chassis "ON" and host "Running" state is
    ...  unchanged after BMC reset reload.
    [Tags]  Verify_BMC_Reset_Reload_With_System_On

    Initiate Host Boot

    Trigger Reset Reload via BMC Reboot

    ${rr_status}=  Check Reset Reload Status
    Should Be Equal  ${rr_status}  Yes

    Wait Until Keyword Succeeds  5 min  10 sec  Is OS Booted


Test Reset Reload When Host Booted
    [Documentation]  Reset reoad when host is booted.
    [Tags]  Test_Reset_Reload_When_Host_Booted
    #[Setup]  Scrub_Journald_logs

    Repeat Keyword  ${LOOP_COUNT} times   Reboot BMC And Check For Errors


*** Keywords ***

Reboot BMC And Check For Errors
    [Documentation]  Boot to OS, reboot BMC and verify OCC and logs.

    OBMC Reboot (run)

    Verify OCC State  ${1}

    #${journal_log}=  BMC Execute Command

    ${journal_log}=  Execute Command On BMC
    ...  journalctl --no-pager | egrep '${ERROR_REGEX}'

    Should Be Empty  ${journal_log}


Check Reset Reload Status
    [Documentation]  Returns reset reload status based on file presence.

    ${rr_status}=  Execute Command On BMC
    ...  test -e /run/openbmc/chassis@0-on && echo "Yes" || echo "No"
    [Return]  ${rr_status}


Trigger Reset Reload via BMC Reboot
    [Documentation]  Initiate Reset reload using BMC Reboot.

    Initiate BMC Reboot
    Wait Until Keyword Succeeds  10 min  10 sec  Is BMC Ready


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Close all open SSH connections.

    FFDC On Test Case Fail
    Close All Connections
