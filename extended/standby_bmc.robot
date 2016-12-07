*** Settings ***
Documentation     This module will take whatever action is necessary
...               to bring the BMC to a stable, standby state.  For our
...               purposes, a stable state is defined as:
...                  - BMC is communicating
...                   (pinging, sshing and REST commands working)
...                  - Power state is 0 (off)
...                  - BMC state is "BMC_READY" or "HOST_POWERED_OFF"
...                  - Boot policy is "RESTORE_LAST_STATE"

Resource          ../lib/boot/boot_resource_master.robot
Resource          ../lib/utils.robot

*** Variables ***
${HOST_SETTING}      /org/openbmc/settings/host0

*** Test cases ***

Get to Stable State
    [Documentation]    BMC cleanup drive to stable state
    ...                1. Ping Test
    ...                2. SSH Connection session Test
    ...                3. REST Connection session Test
    ...                4. Reboot BMC if REST Test failed
    ...                5. Check BMC state for standby
    ...                6. Issue poweroff if not already in
    ...                   standby state
    ...                7. Update restore policy
    [Tags]  Get to Stable State

    Wait For Host To Ping  ${OPENBMC_HOST}  1 mins
    Open Connection And Log In   host=${OPENBMC_HOST}

    ${l_rest}=   Run Keyword And Return Status
    ...    Initialize OpenBMC
    Run Keyword If  '${l_rest}' == '${False}'
    ...    Reboot and Wait for BMC Online

    ${l_ready}=   Run Keyword And Return Status
    ...    Get BMC State and Expect Standby

    Run Keyword If  '${l_ready}' == '${False}'
    ...    Initiate Power Off

    Update Policy Setting   RESTORE_LAST_STATE


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
    ${bmc_state}=  Get BMC State
    Should Contain  ${states}   ${bmc_state}


Update Policy Setting
    [Documentation]   Update the given restore policy
    [arguments]   ${policy}

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
