*** Settings ***
Documentation       This module is for OS checkstop opertions.
Resource            ../../lib/rest_client.robot
Resource            ../../lib/utils.robot
Library             OperatingSystem

*** Keywords ***

Getscom Operations On OS
    [Documentation]  Executes getscom command on OS
    ...              with the given input command.
    [Arguments]      ${input_cmd}
    #input_cmd       -l|--list-chips
    #                -c|--chip <chip-id> <addr>

    ${output}  ${stderr}=  Execute Command  getscom ${input_cmd}
    ...        return_stderr=True
    Should Be Empty  ${stderr}
    [Return]  ${output}

Gard Operations On OS
    [Documentation]  Executes opal-gard command on OS
    ...              with the given input command.
    [Arguments]      ${input_cmd}
    #input_cmd       list/clear all/show <gard_record_id>

    ${output}  ${stderr}=  Execute Command  opal-gard ${input_cmd}
    ...        return_stderr=True
    Should Be Empty  ${stderr}
    [Return]  ${output}

Putscom Through OS
    [Documentation]  Executes putscom command on OS
    ...              with the given input arguments.
    [Arguments]      ${chip_id}  ${fru}  ${address}
    #chip_id         processor ID
    #fru             FRU value
    #address         chip address

    ${cmd}=  Catenate  putscom -c 0x${chip_id} 0x${fru} 0x${address}
    Start Command  ${cmd}

Get Cores Values From OS
    [Documentation]  Checks if cores present on HOST OS
    ...              and returns core values

    ${output}=  Execute Command  cat /sys/firmware/opal/msglog | grep -i chip | grep -i core
    Should Not Be Empty  ${output}
    [Return]  ${output}

Get ChipID From OS
    [Documentation]  Get chip ID values based on the input.
    [Arguments]      ${chip_type}
    #chip_type       Processor/Centaur

    ${chip_id}=  Getscom Operations On OS  -l | grep -i ${chip_type} | cut -c1-8
    [Return]  ${chip_id}
