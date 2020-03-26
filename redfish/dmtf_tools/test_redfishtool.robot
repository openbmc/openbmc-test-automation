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

${cmd_prefix}          redfishtool raw
${root_cmd_args}       -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always
${HTTTP_ERROR}         Error
${min_number_roles}    ${4}
${min_number_users}    ${1}

*** Test Cases ***

Verify Redfishtool Login with Deleted Redfish Users
    ${user}=  Redfishtool Verify User Name Exists  "UserT100"
    Run Keyword If  ${user} == False  Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    Redfishtool Delete User  "UserT100"
    ${error}=  Redfishtool Access Resource  "UserT100"  "TestPwd123"  /redfish/v1/AccountService/Accounts
    Should Be True  ${error} == True

Verify Redfishtool Error Upon Creating Same Users With Different Privileges
    ${user}=  Redfishtool Verify User Name Exists  "UserT100"
    Run Keyword If  ${user} == False  Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    ${error}=  Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    Should Be True  ${error} == True

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
    [Arguments]  ${user_name}  ${Password}  ${uri}

    ${user_cmd_args}=  Set Variable  -r ${OPENBMC_HOST} -u ${user_name} -p ${Password} -S Always
    ${cmd_output}=  Redfishtool Get  ${uri}  ${user_cmd_args}
    ${error}=  Redfishtool Check HTTP Error  ${cmd_output}
    Run Keyword If  ${error} == True  Redfishtool Handle Error  ${cmd_output}  ${HTTP_UNAUTHORIZED}
    [return]  ${error}

Redfishtool Handle Error
    [Documentation]  Handle error.
    [Arguments]  ${cmd_output}  ${error_expected}

    ${contains}=  Evaluate   "${error_expected}" in """${cmd_output}"""
    Should Be True  ${contains}
    ...  msg=${cmd_output}

Redfishtool Create User
    [Documentation]  Create new user.
    [Arguments]  ${user_name}  ${Password}  ${roleID}  ${Enabled}  ${log_user}=""  ${log_pasword}=""

    # Description of argument(s):
    # user_name  User name
    # Password   Password of user.
    # roleID     Role of user.
    # Enabled    Enabled attribute of user.

    ${user_cmd_args}=  Set Variable  -r ${OPENBMC_HOST} -u ${log_user} -p ${log_pasword} -S Always
    ${Data}=   Set Variable   '{"UserName":${user_name},"Password":${Password},"RoleId":${roleId},"Enabled":${Enabled}}'
    ${cmd_output}=  Run Keyword If  ${log_user} == ""
    ...   Redfishtool Post  ${Data}  /redfish/v1/AccountService/Accounts
    ...   ELSE
    ...   Redfishtool Post  ${Data}  /redfish/v1/AccountService/Accounts  ${user_cmd_args}
    ${error}=  Redfishtool Check HTTP Error  ${cmd_output}
    Run Keyword If  ${error} == True  Redfishtool Handle Error  ${cmd_output}  ${HTTP_BAD_REQUEST}
    [return]  ${error}

Redfishtool Update User Role
    [Documentation]  Update an existing user.
    [Arguments]  ${user_name}  ${newRole}  ${log_user}=""  ${log_pasword}=""

    # Description of argument(s):
    # user_name  user name of user
    # newRole    new role of user
    # log_user    login user
    # log_pasword login password

    ${user_cmd_args}=  Set Variable  -r ${OPENBMC_HOST} -u ${log_user} -p ${log_pasword} -S Always
    ${Data}=   Set Variable   '{"RoleId":${newRole}}'
    ${cmd_output}=  Run Keyword If  ${log_user} == "" 
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
    # user_name  user name of user

    ${cmd_output}=  Redfishtool Delete  /redfish/v1/AccountService/Accounts/${user_name}
    #Redfishtool Verify User Name Exists  ${user_name}
    ${error}=  Redfishtool Check HTTP Error  ${cmd_output}
    Should Be True  ${error} == False
    ...  msg=${cmd_output}

Redfishtool Verify User
    [Documentation]  Verify role of the user.
    [Arguments]  ${user_name}  ${role}

    # Description of argument(s):
    # user_name  user name of user
    # role  role of user

    ${user_account}=  Redfishtool Get  /redfish/v1/AccountService/Accounts/${user_name}
    ${json_obj}=   Evaluate  json.loads('''${user_account}''')  json
    Should Be equal  "${json_obj["RoleId"]}"  ${role}

Redfishtool Verify User Name Exists
    [Documentation]  Verify user name exists.
    [Arguments]  ${user_name}

    # Description of argument(s):
    # user_name  user name of user

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

    ${cmd_output}=  Run  ${cmd_prefix} GET ${uri} ${cmd_args}
    [Return]  ${cmd_output}

Redfishtool Post
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for POST operation.

    ${cmd_output}=  Run  ${cmd_prefix} POST ${uri} --data=${payload} ${cmd_args}
    [Return]  ${cmd_output}

Redfishtool Patch
    [Documentation]  Execute DMTF redfishtool for  Patch operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for POST operation.

    ${cmd_output}=  Run  ${cmd_prefix} PATCH ${uri} --data=${payload} ${cmd_args}
    [Return]  ${cmd_output}

Redfishtool Delete
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for DELETE operation.

    ${cmd_output}=  Run  ${cmd_prefix} DELETE ${uri} ${cmd_args}
    [Return]  ${cmd_output}

Redfishtool Check HTTP Error
    [Documentation]
    [Arguments]  ${response}

    ${contains}=  Evaluate   "${HTTTP_ERROR}" in """${response}"""
    ${server_error}=  Run Keyword If  ${contains}  Evaluate   "500" in """${response}"""
    ...  ELSE
    ...  Run Keyword  Set Variable  False 
    Should Be True  ${server_error} == False
    ...  msg=${response} 
    [return]  ${contains}

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

    ${user}=  Redfishtool Verify User Name Exists  "readonly_user"
    Run Keyword If  ${user} == True  Redfishtool Delete User  "readonly_user"
