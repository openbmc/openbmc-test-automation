*** Settings ***

Documentation    Test Save Area feature of Management Console on BMC.

Resource          ../../lib/rest_client.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/resource.robot
Resource          ../../lib/utils.robot

Suite Setup    Suite Setup Execution
Test Teardown  Test Teardown Execution


*** Variables ***

${MAX_SIZE_UPLOAD_MSG}  File size exceeds 200KB. Maximum allowed size is 200KB
${FILE_UPLOADED_MSG}    File Created


*** Test Cases ***

Verify Small Partition File Upload And Delete
    [Documentation]  Verify small partition file upload and delete.
    [Tags]  Verify_Small_Partition_File_Upload_And_Delete
    [Template]  Upload File To Create Partition Then Delete Partition

    # file_name  size_kb  partition_name  expect_resp_code     expected_msg             delete_partition
    201KB_file   201      201KB           ${HTTP_BAD_REQUEST}  ${MAX_SIZE_UPLOAD_MSG}   ${True}
    15KB_file    15       15KB            ${HTTP_OK}           ${FILE_UPLOADED_MSG}     ${True}
    200KB_file   200      200KB           ${HTTP_OK}           ${FILE_UPLOADED_MSG}     ${True}


Verify Multiple Files Upload
    [Documentation]  Verify multiple files upload.
    [Tags]  Verify_Multiple_Files_Upload
    [Template]  Upload File To Create Partition Then Delete Partition

    # file_name  size_kb  partition_name  expect_resp_code     expected_msg             delete_partition
    0KB_file     0        0KB             ${HTTP_OK}           ${FILE_UPLOADED_MSG}     ${False}
    10KB_file    10       10KB            ${HTTP_OK}           ${FILE_UPLOADED_MSG}     ${False}
    50KB_file    50       50KB            ${HTTP_OK}           ${FILE_UPLOADED_MSG}     ${False}
    250KB_file   250      250KB           ${HTTP_BAD_REQUEST}  ${MAX_SIZE_UPLOAD_MSG}   ${False}
    15KB_file    15       15KB            ${HTTP_OK}           ${FILE_UPLOADED_MSG}     ${False}
    199KB_file   199      199KB           ${HTTP_OK}           ${FILE_UPLOADED_MSG}     ${False}


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


Upload File To Create Partition Then Delete Partition
    [Documentation]  Upload file to create partition the delete partition.
    [Arguments]  ${file_name}=dummyfile  ${size_kb}=15  ${partition_name}=p1  ${expect_resp_code}=${HTTP_OK}
    ...  ${expected_msg}=File Created  ${delete_partition}=${True}

    # Description of argument(s):
    # file_name           Name of the test file to be created.
    # partition_name      Name of the partition on BMC.
    # expect_resp_code    Expected REST response code, default is ${HTTP_OK}.
    # expected_msg        Expected message from file upload, default is 'File Created'.
    # delete_partition    Partition will be deleted if this is True.

    # Create a partition file.
    Create Partition File  ${file_name}  ${size_kb}

    # Get the content of the file and upload to BMC.
    ${image_data}=  OperatingSystem.Get Binary File  ${file_name}
    ${data}=  Create Dictionary  data  ${image_data}
    ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}

    Set To Dictionary  ${data}  headers  ${headers}
    ${resp}=  Put Request  openbmc  /ibm/v1/Host/ConfigFiles/${partition_name}  &{data}
    Should Be Equal As Strings  ${resp.status_code}  ${expect_resp_code}

    # Upload Success will have a response body as :
    #           {
    #             "Description": "File Created"
    #           }
    ${message}=  evaluate  json.loads('''${resp.text}''')  json
    Should Be Equal As Strings  ${message["Description"]}  ${expected_msg}

    # Cleanup local space after upload attempt.
    Run Keyword And Ignore Error  Delete Local File Created To Upload  ${file_name}

    ${upload_success}=  Set Variable If   ${expect_resp_code} != ${HTTP_OK}  ${False}  ${True}
    Verify Partition Available On BMC  ${partition_name}  ${upload_success}

    # Delete partition and verify on BMC.
    Return From Keyword If  ${delete_partition} == ${False}
    ${del_resp_code}=  Set Variable If  ${expect_resp_code} != ${HTTP_OK}  ${HTTP_NOT_FOUND}  ${HTTP_OK}
    Delete Partition  ${partition_name}  ${del_resp_code}
    Verify Partition Available On BMC  ${partition_name}  ${False}


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
    [Arguments]  ${partition_name}=${EMPTY}  ${operation_status}=${True}

    # Description of argument(s):
    # partition_name    Name of the partition on BMC.
    # operation_success   Status of the previous operation like upload/delete success or failure.
    #                     True if operation was a success else False.


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


Suite Setup Execution
    [Documentation]  Suite setup execution.

    # Get REST session to BMC.
    Initialize OpenBMC


Test Teardown Execution
    [Documentation]  Test teardown execution.

    Delete And Verify All Partitions on BMC
    FFDC On Test Case Fail

