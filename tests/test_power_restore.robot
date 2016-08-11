*** Settings ***
Documentation                This suite will verifiy the power restore policy rest Interfaces
...                          Details of valid interfaces can be found here...
...                          https://github.com/openbmc/docs/blob/master/rest-api.md

Resource        ../lib/rest_client.robot
Resource        ../lib/pdu/pdu.robot
Resource        ../lib/utils.robot


Library         SSHLibrary

Force Tags      chassisboot  bmcreboot

***test cases***

Set the power restore policy       Policy                 ExpectedSystemState       NextSystemState
                  
                                   LEAVE_OFF              HOST_POWERED_OFF          HOST_POWERED_OFF
                                   LEAVE_OFF              HOST_POWERED_ON           HOST_POWERED_OFF
                                   ALWAYS_POWER_ON        HOST_POWERED_OFF          HOST_POWERED_ON
                                   ALWAYS_POWER_ON        HOST_POWERED_ON           HOST_POWERED_ON
                                   RESTORE_LAST_STATE     HOST_POWERED_ON           HOST_POWERED_ON
                                   RESTORE_LAST_STATE     HOST_POWERED_OFF          HOST_POWERED_OFF 
                                     
    [Documentation]   This test case sets the pilicy as given under the policy attribute.
    ...               ExpectedSystemState:-is the state where system should be before running the test case
    ...               NextSystemState:-is After Power cycle system should reach to this state 
    ...               if the system is not at the Expected System State,This test case brings the system 
    ...               in the Expected state then do the power cycle.

    [Template]    setRestorePolicy

***keywords***
setRestorePolicy
    [arguments]        ${policy}     ${expectedSystemState}   ${nextSystemState}
    ${valueDict} =   create dictionary   data=${policy}
    Write Attribute  /org/openbmc/settings/host0    power_policy      data=${valueDict}
    ${currentPolicy}=      Read Attribute    /org/openbmc/settings/host0    power_policy
    Should Be Equal     ${currentPolicy}      ${policy}
    ${currentSystemState}=      Read Attribute    /org/openbmc/settings/host0    system_state
    log Many   "CurrentSystemState="   ${currentSystemState}   
    log Many   "ExpectedSystemState="  ${expectedSystemState}   
    log Many   "NextSystemState="      ${nextSystemState}
    Run Keyword If   '${currentSystemState}' != '${expectedSystemState}' and '${expectedSystemState}' == 'HOST_POWERED_ON'      powerOnHost
    Run Keyword If   '${currentSystemState}' != '${expectedSystemState}' and '${expectedSystemState}' == 'HOST_POWERED_OFF'     powerOffHost
    log to console   "Doing power cycle"
    PDU Power Cycle
    Wait For Host To Ping   ${OPENBMC_HOST}
    log to console   "Host is pingable now"
    Sleep   100sec
    ${afterPduSystemState}=      Read Attribute    /org/openbmc/settings/host0    system_state
    Should be equal   ${afterPduSystemState}    ${nextSystemState}

powerOffHost
    log to console    "Powering off the host"
    @{arglist}=   Create List    
    ${args}=     Create Dictionary   data=@{arglist}
    ${resp}=   Call Method    /org/openbmc/control/chassis0/    powerOff    data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json} =   to json         ${resp.content}
    should be equal as strings      ${json['status']}      ok
    sleep  30sec
    ${currentSystemState}=      Read Attribute    /org/openbmc/settings/host0    system_state
    Should be equal   ${currentSystemState}     HOST_POWERED_OFF

powerOnHost
    log to console    "Powering on the host"
    @{arglist}=   Create List   
    ${args}=     Create Dictionary    data=@{arglist}
    ${resp}=   Call Method    /org/openbmc/control/chassis0/    powerOn    data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json} =   to json         ${resp.content}
    should be equal as strings      ${json['status']}      ok
    sleep   30sec
    ${currentSystemState}=      Read Attribute    /org/openbmc/settings/host0    system_state
    Should be equal   ${currentSystemState}     HOST_POWERED_ON



