*** Settings ***
Documentation  Sensor Related Keywords.

Resource         resource.robot
Library          utils.py
Library          sensor_info_record.py
Variables        ../data/sensor_details.py

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

Create A Dictionary With Sensor Name And Service Path URI
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
      ${service_name_index_value}=  get_subsequent_value_from_list  ${bmc_response_output_list}
      ...  ${service_name}
      ${service_name_index_value}=  Get From List  ${service_name_index_value}  0
      ${service_name_with_sensor_list}=  Get From List  ${bmc_response_output_list}
      ...  ${service_name_index_value}
      ${service_name_with_sensor_list}=  Split String  ${service_name_with_sensor_list}  \n
      ${sensor_uri_list_index}=  get_subsequent_value_from_list  ${service_name_with_sensor_list}
      ...  /xyz/openbmc_project/sensors
      FOR  ${list_index}  IN  @{sensor_uri_list_index}
        ${sensors_uri_list}=  Get From List  ${service_name_with_sensor_list}  ${list_index}
        ${sensor_uri_index}=  Get String Index  ${sensors_uri_list}  /
        ${sensors_uri}=  Set Variable  ${sensors_uri_list[${sensor_uri_index}:]}
        Append To List  ${object_path_uri_list}  ${sensors_uri}
      END
      FOR  ${sensor_id}  IN  @{sensor_id_list}
        ${sensor_id_index_value}=  get_subsequent_value_from_list  ${object_path_uri_list}  ${sensor_id}
        ${sensor_id_index_value_status}=  Run Keyword And Return Status  Should Not Be Empty
        ...  ${sensor_id_index_value}
        Continue For Loop If  ${sensor_id_index_value_status} == False
        ${sensor_id_in_dict}=  Evaluate  "${sensor_id}" in ${sensor_name_service_path_uri_dict}
        Continue For Loop If  ${sensor_id_in_dict} == True
        FOR  ${index}  IN  @{sensor_id_index_value}
          ${dbus_sensor_id}=  Get From List  ${object_path_uri_list}  ${index}
          ${dbus_sensor_id}=  Split String  ${dbus_sensor_id}  /
          ${dbus_sensor_id}=  Get From List  ${dbus_sensor_id}  -1
          ${dbus_sensor_name_status}=  Run Keyword And Return Status  Should Be Equal  ${dbus_sensor_id}
          ...  ${sensor_id}
          Continue For Loop If  ${dbus_sensor_name_status} == False
          Set To Dictionary  ${sensor_name_service_path_uri_dict}  ${dbus_sensor_id}  ${service_name}
        END
      END
    END

    [Return]  ${sensor_name_service_path_uri_dict}  ${object_path_uri_list}

Create A Dictionary With Sensor Name And Object Path URI
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
        ${dbus_sensor_name_status}=  Run Keyword And Return Status  Should Be Equal  ${dbus_sensor_id}
        ...  ${sensor_id}
        Run Keyword If  '${dbus_sensor_name_status}' == 'False'
        ...  Remove Values From List  ${sensor_id_index}  ${index}
      END
      ${sensor_id_index_value_status}=  Run Keyword And Return Status  Should Not Be Empty  ${sensor_id_index}
      Run Keyword If  '${sensor_id_index_value_status}' == 'False'
      ...  Append To List  ${sensor_service_path_not_mapped_in_sensor_tree}  ${sensor_id}
      Continue For Loop If  ${sensor_id_index_value_status} == False
      ${sensor_id_index}=  Get From List  ${sensor_id_index}  0
      ${dbus_sensor_uri}=  Get From List  ${object_path_uri_list}  ${sensor_id_index}
      Set To Dictionary  ${sensor_name_object_path_uri_dict}  ${sensor_id}  ${dbus_sensor_uri}
    END

    [Return]  ${sensor_name_object_path_uri_dict}

Create A Dictionary With Sensor ID And Dbus Command For Sensors
    [Documentation]  Create an dictionary by mapping sensor id with dbus command.
    [Arguments]  ${sensor_id_list}

    # Description of argument(s):
    # sensor_id_list        Sensor name list.

    ${sensor_name_service_path_uri_dict}  ${object_path_uri_list}=
    ...  Create A Dictionary With Sensor Name And Service Path URI  ${sensor_id_list}

    ${sensor_name_object_path_uri_dict}=
    ...  Create A Dictionary With Sensor Name And Object Path URI  ${object_path_uri_list}  ${sensor_id_list}

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
    # dbus_uri  service path.object path uri.

    # Build complete dbus command and return the command.

    ${busctl_command}=  Catenate  ${busctl_introspect_command} ${dbus_uri}
    [Return]  ${busctl_command}

Get Dbus Sensor Threshold
    [Documentation]  Get sensor threshold values.
    [Arguments]  ${busctl_command}  ${dbus_threshold}

    # Description of argument(s):
    # busctl_command    BMC busctl introspect command.
    # dbus_threshold    Threshold keys such as FatalHigh, FatalLow, etc for mapping threshold value to the
    # particular sensor.

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

Validate Default Threshold Values Alignment As Per IPMI Spec
    [Documentation]  Threshold values needs to be assigned properly as per IPMI spec.
    [Arguments]  ${sensor_id_sensor_threshold_mapping}

    # Description of argument(s):
    # sensor_id_sensor_threshold_mapping  Dictionary that contains all available sensor threshold values
    # for respective sensor id

    FOR  ${sensor_id}  ${sensor_threshold_values}  IN  &{sensor_id_sensor_threshold_mapping}
      ${sensor_threshold_values_length}=  Get Length  ${sensor_threshold_values}
      Continue For Loop If  ${sensor_threshold_values_length} <= 1
      Run Keyword And Continue On Failure  Validate Threshold Values  ${sensor_threshold_values}  ${sensor_id}
    END

