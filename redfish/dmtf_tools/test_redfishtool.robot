*** Settings ***
Documentation    Verify Redfish tool functionality.

# The following tests are performed:
#
# create user
# modify user
# delete user
#
# Test Parameters:
# OPENBMC_HOST          The BMC host name or IP address.
# OPENBMC_USERNAME      The username to login to the BMC.
# OPENBMC_PASSWORD      Password for OPENBMC_USERNAME.
#
# We use DMTF Redfishtool for writing openbmc automation test cases.
# DMTF redfishtool is a commandline tool that implements the client
# side of the Redfish RESTful API for Data Center Hardware Management.

*** Settings ***

Library   OperatingSystem
Library   String
Library   Collections

Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_resource.robot
Resource          ../../lib/openbmc_ffdc.robot

Suite Setup       Suite Setup Execution
Test Teardown     Test Teardown Execution

*** Variables ***

${root_cmd_args}       redfishtool raw -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always
${HTTP_ERROR}          Error
${min_number_roles}    ${4}
${min_number_users}    ${1}

*** Test Cases ***

Verify Redfishtool Login with Deleted Redfish Users
    Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true  expected_error=400
    Redfishtool Delete User  "UserT100"
    Redfishtool Access Resource  /redfish/v1/AccountService/Accounts  "UserT100"  "TestPwd123"  ${HTTP_UNAUTHORIZED}

Verify Redfishtool Error Upon Creating Same Users With Different Privileges
    #${user}=  Redfishtool Verify User Name Exists  "UserT100"
    Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    Redfishtool Create User  "UserT100"  "TestPwd123"  "Administrator"  true  expected_error=400
    #Should Be True  ${error} == True

Verify Redfishtool Admin User Privilege
    Redfishtool Create User  "admin_user"  "TestPwd123"  "Administrator"  true
    Redfishtool Create User  "operator_user"  "TestPwd123"  "Operator"  true

    # Change role ID of operator user with admin user.
    Redfishtool Update User Role  "operator_user"  "Administrator"  "admin_user"  "TestPwd123"

    # Verify modified user.
    Redfishtool Verify User  "operator_user"  "Administrator"

    Redfishtool Delete User  "admin_user"
    Redfishtool Delete User  "operator_user"

Verify Redfishtool ReadOnly User Privilege
    [Documentation]  Verify Redfishtool ReadOnly user privilege works.
    [Tags]  Verify_Redfishtool_ReadOnly_User_Privilege

    Redfishtool Create User  "readonly_user"  "TestPwd123"  "ReadOnly"  true
    ${error}=  Redfishtool Access Resource  "readonly_user"  "TestPwd123"  /redfish/v1/Systems/
    Should Be True  ${error} == False

    Redfishtool Delete User  "readonly_user"

Verify Redfishtool Role List
    [Documentation]  Verify the list of roles.

    ${usr_roles}=   Redfishtool Get  /redfish/v1/AccountService/Roles
    ${resp}=  Run Keyword And Return Status  Evaluate  json.loads('''${usr_roles}''')  json
    Should Be True  ${resp}
    ${json_object}=  Evaluate  json.loads('''${usr_roles}''')  json
    Should Be True  ${json_object["Members@odata.count"]} >= ${min_number_roles}
    ...  msg=There should be at least ${min_number_roles} users.

Verify Redfishtool User List
    [Documentation]  Verify the list of users.

    ${usr_accounts}=   Redfishtool Get  /redfish/v1/AccountService/Accounts
    ${resp}=  Run Keyword And Return Status  Evaluate  json.loads('''${usr_accounts}''')  json
    Should Be True  ${resp}
    ${json_object}=  Evaluate  json.loads('''${usr_accounts}''')  json
    Should Be True  ${json_object["Members@odata.count"]} >= ${min_number_users}
    ...  msg=There should be at least ${min_number_users} users.

*** Keywords ***

Redfishtool Access Resource
    [Documentation]  Access resource.
    [Arguments]  ${uri}   ${login_user}  ${login_pasword}  ${expected_error}=""

    ${user_cmd_args}=  Set Variable  redfishtool raw -r ${OPENBMC_HOST} -u ${login_user} -p ${login_pasword} -S Always
    ${cmd_output}=  Redfishtool Get  ${uri}  ${user_cmd_args}  ${expected_error}

Check HTTP error
    [Documentation]  Check if there is an HTTP error.
    [Arguments]  ${cmd_output}  ${error_expected}

    # Description of argument(s):
    # cmd_output      Output of an HTTP operation.
    # error_expected  Expected error.

    ${error}=  Evaluate  "${HTTP_ERROR}" in """${cmd_output}"""
    ${error_expected}=  Run Keyword If  ${error}
    ...  Evaluate  "${error_expected}" in """${cmd_output}"""
    ...  ELSE
    ...  Set Variable  False
    Run Keyword If  ${error} == True  Should Be True  ${error_expected} == True

