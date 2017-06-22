*** Settings ***

Documentation       Test dump functionality of OpenBMC.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/rest_client.robot

Test Setup          Open Connection And Log In
Test Teardown       Post Testcase Execution

*** Variables ***


*** Test Cases ***

Verify User Initiated Dump At Host Running
    [Documentation]  Verify user initiated dump at host running.
    [Tags]  Verify_User_Initiated_Dump_At_Host_Running

    Initiate Host Boot
    ${dump_id}=  Create User Initiated Dump
    Check Dump Entry  ${dump_id}


Verify User Initiated Dump At Host Off
    [Documentation]  Verify user initiated dump at host off.
    [Tags]  Verify_User_Initiated_Dump_At_Host_Off

    Initiate Host PowerOff
    ${dump_id}=  Create User Initiated Dump
    Check Dump Entry  ${dump_id}


Delete User Initiated Dump And Verify
    [Documentation]  Delete user initiated dump and verify.
    [Tags]  Delete_User_Initiated_Dump_And_Verify

    ${dump_id}=  Create User Initiated Dump
    Check Dump Entry  ${dump_id}

    ${resp}=  Delete Dump Entry  ${dump_id}
    Should Be Equal As Strings  ${resp}  ok


Verify User Initiated Dump Size
    [Documentation]  Verify user Initiated dump size.
    [Tags]  Verify_User_Initiated_Dump_Size

    ${dump_id}=  Create User Initiated Dump

    ${dump_size}=  Read Attribute  ${DUMP_ENTRY_URI}/${dump_id}  Size
    # Max size for dump is 500k
    Should Be True  ${dump_size} < 500000


*** Keywords ***

Create User Initiated Dump
    [Documentation]  Generate user initiated dump. And returns
    ...  dump id (e.g 1, 2 etc).

    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  OpenBMC Post Request
    ...  ${DUMP_URI}/action/CreateDump  data=${data}
    ${json}=  To JSON  ${resp.content}
    Should Be Equal As Strings  ${json["status"]}  ok
    Sleep  3 secs

    [Return]  ${json["data"]}

Check Dump Entry
    [Documentation]  Verify if given dump entry exist.
    [Arguments]  ${dump_id}
    # Description of Arguments:
    # dump_id  dump entry to be checked (e.g. 1, 3, 5).

    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}/${dump_id}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    

Delete Dump Entry
    [Documentation]  Deletes given dump entry.
    [Arguments]  ${dump_id}
    # Description of Arguments:
    # dump_id  dump entry to be deleted (e.g. 1, 3, 5).

    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  OpenBMC Post Request
    ...  ${DUMP_ENTRY_URI}/${dump_id}/action/Delete  data=${data}

    ${json}=  To JSON  ${resp.content}

    [Return]  ${json["status"]}

Post Testcase Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Close All Connections