Validate Sensor State For Lower Threshold Values
    [Documentation]  Check reading value with threshold value.
    [Arguments]  ${expected_state}  ${sensor_threshold_values}  ${threshold_key}  ${sensor_reading_values}
    ...  ${sensor_state}  ${sensor_id}

    # Description of argument(s):
    # expected_state            Expected sensor state based on threshold, if lcr or lnr expected state will
    #                           be cr and if lnc expected state will be nc.
    # sensor_threshold_value    Sensor threshold value from ipmi sensor command or redfish.
    # threshold_key             Threshold keys such as lnc, lcr and lnr.
    # sensor_reading_values     Sensor reading value from ipmi sensor command or redfish.
    # sensor_state              Sensor state got from ipmi sensor command or redfish.
    # sensor_id                 Sensor name.

    ${threshold_value}=  Get From Dictionary  ${sensor_threshold_values}  ${threshold_key}
    ${status}=  Run Keyword And Return Status  Should Be True  ${threshold_value} < ${sensor_reading_values}

    Run Keyword If  '${status}' == 'False'
    ...  Validate Redfish Sensor Status  ${sensor_state}  ${expected_state}  ${sensor_id}

    Set Test Variable  ${status}

Validate Sensor State For Upper Threshold Values
    [Documentation]  Check reading value with threshold value.
    [Arguments]  ${expected_state}  ${sensor_threshold_values}  ${threshold_key}  ${sensor_reading_values}
    ...  ${sensor_state}  ${sensor_id}

    # Description of argument(s):
    # expected_state            Expected sensor state based on threshold, if lcr or lnr expected state will
    #                           be cr and if lnc expected state will be nc.
    # sensor_threshold_value    Sensor threshold value from ipmi sensor command or redfish.
    # threshold_key             Threshold keys such as lnc, lcr and lnr.
    # sensor_reading_values     Sensor reading value from ipmi sensor command or redfish.
    # sensor_state              Sensor state got from ipmi sensor command or redfish.
    # sensor_id                 Sensor name.

    ${threshold_value}=  Get From Dictionary  ${sensor_threshold_values}  ${threshold_key}
    ${status}=  Run Keyword And Return Status  Should Be True  ${sensor_reading_values} < ${threshold_value}

    Run Keyword If  '${status}' == 'False'
    ...  Validate Redfish Sensor Status  ${sensor_state}  ${expected_state}  ${sensor_id}

    Set Test Variable  ${status}

Validate Redfish Sensor Status
    [Documentation]  Validate Redfish Sensor Status.
    [Arguments]  ${sensor_state}  ${expected_state}  ${sensor_id}

    # Description of argument(s):
    # sensor_state   Sensor state got from ipmi sensor command or redfish.
    # expected_state  Expected sensor state based on threshold, if ucr or unr expected state will be cr
    # and if unc expected state will be nc. If reading value was not available for an sensor
    # then expected sensor state will be 'na'.
    # sensor_id      Sensor name.

    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${sensor_state}  ${expected_state}
    ...  message=Instead of showing ${expected_state} state showing as ${sensor_state} state for ${sensor_id}.

Get Respective Sensor Property Value Via Redfish
    [Documentation]  Return requested property for an respective redfish uri.
    [Arguments]  ${sensor_uri}  ${required_field}

    # Description of argument(s):
    # sensor_uri    redfish sensor uri.
    # required_field  sensor property name for respective redfish uri.

    ${sensor_properties}=  Redfish.Get Properties  ${sensor_uri}
    ${property_value}=  Run Keyword If  '${required_field}' == 'State' or '${required_field}' == 'Health'
    ...    Set Variable  ${sensor_properties['Status']['${required_field}']}
    ...  ELSE
    ...    Set Variable  ${sensor_properties['${required_field}']}

    [Return]  ${property_value}

Create Discrete Sensor List
    [Documentation]  Create discrete sensor list.

    @{discrete_sensor_list}=  Create List

    ${ipmi_sensor_command_response}=  Run IPMI Standard Command    sensor
    @{ipmi_sensor_response}=  Split To Lines  ${ipmi_sensor_command_response}
    FOR  ${ipmi_sensor_details}  IN  @{ipmi_sensor_response}
      ${sensor_status}=  Run Keyword And Return Status  Should Contain  ${ipmi_sensor_details}  discrete
      Continue For Loop If  '${sensor_status}' == 'False'
      @{ipmi_sensor}=  Split String  ${ipmi_sensor_details}  |
      ${get_ipmi_sensor_name}=  Get From List  ${ipmi_sensor}  0
      ${ipmi_sensor_name}=  Set Variable  ${get_ipmi_sensor_name.strip()}
      ${sensor_name}=  Replace String  ${ipmi_sensor_name}  ${SPACE}  _
      Append To List  ${discrete_sensor_list}  ${sensor_name}
    END

    [Return]  ${discrete_sensor_list}

Create Expected Sensor List
    [Documentation]  Create expected sensors list.

    ${expected_sensor_list}=  Set Variable  ${sensor_info_map['${OPENBMC_MODEL}']['HOST_BMC_SENSORS']}

    [Return]  ${expected_sensor_list}
