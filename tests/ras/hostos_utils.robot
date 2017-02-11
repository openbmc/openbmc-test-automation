*** Settings ***
Documentation       This module is for OS checkstop checkstop opertions.
Resource            ../../lib/rest_client.robot
Resource            ../../lib/utils.robot

*** Keywords ***

Getscom Values From OS
    [Documentation]  Get scom values from OS.

    ${output}  ${stderr}=  Execute Command  getscom -l  return_stderr=True
    Should Be Empty  ${stderr}
    [Return]  ${output}

Gard Operations On OS
    [Documentation]  Perform gard related operations on OS
    ...              with the given input command.
    [Arguments]      ${input_cmd}
    #input_cmd       list/clear all/show <gard_record_id>

    ${output}  ${stderr}=  Execute Command  opal-gard ${input_cmd}
    ...        return_stderr=True
    Should Be Empty  ${stderr}
    [Return]  ${output}

Inject Checkstop On OS
    [Documentation]  Using putscom inject checkstop on OS.
    [Arguments]  ${chip_id}  ${fru}  ${address}
    #chip_id           processor ID
    #fru               FRU value
    #address           chip address

    ${cmd}=  Catenate  putscom -c 0x${chip_id} 0x${fru} 0x${adress}
    Start Command  ${cmd}
