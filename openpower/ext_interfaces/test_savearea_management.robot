*** Settings ***

Documentation    Test Save Area feature of Management Console on BMC.

Resource          ../../lib/rest_client.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_utils.robot
Resource          ../../lib/utils.robot

Suite Setup       Suite Setup Execution
Test Teardown     Test Teardown Execution
Suite Teardown    Suite Teardown Execution


*** Variables ***

${MAX_SIZE_MSG}           File size exceeds maximum allowed size[500KB]
${UPLOADED_MSG}           File Created
${FORBIDDEN_MSG}          Forbidden
${FILE_CREATE_ERROR_MSG}  Error while creating the file

@{ADMIN}                  admin_user              TestPwd123
@{OPERATOR}               operator_user           TestPwd123
&{USERS}                  Administrator=${ADMIN}  Operator=${OPERATOR}

*** Test Cases ***

Verify Small Partition File Upload And Delete
    [Documentation]  Verify small partition file upload and delete.
    [Tags]  Verify_Small_Partition_File_Upload_And_Delete
    [Template]  Upload File To Create Partition Then Delete Partition

    #                     partition                                         delete
    # file_name  size_kb  name       expect_resp_code     expected_msg      partition    username
    501KB_file   501      501KB      ${HTTP_BAD_REQUEST}  ${MAX_SIZE_MSG}   ${True}      ${OPENBMC_USERNAME}
    15KB_file    15       15KB       ${HTTP_OK}           ${UPLOADED_MSG}   ${True}      ${OPENBMC_USERNAME}
    500KB_file   500      500KB      ${HTTP_OK}           ${UPLOADED_MSG}   ${True}      ${OPENBMC_USERNAME}


Verify Multiple Files Upload
    [Documentation]  Verify multiple files upload.
    [Tags]  Verify_Multiple_Files_Upload
    [Template]  Upload File To Create Partition Then Delete Partition

    #                     partition                                         delete
    # file_name  size_kb  name       expect_resp_code     expected_msg      partition    username
    0KB_file     0        0KB        ${HTTP_OK}           ${UPLOADED_MSG}   ${False}     ${OPENBMC_USERNAME}
    10KB_file    10       10KB       ${HTTP_OK}           ${UPLOADED_MSG}   ${False}     ${OPENBMC_USERNAME}
    50KB_file    50       50KB       ${HTTP_OK}           ${UPLOADED_MSG}   ${False}     ${OPENBMC_USERNAME}
    550KB_file   550      550KB      ${HTTP_BAD_REQUEST}  ${MAX_SIZE_MSG}   ${False}     ${OPENBMC_USERNAME}
    19KB_file    19       19KB       ${HTTP_OK}           ${UPLOADED_MSG}   ${False}     ${OPENBMC_USERNAME}
    499KB_file   199      499KB      ${HTTP_OK}           ${UPLOADED_MSG}   ${False}     ${OPENBMC_USERNAME}


Verify Read Partition
    [Documentation]  Verify read partition.
    [Tags]  Verify_Read_Partition

    Set Test Variable  ${file_name}  testfile
    Set Test Variable  ${partition_name}  part_read
    Set Test Variable  ${content}  Sample Content to test partition file upload

    Run  echo "${content}" > ${file_name}
    OperatingSystem.File Should Exist  ${file_name}

    Upload File To Create Partition Then Delete Partition  ${file_name}  1  ${partition_name}
    ...  delete_partition=${False}

    Read Partition And Verify Content  ${partition_name}  ${content}


Verify Non-Admin User Is Forbidden To Upload Partition File
    [Documentation]  Verify non-admin user is forbidden to upload partition file.
    [Tags]   Verify_Non-Admin_User_Is_Forbidden_To_Upload_Partition_File
    [Template]  Upload File To Create Partition Then Delete Partition

    #                     partition                                         delete
    # file_name  size_kb  name       expect_resp_code     expected_msg      partition    username
    12KB_file    12       12KB       ${HTTP_FORBIDDEN}    ${FORBIDDEN_MSG}  ${False}     operator_user


Verify Partition Update On BMC
    [Documentation]  Verify partition update on BMC.
    [Tags]  Verify_Partition_Update_On_BMC

    Set Test Variable  ${file_name}  testfile
    Set Test Variable  ${partition_name}  part_read
    Set Test Variable  ${content1}  Sample Content to test partition file upload
    Set Test Variable  ${content2}  Sample Content to test partition file update

    Upload Partition File With Some Known Contents  ${file_name}  ${partition_name}  ${content1}
    Read Partition And Verify Content  ${partition_name}  ${content1}

    # Upload the same partition with modified contents to verify update partition feature.
    Upload Partition File With Some Known Contents  ${file_name}  ${partition_name}  ${content2}
    Read Partition And Verify Content  ${partition_name}  ${content2}


