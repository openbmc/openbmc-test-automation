*** Settings ***

Documentation          To Verify Lanplus interface

Resource               ../lib/ipmi_client.robot
Resource               ../lib/ipmi_commands.robot
Variables              ../data/ipmi_raw_cmd_table.py
Library                ../lib/ipmi_utils.py

*** Test Cases ***

Verify Lanplus Interface
    [Documentation]  Verify Lanplus interface.
    [Tags]  verify_lanplus_interface

    Verify Lanplus Interface Commands

