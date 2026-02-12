*** Settings ***


Documentation     Suite to test local user management.

Library           OperatingSystem
Library           String
Library           Collections

Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_resource.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/certificate_utils.robot
Resource          ../../lib/dmtf_redfishtool_utils.robot

Suite Setup       Suite Setup Execution

Test Tags        Redfishtool_Local_User

*** Variables ***

${root_cmd_args} =  SEPARATOR=
...  redfishtool raw -r ${OPENBMC_HOST}:${HTTPS_PORT} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always


*** Test Cases ***

Verify Redfishtool Create Users
    [Documentation]  Create user via Redfishtool and verify.
    [Tags]  Verify_Redfishtool_Create_Users
    [Teardown]  Redfishtool Delete User  "UserT100"

    Redfishtool Create User  "UserT100"  "TestPwd123"  "ReadOnly"  true
    Redfishtool Verify User  "UserT100"  "ReadOnly"


Verify Redfishtool Modify Users
    [Documentation]  Modify user via Redfishtool and verify.
    [Tags]  Verify_Redfishtool_Modify_Users
    [Teardown]  Redfishtool Delete User  "UserT100"

    Redfishtool Create User  "UserT100"  "TestPwd123"  "ReadOnly"  true
    Redfishtool Update User Role  "UserT100"  "Administrator"
    Redfishtool Verify User  "UserT100"  "Administrator"


Verify Redfishtool Delete Users
    [Documentation]  Delete user via Redfishtool and verify.
    [Tags]  Verify_Redfishtool_Delete_Users

    Redfishtool Create User  "UserT100"  "TestPwd123"  "ReadOnly"  true
    Redfishtool Delete User  "UserT100"
    ${status}=  Redfishtool Verify User Name Exists  "UserT100"
    Should Be True  ${status} == False


Verify Redfishtool Login With Deleted Redfish Users
    [Documentation]  Verify login with deleted user via Redfishtool.
    [Tags]  Verify_Redfishtool_Login_With_Deleted_Redfish_Users

    Redfishtool Create User  "UserT100"  "TestPwd123"  "ReadOnly"  true
    Redfishtool Delete User  "UserT100"
    Redfishtool Access Resource  /redfish/v1/AccountService/Accounts  "UserT100"  "TestPwd123"
    ...  ${HTTP_UNAUTHORIZED}


Verify Redfishtool Error Upon Creating Same Users With Different Privileges
    [Documentation]  Verify error upon creating same users with different privileges.
    [Tags]  Verify_Redfishtool_Error_Upon_Creating_Same_Users_With_Different_Privileges
    [Teardown]  Redfishtool Delete User  "UserT100"

    Redfishtool Create User  "UserT100"  "TestPwd123"  "ReadOnly"  true
    Redfishtool Create User  "UserT100"  "TestPwd123"  "Administrator"  true
    ...  expected_error=${HTTP_BAD_REQUEST}


Verify Redfishtool Admin User Privilege
    [Documentation]  Verify privilege of admin user.
    [Tags]  Verify_Redfishtool_Admin_User_Privilege
    [Teardown]  Run Keywords  Redfishtool Delete User  "UserT100"  AND
    ...  Redfishtool Delete User  "UserT101"

    Redfishtool Create User  "UserT100"  "TestPwd123"  "Administrator"  true

    # Verify if a user can be added by admin
    Redfishtool Create User  "UserT101"  "TestPwd123"  "ReadOnly"  true  "UserT100"  "TestPwd123"


Verify Redfishtool ReadOnly User Privilege
    [Documentation]  Verify Redfishtool ReadOnly user privilege works.
    [Tags]  Verify_Redfishtool_ReadOnly_User_Privilege
    [Teardown]  Redfishtool Delete User  "UserT100"

    Redfishtool Create User  "UserT100"  "TestPwd123"  "ReadOnly"  true
    Redfishtool Access Resource  /redfish/v1/Systems/  "UserT100"  "TestPwd123"

    Redfishtool Create User
    ...  "UserT101"  "TestPwd123"  "Operator"  true  "UserT100"  "TestPwd123"  ${HTTP_FORBIDDEN}


