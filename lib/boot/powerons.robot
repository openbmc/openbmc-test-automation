*** Settings ***
Documentation  Contains all of the keywords that do various power ons.

Resource    ../resource.txt
Resource    ../utils.robot
Resource    ../connection_client.robot
Resource    ../state_manager.robot

*** Keywords ***
BMC Power On
    [Documentation]  Powers on the system, checks that the OS is functional, and
    ...  makes sure that all states are powered on.

    &{bmc_connection_args}=  Create Dictionary  alias=bmc_connection

    Open Connection and Log In  &{bmc_connection_args}
    Initiate Host Boot
    Run Keyword If   '${OS_HOST}' != '${EMPTY}'   Wait For OS
    Switch Connection  bmc_connection
    Check Power On States
    Close Connection

Check Power On States
    [Documentation]  Checks that the host state, power state, and boot progress
    ...  are correctly powered on.

    Is Host Running

    Wait Until Keyword Succeeds   ${OS_WAIT_TIMEOUT}  10sec  Is OS Starting

    ${power_state}=  Get Power State
    Should Be Equal  ${power_state}  ${1}
    Log to Console  Power State: ${power_state}

Is OS Starting
    [Documentation]  Check if boot progress is OS starting.
    ${boot_progress}=  Get Boot Progress
    Should Be Equal  ${boot_progress}  FW Progress, Starting OS 
