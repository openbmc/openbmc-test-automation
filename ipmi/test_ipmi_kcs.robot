*** Settings ***

Documentation          To Verify KCS interface.

Resource               ../lib/ipmi_client.robot
Resource               ../lib/ipmi_commands.robot
Variables              ../data/ipmi_raw_cmd_table.py
Library                ../lib/ipmi_utils.py


Suite Setup     Test Setup Execution


*** Test Cases ***

Verify KCS interface
    [Documentation]  Verify KCS interface.
    [Tags]  Verify_KCS_interface

    Verify KCS Interface Commands

*** Keywords ***

Test Setup Execution
   [Documentation]  Do suite setup tasks.

    Should Not Be Empty  ${OS_HOST}
    Should Not Be Empty  ${OS_USERNAME}
    Should Not Be Empty  ${OS_PASSWORD}
