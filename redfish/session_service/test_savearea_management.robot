*** Settings ***
Documentation    Test Save Area Feature of HMC on BMC.

Resource          ../../lib/rest_client.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/resource.robot
Resource          ../../lib/utils.robot
Library           Collections

Suite Setup  Suite Setup Execution
Test Setup   Test Setup Execution
Test Teardown  Test Teardown Execution


*** Test Cases ***

Verify Small Partition File Upload And Delete
    [Documentation]  Verify small partition file upload and delete.
    [Tags]  Verify_Small_Partition_File_Upload_And_Delete

    Set Test Variable  ${file}  15KB_file
    Set Test Variable  ${partition}  15KB

    Create Partition File  ${file}
    Upload File To Create Partition  ${file}  ${partition}
    Verify Partition Availability After File Upload Success  ${partition}
    Delete Partition  ${partition}
    Verify Partition Availability After Delete Success  ${partition}


Verify 200KB Partition File Upload And Delete
    [Documentation]  Verify 200KB partition file upload and delete.
    [Tags]  Verify_200KB_Partition_File_Upload_And_Delete

    Set Test Variable  ${file}  200KB_file
    Set Test Variable  ${partition}  200KB

    Create Partition File  ${file}  ${partition}
    Upload File To Create Partition  ${file}  ${partition}
    Verify Partition Availability After File Upload Success  ${partition}
    Delete Partition  ${partition}
    Verify Partition Availability After Delete Success  ${partition}


Verify More Than 200KB Partition File Upload And Delete
    [Documentation]  Verify more than 200KB partition file upload and delete.
    [Tags]  Verify_More_Than_200KB_Partition_File_Upload_And_Delete

    Set Test Variable  ${file}  201KB_file
    Set Test Variable  ${partition}  201KB

    ${error_msg}=  Set Variable  File size exceeds 200KB. Maximum allowed size is 200KB

    Create Partition File  ${file}  ${partition}
    Upload File To Create Partition  ${file}  ${partition}  ${HTTP_BAD_REQUEST}  ${error_msg}
    Verify Partition Availability After File Upload Failure  ${partition}
    Delete Partition  ${partition}  ${HTTP_NOT_FOUND}
    Verify Partition Availability After Delete Success  ${partition}


Verify Multiple Partition Files Upload And Delete
    [Documentation]  Verify multiple partition files upload and delete.
    [Tags]  Verify_Multiple_Partition_Files_Upload_And_Delete

    Create Partition File  empty_file  0KB
    Create Partition File  5KB_file    5KB
    Create Partition File  10KB_file    10KB

    Upload File To Create Partition  empty_file  0KB
    Upload File To Create Partition  5KB_file    5KB
    Upload File To Create Partition  10KB_file   10KB

    Verify Partition Availability After File Upload Success  0KB
    Verify Partition Availability After File Upload Success  5KB
    Verify Partition Availability After File Upload Success  10KB

    Delete And Verify All Partitions on BMC
     

Verify Read Partition
    [Documentation]  Verify read partition.
    [Tags]  Verify_Read_Partition

    Set Test Variable  ${filename}  testfile
    Set Test Variable  ${partition}  part_read
    Set Test Variable  ${content}  Sample Content to test partition file upload

    Run  echo "${content}" > ${filename}
    OperatingSystem.File Should Exist  ${filename}

    Upload File To Create Partition  ${filename}  ${partition}
    Verify Partition Availability After File Upload Success  ${partition}

    Read Partition And Verify Content  ${partition}  ${content}
    
    

*** Keywords ***

Create Partition File
    [Documentation]  Create partitio file.
    [Arguments]  ${filename}=dummyfile  ${size}=15KB

    # Description of argument(s):
    # filename            Name of the test file to be created.

    Run  dd if=/dev/zero of=${filename} bs=1 count=0 seek=${size}
    OperatingSystem.File Should Exist  ${filename}


Upload File To Create Partition
    [Documentation]  Upload file to create partition.
    [Arguments]  ${filename}=dummyfile  ${partition_name}=p1  ${expect_resp_code}=${HTTP_OK}  ${msg}=File Created

    # Description of argument(s):
    # filename            Name of the test file to be created.

    # Get the content of the file and upload to BMC
    ${image_data}=  OperatingSystem.Get Binary File  ${filename}

    ${data}=  Create Dictionary  data  ${image_data}
    ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}

    Set To Dictionary  ${data}  headers  ${headers}
    ${resp}=  Put Request  openbmc  /ibm/v1/Host/ConfigFiles/${partition_name}  &{data}

    Log To Console  ${resp.text}
    Should Be Equal As Strings  ${resp.status_code}  ${expect_resp_code}

    ${message}=  evaluate  json.loads('''${resp.text}''')  json
    Should Be Equal As Strings  ${message["Description"]}  ${msg}
    


Verify Partition Availability After File Upload Success
    [Documentation]  Verify partition availability after file upload success.
    [Arguments]  ${partition_name}=p1

    Verify Partition Available On BMC  ${partition_name}
    

