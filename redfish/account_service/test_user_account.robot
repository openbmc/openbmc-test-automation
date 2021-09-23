*** Settings ***
Documentation    Test Redfish user account.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot

Library          SSHLibrary

Test Setup       Redfish.Login
Test Teardown    Test Teardown Execution

*** Variables ***

${account_lockout_duration}   ${30}
${account_lockout_threshold}  ${3}

** Test Cases **

Verify AccountService Available
    [Documentation]  Verify Redfish account service is available.
    [Tags]  Verify_AccountService_Available

    ${resp} =  Redfish_utils.Get Attribute  /redfish/v1/AccountService  ServiceEnabled
    Should Be Equal As Strings  ${resp}  ${True}

Verify Redfish User Persistence After Reboot
    [Documentation]  Verify Redfish user persistence after reboot.
    [Tags]  Verify_Redfish_User_Persistence_After_Reboot

    # Create Redfish users.
    Redfish Create User  admin_user     TestPwd123  Administrator   ${True}
    Redfish Create User  operator_user  TestPwd123  Operator        ${True}
    Redfish Create User  readonly_user  TestPwd123  ReadOnly        ${True}

    # Reboot BMC.
    Redfish OBMC Reboot (off)  stack_mode=normal

    # Verify users after reboot.
    Redfish Verify User  admin_user     TestPwd123  Administrator   ${True}
    Redfish Verify User  operator_user  TestPwd123  Operator        ${True}
    Redfish Verify User  readonly_user  TestPwd123  ReadOnly        ${True}

    # Delete created users.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/admin_user
    Redfish.Delete  /redfish/v1/AccountService/Accounts/operator_user
    Redfish.Delete  /redfish/v1/AccountService/Accounts/readonly_user

Redfish Create and Verify Users
    [Documentation]  Create Redfish users with various roles.
    [Tags]  Redfish_Create_and_Verify_Users
    [Template]  Redfish Create And Verify User

    #username      password    role_id         enabled
    admin_user     TestPwd123  Administrator   ${True}
    operator_user  TestPwd123  Operator        ${True}
    readonly_user  TestPwd123  ReadOnly        ${True}

Verify Redfish User with Wrong Password
    [Documentation]  Verify Redfish User with Wrong Password.
    [Tags]  Verify_Redfish_User_with_Wrong_Password
    [Template]  Verify Redfish User with Wrong Password

    #username      password    role_id         enabled  wrong_password
    admin_user     TestPwd123  Administrator   ${True}  alskjhfwurh
    operator_user  TestPwd123  Operator        ${True}  12j8a8uakjhdaosiruf024
    readonly_user  TestPwd123  ReadOnly        ${True}  12

Verify Login with Deleted Redfish Users
    [Documentation]  Verify login with deleted Redfish Users.
    [Tags]  Verify_Login_with_Deleted_Redfish_Users
    [Template]  Verify Login with Deleted Redfish User

    #username     password    role_id         enabled
    admin_user     TestPwd123  Administrator   ${True}
    operator_user  TestPwd123  Operator        ${True}
    readonly_user  TestPwd123  ReadOnly        ${True}

Verify User Creation Without Enabling It
    [Documentation]  Verify User Creation Without Enabling it.
    [Tags]  Verify_User_Creation_Without_Enabling_It
    [Template]  Verify Create User Without Enabling

    #username      password    role_id         enabled
    admin_user     TestPwd123  Administrator   ${False}
    operator_user  TestPwd123  Operator        ${False}
    readonly_user  TestPwd123  ReadOnly        ${False}

Verify User Creation With Invalid Role Id
    [Documentation]  Verify user creation with invalid role ID.
    [Tags]  Verify_User_Creation_With_Invalid_Role_Id

    # Make sure the user account in question does not already exist.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/test_user
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    # Create specified user.
    ${payload}=  Create Dictionary
    ...  UserName=test_user  Password=TestPwd123  RoleId=wrongroleid  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{payload}
    ...  valid_status_codes=[${HTTP_BAD_REQUEST}]

Verify Error Upon Creating Same Users With Different Privileges
    [Documentation]  Verify error upon creating same users with different privileges.
    [Tags]  Verify_Error_Upon_Creating_Same_Users_With_Different_Privileges

    Redfish Create User  test_user  TestPwd123  Administrator  ${True}

    # Create specified user.
    ${payload}=  Create Dictionary
    ...  UserName=test_user  Password=TestPwd123  RoleId=Operator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{payload}
    ...  valid_status_codes=[${HTTP_BAD_REQUEST}]

    Redfish.Delete  /redfish/v1/AccountService/Accounts/test_user

