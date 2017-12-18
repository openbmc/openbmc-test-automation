*** Settings ***

Documentation       Test reset reload functionality of BMC.

Resource            ../lib/rest_client.robot
Resource            ../lib/state_manager.robot
Resource            ../lib/openbmc_ffdc.robot

Test Setup          Open Connection And Log In
Test Teardown       Test Teardown Execution

*** Variables ***


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


*** Keywords ***

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
