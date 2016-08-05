*** Settings ***
Documentation       This module will test basic power on use cases for CI

Resource            ../lib/rest_client.robot

Suite Setup         Initialize REST setup
Test template       power on tests

*** variables ***

${POWER_CONTROL}    /org/openbmc/control/chassis0/
${POWER_SETTING}    /org/openbmc/settings/host0
${Retry}            1 min
${Interval}         30s

*** test cases ***

Verify power on system states

    # Template Action       Expected End State
    poweroff                HOST_POWERED_OFF
    poweron                 HOST_POWERED_ON
    poweroff                HOST_POWERED_OFF

*** keywords ***

power on tests
    [Arguments]   ${action}    ${endState}
    Log To Console    ${\n}${action} the host

    @{arglist}=   Create List
    ${args}=      Create Dictionary   data=@{arglist}
    ${resp}=      Call Method    ${POWER_CONTROL}    ${action}    data=${args}
    should be equal as strings       ${resp.status_code}     ${HTTP_OK}
    ${json} =     to json            ${resp.content}
    should be equal as strings       ${json['status']}      ok

    Wait Until Keyword Succeeds      ${Retry}    ${Interval}
    ...    system power state   ${endState}


system power state
    [Arguments]       ${endState}
    ${currState}=     Read Attribute   ${POWER_SETTING}   system_state
    Should be equal   ${currState}     ${endState}
