*** Settings ***

Documentation     Test Save Area feature of Management Console on BMC.

Resource          ../../lib/rest_client.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_utils.robot
Resource          ../../lib/utils.robot
Resource          ../../lib/bmc_redfish_resource.robot

Suite Setup       Suite Setup Execution
Test Teardown     Test Teardown Execution
Suite Teardown    Suite Teardown Execution

*** Variables ***

${MAXIMUM_SIZE_MESSAGE}     File size exceeds maximum allowed size[500KB]
${FILE_UPLOAD_MESSAGE}      File Created
${FILE_DELETED_MESSAGE}     File Deleted
${FILE_UPDATED}             File Updated
${FORBIDDEN_MESSAGE}        Forbidden
${ERROR_MESSAGE}            Error while creating the file
${RESOURCE_NOT_FOUND}       Resource Not Found

*** Test Cases ***

Redfish Upload Partition File To BMC
    [Documentation]  Upload partition file to BMC using redfish.
    [Tags]  Redfish_Upload_Partition_File_To_BMC
    [Template]  Redfish Upload Partition File

    # file_name
    500KB_file


Redfish Fail To Upload Partition File To BMC
    [Documentation]  Fail to upload partition file to BMC using redfish.
    [Tags]  Redfish_Fail_To_Upload_Partition_File_To_BMC
    [Template]  Redfish Fail To Upload Partition File

    # file_name
    501KB_file


Redfish Upload Multiple Partition File To BMC
    [Documentation]  Upload multiple partition file to BMC using redfish.
    [Tags]  Redfish_Upload_Multiple_Partition_File_To_BMC
    [Template]  Redfish Upload Partition File

    # file_name
    250KB_file,500KB_file


Redfish Fail To Upload Multiple Partition File To BMC
    [Documentation]  Fail to upload multiple partition file to BMC using redfish.
    [Tags]  Redfish_Fail_To_Upload_Multiple_Partition_File_To_BMC
    [Template]  Redfish Fail To Upload Partition File

    # file_name
    650KB_file,501KB_file


Redfish Partition File Persistency On BMC Reboot
    [Documentation]  Upload partition file to BMC using redfish and is same after reboot.
    [Tags]  Redfish_Partition_File_Persistency_On_BMC_Reboot
    [Template]  Redfish Partition File Persistency

    # file_name
    500KB_file


Redfish Multiple Partition File Persistency On BMC Reboot
    [Documentation]  Upload partition file to BMC using redfish and is same after reboot.
    [Tags]  Redfish_Multiple_Partition_File_Persistency_On_BMC_Reboot
    [Template]  Redfish Partition File Persistency

    # file_name
    250KB_file,500KB_file


Redfish Read Partition File On BMC
    [Documentation]  Upload partition file to BMC using redfish and verify the content.
    [Tags]  Redfish_Read_Partition_File_On_BMC
    [Template]  Redfish Read Partition File

    # file_name            reboot_flag
    testfile               False
    testfile01,testfile02  False


Redfish Read Partition File On BMC Reboot
    [Documentation]  Upload partition file to BMC using redfish and verify the content after reboot.
    [Tags]  Check_Redfish_Read_Partition_File_On_BMC_Reboot
    [Template]  Redfish Read Partition File

    # file_name            reboot_flag
    testfile               True
    testfile01,testfile02  True


Redfish Update Partition File On BMC
    [Documentation]  Upload partition file to BMC using redfish and verify the content.
    [Tags]  Redfish_Update_Partition_File_On_BMC
    [Template]  Redfish Update Partition File With Different Content

    # file_name            reboot_flag
    testfile01             False


Redfish Update Partition File On BMC Reboot
    [Documentation]  Upload partition file to BMC using redfish and verify the content after the reboot.
    [Tags]  Redfish_Update_Partition_File_On_BMC_Reboot
    [Template]  Redfish Update Partition File With Different Content

    # file_name            reboot_flag
    testfile01             True