Verify Delete Partition When Partition Does Not Exist
    [Documentation]  Verify delete partition when partition does not exist.
    [Tags]  Verify_Delete_Partition_When_Partition_Does_Not_Exist
    [Template]  Delete Partition And Verify On BMC

    # partition_name    expect_resp_code      username
    Does_not_exist      ${HTTP_NOT_FOUND}     ${OPENBMC_USERNAME}
    Does_not_exist      ${HTTP_FORBIDDEN}     operator_user


Verify Partition Files Persistency And Re-upload After BMC Reboot
    [Documentation]  Verify partition files persistency and re-upload after BMC reboot.
    [Tags]  Verify_Partition_Files_Persistency_And_Re-upload_After_BMC_Reboot

    Set Test Variable  ${file_name}  testfile
    Set Test Variable  ${partition_name}  part_read
    Set Test Variable  ${content}  Sample Content to test partition file upload

    Upload Partition File With Some Known Contents
    ...  ${file_name}_1  ${partition_name}_1  ${content}_${file_name}_1
    Upload Partition File With Some Known Contents
    ...  ${file_name}_2  ${partition_name}_2  ${content}_${file_name}_2

    OBMC Reboot (off)

    # Get REST session to BMC.
    Initialize OpenBMC

    # Checking for the content of uploaded partitions after BMC reboot.
    Read Partition And Verify Content  ${partition_name}_1  ${content}_${file_name}_1
    Read Partition And Verify Content  ${partition_name}_2  ${content}_${file_name}_2

    # Upload same partition with different content to test partition update after BMC reboot.
    Upload Partition File With Some Known Contents
    ...  ${file_name}_1  ${partition_name}_1  ${content}_${file_name}_2

    # Upload different partition.
    Upload Partition File With Some Known Contents  ${file_name}  ${partition_name}  ${content}


Verify One Thousand Partitions File Upload
    [Documentation]  Verify One Thousand Partitions File Upload.
    [Tags]  Verify_One_Thousand_Partitions_File_Upload

    # Note: 1000 Partitions file upload would take 15-20 minutes.
    FOR  ${INDEX}  IN RANGE  1  1000
        ${status}=  Run Keyword And Return Status  Upload File To Create Partition Then Delete Partition
        ...  200KB  200  p${INDEX}  delete_partition=${False}
        Run Keyword If  ${status} == ${True}  Continue For Loop

        # Check if /var is full on BMC.
        ${status}  ${stderr}  ${rc}=  BMC Execute Command  df -k | grep \' /var\' | grep -v /var/
        ${var_size}=  Set Variable  ${status.split('%')[0].split()[1]}

        # Should be a problem if partition file upload request has failed when /var is not full.
        Exit For Loop If  ${var_size} != ${100}

        # Expect HTTP_INTERNAL_SERVER_ERROR and FILE_CREATE_ERROR_MSG when /var is full.
        Upload File To Create Partition Then Delete Partition
        ...  200KB  200  p${INDEX}  ${HTTP_INTERNAL_SERVER_ERROR}  ${FILE_CREATE_ERROR_MSG}  ${False}
    END


*** Keywords ***

Create Partition File
    [Documentation]  Create partition file.
    [Arguments]  ${file_name}=dummyfile  ${size_kb}=15

    # Description of argument(s):
    # file_name           Name of the test file to be created. Examples:  p1.log, part1.txt etc.
    # size_kb             Size of the test file to be created in KB, default is 15KB.
    #                     Example : 15, 200 etc.

    ${file_exist}=  Run Keyword And Return Status  OperatingSystem.File Should Exist  ${file_name}
    Return From Keyword If  ${file_exist}  ${True}

    # Create a partition file if it does not exist locally.
    Run  dd if=/dev/zero of=${file_name} bs=1 count=0 seek=${size_kb}KB
    OperatingSystem.File Should Exist  ${file_name}


Delete All Sessions And Login Using Given User
    [Documentation]    Delete all sessions and login using given user.
    [Arguments]   ${username}=${OPENBMC_USERNAME}

    # Description of argument(s):
    # username            Username to login. Default is OPENBMC_USERNAME.
    #                     Ex: root, operator_user, admin_user, readonly_user etc.

    Delete All Sessions
    ${password}=  Set Variable If  '${username}' == '${OPENBMC_USERNAME}'  ${OPENBMC_PASSWORD}  TestPwd123
    Initialize OpenBMC  rest_username=${username}  rest_password=${password}


