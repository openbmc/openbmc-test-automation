*** Settings ***

Documentation    Module to test IPMI DCMI functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/bmc_network_utils.robot
Resource         ../lib/boot_utils.robot
Variables        ../data/ipmi_raw_cmd_table.py
Variables        ../data/dcmi_raw_cmd_table.py
Variables        ../data/ipmi_variable.py
Library          ../lib/bmc_network_utils.py
Library          ../lib/ipmi_utils.py
Library          ../lib/utilities.py
Library          JSONLibrary

Suite Setup  Suite Setup Execution

*** Variables ***
${config_file_name}             dcmi_sensors.json
${dcmi_sensors_info_json_file}  /usr/share/ipmi-providers/${config_file_name}
${client_config_file_path}      ${EXEC_DIR}/${config_file_name}
&{dcmi_sensor_uri}

*** Test Cases ***
Verify Get Temperature Reading Command For Inlet Temperature Sensor
    [Documentation]  Verify IPMI Get Temperature Reading command for inlet temperature sensor.
    [Tags]  Verify_Get_Temperature_Reading_Command_For_Inlet_Temperature_Sensor

    ${cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['GET_TEMPERATURE_READING'][0]}
    ...  ${DCMI_RAW_CMD['DCMI']['GET_TEMPERATURE_READING'][1]} 0x00 0x00
    ${ipmi_resp}=  Run External IPMI Raw Command  ${cmd}
    Verify Reading With IPMI  ${ipmi_resp}  ${1}  inlet
    # Verify Temperature Reading With Dbus URI  ${ipmi_resp}  inlet  ${1}

Verify Get Temperature Reading Command For CPU 0 Temperature Sensor
    [Documentation]  Verify IPMI Get Temperature Reading command for cpu temperature sensor.
    [Tags]  Verify_Get_Temperature_Reading_Command_For_CPU_Temperature_Sensor

    ${cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['GET_TEMPERATURE_READING'][0]}
    ...  ${DCMI_RAW_CMD['DCMI']['GET_TEMPERATURE_READING'][2]} 0x00 0x00
    ${ipmi_resp}=  Run External IPMI Raw Command  ${cmd}
    Verify Reading With IPMI  ${ipmi_resp}  ${1}  cpu
    # Verify Temperature Reading With Dbus URI  ${ipmi_resp}  cpu  ${1}

Verify Get Temperature Reading Command For CPU 1 Temperature Sensor
    [Documentation]  Verify IPMI Get Temperature Reading command for cpu temperature sensor.
    [Tags]  Verify_Get_Temperature_Reading_Command_For_CPU_Temperature_Sensor

    ${cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['GET_TEMPERATURE_READING'][0]}
    ...  ${DCMI_RAW_CMD['DCMI']['GET_TEMPERATURE_READING'][2]} 0x00 0x00
    ${ipmi_resp}=  Run External IPMI Raw Command  ${cmd}
    Verify Reading With IPMI  ${ipmi_resp}  ${2}  cpu
    # Verify Temperature Reading With Dbus URI  ${ipmi_resp}  cpu  ${2}

Verify Get Temperature Reading Command For Baseboard Temperature Sensor
    [Documentation]  Verify IPMI Get Temperature Reading command for baseboard temperature sensor.
    [Tags]  Verify_Get_Temperature_Reading_Command_For_Baseboard_Temperature_Sensor

    ${cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['GET_TEMPERATURE_READING'][0]}
    ...  ${DCMI_RAW_CMD['DCMI']['GET_TEMPERATURE_READING'][3]} 0x00 0x00
    ${ipmi_resp}=  Run External IPMI Raw Command  ${cmd}
    Verify Reading With IPMI  ${ipmi_resp}  ${1}  baseboard
    # Verify Temperature Reading With Dbus URI  ${ipmi_resp}  baseboard  ${1}

*** Keywords ***
Suite Setup Execution
    [Documentation]  Get dcmi sensors uri from config file.

    IPMI Power On  stack_mode=skip  quiet=1

    # Get this file to client machine /usr/share/ipmi-providers/dcmi_sensors.json
    scp.Open Connection
    ...  ${OPENBMC_HOST}  username=${OPENBMC_USERNAME}  password=${OPENBMC_PASSWORD}  port=${SSH_PORT}
    scp.Get File  ${dcmi_sensors_info_json_file}  ${EXEC_DIR}
    scp.Close Connection

    ${config_file}=  OperatingSystem.Get File  ${client_config_file_path}
    ${config_file_response}=  Evaluate  json.loads('''${config_file}''')  json

    ${remove_configuration_file}=  Catenate  rm -rf ${client_config_file_path}
    ${rc}  ${output}=  Shell Cmd  ${remove_configuration_file}

    FOR  ${key}  ${value}  IN  &{config_file_response}
      &{tmp}=  Create Dictionary
      FOR  ${response}  IN  @{value}
        ${sensor_dbus}=  Get From Dictionary  ${response}  dbus
        ${instance}=  Get From Dictionary  ${response}  instance
        Set To Dictionary  ${tmp}  ${instance}  ${sensor_dbus}
      END
      Set To Dictionary  ${dcmi_sensor_uri}  ${key}  ${tmp}
    END

