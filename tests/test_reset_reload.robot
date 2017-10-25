*** Settings ***

Documentation       Test reset reload functionality of BMC.

Resource            ../lib/rest_client.robot
Resource            ../lib/state_manager.robot
Resource            ../lib/openbmc_ffdc.robot

Test Setup          Open Connection And Log In
Test Teardown       Post Testcase Execution

*** Variables ***


*** Test Cases ***

Verify BMC Reset Reload With System On
    [Documentation]  Validate chassis "ON" and host "Running" state is
    ...  unchanged after BMC reset reload.
    [Tags]  Verify_BMC_Reset_Reload_With_System_On

    Initiate Host Boot
    Wait Until Keyword Succeeds  5 min  10 sec  Is Chassis On
    ${chassis_state_before}=  Run Keyword  Get Chassis Power State

    Trigger Reset Reload via BMC Reboot

    ${chassis_state_after}=  Run Keyword  Get Chassis Power State
    ${rr_status}=  Run Keyword  Check Reset Reload Status

    Should Be Equal  ${chassis_state_before}  ${chassis_state_after}
    Should Be Equal  ${rr_status}  Yes

    ${host_state}=  Run Keyword  Get Host State
    Should Be Equal  ${host_state}  Running


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


Post Testcase Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Close all open SSH connections.

    FFDC On Test Case Fail
    Close All Connections
