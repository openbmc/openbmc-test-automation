*** Settings ***

Documentation          To Verify Lanplus interface

Resource               ../lib/ipmi_client.robot
Resource               ../lib/ipmi_utils.robot
Variables              ../data/ipmi_raw_cmd_table.py
Library                ../lib/ipmi_utils.py

Force Tags             IPMI_LANplus

*** Variables ***

${LOOP_COUNT}          ${1}


*** Test Cases ***

Verify Lanplus Raw IPMI Commands Multiple Times
    [Documentation]  Verify Lanplus interface With raw ipmi command for multiple times.
    [Tags]  Verify_Lanplus_Raw_IPMI_Commands_Multiple_Times

    Repeat Keyword  ${LOOP_COUNT} times  Verify Lanplus Interface Commands


Verify Lanplus Interface
    [Documentation]  Verify Lanplus interface.
    [Tags]  Verify_Lanplus_Interface

    Verify Lanplus Interface Commands

