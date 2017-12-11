*** Settings ***
Documentation   This suite verifies the power restore policy supported by
...             REST Interfaces.
...             Refer here for documentation on the REST interfaces
...             https://github.com/openbmc/docs/blob/master/rest-api.md

Resource        ../lib/rest_client.robot
Resource        ../lib/utils.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/state_manager.robot
Library         ../lib/state_map.py


Library         SSHLibrary

Test Teardown   Test Teardown Execution
Suite Teardown  Suite Teardown Execution

Force Tags      power_restore

*** Variables ***

*** Test Cases ***

Test Restore Policy ALWAYS_POWER_OFF With Host Off
    # Policy                Initial Host State     Expected Host State

    ${ALWAYS_POWER_OFF}     Off                    Off

    [Documentation]  Validate ALWAYS_POWER_OFF restore policy functionality.
    ...              Policy:
    ...                    System policy set to ALWAYS_POWER_OFF.
    ...              Initial Host State:
    ...                    State where system should be before running the
    ...                    test case.
    ...              Expected Host State:
    ...                    After BMC reset, system should reach this
    ...                    specific state.

    [Template]  Verify Restore Policy
    [Tags]  Test_Restore_Policy_ALWAYS_POWER_OFF_With_Host_Off


Test Restore Policy ALWAYS_POWER_OFF With Host Running
    # Policy                Initial Host State     Expected Host State

    ${ALWAYS_POWER_OFF}     Running                Running

    [Template]  Verify Restore Policy
    [Tags]  Test_Restore_Policy_ALWAYS_POWER_OFF_With_Host_Running


Test Restore Policy ALWAYS_POWER_ON With Host Off
    # Policy                Initial Host State     Expected Host State

    ${ALWAYS_POWER_ON}      Off                    Running

    [Documentation]  Validate ALWAYS_POWER_ON restore policy functionality.
    ...              Policy:
    ...                    System policy set to ALWAYS_POWER_OFF.
    ...              Initial Host State:
    ...                    State where system should be before running the
    ...                    test case.
    ...              Expected Host State:
    ...                    After BMC reset, system should reach this
    ...                    specific state.

    [Template]  Verify Restore Policy
    [Tags]  Test_Restore_Policy_ALWAYS_POWER_ON_With_Host_Off


Test Restore Policy ALWAYS_POWER_ON With Host Running
    # Policy                Initial Host State     Expected Host State

    ${ALWAYS_POWER_ON}      Running                Running

    [Template]  Verify Restore Policy
    [Tags]  Test_Restore_Policy_ALWAYS_POWER_ON_With_Host_Running


Test Restore Policy Restore Last State With Host Running
    # Policy                Initial Host State     Expected Host State

    ${RESTORE_LAST_STATE}   Running                Running

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
    [Tags]  Test_Restore_Policy_Restore_Last_State_With_Host_Running


Test Restore Policy Restore Last State With Host Off
    # Policy                Initial Host State     Expected Host State

    ${RESTORE_LAST_STATE}   Off                    Off


    [Template]  Verify Restore Policy
    [Tags]  Test_Restore_Policy_Restore_Last_State_With_Host_Off


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

    Set Initial Test State  ${expectedState}

    ${initial_states}=  Get Boot State

    Initiate BMC Reboot

    Wait Until Keyword Succeeds
    ...  10 min  10 sec  Valid Boot States  ${initial_states}


Valid Boot States
    [Documentation]  Verify boot states for a given system state.
    [Arguments]  ${sys_state}

    # Description of argument(s):
    # sys_state    system state list
    #              (e.g.bmc,chassis,host,BootProgress,OperatingSystemState).

    ${current_state}=  Get Boot State
    Lists Should Be Equal  ${sys_state}  ${current_state}


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


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    # 1. Capture FFDC on test failure.
    # 2. Close all open SSH connections.

    FFDC On Test Case Fail
    Close All Connections


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.
    # 1. Set policy to default.

    Run Keyword And Ignore Error  Set BMC Power Policy  ${RESTORE_LAST_STATE}

