*** Settings ***
Documentation    This suite is to verify admin user restrictions.

Resource         ../../lib/connection_client.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot

Library          SSHLibrary

Suite Setup      Suite Setup Execution
Suite Teardown   Redfish.Logout
Test Teardown    FFDC On Test Case Fail


*** Test Cases ***

Verify SSH Login Access With Admin User
    [Documentation]  Verify admin user does not have ssh login access.
    [Tags]  Verify_SSH_Login_Access_With_Admin_User

    # Create a Admin User.
    # Make sure the user account in question does not already exist.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/new_admin
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    ${payload}=  Create Dictionary
    ...  UserName=new_admin  Password=TestPwd1  RoleId=Administrator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    # Attempt SSH login with admin user.
    SSHLibrary.Open Connection  ${OPENBMC_HOST}
    ${status}=   Run Keyword And Return Status  SSHLibrary.Login  new_admin  TestPwd1
    Should Be Equal  ${status}  ${False}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Redfish.Login
