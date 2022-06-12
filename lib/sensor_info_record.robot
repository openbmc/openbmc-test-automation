*** Settings ***
Documentation  Sensor Related Keywords.

Resource         resource.robot
Library          utils.py

Library          OperatingSystem
Library          Collections

*** Variable ***
@{sensor_service_path_not_mapped_in_sensor_tree}
&{sensor_dbus_uri_command_dict}

${busctl_tree_sensor_service_grep_command}    busctl tree | less | grep -i "Service xyz" | grep -i Sensor
${busctl_tree_command}                        busctl tree | less
${busctl_introspect_command}                  busctl introspect

*** Keywords ***
Get All Sensor Service Path
    [Documentation]  Get sensor service paths.

    # An list of sensor service path will be created.

    @{dbus_tree_sensor_service_list}=  Create List

    ${bmc_response}=  BMC Execute Command  ${busctl_tree_sensor_service_grep_command}
    ${busctl_tree_sensor_service_list}=  Convert To List  ${bmc_response}
    ${service_name}=  Get From List  ${busctl_tree_sensor_service_list}  0
    ${busctl_tree_sensor_service_list}=  Split String  ${service_name}  \n
    FOR  ${service_name}  IN  @{busctl_tree_sensor_service_list}
      ${service_name}=  Remove String  ${service_name}  :
      Append To List  ${dbus_tree_sensor_service_list}  ${service_name}
    END

    [Return]  ${dbus_tree_sensor_service_list}


Create An Dictionary With Sensor Name And Service Path URI
    [Documentation]  Dictionary will be created with sensor name as an key and service path as an value.
    [Arguments]  ${sensor_id_list}

    # Description of argument(s):
    # sensor_id_list    Sensor name list.

    # An list will be created with respective sensor object path uris.
    # An dictionary will be created with sensor name as key and its respective service path uri as value.

    @{object_path_uri_list}=  Create List
    &{sensor_name_service_path_uri_dict}=  Create Dictionary

    ${dbus_tree_sensor_service_list}=  Get All Sensor Service Path

    ${bmc_response}=  BMC Execute Command  ${busctl_tree_command}
    ${bmc_response}=  Convert To List  ${bmc_response}
    ${bmc_response_output}=  Get From List  ${bmc_response}  0
    ${bmc_response_output_list}=  Split String  ${bmc_response_output}  \n\n

    FOR  ${service_name}  IN  @{dbus_tree_sensor_service_list}
      ${service_name_index_value}=  get_subsequent_value_from_list  ${bmc_response_output_list}  ${service_name}
      ${service_name_index_value}=  Get From List  ${service_name_index_value}  0
      ${service_name_with_sensor_list}=  Get From List  ${bmc_response_output_list}  ${service_name_index_value}
      ${service_name_with_sensor_list}=  Split String  ${service_name_with_sensor_list}  \n
      ${sensor_uri_list_index}=  get_subsequent_value_from_list  ${service_name_with_sensor_list}  /xyz/openbmc_project/sensors
      FOR  ${list_index}  IN  @{sensor_uri_list_index}
        ${sensors_uri_list}=  Get From List  ${service_name_with_sensor_list}  ${list_index}
        Append To List  ${object_path_uri_list}  ${sensors_uri_list}
      END
      FOR  ${sensor_id}  IN  @{sensor_id_list}
        ${sensor_id_index_value}=  get_subsequent_value_from_list  ${object_path_uri_list}  ${sensor_id}
        ${sensor_id_index_value_status}=  Run Keyword And Return Status  Should Not Be Empty  ${sensor_id_index_value}
        Continue For Loop If  ${sensor_id_index_value_status} == False
        ${sensor_id_in_dict}=  Evaluate  "${sensor_id}" in ${sensor_name_service_path_uri_dict}
        Continue For Loop If  ${sensor_id_in_dict} == True
        FOR  ${index}  IN  @{sensor_id_index_value}
          ${dbus_sensor_id}=  Get From List  ${object_path_uri_list}  ${index}
          ${dbus_sensor_id}=  Split String  ${dbus_sensor_id}  /
          ${dbus_sensor_id}=  Get From List  ${dbus_sensor_id}  -1
          ${dbus_sensor_name}=  Convert Sensor Name As Per IPMI Spec  ${dbus_sensor_id}
          ${dbus_sensor_name_status}=  Run Keyword And Return Status  Should Be Equal  ${dbus_sensor_name}  ${sensor_id}
          Continue For Loop If  ${dbus_sensor_name_status} == False
          Set To Dictionary  ${sensor_name_service_path_uri_dict}  ${dbus_sensor_name}  ${service_name}
        END
      END
    END

    [Return]  ${sensor_name_service_path_uri_dict}  ${object_path_uri_list}


