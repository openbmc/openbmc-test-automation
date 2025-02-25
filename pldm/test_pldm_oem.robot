*** Settings ***

Documentation    Module to test PLDM oem commands.

Library          ../lib/pldm_utils.py
Variables        ../data/pldm_variables.py
Resource         ../lib/openbmc_ffdc.robot

Test Setup       Printn
Test Teardown    FFDC On Test Case Fail

Test Tags       Pldm_OEM

*** Test Cases ***

Verify GetAlertStatus
    [Documentation]  Verify get alert status descriptor response message.
    [Tags]  Verify_GetAlertStatus

    ${pldm_output}=  Pldmtool  oem-ibm GetAlertStatus -i 0
    Rprint Vars  pldm_output
    Valid Value  pldm_output['rack entry']  ['0xff000030']
    Valid Value  pldm_output['pri cec node']  ['0x00008030']


Verify GetFileTable
    [Documentation]  Verify GetFileTable response message.
    [Tags]  Verify_GetFileTable

    ${pldm_output}=  Pldmtool  oem-ibm GetFileTable

    # Example output
    # [{
    #    "FileHandle": "0",
    #    "FileNameLength": 7,
    #    "FileName": "abcdxxx",
    #    "FileSize": 28672,
    #    "FileTraits": 1
    # }]

    Should Be Equal  ${pldm_output[0]["FileHandle"]}  0
    ${output_length}=  Get Length  ${pldm_output}
    Should Be True  ${output_length}>${1}
