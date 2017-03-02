*** Settings ***
Documentation     This module will take whatever action is necessary
...               to bring the BMC to a stable, standby state.  For our
...               purposes, a stable state is defined as:
...                  - BMC is communicating
...                   (pinging, sshing and REST commands working)
...                  - Power state is 0 (off)
...                  - BMC state is "Ready"
...                  - HOST state is "Off"
...                  - Boot policy is "RESTORE_LAST_STATE"
...               Power cycle system via PDU if specified
...               Prune archived journal logs

Resource          ../lib/utils.robot
Resource          ../lib/pdu/pdu.robot
Resource          ../lib/state_manager.robot

*** Variables ***
${HOST_SETTING}      /org/openbmc/settings/host0

*** Test Cases ***

Get To Stable State
    [Documentation]  BMC cleanup drive to stable state
    ...              1. PDU powercycle if specified
    ...              1. Ping Test
    ...              2. SSH Connection session Test
    ...              3. REST Connection session Test
    ...              4. Reboot BMC if REST Test failed
    ...              5. Get BMC in Ready state if its not in this state
    ...              6. Get Host in Off state if its not in this state
    ...              7. Update restore policy
    [Tags]  Get_To_Stable_State

    Run Keyword And Ignore Error  Powercycle System Via PDU

    Wait For Host To Ping  ${OPENBMC_HOST}  1 mins
    Open Connection And Log In  host=${OPENBMC_HOST}

    ${rest_status}=  Run Keyword And Return Status  Initialize OpenBMC
    Run Keyword If  '${rest_status}' == '${False}'
    ...  Reboot and Wait for BMC Online

    # Power off using new interface
    ${poweroff_status}=  Run Keyword And Return Status  Initiate Host PowerOff

    # If power off fails, resort to old org poweroff 
    Run Keyword If  '${poweroff_status}' == '${False}'  Initiate Power Off

    Prune Journal Log

    Run Keyword And Ignore Error  Update Policy Setting  RESTORE_LAST_STATE


*** Keywords ***

Reboot and Wait for BMC Online
    [Documentation]    Reboot BMC and wait for it to come online
    ...                and boot to standby

    Trigger Warm Reset via Reboot
    Wait Until Keyword Succeeds
    ...    5 min   10 sec    BMC Online Test

    Wait For BMC Standby


BMC Online Test
    [Documentation]   BMC ping, SSH, REST connection Test

    ${l_status}=   Run Keyword and Return Status
    ...   Verify Ping and REST Authentication
    Run Keyword If  '${l_status}' == '${False}'
    ...   Fail  msg=System not in ideal state to continue [ERROR]


Wait For BMC Standby
    [Documentation]   Wait Until BMC standby post BMC reboot

    @{states}=   Create List   BMC_READY   HOST_POWERED_OFF
    Wait Until Keyword Succeeds
    ...    10 min   10 sec   Verify BMC State   ${states}


Get BMC State and Expect Standby
    [Documentation]   Get BMC state and should be at standby

    @{states}=     Create List   BMC_READY   HOST_POWERED_OFF
    ${bmc_state}=  Get BMC State Deprecated
    Should Contain  ${states}   ${bmc_state}


Update Policy Setting
    [Documentation]   Update the given restore policy
    [Arguments]   ${policy}

    ${valueDict}=     create dictionary  data=${policy}
    Write Attribute    ${HOST_SETTING}    power_policy   data=${valueDict}
    ${currentPolicy}=  Read Attribute     ${HOST_SETTING}   power_policy
    Should Be Equal    ${currentPolicy}   ${policy}


Trigger Warm Reset via Reboot
    [Documentation]    Execute reboot command on the remote BMC and
    ...                returns immediately. This keyword "Start Command"
    ...                returns nothing and does not wait for the command
    ...                execution to be finished.
    Open Connection And Log In

    Start Command   /sbin/reboot


Powercycle System Via PDU
    [Documentation]   AC cycle the system via PDU

    Validate Parameters
    PDU Power Cycle
    Check If BMC is Up   5 min    10 sec


Validate Parameters
    Should Not Be Empty   ${PDU_IP}
    Should Not Be Empty   ${PDU_TYPE}
    Should Not Be Empty   ${PDU_SLOT_NO}
    Should Not Be Empty   ${PDU_USERNAME}
    Should Not Be Empty   ${PDU_PASSWORD}
