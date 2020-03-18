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

Library                 String
Library                 OperatingSystem

Suite Setup             Suite Setup Execution

*** Variables ***

${cmd_prefix}    redfishtool raw
${cmd_args}      -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always
${user_name}     "UserTest"
${Password}      "TestPwd123"
${RoleId}        "ReadOnly"


*** Test Cases ***

Verify Redfishtool usermanagement Commands
    [Documentation]  Verify Redfishtool usermanagement Commands work.
    [Tags]  Verify_Redfishtool_usermanagement_Commands

    Verify Create User  ${user_name}  ${password}
    Verify Delete User  ${user_name}

*** Keywords ***

Verify Create User
    [Documentation]  Verify user creation.
    [Arguments]  ${user_name}  ${password}

    ${Data}=   Set Variable   '{"UserName":${user_name},"Password":${Password},"RoleId":${RoleId},"Enabled":true}'
    Redfishtool Post  ${Data}  /redfish/v1/AccountService/Accounts


Redfishtool Post
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${Payload}  ${uri}

    # Description of argument(s):
    # Payload  payload data for POST
    # uri      URI for POST operation.

    ${cmd_output}=  Run  ${cmd_prefix} POST ${uri} --data=${Payload} ${cmd_args}

Verify Delete User
    [Documentation]  Verify user deletion.
    [Arguments]  ${uri} 

    # Description of argument(s):
    # uri  URI for DELETE operation.
   
    Redfishtool Delete  /redfish/v1/AccountService/Accounts/${user_name} 

Redfishtool Delete
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${uri}

    # Description of argument(s):
    # uri  URI for DELETE operation.

    ${cmd_output}=  Run  ${cmd_prefix} DELETE ${uri} ${cmd_args}


Suite Setup Execution
    [Documentation]  Do suite setup execution.
    ${tool_exist}=  Run  which redfishtool
    Should Not Be Empty  ${tool_exist}
