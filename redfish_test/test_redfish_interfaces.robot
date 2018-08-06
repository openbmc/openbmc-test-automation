*** Settings ***
Documentation    Test Redfish interfaces supported.

Resource         ../lib/redfish_client.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


** Test Cases **

Test Get Redfish Session Id
    [Documentation]  Establish session to BMC and get session identifier.
    [Tags]  Test_Get_Redfish_Session_Id

    # Example:
    # {
    #    "@odata.context": "/redfish/v1/$metadata#Session.Session",
    #    "@odata.id": "/redfish/v1/SessionService/Sessions/gxgwFkuPqo",
    #    "@odata.type": "#Session.v1_0_2.Session",
    #    "Description": "Manager User Session",
    #    "Id": "gxgwFkuPqo",
    #    "Name": "User Session",
    #    "UserName": "root"
    # }

    ${session_url} =
    ...  Catenate  SEPARATOR=  ${REDFISH_SESSION_URI}  ${test_session_id}
    ${resp} =  Redfish Get Request
    ...  ${session_url}  xauth_token=${test_auth_token}

    Should Be Equal As Strings
    ...  /redfish/v1/${session_url}  ${resp["@odata.id"]}


Test Invalid Redfish Token Access
    [Documentation]  Access valid session id using invalid session token.
    [Tags]  Test_Invalid_Redfish_Token_Access

    ${session_url} =
    ...  Catenate  SEPARATOR=  ${REDFISH_SESSION_URI}  ${test_session_id}
    ${resp} =  Redfish Get Request
    ...  ${session_url}  xauth_token=InvalidToken  response_format=${0}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_UNAUTHORIZED}


Test Get Redfish Response Codes
    [Documentation]  Get Redfish response codes and validate them.
    [Tags]  Test_Get_Redfish_Response_Codes
    [Template]  Execute Get And Check Response

    # Expected status    URL Path
    ${HTTP_OK}           Systems
    ${HTTP_OK}           Systems/motherboard
    ${HTTP_OK}           Chassis/system
    ${HTTP_OK}           Managers/openbmc/EthernetInterfaces/eth0
    ${HTTP_NOT_FOUND}    /i/dont/exist/


*** Keywords ***

Execute Get And Check Response
    [Documentation]  Execute "GET" request and check for expected status.
    [Arguments]  ${expected_response_code}  ${url_path}
    # Description of argument(s):
    # expected_response_code   Expected REST status codes.
    # url_path                 URL path.

    ${resp} =  Redfish Get Request
    ...  ${url_path}  xauth_token=${test_auth_token}  response_format=${0}
    Should Be Equal As Strings  ${resp.status_code}  ${expected_response_code}


Test Setup Execution
    [Documentation]  Do the test setup.

    ${session_id}  ${auth_token} =  Redfish Login Request
    Set Test Variable  ${test_session_id}  ${session_id}
    Set Test Variable  ${test_auth_token}  ${auth_token}


Test Teardown Execution
    [Documentation]  Do the test teardown.

    Redfish Delete Request  ${test_session_id}  ${test_auth_token}
