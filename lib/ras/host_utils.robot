*** Settings ***
Documentation       This module is for OS checkstop opertions.
Resource            ../../lib/rest_client.robot
Resource            ../../lib/utils.robot
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

    Log To Console  INPUT_COMMAND  ${input_cmd}
    ${cmd}=  Catenate  sudo skiboot/external/gard/gard ${input_cmd}
    ${output}  ${stderr}=  Execute Command  ${cmd} 
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

Get Cores Values From OS
    [Documentation]  Check if cores present on HOST OS & return core values.
    ${cmd}=  Catenate  cat /sys/firmware/opal/msglog|grep -i chip|grep -i core
    ${output}=  Execute Command  ${cmd}
    Should Not Be Empty  ${output}
    [Return]  ${output}

Get ChipID From OS
    [Documentation]  Get chip ID values based on the input.
    [Arguments]      ${chip_type}
    # Description of arguments:
    # chip_type      The chip type (Processor/Centaur).

    ${cmd}=  Catenate  -l | grep -i ${chip_type} | cut -c1-8
    ${chip_id}=  Getscom Operations On OS  ${cmd}
    [Return]  ${chip_id}
