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

${MAXIMUM_FILE_SIZE_MESSAGE}        File size exceeds maximum allowed size[10MB]
${MAXIMUM_DIR_SIZE_MESSAGE}
...   File size does not fit in the savearea directory maximum allowed size[10MB]
${FILE_UPLOAD_MESSAGE}              File Created
${FILE_DELETED_MESSAGE}             File Deleted
${FILE_UPDATED_MESSAGE}             File Updated
${FORBIDDEN_MESSAGE}                Forbidden
${ERROR_MESSAGE}                    Error while creating the file
${RESOURCE_NOT_FOUND_MESSAGE}       Resource Not Found
${MINIMUM_FILE_SIZE_MESSAGE}        File size is less than minimum allowed size[100B]
${MAXIMUM_FILE_NAME_MESSAGE}        Filename must be maximum 20 characters
${UNSUPPORTED_FILE_NAME_MESSAGE}    Unsupported character in filename

${content-1}                        Sample Content to test partition file upload
...  Sample Content to test partition file upload
...  Sample Content to test partition file upload
${content-2}                        Sample Content to test partition file upload after reboot
...  Sample Content to test partition file upload after reboot
...  Sample Content to test partition file upload after reboot

*** Test Cases ***

Redfish Upload Lower Limit Partition File To BMC
    [Documentation]  Upload lower limit of allowed partition file to BMC using Redfish.
    [Tags]  Redfish_Upload_Lower_Limit_Partition_File_To_BMC
    [Template]  Redfish Upload Partition File

    # file_name
    100-file


Redfish Upload Partition File To BMC
    [Documentation]  Upload partition file to BMC using Redfish.
    [Tags]  Redfish_Upload_Partition_File_To_BMC
    [Template]  Redfish Upload Partition File

    # file_name
    500KB-file
    501KB-file
    550KB-file
    10000KB-file


Test Upload Lower Limit Partition File To BMC And Expect Failure
    [Documentation]  Fail to upload partition file to BMC with file size
    ...  below the lower limit of allowed partition file size using Redfish.
    [Tags]  Test_Upload_Lower_Limit_Partition_File_To_BMC_And_Expect_Failure
    [Template]  Redfish Fail To Upload Partition File

    # file_name    status_code            partition_status    response_message
    99-file        ${HTTP_BAD_REQUEST}    0                   ${MINIMUM_FILE_SIZE_MESSAGE}


Redfish Fail To Upload Partition File To BMC
    [Documentation]  Fail to upload partition file to BMC using Redfish.
    [Tags]  Redfish_Fail_To_Upload_Partition_File_To_BMC
    [Template]  Redfish Fail To Upload Partition File

    # file_name     status_code            partition_status    response_message
    10001KB-file    ${HTTP_BAD_REQUEST}    0                   ${MAXIMUM_FILE_SIZE_MESSAGE}


Redfish Upload Multiple Partition File To BMC
    [Documentation]  Upload multiple partition file to BMC using Redfish.
    [Tags]  Redfish_Upload_Multiple_Partition_File_To_BMC
    [Template]  Redfish Upload Partition File

    # file_name
    250KB-file,500KB-file


Redfish Fail To Upload Multiple Partition File To BMC
    [Documentation]  Fail to upload multiple partition file to BMC using Redfish.
    [Tags]  Redfish_Fail_To_Upload_Multiple_Partition_File_To_BMC
    [Template]  Redfish Fail To Upload Partition File

    # file_name     status_code            partition_status    response_message
    5000KB-file     ${HTTP_OK}             1                   ${FILE_UPLOAD_MESSAGE}
    6000KB-file     ${HTTP_BAD_REQUEST}    0                   ${MAXIMUM_DIR_SIZE_MESSAGE}
    10000KB-file    ${HTTP_OK}             1                   ${FILE_UPLOAD_MESSAGE}
    100-file        ${HTTP_BAD_REQUEST}    0                   ${MAXIMUM_DIR_SIZE_MESSAGE}


Redfish Upload Same Partition File To BMC In Loop
    [Documentation]  Upload same partition file to BMC using Redfish in loop.
    [Tags]  Redfish_Upload_Same_Partition_File_To_BMC_In_Loop
    [Template]  Redfish Upload Partition File In Loop

    # file_name
    500KB-file


