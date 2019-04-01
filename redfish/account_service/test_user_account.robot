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

    ${resp} =  Redfish_utils.Get Attribute  /redfish/v1/AccountService  ServiceEnabled
    Should Be Equal As Strings  ${resp}  ${True}

Redfish Create and Verify Users
    [Documentation]  Create Redfish users with various roles
    [Tags]  Redfish_Create_and_Verify_Users
    [Template]  Redfish Create And Verify User

     # username       password    role_id         enabled
       admin_user     TestPwd123  Administrator   ${True}
       operator_user  TestPwd123  Operator        ${True}
       user_user      TestPwd123  User            ${True}
       callback_user  TestPwd123  Callback        ${True}

Verify Redfish User with Wrong Password
    [Documentation]  Verify Redfish User with Wrong Password
    [Tags]  Verify_Redfish_User_with_Wrong_Password
    [Template]  Verify Redfish User with Wrong Password

     # username       password    role_id         enabled  wrong_password
       admin_user     TestPwd123  Administrator   ${True}  alskjhfwurh
       operator_user  TestPwd123  Operator        ${True}  12j8a8uakjhdaosiruf024
       user_user      TestPwd123  User            ${True}  12
       callback_user  TestPwd123  Callback        ${True}  !#@D#RF#@!D

Verify Login with Deleted Redfish Users
    [Documentation]  Verify login with deleted Redfish Users
    [Tags]  Verify_Login_with_Deleted_Redfish_Users
    [Template]  Verify Login with Deleted Redfish User

     # username       password    role_id         enabled
       admin_user     TestPwd123  Administrator   ${True}
       operator_user  TestPwd123  Operator        ${True}
       user_user      TestPwd123  User            ${True}
       callback_user  TestPwd123  Callback        ${True}

Verify Create User Without Enabling It
    [Documentation]  Verify Create User Without Enabling It
    [Tags]  Verify_Create_User_Without_Enabling_It
    [Template]  Verify Create User Without Enabling

     # username       password    role_id         enabled
       admin_user     TestPwd123  Administrator   ${False}
       operator_user  TestPwd123  Operator        ${False}
       user_user      TestPwd123  User            ${False}
       callback_user  TestPwd123  Callback        ${False}

Verify Redfish User Persistence After Reboot
    [Documentation]  Verify Redfish user persistence after reboot
    [Tags]  Verify_Redfish_User_Persistence_After_Reboot

    # Create Redfish users.
    Redfish Create User  admin_user     TestPwd123  Administrator   ${True}
    Redfish Create User  operator_user  TestPwd123  Operator        ${True}
    Redfish Create User  user_user      TestPwd123  User            ${True}
    Redfish Create User  callback_user  TestPwd123  Callback        ${True}

    # Reboot BMC.
    Redfish OBMC Reboot (off)

    # Verify users after reboot.
    Redfish Verify User  admin_user     TestPwd123  Administrator   ${True}
    Redfish Verify User  operator_user  TestPwd123  Operator        ${True}
    Redfish Verify User  user_user      TestPwd123  User            ${True}
    Redfish Verify User  callback_user  TestPwd123  Callback        ${True}

    # Delete created users.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/admin_user
    Redfish.Delete  /redfish/v1/AccountService/Accounts/operator_user
    Redfish.Delete  /redfish/v1/AccountService/Accounts/user_user
    Redfish.Delete  /redfish/v1/AccountService/Accounts/callback_user

*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Redfish.Logout

Redfish Create User
    [Documentation]  Redfish create user
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role id of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).

    # Make sure the user account in question does not already exist.
    Run Keyword And Ignore Error
    ...  Redfish.Delete  /redfish/v1/AccountService/Accounts/${username}

    # Create specified user.
    ${payload}=  Create Dictionary
    ...  UserName=${username}  Password=${password}  RoleId=${role_id}  Enabled=${enabled}
    Redfish.Post  /redfish/v1/AccountService/Accounts  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    Redfish.Logout

    # Login with created user.
    Redfish.Login  ${username}  ${password}

    # Validate Role Id of created user.
    ${role_config}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/${username}  RoleId
    Should Be Equal  ${role_id}  ${role_config}

Redfish Verify User
    [Documentation]  Redfish create user
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role id of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).

    # Login with created user.
    Redfish.Login  ${username}  ${password}

    # Validate Role Id of created user.
    ${role_config}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/${username}  RoleId
    Should Be Equal  ${role_id}  ${role_config}


Redfish Create And Verify User
    [Documentation]  Redfish create and verify user.
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role id of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).

    # Example:
    #{
    #"@odata.context": "/redfish/v1/$metadata#ManagerAccount.ManagerAccount",
    #"@odata.id": "/redfish/v1/AccountService/Accounts/test1",
    #"@odata.type": "#ManagerAccount.v1_0_3.ManagerAccount",
    #"Description": "User Account",
    #"Enabled": true,
    #"Id": "test1",
    #"Links": {
    #  "Role": {
    #    "@odata.id": "/redfish/v1/AccountService/Roles/Administrator"
    #  }
    #},

    Redfish.Login

    Redfish Create User  ${username}  ${password}  ${role_id}  ${enabled}

    Redfish Verify User  ${username}  ${password}  ${role_id}  ${enabled}

    # Delete Specified User
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${username}

Verify Redfish User with Wrong Password
    [Documentation]  Verify Redfish User with Wrong Password
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}  ${wrong_password}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role id of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).
    # wrong_password      Any invalid password.

    Redfish.Login

    Redfish Create User  ${username}  ${password}  ${role_id}  ${enabled}

    Redfish.Logout

    # Attempt to login with created user with invalid password.
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  ${username}  ${wrong_password}

    Redfish.Login

    # Delete newly created user.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${username}


Verify Login with Deleted Redfish User
    [Documentation]  Verify Login with Deleted Redfish User
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role id of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).

    Redfish.Login

    Redfish Create User  ${username}  ${password}  ${role_id}  ${enabled}

    Redfish.Login

    # Delete newly created user.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${username}

    # Attempt to login with deleted user account.
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  ${username}  ${password}

Verify Create User Without Enabling
    [Documentation]  Verify Create User Without Enabling
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role id of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).

    Redfish.Login

    Redfish Create User  ${username}  ${password}  ${role_id}  ${enabled}

    Redfish.Logout

    # Login with created user.
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  ${username}  ${password}

    Redfish.Login

    # Delete newly created user.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${username}

