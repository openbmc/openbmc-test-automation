*** Settings ***
Documentation       This module for OS related opertions.
Resource            ../../lib/rest_client.robot
Resource            ../../lib/utils.robot
Resource            ../../lib/resource.txt

*** Keywords ***

Is Skiboot Installed On OS

    [Documentation]  Checks if skiboot directory is installed on OS.

    Execute Command  Directory Should Exist  skiboot
    ${current_dir}=  Execute Command  pwd
    Should Not Be Empty  ${current_dir}
    Log To Console  ${current_dir}

    ${skiboot_util_dir}=  Catenate  ${current_dir}/skiboot/external/
    Log To Console  ${skiboot_util_dir}
    [Return]  ${skiboot_util_dir}

Get Core Values From OS

    [Documentation]  Get core values from OS.

    ${cmd}=  Catenate  ${CORE_VALUES_FROM_OS}
    ${output}=  Execute Command  ${cmd}
    Should Not Be Empty  ${output}
    [Return]  ${output}

Getscom Values From OS

    [Documentation]  Get scom values from OS.
    [Arguments]  ${skiboot_util_dir}
    #skiboot_util_dir  skiboot utility path 

    ${xscomutil_dir}=  Catenate  ${skiboot_util_dir}/xscom-utils/
    Execute Command  Directory Should Exist  ${xscomutil_dir}
    ${cmd}=  Catenate  sudo ${xscomutil_dir}/getscom -l
    ${output}=  Execute Command  ${cmd}
    Should Not Be Empty  ${output}
    [Return]  ${output}

Gard Operations On OS

    [Documentation]  Perform gard related operations on OS
    ...              with the given input command.
    [Arguments]  ${skiboot_util_dir}  ${input_cmd}
    #skiboot_util_dir  skiboot utility path 
    #input_cmd         list/clear all/show <gard_record_id>

    ${gardutil_dir}=  Catenate  ${skiboot_util_dir}/gard
    Execute Command  Directory Should Exist  ${gardutil_dir}
    ${cmd}=  Catenate  ${gardutil_dir}/gard ${input_cmd}
    ${output}=  Execute Command  ${cmd}
    Should Not Be Empty  ${output}
    [Return]  ${output}

Inject Checkstop On OS

    [Documentation]  Using putscom inject checkstop on OS.
    [Arguments]  ${skiboot_util_dir}  ${chip_id}  ${fru}  ${address}
    #skiboot_util_dir  skiboot utility path 
    #chip_id           processor ID
    #fru               FRU value
    #address           chip address

    ${pustscom_dir}=  Catenate  ${skiboot_util_dir}xscom-utils/putscom
    ${cmd}=  Catenate  sudo ${pustscom_dir} -c 0x${chip_id} 0x${fru} 0x${adress}
     Command  ${cmd}
