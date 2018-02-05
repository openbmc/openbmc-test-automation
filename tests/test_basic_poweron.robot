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

Power On Test
    [Documentation]  Power off and on.
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

    BMC Execute Command  true
    Run IPMI Standard Command  chassis status

Verify Uptime Average Against Threshold
    [Documentation]  Compare BMC average boot time to a constant threshold.
    [Tags]  Verify_Uptime_Average_Against_Threshold

    ${uptime_total}=  Convert To Integer  0

    : FOR  ${index}  IN RANGE  0  3
    \  OBMC Reboot (off)
    \  ${uptime}=  Measure BMC Boot Time
    \  ${uptime_average}=  Evaluate  ${uptime_total}+${uptime}

    ${uptime_average}=  Evaluate  ${uptime_total}/3
    Should Be True  ${uptime_average} < 180
    ...  msg=${uptime_average} exceeds threshold.

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

Measure BMC Boot Time
    [Documentation]  Reboot the BMC and collect uptime.

    Open Connection And Log In
    ${uptime}=
    ...   Execute Command    cut -d " " -f 1 /proc/uptime| cut -d "." -f 1
    ${uptime}=  Convert To Integer  ${uptime}
    [return]  ${uptime}
