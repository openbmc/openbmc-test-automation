*** Settings ***
Documentation   This suite tests Timed Power On(TPO) feature via busctl command
...             and verify the power status of the system.
...
...             System can be scheduled to Power ON at a specified time by using this feature.


Resource        ../lib/boot_utils.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/bmc_redfish_resource.robot


Suite Setup     Redfish.Login
Suite Teardown  Redfish.Logout
Test Setup      Test Setup Execution
Test Teardown   Test Teardown Execution


*** Variables ****

${CMD_SET_TPO_TIME}    busctl set-property xyz.openbmc_project.State.ScheduledHostTransition
...  /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.ScheduledHostTransition ScheduledTime t

${CMD_GET_TPO_TIME}    busctl get-property xyz.openbmc_project.State.ScheduledHostTransition
...  /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.ScheduledHostTransition ScheduledTime

${TIMER_POWER_ON}      100


*** Test Cases ***

Set And Return Timer For Power ON
    [Documentation]  Set time for power ON using busctl command and verify.
    [Tags]  Set_And_Return_Timer_For_Power_ON

    ${tpo_set_value}=  Set Timer For Power ON
    ${new_tpo_value}=  Get Time Power ON Value
    Should Be Equal  ${new_tpo_value}  ${tpo_set_value}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Open Connection And Login
    Redfish Power Off


Test Teardown Execution
    [Documentation]  Do the test teardown

    FFDC On Test Case Fail
    Close All Connections


Set Timer For Power ON
    [Documentation]  Set the time for power ON with given value.

    ${current_bmc_time}=  BMC Execute Command  date +%s
    ${time_set}=  Evaluate  ${current_bmc_time[0]} + ${TIMER_POWER_ON}
    BMC Execute Command  ${CMD_SET_TPO_TIME} ${time_set}

    [Return]  ${time_set}


Get Time Power ON Value
    [Documentation]  Returns time power ON value.

    ${timer_value}=  BMC Execute Command  ${CMD_GET_TPO_TIME}
    @{return_value}=  Split String  ${timer_value[0]}
    ${return_value}=  Evaluate  ${return_value}[1]

    # BMC command returns integer value.
    [Return]  ${return_value}
