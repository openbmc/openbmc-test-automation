*** Settings ***
Documentation    Test Redfish user account.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


** Test Cases **

Verify AccountService Available
    [Documentation]  Verify Redfish account service is available.
    [Tags]  Verify_AccountService_Available

    ${resp} =  redfish_utils.Get Attribute  /redfish/v1/AccountService  ServiceEnabled
    Should Be Equal As Strings  ${resp}  ${True}

Redfish Create And Verify Specified User
    [Documentation]  Create Redfish User With Specified Role
    [Tags]  Redfish_Login_With_Specified_Credentials
    [Template]  Redfish Create And Verify User

    #  Username               Password              RoleId                  Enabled
       admin_user             TestPwd123            Administrator           ${True}
       operator_user          TestPwd123            Operator                ${True}
       user_user              TestPwd123            User                    ${True}
       callback_user          TestPwd123            Callback                ${True}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.
 
    FFDC On Test Case Fail
    redfish.Logout

Redfish Create And Verify User
    [Documentation]  Redfish Create And Verify User
    [Arguments]  ${Username}  ${Password}  ${RoleId}  ${Enabled}

    # Description of arguments:
    # Username            The username to be created
    # Password            The password to be assigned
    # Roleid              The role id of the user to be created
    # Enabled             The decision if it should be enabled

    # Example:
    # redfiscription": "User Account",
    # "Enabled": true,
    # "Id": "username",
    # "Links": {
    # "Role": {
    #  "@odata.id": "/redfish/v1/AccountService/Roles/Operator"
    # }
    # },

    ${payload}=  Create Dictionary
    ...  UserName=${Username}  Password=${Password}  RoleId=${RoleId}  Enabled=${Enabled}
    ${resp}=  redfish.Post  /redfish/v1/AccountService/Accounts  body=&{payload}
    Should Be Equal As Strings  ${resp.status}  ${HTTP_CREATED}

    ${output}=  redfish.Get  /redfish/v1/AccountService/Accounts
    Log  ${output}

    ${data}=  Create Dictionary  username=${Username}  password=${Password}
    redfish.Login  ${data}

    ${resp} =  redfish_utils.Get Attribute  /redfish/v1/AccountService/Accounts/${UserName}  RoleId
    Should Be Equal As Strings  ${resp}  ${RoleId}

    ${resp}=  redfish.Delete  /redfish/v1/AccountService/Accounts/${UserName}
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}

    ${output}=  redfish.Get  /redfish/v1/AccountService/Accounts
    Log  ${output}

