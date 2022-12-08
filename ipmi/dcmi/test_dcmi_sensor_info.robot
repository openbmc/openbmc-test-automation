*** Settings ***

Documentation    Module to test dcmi get sensor info functionality.
Resource         ../../lib/ipmi_client.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_network_utils.robot
Resource         ../../lib/boot_utils.robot
Variables        ../../data/ipmi_raw_cmd_table.py
Variables        ../../data/dcmi_raw_cmd_table.py
Variables        ../../data/ipmi_variable.py
Library          ../../lib/bmc_network_utils.py
Library          ../../lib/ipmi_utils.py
Library          ../../lib/utilities.py
Library          JSONLibrary

Suite Setup  Suite Setup Execution

*** Variables ***
${config_file_name}             dcmi_sensors.json
${dcmi_sensors_info_json_file}  /usr/share/ipmi-providers/${config_file_name}
${client_config_file_path}      ${EXEC_DIR}/${config_file_name}
&{dcmi_sensor_name}
&{dcmi_instance_count}

*** Test Cases ***
Verify DCMI Sensor Info Command For Inlet Temperature Sensor
    [Documentation]  Verify IPMI DCMI sensor info command for inlet temperature sensor.
    [Tags]  Verify_DCMI_Sensor_Info_Command_For_Inlet_Temperature_Sensor

    ${sensor_info_cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['Sensor_Info'][0]}
    ...  ${DCMI_RAW_CMD['DCMI']['Sensor_Info'][1]} 0x00 0x00
    ${ipmi_resp}=  Run External IPMI Raw Command  ${sensor_info_cmd}
    Verify Instance ID  ${ipmi_resp}  inlet
    Verify SDR Record ID  ${ipmi_resp}  inlet

Verify DCMI Sensor Info Command For CPU Temperature Sensor
    [Documentation]  Verify IPMI DCMI sensor info command for cpu temperature sensor.
    [Tags]  Verify_DCMI_Sensor_Info_Command_For_CPU_Temperature_Sensor

    ${sensor_info_cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['Sensor_Info'][0]}
    ...  ${DCMI_RAW_CMD['DCMI']['Sensor_Info'][2]} 0x00 0x00
    ${ipmi_resp}=  Run External IPMI Raw Command  ${sensor_info_cmd}
    Verify Instance ID  ${ipmi_resp}  cpu
    Verify SDR Record ID  ${ipmi_resp}  cpu

Verify DCMI Sensor Info Command For Baseboard Temperature Sensor
    [Documentation]  Verify IPMI DCMI sensor info command for baseboard temperature sensor.
    [Tags]  Verify_DCMI_Sensor_Info_Command_For_Baseboard_Temperature_Sensor

    ${sensor_info_cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['Sensor_Info'][0]}
    ...  ${DCMI_RAW_CMD['DCMI']['Sensor_Info'][3]} 0x00 0x00
    ${ipmi_resp}=  Run External IPMI Raw Command  ${sensor_info_cmd}
    Verify Instance ID  ${ipmi_resp}  baseboard
    Verify SDR Record ID  ${ipmi_resp}  baseboard

*** Keywords ***
Suite Setup Execution
    [Documentation]  Get dcmi sensors name from config file.

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
      @{tmp}=  Create List
      ${instance_count}=  Get Length  ${value}
      FOR  ${response}  IN  @{value}
        ${sensor_dbus}=  Get From Dictionary  ${response}  dbus
        ${sensor_name}=  Set Variable  ${sensor_dbus.split('/')[-1]}
        Append To List  ${tmp}  ${sensor_name}
      END
      Set To Dictionary  ${dcmi_sensor_name}  ${key}  ${tmp}
      Set To Dictionary  ${dcmi_instance_count}  ${key}  ${instance_count}
    END

    ${ipmi_sdr_elist_command_response}=  Run External IPMI Standard Command  sdr elist
    Set Suite Variable  ${ipmi_sdr_elist_command_response}

Verify Instance ID
    [Documentation]  Verify Instance ID we got from json file matching with ipmi resp
    ...  for given entity ID.
    [Arguments]  ${ipmi_resp}  ${instance}

    # Description of argument(s):
    # ipmi_resp         IPMI command response.
    # instance          Entity ID description i.e inlet, cpu, baseboard.

    ${instance_count_from_dict}=  Get From Dictionary  ${dcmi_instance_count}  ${instance}

    ${ipmi_resp_list}=  Split String  ${ipmi_resp}
    ${ipmi_instance_count}=  Get From List  ${ipmi_resp_list}  1
    Should Be Equal As Numbers  ${instance_count_from_dict}  ${ipmi_instance_count}
    ...  msg=instance count mismatched between ipmi response and dcmi_sensors.json file.

Verify SDR Record ID
    [Documentation]  Verify Record ID of sensor name we got from json file matching with ipmi resp
    ...  for given .
    [Arguments]  ${ipmi_resp}  ${instance}

    # Description of argument(s):
    # ipmi_resp         IPMI command response.
    # instance          Entity ID description i.e inlet, cpu, baseboard.

    ${dcmi_sensor_list}=  Get From Dictionary  ${dcmi_sensor_name}  ${instance}
    ${record_id}=  Set Variable  ${ipmi_resp[10:]}
    ${dcmi_record_id_list}=  Split String  ${record_id}

    FOR  ${sensor_name}  IN  @{dcmi_sensor_list}
      ${get_sdr_line}=  Get Lines Containing String  ${ipmi_sdr_elist_command_response}  ${sensor_name}
      ${sdr_record_id}=  Set Variable  ${get_sdr_line.split("|")[1].replace('h', '').strip()}
      ${ipmi_record_id}=  Convert To Lowercase  ${sdr_record_id}
      List Should Contain Value  ${dcmi_record_id_list}  ${ipmi_record_id}
      Remove Values From List  ${dcmi_record_id_list}  ${ipmi_record_id}
    END
