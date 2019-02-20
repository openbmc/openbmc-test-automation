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


Test Create Redfish User With Admin Role
    [Documentation]  Create Redfish User With Admin Role.
    [Tags]  Test_Create_Redfish_User_With_Admin_Role

    # Example:
    # redfiscription": "User Account",
    # "Enabled": true,
    # "Id": "test1",
    # "Links": {
    # "Role": {
    #  "@odata.id": "/redfish/v1/AccountService/Roles/Administrator"
    # }
    #  },

    redfish.Login
    ${payload}=  Create Dictionary
    ...  UserName=sandhya  Password=TestPwd123  RoleId=Administrator  Enabled=${True}
    ${resp}=  redfish.Post  AccountService/Accounts  body=&{payload}
    Should Be Equal As Strings  ${resp.status}  ${HTTP_CREATED}

    ${data}=  Create Dictionary  username=sandhya  password=TestPwd123
    redfish.Login  ${data}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    redfish.Logout


