*** Settings ***
Documentation  Power on, ping and SSH to OS, and check states for powered on.

Resource    ../resource.txt
Resource    ../utils.robot
Resource    ../connection_client.robot

*** Keywords ***
BMC Power On
    [Arguments]  ${bmc_alias}=${BMC_ALIAS}

    # bmc_alias     The name of the alias to give the connection to the BMC.

    Open Connection and Log In  alias=${bmc_alias}
    Power On Host
    Wait For OS
    Switch Connection  ${bmc_alias}
    Check Power On States
    Close Connection

Check Power On States
    ${bmc_state}=  Get BMC State
    Should Contain  ${bmc_state}  HOST_BOOTED
    Log to Console  BMC State: ${bmc_state}

    ${boot_progress}=  Get Boot Progress
    Should Be Equal  ${boot_progress}  FW Progress, Starting OS
    Log to Console  Boot Progress: ${boot_progress}

    ${power_state}=  Get Power State
    Should Be Equal  ${power_state}  ${1}
    Log to Console  Power State: ${power_state}
