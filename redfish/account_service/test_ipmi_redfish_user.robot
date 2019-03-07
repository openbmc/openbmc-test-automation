*** Settings ***
Documentation    Test IPMI and Redfish combinations for user management.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/ipmi_client.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


*** Variables ***

${valid_password}       0penBmc1


** Test Cases **

Create Admin Redfish User And Verify Login Via IPMI
    [Documentation]  Create user using redfish and verify via IPMI.
    [Tags]  Create_Admin_Redfish_User_And_Verify_Login_Via_IPMI

    ${random_username}=  Generate Random String  8  [LETTERS]
    Set Test Variable  ${random_username}

    # Delete if the user exist.
    Run Keyword And Ignore Error
    ...  Redfish.Delete  /redfish/v1/AccountService/Accounts/${random_username}

    ${payload}=  Create Dictionary
    ...  UserName=${random_username}  Password=${valid_password}
    ...  RoleId=Administrator  Enabled=${True}

    Redfish.Post  /redfish/v1/AccountService/Accounts  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    Redfish.Login  ${random_username}  ${valid_password}

    Verify IPMI Username And Password  ${random_username}  ${valid_password}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail

    # Delete the test user.
    Run Keyword And Ignore Error
    ...  Redfish.Delete  /redfish/v1/AccountService/Accounts/${random_username}

    Redfish.Logout
