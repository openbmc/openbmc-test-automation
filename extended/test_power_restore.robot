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


Library         SSHLibrary

Test Teardown   FFDC On Test Case Fail
Force Tags      chassisboot  bmcreboot

*** Variables ***
${HOST_SETTING}    ${OPENBMC_BASE_URI}settings/host0

*** Test Cases ***

Set the power restore policy
    #Policy                Expected System State     Next System State

    LEAVE_OFF              HOST_POWERED_OFF          BMC_READY
    LEAVE_OFF              HOST_BOOTED               BMC_READY
    ALWAYS_POWER_ON        HOST_POWERED_OFF          HOST_BOOTED
    ALWAYS_POWER_ON        HOST_BOOTED               HOST_BOOTED
    RESTORE_LAST_STATE     HOST_BOOTED               HOST_BOOTED
    RESTORE_LAST_STATE     HOST_POWERED_OFF          BMC_READY

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

    Set Policy Setting   ${policy}

    ${currentState}=  Get BMC State

    Log   Current System State= ${currentState}
    Log   Expected System State= ${expectedState}
    Log   Next System State= ${nextState}

    Run Keyword If
    ...   '${currentState}' != '${expectedState}'
    ...   Set Initial Test State   ${expectedState}

    Log   "Doing power cycle"
    PDU Power Cycle
    Check If BMC is Up   5 min    10 sec
    Log   "BMC is Online now"

    Wait Until Keyword Succeeds
    ...   5 min   10 sec   Verify BMC State  ${nextState}


Set Policy Setting
    [Documentation]   Set the given test policy
    [Arguments]   ${policy}

    ${valueDict}=     create dictionary  data=${policy}
    Write Attribute    ${HOST_SETTING}    power_policy   data=${valueDict}
    ${currentPolicy}=  Read Attribute     ${HOST_SETTING}   power_policy
    Should Be Equal    ${currentPolicy}   ${policy}


Set Initial Test State
    [Documentation]   Poweron if ON expected, Poweroff if OFF expected
    ...               to initial state of the test.
    [Arguments]   ${expectedState}

    Run Keyword If
    ...   '${expectedState}' == 'HOST_BOOTED'
    ...   BMC Power On

    Run Keyword If
    ...   '${expectedState}' == 'HOST_POWERED_OFF'
    ...   BMC Power Off


System State
    [Arguments]     ${nextState}
    ${afterPduSystemState}=
    ...   Read Attribute    ${HOST_SETTING}    system_state
    Should be equal   ${afterPduSystemState}    ${nextState}