Create An Dictionary With Sensor Name And Object Path URI
    [Documentation]  Dictionary will be created with sensor name as an key and object path as an value.
    [Arguments]  ${object_path_uri_list}  ${sensor_id_list}

    # Description of argument(s):
    # object_path_uri_list  List of respective sensor object path uri.
    # sensor_id_list        Sensor name list.

    # An list will be created for an sensors which service path / object path was not mapped in sensor tree.
    # An dictionary will be created with sensor name as key and its respective object path uri as value.

    &{sensor_name_object_path_uri_dict}=  Create Dictionary

    FOR  ${sensor_id}  IN  @{sensor_id_list}
      ${sensor_id_index}=  get_subsequent_value_from_list  ${object_path_uri_list}  ${sensor_id}
      FOR  ${index}  IN  @{sensor_id_index}
        ${dbus_sensor_uri}=  Get From List  ${object_path_uri_list}  ${index}
        ${dbus_sensor_uri}=  Split String  ${dbus_sensor_uri}  /
        ${dbus_sensor_id}=  Get From List  ${dbus_sensor_uri}  -1
        ${dbus_uri_sensor_name}=  Convert Sensor Name As Per IPMI Spec  ${dbus_sensor_id}
        ${dbus_sensor_name_status}=  Run Keyword And Return Status  Should Be Equal  ${dbus_uri_sensor_name}  ${sensor_id}
        Run Keyword If  '${dbus_sensor_name_status}' == 'False'
        ...  Remove Values From List  ${sensor_id_index}  ${index}
      END
      ${sensor_id_index_value_status}=  Run Keyword And Return Status  Should Not Be Empty  ${sensor_id_index}
      Run Keyword If  '${sensor_id_index_value_status}' == 'False'
      ...  Append To List  ${sensor_service_path_not_mapped_in_sensor_tree}  ${sensor_id}
      Continue For Loop If  ${sensor_id_index_value_status} == False
      ${sensor_id_index}=  Get From List  ${sensor_id_index}  0
      ${dbus_sensor_uri}=  Get From List  ${object_path_uri_list}  ${sensor_id_index}
      ${dbus_sensor_name}=  Convert Sensor Name As Per IPMI Spec  ${sensor_id}
      ${sensor_uri}=  return_decoded_string  ${dbus_sensor_uri}
      Set To Dictionary  ${sensor_name_object_path_uri_dict}  ${dbus_sensor_name}  ${sensor_uri}
    END

    [Return]  ${sensor_name_object_path_uri_dict}


Create an Dictionary With Sensor ID And Dbus Command For Sensors Via IPMI
    [Documentation]  Create an dictionary by mapping sensor id with dbus command.
    [Arguments]  ${sensor_id_list}

    # Description of argument(s):
    # sensor_id_list        Sensor name list.

    ${sensor_name_service_path_uri_dict}  ${object_path_uri_list}=
    ...  Create An Dictionary With Sensor Name And Service Path URI  ${sensor_id_list}

    ${sensor_name_object_path_uri_dict}=
    ...  Create An Dictionary With Sensor Name And Object Path URI  ${object_path_uri_list}  ${sensor_id_list}

    FOR  ${sensor_id}  IN  @{sensor_id_list}
      ${sensor_id_in_dict}=  Evaluate  "${sensor_id}" in ${sensor_name_object_path_uri_dict}
      Continue For Loop If  ${sensor_id_in_dict} == False
      ${dbus_service_name}=  Get From Dictionary  ${sensor_name_service_path_uri_dict}  ${sensor_id}
      ${dbus_command}=  Get From Dictionary  ${sensor_name_object_path_uri_dict}  ${sensor_id}
      ${dbus_service_name}=  Split String  ${dbus_service_name}
      ${dbus_service_name}=  Get From List  ${dbus_service_name}  1
      ${dbus_service_name}=  Replace String  ${dbus_service_name}  ${SPACE}  ${EMPTY}
      ${dbus_command}=  Replace String  ${dbus_command}  ${SPACE}  ${EMPTY}
      ${sensor_dbus_uri}=  Catenate  ${dbus_service_name} ${dbus_command}
      Set To Dictionary  ${sensor_dbus_uri_command_dict}  ${sensor_id}  ${sensor_dbus_uri}
    END

    [Return]  ${sensor_dbus_uri_command_dict}  ${sensor_service_path_not_mapped_in_sensor_tree}


