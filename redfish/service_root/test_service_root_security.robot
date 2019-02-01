*** Settings ***
Resource         ../../lib/resource.txt
Resource         ../../lib/bmc_redfish_resource.robot

*** Test Cases ***

Login To BMCweb With Invalid Credentials
    [Documentation]  Login to BMC web using invalid credential.
    [Tags]  Login_To_BMCweb_With_Invalid_Credentials
    [Template]  Login And Verify Redfish Response

    # Expect status            Username        Password
    InvalidCredentialsError*   root            deadpassword
    InvalidCredentialsError*   groot           0penBmc


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

