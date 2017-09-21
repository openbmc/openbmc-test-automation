*** Settings ***
Documentation       This module is for OS checkstop opertions.
Resource            ../../lib/rest_client.robot
Resource            ../../lib/utils.robot
Resource            ../../lib/ras/variables.py
Resource            ../../lib/bmc_ssh_utils.py
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
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    [Return]  ${output}

Gard Operations On OS
    [Documentation]  Executes opal-gard command on OS with the given
    ...              input command.
    [Arguments]      ${input_cmd}
    # Description of arguments:
    # input_cmd      list/clear all/show <gard_record_id>

    ${output}  ${stderr}  ${rc}=  OS Execute Command  opal-gard ${input_cmd}
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    [Return]  ${output}

Putscom Through OS
    [Documentation]  Executes putscom command on OS with the given
    ...              input arguments.
    [Arguments]      ${proc_chip_id}  ${fru}  ${address}
    # Description of arguments:
    # proc_chip_id        Processor ID (e.g '0', '8').
    # fru            FRU value (e.g. 2011400).
    # address        Chip address (e.g 4000000000000000).

    ${cmd}=  Catenate  putscom -c 0x${proc_chip_id} 0x${fru} 0x${address}
    Start Command  ${cmd}

Get ChipID From OS
    [Documentation]  Get chip ID values based on the input.
    [Arguments]      ${chip_type}
    # Description of arguments:
    # chip_type      The chip type (Processor/Centaur).

    ${cmd}=  Catenate  -l | grep -i ${chip_type} | cut -c1-8
    ${proc_chip_id}=  Getscom Operations On OS  ${cmd}
    [Return]  ${proc_chip_id}


Get Core IDs From OS
    [Documentation]  Get Core IDs corresponding to the input processor chip ID.
    [Arguments]      ${proc_chip_id}
    # Description of argument(s):
    # proc_chip_id        Processor ID (e.g '0', '8').

    SSHLibrary.File Should Exist  ${probe_cpu_file}
    ${cmd}=  Catenate  ${probe_cpu_file} | grep -i 'CHIP ID: ${proc_chip_id}'
    ...  | cut -c21-22
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}  return_stderr=True
    ${core_ids}=  Split String  ${output}
    [Return]  ${core_ids}

FIR Address Translation Through HOST
    [Documentation]  Do FIR address translation through host with given FRI,
    ...              core value & target type.
    [Arguments]  ${fir}  ${core_id}  ${target_type}
    # Description of argument(s):
    # fri          FRI value (e.g. 2011400).
    # core_id      Core ID (e.g. 9).
    # target_type  Target type (e.g. 'EQ', 'EX', 'C').

    SSHLibrary.File Should Exist  ${Adrs_translation_file}
    ${cmd}=  Catenate  set -o pipefail ; ${Adrs_translation_file} ${fir}
    ...  ${core_id} | grep -i ${target_type}
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    ...  return_stderr=True
    # Example
    # EX[ 1]: 0x10010c00
    ${translated_addr}=  Split String  ${output}  :${SPACE}0x
    [Return]  ${translated_addr[1]}