Build DBus Command
    [Documentation]  Build dbus command.
    [Arguments]  ${dbus_uri}

    # Description of argument(s):
    # dbus_uri    service path.object path uri.
 
    # Build complete dbus command and return the command.

    ${busctl_command}=  Catenate  ${busctl_introspect_command} ${dbus_uri}
    [Return]  ${busctl_command}


Get Dbus Sensor Threshold
    [Documentation]  Get sensor threshold values.
    [Arguments]  ${busctl_command}  ${dbus_threshold}

    # Description of argument(s):
    # busctl_command    BMC busctl introspect command.
    # dbus_threshold    Threshold keys such as FatalHigh, FatalLow, etc for mapping threshold value to the particular sensor.

    FOR  ${sensor_threshold}  IN  @{dbus_threshold.keys()}
      ${ssh_response}=  BMC Execute Command  ${busctl_command}
      ${ssh_response}=  Convert To List  ${ssh_response}
      ${ssh_response}=  Get From List  ${ssh_response}  0
      ${ssh_response}=  Split String  ${ssh_response}  \n
      ${ssh_response_index}=  get_subsequent_value_from_list  ${ssh_response}  ${sensor_threshold}
      ${ssh_response_index}=  Convert To String  ${ssh_response_index}[0]
      ${ssh_response}=  Get From List  ${ssh_response}  ${ssh_response_index}
      ${split_threshold_line}=  Split String  ${ssh_response}
      ${threshold_value}=  Get From List  ${split_threshold_line}  3
      Set To Dictionary  ${dbus_threshold}  ${sensor_threshold}  ${threshold_value}
    END

    [Return]  ${dbus_threshold}


Check Reading Value Length
    [Documentation]  Check reading value length was within the limit.
    [Arguments]  ${sensor_reading}  ${sensor_id}  ${sensor_unit}

    # Description of argument(s):
    # sensor_reading    Sensor reading value.
    # sensor_id         Sensor name.
    # sensor_unit       Sensor unit like for fan it will be rpm.

    # Reading value will have dot.
    # Hence value before dot was taken as integer reading value and after dot was taken as fractional reading value.
    # For Fan, Integer reading value limit needs to be within 6 and for other sensor type integer reading value limit should be within 4.
    # Fractional reading value for all sensor type(including fan) limit should be within 4.

    @{reading_value}=  Split String  ${sensor_reading}  .
    ${integer_reading_value}=  Get From List  ${reading_value}  0
    ${fractional_reading_value}=  Get From List  ${reading_value}  1
    ${integer_value_length}=  Get Length  ${integer_reading_value}
    ${fractional_value_length}=  Get Length  ${fractional_reading_value}
    ${fan_sensor_status}=  Run Keyword And Return Status  Should Be Equal As Strings  ${sensor_unit}  RPM
    Run Keyword If  '${fan_sensor_status}' == 'True'
    ...    Run Keyword And Continue On Failure  Should Be True  ${integer_value_length} < 6
    ...    message= ${sensor_id} sensor reading length was more than 5. Integer Reading value Length is ${integer_value_length}(${integer_reading_value})
    ...  ELSE
    ...    Run Keyword And Continue On Failure  Should Be True  ${integer_value_length} < 4
    ...    message= ${sensor_id} sensor reading length was more than 3. Integer Reading value Length is ${integer_value_length}(${integer_reading_value})
      
    Run Keyword And Continue On Failure  Should Be True  ${fractional_value_length} < 5
    ...  message= ${sensor_id} sensor reading length was more than 4. Fractional Reading value Length is ${fractional_value_length}(${fractional_reading_value})


Validate Threshold Values Are Properly Assigned As Per IPMI Spec
    [Documentation]  Threshold values needs to be assigned properly as per IPMI spec.
    [Arguments]  ${sensor_id_sensor_threshold_mapping}

    FOR  ${sensor_id}  IN  @{sensor_id_sensor_threshold_mapping}
      ${sensor_threshold_values}=  Get From Dictionary  ${sensor_id_sensor_threshold_mapping}  ${sensor_id}
      ${sensor_threshold_values_length}=  Get Length  ${sensor_threshold_values}
      Continue For Loop If  ${sensor_threshold_values_length} <= 1
      Validate Threshold Values  ${sensor_threshold_values}  ${sensor_id}
    END