Verify Redfishtool Operator User Privilege
    [Documentation]  Verify that an operator user is able to perform operator privilege
    ...  task(e.g. create user, delete user).
    [Tags]  Verify_Redfishtool_Operator_User_Privilege
    [Teardown]  Redfishtool Delete User  "UserT100"

    Redfishtool Create User  "UserT100"  "TestPwd123"  "ReadOnly"  true
    Redfishtool Access Resource  /redfish/v1/Systems/  "UserT100"  "TestPwd123"

    Redfishtool Create User
    ...  "UserT101"  "TestPwd123"  "Operator"  true  "UserT100"  "TestPwd123"  ${HTTP_FORBIDDEN}


Verify Error While Creating User With Invalid Role
    [Documentation]  Verify error while creating a user with invalid role using Redfishtool.
    [Tags]  Verify_Error_While_Creating_User_With_Invalid_Role
    [Teardown]  Redfishtool Delete User  "UserT100"  ${HTTP_NOT_FOUND}

    Redfishtool Create User  "UserT100"  "TestPwd123"  "wrongroleid"  true  expected_error=${HTTP_BAD_REQUEST}


Verify Minimum Password Length For Redfish User Using Redfishtool
    [Documentation]  Verify minimum password length of eight characters for new and existing user.
    [Tags]  Verify_Minimum_Password_Length_For_Redfish_User_Using_Redfishtool
    [Teardown]  Redfishtool Delete User  "UserT100"

    Redfishtool Create User  "UserT100"  "TestPwd"  "ReadOnly"  true  expected_error=${HTTP_BAD_REQUEST}
    Redfishtool Create User  "UserT100"  "TestPwd1"  "ReadOnly"  true


Verify Create User Without Enabling
    [Documentation]  Create a user without enabling it and verify that it does not have access.
    [Tags]  Verify_Create_User_Without_Enabling
    [Teardown]  Redfishtool Delete User  "UserT100"

    Redfishtool Create User  "UserT100"  "TestPwd123"  "ReadOnly"  false
    Redfishtool Access Resource  /redfish/v1/AccountService/Accounts  "UserT100"  "TestPwd123"
    ...  ${HTTP_UNAUTHORIZED}


Verify Error While Running Redfishtool With Incorrect Password
    [Documentation]  Verify error while running redfishtool with incorrect Password.
    [Tags]  Verify_Error_While_Running_Redfishtool_With_Incorrect_Password
    [Teardown]  Redfishtool Delete User  "UserT100"

    Redfishtool Create User  "UserT100"  "TestPwd123"  "Administrator"  true
    Redfishtool Access Resource  /redfish/v1/Systems/  "UserT100"  "TestPwd234"  ${HTTP_UNAUTHORIZED}

*** Keywords ***


Redfishtool Access Resource
    [Documentation]  Access resource.
    [Arguments]  ${uri}   ${login_user}  ${login_pasword}  ${expected_error}=200

    # Description of argument(s):
    # uri            URI for resource access.
    # login_user     The login user name used other than default root user.
    # login_pasword  The login password.
    # expected_error Expected error optionally provided in testcase (e.g. 401 /
    #                authentication error, etc. )

    ${user_cmd_args}=  Set Variable
    ...  redfishtool raw -r ${OPENBMC_HOST}:${HTTPS_PORT} -u ${login_user} -p ${login_pasword} -S Always
    Redfishtool Get  ${uri}  ${user_cmd_args}  ${expected_error}