Redfish Persistency Update Partition File On BMC
    [Documentation]  Upload partition file to BMC using redfish and verify the content.
    [Tags]  Redfish_Persistency_Update_Partition_File_On_BMC
    [Template]  Redfish Update Partition File With Same Content

    # file_name            reboot_flag
    testfile01             False


Redfish Persistency Update Partition File On BMC Reboot
    [Documentation]  Upload partition file to BMC using redfish and verify the content after the reboot.
    [Tags]  Redfish_Persistency_Update_Partition_File_On_BMC_Reboot
    [Template]  Redfish Update Partition File With Same Content

    # file_name            reboot_flag
    testfile01             True


Redfish Delete Non Existence Of Partition File
    [Documentation]  Delete the partition file if do not exists.
    [Tags]  Redfish_Delete_Non_Existence_Of_Partition_File
    [Template]  Redfish Delete Non Existence Partition File

    # file_name
    testfile01


Verify One Thousand Partitions File Upload
    [Documentation]  Upload 1000 partition file to BMC.
    [Tags]  Verify_One_Thousand_Partitions_File_Upload
    [Template]  Redfish Upload Partition File With Range

    # range
    1000


Non Admin Users Fail To Upload Partition File
    [Documentation]  Non admin user will fail to upload the partition file.
    [Tags]  Non_Admin_Users_Fail_To_Upload_Partition_File
    [Template]  Non Admin User To Upload Partition File

    # file_name    username         password       role_id
    500KB_file     operator_user    TestPwd123     Operator


Non Admin User Delete Non Existence Of Partition File
    [Documentation]  Delete the partion file if does not exists.
    [Tags]  Non_Admin_User_Delete_Non_Existence_Of_Partition_File
    [Template]  Non Admin Delete Non Existence Partition File

    # file_name    username         password       role_id
    500KB_file     operator_user    TestPwd123     Operator


Redfish Update Wrong Partition File To BMC
    [Documentation]  Upload partition file to BMC by wrong URI using redfish.
    [Tags]  Redfish_Update_Wrong_Partition_File_To_BMC
    [Template]  Verify Update Wrong Partition File To BMC

    # file_name
    500KB_file

*** Keywords ***

Suite Setup Execution
    [Documentation]  Suite setup execution.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Test teardown execution.

    Delete All BMC Partition File  ${HTTP_OK}
    FFDC On Test Case Fail


Suite Teardown Execution
    [Documentation]  Suite teardown execution.

    Delete All Sessions


Delete Local Partition File
    [Documentation]  Delete local partition file.
    [Arguments]  ${file_name}

    # Description of argument(s):
    # file_name    Partition file name.

    FOR  ${conf_file}  IN  @{file_name}
      ${file_exist}=  Run Keyword And Return Status  OperatingSystem.File Should Exist  ${conf_file}
      Run Keyword If  'True' == '${file_exist}'  Remove File  ${conf_file}
    END


Create Partition File
    [Documentation]  Create Partition file.
    [Arguments]  ${file_name}

    # Description of argument(s):
    # file_name    Partition file name.

    Delete Local Partition File  ${file_name}

    FOR  ${conf_file}  IN  @{file_name}
      @{words}=  Split String  ${conf_file}  _
      Run  dd if=/dev/zero of=${conf_file} bs=1 count=0 seek=${words}[-0]
      OperatingSystem.File Should Exist  ${conf_file}
    END


Delete BMC Partition File
    [Documentation]  Delete single partition file on BMC via redfish.
    [Arguments]  ${file_name}  ${status_code}  ${expected_message}

    # Description of argument(s):
    # file_name           Partition file name.
    # status_code         HTTPS status code.
    # expected_message    Expected message of URI.

    FOR  ${conf_file}  IN  @{file_name}
      ${data}=  Create Dictionary
      ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}
      Set To Dictionary  ${data}  headers  ${headers}

      ${resp}=  Delete Request  openbmc  /ibm/v1/Host/ConfigFiles/${conf_file}  &{data}
      Should Be Equal As Strings  ${resp.status_code}  ${status_code}

      Run Keyword If  ${resp.status_code} == ${HTTP_FORBIDDEN}
      ...    Should Be Equal As Strings  ${resp.text}  ${expected_message}
      ${description}=  Run Keyword If  ${resp.status_code} == ${HTTP_OK}
      ...  Return Description Of Response  ${resp.text}
      Run Keyword If  '${description}' != 'None'
      ...  Should Be Equal As Strings  ${description}  ${expected_message}
    END


