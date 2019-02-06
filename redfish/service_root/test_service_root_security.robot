*** Settings ***
Resource         ../../lib/resource.txt
Resource         ../../lib/bmc_redfish_resource.robot

*** Test Cases ***

Login To BMCweb With Invalid Credentials
    [Documentation]  Login to BMC web using invalid credential.
    [Tags]  Login_To_BMCweb_With_Invalid_Credentials
    [Template]  Login And Verify Redfish Response

    # Expect status            Username               Password
    InvalidCredentialsError*   ${OPENBMC_USERNAME}    deadpassword
    InvalidCredentialsError*   groot                  ${OPENBMC_PASSWORD}
    InvalidCredentialsError*   ${EMPTY}               ${OPENBMC_PASSWORD}
    InvalidCredentialsError*   ${OPENBMC_USERNAME}    ${EMPTY}
    InvalidCredentialsError*   ${EMPTY}               ${EMPTY}


Login To BMCweb Using Unsecured HTTP
    [Documentation]  Login to BMC web through http unsecured.
    [Tags]  Login_To_BMCweb_Using_Unsecured_HTTP

    Create Session  openbmc  http://${OPENBMC_HOST}
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

    # Update __init__ with default credentials.
    # robot doesn't flush the object per suite if executed in sequence suites.
    ${data}=  Create Dictionary  username=${OPENBMC_USERNAME}  password=${OPENBMC_PASSWORD}
    redfish.Login  ${data}

