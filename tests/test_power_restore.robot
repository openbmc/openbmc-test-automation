*** Settings ***
Documentation   This suite verifies the power restore policy supported by
...             REST Interfaces.
...             Refer here for documentation on the REST interfaces
...             https://github.com/openbmc/docs/blob/master/rest-api.md

Resource        ../lib/rest_client.robot
Resource        ../lib/utils.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/state_manager.robot


Library         SSHLibrary

Test Teardown   Post Test Case Execution
Suite Teardown  Post Test Suite Execution

Force Tags      power_restore

*** Variables ***

*** Test Cases ***

Test Restore Policy LEAVE_OFF
    #Policy                Initial Host State     Expected Host State

    LEAVE_OFF              Off                       Off
    #LEAVE_OFF              Running                   Off

    [Documentation]  Validate LEAVE_OFF restore policy functionality.
    ...              Policy:
    ...                    System policy set to LEAVE_OFF.
    ...              Initial Host State:
    ...                    State where system should be before running the
    ...                    test case.
    ...              Expected Host State:
    ...                    After BMC reset, system should reach this
    ...                    specific state.

    [Template]  Verify Restore Policy


Test Restore Policy ALWAYS_POWER_ON
    #Policy                Initial Host State     Expected Host State

    ALWAYS_POWER_ON        Off                       Running
    ALWAYS_POWER_ON        Running                   Running

    [Documentation]  Validate ALWAYS_POWER_ON restore policy functionality.
    ...              Policy:
    ...                    System policy set to LEAVE_OFF.
    ...              Initial Host State:
    ...                    State where system should be before running the
    ...                    test case.
    ...              Expected Host State:
    ...                    After BMC reset, system should reach this
    ...                    specific state.

    [Template]  Verify Restore Policy


Test Restore Policy RESTORE_LAST_STATE
    #Policy                Initial Host State     Expected Host State

    RESTORE_LAST_STATE     Running                   Running
    RESTORE_LAST_STATE     Off                       Off

    [Documentation]  Validate RESTORE_LAST_STATE restore policy functionality.
    ...              Policy:
    ...                    System policy set to RESTORE_LAST_STATE.
    ...              Initial Host State:
    ...                    State where system should be before running the
    ...                    test case.
    ...              Expected Host State:
    ...                    After BMC reset, system should reach this
    ...                    specific state.

    [Template]  Verify Restore Policy

*** Keywords ***

Verify Restore Policy
    [Documentation]  Set given policy, reset BMC and expect specified end
    ...              state.
    [Arguments]  ${policy}  ${expectedState}  ${nextState}

    # Description of argument(s):
    # policy           System policy state string.
    # expectedState    Test initial host state.
    # nextState        Test end host state.

    Set BMC Power Policy  ${policy}

    ${currentState}=  Get Host State

    Log  Current System State= ${currentState}
    Log  Initial Host State= ${expectedState}
    Log  Expected Host State= ${nextState}

    Run Keyword If
    ...  '${currentState}' != '${expectedState}'
    ...  Set Initial Test State  ${expectedState}

    # TBD: Replace reboot with 'Initiate BMC Reboot' keyword
    # Reference: openbmc/openbmc#1161
    Open Connection And Log In
    Start Command   /sbin/reboot

    Wait Until Keyword Succeeds
    ...  5 min  10 sec  Is BMC Ready

    Wait Until Keyword Succeeds
    ...  10 min  10 sec  Verify Host State  ${nextState}


Set Initial Test State
    [Documentation]  Poweron if ON expected, Poweroff if OFF expected
    ...              to initial state of the test.

    [Arguments]  ${expectedState}
    # Description of argument(s):
    # expectedState    Test initial host state.

    Run Keyword If  '${expectedState}' == 'Running'
    ...  Initiate Host Boot

    Run Keyword If  '${expectedState}' == 'Off'
    ...  Initiate Host PowerOff


    ${currentState}=  Get Host State


Verify Host State
    [Documentation]  Verify expected host state.
    [Arguments]  ${expectedState}

    # Description of argument(s):
    # expectedState   Expected host state.
    ${currentState}=  Get Host State
    Should Be Equal  ${currentState}  ${expectedState}


Post Test Case Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Close all open SSH connections.

    FFDC On Test Case Fail
    Close All Connections


Post Test Suite Execution
    [Documentation]  Do the post suite teardown.
    ...  1. Set policy to default.

    Run Keyword And Ignore Error  Set BMC Power Policy  RESTORE_LAST_STATE

