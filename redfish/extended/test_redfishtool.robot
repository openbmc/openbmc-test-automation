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
${cmd_args}             -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always
${min_number_sensors}   ${15}

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
    ${num_sensors}=   Set Variable   ${json_object["Members@odata.count"]}
    ${num_sensors}=  Convert to Integer  ${num_sensors}
    Should Be True  ${num_sensors} > ${min_number_sensors}
    ...  msg=There should be at least ${min_number_sensors} sensors.


Verify Redfishtool Health Check Commands
    [Documentation]  Verify health check command works.
    [Tags]  Verify_Redfishtool_Health_Check_Commands

    #${health_results}=  Get Health Check  verify=${1}
    Get Health Check  verify=${health}
    #Rprint Vars  health_results

*** Keywords ***


Redfishtool Get
    [Documentation]  Execute DMTF redfishtool for  GET operation.
    [Arguments]  ${uri}

    # Description of argument(s):
    # uri  URI for GET operation.

    ${cmd_output}=  Run  ${cmd_prefix} GET ${uri} ${cmd_args}
    [Return]  ${cmd_output}

Get Health Check
    [Documentation]  Execute DMTF redfishtool for  GET operation.
    [Arguments]  ${health_status}

    Log To Console  The value comes as : ${health_status}
    ${chassis_data}=    Redfishtool Get  /redfish/v1/Chassis/chassis/
    ${resp}=  Run Keyword And Return Status  Evaluate  json.loads('''${chassis_data}''')  json
    Should Be True  ${resp}
    ${json_object}=  Evaluate  json.loads('''${chassis_data}''')  json
    ${status}=   Set Variable   ${json_object["Status"]}
    ${status_health}=          Convert to string    ${status["Health"]}
    ${health_status}=          Convert to string    ${health_status}
    Should be equal   ${health_status}    ${status_health}
    ...  msg=Health status should be ${status["Health"]}.


Suite Setup Execution
    [Documentation]  Do suite setup execution.
    ${tool_exist}=  Run  which redfishtool
    Should Not Be Empty  ${tool_exist}
