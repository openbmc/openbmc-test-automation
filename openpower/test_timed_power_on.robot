*** Settings ***
Documentation   This suite tests timed power On feature of OpenBMC.

Resource        ../lib/boot_utils.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/bmc_redfish_resource.robot


Test Setup      Test Setup Execution
Test Teardown   Test Teardown Execution


*** Variables ****

${CMD_SET_TPO_TIME}    busctl set-property xyz.openbmc_project.State.ScheduledHostTransition
...  /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.ScheduledHostTransition ScheduledTime t

${CMD_GET_TPO_TIME}    busctl get-property xyz.openbmc_project.State.ScheduledHostTransition
...  /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.ScheduledHostTransition ScheduledTime

${TIMER_POWER_ON}      100


*** Test Cases ***

Set Time For Power ON
    [Documentation]  Set time for power ON using busctl command and verify.
    [Tags]  Set_Time_For_Power_ON

    ${tpo_value}=  Get Time Power ON Value
    Should Not Be Equal  ${tpo_value}  0


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Open Connection And Login
    Redfish Power Off

    Set Timer For Power ON  ${TIMER_POWER_ON}


Test Teardown Execution
    [Documentation]  Do the test teardown

    FFDC On Test Case Fail
    Close All Connections


Set Timer For Power ON
    [Documentation]  Set the time for power ON with given value .
    [Arguments]  ${time}

    # Description of argument(s):
    # time  Time duration for setting TPO time in milliseconds.

    ${current_bmc_time}=  BMC Execute Command  date +%s
    ${time_set}=  Evaluate  ${current_bmc_time[0]} + ${time}
    BMC Execute Command  ${CMD_SET_TPO_TIME} ${time_set}


Get Time Power ON Value
    [Documentation]  Returns time power ON value.

    ${timer_value}=  BMC Execute Command  ${CMD_GET_TPO_TIME}

    # BMC command returns integer value.
    [Return]  ${timer_value[1]}
