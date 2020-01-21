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
${FILE_UPLOADED_MSG}  File Created

*** Test Cases ***

Verify Small Partition File Upload And Delete
    [Documentation]  Verify small partition file upload and delete.
    [Tags]  Verify_Small_Partition_File_Upload_And_Delete
    [Template]  Create And Upload File To Create Partition Then Delete Partition

    # filename  size_kb  partition  expect_resp_code     msg                      delete_partition
    201KB_file  201      201KB      ${HTTP_BAD_REQUEST}  ${MAX_SIZE_UPLOAD_MSG}
    15KB_file   15       15KB       
    200KB_file  200      200KB

    # Upload multiple files and let test teardown delete all of them in one go
    0KB_file    0        0KB        delete_partition=${False}
    10KB_file   10       10KB       delete_partition=${False}
    50KB_file   50       50KB       delete_partition=${False}
    100KB_file  100      100KB      delete_partition=${False}
    199KB_file  199      199KB      delete_partition=${False}


Verify Read Partition
    [Documentation]  Verify read partition.
    [Tags]  Verify_Read_Partition

    Set Test Variable  ${filename}  testfile
    Set Test Variable  ${partition}  part_read
    Set Test Variable  ${content}  Sample Content to test partition file upload

    Run  echo "${content}" > ${filename}
    OperatingSystem.File Should Exist  ${filename}

    Create And Upload File To Create Partition Then Delete Partition  ${filename}  1  ${partition}
    ...  delete_partition=${False}

    Read Partition And Verify Content  ${partition}  ${content}


*** Keywords ***

Create Partition File
    [Documentation]  Create partition file.
    [Arguments]  ${filename}=dummyfile  ${size_kb}=15

    # Description of argument(s):
    # filename            Name of the test file to be created.
    # size_kb             Size of the test file to be created in KB, deafult is 15KB
    #                     Example : 15, 200 etc.

    ${file_exist}=  Run Keyword And Return Status  OperatingSystem.File Should Exist  ${filename}
    Return From Keyword If  ${file_exist}  ${True}

    # Create a partition file if it does not exist locally
    Run  dd if=/dev/zero of=${filename} bs=1 count=0 seek=${size_kb}KB
    OperatingSystem.File Should Exist  ${filename}


Create And Upload File To Create Partition Then Delete Partition
    [Documentation]  Create and upload file to create partition the delete partition.
    [Arguments]  ${filename}=dummyfile  ${size_kb}=15  ${partition}=p1  ${expect_resp_code}=${HTTP_OK}
    ...  ${msg}=File Created  ${delete_partition}=${True}

    # Description of argument(s):
    # filename            Name of the test file to be created.
    # partition           Name of the partition on BMC.
    # expect_resp_code    Expected REST response code, default is ${HTTP_OK}.
    # msg                 Expected message from file upload, default is 'File Created'.
    # delete_partition    Partition will be deleted if this is True

    # Create a partition file
    Create Partition File  ${filename}  ${size_kb}

    # Get the content of the file and upload to BMC
    ${image_data}=  OperatingSystem.Get Binary File  ${filename}
    ${data}=  Create Dictionary  data  ${image_data}
    ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}
    
    Set To Dictionary  ${data}  headers  ${headers}
    ${resp}=  Put Request  openbmc  /ibm/v1/Host/ConfigFiles/${partition}  &{data}
    Should Be Equal As Strings  ${resp.status_code}  ${expect_resp_code}

    # Upload Success will have a response body as :
    #           {
    #             "Description": "File Created"
    #           }
    ${message}=  evaluate  json.loads('''${resp.text}''')  json
    Should Be Equal As Strings  ${message["Description"]}  ${msg}

    # Cleanup local space after upload attempt
    Run Keyword And Ignore Error  Delete Local File Created To Upload  ${filename}
   
    ${upload_success}=  Set Variable If   ${expect_resp_code} != ${HTTP_OK}  ${False}  ${True}
    Verify Partition Availability After File Upload  ${partition}  ${upload_success}

    # Delete partition and verify on BMC
    Return From Keyword If  ${delete_partition} == ${False}
    ${del_resp_code}=  Set Variable If  ${expect_resp_code} != ${HTTP_OK}  ${HTTP_NOT_FOUND}  ${HTTP_OK}
    Delete Partition  ${partition}  ${del_resp_code}
    Verify Partition Availability After Delete  ${partition}


