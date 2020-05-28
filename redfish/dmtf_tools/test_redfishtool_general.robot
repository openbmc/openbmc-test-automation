*** Settings ***


Documentation     Verify Redfish tool general functionality.

Library           OperatingSystem
Library           String
Library           Collections

Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_resource.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/dmtf_redfishtool_utils.robot


Suite Setup       Suite Setup Execution


*** Variables ***


${root_cmd_args} =  SEPARATOR=
...  redfishtool raw -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always
${min_number_sensors}  ${15}


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


Suite Setup Execution
    [Documentation]  Do suite setup execution.

    ${tool_exist}=  Run  which redfishtool
    Should Not Be Empty  ${tool_exist}
