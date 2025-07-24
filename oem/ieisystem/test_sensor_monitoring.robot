*** Settings ***
Documentation    Test Redfish sensor monitoring.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/bmc_redfish_utils.robot
Library          ../../lib/gen_robot_print.py
Library          ../../lib/utils.py

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

*** Variables ***

@{INVALID_SENSORS}
${OPENBMC_CONN_METHOD}  ssh
${IPMI_COMMAND}         Inband

** Test Cases **

Verify Sensor Monitoring
    [Documentation]  Verify the redfish sensor monitoring according to the BMC
    ...              expected SDR table.
    [Tags]  Verify_Sensor_Monitoring

    # Check whether the expected sensors are present in the Redfish request.
    # Check whether the sensors's 'Health' is 'OK' and the 'State' is 'Enabled'.
    # Check sensor reading is not equal to null.

    ${resp}=  Redfish.Get  /redfish/v1/Chassis/${CHASSIS_ID}
    ...  valid_status_codes=[${HTTP_OK}]

   Should Be Equal As Strings  ${resp.dict['Oem']['Public']['DiscreteSensors']['@odata.id']}
   ...  /redfish/v1/Chassis/${CHASSIS_ID}/DiscreteSensors
   Should Be Equal As Strings  ${resp.dict['Oem']['Public']['ThresholdSensors']['@odata.id']}
   ...  /redfish/v1/Chassis/${CHASSIS_ID}/ThresholdSensors
   Should Be Equal As Strings  ${resp.dict['Thermal']['@odata.id']}
   ...  /redfish/v1/Chassis/${CHASSIS_ID}/Thermal
   Should Be Equal As Strings  ${resp.dict['Power']['@odata.id']}
   ...  /redfish/v1/Chassis/${CHASSIS_ID}/Power

    # Check sensors in /redfish/v1/Chassis/{ChassisId}/Power
    ${resp}=  Redfish.Get  /redfish/v1/Chassis/${CHASSIS_ID}/Power
    ...  valid_status_codes=[${HTTP_OK}]

    Check Sensors Present  ${resp.dict['Voltages']}  Voltages
    Check Sensor Status And Reading Via Sensor Info
    ...  ${resp.dict['Voltages']}  ReadingVolts

    # Check sensors in /redfish/v1/Chassis/{ChassisId}/Thermal
    ${resp}=  Redfish.Get  /redfish/v1/Chassis/${CHASSIS_ID}/Thermal
    ...  valid_status_codes=[${HTTP_OK}]

    Check Sensors Present  ${resp.dict['Temperatures']}  Temperatures
    Check Sensors Present  ${resp.dict['Fans']}  Fans

    Check Sensor Status And Reading Via Sensor Info
    ...  ${resp.dict['Temperatures']}  ReadingCelsius
    Check Sensor Status And Reading Via Sensor Info
    ...  ${resp.dict['Fans']}  Reading

    # Check sensors in
    # /redfish/v1/Chassis/{ChassisId}/DiscreteSensors
    ${resp}=  Redfish.Get  /redfish/v1/Chassis/${CHASSIS_ID}/DiscreteSensors
    ...  valid_status_codes=[${HTTP_OK}]

    Check Sensors Present  ${resp.dict['Sensors']}  DiscreteSensors
    Check Sensor Status And Reading Via Sensor Info
    ...  ${resp.dict['Sensors']}  Status

    # Check sensors in
    # /redfish/v1/Chassis/{ChassisId}/ThresholdSensors
    ${resp}=  Redfish.Get  /redfish/v1/Chassis/${CHASSIS_ID}/ThresholdSensors
    ...  valid_status_codes=[${HTTP_OK}]

    Check Sensors Present  ${resp.dict['Sensors']}  ThresholdSensors
    Check Sensor Status And Reading Via Sensor Info
    ...  ${resp.dict['Sensors']}  Reading
    # ${expected_current_power_sensor_name_list}=  Set Variable
    # ...  ${redfish_sensor_info_map['${OPENBMC_MODEL}']['Current_Power']}

    # FOR  ${sensor_name}  IN  @{expected_current_power_sensor_name_list}
    #     Check Sensor Status And Reading Via Sensor Name  ${sensor_name}
    # END

    Rprint Vars  INVALID_SENSORS

    ${error_msg}=   Evaluate  ", ".join(${INVALID_SENSORS})
    Should Be Empty  ${INVALID_SENSORS}
    ...  msg=Test fail, invalid sensors are ${error_msg}.


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

    Should Not Be Empty   ${OS_HOST}
    Should Not Be Empty   ${OS_USERNAME}
    Should Not Be Empty   ${OS_PASSWORD}
    Run Keyword If  '${OPENBMC_CONN_METHOD}' == 'ssh'
    ...    Should Not Be Empty   ${OPENBMC_HOST}
    ...  ELSE IF  '${OPENBMC_CONN_METHOD}' == 'telnet'
    ...    Should Not Be Empty   ${OPENBMC_SERIAL_HOST}


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
    #   "Voltages": [
    #     {
    #     "@odata.id": "/redfish/v1/Chassis/1/Power#/Voltages/0",
    #     "@odata.type": "#Power.v1_7_1.Voltage",
    #     "LowerThresholdCritical": 10.8,
    #     "LowerThresholdFatal": 10.44,
    #     "LowerThresholdNonCritical": 11.16,
    #     "MaxReadingRange": 255.0,
    #     "MemberId": "0",
    #     "MinReadingRange": 0.0,
    #     "Name": "P12V_CPU0_DIMM",
    #     "ReadingVolts": null,
    #     "Status": {
    #         "Health": "OK",
    #         "State": "Enabled"
    #     },
    #     "UpperThresholdCritical": 13.2,
    #     "UpperThresholdFatal": 13.786,
    #     "UpperThresholdNonCritical": 12.84
    #     },

    #     ..
    # }

    @{sensor_name_list}=  Create List
    FOR  ${sensor_info}  IN  @{sensor_info_list}
        Append To List  ${sensor_name_list}  ${sensor_info['Name']}
    END

    [Return]  ${sensor_name_list}