Redfish Upload And Delete Same Partition File To BMC In Loop
    [Documentation]  Upload same partition file to BMC using Redfish in loop.
    [Tags]  Redfish_Upload_And_Delete_Same_Partition_File_To_BMC_In_Loop
    [Template]  Redfish Upload And Delete Partition File In Loop

    # file_name
    500KB-file


Redfish Partition File Upload Post BMC Reboot
    [Documentation]  Upload partition file to BMC using Redfish, after the BMC reboot.
    [Tags]  Redfish_Partition_File_Upload_Post_BMC_Reboot
    [Template]  Verify Partition File Upload Post BMC Reboot

    # file_name
    500KB-file


Redfish Partition File Persistency On BMC Reboot
    [Documentation]  Upload partition file to BMC using Redfish and is same after reboot.
    [Tags]  Redfish_Partition_File_Persistency_On_BMC_Reboot
    [Template]  Redfish Partition File Persistency

    # file_name
    500KB-file


Redfish Multiple Partition File Persistency On BMC Reboot
    [Documentation]  Upload multiple partition file to BMC using Redfish and is same after reboot.
    [Tags]  Redfish_Multiple_Partition_File_Persistency_On_BMC_Reboot
    [Template]  Redfish Partition File Persistency

    # file_name
    250KB-file,500KB-file


Redfish Read Partition File On BMC
    [Documentation]  Upload partition file to BMC using Redfish and verify the content.
    [Tags]  Redfish_Read_Partition_File_On_BMC
    [Template]  Redfish Read Partition File

    # file_name                      reboot_flag
    testfile01-file                  False
    testfile01-file,testfile02-file  False


Redfish Read Partition File On BMC Reboot
    [Documentation]  Upload partition file to BMC using Redfish and verify the content after reboot.
    [Tags]  Check_Redfish_Read_Partition_File_On_BMC_Reboot
    [Template]  Redfish Read Partition File

    # file_name                      reboot_flag
    testfile01-file                  True
    testfile01-file,testfile02-file  True


Redfish Update Partition File On BMC
    [Documentation]  Upload partition file to BMC using Redfish and verify the content.
    [Tags]  Redfish_Update_Partition_File_On_BMC
    [Template]  Redfish Update Partition File With Different Content

    # file_name                 reboot_flag
    testfile01-file             False


Redfish Update Partition File On BMC Reboot
    [Documentation]  Upload partition file to BMC using Redfish and verify the content after the reboot.
    [Tags]  Redfish_Update_Partition_File_On_BMC_Reboot
    [Template]  Redfish Update Partition File With Different Content

    # file_name                 reboot_flag
    testfile01-file             True


Redfish Persistency Update Partition File On BMC
    [Documentation]  Upload partition file to BMC using Redfish and verify the content.
    [Tags]  Redfish_Persistency_Update_Partition_File_On_BMC
    [Template]  Redfish Update Partition File With Same Content

    # file_name                 reboot_flag
    testfile01-file             False


Redfish Persistency Update Partition File On BMC Reboot
    [Documentation]  Upload partition file to BMC using Redfish and verify the content after the reboot.
    [Tags]  Redfish_Persistency_Update_Partition_File_On_BMC_Reboot
    [Template]  Redfish Update Partition File With Same Content

    # file_name                 reboot_flag
    testfile01-file             True


Redfish Delete Non Existence Of Partition File
    [Documentation]  Delete the partition file if do not exists.
    [Tags]  Redfish_Delete_Non_Existence_Of_Partition_File
    [Template]  Redfish Delete Non Existence Partition File

    # file_name
    testfile01-file


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
    500KB-file     operator_user    TestPwd123     Operator


Non Admin User Delete Non Existence Of Partition File
    [Documentation]  Delete the partition file if does not exists.
    [Tags]  Non_Admin_User_Delete_Non_Existence_Of_Partition_File
    [Template]  Non Admin Delete Non Existence Partition File

    # file_name    username         password       role_id
    500KB-file     operator_user    TestPwd123     Operator