Delete All BMC Partition File
    [Documentation]  Delete multiple partition file on BMC via redfish.
    [Arguments]  ${status_code}

    # Description of argument(s):
    # status_code       HTTPS status code.

    Initialize OpenBMC
    ${data}=  Create Dictionary
    ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}
    Set To Dictionary  ${data}  headers  ${headers}

    ${resp}=  Post Request  openbmc  /ibm/v1/Host/ConfigFiles/Actions/IBMConfigFiles.DeleteAll  &{data}
    Should Be Equal As Strings  ${resp.status_code}  ${status_code}


Return Description Of Response
    [Documentation]  Return description of REST response.
    [Arguments]  ${resp_text}

    # Description of argument(s):
    # resp_text    REST response body.

    # resp_text after successful partition file upload looks like:
    # {
    #    "Description": "File Created"
    # }

    ${message}=  Evaluate  json.loads('''${resp_text}''')  json

    [Return]  ${message["Description"]}


Upload Partition File To BMC
    [Documentation]  Upload partition file to BMC.
    [Arguments]  ${file_name}  ${status_code}  ${expected_message}  ${flag}=${True}

    # Description of argument(s):
    # file_name           Partition file name.
    # status_code         HTTPS status code.
    # expected_message    Expected message of URI.
    # flag                If True run part of program, else skip.

    Run Keyword If  '${flag}' == '${True}'  Initialize OpenBMC
    FOR  ${conf_file}  IN  @{file_name}
      # Get the content of the file and upload to BMC.
      ${image_data}=  OperatingSystem.Get Binary File  ${conf_file}
      ${data}=  Create Dictionary  data  ${image_data}
      ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}
      Set To Dictionary  ${data}  headers  ${headers}

      ${resp}=  Put Request  openbmc  /ibm/v1/Host/ConfigFiles/${conf_file}  &{data}
      Should Be Equal As Strings  ${resp.status_code}  ${status_code}

      Run Keyword If  ${resp.status_code} == ${HTTP_FORBIDDEN}
      ...    Should Be Equal As Strings  ${resp.text}  ${expected_message}
      ${description}=  Run Keyword If  ${resp.status_code} == ${HTTP_OK}
      ...  Return Description Of Response  ${resp.text}
      Run Keyword If  '${description}' != 'None'
      ...  Should Be Equal As Strings  ${description}  ${expected_message}
    END


Verify Partition File On BMC
    [Documentation]  Verify partition file on BMC.
    [Arguments]  ${file_name}  ${Partition_status}

    # Description of argument(s):
    # file_name           Partition file name.
    # Partition_status    Partition file status on BMC.

    FOR  ${conf_file}  IN  @{file_name}
      ${status}  ${stderr}  ${rc}=  BMC Execute Command
      ...  ls -l /var/lib/obmc/bmc-console-mgmt/save-area/${conf_file} | wc -l
      Valid Value  ${status}  [${Partition_status}]
    END


Redfish Upload Partition File
    [Documentation]  Upload the partition file.
    [Arguments]  ${file_name}

    # Description of argument(s):
    # file_name    Partition file name.

    @{Partition_file_list} =  Split String  ${file_name}  ,
    ${num_records}=  Get Length  ${Partition_file_list}
    Create Partition File  ${Partition_file_list}
    Upload Partition File To BMC  ${Partition_file_list}  ${HTTP_OK}  ${FILE_UPLOAD_MESSAGE}
    Verify Partition File On BMC  ${Partition_file_list}  Partition_status=1
    Run Keyword If  ${num_records} == ${1}
    ...    Delete BMC Partition File  ${Partition_file_list}  ${HTTP_OK}  ${FILE_DELETED_MESSAGE}
    ...  ELSE
    ...    Delete All BMC Partition File  ${HTTP_OK}
    Delete Local Partition File  ${Partition_file_list}


