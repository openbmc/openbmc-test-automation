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

*** Test Cases ***

Verify Redfishtool Create Users
    [Documentation]  Verify Redfishtool Create Users work.
    [Tags]  Verify_Redfishtool_Create_Users

    Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    Redfishtool Verify User  "UserT100"  "Operator"

Verify Redfishtool Modify Users
    [Documentation]  Verify Redfishtool Modify Users work.
    [Tags]  Verify_Redfishtool_Modify_Users

    Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    Redfishtool Update User Role  "UserT100"  "Administrator"
    Redfishtool Verify User  "UserT100"  "Administrator"

Verify Redfishtool Delete Users
    [Documentation]  Verify Redfishtool Delete Users work.
    [Tags]  Verify_Redfishtool_Delete_Users

    Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    Redfishtool Delete User  "UserT100"
    ${status}=  Redfishtool Verify User Name Exists  "UserT100"
    Should Be True  ${status} == False

*** Keywords ***

Check HTTP error
    [Documentation]  Check if there is an HTTP error.
    [Arguments]  ${cmd_output}  ${error_expected}

    # Description of argument(s):
    # cmd_output      Output of an HTTP operation.
    # error_expected  Expected error.

    ${error}=  Evaluate  "${HTTP_ERROR}" in """${cmd_output}"""
    ${contains}=  Run Keyword If  ${error}
    ...  Evaluate  "${error_expected}" in """${cmd_output}"""
    ...  ELSE
    ...  Set Variable  False
    Should Be True  ${contains} == False  msg=${cmd_output}

Redfishtool Create User
    [Documentation]  Create new user.
    [Arguments]  ${user_name}  ${password}  ${roleID}  ${Enabled}  ${login_user}=""  ${login_pasword}=""  ${expected_error}=""

    # Description of argument(s):
    # user_name  User name.
    # Password   password of user.
    # roleID     Role of user.
    # Enabled    Enabled attribute of user.

    ${user_cmd_args}=  Set Variable  -r ${OPENBMC_HOST} -u ${login_user} -p ${login_pasword} -S Always
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

    ${user_cmd_args}=  Set Variable  -r ${OPENBMC_HOST} -u ${login_user} -p ${login_pasword} -S Always
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