Redfish Update Wrong Partition File To BMC
    [Documentation]  Upload partition file to BMC by wrong URI using Redfish.
    [Tags]  Redfish_Update_Wrong_Partition_File_To_BMC
    [Template]  Verify Update Wrong Partition File To BMC

    # file_name
    500KB-file


Test Redfish Upload Partition File Name With Character Limit To BMC
    [Documentation]  Upload partition file to BMC with file name character allowed limit
    ...  and above allowed limit using Redfish.
    [Tags]  Test_Redfish_Upload_Partition_File_Name_With_Character_Limit_To_BMC
    [Template]  Check Redfish Upload Partition File Name With Character Limit To BMC

    # file_name              status_code            message
    50KB-testfilesavfile     ${HTTP_OK}             ${FILE_UPLOAD_MESSAGE}
    50KB-testsaveareafile    ${HTTP_BAD_REQUEST}    ${MAXIMUM_FILE_NAME_MESSAGE}


Test Redfish Fail To Upload Partition File Name With Special Character To BMC
    [Documentation]  Upload partition file to BMC with special character file name and
    ...  Redfish through an error.
    [Tags]  Test_Redfish_Fail_To_Upload_Partition_File_Name_With_Special_Character_To_BMC
    [Template]  Check Redfish Fail To Upload Partition File Name With Special Character To BMC

    # file_name      status_code            message
    1KB-*filename    ${HTTP_BAD_REQUEST}    ${UNSUPPORTED_FILE_NAME_MESSAGE}
    1KB-!filename    ${HTTP_BAD_REQUEST}    ${UNSUPPORTED_FILE_NAME_MESSAGE}
    1KB-@filename    ${HTTP_BAD_REQUEST}    ${UNSUPPORTED_FILE_NAME_MESSAGE}

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


Delete Local Server Partition File
    [Documentation]  Local partition files which is getting uploaded to BMC,
    ...  will get deleted after the uploads. If partition file name consist
    ...  of “-file” then partition file gets deleted.

    @{conf_file_list} =  OperatingSystem.List Files In Directory  ${EXECDIR}
    ${match_conf_file_list}=  Get Matches  ${conf_file_list}  regexp=.*-file  case_insensitive=${True}

    ${num_records}=  Get Length  ${match_conf_file_list}
    Return From Keyword If  ${num_records} == ${0}  ${EMPTY}

    FOR  ${conf_file}  IN  @{match_conf_file_list}
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
      @{words}=  Split String  ${conf_file}  -
      Run  dd if=/dev/zero of=${conf_file} bs=${words}[-0] count=1
      OperatingSystem.File Should Exist  ${conf_file}
    END


Delete BMC Partition File
    [Documentation]  Delete single partition file on BMC via Redfish.
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

      ${description}=  Return Description Of Response  ${resp.text}
      Should Be Equal As Strings  ${description}  ${expected_message}
    END


Delete All BMC Partition File
    [Documentation]  Delete multiple partition file on BMC via Redfish.
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

    ${status}=  Run Keyword And Return Status  Evaluate  isinstance(${resp_text}, dict)
    Return From Keyword If  '${status}' == 'False'  ${resp_text}
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
      ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}  Content-Type=application/octet-stream

      ${kwargs}=  Create Dictionary  data=${image_data}
      Set To Dictionary  ${kwargs}  headers  ${headers}
      ${resp}=  Put Request  openbmc  /ibm/v1/Host/ConfigFiles/${conf_file}  &{kwargs}  timeout=10
      Should Be Equal As Strings  ${resp.status_code}  ${status_code}

      ${description}=  Return Description Of Response  ${resp.text}
      Should Be Equal As Strings  ${description}  ${expected_message}
    END


Verify Partition File On BMC
    [Documentation]  Verify partition file on BMC.
    [Arguments]  ${file_name}  ${Partition_status}

    # Description of argument(s):
    # file_name           Partition file name.
    # Partition_status    Partition file status on BMC.

    FOR  ${conf_file}  IN  @{file_name}
      ${status}  ${stderr}  ${rc}=  BMC Execute Command
      ...  ls -l /var/lib/bmcweb/ibm-management-console/configfiles/${conf_file} | wc -l
      Valid Value  ${status}  [${Partition_status}]
    END


