*** Settings ***

Documentation    Module to test PLDM base commands.
Library          ../lib/pldm_utils.py
Resource         ../lib/openbmc_ffdc.robot

Test Teardown    FFDC On Test Case Fail


*** Test Cases ***

Verify Get PLDM Types
    [Documentation]  Verify supported PLDM types.
    [Tags]  Verify_Get_PLDM_Types

    ${pldm_output}=  Get PLDM Output  base GetPLDMTypes
    Should Contain  ${pldm_output['supported_types']}  0(base)  2(platform)  3(bios)


Verify Get PLDM Version For Base Type
    [Documentation]  Verify supported PLDM version for base type.
    [Tags]  Verify_Get_PLDM_Version_For_Base_Type

    ${pldm_output}=  Get PLDM Output  base GetPLDMVersion -t base
    Valid Value  pldm_output['type_0(base)']  ["1.0.0"]


Verify Get PLDM Version For Platform Type
    [Documentation]  Verify supported PLDM version for platform type.
    [Tags]  Verify_Get_PLDM_Version_For_Platform_Type

    ${pldm_output}=  Get PLDM Output  base GetPLDMVersion -t platform
    Valid Value  pldm_output['type_2(platform)']  ["1.1.1"]


Verify Get PLDM Version For BIOS Type
    [Documentation]  Verify supported PLDM version for BIOS type.
    [Tags]  Verify_Get_PLDM_Version_For_BIOS_Type

    ${pldm_output}=  Get PLDM Output  base GetPLDMVersion -t bios
    Valid Value  pldm_output['type_3(bios)']  ["1.0.0"]


Verify Get PLDM Version For FRU Type
    [Documentation]  Verify supported PLDM version for FRU type.
    [Tags]  Verify_Get_PLDM_Version_For_FRU_Type

    ${pldm_output}=  Get PLDM Output  base GetPLDMVersion -t fru
    Valid Value  pldm_output['type_4(fru)']  ["1.0.0"]