Check Sensor Status And Reading Via Sensor Name
    [Documentation]  Check Sensor Status And Reading Via Sensor Name.
    [Arguments]  ${sensor_name}
    # Description of arguments:
    # sensor_name    Sensor that should be present.

    ${resp}=  Redfish.Get
    ...  /redfish/v1/Chassis/${CHASSIS_ID}/Sensors/${sensor_name}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    Run Keyword And Return If  '${resp.status}' == '${HTTP_NOT_FOUND}'
    ...  Append To List  ${INVALID_SENSORS}  ${sensor_name}

    ${condition_str}=  Catenate
        ...  '${resp.dict['Status']['Health']}' != 'OK'
        ...  or '${resp.dict['Status']['State']}' != 'Enabled'
        ...  or ${resp.dict['Reading']} == ${null}

    Run Keyword If  ${condition_str}
    ...  Append To List  ${INVALID_SENSORS}  ${sensor_name}


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
        ${condition_str}=  Catenate
        ...  '${sensor_info['Status']['Health']}' != 'OK'
        ...  or '${sensor_info['Status']['State']}' != 'Enabled'
        ...  or ${sensor_info['${reading_unit}']} == ${null}

        Run Keyword If  ${condition_str}
        ...  Append To List  ${INVALID_SENSORS}  ${sensor_info['Name']}
    END


Check Sensors Present
    [Documentation]  Check that sensors are present as expected.
    [Arguments]  ${sensor_info_list}  ${sensor_type}
    # Description of arguments:
    # sensor_info_list  A list of a specified sensor info return by a redfish
    #                   request.
    # sensor_type       A string represents the sensor category to be verified.

    # An example table of expected sensors:
    # redfish_sensor_info_map = {
    #       "Voltages":{
    #           "Voltage0",
    #           ...
    #       },
    #       "Temperatures":{
    #           "DIMM0",
    #           ...
    #       }
    #       "Fans":{
    #           "Fan0",
    #           ...
    #       }...
    #}

    ${curr_sensor_name_list}=  Get Sensors Name List From Redfish
    ...  ${sensor_info_list}

    ${code_base_dir_path}=  Get Code Base Dir Path
    ${redfish_sensor_info_map}=  Evaluate
    ...  json.load(open('${code_base_dir_path}data/oem/ieisystem/sensors_resource.json'))  modules=json

    ${expected_sensor_name_list}=  Set Variable
    ...  ${redfish_sensor_info_map['${sensor_type}']}

    FOR  ${sensor_name}  IN  @{expected_sensor_name_list}
        ${exist}=  Evaluate  '${sensor_name}' in ${curr_sensor_name_list}
        Run Keyword If  '${exist}' == '${False}'
        ...  Append To List  ${INVALID_SENSORS}  ${sensor_name}
    END