# Keywords for converting sensor name as per ipmi spec
Convert Sensor Name As Per IPMI Spec
    [Documentation]  As per IPMI spec, sensor id in IPMI sensor command needs to be in 16 bytes only but in dbus it can be any length.
    ...  Hence it will grep only first 16 bytes of sensor name got from dbus.
    [Arguments]  ${sensor_name}

    # Description of argument(s):
    # sensor_name - Sensor name got from dbus.

    @{characters_hex_lst}=  Create List
    ${expected_byte}=  Set Variable  16

    ${tmp_lst}=  split_string_create_list  ${sensor_name}

    FOR  ${i}  IN  @{tmp_lst}
      ${character_hex_value}=  Evaluate  hex(ord("${i}"))
      Append To List  ${characters_hex_lst}  ${character_hex_value}
    END

    ${bytes_length}=  Get Length  ${characters_hex_lst}
    ${bytes_length}=  Convert To Integer  ${bytes_length}
    ${expected_byte}=  Convert To Integer  ${expected_byte}

    ${sensors_name}=  Run Keyword If  ${bytes_length} > ${expected_byte}
    ...    Reduce Byte And Convert To String  ${characters_hex_lst}  ${expected_byte}
    ...  ELSE
    ...    Convert Hex Values To String  ${characters_hex_lst}

    [Return]  ${sensors_name}


Reduce Byte And Convert To String
    [Documentation]  Reduce bytes and convert string.
    [Arguments]  ${characters_hex_lst}  ${expected_byte}

    # Description of argument(s):
    # characters_hex_lst - List of hexa decimal values for the sensor name.
    # expected_byte - Number of expected bytes(16) as per ipmi spec for sensor name.

    @{new_lst}=  Create List

    FOR  ${value}  IN RANGE  0  ${expected_byte}
      ${hex_value}=  Get From List  ${characters_hex_lst}  ${value}
      Append To List  ${new_lst}  ${hex_value}
    END

    ${sensors_name}=  Convert Hex Values To String  ${new_lst}

    [Return]  ${sensors_name}


Convert Hex Values To String
    [Documentation]  Convert bytes to string.
    [Arguments]  ${characters_hex_lst}

    # Description of argument(s):
    # characters_hex_lst - List of hexa decimal values for the sensor name.

    @{tmp_lst}=  Create List

    FOR  ${hex_values}  IN  @{characters_hex_lst}
      ${hex_number}=  Remove String  ${hex_values}  0x
      ${character}=  Evaluate  bytes.fromhex("${hex_number}")
      ${string}=  Decode Bytes To String  ${character}  ASCII
      Append To List  ${tmp_lst}  ${string}
    END

    ${sensors_name}=  convert_list_to_string  ${tmp_lst}

    [Return]  ${sensors_name}


# Keywords For Checking Threshold Values Are Properly Assigned As Per IPMI Spec.
# As per IPMI spec, threshold value should not be equal and lower values should be lower within its key and upper value should
# higher within its key.
# It should be like below,
# For lower -  lnr < lcr < lnc  
# For upper -  unc < ucr < unr
Validate Threshold Values
    [Documentation]  Compare threshold values.
    [Arguments]  ${sensor_threshold_values}  ${sensor_id}

    # Description of argument(s):
    # sensor_threshold_values    Sensor threshold value dictionary.
    # sensor_id                  Sensor name.
    @{threshold_values}=  Create List

    ${threshold_keys}=  Get Dictionary Keys  ${sensor_threshold_values}  sort_keys=False

    ${sensor_threshold_length}=  Get Length  ${threshold_keys}

    FOR  ${key}  IN RANGE  ${sensor_threshold_length}-1
      ${threshold_key_1}=  Get From List  ${threshold_keys}  ${key}
      ${threshold_value_1}=  Get From Dictionary  ${sensor_threshold_values}  ${threshold_key_1}
      ${key_1}=  Evaluate  ${key}+${1}
      ${threshold_key_2}=  Get From List  ${threshold_keys}  ${key_1}
      ${threshold_value_2}=  Get From Dictionary  ${sensor_threshold_values}  ${threshold_key_2}
      Run Keyword And Continue On Failure  Should Be True  ${threshold_value_1} < ${threshold_value_2}
      ...  message= ${sensor_id} threshold value : ${threshold_key_1} - ${threshold_value_1} and ${threshold_key_2} - ${threshold_value_2}.
    END