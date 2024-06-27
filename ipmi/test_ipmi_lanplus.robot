*** Settings ***
Documentation       To Verify Lanplus interface

Resource            ../lib/ipmi_client.robot
Resource            ../lib/ipmi_utils.robot
Variables           ../data/ipmi_raw_cmd_table.py
Library             ../lib/ipmi_utils.py

Test Tags           ipmi_lanplus


*** Variables ***
${LOOP_COUNT}       ${1}


*** Test Cases ***
Verify Lanplus Raw IPMI Commands Multiple Times
    [Documentation]    Verify Lanplus interface With raw ipmi command for multiple times.
    [Tags]    verify_lanplus_raw_ipmi_commands_multiple_times

    Repeat Keyword    ${LOOP_COUNT} times    Verify Lanplus Interface Commands

Verify Lanplus Interface
    [Documentation]    Verify Lanplus interface.
    [Tags]    verify_lanplus_interface

    Verify Lanplus Interface Commands