Verify Modifying User Attributes
    [Documentation]  Verify modifying user attributes.
    [Tags]  Verify_Modifying_User_Attributes

    # Create Redfish users.
    Redfish Create User  admin_user     TestPwd123  Administrator   ${True}
    Redfish Create User  operator_user  TestPwd123  Operator        ${True}
    Redfish Create User  readonly_user  TestPwd123  ReadOnly        ${True}

    # Make sure the new user account does not already exist.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/newadmin_user
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    # Update admin_user username using Redfish.
    ${payload}=  Create Dictionary  UserName=newadmin_user
    Redfish.Patch  /redfish/v1/AccountService/Accounts/admin_user  body=&{payload}

    # Update operator_user password using Redfish.
    ${payload}=  Create Dictionary  Password=NewTestPwd123
    Redfish.Patch  /redfish/v1/AccountService/Accounts/operator_user  body=&{payload}

    # Update readonly_user role using Redfish.
    ${payload}=  Create Dictionary  RoleId=Operator
    Redfish.Patch  /redfish/v1/AccountService/Accounts/readonly_user  body=&{payload}

    # Verify users after updating
    Redfish Verify User  newadmin_user  TestPwd123     Administrator   ${True}
    Redfish Verify User  operator_user  NewTestPwd123  Operator        ${True}
    Redfish Verify User  readonly_user  TestPwd123     Operator        ${True}

    # Delete created users.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/newadmin_user
    Redfish.Delete  /redfish/v1/AccountService/Accounts/operator_user
    Redfish.Delete  /redfish/v1/AccountService/Accounts/readonly_user

Verify User Account Locked
    [Documentation]  Verify user account locked upon trying with invalid password.
    [Tags]  Verify_User_Account_Locked

    Redfish Create User  admin_user  TestPwd123  Administrator   ${True}

    ${payload}=  Create Dictionary  AccountLockoutThreshold=${account_lockout_threshold}
    ...  AccountLockoutDuration=${account_lockout_duration}
    Redfish.Patch  ${REDFISH_ACCOUNTS_SERVICE_URI}  body=${payload}

    Redfish.Logout

    # Make ${account_lockout_threshold} failed login attempts.
    Repeat Keyword  ${account_lockout_threshold} times
    ...  Run Keyword And Expect Error  InvalidCredentialsError*  Redfish.Login  admin_user  abc123

    # Verify that legitimate login fails due to lockout.
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  admin_user  TestPwd123

    # Wait for lockout duration to expire and then verify that login works.
    Sleep  ${account_lockout_duration}s
    Redfish.Login  admin_user  TestPwd123

    Redfish.Logout

    Redfish.Login

    Redfish.Delete  /redfish/v1/AccountService/Accounts/admin_user

Verify Admin User Privilege
    [Documentation]  Verify admin user privilege.
    [Tags]  Verify_Admin_User_Privilege

    Redfish Create User  admin_user  TestPwd123  Administrator  ${True}
    Redfish Create User  operator_user  TestPwd123  Operator  ${True}
    Redfish Create User  readonly_user  TestPwd123  ReadOnly  ${True}

    Redfish.Logout

    # Change role ID of operator user with admin user.
    # Login with admin user.
    Redfish.Login  admin_user  TestPwd123

    # Modify Role ID of Operator user.
    Redfish.Patch  /redfish/v1/AccountService/Accounts/operator_user  body={'RoleId': 'Administrator'}

    # Verify modified user.
    Redfish Verify User  operator_user  TestPwd123  Administrator  ${True}

    Redfish.Logout
    Redfish.Login  admin_user  TestPwd123

    # Change password of 'user' user with admin user.
    Redfish.Patch  /redfish/v1/AccountService/Accounts/readonly_user  body={'Password': 'NewTestPwd123'}

    # Verify modified user.
    Redfish Verify User  readonly_user  NewTestPwd123  ReadOnly  ${True}

    Redfish.Delete  /redfish/v1/AccountService/Accounts/admin_user
    Redfish.Delete  /redfish/v1/AccountService/Accounts/operator_user
    Redfish.Delete  /redfish/v1/AccountService/Accounts/readonly_user