Upload File To Create Partition Then Delete Partition
    [Documentation]  Upload file to create partition the delete partition.
    [Arguments]  ${file_name}=dummyfile  ${size_kb}=15  ${partition_name}=p1  ${expect_resp_code}=${HTTP_OK}
    ...  ${expected_msg}=File Created  ${delete_partition}=${True}  ${username}=${OPENBMC_USERNAME}

    # Description of argument(s):
    # file_name           Name of the test file to be created.
    # partition_name      Name of the partition on BMC.
    # expect_resp_code    Expected REST response code, default is ${HTTP_OK}.
    # expected_msg        Expected message from file upload, default is 'File Created'.
    # delete_partition    Partition will be deleted if this is True.
    # username            Login username

    # Create a session with given user to test upload partition file.
    Run Keyword If  '${username}' != '${OPENBMC_USERNAME}'
    ...  Delete All Sessions And Login Using Given User  ${username}

    # Create a partition file.
    Create Partition File  ${file_name}  ${size_kb}

    # Get the content of the file and upload to BMC.
    ${image_data}=  OperatingSystem.Get Binary File  ${file_name}
    ${data}=  Create Dictionary  data  ${image_data}
    ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}

    Set To Dictionary  ${data}  headers  ${headers}
    ${resp}=  Put Request  openbmc  /ibm/v1/Host/ConfigFiles/${partition_name}  &{data}
    Should Be Equal As Strings  ${resp.status_code}  ${expect_resp_code}

    ${description}=  Run Keyword If  ${expect_resp_code} != ${HTTP_FORBIDDEN}
    ...  Return Description Of REST Response  ${resp.text}
    ...  ELSE  Set Variable  ${FORBIDDEN_MSG}

    Should Be Equal As Strings  ${description}  ${expected_msg}

    # Cleanup local space after upload attempt.
    Run Keyword And Ignore Error  Delete Local File Created To Upload  ${file_name}

    ${upload_success}=  Set Variable If   ${expect_resp_code} != ${HTTP_OK}  ${False}  ${True}
    Verify Partition Available On BMC  ${partition_name}  ${upload_success}  ${username}

    # Delete partition and verify on BMC.
    ${expect_resp_code}=  Set Variable If  ${expect_resp_code} != ${HTTP_OK}  ${HTTP_NOT_FOUND}  ${HTTP_OK}
    Run Keyword If  ${delete_partition} == ${True}  Delete Partition And Verify On BMC
    ...  ${partition_name}  ${expect_resp_code}  ${username}


Return Description Of REST Response
    [Documentation]  Return description of REST response.
    [Arguments]  ${resp_text}

    # Description of argument(s):
    # resp_text    REST response body.

    # resp_text after successful partition file upload looks like:
    #           {
    #             "Description": "File Created"
    #           }

    ${message}=  Evaluate  json.loads('''${resp_text}''')  json

    [Return]  ${message["Description"]}


Delete Partition And Verify On BMC
    [Documentation]  Delete partition and verify on BMC.
    [Arguments]  ${partition_name}  ${expect_resp_code}=${HTTP_OK}  ${username}=${OPENBMC_USERNAME}

    # Description of argument(s):
    # partition_name      Name of the partition on BMC.
    # expect_resp_code    Expected REST response code from DELETE request, default is ${HTTP_OK}.
    # username            Username to login, if other than OPENBMC_USERNAME user.

    # Create a session with given user to test delete operation.
    # If user is a non-admin user then DELETE request is forbidden for the user.
    Run Keyword If  '${username}' != '${OPENBMC_USERNAME}'
    ...  Delete All Sessions And Login Using Given User  ${username}

    Delete Partition  ${partition_name}  ${expect_resp_code}
    Verify Partition Available On BMC  ${partition_name}  ${False}  ${username}


Get List Of Partitions
    [Documentation]  Get list of partitions.
    [Arguments]  ${expect_resp_code}=${HTTP_OK}

    # Description of argument(s):
    # expect_resp_code    Expected REST response code, default is ${HTTP_OK}.

    ${resp}=  Get Request  openbmc  /ibm/v1/Host/ConfigFiles
    Should Be Equal As Strings  ${resp.status_code}  ${expect_resp_code}
    Return From Keyword If  ${expect_resp_code} != ${HTTP_OK}

    ${resp_json}=  To JSON  ${resp.content}
    ${partitions_cnt}=  Get Length  ${resp_json['Members']}

    [Return]  ${resp_json['Members']}  ${partitions_cnt}


