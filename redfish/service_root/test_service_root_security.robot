*** Settings ***
Resource         ../../lib/resource.txt
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Test Teardown    FFDC On Test Case Fail

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
