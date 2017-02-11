*** Settings ***
Resource            ../../lib/rest_client.robot
Resource            ../../lib/utils.robot

*** Keywords ***

Check If Skiboot Is Installed On Host OS

    [Documentation]  Checks if skiboot directory is installed on HOST OS
    ...              and returns the skiboot directory path

    Execute Command  Directory Should Exist  skiboot
    ${current_dir}=  Execute Command  pwd
    Should Not Be Empty  ${current_dir}
    Log To Console  ${current_dir}

    ${skiboot_util_dir}=  Catenate  ${current_dir}/skiboot/external/
    Log To Console  ${skiboot_util_dir}
    [Return]  ${skiboot_util_dir}

Check If Cores Present On Host OS 

    [Documentation]  Checks if cores present on HOST OS
    ...              and returns core values

    ${cmd}=  Catenate  cat /sys/firmware/opal/msglog |grep -i chip|grep -i core
    ${output}=  Execute Command  ${cmd}
    Should Not Be Empty  ${output}
    [Return]  ${output}

Getscom Values On Host OS

    [Documentation]  Get scom values present on HOST OS and
    ...              returns the response of getscom values
    [Arguments]  ${skiboot_util_dir}

    ${xscomutil_dir}=  Catenate  ${skiboot_util_dir}/xscom-utils/
    Execute Command  Directory Should Exist  ${xscomutil_dir}
    ${cmd}=  Catenate  sudo ${xscomutil_dir}/getscom -l
    ${output}=  Execute Command  ${cmd} 
    Should Not Be Empty  ${output}
    [Return]  ${output}

Gard Operations On Host OS

    [Documentation]  Perform gard related operations on HOST OS
    ...              with the given input command and the returns the output
    [Arguments]  ${skiboot_util_dir}  ${input_cmd}
    #input_cmd   list/clear all/show <gard_record_id>

    ${gardutil_dir}=  Catenate  ${skiboot_util_dir}/gard
    Execute Command  Directory Should Exist  ${gardutil_dir}
    ${cmd}=  Catenate  ${gardutil_dir}/gard ${input_cmd}
    ${output}=  Execute Command  ${cmd}
    Should Not Be Empty  ${output}
    [Return]  ${output}

Inject Checkstop On Host OS

    [Documentation]  Using putscom inject checkstop on HOST OS
    [Arguments]  ${skiboot_util_dir}  ${chip_id}  ${fru}  ${address}
    #chip_id     processor ID
    #fru         FRU value
    #address     bit address

    ${pustscom_dir}=  Catenate  ${skiboot_util_dir}xscom-utils/putscom
    ${cmd}=  Catenate  sudo ${pustscom_dir} -c 0x${chip_id} 0x${fru} 0x${adress}
    Start Command  ${cmd}