Verify Operator User Privilege
    [Documentation]  Verify operator user privilege.
    [Tags]  Verify_operator_User_Privilege

    Redfish Create User  admin_user  TestPwd123  Administrator  ${True}
    Redfish Create User  operator_user  TestPwd123  Operator  ${True}

    Redfish.Logout
    # Login with operator user.
    Redfish.Login  operator_user  TestPwd123

    # Verify BMC reset.
    Run Keyword And Expect Error  ValueError*  Redfish BMC Reset Operation

    # Attempt to change password of admin user with operator user.
    Redfish.Patch  /redfish/v1/AccountService/Accounts/admin_user  body={'Password': 'NewTestPwd123'}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

    Redfish.Logout

    Redfish.Login

    Redfish.Delete  /redfish/v1/AccountService/Accounts/admin_user
    Redfish.Delete  /redfish/v1/AccountService/Accounts/operator_user


Verify ReadOnly User Privilege
    [Documentation]  Verify ReadOnly user privilege.
    [Tags]  Verify_ReadOnly_User_Privilege

    Redfish Create User  readonly_user  TestPwd123  ReadOnly  ${True}
    Redfish.Logout

    # Login with read_only user.
    Redfish.Login  readonly_user  TestPwd123

    # Read system level data.
    ${system_model}=  Redfish_Utils.Get Attribute
    ...  ${SYSTEM_BASE_URI}  Model

    Redfish.Logout
    Redfish.Login
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}readonly_user


Verify Minimum Password Length For Redfish User
    [Documentation]  Verify minimum password length for new and existing user.
    [Tags]  Verify_Minimum_Password_Length_For_Redfish_User

    ${user_name}=  Set Variable  testUser

    # Make sure the user account in question does not already exist.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${user_name}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    # Try to create a user with invalid length password.
    ${payload}=  Create Dictionary
    ...  UserName=${user_name}  Password=UserPwd  RoleId=Administrator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{payload}
    ...  valid_status_codes=[${HTTP_BAD_REQUEST}]

    # Create specified user with valid length password.
    Set To Dictionary  ${payload}  Password  UserPwd1
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    # Try to change to an invalid password.
    Redfish.Patch  /redfish/v1/AccountService/Accounts/${user_name}  body={'Password': 'UserPwd'}
    ...  valid_status_codes=[${HTTP_BAD_REQUEST}]

    # Change to a valid password.
    Redfish.Patch  /redfish/v1/AccountService/Accounts/${user_name}  body={'Password': 'UserPwd1'}

    # Verify login.
    Redfish.Logout
    Redfish.Login  ${user_name}  UserPwd1
    Redfish.Logout
    Redfish.Login
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${user_name}


