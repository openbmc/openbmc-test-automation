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
    [Documentation]  Create Redfish users with various roles.
    [Tags]  Redfish_Create_and_Verify_Users
    [Template]  Redfish Create And Verify User

    #username      password    role_id         enabled
    admin_user     TestPwd123  Administrator   ${True}
    operator_user  TestPwd123  Operator        ${True}
    user_user      TestPwd123  User            ${True}
    callback_user  TestPwd123  Callback        ${True}

Verify Redfish User with Wrong Password
    [Documentation]  Verify Redfish User with Wrong Password.
    [Tags]  Verify_Redfish_User_with_Wrong_Password
    [Template]  Verify Redfish User with Wrong Password

    #username      password    role_id         enabled  wrong_password
    admin_user     TestPwd123  Administrator   ${True}  alskjhfwurh
    operator_user  TestPwd123  Operator        ${True}  12j8a8uakjhdaosiruf024
    user_user      TestPwd123  User            ${True}  12
    callback_user  TestPwd123  Callback        ${True}  !#@D#RF#@!D

Verify Login with Deleted Redfish Users
    [Documentation]  Verify login with deleted Redfish Users.
    [Tags]  Verify_Login_with_Deleted_Redfish_Users
    [Template]  Verify Login with Deleted Redfish User

    #username     password    role_id         enabled
    admin_user     TestPwd123  Administrator   ${True}
    operator_user  TestPwd123  Operator        ${True}
    user_user      TestPwd123  User            ${True}
    callback_user  TestPwd123  Callback        ${True}

Verify User Creation Without Enabling It
    [Documentation]  Verify User Creation Without Enabling it.
    [Tags]  Verify_User_Creation_Without_Enabling_It
    [Template]  Verify Create User Without Enabling

    #username      password    role_id         enabled
    admin_user     TestPwd123  Administrator   ${False}
    operator_user  TestPwd123  Operator        ${False}
    user_user      TestPwd123  User            ${False}
    callback_user  TestPwd123  Callback        ${False}

Verify Redfish User Persistence After Reboot
    [Documentation]  Verify Redfish user persistence after reboot.
    [Tags]  Verify_Redfish_User_Persistence_After_Reboot

    # Create Redfish users.
    Redfish Create User  admin_user     TestPwd123  Administrator   ${True}
    Redfish Create User  operator_user  TestPwd123  Operator        ${True}
    Redfish Create User  user_user      TestPwd123  User            ${True}
    Redfish Create User  callback_user  TestPwd123  Callback        ${True}

    # Reboot BMC.
    Redfish OBMC Reboot (off)  stack_mode=normal

    # Verify users after reboot.
    Redfish Verify User  admin_user     TestPwd123  Administrator   ${True}
    Redfish Verify User  operator_user  TestPwd123  Operator        ${True}
    Redfish Verify User  user_user      TestPwd123  User            ${True}
    Redfish Verify User  callback_user  TestPwd123  Callback        ${True}

    # Delete created users.
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}admin_user
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}operator_user
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}user_user
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}callback_user

Verify User Creation With Invalid Role Id
    [Documentation]  Verify user creation with invalid role id.
    [Tags]  Verify_User_Creation_With_Invalid_Role_Id

    # Make sure the user account in question does not already exist.
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}test_user
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    # Create specified user.
    ${payload}=  Create Dictionary
    ...  UserName=test_user  Password=TestPwd123  RoleId=wrongroleid  Enabled=${True}
    Redfish.Post  ${REDFISH_ACCOUNTS_URI}  body=&{payload}
    ...  valid_status_codes=[${HTTP_BAD_REQUEST}]

Verify Error Upon Creating Same Users With Different Privileges
    [Documentation]  Verify error upon creating same users with different privileges.
    [Tags]  Verify_Error_Upon_Creating_Same_Users_With_Different_Privileges

    Redfish Create User  test_user  TestPwd123  Administrator  ${True}

    # Create specified user.
    ${payload}=  Create Dictionary
    ...  UserName=test_user  Password=TestPwd123  RoleId=Operator  Enabled=${True}
    Redfish.Post  ${REDFISH_ACCOUNTS_URI}  body=&{payload}
    ...  valid_status_codes=[${HTTP_BAD_REQUEST}]


Verify Modifying User Attributes
    [Documentation]  Verify modifying user attributes.
    [Tags]  Verify_Modifying_User_Attributes

    # Create Redfish users.
    Redfish Create User  admin_user     TestPwd123  Administrator   ${True}
    Redfish Create User  operator_user  TestPwd123  Operator        ${True}
    Redfish Create User  user_user      TestPwd123  User            ${True}
    Redfish Create User  callback_user  TestPwd123  Callback        ${True}

    Redfish.Login

    # Make sure the new user account does not already exist.
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}newadmin_user
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    # Update admin_user username using Redfish.
    ${payload}=  Create Dictionary  UserName=newadmin_user
    Redfish.Patch  ${REDFISH_ACCOUNTS_URI}admin_user  body=&{payload}

    # Update operator_user password using Redfish.
    ${payload}=  Create Dictionary  Password=NewTestPwd123
    Redfish.Patch  ${REDFISH_ACCOUNTS_URI}operator_user  body=&{payload}

    # Update user_user role using Redfish.
    ${payload}=  Create Dictionary  RoleId=Operator
    Redfish.Patch  ${REDFISH_ACCOUNTS_URI}user_user  body=&{payload}

    # Update callback_user to disable using Redfish.
    ${payload}=  Create Dictionary  Enabled=${False}
    Redfish.Patch  ${REDFISH_ACCOUNTS_URI}callback_user  body=&{payload}

    # Verify users after updating
    Redfish Verify User  newadmin_user  TestPwd123     Administrator   ${True}
    Redfish Verify User  operator_user  NewTestPwd123  Operator        ${True}
    Redfish Verify User  user_user      TestPwd123     Operator        ${True}
    Redfish Verify User  callback_user  TestPwd123     Callback        ${False}

    # Delete created users.
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}newadmin_user
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}operator_user
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}user_user
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}callback_user

