*** Settings ***
Documentation    Test Redfish sensor monitoring.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/bmc_redfish_utils.robot
Library          ../../lib/gen_robot_print.py

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

Test Tags        Sensor_Monitoring

*** Variables ***

@{INVALID_SENSORS}
${OPENBMC_CONN_METHOD}  ssh
${IPMI_COMMAND}         Inband

# Optional filters for Verify Redfish Sensor Collection.
# Set on the CLI with -v to further scope the run, e.g.:
#   -v RESOURCE_PATH_FILTER:Sensors
#   -v RESOURCE_TYPE_FILTER:Fan_Tach
${RESOURCE_PATH_FILTER}   Sensors
${RESOURCE_TYPE_FILTER}       ${EMPTY}

*** Test Cases ***

Verify Sensor Monitoring
    [Documentation]  Verify the redfish sensor monitoring according to the BMC
    ...              expected SDR table.
    [Tags]  Verify_Sensor_Monitoring

    # Check whether the expected sensors are present in the Redfish request.
    # Check whether the sensors's 'Health' is 'OK' and the 'State' is 'Enabled'.
    # Check sensor reading is not equal to null.

    ${resp}=  Redfish.Get  /redfish/v1/Chassis/${CHASSIS_ID}
    ...  valid_status_codes=[${HTTP_OK}]

    Should Be Equal As Strings  ${resp.dict['Sensors']['@odata.id']}
    ...  /redfish/v1/Chassis/${CHASSIS_ID}/Sensors
    Should Be Equal As Strings  ${resp.dict['Thermal']['@odata.id']}
    ...  /redfish/v1/Chassis/${CHASSIS_ID}/Thermal
    Should Be Equal As Strings  ${resp.dict['Power']['@odata.id']}
    ...  /redfish/v1/Chassis/${CHASSIS_ID}/Power

    # Check sensors in /redfish/v1/Chassis/{ChassisId}/Power
    ${resp}=  Redfish.Get  /redfish/v1/Chassis/${CHASSIS_ID}/Power
    ...  valid_status_codes=[${HTTP_OK}]

    Check Sensors Present  ${resp.dict['Voltages']}  Voltage
    Check Sensor Status And Reading Via Sensor Info
    ...  ${resp.dict['Voltages']}  ReadingVolts

    # Check sensors in /redfish/v1/Chassis/{ChassisId}/Thermal
    ${resp}=  Redfish.Get  /redfish/v1/Chassis/${CHASSIS_ID}/Thermal
    ...  valid_status_codes=[${HTTP_OK}]

    Check Sensors Present  ${resp.dict['Temperatures']}  Temperature
    Check Sensors Present  ${resp.dict['Fans']}  Fans

    Check Sensor Status And Reading Via Sensor Info
    ...  ${resp.dict['Temperatures']}  ReadingCelsius
    Check Sensor Status And Reading Via Sensor Info
    ...  ${resp.dict['Fans']}  Reading

    # Check sensors in
    # /redfish/v1/Chassis/{ChassisId}/Sensors/{Sensor Name}
    ${expected_current_power_sensor_name_list}=  Set Variable
    ...  ${redfish_sensor_info_map['${OPENBMC_MODEL}']['Current_Power']}

    FOR  ${sensor_name}  IN  @{expected_current_power_sensor_name_list}
        Check Sensor Status And Reading Via Sensor Name  ${sensor_name}
    END

    Rprint Vars  INVALID_SENSORS

    ${error_msg}=   Evaluate  ", ".join(${INVALID_SENSORS})
    Should Be Empty  ${INVALID_SENSORS}
    ...  msg=Test fail, invalid sensors are ${error_msg}.


