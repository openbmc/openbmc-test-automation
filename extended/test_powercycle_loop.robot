*** Settings ***
Documentation   Power cycle loop. This is to test where network service
...             becomes unavailable during AC-Cycle stress test.

Resource        ../lib/rest_client.robot
Resource        ../lib/pdu/pdu.robot
Resource        ../lib/utils.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/state_manager.robot

Test Teardown   Test Exit Logs

*** Variables ***
${LOOP_COUNT}    ${50}

*** Test Cases ***

Run Multiple Power Cycle
    [Documentation]  Execute multiple power cycles.
    [Setup]  Validate Parameters
    [Tags]  Run_Multiple_Power_Cycle

    # By default run test for 50 loops, else user input iteration.
    # Fails immediately if any of the execution rounds fail and
    # check if BMC is still pinging and FFDC is collected.
    Repeat Keyword  ${LOOP_COUNT} times  Power Cycle System Via PDU


Run Multiple BMC Reset Via REST
    [Documentation]  Execute multiple reboots via REST.
    [Tags]  Run_Multiple_Reboot

    # By default run test for 50 loops, else user input iteration.
    # Fails immediately if any of the execution rounds fail and
    # check if BMC is still pinging and FFDC is collected.
    Repeat Keyword  ${LOOP_COUNT} times  BMC REST Reset Cycle


Run Multiple BMC Reset Via Reboot
    [Documentation]  Execute multiple reboots via "reboot".
    [Tags]  Run_Multiple_Reboot

    # By default run test for 50 loops, else user input iteration.
    # Fails immediately if any of the execution rounds fail and
    # check if BMC is still pinging and FFDC is collected.
    Repeat Keyword  ${LOOP_COUNT} times  BMC Reboot Cycle


*** Keywords ***

Power Cycle System Via PDU
    [Documentation]  Power cycle system and wait for BMC to reach Ready state.
    Log  "Doing power cycle"
    PDU Power Cycle
    Check If BMC Is Up  5 min  10 sec

    Wait Until Keyword Succeeds  10 min  10 sec  Is BMC Ready


BMC REST Reset Cycle
    [Documentation]  Reset BMC via REST and wait for ready state.
    Log  "Doing Reboot cycle"
    Initiate BMC Reboot
    Wait Until Keyword Succeeds  10 min  10 sec  Is BMC Ready


BMC Reboot Cycle
    [Documentation]  Reboot BMC and wait for ready state.
    Log  "Doing Reboot cycle"
    ${bmc_version_before}=
    ...  BMC Execute Command  grep ^VERSION_ID= /etc/os-release
    OBMC Reboot (off)  stack_mode=normal
    Ping Host  ${OPENBMC_HOST}
    ${bmc_version_after}=
    ...  BMC Execute Command  grep ^VERSION_ID= /etc/os-release
    Should Be Equal  ${bmc_version_before}  ${bmc_version_after}


Test Exit Logs
    Ping Host  ${OPENBMC_HOST}
    FFDC On Test Case Fail


Validate Parameters
    Should Not Be Empty   ${PDU_IP}
    Should Not Be Empty   ${PDU_TYPE}
    Should Not Be Empty   ${PDU_SLOT_NO}
    Should Not Be Empty   ${PDU_USERNAME}
    Should Not Be Empty   ${PDU_PASSWORD}