Redfish Upload Partition File
    [Documentation]  Upload the partition file.
    [Arguments]  ${file_name}  ${file_size}=${EMPTY}

    # Description of argument(s):
    # file_name    Partition file name.
    # file_size    By Default is set to EMPTY,
    #              if user pass small_file_size the create file with small
    #              size keyword gets executed.

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
    [Documentation]  Fail to upload the partition file.
    [Arguments]  ${file_name}  ${status_code}  ${partition_status}  ${response_message}=${EMPTY}

    # Description of argument(s):
    # file_name           Partition file name.
    # status_code         HTTPS status code.
    # partition_status    Partition status.
    # response_message    By default is set to EMPTY,
    #                     else user provide the information when user upload the partition with file size
    #                     below lower linit of allowed partition or more than of large allowed partition.

    @{Partition_file_list} =  Split String  ${file_name}  ,

    Create Partition File  ${Partition_file_list}
    Upload Partition File To BMC  ${Partition_file_list}  ${status_code}  ${response_message}
    Verify Partition File On BMC  ${Partition_file_list}  Partition_status=${partition_status}

    Run Keyword If  ${partition_status} == 0
    ...  Run Keywords
    ...  Delete BMC Partition File
    ...  ${Partition_file_list}  ${HTTP_NOT_FOUND}  ${RESOURCE_NOT_FOUND_MESSAGE}  AND
    ...  Delete All BMC Partition File  ${HTTP_OK}  AND
    ...  Delete Local Server Partition File

    Delete Local Partition File  ${Partition_file_list}


Redfish Upload Partition File In Loop
    [Documentation]  Upload the same partition file multiple times in loop to BMC.
    [Arguments]  ${file_name}

    # Description of argument(s):
    # file_name    Partition file name.

    @{Partition_file_list} =  Split String  ${file_name}  ,
    Create Partition File  ${Partition_file_list}

    Upload Partition File To BMC  ${Partition_file_list}  ${HTTP_OK}  ${FILE_UPLOAD_MESSAGE}
    Verify Partition File On BMC  ${Partition_file_list}  Partition_status=1

    FOR  ${count}  IN RANGE  1  11
      Upload Partition File To BMC  ${Partition_file_list}  ${HTTP_OK}  ${FILE_UPDATED_MESSAGE}
      Verify Partition File On BMC  ${Partition_file_list}  Partition_status=1
    END

    Initialize OpenBMC
    Delete BMC Partition File  ${Partition_file_list}  ${HTTP_OK}  ${FILE_DELETED_MESSAGE}
    Delete Local Partition File  ${Partition_file_list}


Redfish Upload And Delete Partition File In Loop
    [Documentation]  Upload the same partition file multiple times in loop to BMC.
    [Arguments]  ${file_name}

    # Description of argument(s):
    # file_name    Partition file name.

    FOR  ${count}  IN RANGE  1  11
      Redfish Upload Partition File  ${file_name}
    END


