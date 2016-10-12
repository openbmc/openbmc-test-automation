*** Settings ***
Documentation   This suite verifies the power restore policy supported by
...             REST Interfaces.
...             Documentation on the REST interfaces can be refer from
...             https://github.com/openbmc/docs/blob/master/rest-api.md

Resource        ../lib/rest_client.robot
Resource        ../lib/pdu/pdu.robot
Resource        ../lib/utils.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/boot/boot_resource_master.robot


Library         SSHLibrary

Test Teardown   Log FFDC
Force Tags      chassisboot  bmcreboot

*** Variables ***
${HOST_SETTING}    /org/openbmc/settings/host0

*** Test Cases ***

Set the power restore policy
    #Policy                Expected System State     Next System State

    LEAVE_OFF              HOST_POWERED_OFF          HOST_POWERED_OFF
    LEAVE_OFF              HOST_BOOTED               HOST_POWERED_OFF
    ALWAYS_POWER_ON        HOST_POWERED_OFF          HOST_BOOTED
    ALWAYS_POWER_ON        HOST_BOOTED               HOST_BOOTED
    RESTORE_LAST_STATE     HOST_BOOTED               HOST_BOOTED
    RESTORE_LAST_STATE     HOST_POWERED_OFF          HOST_POWERED_OFF

    [Documentation]   Test to validate restore policy attribute functionality.
    ...               Policy:
    ...                     System policy to restore on power cycle
    ...               Expected System State:
    ...                     State where system should be before running the
    ...                     test case
    ...               Next System State:
    ...                     After Power cycle, the system should reach to
    ...                     this specific state

    [Template]    setRestorePolicy

***keywords***
setRestorePolicy
    [arguments]      ${policy}     ${expectedState}   ${nextState}

    ${valueDict} =     create dictionary  data=${policy}
    Write Attribute    ${HOST_SETTING}    power_policy   data=${valueDict}
    ${currentPolicy}=  Read Attribute     ${HOST_SETTING}   power_policy
    Should Be Equal    ${currentPolicy}   ${policy}

    ${currentState}=
    ...   Read Attribute   ${HOST_SETTING}   system_state

    Log   Current System State= ${currentState}
    Log   Expected System State= ${expectedState}
    Log   Next System State= ${nextState}

    Run Keyword If
    ...   '${currentState}' != '${expectedState}' and '${expectedState}' == 'HOST_BOOTED'
    ...   BMC Power On
    Run Keyword If
    ...   '${currentState}' != '${expectedState}' and '${expectedState}' == 'HOST_POWERED_OFF'
    ...   BMC Power Off

    Log    "Doing power cycle"
    PDU Power Cycle
    Check If BMC is Up   5 min    10 sec
    Log   "BMC is Online now"

    Wait Until Keyword Succeeds
    ...    5 min   10 sec   System State  ${nextState}


System State
    [arguments]     ${nextState}
    ${afterPduSystemState}=
    ...   Read Attribute    ${HOST_SETTING}    system_state
    Should be equal   ${afterPduSystemState}    ${nextState}
