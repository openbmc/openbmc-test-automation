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
${HTTTP_ERROR}         Error

*** Test Cases ***

Verify Redfishtool Create Users
    [Documentation]  Verify Redfishtool Create Users work.
    [Tags]  Verify_Redfishtool_Create_Users

    ${user_exists}=  Redfishtool Verify User Name Exists  "UserT100"
    Run Keyword If  ${user_exists} == True   Redfishtool Delete User  "UserT100"
    Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    Redfishtool Verify User  "UserT100"  "Operator"
    Redfishtool Delete User  "UserT100"

Verify Redfishtool Modify Users
    [Documentation]  Verify Redfishtool Modify Users work.
    [Tags]  Verify_Redfishtool_Modify_Users

    Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    Redfishtool Update User Role  "UserT100"  "Administrator"
    Redfishtool Verify User  "UserT100"  "Administrator"
    Redfishtool Delete User  "UserT100"

Verify Redfishtool Delete Users
    [Documentation]  Verify Redfishtool Delete Users work.
    [Tags]  Verify_Redfishtool_Delete_Users

    ${user_exists}=  Redfishtool Verify User Name Exists  "UserT100"
    Run Keyword If  ${user_exists} == False  Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    Redfishtool Delete User  "UserT100"
    ${status}=  Redfishtool Verify User Name Exists  "UserT100"
    Should Be True  ${status} == False

*** Keywords ***

Redfishtool Handle Error
    [Arguments]  ${cmd_output}  ${error_expected}

    ${contains}=  Evaluate   "${error_expected}" in """${cmd_output}"""
    Should Be True  ${contains}  msg=${cmd_output}

Redfishtool Create User
    [Documentation]  Create new user.
    [Arguments]  ${user_name}  ${password}  ${roleID}  ${Enabled}  ${login_user}=""  ${login_pasword}=""

    # Description of argument(s):
    # user_name  User name.
    # Password   password of user.
    # roleID     Role of user.
    # Enabled    Enabled attribute of user.

    ${user_cmd_args}=  Set Variable  -r ${OPENBMC_HOST} -u ${login_user} -p ${login_pasword} -S Always
    ${Data}=   Set Variable   '{"UserName":${user_name},"Password":${password},"RoleId":${roleId},"Enabled":${Enabled}}'
    ${cmd_output}=  Run Keyword If  ${login_user} == ""
    ...   Redfishtool Post  ${Data}  /redfish/v1/AccountService/Accounts
    ...   ELSE
    ...   Redfishtool Post  ${Data}  /redfish/v1/AccountService/Accounts  ${user_cmd_args}
    ${error}=  Redfishtool Check HTTP Error  ${cmd_output}
    Run Keyword If  ${error} == True  Redfishtool Handle Error  ${cmd_output}  ${HTTP_BAD_REQUEST}
    [return]  ${error}

Redfishtool Update User Role
    [Documentation]  Update user role.
    [Arguments]  ${user_name}  ${newRole}  ${login_user}=""  ${login_pasword}=""

    # Description of argument(s):
    # user_name   user name of user.
    # newRole     new role of user.
    # login_user    login user.
    # login_pasword login password.

    ${user_cmd_args}=  Set Variable  -r ${OPENBMC_HOST} -u ${login_user} -p ${login_pasword} -S Always
    ${Data}=   Set Variable   '{"RoleId":${newRole}}'
    ${cmd_output}=  Run Keyword If  ${login_user} == ""
    ...   Redfishtool Patch  ${Data}  /redfish/v1/AccountService/Accounts/${user_name}
    ...   ELSE
    ...   Redfishtool Patch  ${Data}  /redfish/v1/AccountService/Accounts/${user_name}  ${user_cmd_args}
    ${error}=  Redfishtool Check HTTP Error  ${cmd_output}
    Should Be True  ${error} == False
    ...  msg=${cmd_output}

Redfishtool Delete User
    [Documentation]  Delete an user.
    [Arguments]  ${user_name}

    # Description of argument(s):
    # user_name  user name of user.

    ${cmd_output}=  Redfishtool Delete  /redfish/v1/AccountService/Accounts/${user_name}
    ${error}=  Redfishtool Check HTTP Error  ${cmd_output}
    Run Keyword If  ${error} == True  Redfishtool Handle Error  ${cmd_output}  ${HTTP_NOT_FOUND}
    [return]  ${error}

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

    ${usr_accounts}=  Redfishtool Get  /redfish/v1/AccountService/Accounts
    ${user_name}=  Remove string  ${user_name}  "
    ${user_account_url}=   Catenate   /redfish/v1/AccountService/Accounts/${user_name}
    ${contains}=  Evaluate   "${user_account_url}" in """${usr_accounts}"""
    [return]  ${contains}

Redfishtool Get
    [Documentation]  Execute DMTF redfishtool for  GET operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for GET operation.

    ${cmd_output}=  Run  ${cmd_args} GET ${uri}
    [Return]  ${cmd_output}


Redfishtool Post
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for POST operation.

    ${cmd_output}=  Run  ${cmd_args} POST ${uri} --data=${payload}
    [Return]  ${cmd_output}

Redfishtool Patch
    [Documentation]  Execute DMTF redfishtool for  Patch operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for POST operation.

    ${cmd_output}=  Run  ${cmd_args} PATCH ${uri} --data=${payload}
    [Return]  ${cmd_output}

Redfishtool Delete
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for DELETE operation.

    ${cmd_output}=  Run  ${cmd_args} DELETE ${uri}
    [Return]  ${cmd_output}

Redfishtool Check HTTP Error
    [Documentation]  Check if there is an error in the HTTP response.
    [Arguments]  ${response}

    ${contains}=  Evaluate   "${HTTTP_ERROR}" in """${response}"""
    ${server_error}=  Run Keyword If  ${contains}  Evaluate   "500" in """${response}"""
    ...  ELSE
    ...  Run Keyword  Set Variable  False
    Should Be True  ${server_error} == False
    ...  msg=${response}
    [return]  ${contains}

Redfishtool verify Roles List
    [Documentation]  Verify the list of roles.

    ${resp}=  Run Keyword And Return Status  Evaluate  json.loads('''${usr_roles}''')  json
    Should Be True  ${resp}
    ${json_object}=  Evaluate  json.loads('''${usr_roles}''')  json
    ${list_roles}=  Set Variable   ${json_object["Members"]}
    ${num}=   Get Length  ${list_roles}
    Should Be True  ${num} > 5
    ...  msg=There should be at least ${min_number_users} users.

Suite Setup Execution
    [Documentation]  Do suite setup execution.
    ${tool_exist}=  Run  which redfishtool
    Should Not Be Empty  ${tool_exist}

Test Teardown Execution
    ${user}=  Redfishtool Verify User Name Exists  "UserT100"
    Run Keyword If  ${user} == True  Redfishtool Delete User  "UserT100"

    ${user}=  Redfishtool Verify User Name Exists  "admin_user"
    Run Keyword If  ${user} == True  Redfishtool Delete User  "admin_user"

    ${user}=  Redfishtool Verify User Name Exists  "operator_user"
    Run Keyword If  ${user} == True  Redfishtool Delete User  "operator_user"
