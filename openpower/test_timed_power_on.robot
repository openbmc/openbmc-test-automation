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

${CMD_ENABLE_TPO}      busctl set-property xyz.openbmc_project.State.ScheduledHostTransition
...   /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.ScheduledHostTransition
...   ScheduledTransition s "xyz.openbmc_project.State.Host.Transition.On"

${CMD_SET_TPO_TIME}    busctl set-property xyz.openbmc_project.State.ScheduledHostTransition
...  /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.ScheduledHostTransition ScheduledTime t

${CMD_GET_TPO_TIME}    busctl get-property xyz.openbmc_project.State.ScheduledHostTransition
...  /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.ScheduledHostTransition ScheduledTime

# Time in seconds.
${TIMER_POWER_ON}      100


*** Test Cases ***

Test Timed Powered On Via BMC
    [Documentation]  Set time to power on host attribute ScheduledTime and expect
    ...              the system to boot on scheduled time.
    [Tags]  Test_Timed_Powered_On_Via_BMC

    # Make sure the host is powered off.
    Redfish Power Off  stack_mode=skip

    # Set Host transition to ON to enable TPO.
    BMC Execute Command  ${CMD_ENABLE_TPO}

    ${tpo_set_value}=  Set Timer For Power ON
    ${new_tpo_value}=  Get Time Power ON Value

    Should Be Equal  ${new_tpo_value}  ${tpo_set_value}
    ...  msg=TPO time set mismatched.

    # Check if the system BootProgress state changed. If changed, it implies the
    # system is powering on. Though we have set system to power on in 120 seconds
    # since, the system boot sometime to change.
    Wait Until Keyword Succeeds  10 min  20 sec  Is Boot Progress Changed

    Log To Console   Scheduled Time Power on success


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the test teardown

    FFDC On Test Case Fail


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
