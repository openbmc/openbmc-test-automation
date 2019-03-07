*** Settings ***
Documentation    Test IPMI and Redfish combinations for user management.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/ipmi_client.robot

Test Setup       Redfish.Login
Test Teardown    Test Teardown Execution


*** Variables ***

${valid_password}       0penBmc1


** Test Cases **

Create User Using Redfish And Verify Via IPMI
    [Documentation]  Create user using redfish and verify via IPMI.
    [Tags]  Create_User_Using_Redfish_And_Verify_Via_IPMI

    ${random_username}=  Generate Random String  8  [LETTERS]
    ${payload}=  Create Dictionary
    ...  UserName=${random_username}  Password=${valid_password}
    ...  RoleId=Administrator  Enabled=${True}
    ${resp}=  Redfish.Post  /redfish/v1/AccountService/Accounts  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    Verify IPMI Username And Password  ${random_username}  ${valid_password}


*** Keywords ***

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Delete All Non Root User Via Redfish
    Redfish.Logout

Delete All Non Root User Via Redfish
    [Documentation]  Delete all non-root user via Redfish.

    ${user_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/AccountService/Accounts

    # Remove root user from the list.
    Remove Values From List  ${user_list}  /redfish/v1/AccountService/Accounts/root

    :FOR  ${user}  IN  @{user_list}
    \  Redfish.Delete  ${user}
