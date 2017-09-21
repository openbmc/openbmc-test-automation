*** Settings ***
Documentation       This module is for OS checkstop opertions.
Resource            ../../lib/rest_client.robot
Resource            ../../lib/utils.robot
Resource            ../../lib/ras/variables.py
Library             OperatingSystem

*** Keywords ***

Getscom Operations On OS
    [Documentation]  Executes getscom command on OS with the given
    ...              input command.
    [Arguments]      ${input_cmd}
    # Description of arguments:
    # input_cmd      -l|--list-chips
    #                -c|--chip <chip-id> <addr>

    ${output}  ${stderr}=  Execute Command  getscom ${input_cmd}
    ...        return_stderr=True
    Should Be Empty  ${stderr}
    [Return]  ${output}

Gard Operations On OS
    [Documentation]  Executes opal-gard command on OS with the given
    ...              input command.
    [Arguments]      ${input_cmd}
    # Description of arguments:
    # input_cmd      list/clear all/show <gard_record_id>

    ${output}  ${stderr}=  Execute Command  opal-gard ${input_cmd}
    ...        return_stderr=True
    Should Be Empty  ${stderr}
    [Return]  ${output}

Putscom Through OS
    [Documentation]  Executes putscom command on OS with the given
    ...              input arguments.
    [Arguments]      ${chip_id}  ${fru}  ${address}
    # Description of arguments:
    # chip_id        processor ID (e.g 00000000).
    # fru            FRU value (e.g. 2011400).
    # address        chip address (e.g 4000000000000000).

    ${cmd}=  Catenate  putscom -c 0x${chip_id} 0x${fru} 0x${address}
    Start Command  ${cmd}

Get ChipID From OS
    [Documentation]  Get chip ID values based on the input.
    [Arguments]      ${chip_type}
    # Description of arguments:
    # chip_type      The chip type (Processor/Centaur).

    ${cmd}=  Catenate  -l | grep -i ${chip_type} | cut -c1-8
    ${chip_id}=  Getscom Operations On OS  ${cmd}
    [Return]  ${chip_id}


Get Core IDs From OS
    [Documentation]  Get Core IDs corresponding to the input processor chip ID.
    [Arguments]      ${chip_ID}
    # Description of argument(s):
    # chip_id        processor ID (e.g 0/8).

    SSHLibrary.File Should Exist  ${probe_cpu_file}
    ${cmd}=  Catenate  ${probe_cpu_file} | grep -i 'CHIP ID: ${chip_ID}'
    ...      | cut -c21-22
    ${output}  ${stderr}=  Execute Command  ${cmd}  return_stderr=True
    ${core_ids}=  Split String  ${output}
    [Return]  ${core_ids}

FIR Address Translation Through HOST
    [Documentation]  Do FIR address translation through host with given FRI,
    ...              core value & target type.
    [Arguments]  ${fir}  ${core_ID}  ${target_type}
    # Description of argument(s):
    # fri          FRI value (e.g. 2011400).
    # core_ID      core ID (e.g. 9).
    # target_type  target type (e.g. EX/EQ/C).


    SSHLibrary.File Should Exist  ${Adrs_translation_file}
    ${cmd}=  Catenate  ${Adrs_translation_file} ${fir} ${core_ID}
    ...       | grep -i ${target_type}
    ${output}  ${stderr}=  Execute Command  ${cmd}
    ...        return_stderr=True
    ${translated_adrs}=  Split String  ${output}  :${SPACE}0x
    ${translated_adrs}=  Get From List  ${translated_adrs}  1
    [Return]  ${translated_adrs}
