*** Settings ***

Documentation    Module to test PLDM oem commands.

Library          ../lib/pldm_utils.py
Variables        ../data/pldm_variables.py
Resource         ../lib/openbmc_ffdc.robot

Test Setup       Printn
Test Teardown    FFDC On Test Case Fail


*** Test Cases ***

Verify GetAlertStatus
    [Documentation]  Verify get alert status descriptor response message.
    [Tags]  Verify_GetAlertStatus

    ${pldm_output}=  Pldmtool  oem-ibm GetAlertStatus -i 0
    Rprint Vars  pldm_output
    Valid Value  pldm_output['rack entry']  ['0xff000030']
    Valid Value  pldm_output['pri cec node']  ['0x00008030']