Redfish Fail To Upload Partition File
    [Documentation]  Fail to uplaod the partition file.
    [Arguments]  ${file_name}

    # Description of argument(s):
    # file_name    Partition file name.

    @{Partition_file_list} =  Split String  ${file_name}  ,
    Create Partition File  ${Partition_file_list}
    Upload Partition File To BMC  ${Partition_file_list}  ${HTTP_BAD_REQUEST}  ${MAXIMUM_SIZE_MESSAGE}
    Verify Partition File On BMC  ${Partition_file_list}  Partition_status=0
    Delete BMC Partition File  ${Partition_file_list}  ${HTTP_NOT_FOUND}  ${RESOURCE_NOT_FOUND}
    Delete Local Partition File  ${Partition_file_list}


Redfish Partition File Persistency
    [Documentation]  Upload the partition file and check for persistency after reboot.
    [Arguments]  ${file_name}

    # Description of argument(s):
    # file_name    Partition file name.

    @{Partition_file_list} =  Split String  ${file_name}  ,
    ${num_records}=  Get Length  ${Partition_file_list}
    Create Partition File  ${Partition_file_list}
    Upload Partition File To BMC  ${Partition_file_list}  ${HTTP_OK}  ${FILE_UPLOAD_MESSAGE}
    Verify Partition File On BMC  ${Partition_file_list}  Partition_status=1
    Redfish OBMC Reboot (off)
    Verify Partition File On BMC  ${Partition_file_list}  Partition_status=1
    Initialize OpenBMC
    Run Keyword If  ${num_records} == ${1}
    ...    Delete BMC Partition File  ${Partition_file_list}  ${HTTP_OK}  ${FILE_DELETED_MESSAGE}
    ...  ELSE
    ...    Delete All BMC Partition File  ${HTTP_OK}
    Delete Local Partition File  ${Partition_file_list}


Verify Redfish Partition File Content
    [Documentation]  Verify partition file content.
    [Arguments]  ${file_name}  ${content_dict}  ${status_code}

    # Description of argument(s):
    # file_name       Partition file name.
    # content_dict    Dict contain the content.
    # status_code     HTTPS status code.

    FOR  ${conf_file}  IN  @{file_name}
      ${resp}=  Get Request  openbmc  /ibm/v1/Host/ConfigFiles/${conf_file}
      Should Be Equal As Strings  ${resp.status_code}  ${status_code}

      ${Partition_file_data}=  Remove String  ${resp.text}  \\n
      ${Partition_file_data}=  Evaluate  json.loads('''${Partition_file_data}''')  json
      Should Be Equal As Strings  ${Partition_file_data["Data"]}  ${content_dict['${conf_file}']}
    END


Add Content To Files
    [Documentation]  Add defined content in partition file.
    [Arguments]  ${file_name}  ${index}=${0}

    # Description of argument(s):
    # file_name    Partition file name.
    # index        Index

    ${num_records}=  Get Length  ${file_name}
    Set Test Variable  ${content-1}  Sample Content to test partition file upload
    Set Test Variable  ${content-2}  Sample Content to test partition file upload after reboot
    &{content_dict}=  Create Dictionary
    FOR  ${conf_file}  IN  @{file_name}
       ${index}=  Get Index From List  ${file_name}  ${conf_file}
       ${index}=  Evaluate  ${index} + 1

       Run  echo "${content-${index}}" > ${conf_file}
       OperatingSystem.File Should Exist  ${conf_file}

       Set To Dictionary  ${content_dict}  ${conf_file}  ${content-${index}}
    END

    [Return]  &{content_dict}