Verify Standard User Roles Defined By Redfish
    [Documentation]  Verify standard user roles defined by Redfish.
    [Tags]  Verify_Standard_User_Roles_Defined_By_Redfish

    ${member_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/AccountService/Roles

    @{roles}=  Create List
    ...  /redfish/v1/AccountService/Roles/Administrator
    ...  /redfish/v1/AccountService/Roles/Operator
    ...  /redfish/v1/AccountService/Roles/ReadOnly

    List Should Contain Sub List  ${member_list}  ${roles}

    # The standard roles are:

    # | Role name | Assigned privileges |
    # | Administrator | Login, ConfigureManager, ConfigureUsers, ConfigureComponents, ConfigureSelf |
    # | Operator | Login, ConfigureComponents, ConfigureSelf |
    # | ReadOnly | Login, ConfigureSelf |

    @{admin}=  Create List  Login  ConfigureManager  ConfigureUsers  ConfigureComponents  ConfigureSelf
    @{operator}=  Create List  Login  ConfigureComponents  ConfigureSelf
    @{readOnly}=  Create List  Login  ConfigureSelf

    ${roles_dict}=  create dictionary  admin_privileges=${admin}  operator_privileges=${operator}
    ...  readOnly_privileges=${readOnly}

    ${resp}=  redfish.Get  /redfish/v1/AccountService/Roles/Administrator
    List Should Contain Sub List  ${resp.dict['AssignedPrivileges']}  ${roles_dict['admin_privileges']}

    ${resp}=  redfish.Get  /redfish/v1/AccountService/Roles/Operator
    List Should Contain Sub List  ${resp.dict['AssignedPrivileges']}  ${roles_dict['operator_privileges']}

    ${resp}=  redfish.Get  /redfish/v1/AccountService/Roles/ReadOnly
    List Should Contain Sub List  ${resp.dict['AssignedPrivileges']}  ${roles_dict['readOnly_privileges']}


Verify Error While Deleting Root User
    [Documentation]  Verify error while deleting root user.
    [Tags]  Verify_Error_While_Deleting_Root_User

    Redfish.Delete  /redfish/v1/AccountService/Accounts/root  valid_status_codes=[${HTTP_FORBIDDEN}]


Verify SSH Login Access With Admin User
    [Documentation]  Verify that admin user does not have SSH login access.
    [Tags]  Verify_SSH_Login_Access_With_Admin_User

    # Create an admin User.
    Redfish Create User  new_admin  TestPwd1  Administrator  ${True}

    # Attempt SSH login with admin user.
    SSHLibrary.Open Connection  ${OPENBMC_HOST}
    ${status}=  Run Keyword And Return Status  SSHLibrary.Login  new_admin  TestPwd1
    Should Be Equal  ${status}  ${False}


*** Keywords ***

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    Run Keyword And Ignore Error  Redfish.Logout
    FFDC On Test Case Fail


Redfish Create User
    [Documentation]  Redfish create user.
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}  ${login_check}=${True}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role ID of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).
    # login_check         Checks user login for created user.
    #                     (e.g. ${True}, ${False}).

    # Make sure the user account in question does not already exist.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${userName}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    # Create specified user.
    ${payload}=  Create Dictionary
    ...  UserName=${username}  Password=${password}  RoleId=${role_id}  Enabled=${enabled}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    # Resetting faillock count as a workaround for issue
    # openbmc/phosphor-user-manager#4
    ${cmd}=  Catenate  /usr/sbin/faillock --user USER --reset
    Bmc Execute Command  ${cmd}

    # Verify login with created user.
    ${status}=  Run Keyword If  '${login_check}' == '${True}'
    ...  Verify Redfish User Login  ${username}  ${password}
    Run Keyword If  '${login_check}' == '${True}'  Should Be Equal  ${status}  ${enabled}

    # Validate Role ID of created user.
    ${role_config}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/${username}  RoleId
    Should Be Equal  ${role_id}  ${role_config}


Redfish Verify User
    [Documentation]  Redfish user verification.
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role ID of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).

    ${status}=  Verify Redfish User Login  ${username}  ${password}
    # Doing a check of the returned status.
    Should Be Equal  ${status}  ${enabled}

    # Validate Role Id of user.
    ${role_config}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/${username}  RoleId
    Should Be Equal  ${role_id}  ${role_config}


Verify Redfish User Login
    [Documentation]  Verify Redfish login with given user id.
    [Teardown]  Run Keywords  Run Keyword And Ignore Error  Redfish.Logout  AND  Redfish.Login
    [Arguments]   ${username}  ${password}

    # Description of argument(s):
    # username            Login username.
    # password            Login password.

    # Logout from current Redfish session.
    # We don't really care if the current session is flushed out since we are going to login
    # with new credential in next.
    Run Keyword And Ignore Error  Redfish.Logout

    ${status}=  Run Keyword And Return Status  Redfish.Login  ${username}  ${password}
    [Return]  ${status}


Redfish Create And Verify User
    [Documentation]  Redfish create and verify user.
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role ID of the user to be created
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
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${username}

Verify Redfish User with Wrong Password
    [Documentation]  Verify Redfish User with Wrong Password.
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}  ${wrong_password}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role ID of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).
    # wrong_password      Any invalid password.

    Redfish Create User  ${username}  ${password}  ${role_id}  ${enabled}

    Redfish.Logout

    # Attempt to login with created user with invalid password.
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  ${username}  ${wrong_password}

    Redfish.Login

    # Delete newly created user.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${username}


Verify Login with Deleted Redfish User
    [Documentation]  Verify Login with Deleted Redfish User.
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role ID of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).

    Redfish Create User  ${username}  ${password}  ${role_id}  ${enabled}

    # Delete newly created user.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${userName}

    Redfish.Logout

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
    # role_id             The role ID of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).

    Redfish Create User  ${username}  ${password}  ${role_id}  ${enabled}  ${False}

    Redfish.Logout

    # Login with created user.
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  ${username}  ${password}

    Redfish.Login

    # Delete newly created user.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${username}

