*** Settings ***
Documentation       This module will test basic power on use cases for CI

Resource            ../lib/rest_client.robot

Suite Setup         poweron readiness test

Test template       power on tests

*** variables ***

${POWER_CONTROL}    /org/openbmc/control/chassis0
${POWER_SETTING}    /org/openbmc/settings/host0
${SYSTEM_STATE}     /org/openbmc/managers/System
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
    [Arguments]   ${method}    ${endState}
    Log To Console    ${\n}${method} the host

    Call Poweron method   ${POWER_CONTROL}  ${method}

    Wait Until Keyword Succeeds      ${Retry}    ${Interval}
    ...    system power state   ${endState}


system power state
    [Arguments]       ${endState}
    ${currState}=     Read Attribute   ${POWER_SETTING}   system_state
    Should be equal   ${currState}     ${endState}


poweron readiness test
    [Documentation]   Confirm that the system is ready for poweron and
    ...               not in BMC_STARTING state
    ${state}=   System state  ${SYSTEM_STATE}  getSystemState
    Should not be equal   ${state}  BMC_STARTING  msg=Host not ready
