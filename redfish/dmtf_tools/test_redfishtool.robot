*** Settings ***
Documentation    Verify Redfish tool functionality.

# The following tests are performed:
#
# sensors list
# health check
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

${cmd_prefix}           redfishtool raw
${root_cmd_args}        -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always
${HTTTP_ERROR}          Error
${min_number_sensors}   ${15}
${Health_status}        OK

*** Test Cases ***

Verify Redfishtool Sensor Commands
    [Documentation]  Verify sensor commands work.
    [Tags]  Verify_Redfishtool_Sensor_Commands

    #Verify Sensors List
    ${sensor_status}=    Redfishtool Get  /redfish/v1/Chassis/chassis/Sensors
    ${resp}=  Run Keyword And Return Status  Evaluate  json.loads('''${sensor_status}''')  json
    Should Be True  ${resp}
    ...  msg=There is some issue with execution of redfishtool.
    ${json_object}=  Evaluate  json.loads('''${sensor_status}''')  json
    Should Be True  ${json_object["Members@odata.count"]} > ${min_number_sensors}
    ...  msg=There should be at least ${min_number_sensors} sensors.

Verify Redfishtool Health Check Commands
    [Documentation]  Verify health check command works.
    [Tags]  Verify_Redfishtool_Health_Check_Commands

    ${chassis_data}=    Redfishtool Get  /redfish/v1/Chassis/chassis/
    ${error}=  Redfishtool Check HTTP Error  ${chassis_data}
    Should Be True  ${error} == False
    ...  msg=${chassis_data}
    ${json_object}=  Evaluate  json.loads('''${chassis_data}''')  json
    ${status}=   Set Variable   ${json_object["Status"]}
    Should Be Equal  ${Health_status}  ${status["Health"]}
    ...  msg=Health status should be ${Health_status}.

*** Keywords ***

Redfishtool Get
    [Documentation]  Execute DMTF redfishtool for  GET operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for GET operation.

    ${cmd_output}=  Run  ${cmd_prefix} GET ${uri} ${cmd_args}
    [Return]  ${cmd_output}

Redfishtool Check HTTP Error
    [Documentation]
    [Arguments]  ${response}

    # Description of argument(s):
    # response  response of HTTP operation

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