Verify Temperature Reading With Dbus URI
    [Documentation]  Verify temperature from ipmi response and json file.
    [Arguments]  ${ipmi_resp}  ${key}  ${instance}

    # Description of argument(s):
    # ipmi_resp         IPMI command response.
    # key               Entity ID description i.e inlet, cpu, baseboard.
    # instance          instance number 1, 2, ..

    ${dbus_uris}=  Get From Dictionary  ${dcmi_sensor_uri}  ${key}
    ${dbus_uri}=  Get From Dictionary  ${dbus_uris}  ${instance}

    ${get_reading_value}=  Set Variable If
    ...  '${instance}' == '1'  ${3}
    ...  '${instance}' == '2'  ${5}

    ${ipmi_resp_list}=  Split String  ${ipmi_resp}
    ${temperature_reading}=  Get From List  ${ipmi_resp_list}  ${get_reading_value}
    ${temp_reading}=  Convert To Integer  ${temperature_reading}  16
    ${busctl_cmd}=  Catenate  busctl introspect xyz.openbmc_project.HwmonTempSensor ${dbus_uri}
    ${busctl_cmd_resp}=  BMC Execute Command  ${busctl_cmd}
    ${current_temp_value_from_dbus}=  Get Regexp Matches  ${busctl_cmd_resp[0]}
    ...  \\.Value\\s+property\\s+d\\s+(\\S+)\\s  1

    ${min_value}=  Evaluate  ${temp_reading} - 1
    ${max_value}=  Evaluate  ${temp_reading} + 1

Check Reading Value In D-Bus
    [Documentation]  Verify temperature from ipmi response and json file.
    [Arguments]  ${key}  ${instance}  ${dcmi_reading_value}

    # Description of argument(s):
    # key               Entity ID description i.e inlet, cpu, baseboard.
    # instance          instance number 1, 2, ..

    ${dbus_uris}=  Get From Dictionary  ${dcmi_sensor_uri}  ${key}
    ${dbus_uri}=  Get From Dictionary  ${dbus_uris}  ${instance}

    ${busctl_cmd}=  Catenate  busctl introspect xyz.openbmc_project.HwmonTempSensor ${dbus_uri}
    ${busctl_cmd_resp}=  BMC Execute Command  ${busctl_cmd}
    ${current_temp_value_from_dbus}=  Get Regexp Matches  ${busctl_cmd_resp[0]}
    ...  \\.Value\\s+property\\s+d\\s+(\\S+)\\s  1
    Run Keyword If  '${current_temp_value_from_dbus[0]}' == 'nan' and '${dcmi_reading_value}' == '0'
    ...  Fail  msg=sensor reading value is not present.
    Run Keyword If  '${current_temp_value_from_dbus[0]}' != 'nan' and '${dcmi_reading_value}' == '0'
    ...  Fail  msg=sensor reading value is showing as 0 in dcmi get temperature raw command.
    ${dbus_reading_value}=  Set Variable  .${current_temp_value_from_dbus[0].split(".")[1].strip()}
    ${status}=  Run Keyword And Return Status  Should Be True  ${dbus_reading_value} > .499
    Run Keyword If  ${status} == False
    ...  Fail  msg=sensor reading value is showing wrongly in dcmi get temperature raw command.
    ${dbus_reading_value}=  Set Variable  ${current_temp_value_from_dbus[0].split(".")[0].strip()}
    Should Be Equal  ${dcmi_reading_value}  ${dbus_reading_value}
    ...  msg=sensor reading value is showing wrongly in dcmi get temperature raw command.

Verify Reading With IPMI
    [Documentation]  Verify temperature reading with ipmi command.
    [Arguments]  ${ipmi_resp}  ${instance}  ${key}

    # Description of argument(s):
    # ipmi_resp         IPMI command response.
    # instance          instance number 1, 2, ..
    # key               Entity ID description i.e inlet, cpu, baseboard.

    ${get_reading_value}=  Set Variable If
    ...  '${instance}' == '1'  ${3}
    ...  '${instance}' == '2'  ${5}

    ${ipmi_resp_list}=  Split String  ${ipmi_resp}
    ${temperature_reading}=  Get From List  ${ipmi_resp_list}  ${get_reading_value}
    ${dcmi_reading}=  Convert To Integer  ${temperature_reading}  16
    Run Keyword If  '${dcmi_reading}' == '0'
    ...  Check Reading Value In D-Bus  ${key}  ${instance}  ${dcmi_reading}
    ${dcmi_temp_reading}=  Convert To String  ${dcmi_reading}
    ${ipmi_sensor_cmd_rsp}=  Get IPMI Sensor Reading  ${key}  ${instance}
    ${ipmi_sensor_cmd_rsp_list}=  Split String  ${ipmi_sensor_cmd_rsp}  |
    ${ipmi_temp_reading}=  Set Variable  ${ipmi_sensor_cmd_rsp_list[1].strip().split(".")[0]}
    ${reading_status}=  Run Keyword And Return Status  Should Be Equal
    ...  ${dcmi_temp_reading}  ${ipmi_temp_reading}
    Run Keyword If  ${reading_status} == False
    ...  Check Reading Value In D-Bus  ${key}  ${instance}  ${dcmi_temp_reading}

Get IPMI Sensor Reading
    [Documentation]  Return ipmi sensor reading.
    [Arguments]  ${key}  ${instance}

    # Description of argument(s):
    # instance          Entity ID description i.e inlet, cpu, baseboard.
    # index             Selecting the corresponding sensor dbus uri from list.

    ${dbus_uris}=  Get From Dictionary  ${dcmi_sensor_uri}  ${key}
    ${dbus_uri}=  Get From Dictionary  ${dbus_uris}  ${instance}
    ${sensor_name}=  Set Variable  ${dbus_uri.split('/')[-1]}

    ${rsp}=  Run External IPMI Standard Command  sensor | grep -i "${sensor_name}"

    [Return]  ${rsp}
