*** Settings ***
Documentation    Verify Redfish tool functionality.

# The following tests are performed:
#
# create user
#
# directory PATH in $PATH.
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
Library           String
Library    Collections

*** Variables ***

${cmd_prefix}      redfishtool raw
${cmd_args}        -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always
${DefaultRoleId}   "ReadOnly"
${newRoldId}       "Operator"

*** Test Cases ***

Verify Redfishtool Create Users
    [Documentation]  Verify Redfishtool usermanagement Commands work.
    [Tags]  Verify_Redfishtool_usermanagement_Commands

    ${user}=  Redfishtool verify User Name Exists  "UserT100"
    Run Keyword If  ${user} == True   Redfishtool Delete User  "UserT100"
    Redfishtool Create User  "UserT100"  "TestPwd123"  "User"  "True"
    Redfishtool verify User Exists  "UserT100"  "User"
    Redfishtool Delete User  "UserT100"    

*** Keywords ***

Redfishtool Create User
    [Documentation]  Verify user creation. 
    [Arguments]  ${user_name}  ${password}  ${roleID}  ${Enabled}

    ${Data}=   Set Variable   '{"UserName":${user_name},"Password":${Password},"RoleId":${roleId},"Enabled":true}'
    Redfishtool Post  ${Data}  /redfish/v1/AccountService/Accounts

Redfishtool Update User
    [Documentation]  Verify user updation.
    [Arguments]  ${user_name}  ${newRole}

    ${Data}=   Set Variable   '{"UserName":${user_name},"Password":${password},"RoleId":${newRole},"Enabled":true}'
    Redfishtool Patch  ${Data}  /redfish/v1/AccountService/Accounts/${user_name}

Redfishtool Delete User
    [Documentation]  Verify user deletion.
    [Arguments]  ${user_name}

    Redfishtool Delete  /redfish/v1/AccountService/Accounts/${user_name}
  
Redfishtool verify User Role
    [Documentation]  Verify role of the user.
    [Arguments]  ${user_name}  ${role}
   
    ${user_account}=  Redfishtool Get  /redfish/v1/AccountService/Accounts/${user_name}
    ${json_obj}=   Evaluate  json.loads('''${user_account}''')  json
    ${retn_val}=  Redfishtool Compare Roles If Equal  "${json_obj["RoleId"]}"   ${role}
    Should Be True  ${retn_val}
 
Redfishtool verify User Exists
    [Documentation]  Verify user exists with the name and role
    [Arguments]  ${user_name}  ${role}
    
    ${verify}=  Redfishtool Verify User Name Exists  ${user_name}
    Should Be True  ${verify} 
    ${user_account}=  Redfishtool Get  /redfish/v1/AccountService/Accounts/${user_name}
    ${json_obj}=   Evaluate  json.loads('''${user_account}''')  json
    ${retn_val}=   Redfishtool Compare Roles If Equal  "${json_obj["RoleId"]}"   ${role}
    Should Be True  ${retn_val}
    
Redfishtool Compare Roles If Equal
    [Documentation]  Verify user exists with the name and role
    [Arguments]   ${role1}   ${role2}
    ${result}=  Run Keyword If   ${role1} == ${role1}  Set Variable  True
    [return]  ${result}   
    
Redfishtool verify User Name Exists
    [Documentation]  Verify user name exists
    [Arguments]  ${user_name}
 
    ${usr_accounts}=  Redfishtool Get  /redfish/v1/AccountService/Accounts
    ${user_name}=  Remove string  ${user_name}  "
    ${user_account_url}=   Catenate   /redfish/v1/AccountService/Accounts/${user_name}
    ${contains}=  Evaluate   "${user_account_url}" in """${usr_accounts}"""
    [return]  ${contains}

Redfishtool Get
    [Documentation]  Execute DMTF redfishtool for  GET operation.
    [Arguments]  ${uri}

    # Description of argument(s):
    # uri  URI for GET operation.

    ${cmd_output}=  Run  ${cmd_prefix} GET ${uri} ${cmd_args}
    [Return]  ${cmd_output}
 
Redfishtool Post
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${Payload}  ${uri}

    # Description of argument(s):
    # uri  URI for POST operation.

    ${cmd_output}=  Run  ${cmd_prefix} POST ${uri} --data=${Payload} ${cmd_args}
    #[Return]  ${cmd_output}

Redfishtool Patch
    [Documentation]  Execute DMTF redfishtool for  Patch operation.
    [Arguments]  ${Payload}  ${uri}

    # Description of argument(s):
    # uri  URI for POST operation.

    ${cmd_output}=  Run  ${cmd_prefix} PATCH ${uri} --data=${Payload} ${cmd_args}
    #[Return]  ${cmd_output}

Redfishtool Delete
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${uri}

    # Description of argument(s):
    # uri  URI for DELETE operation.

    ${cmd_output}=  Run  ${cmd_prefix} DELETE ${uri} ${cmd_args}
    #[Return]  ${cmd_output}

Redfishtool verify User List
    [Documentation]  Verify the list of roles.
 
    ${usr_accounts}=   Run   redfishtool -r wsbmc007.aus.stglabs.ibm.com -u root -p 0penBmc007 -S Always raw GET /redfish/v1/AccountService/Accounts
    ${resp}=  Run Keyword And Return Status  Evaluate  json.loads('''${usr_accounts}''')  json
    Should Be True  ${resp}
    ${json_object}=  Evaluate  json.loads('''${usr_accounts}''')  json  
    ${list_usrs}=  Set Variable   ${json_object["Members"]} 
    ${num}=   Get Length  ${list_usrs} 
    #Log To Console  Total length is ${num}
    Should Be True  ${num} >= 1 
    ...  msg=There should be at least 1 users. 

Redfishtool verify Roles List
    [Documentation]  Verify the list of users.

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
