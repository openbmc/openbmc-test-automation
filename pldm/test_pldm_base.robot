*** Settings ***

Documentation    Module to test PLDM base commands.
Library          ../lib/pldm_utils.py
Variables        ../data/pldm_variables.py
Resource         ../lib/openbmc_ffdc.robot

Test Setup       Printn
Test Teardown    FFDC On Test Case Fail

Test Tags       Pldm_Base

*** Test Cases ***

Verify Get PLDM Types
    [Documentation]  Verify supported PLDM types.
    [Tags]  Verify_Get_PLDM_Types

    ${pldm_output}=  Pldmtool  base GetPLDMTypes
    ${count}=  Get Length  ${pldm_output}
    ${cmd_list}=  Create List
    FOR  ${i}  IN RANGE  ${count}
      ${cmd}=  Catenate  ${pldm_output}[${i}][PLDM Type Code](${pldm_output}[${i}][PLDM Type])
      Append To List  ${cmd_list}  ${cmd}
    END
    Valid List  cmd_list  required_values=${PLDM_SUPPORTED_TYPES}

Verify Get PLDM Version For Base
    [Documentation]  Verify supported PLDM version for base type.
    [Tags]  Verify_Get_PLDM_Version_For_Base

    ${pldm_cmd}=  Evaluate  $CMD_GETPLDMVERSION % 'base'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Valid Value  pldm_output['Response']  ['${VERSION_BASE['STRING']}']

Verify Get PLDM Version For Platform
    [Documentation]  Verify supported PLDM version for platform type.
    [Tags]  Verify_Get_PLDM_Version_For_Platform

    ${pldm_cmd}=  Evaluate  $CMD_GETPLDMVERSION % 'platform'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Valid Value  pldm_output['Response']  ['${VERSION_PLATFORM['STRING']}']


Verify Get PLDM Version For BIOS
    [Documentation]  Verify supported PLDM version for BIOS type.
    [Tags]  Verify_Get_PLDM_Version_For_BIOS

    ${pldm_cmd}=  Evaluate  $CMD_GETPLDMVERSION % 'bios'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Valid Value  pldm_output['Response']  ['${VERSION_BIOS['STRING']}']


Verify Get PLDM Version For FRU
    [Documentation]  Verify supported PLDM version for FRU type.
    [Tags]  Verify_Get_PLDM_Version_For_FRU

    ${pldm_cmd}=  Evaluate  $CMD_GETPLDMVERSION % 'fru'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Valid Value  pldm_output['Response']  ['${VERSION_FRU['STRING']}']


Verify Get PLDM Version For OEM
    [Documentation]  Verify supported PLDM version for oem-ibm type.
    [Tags]  Verify_Get_PLDM_Version_For_OEM

    ${pldm_cmd}=  Evaluate  $CMD_GETPLDMVERSION % 'oem-ibm'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Valid Value  pldm_output['Response']  ['${VERSION_OEM['STRING']}']


Verify GetTID
    [Documentation]  Verify GetTID (Terminus ID) response message.
    [Tags]  Verify_GetTID

    # Example output:
    # {
    #     'Response' : 1
    # }

    ${pldm_output}=  Pldmtool  base GetTID
    Valid Value  pldm_output['Response']  [1]

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


Verify Verbose Flag For PLDM Subsystem Commands
    [Documentation]  Verify verbose flag for PLDM subsystem commands.
    [Tags]  Verify_Verbose_Flag_For_PLDM_Subsystem_Commands

    ${pldm_output}=  Pldmtool  base GetPLDMTypes -v
    Should Contain  ${pldm_output}  pldmtool: Tx:
    Should Contain  ${pldm_output}  pldmtool: Rx:

    ${pldm_output}=  Pldmtool  bios GetDateTime -v
    Should Contain  ${pldm_output}  pldmtool: Tx:
    Should Contain  ${pldm_output}  pldmtool: Rx:


Verify Response For PLDM Raw Commands
    [Documentation]  Verify response for PLDM raw commands.
    [Tags]  Verify_Response_For_PLDM_Raw_Commands

    # Example output format:
    # pldmtool raw -d 0x80 0x00 0x04
    # pldmtool: Tx: 80 00 04
    # pldmtool: Rx: 00 00 04 00 1d 00 00 00 00 00 00 80

    ${pldm_output}=  Pldmtool  ${PLDM_GET_PLDM_TYPES_RAW_CMD}
    Should Contain  ${pldm_output}  ${PLDM_GET_PLDM_TYPES_RAW_CMD_OUTPUT}


Verify Verbose Flag For PLDM Raw Command
    [Documentation]  Verify PLDM raw command with verbose flag,
    [Tags]  Verify_Verbose_Flag_For_PLDM_Raw_Command

    # Example output format:
    # pldmtool raw -d 0x80 0x00 0x04 -v
    # pldmtool: Tx: 80 00 04
    # pldmtool: Rx: 00 00 04 00 1d 00 00 00 00 00 00 80

    ${pldm_output}=  Pldmtool  ${PLDM_GET_PLDM_TYPES_RAW_CMD} -v
    Should Contain  ${pldm_output}  ${PLDM_GET_PLDM_TYPES_RAW_CMD_OUTPUT}


Verify Verbose Flag For Incorrect PLDM Raw Command
    [Documentation]  Verify incorrect PLDM raw command with verbose flag,
    [Tags]  Verify_Verbose_Flag_For_Incorrect_PLDM_Raw_Command

    # Example output format:
    # pldmtool raw -d 0x80 0x00 0x00 -v
    # pldmtool: Tx: 80 00 04
    # pldmtool: Rx: 00 00 00 05

    ${pldm_output}=  Pldmtool  ${PLDM_RAW_CMD_INVALID} -v
    Should Contain  ${pldm_output}  ${PLDM_RAW_CMD_INVALID_OUTPUT}


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
    ${count}=  Get Length  ${pldm_output}
    ${cmd_list}=  Create List
    FOR  ${i}  IN RANGE  ${count}
      ${cmd}=  Catenate  ${pldm_output}[${i}][PLDM Command Code](${pldm_output}[${i}][PLDM Command])
      Append To List  ${cmd_list}  ${cmd}
    END
    Valid List  cmd_list  required_values=${expected_pldm_cmds}
