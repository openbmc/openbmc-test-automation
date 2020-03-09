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
# We use DMTF redfishtool for writing openbmc automation test cases.
# DMTF redfishtool is a commandline tool that implements the client
# side of the Redfish RESTful API for Data Center Hardware Management.

Library                 String
Library                 OperatingSystem

Suite Setup             Suite Setup Execution

*** Variables ***

${root_cmd_args}        redfishtool raw -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always
${HTTTP_ERROR}          Error
${min_number_sensors}   ${15}

*** Test Cases ***

Verify Redfishtool Sensor Commands
    [Documentation]  Verify redfishtool's sensor commands.
    [Tags]  Verify_Redfishtool_Sensor_Commands

    ${sensor_status}=  Redfishtool Get  /redfish/v1/Chassis/chassis/Sensors
    ${json_object}=  Evaluate  json.loads('''${sensor_status}''')  json
    Should Be True  ${json_object["Members@odata.count"]} > ${min_number_sensors}
    ...  msg=There should be at least ${min_number_sensors} sensors.

Verify Redfishtool Health Check Commands
    [Documentation]  Verify redfishtool's health check command.
    [Tags]  Verify_Redfishtool_Health_Check_Commands

    ${chassis_data}=  Redfishtool Get  /redfish/v1/Chassis/chassis/
    ${json_object}=  Evaluate  json.loads('''${chassis_data}''')  json
    ${status}=  Set Variable  ${json_object["Status"]}
    Should Be Equal  OK  ${status["Health"]}
    ...  msg=Health status should be OK.

*** Keywords ***

Redfishtool Get
    [Documentation]  Return the output of redfishtool for GET operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for GET operation.
    # cmd_args redfishtool command arguments.

    ${cmd_output}=  Run  ${cmd_args} GET ${uri}
    [Return]  ${cmd_output}

Suite Setup Execution
    [Documentation]  Do suite setup execution.

    ${tool_exist}=  Run  which redfishtool
    Should Not Be Empty  ${tool_exist}
