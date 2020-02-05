*** Settings ***

Documentation    Module to test PLDM FRU (Field Replaceable Unit) commands.

Library          ../lib/pldm_utils.py
Variables        ../data/pldm_variables.py
Resource         ../lib/openbmc_ffdc.robot

Test Setup       Printn
Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify GetFruRecordTableMetadata
    [Documentation]  Verify get fru record table meta data reponse message.
    [Tags]  Verify_GetFruRecordTableMetadata

    # pldm_output:
    # [frutablelength]:                                   60
    # [frudatamajorversion]:                              1
    # [total_number_of_record_set_identifiers_in_table]:  1
    # [frudataminorversion]:                              0
    # [total_number_of_records_in_table]:                 1
    # [frutablemaximumsize]:                              4294967295

    ${pldm_output}=  Pldmtool  fru GetFruRecordTableMetadata
    Rprint Vars  pldm_output
    Valid Dict  pldm_output  valid_values=${RESPONSE_DICT_GETFRURECORDTABLEMETADATA}