Redfishtool Create User
    [Documentation]  Create new user.
    [Arguments]  ${user_name}  ${password}  ${roleID}  ${Enabled}  ${login_user}=""  ${login_pasword}=""  ${expected_error}=""

    # Description of argument(s):
    # user_name  User name.
    # Password   password of user.
    # roleID     Role of user.
    # Enabled    Enabled attribute of user.

    ${user_cmd_args}=  Set Variable  redfishtool raw -r ${OPENBMC_HOST} -u ${login_user} -p ${login_pasword} -S Always
    ${Data}=   Set Variable   '{"UserName":${user_name},"Password":${password},"RoleId":${roleId},"Enabled":${Enabled}}'
    ${cmd_output}=  Run Keyword If  ${login_user} == ""
    ...   Redfishtool Post  ${Data}  /redfish/v1/AccountService/Accounts  ${root_cmd_args}  ${expected_error}
    ...   ELSE
    ...   Redfishtool Post  ${Data}  /redfish/v1/AccountService/Accounts  ${user_cmd_args}  ${expected_error}

Redfishtool Update User Role
    [Documentation]  Update user role.
    [Arguments]  ${user_name}  ${newRole}  ${login_user}=""  ${login_pasword}=""  ${expected_error}=""

    # Description of argument(s):
    # user_name     user name of user.
    # newRole       new role of user.
    # login_user    login user.
    # login_pasword login password.

    ${user_cmd_args}=  Set Variable  redfishtool raw -r ${OPENBMC_HOST} -u ${login_user} -p ${login_pasword} -S Always
    ${Data}=   Set Variable   '{"RoleId":${newRole}}'
    ${cmd_output}=  Run Keyword If  ${login_user} == ""
    ...   Redfishtool Patch  ${Data}  /redfish/v1/AccountService/Accounts/${user_name}  ${root_cmd_args}  ${expected_error}
    ...   ELSE
    ...   Redfishtool Patch  ${Data}  /redfish/v1/AccountService/Accounts/${user_name}  ${user_cmd_args}  ${expected_error}

Redfishtool Delete User
    [Documentation]  Delete an user.
    [Arguments]  ${user_name}  ${expected_error}=""

    # Description of argument(s):
    # user_name  user name of user.
    # expected_error  Expected error.

    ${cmd_output}=  Redfishtool Delete  /redfish/v1/AccountService/Accounts/${user_name}  ${root_cmd_args}  ${expected_error}

Redfishtool Verify User
    [Documentation]  Verify role of the user.
    [Arguments]  ${user_name}  ${role}

    # Description of argument(s):
    # user_name  user name of user.
    # role  role of user.

    ${user_account}=  Redfishtool Get  /redfish/v1/AccountService/Accounts/${user_name}
    ${json_obj}=   Evaluate  json.loads('''${user_account}''')  json
    Should Be equal  "${json_obj["RoleId"]}"  ${role}

Redfishtool Verify User Name Exists
    [Documentation]  Verify user name exists.
    [Arguments]  ${user_name}

    # Description of argument(s):
    # user_name  user name of user.

    ${status}=  Run Keyword And Return Status  redfishtool Get  /redfish/v1/AccountService/Accounts/${user_name}
    [return]  ${status}

Redfishtool Get
    [Documentation]  Execute DMTF redfishtool for  GET operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=""

    # Description of argument(s):
    # uri  URI for GET operation.
    # cmd_args  Commandline arguments.
    # expected_error  Expected error.

    ${cmd_output}=  Run  ${cmd_args} GET ${uri}
    Check HTTP error  ${cmd_output}  ${expected_error}
    [Return]  ${cmd_output}

Redfishtool Post
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=""

    # Description of argument(s):
    # uri  URI for POST operation.
    # cmd_args  Commandline arguments.
    # expected_error  Expected error.

    ${cmd_output}=  Run  ${cmd_args} POST ${uri} --data=${payload}
    Check HTTP error  ${cmd_output}  ${expected_error}
    [Return]  ${cmd_output}

Redfishtool Patch
    [Documentation]  Execute DMTF redfishtool for  Patch operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=""

    # Description of argument(s):
    # uri  URI for POST operation.
    # cmd_args  Commandline arguments.
    # expected_error  Expected error.

    ${cmd_output}=  Run  ${cmd_args} PATCH ${uri} --data=${payload}
    Check HTTP error  ${cmd_output}  ${expected_error}
    [Return]  ${cmd_output}

Redfishtool Delete
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=""

    # Description of argument(s):
    # uri  URI for DELETE operation.
    # cmd_args  Commandline arguments.
    # expected_error  Expected error.

    ${cmd_output}=  Run  ${cmd_args} DELETE ${uri}
    Check HTTP error  ${cmd_output}  ${expected_error}
    [Return]  ${cmd_output}

Suite Setup Execution
    [Documentation]  Do suite setup execution.
    ${tool_exist}=  Run  which redfishtool
    Should Not Be Empty  ${tool_exist}

Test Teardown Execution
    ${user}=  Redfishtool Verify User Name Exists  "UserT100"
    Run Keyword If  ${user} == True  Redfishtool Delete User  "UserT100"

