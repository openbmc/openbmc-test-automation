*** Settings ***

Documentation   This testsuite is for testing journal logs in openbmc.

Resource           ../lib/rest_client.robot
Resource           ../lib/utils.robot
Resource           ../lib/openbmc_ffdc.robot

Suite Setup        Open Connection And Log In
Suite Teardown     Close All Connections
Test Teardown      Log FFDC

*** Variables ***
&{NIL}  data=@{EMPTY}

*** Test Cases ***

Get Request Journal Log
    [Documentation]   This testcase is to verify that proper log is logged in
    ...               journal log for GET request.
    [Tags]  Get_Request_Journal_Log

    Start Journal Log

    openbmc get request     ${OPENBMC_BASE_URI}

    ${output}=    Stop Journal Log
    Should Contain   ${output}    GET ${OPENBMC_BASE_URI} HTTP/1.1

Post Request Journal Log
    [Documentation]   This testcase is to verify that proper log is logged in
    ...               journal log for POST request.
    [Tags]  Post_Request_Journal_Log

    Start Journal Log

    openbmc post request     ${OPENBMC_BASE_URI}records/events/action/clear    data=${NIL}

    ${output}=    Stop Journal Log
    Should Contain   ${output}    POST ${OPENBMC_BASE_URI}records/events/action/clear HTTP/1.1

Put Request Journal Log
    [Documentation]   This testcase is to verify that proper log is logged in
    ...               journal log for PUT request.
    [Tags]  Put_Request_Journal_Log

    Start Journal Log

    ${bootpolicy} =   Set Variable   ONETIME
    ${valueDict} =   create dictionary   data=${bootpolicy}
    openbmc put request  ${OPENBMC_BASE_URI}settings/host0/attr/boot_policy   data=${valueDict}

    ${output}=    Stop Journal Log
    Should Contain   ${output}    PUT ${OPENBMC_BASE_URI}settings/host0/attr/boot_policy HTTP/1.1

*** Keywords ***