Verify Sensor Monitoring Per Collection
    [Documentation]  For every endpoint and resource type defined for CHASSIS_ID
    ...              in redfish_sensor_info_map, verify that each expected resource:
    ...                1. Is present in the Redfish collection.
    ...                2. Has Status.Health == OK.
    ...                3. Has Status.State == Enabled.
    ...                4. Has a non-null Reading.
    ...              The Redfish sub-path is set via RESOURCE_PATH_FILTER (default: Sensors).
    ...              Resource-type lists are driven entirely by the model variable file.
    ...              Use the CLI filters to scope the run:
    ...                RESOURCE_PATH_FILTER - Redfish sub-path to GET (e.g. Sensors)
    ...                RESOURCE_TYPE_FILTER - limit to one resource type
    ...              Chassis is always scoped to CHASSIS_ID.
    [Tags]  Verify_Sensor_Monitoring_Per_Collection

    ${model_map}=  Set Variable  ${redfish_sensor_info_map['${OPENBMC_MODEL}']}

    # Skip gracefully when the model does not define any chassis entries.
    ${has_resources}=  Evaluate  len($model_map) > 0
    Skip If  not ${has_resources}
    ...  No chassis resources defined for ${OPENBMC_MODEL}; skipping.

    # Counter to detect vacuous passes caused by filters that match nothing.
    ${resources_checked}=  Set Variable  ${0}

    Log  Verifying chassis: ${CHASSIS_ID} path: ${RESOURCE_PATH_FILTER}

    # GET the collection at the specified sub-path.
    ${resp}=  Redfish.Get  /redfish/v1/Chassis/${CHASSIS_ID}/${RESOURCE_PATH_FILTER}
    ...  valid_status_codes=[${HTTP_OK}]

    # Extract all resource names present in the collection.
    ${present_names}=  Get Sensor Names From Members List  ${resp.dict['Members']}

    Log  Resources found: ${present_names}

    # Iterate over every resource type defined for this chassis.
    FOR  ${resource_type}  IN  @{model_map}

        # Skip any resource type that does not match the required filter.
        # When RESOURCE_TYPE_FILTER is empty, all types are validated.
        Continue For Loop If
        ...  '${RESOURCE_TYPE_FILTER}' != '${EMPTY}' and '${resource_type}' != '${RESOURCE_TYPE_FILTER}'

        ${expected_list}=  Set Variable  ${model_map['${resource_type}']}

        FOR  ${resource_name}  IN  @{expected_list}
            ${exist}=  Evaluate  ${resource_name} in ${present_names}
            IF  '${exist}' == '${False}'
                # Resource missing from collection — record and skip status check.
                Append To List  ${INVALID_SENSORS}  ${resource_name}
            ELSE
                # Resource present — validate Health, State, and Reading.
                Check Sensor Status And Reading Via Sensor Name
                ...  ${resource_name}  ${RESOURCE_PATH_FILTER}
            END
            ${resources_checked}=  Evaluate  ${resources_checked} + 1
        END
    END

    # Fail if no resources were validated — prevents silent passes when filters
    # are misconfigured or match nothing in the map.
    IF  ${resources_checked} == 0
        Fail  No resources were validated. Verify filter values:
        ...   CHASSIS_ID=${CHASSIS_ID},
        ...   RESOURCE_PATH_FILTER=${RESOURCE_PATH_FILTER},
        ...   RESOURCE_TYPE_FILTER=${RESOURCE_TYPE_FILTER}
    END

    Rprint Vars  INVALID_SENSORS

    ${error_msg}=  Evaluate  ", ".join(${INVALID_SENSORS})
    Should Be Empty  ${INVALID_SENSORS}
    ...  msg=Test fail, invalid resources are ${error_msg}.


*** Keywords ***

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    Run Keyword And Ignore Error  Redfish.Logout


Test Setup Execution
    [Documentation]  Do the test setup.

    Required Parameters For Sensor Monitoring
    Redfish.Login


Required Parameters For Sensor Monitoring
    [Documentation]  Check if required parameters are provided via command line.
    ...              Also loads the model-specific variable file so that
    ...              ${redfish_sensor_info_map} is available to all tests.

    Should Not Be Empty   ${OS_HOST}
    Should Not Be Empty   ${OS_USERNAME}
    Should Not Be Empty   ${OS_PASSWORD}

    IF  '${OPENBMC_CONN_METHOD}' == 'ssh'
        Should Not Be Empty   ${OPENBMC_HOST}
    ELSE IF  '${OPENBMC_CONN_METHOD}' == 'telnet'
        Should Not Be Empty   ${OPENBMC_SERIAL_HOST}
    END

    Should Not Be Empty   ${OPENBMC_MODEL}


Get Sensors Name List From Redfish
    [Documentation]  Get sensors name list from redfish.
    [Arguments]  ${sensor_info_list}
    # Description of arguments:
    # sensor_info_list    A list of a specified sensor info return by a redfish
    #                     request.

    # An example of a sensor redfish request:
    # /redfish/v1/Chassis/${CHASSIS_ID}/Power
    # {
    #     ...
    #     "Voltages": [
    #     {
    #     "@odata.id": "/redfish/v1/Chassis/${CHASSIS_ID}/Power#/Voltages/0",
    #     "@odata.type": "#Power.v1_0_0.Voltage",
    #     "LowerThresholdCritical": 1.14,
    #     "LowerThresholdNonCritical": 1.14,
    #     "MaxReadingRange": 2.0,
    #     "MemberId": "Output_Voltage",
    #     "MinReadingRange": 0.0,
    #     "Name": "Output Voltage",
    #     "ReadingVolts": 1.176,
    #     "Status": {
    #         "Health": "OK",
    #         "State": "Enabled"
    #     },
    #     "UpperThresholdCritical": 1.21,
    #     "UpperThresholdNonCritical": 1.21
    #     }
    #     ...
    # }

    @{sensor_name_list}=  Create List
    FOR  ${sensor_info}  IN  @{sensor_info_list}
        Append To List  ${sensor_name_list}  ${sensor_info['MemberId']}
    END

    RETURN  ${sensor_name_list}


