*** Settings ***
Documentation   Power cycle loop. This is to test where network service
...             become unavailable during AC-Cycle stress test.

Resource        ../lib/rest_client.robot
Resource        ../lib/pdu/pdu.robot
Resource        ../lib/utils.robot
Resource        ../lib/openbmc_ffdc.robot

Test Setup      Validate PDU Env Variables
Test Teardown   Test Exit Logs

*** Variables ***
${LOOP_COUNT}    ${50}

*** Test Cases ***

Test Power Cycle
    [Documentation]   By default run test for 50 loops, else user
    ...               input iteration. Fails immediately if any
    ...               of the execution rounds fails and Check if
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
    Log FFDC


Validate PDU Env Variables

    ${PDU_IP}=   Get Environment Variable    PDU_IP
    should not be empty   ${PDU_IP}

    ${PDU_TYPE}=   Get Environment Variable    PDU_TYPE
    should not be empty   ${PDU_TYPE}

    ${PDU_SLOT_NO}=    Get Environment Variable    PDU_SLOT_NO
    should not be empty   ${PDU_SLOT_NO}

    ${PDU_USERNAME}=   Get Environment Variable    PDU_USERNAME
    should not be empty   ${PDU_USERNAME}

    ${PDU_PASSWORD}=   Get Environment Variable    PDU_PASSWORD
    should not be empty   ${PDU_PASSWORD}

