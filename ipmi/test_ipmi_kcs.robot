*** Settings ***
Documentation       To Verify KCS interface.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/ipmi_utils.robot
Variables           ../data/ipmi_raw_cmd_table.py
Library             ../lib/ipmi_utils.py

Suite Setup         Suite Setup Execution

Test Tags           ipmi_kcs


*** Variables ***
${LOOP_COUNT}       ${1}


*** Test Cases ***
Verify KCS interface
    [Documentation]    Verify KCS interface.
    [Tags]    verify_kcs_interface

    Verify KCS Interface Commands

Verify KCS Raw IPMI Multiple Times
    [Documentation]    Verify KCS interface raw ipmi command for multiple times.
    [Tags]    verify_kcs_raw_ipmi_multiple_times

    Repeat Keyword    ${LOOP_COUNT} times    Verify KCS Interface Commands


*** Keywords ***
Suite Setup Execution
    [Documentation]    Do suite setup tasks.

    Should Not Be Empty    ${OS_HOST}    msg=Please provide required parameter OS_HOST
    Should Not Be Empty    ${OS_USERNAME}    msg=Please provide required parameter OS_USERNAME
    Should Not Be Empty    ${OS_PASSWORD}    msg=Please provide required parameter OS_PASSWORD
