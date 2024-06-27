*** Settings ***
Documentation       Suite to test local user management.

Library             OperatingSystem
Library             String
Library             Collections
Resource            ../../lib/resource.robot
Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/certificate_utils.robot
Resource            ../../lib/dmtf_redfishtool_utils.robot

Suite Setup         Suite Setup Execution

Test Tags           redfishtool_local_user


*** Variables ***
${root_cmd_args} =
...    SEPARATOR=
...    redfishtool raw -r ${OPENBMC_HOST}:${HTTPS_PORT} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always


*** Test Cases ***
Verify Redfishtool Create Users
    [Documentation]    Create user via Redfishtool and verify.
    [Tags]    verify_redfishtool_create_users

    Redfishtool Create User    "UserT100"    "TestPwd123"    "ReadOnly"    true
    Redfishtool Verify User    "UserT100"    "ReadOnly"
    [Teardown]    Redfishtool Delete User    "UserT100"

Verify Redfishtool Modify Users
    [Documentation]    Modify user via Redfishtool and verify.
    [Tags]    verify_redfishtool_modify_users

    Redfishtool Create User    "UserT100"    "TestPwd123"    "ReadOnly"    true
    Redfishtool Update User Role    "UserT100"    "Administrator"
    Redfishtool Verify User    "UserT100"    "Administrator"
    [Teardown]    Redfishtool Delete User    "UserT100"

Verify Redfishtool Delete Users
    [Documentation]    Delete user via Redfishtool and verify.
    [Tags]    verify_redfishtool_delete_users

    Redfishtool Create User    "UserT100"    "TestPwd123"    "ReadOnly"    true
    Redfishtool Delete User    "UserT100"
    ${status}=    Redfishtool Verify User Name Exists    "UserT100"
    Should Be True    ${status} == False

Verify Redfishtool Login With Deleted Redfish Users
    [Documentation]    Verify login with deleted user via Redfishtool.
    [Tags]    verify_redfishtool_login_with_deleted_redfish_users

    Redfishtool Create User    "UserT100"    "TestPwd123"    "ReadOnly"    true
    Redfishtool Delete User    "UserT100"
    Redfishtool Access Resource    /redfish/v1/AccountService/Accounts    "UserT100"    "TestPwd123"
    ...    ${HTTP_UNAUTHORIZED}

Verify Redfishtool Error Upon Creating Same Users With Different Privileges
    [Documentation]    Verify error upon creating same users with different privileges.
    [Tags]    verify_redfishtool_error_upon_creating_same_users_with_different_privileges

    Redfishtool Create User    "UserT100"    "TestPwd123"    "ReadOnly"    true
    Redfishtool Create User    "UserT100"    "TestPwd123"    "Administrator"    true
    ...    expected_error=${HTTP_BAD_REQUEST}
    [Teardown]    Redfishtool Delete User    "UserT100"

Verify Redfishtool Admin User Privilege
    [Documentation]    Verify privilege of admin user.
    [Tags]    verify_redfishtool_admin_user_privilege

    Redfishtool Create User    "UserT100"    "TestPwd123"    "Administrator"    true

    # Verify if a user can be added by admin
    Redfishtool Create User    "UserT101"    "TestPwd123"    "ReadOnly"    true    "UserT100"    "TestPwd123"
    [Teardown]    Run Keywords    Redfishtool Delete User    "UserT100"    AND
    ...    Redfishtool Delete User    "UserT101"

Verify Redfishtool ReadOnly User Privilege
    [Documentation]    Verify Redfishtool ReadOnly user privilege works.
    [Tags]    verify_redfishtool_readonly_user_privilege

    Redfishtool Create User    "UserT100"    "TestPwd123"    "ReadOnly"    true
    Redfishtool Access Resource    /redfish/v1/Systems/    "UserT100"    "TestPwd123"

    Redfishtool Create User
    ...    "UserT101"    "TestPwd123"    "Operator"    true    "UserT100"    "TestPwd123"    ${HTTP_FORBIDDEN}
    [Teardown]    Redfishtool Delete User    "UserT100"

Verify Redfishtool Operator User Privilege
    [Documentation]    Verify that an operator user is able to perform operator privilege
    ...    task(e.g. create user, delete user).
    [Tags]    verify_redfishtool_operator_user_privilege

    Redfishtool Create User    "UserT100"    "TestPwd123"    "ReadOnly"    true
    Redfishtool Access Resource    /redfish/v1/Systems/    "UserT100"    "TestPwd123"

    Redfishtool Create User
    ...    "UserT101"    "TestPwd123"    "Operator"    true    "UserT100"    "TestPwd123"    ${HTTP_FORBIDDEN}
    [Teardown]    Redfishtool Delete User    "UserT100"

Verify Error While Creating User With Invalid Role
    [Documentation]    Verify error while creating a user with invalid role using Redfishtool.
    [Tags]    verify_error_while_creating_user_with_invalid_role

    Redfishtool Create User
    ...    "UserT100"
    ...    "TestPwd123"
    ...    "wrongroleid"
    ...    true
    ...    expected_error=${HTTP_BAD_REQUEST}
    [Teardown]    Redfishtool Delete User    "UserT100"    ${HTTP_NOT_FOUND}

Verify Minimum Password Length For Redfish User Using Redfishtool
    [Documentation]    Verify minimum password length of eight characters for new and existing user.
    [Tags]    verify_minimum_password_length_for_redfish_user_using_redfishtool

    Redfishtool Create User    "UserT100"    "TestPwd"    "ReadOnly"    true    expected_error=${HTTP_BAD_REQUEST}
    Redfishtool Create User    "UserT100"    "TestPwd1"    "ReadOnly"    true
    [Teardown]    Redfishtool Delete User    "UserT100"

