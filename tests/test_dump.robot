*** Settings ***

Documentation       Test dump functionality of OpenBMC.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/rest_client.robot
Resource            ../lib/state_manager.robot

Test Setup          Open Connection And Log In
Test Teardown       Post Testcase Execution

*** Variables ***


*** Test Cases ***



*** Keywords ***

Create User Initiated Dump
    [Documentation]  Generate user initiated dump. And returns
    ...  dump id (e.g 1, 2 etc).

    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  OpenBMC Post Request
    ...  ${DUMP_URI}/action/CreateDump  data=${data}
    ${json}=  To JSON  ${resp.content}
    Should Be Equal As Strings  ${json["status"]}  ok

    [Return]  ${json["data"]}

Post Testcase Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Close All Connections
