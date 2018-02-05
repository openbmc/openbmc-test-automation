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
    [Tags]  Run_Multiple_BMC_Reset_Via_REST

    # By default run test for 50 loops, else user input iteration.
    # Fails immediately if any of the execution rounds fail and
    # check if BMC is still pinging and FFDC is collected.
    Repeat Keyword  ${LOOP_COUNT} times  BMC REST Reset Cycle


Run Multiple BMC Reset Via Reboot
    [Documentation]  Execute multiple reboots via "reboot" command.
    [Tags]  Run_Multiple_BMC_Reset_Via_Reboot

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
    Verify BMC RTC And UTC Time Drift
    Field Mode Should Be Enabled


BMC REST Reset Cycle
    [Documentation]  Reset BMC via REST and wait for ready state.
    Log  "Doing Reboot cycle"
    ${bmc_version_before}=  Get BMC Version
    Initiate BMC Reboot
    Wait Until Keyword Succeeds  10 min  10 sec  Is BMC Ready
    ${bmc_version_after}=  Get BMC Version
    Should Be Equal  ${bmc_version_before}  ${bmc_version_after}
    Verify BMC RTC And UTC Time Drift
    Field Mode Should Be Enabled


BMC Reboot Cycle
    [Documentation]  Reboot BMC and wait for ready state.
    Log  "Doing Reboot cycle"
    ${bmc_version_before}=  Get BMC Version
    OBMC Reboot (off)  stack_mode=normal
    ${bmc_version_after}=  Get BMC Version
    Should Be Equal  ${bmc_version_before}  ${bmc_version_after}
    Verify BMC RTC And UTC Time Drift
    Field Mode Should Be Enabled


Test Teardown Execution
    [Documentation]  Do test case tear-down.
    Ping Host  ${OPENBMC_HOST}
    FFDC On Test Case Fail

    # Example of the u-boot-env o/p:
    # root@witherspoon:~# grep fieldmode /dev/mtd/u-boot-env
    # fieldmode=true
    # fieldmode=true
    ${field_mode}=
    ...  BMC Execute Command  grep fieldmode /dev/mtd/u-boot-env
    Should Contain  "${field_mode[0]}"  fieldmode=true
    ...  msg=u-boot-env shows "fieldmode" is not set to true.


Validate Parameters
    [Documentation]  Validate PDU parameters.
    Should Not Be Empty   ${PDU_IP}
    Should Not Be Empty   ${PDU_TYPE}
    Should Not Be Empty   ${PDU_SLOT_NO}
    Should Not Be Empty   ${PDU_USERNAME}
    Should Not Be Empty   ${PDU_PASSWORD}


Suite Setup Execution
    [Documentation]  Enable field mode.
    Enable Field Mode And Verify Unmount
    Field Mode Should Be Enabled
