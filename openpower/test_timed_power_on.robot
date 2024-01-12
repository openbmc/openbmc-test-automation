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
...   /xyz/openbmc_project/scheduled/host0 xyz.openbmc_project.State.ScheduledHostTransition
...   ScheduledTransition s "xyz.openbmc_project.State.Host.Transition.On"

${CMD_SET_TPO_TIME}    busctl set-property xyz.openbmc_project.State.ScheduledHostTransition
...  /xyz/openbmc_project/scheduled/host0 xyz.openbmc_project.State.ScheduledHostTransition ScheduledTime t

${CMD_GET_TPO_TIME}    busctl get-property xyz.openbmc_project.State.ScheduledHostTransition
...  /xyz/openbmc_project/scheduled/host0 xyz.openbmc_project.State.ScheduledHostTransition ScheduledTime

# Time in seconds.
${TIMER_POWER_ON}      100

# All current versions of the following distributions:
#  - Red Hat Enterprise Linux
#  - SUSE Linux Enterprise Server
# Tested on RHEL 8.4.

# Shut down the system and schedule it to restart in 1 hour.
# User can input -v HOST_TIMER_POWER_ON:h24  ( e.g. 24 hours )
${HOST_TIMER_POWER_ON}            h1
${HOST_TIMED_POWER_ON_REQUEST}    set_poweron_time -d ${HOST_TIMER_POWER_ON} -s

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
    # system is powering on. Though we have set system to power on in 100 seconds
    # since, the system boot sometime to change.
    Wait Until Keyword Succeeds  10 min  20 sec  Is Boot Progress Changed

    Log To Console   BMC Scheduled Time Power on success.


Test Timed Powered On Via Host OS
    [Documentation]  Set time to power on host via service aids tool set_poweron_time
    ...              and expect the system to boot on scheduled time.
    [Tags]  Test_Timed_Powered_On_Via_Host_OS

    # Make sure the host is powered on and booted to host OS partition.
    Redfish Power On

    ${stdout}  ${stderr}  ${rc}=  OS Execute Command  which set_poweron_time  ignore_err=${0}
    # Skip the test if the tool does not exist or error getting the tool.
    Skip If  ${rc} != ${0}  INFO: ${stdout} Skip the test since the tool does not. Install and re-run.

    # Set Host transition to ON to enable TPO.
    ${stdout}  ${stderr}  ${rc}=  OS Execute Command  ${HOST_TIMED_POWER_ON_REQUEST}  ignore_err=${0}

    # Wait for host to Power off.
    Wait Until Keyword Succeeds  45 min  30 sec  Is BMC Standby

    Log To Console  Power Off completed.

    # Note: The verification could more precise by checking date and set time.

    # Check if the system BootProgress state changed. If changed, it implies the
    # system is powering on after user timer set and delta time to update BootProgress
    # state by the state manager.
    # ${HOST_TIMER_POWER_ON} is in <m/h/d/><time> format
    # Example:  h1 , logic to convert  x[1:] -> 1 and x[:1] ->h  to robot format 1 h.

    Log To Console  Waiting for system to power on.
    Wait Until Keyword Succeeds  ${HOST_TIMER_POWER_ON[1:]} ${HOST_TIMER_POWER_ON[:1]}  30 sec
    ...  Is Boot Progress Changed

    Log To Console   Host Scheduled Time Power on success.


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login
    Set Power Policy For TPO  Automatic


Set Power Policy For TPO
    [Documentation]   Change 'server power policy' option to automatic.
    [Arguments]  ${power_policy_mode}

    # Description of argument(s):
    # power_policy_mode           BIOS attribute value. E.g. "Stay On", "Automatic".

    Redfish.Patch  /redfish/v1/Systems/${SYSTEM_ID}/Bios/Settings
    ...  body={"Attributes":{"pvm_system_power_off_policy": "${power_policy_mode}"}}
    ...  valid_status_codes=[${HTTP_OK}]


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
