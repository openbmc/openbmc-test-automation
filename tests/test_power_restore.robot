*** Settings ***
Documentation   This suite will verifiy the power restore policy rest
...             Interfaces
...             Details of valid interfaces can be found here...
...             https://github.com/openbmc/docs/blob/master/rest-api.md

Resource        ../lib/rest_client.robot
Resource        ../lib/pdu/pdu.robot
Resource        ../lib/utils.robot
Resource        ../lib/openbmc_ffdc.robot


Library         SSHLibrary

Test Teardown   Log FFDC
Force Tags      chassisboot  bmcreboot

*** Variables ***

${HOST_SETTING}      /org/openbmc/settings/host0
${CHASSIS_CONTROL}   /org/openbmc/control/chassis0/

***test cases***

Set the power restore policy
           Policy                 ExpectedSystemState       NextSystemState

           LEAVE_OFF              HOST_POWERED_OFF          HOST_POWERED_OFF
           LEAVE_OFF              HOST_POWERED_ON           HOST_POWERED_OFF
           ALWAYS_POWER_ON        HOST_POWERED_OFF          HOST_POWERED_ON
           ALWAYS_POWER_ON        HOST_POWERED_ON           HOST_POWERED_ON
           RESTORE_LAST_STATE     HOST_POWERED_ON           HOST_POWERED_ON
           RESTORE_LAST_STATE     HOST_POWERED_OFF          HOST_POWERED_OFF

    [Documentation]   This test case sets the pilicy as given under the policy
    ...               attribute.
    ...               ExpectedSystemState:-is the state where system should be
    ...               before running the test case
    ...               NextSystemState:-is After Power cycle system should reach
    ...               to this state
    ...               if the system is not at the Expected System State,This
    ...               test case brings the system in the Expected state then
    ...               do the power cycle.

    [Template]    setRestorePolicy

***keywords***
setRestorePolicy
    [arguments]   ${policy}     ${expectedState}   ${nextState}
    Test Restore Policy   ${policy}    ${expectedState}   ${nextState}


Test Restore Policy
     [Documentation]  Return if PDU related parameter are not set
    [arguments]      ${policy}     ${expectedState}   ${nextState}
    ${valid}=   Run Keyword and Return Status    Validate PDU Variables
    Return From Keyword If   '${valid}' == '${False}'     ${False}

    ${valueDict} =   create dictionary   data=${policy}
    Write Attribute  ${HOST_SETTING}    power_policy      data=${valueDict}
    ${currentPolicy}=      Read Attribute    ${HOST_SETTING}    power_policy
    Should Be Equal     ${currentPolicy}      ${policy}
    ${currentState}=    Read Attribute    ${HOST_SETTING}    system_state
    Run Keyword If
    ...   '${currentState}' != '${expectedState}' and '${expectedState}' == 'HOST_POWERED_ON'
    ...   powerOnHost
    Run Keyword If
    ...   '${currentState}' != '${expectedState}' and '${expectedState}' == 'HOST_POWERED_OFF'
    ...     powerOffHost
    PDU Power Cycle
    Wait For Host To Ping   ${OPENBMC_HOST}
    Sleep   100sec
    ${afterPduSystemState}=    Read Attribute   ${HOST_SETTING}    system_state
    Should be equal   ${afterPduSystemState}    ${nextState}

powerOffHost
    @{arglist}=   Create List
    ${args}=     Create Dictionary   data=@{arglist}
    ${resp}=   Call Method   ${CHASSIS_CONTROL}    powerOff    data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json} =   to json         ${resp.content}
    should be equal as strings      ${json['status']}      ok
    sleep  30sec
    ${currentState}=     Read Attribute   ${HOST_SETTING}   system_state
    Should be equal   ${currentState}     HOST_POWERED_OFF

powerOnHost
    @{arglist}=   Create List
    ${args}=     Create Dictionary    data=@{arglist}
    ${resp}=   Call Method   ${CHASSIS_CONTROL}    powerOn    data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json} =   to json         ${resp.content}
    should be equal as strings      ${json['status']}      ok
    sleep   30sec
    ${currentState}=    Read Attribute    ${HOST_SETTING}    system_state
    Should be equal   ${currentState}     HOST_POWERED_ON


Validate PDU Variables
    Should not be empty  ${PDU_TYPE}
    Should not be empty  ${PDU_IP}
    Should not be empty  ${PDU_USERNAME}
    Should not be empty  ${PDU_PASSWORD}
    Should not be empty  ${PDU_SLOT_NO}