Redfishtool Create User
    [Documentation]  Create new user.
    [Arguments]  ${user_name}  ${password}  ${roleId}  ${enable}  ${login_user}=""  ${login_pasword}=""
    ...  ${expected_error}=200

    # Description of argument(s):
    # user_name      The user name (e.g. "test", "robert", etc.).
    # password       The user password (e.g. "0penBmc", "0penBmc1", etc.).
    # roleId         The role of user (e.g. "Administrator", "Operator", etc.).
    # enable         Enabled attribute of (e.g. true or false).
    # expected_error Expected error optionally provided in testcase (e.g. 401 /
    #                authentication error, etc. )

    ${user_cmd_args}=  Set Variable
    ...  redfishtool raw -r ${OPENBMC_HOST}:${HTTPS_PORT} -u ${login_user} -p ${login_pasword} -S Always
    ${data}=  Set Variable
    ...  '{"UserName":${user_name},"Password":${password},"RoleId":${roleId},"Enabled":${enable}}'
    IF  ${login_user} == ""
        Redfishtool Post  ${data}  /redfish/v1/AccountService/Accounts  ${root_cmd_args}  ${expected_error}
    ELSE
        Redfishtool Post  ${data}  /redfish/v1/AccountService/Accounts  ${user_cmd_args}  ${expected_error}
    END


Redfishtool Update User Role
    [Documentation]  Update user role.
    [Arguments]  ${user_name}  ${newRole}  ${login_user}=""  ${login_pasword}=""
    ...  ${expected_error}=200

    # Description of argument(s):
    # user_name      The user name (e.g. "test", "robert", etc.).
    # newRole        The new role of user (e.g. "Administrator", "Operator", etc.).
    # login_user     The login user name used other than default root user.
    # login_pasword  The login password.
    # expected_error Expected error optionally provided in testcase (e.g. 401 /
    #                authentication error, etc. )

    ${user_cmd_args}=  Set Variable
    ...  redfishtool raw -r ${OPENBMC_HOST}:${HTTPS_PORT} -u ${login_user} -p ${login_pasword} -S Always
    IF  ${login_user} == ""
        Redfishtool Patch  '{"RoleId":${newRole}}'
        ...  /redfish/v1/AccountService/Accounts/${user_name}  ${root_cmd_args}  ${expected_error}
    ELSE
        Redfishtool Patch  '{"RoleId":${newRole}}'
        ...  /redfish/v1/AccountService/Accounts/${user_name}  ${user_cmd_args}  ${expected_error}
    END


Redfishtool Delete User
    [Documentation]  Delete a user.
    [Arguments]  ${user_name}  ${expected_error}=200

    # Description of argument(s):
    # user_name       The user name (e.g. "test", "robert", etc.).
    # expected_error  Expected error optionally provided in testcase (e.g. 401 /
    #                 authentication error, etc. ).

    Redfishtool Delete  /redfish/v1/AccountService/Accounts/${user_name}
    ...  ${root_cmd_args}  ${expected_error}


Redfishtool Verify User
    [Documentation]  Verify role of the user.
    [Arguments]  ${user_name}  ${role}

    # Description of argument(s):
    # user_name  The user name (e.g. "test", "robert", etc.).
    # role       The new role of user (e.g. "Administrator", "Operator", etc.).

    ${user_account}=  Redfishtool Get  /redfish/v1/AccountService/Accounts/${user_name}
    ${json_obj}=   Evaluate  json.loads('''${user_account}''')  json
    Should Be Equal  "${json_obj["RoleId"]}"  ${role}


Redfishtool Verify User Name Exists
    [Documentation]  Verify user name exists.
    [Arguments]  ${user_name}

    # Description of argument(s):
    # user_name  The user name (e.g. "test", "robert", etc.).

    ${status}=  Run Keyword And Return Status  redfishtool Get
    ...  /redfish/v1/AccountService/Accounts/${user_name}

    RETURN  ${status}


Suite Setup Execution
    [Documentation]  Do suite setup execution.

    ${tool_exist}=  Run  which redfishtool
    Should Not Be Empty  ${tool_exist}
