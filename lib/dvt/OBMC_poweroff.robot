*** Settings ***
[Documentation]  Power off and check states for powered off.

Resource    ../resource.txt
Resource    ../utils.robot
Resource    ../connection_client.robot

*** Keywords ***
BMC Power Off
    [Arguments]  ${bmc_alias}=${BMC_ALIAS}

    # bmc_alias     The name of the alias to give the connection to the BMC.

    Open Connection and Log In  alias=${bmc_alias}
    Power Off Host
    Check Power Off States
    Close Connection

Check Power Off States
    ${power_state}=  Get Power State
    Should Be Equal  ${power_state}  ${0}
    Log to Console  Power State: ${power_state}

    ${boot_progress}=  Get Boot Progress
    Should Be Equal  ${boot_progress}  Off
    Log to Console  Boot Progress: ${boot_progress}

    ${bmc_state}=  Get BMC State
    Should Contain  ${bmc_state}  HOST_POWERED_OFF
    Log to Console  BMC State: ${bmc_state}
