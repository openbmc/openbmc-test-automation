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
    Valid Value  pldm_output['type_0(base)']  ${VERSION_BASE['STRING']}


Verify Get PLDM Version For Platform
    [Documentation]  Verify supported PLDM version for platform type.
    [Tags]  Verify_Get_PLDM_Version_For_Platform

    ${pldm_cmd}=  Evaluate  $CMD_GETPLDMVERSION % 'platform'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Valid Value  pldm_output['type_2(platform)']  ${VERSION_PLATFORM['STRING']}


Verify Get PLDM Version For BIOS
    [Documentation]  Verify supported PLDM version for BIOS type.
    [Tags]  Verify_Get_PLDM_Version_For_BIOS

    ${pldm_cmd}=  Evaluate  $CMD_GETPLDMVERSION % 'bios'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Valid Value  pldm_output['type_3(bios)']  ${VERSION_BIOS['STRING']}


Verify Get PLDM Version For FRU
    [Documentation]  Verify supported PLDM version for FRU type.
    [Tags]  Verify_Get_PLDM_Version_For_FRU

    ${pldm_cmd}=  Evaluate  $CMD_GETPLDMVERSION % 'fru'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Valid Value  pldm_output['type_4(fru)']  ${VERSION_FRU['STRING']}