Check Sensor Status And Reading Via Sensor Name
    [Documentation]  Check Sensor Status And Reading Via Sensor Name.
    [Arguments]  ${sensor_name}  ${sub_path}=Sensors
    # Description of arguments:
    # sensor_name    Resource name to validate.
    # sub_path       Redfish sub-path under the chassis (e.g. Sensors,
    #                PowerSubsystem/Regulators). Defaults to Sensors.

    ${resp}=  Redfish.Get
    ...  /redfish/v1/Chassis/${CHASSIS_ID}/${sub_path}/${sensor_name}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    Run Keyword And Return If  '${resp.status}' == '${HTTP_NOT_FOUND}'
    ...  Append To List  ${INVALID_SENSORS}  ${sensor_name}

    ${condition_str}=  Catenate
        ...  '${resp.dict['Status']['Health']}' != 'OK'
        ...  or '${resp.dict['Status']['State']}' != 'Enabled'
        ...  or ${resp.dict['Reading']} == ${null}

    IF  ${condition_str}
        Append To List  ${INVALID_SENSORS}  ${sensor_name}
    END


Check Sensor Status And Reading Via Sensor Info
    [Documentation]  Check Sensor Status And Reading Via Sensor Info.
    [Arguments]  ${sensor_info_list}  ${reading_unit}
    # Description of arguments:
    # sensor_info_list  A list of a specified sensor info return by a redfish
    #                   request.
    # reading_unit      A string represents the reading value in sensor info
    #                   return by a redfish request. It different between
    #                   different sensor unit of sensor info.

    FOR  ${sensor_info}  IN  @{sensor_info_list}
        ${sensor}=  Set Variable  ${sensor_info['MemberId']}
        ${condition_str}=  Catenate
        ...  '${sensor_info['Status']['Health']}' != 'OK'
        ...  or '${sensor_info['Status']['State']}' != 'Enabled'
        ...  or ${sensor_info['${reading_unit}']} == ${null}

        IF  ${condition_str}
            Append To List  ${INVALID_SENSORS}  ${sensor_info['MemberId']}
        END
    END


Get Sensor Names From Members List
    [Documentation]  Extract resource names from a Redfish collection Members list.
    [Arguments]  ${members_list}
    # Description of arguments:
    # members_list  The 'Members' list from any Redfish collection response.
    #               Each entry is a dict with an '@odata.id' key, e.g.:
    #               { "@odata.id": "/redfish/v1/Chassis/${CHASSIS_ID}/Sensors/Fan_0" }
    # Returns a list of resource name strings (last path segment of each @odata.id).

    @{sensor_names}=  Create List
    FOR  ${member}  IN  @{members_list}
        ${sensor_name}=  Evaluate  '${member['@odata.id']}'.split('/')[-1]
        Append To List  ${sensor_names}  ${sensor_name}
    END

    RETURN  ${sensor_names}


Check Sensors Present
    [Documentation]  Check that sensors are present as expected.
    [Arguments]  ${sensor_info_list}  ${sensor_type}
    # Description of arguments:
    # sensor_info_list  A list of a specified sensor info return by a redfish
    #                   request.
    # sensor_type       A string represents the sensor category to be verified.

    # An example table of expected sensors:
    # redfish_sensor_info_map = {
    #   ${OPENBMC_MODEL}:{
    #       "Voltage":{
    #           "Voltage0",
    #           ...
    #       },
    #       "Temperature":{
    #           "DIMM0",
    #           ...
    #       }
    #       "Fans":{
    #           "Fan0",
    #           ...
    #       }...
    #   }
    # }

    ${curr_sensor_name_list}=  Get Sensors Name List From Redfish
    ...  ${sensor_info_list}

    ${expected_sensor_name_list}=  Set Variable
    ...  ${redfish_sensor_info_map['${OPENBMC_MODEL}']['${sensor_type}']}

    FOR  ${sensor_name}  IN  @{expected_sensor_name_list}
        ${exist}=  Evaluate  '${sensor_name}' in ${curr_sensor_name_list}
        IF  '${exist}' == '${False}'
           Append To List  ${INVALID_SENSORS}  ${sensor_name}
        END
    END

