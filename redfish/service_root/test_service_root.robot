*** Settings ***
Documentation       Test Redfish to verify responses for SessionService and Hypermedia.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/openbmc_ffdc.robot

Test Setup          Printn
Test Teardown       FFDC On Test Case Fail

Test Tags           service_root


*** Test Cases ***
Redfish Login And Logout
    [Documentation]    Login to BMCweb and then logout.
    [Tags]    redfish_login_and_logout

    Redfish.Login
    Redfish.Logout

GET Redfish Hypermedia Without Login
    [Documentation]    GET hypermedia URL without login.
    [Tags]    get_redfish_hypermedia_without_login
    [Template]    GET And Verify Redfish Response
    [Setup]    Redfish.Logout

    # Expect status    Resource URL Path
    ${HTTP_OK}    /redfish
    ${HTTP_OK}    /redfish/v1

GET Redfish SessionService Without Login
    [Documentation]    Get /redfish/v1/SessionService without login
    [Tags]    get_redfish_sessionservice_without_login
    [Setup]    Redfish.Logout

    ${resp}=    Redfish.Get    /redfish/v1/SessionService
    ...    valid_status_codes=[${HTTP_UNAUTHORIZED}]

GET Redfish Resources With Login
    [Documentation]    Login to BMCweb and GET valid resource.
    [Tags]    get_redfish_resources_with_login
    [Template]    GET And Verify Redfish Response
    [Setup]    Redfish.Login

    # Expect status    Resource URL Path
    ${HTTP_OK}    /redfish/v1/SessionService
    ${HTTP_OK}    /redfish/v1/AccountService
    ${HTTP_OK}    /redfish/v1/Systems/${SYSTEM_ID}
    ${HTTP_OK}    /redfish/v1/Chassis/${CHASSIS_ID}
    ${HTTP_OK}    /redfish/v1/Managers/${MANAGER_ID}
    ${HTTP_OK}    /redfish/v1/UpdateService

Redfish Login Using Invalid Token
    [Documentation]    Login to BMCweb with invalid token.
    [Tags]    redfish_login_using_invalid_token

    Create Session    openbmc    ${AUTH_URI}

    # Example: "X-Auth-Token: 3la1JUf1vY4yN2dNOwun"
    ${headers}=    Create Dictionary    Content-Type=application/json
    ...    X-Auth-Token=deadbeef

    ${resp}=    GET On Session
    ...    openbmc    /redfish/v1/SessionService/Sessions    headers=${headers}
    ...    expected_status=${HTTP_UNAUTHORIZED}

    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_UNAUTHORIZED}

Verify Redfish Invalid URL Response Code
    [Documentation]    Login to BMCweb and verify error response code.
    [Tags]    verify_redfish_invalid_url_response_code

    Redfish.Login
    Redfish.Get    /redfish/v1/idontexist    valid_status_codes=[${HTTP_NOT_FOUND}]
    Redfish.Logout

Delete Redfish Session Using Valid Login
    [Documentation]    Delete a session using valid login.
    [Tags]    delete_redfish_session_using_valid_login

    Redfish.Login
    ${session_info}=    Get Redfish Session Info

    Redfish.Login

    # Example o/p:
    # [{'@odata.id': '/redfish/v1/SessionService/Sessions/bOol3WlCI8'},
    #    {'@odata.id': '/redfish/v1/SessionService/Sessions/Yu3xFqjZr1'}]
    ${resp_list}=    Redfish_Utils.List Request
    ...    /redfish/v1/SessionService/Sessions

    Redfish.Delete    ${session_info["location"]}

    ${resp}=    Redfish_Utils.List Request    /redfish/v1/SessionService/Sessions
    List Should Not Contain Value    ${resp}    ${session_info["location"]}

Redfish Login Via SessionService
    [Documentation]    Login to BMC via redfish session service.
    [Tags]    redfish_login_via_sessionservice

    Create Session    openbmc    https://${OPENBMC_HOST}:${HTTPS_PORT}
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${data}=    Set Variable    {"UserName":"${OPENBMC_USERNAME}", "Password":"${OPENBMC_PASSWORD}"}

    ${resp}=    POST On Session    openbmc    /redfish/v1/SessionService/Sessions    data=${data}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_CREATED}

    ${headers}=    Create Dictionary    Content-Type=application/json
    ...    X-Auth-Token=${resp.headers["X-Auth-Token"]}
    ${resp}=    DELETE On Session    openbmc    ${REDFISH_SESSION}${/}${resp.json()["Id"]}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}

Verify Redfish Unresponsive URL paths
    [Documentation]    Verify that all URLs in /redfish/v1 respond.
    [Tags]    verify_redfish_unresponsive_url_paths

    Redfish.Login
    ${resource_list}    ${dead_resources}=    Enumerate Request    /redfish/v1    include_dead_resources=True
    Redfish.Logout
    Valid Length    dead_resources    max_length=0


*** Keywords ***
GET And Verify Redfish Response
    [Documentation]    GET given resource and verify response.
    [Arguments]    ${valid_status_codes}    ${resource_path}

    # Description of argument(s):
    # valid_status_codes    A comma-separated list of acceptable
    #    status codes (e.g. 200).
    # resource_path    Redfish resource URL path.

    ${resp}=    Redfish.Get    ${resource_path}
    ...    valid_status_codes=[${valid_status_codes}]