Verify Partition File Upload Post BMC Reboot
    [Documentation]  Upload the partition file, after BMC reboot.
    [Arguments]  ${file_name}

    # Description of argument(s):
    # file_name    Partition file name.

    ${before_reboot_xauth_token}=  Set Variable  ${XAUTH_TOKEN}
    Redfish BMC Reset Operation
    Set Global Variable  ${XAUTH_TOKEN}  ${before_reboot_xauth_token}

    Is BMC Standby

    Redfish Upload Partition File  ${file_name}


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

    ${before_reboot_xauth_token}=  Set Variable  ${XAUTH_TOKEN}
    Redfish BMC Reset Operation
    Set Global Variable  ${XAUTH_TOKEN}  ${before_reboot_xauth_token}

    Is BMC Standby

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

    ${before_reboot_xauth_token}=  Set Variable  ${XAUTH_TOKEN}

    Run Keyword If  ${True} == ${reboot_flag}
    ...  Run Keywords  Redfish BMC Reset Operation  AND
    ...  Set Global Variable  ${XAUTH_TOKEN}  ${before_reboot_xauth_token}  AND
    ...  Is BMC Standby  AND
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

    ${before_reboot_xauth_token}=  Set Variable  ${XAUTH_TOKEN}

    Run Keyword If  ${True} == ${reboot_flag}
    ...  Run Keywords  Redfish BMC Reset Operation  AND
    ...  Set Global Variable  ${XAUTH_TOKEN}  ${before_reboot_xauth_token}  AND
    ...  Is BMC Standby  AND
    ...  Initialize OpenBMC

    ${content_dict}=  Add Content To Files  ${Partition_file_list}  ${0}
    Upload Partition File To BMC  ${Partition_file_list}  ${HTTP_OK}  ${FILE_UPDATED_MESSAGE}
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

    ${before_reboot_xauth_token}=  Set Variable  ${XAUTH_TOKEN}

    Run Keyword If  ${True} == ${reboot_flag}
    ...  Run Keywords  Redfish BMC Reset Operation  AND
    ...  Set Global Variable  ${XAUTH_TOKEN}  ${before_reboot_xauth_token}  AND
    ...  Is BMC Standby  AND
    ...  Initialize OpenBMC

    ${content_dict}=  Add Content To Files  ${Partition_file_list}  ${1}
    Upload Partition File To BMC  ${Partition_file_list}  ${HTTP_OK}  ${FILE_UPDATED_MESSAGE}
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
      Append To List  ${file_name_list}  1KB-file${count}
    END
    [Return]  ${file_name_list}


Redfish Upload Partition File With Range
    [Documentation]  Upload the partition file with the range of files.
    [Arguments]  ${range}

    # Description of argument(s):
    # range    Range in numbers.

    ${Partition_file_list}=  Create File Names  ${range}
    Delete Local Partition File  ${Partition_file_list}
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
    Delete BMC Partition File  ${Partition_file_list}  ${HTTP_NOT_FOUND}  ${RESOURCE_NOT_FOUND_MESSAGE}


Non Admin User To Upload Partition File
    [Documentation]  Non admin user to upload the partition file.
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
    [Documentation]  Non admin user to upload the partition file.
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


Check Redfish Upload Partition File Name With Character Limit To BMC
    [Documentation]  Upload the partition file to BMC with file name character limit.
    [Arguments]  ${file_name}  ${status_code}  ${message}

    # Description of argument(s):
    # file_name       Partition file name.
    # status_code     HTTPS status code.
    # message         Expected message of from upload partition file URI.

    @{Partition_file_list} =  Split String  ${file_name}  ,
    ${num_records}=  Get Length  ${Partition_file_list}
    Create Partition File  ${Partition_file_list}

    ${file_name_length}=  Get Length  ${Partition_file_list}[0]

    Run Keyword If  ${file_name_length} == 20
    ...  Run Keywords
    ...    Upload Partition File To BMC  ${Partition_file_list}  ${status_code}  ${message}  AND
    ...    Verify Partition File On BMC  ${Partition_file_list}  Partition_status=1  AND
    ...    Delete BMC Partition File  ${Partition_file_list}  ${HTTP_OK}  ${FILE_DELETED_MESSAGE}
    ...  ELSE
    ...    Upload Partition File To BMC  ${Partition_file_list}  ${status_code}  ${message}

    Delete Local Partition File  ${Partition_file_list}


Check Redfish Fail To Upload Partition File Name With Special Character To BMC
    [Documentation]  Upload the partition file to BMC with special character file name.
    [Arguments]  ${file_name}  ${status_code}  ${message}

    # Description of argument(s):
    # file_name       Partition file name.
    # status_code     HTTPS status code.
    # message         Expected message from upload partition file URI.

    @{Partition_file_list} =  Split String  ${file_name}  ,
    ${num_records}=  Get Length  ${Partition_file_list}

    Create Partition File  ${Partition_file_list}

    Upload Partition File To BMC  ${Partition_file_list}  ${status_code}  ${message}

    ${status}=  Run Keyword And Return Status
    ...  Verify Partition File On BMC  ${Partition_file_list}  Partition_status=1
    Should Be Equal As Strings  ${status}  False

    Delete Local Partition File  ${Partition_file_list}