Verify User Account Lock Upon Trying With Invalid Password
    [Documentation]  Verify user account lock upon trying with invalid password
    [Tags]  Verify_User_Account_Lock_Upon_Trying_With_Invalid_Password

    #Create a redfish user
    Redfish Create User  admin_user  TestPwd123  Administrator   ${True}

    #Set account lock threshold
    ${payload}=  Create Dictionary  AccountLockoutThreshold=${3}
    Redfish.Patch  ${REDFISH_ACCOUNTS_SERVICE_URI}  body=&{payload}

    #Validate account lock threshold
    ${acc_threshold}=  Redfish_Utils.Get Attribute
    ...  ${REDFISH_ACCOUNTS_SERVICE_URI}  AccountLockoutThreshold
    Should Be Equal  int(3)  int(${acc_threshold})

    #Set account lock duration
    ${payload}=  Create Dictionary  AccountLockoutDuration=${30}
    Redfish.Patch  ${REDFISH_ACCOUNTS_SERVICE_URI}  body=&{payload}

    #Validate account lock duration
    ${acc_threshold}=  Redfish_Utils.Get Attribute
    ...  ${REDFISH_ACCOUNTS_SERVICE_URI}  AccountLockoutDuration
    Should Be Equal  int(30)  int(${acc_threshold})

    #Try to login with created user 3 times with invalid passwords
    #Login with less than 8 character invalid password
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  admin_user  abc123

    #Login with more than 8 character invalid password
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  admin_user  verylongpasswordtest123456789

    #Login with blank password
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  admin_user

    #Login with valid password and it should not work
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  admin_user  TestPwd123

    #After timeout , validate it logs in
    Sleep  30s
    Redfish.Login  admin_user  TestPwd123


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Redfish.Logout

Redfish Create User
    [Documentation]  Redfish create user.
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role id of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).

    Redfish.Login

    # Make sure the user account in question does not already exist.
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${userName}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    # Create specified user.
    ${payload}=  Create Dictionary
    ...  UserName=${username}  Password=${password}  RoleId=${role_id}  Enabled=${enabled}
    Redfish.Post  ${REDFISH_ACCOUNTS_URI}  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    Redfish.Logout

    # Login with created user.
    Run Keyword If  ${enabled} == False
    ...    Run Keyword And Expect Error  InvalidCredentialsError*
    ...    Redfish.Login  ${username}  ${password}
    ...  ELSE
    ...    Redfish.Login  ${username}  ${password}

    Run Keyword If  ${enabled} == False
    ...  Redfish.Login

    # Validate Role Id of created user.
    ${role_config}=  Redfish_Utils.Get Attribute
    ...  ${REDFISH_ACCOUNTS_URI}${username}  RoleId
    Should Be Equal  ${role_id}  ${role_config}


Redfish Verify User
    [Documentation]  Redfish user verification.
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role id of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).

    # Trying to do a login with created user.
    ${status}=  Run Keyword And Return Status  Redfish.Login  ${username}  ${password}

    # Doing a check of the returned status.
    Should Be Equal  ${status}  ${enabled}

    # We do not need to login with created user (user could be in disabled status).
    Redfish.Login

    # Validate Role Id of user.
    ${role_config}=  Redfish_Utils.Get Attribute
    ...  ${REDFISH_ACCOUNTS_URI}${username}  RoleId
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

    Redfish Create User  ${username}  ${password}  ${role_id}  ${enabled}

    Redfish Verify User  ${username}  ${password}  ${role_id}  ${enabled}

    # Delete Specified User
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${username}

Verify Redfish User with Wrong Password
    [Documentation]  Verify Redfish User with Wrong Password.
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}  ${wrong_password}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role id of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).
    # wrong_password      Any invalid password.

    Redfish Create User  ${username}  ${password}  ${role_id}  ${enabled}

    # Attempt to login with created user with invalid password.
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  ${username}  ${wrong_password}

    Redfish.Login

    # Delete newly created user.
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${username}


Verify Login with Deleted Redfish User
    [Documentation]  Verify Login with Deleted Redfish User.
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role id of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).

    Redfish Create User  ${username}  ${password}  ${role_id}  ${enabled}
    ${status}=  Run Keyword And Return Status  Redfish.Login  ${username}  ${password}

    # Doing a check of the rerurned status
    Should Be Equal  ${status}  ${True}

    Redfish.Login

    # Delete newly created user.
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${userName}

    # Attempt to login with deleted user account.
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  ${username}  ${password}

    Redfish.Login

Verify Create User Without Enabling
    [Documentation]  Verify Create User Without Enabling.
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
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${username}