Redfish Read Partition File
    [Documentation]  Read partition file content.
    [Arguments]  ${file_name}  ${reboot_flag}=False

    # Description of argument(s):
    # file_name      Partition file name.
    # reboot_flag    Reboot flag.

    @{Partition_file_list} =  Split String  ${file_name}  ,
    ${content_dict}=  Add Content To Files  ${Partition_file_list}

    ${num_records}=  Get Length  ${Partition_file_list}

    Upload Partition File To BMC  ${Partition_file_list}  ${HTTP_OK}  ${FILE_UPLOAD_MESSAGE}
    Verify Partition File On BMC  ${Partition_file_list}  Partition_status=1
    Verify Redfish Partition File Content  ${Partition_file_list}  ${content_dict}  ${HTTP_OK}

    Run Keyword If  ${True} == ${reboot_flag}
    ...  Run Keywords  Redfish OBMC Reboot (off)  AND
    ...  Initialize OpenBMC  AND
    ...  Verify Redfish Partition File Content  ${Partition_file_list}  ${content_dict}  ${HTTP_OK}
    Run Keyword If  ${num_records} == ${1}
    ...    Delete BMC Partition File  ${Partition_file_list}  ${HTTP_OK}  ${FILE_DELETED_MESSAGE}
    ...  ELSE
    ...    Delete All BMC Partition File  ${HTTP_OK}
    Delete Local Partition File  ${Partition_file_list}


Redfish Update Partition File With Same Content
    [Documentation]  Update partition file with same content.
    [Arguments]  ${file_name}  ${reboot_flag}=False

    # Description of argument(s):
    # file_name      Partition file name.
    # reboot_flag    Reboot flag.

    @{Partition_file_list} =  Split String  ${file_name}  ,
    ${content_dict}=  Add Content To Files  ${Partition_file_list}  ${0}

    Upload Partition File To BMC  ${Partition_file_list}  ${HTTP_OK}  ${FILE_UPLOAD_MESSAGE}
    Verify Partition File On BMC  ${Partition_file_list}  Partition_status=1
    Verify Redfish Partition File Content  ${Partition_file_list}  ${content_dict}  ${HTTP_OK}

    Run Keyword If  ${True} == ${reboot_flag}
    ...  Run Keywords  Redfish OBMC Reboot (off)  AND
    ...  Initialize OpenBMC

    ${content_dict}=  Add Content To Files  ${Partition_file_list}  ${0}
    Upload Partition File To BMC  ${Partition_file_list}  ${HTTP_OK}  ${FILE_UPDATED}
    Verify Partition File On BMC  ${Partition_file_list}  Partition_status=1
    Verify Redfish Partition File Content  ${Partition_file_list}  ${content_dict}  ${HTTP_OK}

    Delete BMC Partition File  ${Partition_file_list}  ${HTTP_OK}  ${FILE_DELETED_MESSAGE}
    Delete Local Partition File  ${Partition_file_list}


Redfish Update Partition File With Different Content
    [Documentation]  Update partition file with different content.
    [Arguments]  ${file_name}  ${reboot_flag}=False

    # Description of argument(s):
    # file_name      Partition file name.
    # reboot_flag    Reboot flag.

    @{Partition_file_list} =  Split String  ${file_name}  ,
    ${content_dict}=  Add Content To Files  ${Partition_file_list}  ${0}

    Upload Partition File To BMC  ${Partition_file_list}  ${HTTP_OK}  ${FILE_UPLOAD_MESSAGE}
    Verify Partition File On BMC  ${Partition_file_list}  Partition_status=1
    Verify Redfish Partition File Content  ${Partition_file_list}  ${content_dict}  ${HTTP_OK}

    Run Keyword If  ${True} == ${reboot_flag}
    ...  Run Keywords  Redfish OBMC Reboot (off)  AND
    ...  Initialize OpenBMC

    ${content_dict}=  Add Content To Files  ${Partition_file_list}  ${1}
    Upload Partition File To BMC  ${Partition_file_list}  ${HTTP_OK}  ${FILE_UPDATED}
    Verify Partition File On BMC  ${Partition_file_list}  Partition_status=1
    Verify Redfish Partition File Content  ${Partition_file_list}  ${content_dict}  ${HTTP_OK}

    Delete BMC Partition File  ${Partition_file_list}  ${HTTP_OK}  ${FILE_DELETED_MESSAGE}
    Delete Local Partition File  ${Partition_file_list}


