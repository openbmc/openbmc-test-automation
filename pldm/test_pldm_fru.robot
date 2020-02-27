*** Settings ***

Documentation    Module to test PLDM FRU (Field Replaceable Unit) commands.

Library          ../lib/pldm_utils.py
Variables        ../data/pldm_variables.py
Resource         ../lib/openbmc_ffdc.robot

Test Setup       Printn
Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify GetFruRecordTableMetadata
    [Documentation]  Verify get fru record table meta data response message.
    [Tags]  Verify_GetFruRecordTableMetadata

    # pldm_output:
    # [frudatamajorversion]:                              1
    # [frudataminorversion]:                              0
    # [frutablemaximumsize]:                              4294967295
    # [frutablelength]:                                   60
    # [total_number_of_record_set_identifiers_in_table]:  1
    # [total_number_of_records_in_table]:                 1

    ${pldm_output}=  Pldmtool  fru GetFruRecordTableMetadata
    Rprint Vars  pldm_output

    Valid Value  pldm_output['frudatamajorversion']  ['1']
    Valid Value  pldm_output['frudataminorversion']  ['0']
    Valid Value  pldm_output['frutablemaximumsize']  ['4294967295']
    Valid Range  ${pldm_output['frutablelength']}  1
    Valid Range  ${pldm_output['total_number_of_records_in_table']}  1
    Valid Range  ${pldm_output['total_number_of_record_set_identifiers_in_table']}  1
