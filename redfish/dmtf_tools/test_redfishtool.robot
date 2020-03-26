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

Suite Setup       Suite Setup Execution
Suite Teardown    Suite Teardown Execution

*** Variables ***

${cmd_prefix}          redfishtool raw
${root_cmd_args}       -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always
${HTTTP_ERROR}         Error
${HTTP_UNAUTHORIZED}   401

*** Test Cases ***

Verify Redfishtool Login with Deleted Redfish Users
    ${user}=  Redfishtool Verify User Name Exists  "UserT100"
    Run Keyword If  ${user} == False  Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    Redfishtool Delete User  "UserT100"
    ${error}=  Redfishtool Access Account  "UserT100"  "TestPwd123"
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
    Redfishtool Update User  "operator_user"  "TestPwd123"  "Administrator"  true  "admin_user"  "TestPwd123"

    # Verify modified user.
    Redfish Verify User  "operator_user"  "Administrator"

    Redfishtool Delete User  "admin_user"
    Redfishtool Delete User  "operator_user"

*** Keywords ***

Redfishtool Access Account
    [Arguments]  ${user_name}  ${Password}

    ${user_cmd_args}=  Set Variable  -r ${OPENBMC_HOST} -u ${user_name} -p ${Password} -S Always
    ${cmd_output}=  Redfishtool Get  /redfish/v1/AccountService/Accounts  ${user_cmd_args}
    ${error}=  Redfishtool Check HTTP Error  ${cmd_output}
    Run Keyword If  ${error} == True  Redfishtool Handle Error  ${cmd_output}  ${HTTP_UNAUTHORIZED} 
    [return]  ${error}

Redfishtool Handle Error
    [Arguments]  ${cmd_output}  ${error_expected}

    ${contains}=  Evaluate   "${error_expected}" in """${cmd_output}"""
    Should Be True  ${contains} 
    ...  msg=${cmd_output}
 
Redfishtool Create User
    [Documentation]  Create new user.
    [Arguments]  ${user_name}  ${Password}  ${roleID}  ${Enabled}  ${log_user}=""  ${log_pasword}=""

    # Description of argument(s):
    # user_name  user name of user
    # Password   password of user
    # roleID     role of user
    # Enabled    enabled attribute of user

    ${user_cmd_args}=  Set Variable  -r ${OPENBMC_HOST} -u ${log_user} -p ${log_pasword} -S Always
    ${Data}=   Set Variable   '{"UserName":${user_name},"Password":${Password},"RoleId":${roleId},"Enabled":${Enabled}}'
    ${cmd_output}=  Run Keyword If  ${log_user} == "" 
    ...   Redfishtool Post  ${Data}  /redfish/v1/AccountService/Accounts
    ...   ELSE
    ...   Redfishtool Post  ${Data}  /redfish/v1/AccountService/Accounts  ${user_cmd_args} 
    ${error}=  Redfishtool Check HTTP Error  ${cmd_output}
    Run Keyword If  ${error} == True  Redfishtool Handle Error  ${cmd_output}  400 
    [return]  ${error}

Redfishtool Update User
    [Documentation]  Update an existing user.
    [Arguments]  ${user_name}  ${Password}  ${newRole}  ${Enabled}  ${log_user}=""  ${log_pasword}=""

    # Description of argument(s):
    # user_name  user name of user
    # Password   password of user
    # newRole    new role of user
    # Enabled    enabled attribute of user

    ${user_cmd_args}=  Set Variable  -r ${OPENBMC_HOST} -u ${log_user} -p ${log_pasword} -S Always
    ${Data}=   Set Variable   '{"UserName":${user_name},"Password":${Password},"RoleId":${newRole},"Enabled":${Enabled}}'
    #${cmd_output}=  Redfishtool Patch  ${Data}  /redfish/v1/AccountService/Accounts/${user_name}
    ${cmd_output}=  Run Keyword If  ${log_user} == "" 
    ...   Redfishtool Patch  ${Data}  /redfish/v1/AccountService/Accounts
    ...   ELSE
    ...   Redfishtool Patch  ${Data}  /redfish/v1/AccountService/Accounts  ${user_cmd_args}
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
    #${error}=  Redfishtool Check HTTP Error  ${cmd_output}
    #Should Be True  ${error} == False
    #...  msg=${cmd_output}
    [Return]  ${cmd_output}

Redfishtool Post
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for POST operation.

    ${cmd_output}=  Run  ${cmd_prefix} POST ${uri} --data=${payload} ${cmd_args}
    #${error}=  Redfishtool Check HTTP Error  ${cmd_output}
    #Should Be True  ${error} == False
    #...  msg=${cmd_output}
    [Return]  ${cmd_output}

Redfishtool Patch
    [Documentation]  Execute DMTF redfishtool for  Patch operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for POST operation.

    ${cmd_output}=  Run  ${cmd_prefix} PATCH ${uri} --data=${payload} ${cmd_args}
    #${error}=  Redfishtool Check HTTP Error  ${cmd_output}
    #Should Be True  ${error} == False
    #...  msg=${cmd_output}
    [Return]  ${cmd_output}

Redfishtool Delete
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for DELETE operation.

    ${cmd_output}=  Run  ${cmd_prefix} DELETE ${uri} ${cmd_args}
    #${error}=  Redfishtool Check HTTP Error  ${cmd_output}
    #Should Be True  ${error} == False
    #...  msg=${cmd_output}
    [Return]  ${cmd_output}

Redfishtool Check HTTP Error 
    [Documentation]
    [Arguments]  ${response}

    ${contains}=  Evaluate   "${HTTTP_ERROR}" in """${response}"""
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

Suite Teardown Execution
    ${user}=  Redfishtool Verify User Name Exists  "UserT100"
    Run Keyword If  ${user} == True  Redfishtool Delete User  "UserT100"

    ${user}=  Redfishtool Verify User Name Exists  "admin_user"
    Run Keyword If  ${user} == True  Redfishtool Delete User  "admin_user"

    ${user}=  Redfishtool Verify User Name Exists  "operator_user"
    Run Keyword If  ${user} == True  Redfishtool Delete User  "operator_user"
