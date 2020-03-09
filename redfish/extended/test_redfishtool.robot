*** Settings ***
Documentation    Verify Redfish tool functionality.

# The following tests are performed:
#
# sensors list
#
# directory PATH in $PATH.
#
# Test Parameters:
# OPENBMC_HOST          The BMC host name or IP address.
# OPENBMC_USERNAME      The username to login to the BMC.
# OPENBMC_PASSWORD      Password for OPENBMC_USERNAME.
#
# We use DMTF Redfishtool for writing openbmc automation test cses.
# DMTF redfishtool is a commandline tool that implements the client
# side of the Redfish RESTful API for Data Center Hardware Management.

Library                 String
Library                 OperatingSystem

Suite Setup             Suite Setup Execution

*** Variables ***

${cmd_prefix}           redfishtool raw
${cmd_args}             -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always
${sensor_uri}           /redfish/v1/Chassis/chassis/Sensors
${health_check_uri}     /redfish/v1/Managers/bmc
${min_number_sensors}   ${15}

*** Test Cases ***

Verify Redfishtool Sensors Commands
    [Documentation]  Verify sensors commands work.
    [Tags]  Verify_Redfishtool_Sensors_Commands

    Verify Sensors List

*** Keywords ***


Verify Sensors List
    [Documentation]  Verify that minimum number of sensors are available.
    ${sensor_status}=    Redfishtool Get  ${sensor_uri}
    ${num_sensors}=  Get Length  ${sensor_status}
    ${num_sensors}=  Convert to Integer  ${num_sensors}
    Should Be True  ${num_sensors} > ${min_number_sensors}
    ...  msg=There should be at least ${min_number_sensors} sensors.

Redfishtool Get
    [Documentation]  Execute DMTF redfishtool for  GET operation.
    [Arguments]  ${uri}

    # Description of argument(s):
    # uri  URI for GET operation.

    ${cmd_output}=  Run  ${cmd_prefix} GET ${uri} ${cmd_args}
    [Return]  ${cmd_output}

Suite Setup Execution
    [Documentation]  Do suite setup execution.
    ${tool_exist}=  Run  which redfishtool
    Should Not Be Empty  ${tool_exist}
