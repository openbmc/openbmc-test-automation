*** Settings ***

Documentation    Module to test PLDM base commands.
Library          ../lib/pldm_utils.py
Variables        ../data/pldm_variables.py
Resource         ../lib/openbmc_ffdc.robot

Test Setup       Printn
Test Teardown    FFDC On Test Case Fail


*** Test Cases ***

Verify Get PLDM Types
    [Documentation]  Verify supported PLDM types.
    [Tags]  Verify_Get_PLDM_Types

    ${pldm_output}=  Pldmtool  base GetPLDMTypes
    Valid List  pldm_output['supported_types']['text']  required_values=${PLDM_SUPPORTED_TYPES}

Verify Get PLDM Version For Base
    [Documentation]  Verify supported PLDM version for base type.
    [Tags]  Verify_Get_PLDM_Version_For_Base

    ${pldm_cmd}=  Evaluate  $CMD_GETPLDMVERSION % 'base'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Valid Value  pldm_output['type_0(base)']  ['${VERSION_BASE['STRING']}']


Verify Get PLDM Version For Platform
    [Documentation]  Verify supported PLDM version for platform type.
    [Tags]  Verify_Get_PLDM_Version_For_Platform

    ${pldm_cmd}=  Evaluate  $CMD_GETPLDMVERSION % 'platform'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Valid Value  pldm_output['type_2(platform)']  ['${VERSION_PLATFORM['STRING']}']


Verify Get PLDM Version For BIOS
    [Documentation]  Verify supported PLDM version for BIOS type.
    [Tags]  Verify_Get_PLDM_Version_For_BIOS

    ${pldm_cmd}=  Evaluate  $CMD_GETPLDMVERSION % 'bios'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Valid Value  pldm_output['type_3(bios)']  ['${VERSION_BIOS['STRING']}']


Verify Get PLDM Version For FRU
    [Documentation]  Verify supported PLDM version for FRU type.
    [Tags]  Verify_Get_PLDM_Version_For_FRU

    ${pldm_cmd}=  Evaluate  $CMD_GETPLDMVERSION % 'fru'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Valid Value  pldm_output['type_4(fru)']  ['${VERSION_FRU['STRING']}']


Verify Get PLDM Version For OEM
    [Documentation]  Verify supported PLDM version for oem-ibm type.
    [Tags]  Verify_Get_PLDM_Version_For_OEM

    ${pldm_cmd}=  Evaluate  $CMD_GETPLDMVERSION % 'oem-ibm'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Valid Value  pldm_output['type_63(oem-ibm)']  ['${VERSION_OEM['STRING']}']


Verify GetTID
    [Documentation]  Verify GetTID (Terminus ID) response message.
    [Tags]  Verify_GetTID

    # Example output:
    # TID : 1

    ${pldm_output}=  Pldmtool  base GetTID
    Rprint Vars  pldm_output

    Valid Dict  pldm_output  valid_values={'tid': ['1']}

Verify GetPLDMCommands
    [Documentation]  Verify GetPLDMCommands response message.
    [Tags]  Verify_GetPLDMCommands
    [Template]  Verify GetPLDMCommands For PLDM Type

    # pldm_type    # expected_pldm_cmds

    '0'            ${PLDM_BASE_CMDS}
    '2'            ${PLDM_PLATFORM_CMDS}
    '3'            ${PLDM_BIOS_CMDS}
    '4'            ${PLDM_FRU_CMDS}
    '63'           ${PLDM_OEM_CMDS}

*** keywords ***

Verify GetPLDMCommands For PLDM Type
    [Documentation]  Verify GetPLDMCommands for given input pldm type with expected pldm cmds.
    [Arguments]  ${pldm_type}  ${expected_pldm_cmds}

    # Description of argument(s):
    # pldm_type             pldm type (e.g. '0', '2', '3', '4', '63').
    #                      '0' -> base, '2' -> platform, '3' -> 'bios', '4' -> 'fru'
    #                      '63' -> oem-ibm.
    # expected_pldm_cmds    expected pldm commands for given pldm type.

    # Example output:
    # Supported Commands : 2(GetTID) 3(GetPLDMVersion) 4(GetPLDMTypes) 5(GetPLDMCommands)

    ${pldm_output}=  Pldmtool  base GetPLDMCommands -t ${pldm_type}
    Rprint Vars  pldm_output
    Valid List  pldm_output  ${expected_pldm_cmds}
