*** Settings ***
Documentation       This module will test basic power on use cases for CI

Resource            ../lib/rest_client.robot
Resource            ../lib/utils.robot

Suite Setup         poweron readiness test

Test template       power on tests

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
    
    Run Keyword If   '${method}' == 'poweron'  Initiate Power On
    ...  ELSE    Initiate Power Off

poweron readiness test
    [Documentation]   Confirm that the system is ready for poweron and
    ...               not in BMC_STARTING state
    ${state}=   Get BMC State
    Should not be equal   ${state}  BMC_STARTING  msg=Host not ready
