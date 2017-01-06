*** Settings ***
Documentation   This suite verifies the power restore policy supported by
...             REST Interfaces.
...             Refer here for documentation on the REST interfaces
...             https://github.com/openbmc/docs/blob/master/rest-api.md

Resource        ../lib/rest_client.robot
Resource        ../lib/pdu/pdu.robot
Resource        ../lib/utils.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/boot/boot_resource_master.robot
Resource        ../lib/state_manager.robot


Library         SSHLibrary

Test Teardown   FFDC On Test Case Fail
Force Tags      chassisboot  bmcreboot

*** Variables ***

*** Test Cases ***

Set the power restore policy
    #Policy                Expected System State     Next System State

    LEAVE_OFF              Off                       Off
    LEAVE_OFF              Running                   Off
    ALWAYS_POWER_ON        Off                       Running
    ALWAYS_POWER_ON        Running                   Running
    RESTORE_LAST_STATE     Running                   Running
    RESTORE_LAST_STATE     Off                       Off

    [Documentation]   Test to validate restore policy attribute functionality.
    ...               Policy:
    ...                     System policy to restore on power cycle
    ...               Expected System State:
    ...                     State where system should be before running the
    ...                     test case
    ...               Next System State:
    ...                     After power cycle, system should reach this
    ...                     specific state

    [Template]    Set Restore Policy

*** Keywords ***

Set Restore Policy
    [Arguments]    ${policy}   ${expectedState}   ${nextState}

    Set BMC Power Policy    ${policy}

    ${currentState}=  Get Host State

    Log   Current System State= ${currentState}
    Log   Expected System State= ${expectedState}
    Log   Next System State= ${nextState}

    Run Keyword If
    ...   '${currentState}' != '${expectedState}'
    ...   Set Initial Test State   ${expectedState}

    Log   "Doing power cycle"
    PDU Power Cycle
    Check If BMC is Up  5 min  10 sec
    Log   "BMC is Online now"

    Wait Until Keyword Succeeds
    ...  5 min  10 sec  Is BMC Ready


Set Initial Test State
    [Documentation]   Poweron if ON expected, Poweroff if OFF expected
    ...               to initial state of the test.
    [Arguments]   ${expectedState}

    Run Keyword If
    ...   '${expectedState}' == 'Running'
    ...   Initiate Host Boot

    Run Keyword If
    ...   '${expectedState}' == 'Off'
    ...   Initiate Host PowerOff
