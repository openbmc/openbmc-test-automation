*** Settings ***
Documentation    Test Redfish user account.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


** Test Cases **

Verify AccountService Available
    [Documentation]  Verify Redfish AccountService is available.
    [Tags]  Verify_AccountService_Available

    ${resp} =  redfish_utils.Get Attribute  /redfish/v1/AccountService  ServiceEnabled
    Should Be Equal As Strings  ${resp}  ${True}


Redfish Create And Verify Administrator User
    [Documentation]  Create Redfish User With Admin Role.
    [Tags]  Redfish_Create_And_Verify_Administrator_User

    # Example:
    # redfiscription": "User Account",
    # "Enabled": true,
    # "Id": "username",
    # "Links": {
    # "Role": {
    #  "@odata.id": "/redfish/v1/AccountService/Roles/Administrator"
    # }
    #  },

    ${payload}=  Create Dictionary
    ...  UserName=admin_user  Password=TestPwd123  RoleId=Administrator  Enabled=${True}
    ${resp}=  redfish.Post  AccountService/Accounts  body=&{payload}
    Should Be Equal As Strings  ${resp.status}  ${HTTP_CREATED}

    ${data}=  Create Dictionary  username=admin_user  password=TestPwd123
    redfish.Login  ${data}

    ${resp} =  redfish_utils.Get Attribute  /redfish/v1/AccountService/Accounts/admin_user  RoleId
    Should Be Equal As Strings  ${resp}  Administrator

    ${resp}=  redfish.Delete  /redfish/v1/AccountService/Accounts/admin_user
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    redfish.Logout