Verify Partition Available On BMC
    [Documentation]  Verify partition available on BMC.
    [Arguments]  ${partition_name}=${EMPTY}  ${operation_status}=${True}  ${username}=${OPENBMC_USERNAME}

    # Description of argument(s):
    # partition_name     Name of the partition on BMC.
    # operation_success  Status of the previous operation like upload/delete success or failure.
    #                    True if operation was a success else False.
    # username           Username used to upload/delete. Default is ${OPENBMC_USERNAME}.

    # Non admin users will not have an access to do GET list
    Run Keyword If  '${username}' != '${OPENBMC_USERNAME}'
    ...  Delete All Sessions And Login Using Given User

    ${partitions}  ${partitions_cnt}=  Get List Of Partitions
    ${rest_response}=  Run Keyword And Return Status  List Should Contain Value  ${partitions}
    ...  /ibm/v1/Host/ConfigFiles/${partition_name}

    ${status}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ls -l /var/lib/obmc/bmc-console-mgmt/save-area/${partition_name} | wc -l
    ${bmc_response}=  Run Keyword And Return Status  Should Be True  ${status} == ${1}

    Run Keyword If  '${partition_name}' == '${EMPTY}'  Run Keywords
    ...  Should Be Equal  ${rest_response}  ${False}  AND  Should Be Equal  ${bmc_response}  ${False}

    Run Keyword And Return If  '${partition_name}' != '${EMPTY}'  Run Keywords
    ...  Should Be True  ${rest_response} == ${operation_status}  AND
    ...  Should Be True  ${bmc_response} == ${operation_status}


Delete Partition
    [Documentation]  Delete partition.
    [Arguments]  ${partition_name}='${EMPTY}'  ${expect_resp_code}=${HTTP_OK}

    # Description of argument(s):
    # partition_name      Name of the partition on BMC.
    # expect_resp_code    Expected REST response code, default is ${HTTP_OK}.

    ${data}=  Create Dictionary
    ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}
    Set To Dictionary  ${data}  headers  ${headers}

    ${resp}=  Delete Request  openbmc  /ibm/v1/Host/ConfigFiles/${partition_name}  &{data}
    ${expect_resp_code}=  Set Variable If  '${partition_name}' == '${EMPTY}'
    ...  ${HTTP_NOT_FOUND}  ${expect_resp_code}
    Should Be Equal As Strings  ${resp.status_code}  ${expect_resp_code}


Delete And Verify All Partitions on BMC
    [Documentation]  Delete and verify all partitions on BMC.
    [Arguments]  ${expect_resp_code}=${HTTP_OK}

    # Description of argument(s):
    # expect_resp_code    Expected REST response code, default is ${HTTP_OK}.

    ${data}=  Create Dictionary
    ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}
    Set To Dictionary  ${data}  headers  ${headers}

    ${resp}=  Post Request  openbmc  /ibm/v1/Host/ConfigFiles/Actions/FileCollection.DeleteAll  &{data}
    Should Be Equal As Strings  ${resp.status_code}  ${expect_resp_code}

    Return From Keyword If  ${expect_resp_code} != ${HTTP_OK}
    Verify Partition Available On BMC  operation_status=${False}


Read Partition And Verify Content
    [Documentation]  Read partition and verify content.
    [Arguments]  ${partition_name}=p1  ${content}=${EMPTY}  ${expect_resp_code}=${HTTP_OK}

    # Description of argument(s):
    # partition_name      Name of the partition on BMC.
    # content             Content of the partition file uploaded.
    # expect_resp_code    Expected REST response code, default is ${HTTP_OK}.

    ${resp}=  Get Request  openbmc  /ibm/v1/Host/ConfigFiles/${partition_name}
    Should Be Equal As Strings  ${resp.status_code}  ${expect_resp_code}

    ${partition_data}=  Remove String  ${resp.text}  \\n
    ${partition_data}=  Evaluate  json.loads('''${partition_data}''')  json
    Should Be Equal As Strings  ${partition_data["Data"]}  ${content}


Delete Local File Created To Upload
    [Documentation]  Delete local file created to upload.
    [Arguments]  ${file_name}

    # Description of argument(s):
    # file_name       Name of the local file to be deleted.

    Run Keyword And Ignore Error  Run  rm -f ${file_name}


Upload Partition File With Some Known Contents
    [Documentation]  Upload partition file with some known contents.
    [Arguments]  ${file_name}  ${partition_name}  ${content}

    # Description of argument(s):
    # file_name           Name of the partition file to be uploaded.
    # partition_name      Name of the partition on BMC.
    # content             Content of the partition file to be uploaded.

    Run  echo "${content}" > ${file_name}
    OperatingSystem.File Should Exist  ${file_name}

    Upload File To Create Partition Then Delete Partition  ${file_name}  1  ${partition_name}
    ...  delete_partition=${False}


Suite Setup Execution
    [Documentation]  Suite setup execution.

    # Create different user accounts.
    Redfish.Login
    Create Users With Different Roles  users=${USERS}  force=${True}
    # Get REST session to BMC.
    Initialize OpenBMC


Test Teardown Execution
    [Documentation]  Test teardown execution.

    Delete And Verify All Partitions on BMC
    FFDC On Test Case Fail


Suite Teardown Execution
    [Documentation]  Suite teardown execution.

    Delete BMC Users Via Redfish  users=${USERS}
    Delete All Sessions