Verify Create User Without Enabling
    [Documentation]    Create a user without enabling it and verify that it does not have access.
    [Tags]    verify_create_user_without_enabling

    Redfishtool Create User    "UserT100"    "TestPwd123"    "ReadOnly"    false
    Redfishtool Access Resource    /redfish/v1/AccountService/Accounts    "UserT100"    "TestPwd123"
    ...    ${HTTP_UNAUTHORIZED}
    [Teardown]    Redfishtool Delete User    "UserT100"

Verify Error While Running Redfishtool With Incorrect Password
    [Documentation]    Verify error while running redfishtool with incorrect Password.
    [Tags]    verify_error_while_running_redfishtool_with_incorrect_password

    Redfishtool Create User    "UserT100"    "TestPwd123"    "Administrator"    true
    Redfishtool Access Resource    /redfish/v1/Systems/    "UserT100"    "TestPwd234"    ${HTTP_UNAUTHORIZED}
    [Teardown]    Redfishtool Delete User    "UserT100"


*** Keywords ***
Redfishtool Access Resource
    [Documentation]    Access resource.
    [Arguments]    ${uri}    ${login_user}    ${login_pasword}    ${expected_error}=200

    # Description of argument(s):
    # uri    URI for resource access.
    # login_user    The login user name used other than default root user.
    # login_pasword    The login password.
    # expected_error Expected error optionally provided in testcase (e.g. 401 /
    #    authentication error, etc. )

    ${user_cmd_args}=    Set Variable
    ...    redfishtool raw -r ${OPENBMC_HOST} -u ${login_user} -p ${login_pasword} -S Always
    Redfishtool Get    ${uri}    ${user_cmd_args}    ${expected_error}

Redfishtool Create User
    [Documentation]    Create new user.
    [Arguments]    ${user_name}    ${password}    ${roleId}    ${enable}    ${login_user}=""    ${login_pasword}=""
    ...    ${expected_error}=200

    # Description of argument(s):
    # user_name    The user name (e.g. "test", "robert", etc.).
    # password    The user password (e.g. "0penBmc", "0penBmc1", etc.).
    # roleId    The role of user (e.g. "Administrator", "Operator", etc.).
    # enable    Enabled attribute of (e.g. true or false).
    # expected_error Expected error optionally provided in testcase (e.g. 401 /
    #    authentication error, etc. )

    ${user_cmd_args}=    Set Variable
    ...    redfishtool raw -r ${OPENBMC_HOST} -u ${login_user} -p ${login_pasword} -S Always
    ${data}=    Set Variable
    ...    '{"UserName":${user_name},"Password":${password},"RoleId":${roleId},"Enabled":${enable}}'
    IF    ${login_user} == ""
        Redfishtool Post    ${data}    /redfish/v1/AccountService/Accounts    ${root_cmd_args}    ${expected_error}
    ELSE
        Redfishtool Post    ${data}    /redfish/v1/AccountService/Accounts    ${user_cmd_args}    ${expected_error}
    END

Redfishtool Update User Role
    [Documentation]    Update user role.
    [Arguments]    ${user_name}    ${newRole}    ${login_user}=""    ${login_pasword}=""
    ...    ${expected_error}=200

    # Description of argument(s):
    # user_name    The user name (e.g. "test", "robert", etc.).
    # newRole    The new role of user (e.g. "Administrator", "Operator", etc.).
    # login_user    The login user name used other than default root user.
    # login_pasword    The login password.
    # expected_error Expected error optionally provided in testcase (e.g. 401 /
    #    authentication error, etc. )

    ${user_cmd_args}=    Set Variable
    ...    redfishtool raw -r ${OPENBMC_HOST} -u ${login_user} -p ${login_pasword} -S Always
    IF    ${login_user} == ""
        Redfishtool Patch
        ...    '{"RoleId":${newRole}}'
        ...    /redfish/v1/AccountService/Accounts/${user_name}
        ...    ${root_cmd_args}
        ...    ${expected_error}
    ELSE
        Redfishtool Patch
        ...    '{"RoleId":${newRole}}'
        ...    /redfish/v1/AccountService/Accounts/${user_name}
        ...    ${user_cmd_args}
        ...    ${expected_error}
    END

Redfishtool Delete User
    [Documentation]    Delete a user.
    [Arguments]    ${user_name}    ${expected_error}=200

    # Description of argument(s):
    # user_name    The user name (e.g. "test", "robert", etc.).
    # expected_error    Expected error optionally provided in testcase (e.g. 401 /
    #    authentication error, etc. ).

    Redfishtool Delete    /redfish/v1/AccountService/Accounts/${user_name}
    ...    ${root_cmd_args}    ${expected_error}

Redfishtool Verify User
    [Documentation]    Verify role of the user.
    [Arguments]    ${user_name}    ${role}

    # Description of argument(s):
    # user_name    The user name (e.g. "test", "robert", etc.).
    # role    The new role of user (e.g. "Administrator", "Operator", etc.).

    ${user_account}=    Redfishtool Get    /redfish/v1/AccountService/Accounts/${user_name}
    ${json_obj}=    Evaluate    json.loads('''${user_account}''')    json
    Should Be equal    "${json_obj["RoleId"]}"    ${role}

Redfishtool Verify User Name Exists
    [Documentation]    Verify user name exists.
    [Arguments]    ${user_name}

    # Description of argument(s):
    # user_name    The user name (e.g. "test", "robert", etc.).

    ${status}=    Run Keyword And Return Status    redfishtool Get
    ...    /redfish/v1/AccountService/Accounts/${user_name}

    RETURN    ${status}

Suite Setup Execution
    [Documentation]    Do suite setup execution.

    ${tool_exist}=    Run    which redfishtool
    Should Not Be Empty    ${tool_exist}