Create File Names
    [Documentation]  Create partition file names.
    [Arguments]  ${range}

    # Description of argument(s):
    # range    Range in numbers.

    @{file_name_list}=  Create List
    Set Test Variable  ${file_name}  rangefile
    FOR  ${count}  IN RANGE  ${range}
      Append To List  ${file_name_list}  200KB_file${count}
    END
    [Return]  ${file_name_list}


Redfish Upload Partition File With Range
    [Documentation]  Upload the partition file with the range of files.
    [Arguments]  ${range}

    # Description of argument(s):
    # range    Range in numbers.

    ${Partition_file_list}=  Create File Names  ${range}
    Create Partition File  ${Partition_file_list}
    Upload Partition File To BMC  ${Partition_file_list}  ${HTTP_OK}  ${FILE_UPLOAD_MESSAGE}
    Verify Partition File On BMC  ${Partition_file_list}  Partition_status=1
    Delete All BMC Partition File  ${HTTP_OK}
    Delete Local Partition File  ${Partition_file_list}


Redfish Delete Non Existence Partition File
    [Documentation]  Delete the partition file if do not exists.
    [Arguments]  ${file_name}

    # Description of argument(s):
    # file_name    Partition file name.

    @{Partition_file_list} =  Split String  ${file_name}  ,
    Delete BMC Partition File  ${Partition_file_list}  ${HTTP_NOT_FOUND}  ${RESOURCE_NOT_FOUND}


Non Admin User To Upload Partition File
    [Documentation]  Non admin user to uplaod the partition file.
    [Arguments]  ${file_name}  ${username}  ${password}  ${role}  ${enabled}=${True}

    # Description of argument(s):
    # file_name    Partition file name.
    # username     Username.
    # password     Password.
    # role         Role of user.
    # enabled      Value can be True or False.

    Redfish Create User  ${username}  ${password}  ${role}  ${enabled}
    Delete All Sessions
    Initialize OpenBMC  rest_username=${username}  rest_password=${password}
    @{Partition_file_list} =  Split String  ${file_name}  ,
    Create Partition File  ${Partition_file_list}
    Upload Partition File To BMC  ${Partition_file_list}  ${HTTP_FORBIDDEN}  ${FORBIDDEN_MESSAGE}  ${False}
    Delete Local Partition File  ${Partition_file_list}
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${username}


Non Admin Delete Non Existence Partition File
    [Documentation]  Non admin user to uplaod the partition file.
    [Arguments]  ${file_name}  ${username}  ${password}  ${role}  ${enabled}=${True}

    # Description of argument(s):
    # file_name    Partition file name.
    # username     Username.
    # password     Password.
    # role         Role of user.
    # enabled      Value can be True or False.

    Redfish Create User  ${username}  ${password}  ${role}  ${enabled}
    Delete All Sessions
    Initialize OpenBMC  rest_username=${username}  rest_password=${password}
    @{Partition_file_list} =  Split String  ${file_name}  ,
    Delete BMC Partition File  ${Partition_file_list}  ${HTTP_FORBIDDEN}  ${FORBIDDEN_MESSAGE}


Verify Update Wrong Partition File To BMC
    [Documentation]  Upload the wrong partition file to BMC.
    [Arguments]  ${file_name}

    # Description of argument(s):
    # file_name    Partition file name.

    Redfish.Login
    ${resp}=  Run Keyword And Return Status
    ...  Redfish.Put  /ibm/v1/Host/ConfigFiles/../../../../../etc/resolv.conf  body={"data": "test string"}
    Should Be Equal As Strings  ${resp}  False
