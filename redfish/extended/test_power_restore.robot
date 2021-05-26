*** Settings ***
Documentation   This suite verifies the power restore policy supported by
...             REST Interfaces.
...             Refer here for documentation on the REST interfaces
...             https://github.com/openbmc/docs/blob/master/rest-api.md

Resource        ../../lib/rest_client.robot
Resource        ../../lib/utils.robot
Resource        ../../lib/openbmc_ffdc.robot
Resource        ../../lib/state_manager.robot
Resource        ../../lib/boot_utils.robot
Resource        ../../lib/bmc_redfish_resource.robot
Resource        ../../lib/bmc_redfish_utils.robot
Library         ../../lib/state_map.py

Test Teardown   Test Teardown Execution
Suite Teardown  Suite Teardown Execution

Force Tags      power_restore

*** Variables ***

*** Test Cases ***

Test Restore Policy ALWAYS_POWER_OFF With Host Off
    [Documentation]  Validate ALWAYS_POWER_OFF restore policy functionality.
    ...              Policy:
    ...                    System policy set to ALWAYS_POWER_OFF.
    ...              Initial Host State:
    ...                    State where system should be before running the
    ...                    test case.
    ...              Expected Host State:
    ...                    After BMC reset, system should reach this
    ...                    specific state.
    [Tags]  Test_Restore_Policy_ALWAYS_POWER_OFF_With_Host_Off
    [Template]  Verify Restore Policy

    # Policy                Initial Host State     Expected Host State
    AlwaysOff               Off                    Off



Test Restore Policy ALWAYS_POWER_OFF With Host Running
    [Documentation]  Verify that the BMC restore policy is ALWAYS_POWER_OFF while the Host is running.
    [Tags]  Test_Restore_Policy_ALWAYS_POWER_OFF_With_Host_Running
    [Template]  Verify Restore Policy

    # Policy                Initial Host State     Expected Host State
    AlwaysOff               Running                Running


Test Restore Policy ALWAYS_POWER_ON With Host Off
    [Documentation]  Validate ALWAYS_POWER_ON restore policy functionality.
    ...              Policy:
    ...                    System policy set to ALWAYS_POWER_OFF.
    ...              Initial Host State:
    ...                    State where system should be before running the
    ...                    test case.
    ...              Expected Host State:
    ...                    After BMC reset, system should reach this
    ...                    specific state.
    [Tags]  Test_Restore_Policy_ALWAYS_POWER_ON_With_Host_Off
    [Template]  Verify Restore Policy

    # Policy                Initial Host State     Expected Host State
    AlwaysOn                Off                    Running



Test Restore Policy ALWAYS_POWER_ON With Host Running
    [Documentation]  Verify the BMC restore policy is ALWAYS_POWER_ON while the Host is running.
    [Tags]  Test_Restore_Policy_ALWAYS_POWER_ON_With_Host_Running
    [Template]  Verify Restore Policy

    # Policy                Initial Host State     Expected Host State
    AlwaysOn                Running                Running



Test Restore Policy Restore Last State With Host Running
    [Documentation]  Validate RESTORE_LAST_STATE restore policy functionality.
    ...              Policy:
    ...                    System policy set to RESTORE_LAST_STATE.
    ...              Initial Host State:
    ...                    State where system should be before running the
    ...                    test case.
    ...              Expected Host State:
    ...                    After BMC reset, system should reach this
    ...                    specific state.
    [Tags]  Test_Restore_Policy_Restore_Last_State_With_Host_Running
    [Template]  Verify Restore Policy

    # Policy                Initial Host State     Expected Host State
    LastState               Running                Running



Test Restore Policy Restore Last State With Host Off
    [Documentation]  Verify the RESTORE_LAST_STATE restore policy functionality while the Host is off.
    [Tags]  Test_Restore_Policy_Restore_Last_State_With_Host_Off
    [Template]  Verify Restore Policy

    # Policy                Initial Host State     Expected Host State
    LastState               Off                    Off


*** Keywords ***

Verify Restore Policy
    [Documentation]  Set given policy, reset BMC and expect specified end
    ...              state.
    [Arguments]  ${policy}  ${expectedState}  ${nextState}

    # Description of argument(s):
    # policy           System policy state string.
    # expectedState    Test initial host state.
    # nextState        Test end host state.

    Set Initial Test State  ${expectedState}

    Redfish Set Power Restore Policy  ${policy}

    Redfish BMC Reset Operation
    Sleep  20s
    Wait For BMC Online

    Wait Until Keyword Succeeds
    ...  10 min  20 sec  Valid Boot States  ${nextState}


Valid Boot States
    [Documentation]  Verify boot states for a given system state.
    [Arguments]  ${sys_state}

    # Description of argument(s):
    # sys_state    system state list
    #              (e.g. "Off", "On", "Reboot", etc.).

    ${current_state}=  Redfish Get States
    Redfish Valid Boot State  ${sys_state}  ${current_state}


Set Initial Test State
    [Documentation]  Poweron if ON expected, Poweroff if OFF expected
    ...              to initial state of the test.

    [Arguments]  ${expectedState}
    # Description of argument(s):
    # expectedState    Test initial host state.

    Redfish.Login

    Run Keyword If  '${expectedState}' == 'Running'
    ...  Redfish Power On  stack_mode=skip

    Run Keyword If  '${expectedState}' == 'Off'
    ...  Redfish Power Off  stack_mode=skip


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    # 1. Capture FFDC on test failure.
    # 2. Close all open SSH connections.

    FFDC On Test Case Fail
    Close All Connections


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.
    # 1. Set policy to default.

    Run Keyword And Ignore Error  Redfish Set Power Restore Policy  AlwaysOff
    Redfish.Logout


Wait For BMC Online
    [Documentation]  Wait for Host to be online. Checks every X seconds
    ...              interval for Y minutes and fails if timed out.
    ...              Default MAX timedout is 10 min, interval 10 seconds.
    [Arguments]      ${max_timeout}=${OPENBMC_REBOOT_TIMEOUT} min
    ...              ${interval}=10 sec

    # Description of argument(s):
    # max_timeout   Maximum time to wait.
    #               This should be expressed in Robot Framework's time format
    #               (e.g. "10 minutes").
    # interval      Interval to wait between status checks.
    #               This should be expressed in Robot Framework's time format
    #               (e.g. "5 seconds").

    Wait Until Keyword Succeeds
    ...   ${max_timeout}  ${interval}  Verify Ping SSH And Redfish Authentication
