*** Settings ***
Documentation     This module will take whatever action is necessary
...               to bring the BMC to a stable, standby state.  For our
...               purposes, a stable state is defined as:
...                  - BMC is communicating
...                   (pinging, sshing and REST commands working)
...                  - Power state is 0 (off)
...                  - BMC state is "Ready"
...                  - HOST state is "Off"
...                  - Boot policy is "ALWAYS_POWER_OFF"
...               Power cycle system via PDU if specified
...               Prune archived journal logs

Resource          ../lib/utils.robot
Resource          ../lib/pdu/pdu.robot
Resource          ../lib/state_manager.robot
Resource          ../lib/bmc_network_utils.robot
Resource          ../lib/bmc_cleanup.robot
Resource          ../lib/dump_utils.robot
Resource          ../lib/bmc_redfish_resource.robot
Resource          ../lib/bmc_redfish_utils.robot
Library           ../lib/gen_misc.py

# Force the test to timedout to prevent test hanging.
Test Timeout      10 minutes


*** Variables ***
${HOST_SETTING}      /org/openbmc/settings/host0

${ERROR_REGEX}  xyz.openbmc_project.Software.BMC.Updater.service: Failed with result 'core-dump'

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
    ...              8. Verify and Update MAC address.
    [Tags]  Get_To_Stable_State

    Run Keyword And Ignore Error  Powercycle System Via PDU

    ${ping_status}=  Run Keyword And Return Status
    ...  Wait For Host To Ping  ${OPENBMC_HOST}  2 mins

    # Check if the ping works using 1400 MTU.
    #IF  ${ping_status} == ${True}  MTU Ping Test

    IF  ${ping_status} == ${False}  Fail  ${OPENBMC_HOST} ping test failed.

    Open Connection And Log In  host=${OPENBMC_HOST}

    IF  ${REDFISH_SUPPORTED}
        Redfish Clean Up
    ELSE
        REST Clean Up
    END


    Prune Journal Log
    Check For Current Boot Application Failures

*** Keywords ***


REST Clean Up
    [Documentation]  Check states, reboot if needed and poweroff.

    Wait Until Keyword Succeeds  1 min  30 sec  Initialize OpenBMC

    ${ready_status}=  Run Keyword And Return Status  Is BMC Ready
    IF  '${ready_status}' == '${False}'
        Put BMC State  Ready
    ELSE
        REST Power Off  stack_mode=skip
    END

    Run Keyword And Ignore Error  Set BMC Power Policy  ${ALWAYS_POWER_OFF}
    Run Keyword And Ignore Error  Delete All Error Logs
    Run Keyword And Ignore Error  Delete All Dumps


Redfish Clean Up
    [Documentation]  Check states, reboot if needed and poweroff.

    Wait Until Keyword Succeeds  1 min  30 sec  Redfish.Login

    Redfish Power Off  stack_mode=skip

    Run Keyword And Ignore Error  Redfish Set Power Restore Policy  AlwaysOff
    Run Keyword And Ignore Error  Redfish Purge Event Log
    Run Keyword And Ignore Error  Redfish Delete All BMC Dumps
    Run Keyword And Ignore Error  Redfish Delete All System Dumps
    Run Keyword And Ignore Error  Clear All Subscriptions
    Run Keyword And Ignore Error  Delete All Redfish Sessions


BMC Online Test
    [Documentation]   BMC ping, SSH, REST connection Test

    ${l_status}=   Run Keyword and Return Status
    ...   Verify Ping and REST Authentication
    IF  '${l_status}' == '${False}'
        Fail  msg=System not in ideal state to continue [ERROR]
    END


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
    [Documentation]   AC cycle the system via PDU.

    Validate Parameters
    PDU Power Cycle
    Check If BMC is Up   5 min    10 sec


Check For Current Boot Application Failures
    [Documentation]  Parse the journal log and check for failures.
    [Arguments]  ${error_regex}=${ERROR_REGEX}

    ${error_regex}=  Escape Bash Quotes  ${error_regex}
    ${journal_log}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl -b --no-pager | egrep '${error_regex}'  ignore_err=1

    Should Be Empty  ${journal_log}


Validate Parameters
    [Documentation]  Validate PDU parameters.
    Should Not Be Empty   ${PDU_IP}
    Should Not Be Empty   ${PDU_TYPE}
    Should Not Be Empty   ${PDU_SLOT_NO}
    Should Not Be Empty   ${PDU_USERNAME}
    Should Not Be Empty   ${PDU_PASSWORD}


MTU Ping Test
    [Documentation]  Ping test using MTU.
    [Arguments]  ${mtu}=${1400}

    # Description of argument(s):
    # mtu   The maximum transmission unit (MTU) of a network interface.

    ${rc}  ${output}=  Run And Return RC And Output
    ...  ping -M do -s ${mtu} -c 10 ${OPENBMC_HOST}
    Should Be Equal As Integers  ${rc}  0
    Should Not Contain  ${output}  100% packet loss


Clear All Subscriptions
    [Documentation]  Delete all subscriptions.

    ${subscriptions}=  Redfish.Get Attribute  /redfish/v1/EventService/Subscriptions  Members
    FOR  ${subscription}  IN  @{subscriptions}
        Redfish.Delete  ${subscription['@odata.id']}
    END
