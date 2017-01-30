*** Settings ***
Documentation  Contains all of the keywords that do various power offs.

Resource    ../resource.txt
Resource    ../utils.robot
Resource    ../connection_client.robot
Resource    ../state_manager.robot

*** Keywords ***
BMC Power Off
    [Documentation]  Powers off the system and makes sure that all states are
    ...  powered off.

    Open Connection and Log In
    Initiate Power Off
    Check Power Off States
    Close Connection

Check Power Off States
    [Documentation]  Checks that the BMC state, power state, and boot progress
    ...  are correctly powered off.

    ${power_state}=  Get Power State
    Should Be Equal  ${power_state}  ${0}
    Log to Console  Power State: ${power_state}

    ${boot_progress}=  Get Boot Progress
    Should Be Equal  ${boot_progress}  Off
    Log to Console  Boot Progress: ${boot_progress}

    ${host_state}=  Get Host State
    Should Be Equal  ${host_state}  Off
    Log to Console  HOST State: ${host_state}
