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

    ${pldm_results}=  Pldmtool  base GetPLDMTypes
    Valid List  pldm_results['supported_types']['text']  required_values=${required_supported_types}

Verify Get PLDM Version For Base Type
    [Documentation]  Verify supported PLDM version for base type.
    [Tags]  Verify_Get_PLDM_Version_For_Base_Type

    ${pldm_results}=  Pldmtool  base GetPLDMVersion -t base
    Valid Value  pldm_results['type_0(base)']  ["1.0.0"]


Verify Get PLDM Version For Platform Type
    [Documentation]  Verify supported PLDM version for platform type.
    [Tags]  Verify_Get_PLDM_Version_For_Platform_Type

    ${pldm_results}=  Pldmtool  base GetPLDMVersion -t platform
    Valid Value  pldm_results['type_2(platform)']  ["1.1.1"]


Verify Get PLDM Version For BIOS Type
    [Documentation]  Verify supported PLDM version for BIOS type.
    [Tags]  Verify_Get_PLDM_Version_For_BIOS_Type

    ${pldm_results}=  Pldmtool  base GetPLDMVersion -t bios
    Valid Value  pldm_results['type_3(bios)']  ["1.0.0"]


Verify Get PLDM Version For FRU Type
    [Documentation]  Verify supported PLDM version for FRU type.
    [Tags]  Verify_Get_PLDM_Version_For_FRU_Type

    ${pldm_results}=  Pldmtool  base GetPLDMVersion -t fru
    Valid Value  pldm_results['type_4(fru)']  ["1.0.0"]

