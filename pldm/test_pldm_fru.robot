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

    Valid Value  pldm_output['FRUDATAMajorVersion']  [1]
    Valid Value  pldm_output['FRUDATAMinorVersion']  [0]
    Valid Value  pldm_output['FRUTableMaximumSize']  [4294967295]
    Valid Range  pldm_output['FRUTableLength']  1
    Valid Range  pldm_output['Total number of records in table']  1
    Valid Range  pldm_output['Total number of Record Set Identifiers in table']  1

Verify GetFruRecordTable
    [Documentation]  Verify GetFruRecordTable response message.
    [Tags]  Verify_GetFruRecordTable

    ${pldm_output}=  Pldmtool  fru GetFruRecordTable
    Should Not Be Empty  ${pldm_output}
    #TODO: Verify the fru table content.

Verify GetFRURecordByOption
    [Documentation]  Verify GetFRURecordByOption response message for
    ...              the available FRU record identifier.
    [Tags]  Verify_GetFRURecordByOption

    # pldm_output:
    # [fru_record_set_identifier]:                    2
    # [fru_record_type]:                              1(General)
    # [number_of_fru_fields]:                         4
    # [encoding_type_for_fru_fields]:                 1(ASCII)
    # [     fru_field_type]:                              Name
    # [     fru_field_length]:                            12
    # [     fru_field_value]:                             BMC PLANAR

    ${pldm_output}=  Pldmtool  fru GetFruRecordTableMetadata
    ${fru_rec_id}=  Convert To Integer  ${pldm_output['Total number of Record Set Identifiers in table']}
    FOR   ${i}  IN RANGE  ${fru_rec_id+1}
       ${pldm_output}=  Run Keyword  Pldmtool  fru GetFRURecordByOption -i ${i} -r 0 -f 0
       Run Keyword  Rprint Vars  pldm_output
       Should Not Be Empty  ${pldm_output}
    END
