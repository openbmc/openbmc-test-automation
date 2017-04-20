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

Test Teardown   FFDC On Test Case Fail
Force Tags      power_restore

*** Variables ***

*** Test Cases ***

Test Restore Policy LEAVE_OFF
    #Policy                Expected System State     Next System State

    LEAVE_OFF              Off                       Off
    LEAVE_OFF              Running                   Off

    [Documentation]  Validate LEAVE_OFF restore policy functionality.
    ...              Policy:
    ...                    System policy set to LEAVE_OFF.
    ...              Expected System State:
    ...                    State where system should be before running the
    ...                    test case.
    ...              Next System State:
    ...                    After BMC reset, system should reach this
    ...                    specific state.

    [Template]  Verify Restore Policy


Test Restore Policy ALWAYS_POWER_ON
    #Policy                Expected System State     Next System State

    ALWAYS_POWER_ON        Off                       Running
    ALWAYS_POWER_ON        Running                   Running

    [Documentation]  Validate ALWAYS_POWER_ON restore policy functionality.
    ...              Policy:
    ...                    System policy set to LEAVE_OFF.
    ...              Expected System State:
    ...                    State where system should be before running the
    ...                    test case.
    ...              Next System State:
    ...                    After BMC reset, system should reach this
    ...                    specific state.

    [Template]  Verify Restore Policy


Test Restore Policy RESTORE_LAST_STATE
    #Policy                Expected System State     Next System State

    RESTORE_LAST_STATE     Running                   Running
    RESTORE_LAST_STATE     Off                       Off

    [Documentation]  Validate RESTORE_LAST_STATE restore policy functionality.
    ...              Policy:
    ...                    System policy set to RESTORE_LAST_STATE.
    ...              Expected System State:
    ...                    State where system should be before running the
    ...                    test case.
    ...              Next System State:
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
    Log  Expected System State= ${expectedState}
    Log  Next System State= ${nextState}

    Run Keyword If
    ...  '${currentState}' != '${expectedState}'
    ...  Set Initial Test State  ${expectedState}

    Initiate BMC Reboot

    Wait Until Keyword Succeeds
    ...  5 min  10 sec  Is BMC Ready


Set Initial Test State
    [Documentation]   Poweron if ON expected, Poweroff if OFF expected
    ...               to initial state of the test.

    [Arguments]  ${expectedState}
    # Description of argument(s):
    # expectedState    Test initial host state.

    Run Keyword If  '${expectedState}' == 'Running'
    ...  Initiate Host Boot

    Run Keyword If  '${expectedState}' == 'Off'
    ...  Initiate Host PowerOff
