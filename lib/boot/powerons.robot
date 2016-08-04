*** Settings ***
Documentation  Contains all of the keywords that do various power ons.

Resource    ../resource.txt
Resource    ../utils.robot
Resource    ../connection_client.robot

*** Keywords ***
BMC Power On
    [Documentation]  Powers on the system, checks that the OS is functional, and
    ...  makes sure that all states are powered on.

    &{bmc_connection_args}=  Create Dictionary  alias=bmc_connection

    Open Connection and Log In  &{bmc_connection_args}
    Initiate Power On
    Wait For OS
    Switch Connection  bmc_connection
    Check Power On States
    Close Connection

Check Power On States
    [Documentation]  Checks that the BMC state, power state, and boot progress
    ...  are correctly powered on.

    ${bmc_state}=  Get BMC State
    Should Contain  ${bmc_state}  HOST_BOOTED
    Log to Console  BMC State: ${bmc_state}

    ${boot_progress}=  Get Boot Progress
    Should Be Equal  ${boot_progress}  FW Progress, Starting OS
    Log to Console  Boot Progress: ${boot_progress}

    ${power_state}=  Get Power State
    Should Be Equal  ${power_state}  ${1}
    Log to Console  Power State: ${power_state}
