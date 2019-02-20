*** Settings ***
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Test Teardown    FFDC On Test Case Fail

*** Variables ***

${LOGIN_SESSION_COUNT}   ${50}

*** Test Cases ***

Redfish Login With Invalid Credentials
    [Documentation]  Login to BMC web using invalid credential.
    [Tags]  Redfish_Login_With_Invalid_Credentials
    [Template]  Login And Verify Redfish Response

    # Expect status            Username               Password
    InvalidCredentialsError*   ${OPENBMC_USERNAME}    deadpassword
    InvalidCredentialsError*   groot                  ${OPENBMC_PASSWORD}
    InvalidCredentialsError*   ${EMPTY}               ${OPENBMC_PASSWORD}
    InvalidCredentialsError*   ${OPENBMC_USERNAME}    ${EMPTY}
    InvalidCredentialsError*   ${EMPTY}               ${EMPTY}


Redfish Login Using Unsecured HTTP
    [Documentation]  Login to BMC web through http unsecured.
    [Tags]  Redfish_Login_Using_Unsecured_HTTP

    Create Session  openbmc  http://${OPENBMC_HOST}
    ${data}=  Create Dictionary
    ...  UserName=${OPENBMC_USERNAME}  Password=${OPENBMC_PASSWORD}

    ${headers}=  Create Dictionary  Content-Type=application/json

    Run Keyword And Expect Error  *Connection refused*
    ...  Post Request  openbmc  /redfish/v1/SessionService/Sessions
    ...  data=${data}  headers=${headers}


Redfish Login Using HTTPS Wrong Port 80 Protocol
    [Documentation]  Login to BMC web through wrong protocol port 80.
    [Tags]  Redfish_Login_Using_HTTPS_Wrong_Port_80_Protocol

    Create Session  openbmc  https://${OPENBMC_HOST}:80
    ${data}=  Create Dictionary
    ...  UserName=${OPENBMC_USERNAME}  Password=${OPENBMC_PASSWORD}

    ${headers}=  Create Dictionary  Content-Type=application/json

    Run Keyword And Expect Error  *Connection refused*
    ...  Post Request  openbmc  /redfish/v1/SessionService/Sessions
    ...  data=${data}  headers=${headers}


Create Multiple Login Sessions And Verify
    [Documentation]  Create 50 login instances and verify.
    [Tags]  Create_Multiple_Login_Sessions_And_Verify
    [Teardown]  Multiple Session Cleanup

    redfish.Login
    # Example:
    #    {
    #      'key': 'L0XEsZAXpNdF147jJaOD',
    #      'location': '/redfish/v1/SessionService/Sessions/qWn2JOJSOs'
    #    }
    ${session_info}=   Get Redfish Session Info

    # Sessions book keeping for cleanup once done.
    ${session_list}=  Create List
    Set Test Variable  ${session_list}

    Repeat Keyword  ${LOGIN_SESSION_COUNT} times  Create New Login Session

    # Update the redfish session object with the first login key and location
    # and verify if it is still working.
    redfish.Set Session Key  ${session_info["key"]}
    redfish.Set Session Location  ${session_info["location"]}
    ${resp}=  redfish.Get  ${session_info["location"]}
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}


*** Keywords ***

Login And Verify Redfish Response
    [Documentation]  Login and verify redfish response.
    [Arguments]  ${expected_response}  ${username}  ${password}

    # Description of arguments:
    # expected_response   Expected REST status.
    # username            The username to be used to connect to the server.
    # password            The password to be used to connect to the server.

    ${data}=  Create Dictionary  username=${username}  password=${password}
    Run Keyword And Expect Error  ${expected_response}  redfish.Login  ${data}


Create New Login Session
    [Documentation]  Multiple login session keys.

    redfish.Login
    ${session_info}=  Get Redfish Session Info

    # Append the session location to the list
    # ['/redfish/v1/SessionService/Sessions/uDzihgDecs',
    #  '/redfish/v1/SessionService/Sessions/PaHF5brPPd']
    Append To List  ${session_list}  ${session_info["location"]}


Multiple Session Cleanup
    [Documentation]  Do the teardown for multiple sessions.

    FFDC On Test Case Fail

    :FOR  ${item}  IN  @{session_list}
    \  redfish.Delete  ${item}

