*** Settings ***
Documentation   Power cycle loop. This is to test where network service
...             becomes unavailable during AC-Cycle stress test.

Resource        ../lib/rest_client.robot
Resource        ../lib/pdu/pdu.robot
Resource        ../lib/utils.robot
Resource        ../lib/openbmc_ffdc.robot

Test Setup      Validate Parameters
Test Teardown   Test Exit Logs

*** Variables ***
${LOOP_COUNT}    ${50}

*** Test Cases ***

Test Power Cycle
    [Documentation]   By default run test for 50 loops, else user
    ...               input iteration. Fails immediately if any
    ...               of the execution rounds fail and checks if
    ...               BMC is still pinging and FFDC is collected.

    Repeat Keyword    ${LOOP_COUNT} times   BMC Power cycle


*** Keywords ***

BMC Power cycle
    [Documentation]    Power cycle and wait for BMC to come
    ...                online to BMC_READY state.
    Log   "Doing power cycle"
    PDU Power Cycle
    Check If BMC is Up   5 min    10 sec

    Wait Until Keyword Succeeds
    ...    10 min   10 sec   Verify BMC State   BMC_READY


Test Exit Logs
    Ping Host  ${OPENBMC_HOST}
    FFDC On Test Case Fail


Validate Parameters
    Should Not Be Empty   ${PDU_IP}
    Should Not Be Empty   ${PDU_TYPE}
    Should Not Be Empty   ${PDU_SLOT_NO}
    Should Not Be Empty   ${PDU_USERNAME}
    Should Not Be Empty   ${PDU_PASSWORD}

