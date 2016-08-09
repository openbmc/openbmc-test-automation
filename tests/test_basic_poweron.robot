*** Settings ***
Documentation       This module will test basic power on use cases for CI

Resource            ../lib/rest_client.robot
Resource            ../lib/utils.robot

Suite Setup         poweron readiness test

Force Tags  chassisboot

*** test cases ***

power on test
    [Documentation]    Poweron if OFF and poweroff if ON

    ${state}=    Get Power State
    Run Keyword If    ${state} == ${0}  Initiate Power On
    ...   ELSE    Initiate Power Off

    ${state}=    Get Power State
    Run Keyword If    ${state} == ${1}  Initiate Power Off
    ...   ELSE    Initiate Power On

*** keywords ***

poweron readiness test
    [Documentation]   Confirm that the system is ready for poweron and
    ...               not in BMC_STARTING state
    ${state}=   Get BMC State
    Should not be equal   ${state}  BMC_STARTING  msg=Host not ready
