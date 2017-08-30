*** Settings ***

Documentation       Test dump functionality of OpenBMC.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/rest_client.robot
Resource            ../lib/dump_utils.robot

Test Setup          Open Connection And Log In
Test Teardown       Post Testcase Execution

*** Variables ***


*** Test Cases ***

Verify User Initiated BMC Dump
    [Documentation]  Create user initiated BMC dump and verify dump
    ...  entry for it.
    [Tags]  Verify_User_Initiated_Dump

    Create User Initiated Dump


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


Verify BMC Core Dump
    [Documentation]  Create BMC core dump and verify dump
    ...  entry for it.
    [Tags]  Verify_BMC_Core_Dump

    Delete All Dumps
    Trigger Core Dump
    Wait Until Keyword Succeeds  1 min  10 sec  Get Dump Entries 


Verify Core Dump Size
    [Documentation]  Verify BMC core dump size is under 200k.
    [Tags]  Verify_Core_Dump_Size

    Delete All Dumps
    Trigger Core Dump
    Wait Until Keyword Succeeds  1 min  10 sec  Get Dump Entries

    ${dump_entries}=  Get URL List  ${DUMP_ENTRY_URI}
    ${dump_size}=  Read Attribute  ${dump_entries[0]}  Size

    # Max size for dump is 200k = 200x1024
    Should Be True  0 < ${dump_size} < 204800


*** Keywords ***

Post Testcase Execution
    [Documentation]  Do the post test teardown.

    Delete All Dumps
    FFDC On Test Case Fail
    Close All Connections
