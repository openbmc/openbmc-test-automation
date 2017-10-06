*** Settings ***

Documentation       Test dump functionality of OpenBMC.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/rest_client.robot
Resource            ../lib/dump_utils.robot
Resource            ../lib/boot_utils.robot
Resource            ../lib/utils.robot
Library             ../lib/bmc_ssh_utils.py

Test Setup          Open Connection And Log In
Test Teardown       Post Testcase Execution

*** Variables ***


*** Test Cases ***

Pre Dump BMC Performance Test
    [Documentation]  Check performance of memory, CPU & file system of BMC.
    [Tags]  Pre_Dump_BMC_Performance_Test 

    Open Connection And Log In
    Check BMC Performance

Verify User Initiated BMC Dump
    [Documentation]  Create user initiated BMC dump and verify dump
    ...  entry for it.
    [Tags]  Verify_User_Initiated_Dump

    Create User Initiated Dump


Verify Dump Persistency On Service Restart
    [Documentation]  Create user dump, restart BMC service and verify dump
    ...  persistency.
    [Tags]  Verify_Dump_Persistency_On_Service_Restart

    Delete All Dumps
    Create User Initiated Dump
    BMC Execute Command
    ...  systemctl restart xyz.openbmc_project.Dump.Manager.service
    Sleep  10s  reason=Wait for BMC dump service to restart properly.

    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}/list
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Verify Dump Persistency On Reset
    [Documentation]  Create user dump, reset BMC and verify dump persistency.
    [Tags]  Verify_Dump_Persistency_On_Reset

    Delete All Dumps
    Create User Initiated Dump
    OBMC Reboot (off)
    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}/list
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Delete User Initiated BMC Dump And Verify
    [Documentation]  Delete user initiated dump and verify.
    [Tags]  Delete_User_Initiated_Dump_And_Verify

    ${dump_id}=  Create User Initiated Dump

    Delete BMC Dump  ${dump_id}


Verify User Initiated Dump Size
    [Documentation]  Verify user Initiated BMC dump size is under 200k.
    [Tags]  Verify_User_Initiated_Dump_Size

    ${dump_id}=  Create User Initiated Dump

    ${dump_size}=  Read Attribute  ${DUMP_ENTRY_URI}/${dump_id}  Size
    # Max size for dump is 200k = 200x1024
    Should Be True  0 < ${dump_size} < 204800


Create Two User Initiated Dump And Delete One
    [Documentation]  Create two dumps and delete the first.
    [Tags]  Create_Two_User_Initiated_Dump_And_Delete_One

    ${dump_id_1}=  Create User Initiated Dump
    ${dump_id_2}=  Create User Initiated Dump

    Delete BMC Dump  ${dump_id_1}

    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}/${dump_id_1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}/${dump_id_2}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Create And Delete BMC Dump Multiple Times
    [Documentation]  Create and delete BMC dump multiple times.
    [Tags]  Create_And_Delete_BMC_Dump_Multiple_Times

    :FOR  ${INDEX}  IN RANGE  1  5
    \  ${dump_id}=  Create User Initiated Dump
    \  Wait Until Keyword Succeeds  3 min  15 sec
    ...  Check Dump Existence  ${dump_id}
    \  Delete BMC Dump  ${dump_id}


Delete All BMC Dumps And Verify
    [Documentation]  Delete all BMC dumps and verify.
    [Tags]  Delete_All_BMC_Dumps_And_Verify

    # Create some dump.
    Create User Initiated Dump
    Create User Initiated Dump

    Delete All Dumps
    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}/list
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

Post Dump BMC Performance Test
    [Documentation]  Check performance of memory, CPU & file system of BMC.
    [Tags]  Post_Dump_BMC_Performance_Test

    Open Connection And Log In
    Check BMC Performance

Post Dump Core Dump Check
    [Documentation]  Check core dump existence on BMC after code update.
    [Tags]  Post_Dump_Core_Dump_Check 

    Check For Core Dumps

*** Keywords ***

Check BMC Performance
    [Documentation]  Check BMC basic CPU Mem File system performance.

    Check BMC CPU Performance
    Check BMC Mem Performance
    Check BMC File System Performance

Post Testcase Execution
    [Documentation]  Do the post test teardown.

    Delete All Dumps
    FFDC On Test Case Fail
    Close All Connections
