*** Settings ***
Documentation       This module is for OS checkstop opertions.
Resource            ../../lib/rest_client.robot
Resource            ../../lib/utils.robot
Variables           ../../lib/ras/variables.py
Library             ../../lib/bmc_ssh_utils.py
Library             OperatingSystem

*** Keywords ***

Getscom Operations On OS
    [Documentation]  Executes getscom command on OS with the given
    ...              input command.
    [Arguments]      ${input_cmd}
    # Description of arguments:
    # input_cmd      -l|--list-chips
    #                -c|--chip <chip-id> <addr>

    ${output}  ${stderr}  ${rc}=  OS Execute Command  getscom ${input_cmd}
    Should Be Empty  ${stderr}
    [Return]  ${output}

Gard Operations On OS
    [Documentation]  Executes opal-gard command on OS with the given
    ...              input command.
    [Arguments]      ${input_cmd}
    # Description of arguments:
    # input_cmd      list/clear all/show <gard_record_id>

    ${output}  ${stderr}  ${rc}=  OS Execute Command  opal-gard ${input_cmd}
    Should Be Empty  ${stderr}
    [Return]  ${output}

Putscom Operations On OS
    [Documentation]  Executes putscom command on OS with the given
    ...              input arguments.
    [Arguments]      ${proc_chip_id}  ${fru}  ${address}
    # Description of arguments:
    # proc_chip_id        Processor ID (e.g '0', '8').
    # fru            FRU value (e.g. 2011400).
    # address        Chip address (e.g 4000000000000000).

    ${cmd}=  Catenate  putscom -c 0x${proc_chip_id} 0x${fru} 0x${address}
    Start Command  ${cmd}

Get ProcChipId From OS
    [Documentation]  Get processor chip ID values based on the input.
    [Arguments]      ${chip_type}
    # Description of arguments:
    # chip_type      The chip type (Processor/Centaur).

    ${cmd}=  Catenate  -l | grep -i ${chip_type} | cut -c1-8
    ${proc_chip_id}=  Getscom Operations On OS  ${cmd}
    # Example output:
    # 00000008
    # 00000000
    [Return]  ${proc_chip_id}

Get Core IDs From OS
    [Documentation]  Get Core IDs corresponding to the input processor chip ID.
    [Arguments]      ${proc_chip_id}
    # Description of argument(s):
    # proc_chip_id        Processor ID (e.g '0', '8').

    ${cmd}=  Catenate  set -o pipefail ; ${probe_cpu_file_path}
    ...    | grep -i 'CHIP ID: ${proc_chip_id}' | cut -c21-22
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    Should Be Empty  ${stderr}
    ${core_ids}=  Split String  ${output}
    # Example output:
    # ['2', '3', '4', '5', '6']
    [Return]  ${core_ids}

FIR Address Translation Through HOST
    [Documentation]  Do FIR address translation through host for given FIR,
    ...              core value & target type.
    [Arguments]  ${fir}  ${core_id}  ${target_type}
    # Description of argument(s):
    # fir          FIR (Fault isolation register) value (e.g. 2011400).
    # core_id      Core ID (e.g. 9).
    # target_type  Target type (e.g. 'EQ', 'EX', 'C').

    ${cmd}=  Catenate  set -o pipefail ; ${addr_translation_file_path} ${fir}
    ...  ${core_id} | grep -i ${target_type}
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    Should Be Empty  ${stderr}
    ${translated_addr}=  Split String  ${output}  :${SPACE}0x
    # Example output:
    # 0x10010c00
    [Return]  ${translated_addr[1]}
