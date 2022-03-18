*** Settings ***
Documentation   Power cycle loop. This is to test where network service
...             becomes unavailable during AC-Cycle stress test.

Resource        ../lib/rest_client.robot
Resource        ../lib/pdu/pdu.robot
Resource        ../lib/utils.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/state_manager.robot
Resource        ../lib/boot_utils.robot
Resource        ../lib/code_update_utils.robot
Library         ../lib/bmc_ssh_utils.py

Test Teardown   Test Teardown Execution
Suite Setup     Suite Setup Execution

*** Variables ***
${LOOP_COUNT}          ${50}
${CHECK_FOR_ERRORS}    ${1}

# Error strings to check from journald.
${ERROR_REGEX}     SEGV|core-dump|FAILURE|Failed to start

*** Test Cases ***

Run Multiple Power Cycle
    [Documentation]  Execute multiple power cycles.
    [Setup]  Validate Parameters
    [Tags]  Run_Multiple_Power_Cycle

    # By default run test for 50 loops, else user input iteration.
    # Fails immediately if any of the execution rounds fail and
    # check if BMC is still pinging and FFDC is collected.
    Repeat Keyword  ${LOOP_COUNT} times  Power Cycle System Via PDU


Run Multiple BMC Reset Via Redfish
    [Documentation]  Execute multiple reboots via REST.
    [Tags]  Run_Multiple_BMC_Reset_Via_Redfish

    # By default run test for 50 loops, else user input iteration.
    # Fails immediately if any of the execution rounds fail and
    # check if BMC is still pinging and FFDC is collected.
    Repeat Keyword  ${LOOP_COUNT} times  BMC Redfish Reset Cycle


Run Multiple BMC Reset Via Reboot
    [Documentation]  Execute multiple reboots via "reboot" command.
    [Tags]  Run_Multiple_BMC_Reset_Via_Reboot

    # By default run test for 50 loops, else user input iteration.
    # Fails immediately if any of the execution rounds fail and
    # check if BMC is still pinging and FFDC is collected.
    Repeat Keyword  ${LOOP_COUNT} times  BMC Reboot Cycle


Run Multiple BMC Reset When Host Is Booted Via Redfish
    [Documentation]  Execute multiple reboots via redfish.
    [Tags]  Run_Multiple_BMC_Reset_When_Host_Is_Booted_Via_Redfish

    # By default run test for 50 loops, else user input iteration.
    # Fails immediately if any of the execution rounds fail and
    # check if BMC is still pinging and FFDC is collected.
    Repeat Keyword  ${LOOP_COUNT} times  BMC Redfish Reset Runtime Cycle

*** Keywords ***

Power Cycle System Via PDU
    [Documentation]  Power cycle system and wait for BMC to reach Ready state.

    PDU Power Cycle
    Check If BMC Is Up  5 min  10 sec

    Wait Until Keyword Succeeds  10 min  10 sec  Is BMC Ready
    Verify BMC RTC And UTC Time Drift


BMC Redfish Reset Cycle
    [Documentation]  Reset BMC via Redfish and verify required states.

    Redfish OBMC Reboot (off)

    ${bmc_version}=  Get BMC Version
    Valid Value  bmc_version  valid_values=['${initial_bmc_version}']

    Run Keyword If  '${CHECK_FOR_ERRORS}' == '${1}'
    ...  Check For Regex In Journald  ${ERROR_REGEX}  error_check=${0}  boot=-b

    Verify BMC RTC And UTC Time Drift


BMC Redfish Reset Runtime Cycle
    [Documentation]  Reset BMC via Redfish and verify required states.

    Redfish OBMC Reboot (run)

    ${bmc_version}=  Get BMC Version
    Valid Value  bmc_version  valid_values=['${initial_bmc_version}']

    Run Keyword If  '${CHECK_FOR_ERRORS}' == '${1}'
    ...  Check For Regex In Journald  ${ERROR_REGEX}  error_check=${0}  boot=-b

    Verify BMC RTC And UTC Time Drift


BMC Reboot Cycle
    [Documentation]  Reboot BMC and wait for ready state.

    OBMC Reboot (off)  stack_mode=normal
    ${bmc_version}=  Get BMC Version
    Valid Value  bmc_version  ["${initial_bmc_version}"]
    Verify BMC RTC And UTC Time Drift
    Check For Regex In Journald  ${ERROR_REGEX}  error_check=${0}  boot=-b
    ${boot_side}=  Get BMC Flash Chip Boot Side
    Valid Value  boot_side  ['0']


Test Teardown Execution
    [Documentation]  Do test case tear-down.
    Ping Host  ${OPENBMC_HOST}
    FFDC On Test Case Fail


Validate Parameters
    [Documentation]  Validate PDU parameters.
    Should Not Be Empty   ${PDU_IP}
    Should Not Be Empty   ${PDU_TYPE}
    Should Not Be Empty   ${PDU_SLOT_NO}
    Should Not Be Empty   ${PDU_USERNAME}
    Should Not Be Empty   ${PDU_PASSWORD}


Suite Setup Execution
    [Documentation]  Do suite setup.

    ${bmc_version}=  Get BMC Version
    Set Suite Variable  ${initial_bmc_version}  ${bmc_version}