Verify Partition Availability After File Upload Failure
    [Documentation]  Verify partition availability after file upload failure.
    [Arguments]  ${partition_name}=p1

    ${partition_found}=  Run Keyword And Return Status  Verify Partition Available On BMC  ${partition_name}
    Should Be Equal  ${partition_found}  ${False}


Get List Of Partitions
    [Documentation]  Get list of partitions.
    [Arguments]  ${expect_resp_code}=${HTTP_OK}

    ${resp}=  Get Request  openbmc  /ibm/v1/Host/ConfigFiles
    Should Be Equal As Strings  ${resp.status_code}  ${expect_resp_code}

    Return From Keyword If  ${expect_resp_code} != ${HTTP_OK}

    ${resp_json}=  To JSON  ${resp.content}
    ${partitions_cnt}=  Get Length  ${resp_json['Members']}
    [Return]  ${resp_json['Members']}  ${partitions_cnt}


Verify Partition Available On BMC
    [Documentation]  Verify partition available on BMC.
    [Arguments]  ${partition_name}=${EMPTY}

    Check Partition Availability Via REST Method  ${partition_name}
    Check Partition Availability Via Login Method  ${partition_name}

    Run Keyword If  '${partition_name}' == '${EMPTY}'  Run Keywords
    ...  Should Be Equal  ${rest_resp}  ${False}  AND  Should Be Equal  ${login_resp}  ${False}
    Return From Keyword If  '${partition_name}' == '${EMPTY}'

    Should Be True  ${rest_resp} == ${True}
    Should Be True  ${login_resp} == ${True}


Check Partition Availability Via REST Method
    [Documentation]  Check partition availability via REST method.
    [Arguments]  ${partition_name}=${EMPTY}

    ${partitions}  ${partitions_cnt}=  Get List Of Partitions
    ${partition_found}=  Run Keyword And Return Status  Should Be True  ${partitions_cnt} > ${0}
    Set Test Variable  ${rest_resp}  ${partition_found}
    Return From Keyword If  '${partition_name}' == '${EMPTY}'

    ${partition_found}=  Run Keyword And Return Status  List Should Contain Value  ${partitions}
    ...  /ibm/v1/Host/ConfigFiles/${partition_name}
    Set Test Variable  ${rest_resp}  ${partition_found}


Check Partition Availability Via Login Method
    [Documentation]  Check partition availability via login method.
    [Arguments]  ${partition_name}=${EMPTY}

    ${status}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ls -l /var/lib/obmc/bmc-console-mgmt/save-area/${partition_name} | wc -l

    ${count}=  Set Variable If  '${partition_name}' == '${EMPTY}'  ${0}  ${1}
    ${partition_found}=  Run Keyword And Return Status  Should Be True  ${count} == ${1}
    Set Test Variable  ${login_resp}  ${partition_found}


Delete Partition
    [Documentation]  Delete partition.
    [Arguments]  ${partition_name}='${EMPTY}'  ${expect_resp_code}=${HTTP_OK}

    ${data}=  Create Dictionary
    ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}
    Set To Dictionary  ${data}  headers  ${headers}

    ${resp}=  Delete Request  openbmc  /ibm/v1/Host/ConfigFiles/${partition_name}  &{data}
    ${expect_resp_code}=  Set Variable If  '${partition_name}' == '${EMPTY}'  ${HTTP_NOT_FOUND}  ${expect_resp_code}
    
    Should Be Equal As Strings  ${resp.status_code}  ${expect_resp_code}


Verify Partition Availability After Delete Success
    [Documentation]  Verify partition availability after delete success.
    [Arguments]  ${partition_name}=p1

    ${partition_found}=  Run Keyword And Return Status  Verify Partition Available On BMC  ${partition_name}
    Should Be Equal  ${partition_found}  ${False}


Verify Partition Availability After Delete Failure
    [Documentation]  Verify partition availability after delete failure.
    [Arguments]  ${partition_name}=p1

    Verify Partition Available On BMC  ${partition_name}

    
Delete And Verify All Partitions on BMC
    [Documentation]  Delete and verify all partitions on BMC.
    [Arguments]  ${expect_resp_code}=${HTTP_OK}

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

    ${resp}=  Get Request  openbmc  /ibm/v1/Host/ConfigFiles/${partition}
    Should Be Equal As Strings  ${resp.status_code}  ${expect_resp_code}

    Log To Console  ${resp.text}

    ${partition_data}=  Remove String  ${resp.text}  \\n
    ${partition_data}=  evaluate  json.loads('''${partition_data}''')  json
    Should Be Equal As Strings  ${partition_data["Data"]}  ${content}


Suite Setup Execution
    [Documentation]  Suite setup execution.

    # Get REST session to BMC
    Initialize OpenBMC


Test Setup Execution
    [Documentation]  Test setup execution.

    Set Test Variable  ${rest_resp}  ${False}
    Set Test Variable  ${login_resp}  ${False}


Test Teardown Execution
    [Documentation]  Test teardown execution.

    Delete And Verify All Partitions on BMC
#    FFDC On Test Case Fail