Verify Partition Availability After File Upload
    [Documentation]  Verify partition availability after file upload
    [Arguments]  ${partition}=p1  ${upload_success}=${True}

    # Description of argument(s):
    # partition           Name of the partition on BMC.
    # upload_success      True incase of successful upload else False.

    ${partition_found}=  Run Keyword And Return Status  Verify Partition Available On BMC  ${partition}
    Should Be Equal  ${partition_found}  ${upload_success}


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
    [Arguments]  ${partition}=${EMPTY}

    # Description of argument(s):
    # partition           Name of the partition on BMC.

    ${partitions}  ${partitions_cnt}=  Get List Of Partitions
    ${rest_response}=  Run Keyword And Return Status  List Should Contain Value  ${partitions}
    ...  /ibm/v1/Host/ConfigFiles/${partition}

    ${status}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ls -l /var/lib/obmc/bmc-console-mgmt/save-area/${partition} | wc -l
    ${bmc_response}=  Run Keyword And Return Status  Should Be True  ${status} == ${1}

    Run Keyword If  '${partition}' == '${EMPTY}'  Run Keywords
    ...  Should Be Equal  ${rest_response}  ${False}  AND  Should Be Equal  ${bmc_response}  ${False}
    Return From Keyword If  '${partition}' == '${EMPTY}'

    Should Be True  ${rest_response} == ${True}
    Should Be True  ${bmc_response} == ${True}


Delete Partition
    [Documentation]  Delete partition.
    [Arguments]  ${partition}='${EMPTY}'  ${expect_resp_code}=${HTTP_OK}

    # Description of argument(s):
    # partition           Name of the partition on BMC.
    # expect_resp_code    Expected REST response code, default is ${HTTP_OK}.

    ${data}=  Create Dictionary
    ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}
    Set To Dictionary  ${data}  headers  ${headers}

    ${resp}=  Delete Request  openbmc  /ibm/v1/Host/ConfigFiles/${partition}  &{data}
    ${expect_resp_code}=  Set Variable If  '${partition}' == '${EMPTY}'  ${HTTP_NOT_FOUND}  ${expect_resp_code}
    Should Be Equal As Strings  ${resp.status_code}  ${expect_resp_code}


Verify Partition Availability After Delete
    [Documentation]  Verify partition availability after delete.
    [Arguments]  ${partition}=p1  ${delete_failure}=${False}

    # Description of argument(s):
    # partition           Name of the partition on BMC.
    # delete_failure      False if delete is successful else True

    ${partition_found}=  Run Keyword And Return Status  Verify Partition Available On BMC  ${partition}
    Should Be Equal  ${partition_found}  ${delete_failure}


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
    Verify Partition Available On BMC


Read Partition And Verify Content
    [Documentation]  Read partition and verify content.
    [Arguments]  ${partition}=p1  ${content}=${EMPTY}  ${expect_resp_code}=${HTTP_OK}

    # Description of argument(s):
    # partition           Name of the partition on BMC.
    # content             Content of the partition file uploaded.
    # expect_resp_code    Expected REST response code, default is ${HTTP_OK}.

    ${resp}=  Get Request  openbmc  /ibm/v1/Host/ConfigFiles/${partition}
    Should Be Equal As Strings  ${resp.status_code}  ${expect_resp_code}

    ${partition_data}=  Remove String  ${resp.text}  \\n
    ${partition_data}=  evaluate  json.loads('''${partition_data}''')  json
    Should Be Equal As Strings  ${partition_data["Data"]}  ${content}


Delete Local File Created To Upload
    [Documentation]  Delete local file created to upload
    [Arguments]  ${filename}=${EMPTY}

    # Description of argument(s):
    # filename       Name of the local file to be deleted.

    Run Keyword And Ignore Error  Run  rm -f ${filename}


Suite Setup Execution
    [Documentation]  Suite setup execution.

    # Get REST session to BMC
    Initialize OpenBMC


Test Teardown Execution
    [Documentation]  Test teardown execution.

    Delete And Verify All Partitions on BMC
#    FFDC On Test Case Fail

