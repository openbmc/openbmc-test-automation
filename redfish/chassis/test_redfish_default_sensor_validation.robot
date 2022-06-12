*** Settings ***
Documentation    Redfish Default Sensor Validation

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/rest_client.robot
Resource         ../../lib/ipmi_client.robot
Resource         ../../lib/sensor_info_record.robot
Library          ../../lib/bmc_redfish_utils.py

Library          OperatingSystem
Library          Collections

Suite Setup     Suite Setup Execution
Suite Teardown  Redfish.Logout
Force Tags      Sensor_Validation

*** Variable ***
@{redfish_sensor_id_list}
&{redfish_sensor_name_sensor_uri_mapping}
&{redfish_sensor_id_sensor_threshold_mapping}
&{sensor_dbus_threshold_values}
@{redfish_sensor_uri_getting_wrong_response_code}

*** Test Case ***
Check Reading Value Was Available In Redfish
    [Documentation]  Check sensor reading value was present via redfish.
    [Tags]  Check_Reading_Value_Was_Available_In_Redfish

    Check Redfish Sensor Reading

Check Redfish Sensor Status As Enabled
    [Documentation]  Check sensor status was showing as enabled via redfish.
    [Tags]  Check_Redfish_Sensor_Status_As_Enabled

    Verify All Redfish Sensors Was Enabled

Check Redfish Sensor Threshold With D-Bus Threshold Value
    [Documentation]  Check threshold values are same in redfish and dbus.
    [Tags]  Check_Redfish_Sensor_Threshold_With_D-Bus_Threshold_Value

    Get Sensor Threshold Values Via Redfish
    Get Sensor Threshold Values via Dbus
    Compare Redfish Threshold Values With Dbus Threshold Values

Validate Redfish Sensor Health State
    [Documentation]  Check sensor health state was showing correctly via redfish.
    [Tags]  Validate_Redfish_Sensor_Health_State

    Get Sensor Threshold Values Via Redfish
    Get Sensor Reading Values And Sensor State via Redfish
    Compare Redfish Reading Value And Threshold Value And Check Sensor State Was Showing Correctly

Get List Of Sensor ID Which Not Mapped In Sensor Tree
    [Documentation]  Get sensor id list which not mapped in sensor tree.
    [Tags]  Get_List_Of_Sensor_ID_Which_Not_Mapped_In_Sensor_Tree

    ${sensor_id_count}=  Get Length  ${sensor_service_path_not_mapped_in_sensor_tree}
    Skip If  '${sensor_id_count}' == '0'
    ...  message=all sensors are having proper dbus uri.
    Run Keyword If  '${sensor_id_count}' != '0'
    ...  Run Keywords  Log  ${sensor_service_path_not_mapped_in_sensor_tree}
    ...  AND  Fail  message=Listed Sensors Are Not Having DBUS URI

Verify Redfish Sensors URI Are Not Having Invalid Response Code
    [Documentation]  Get list of sensor uri which have wrong response code.
    [Tags]  Verify_Redfish_Sensors_URI_Are_Not_Having_Invalid_Response_Code

    ${wrong_response_code}=  Get Length  ${redfish_sensor_uri_getting_wrong_response_code}

    Run Keyword If  '${wrong_response_code}' != '0'
    ...  Run Keywords  Log  ${redfish_sensor_uri_getting_wrong_response_code}
    ...  AND  Fail  message=Listed Sensors Are Having Wrong Redfish Response Code.

Compare Redfish Sensors Name Against IPMI Sensors Name
    [Documentation]  Compare redfish sensor id with IPMI sensor name.
    [Tags]  Compare_Redfish_Sensors_Name_Against_IPMI_Sensors_Name

    Get Sensor List From Redfish And IPMI
    Check All Sensors Present In Redfish Was Showing In IPMI Sensor List

Check Default Threshold Values Are Alligned Properly
    [Documentation]  Threshold values should not be same and it should be properly assigned as per ipmi spec.
    [Tags]  Check_Default_Threshold_Values_Are_Alligned_Properly

    Get Sensor Threshold Values Via Redfish
    Validate Threshold Values Are Properly Assigned As Per IPMI Spec  ${redfish_sensor_id_sensor_threshold_mapping}

*** Keywords ***
Suite Setup Execution
    [Documentation]  Do suite setup execution.

    Redfish Power On  stack_mode=skip

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

    ${chassis_members_list}=  redfish_utils.get_member_list  /redfish/v1/Chassis/
    FOR  ${chassis_member}  IN  @{chassis_members_list}
      ${sensor_uri_list}=  redfish_utils.get_member_list  ${chassis_member}/Sensors
      FOR  ${sensor_uri}  IN  @{sensor_uri_list}
        ${resp}=  OpenBMC Get Request  ${sensor_uri}
        Run Keyword If  '${resp.status_code}' != '200'
        ...  Append To List  ${redfish_sensor_uri_getting_wrong_response_code}  ${sensor_uri}
        Continue For Loop If  ${resp.status_code} != 200
        ${sensor_id}=  Get Sensor ID    ${sensor_uri}
        ${discrete_sensor_status}=  Run Keyword And Return Status  List Should Not Contain Value  ${discrete_sensor_list}  ${sensor_id}
        Continue For Loop If  '${discrete_sensor_status}' == 'False'
        ${sensor_uri_status}=  Run Keyword And Return Status  List Should Contain Value  ${redfish_sensor_id_list}  ${sensor_id}
        Run Keyword If  '${sensor_uri_status}' == 'False'
        ...    Run Keywords  Append To List  ${redfish_sensor_id_list}  ${sensor_id}
        ...    AND  Set To Dictionary  ${redfish_sensor_name_sensor_uri_mapping}  ${sensor_id}  ${sensor_uri}
        ...  ELSE
        ...    Continue For Loop
      END
    END

    ${redfish_sensor_count}=  Get Length  ${redfish_sensor_id_list}
    Run Keyword If  '${redfish_sensor_count}' == '0'
    ...  Fatal Error  msg=response code for all the redfish sensors show incorrect or redfish sensors are not listed

    ${sensor_dbus_command_mapping}  ${sensor_service_path_not_mapped_in_sensor_tree}=
    ...  Create an Dictionary With Sensor ID And Dbus Command For Sensors Via Redfish  ${redfish_sensor_id_list}

    Set Suite Variable  ${sensor_dbus_command_mapping}
    Set Suite Variable  ${sensor_service_path_not_mapped_in_sensor_tree}

Verify All Redfish Sensors Was Enabled
    [Documentation]  Redfish sensors needs to be enabled.

    FOR  ${redfish_sensor_id}  IN  @{redfish_sensor_id_list}
      ${redfish_sensor_uri}=  Get From Dictionary  ${redfish_sensor_name_sensor_uri_mapping}  ${redfish_sensor_id}
      Validate Redfish Sensor Status As Enabled  ${redfish_sensor_uri}  ${redfish_sensor_id}
    END

Check Redfish Sensor Reading
    [Documentation]  Validate redfish sensor reading.

    FOR  ${redfish_sensor_id}  IN  @{redfish_sensor_id_list}
      ${redfish_sensor_uri}=  Get From Dictionary  ${redfish_sensor_name_sensor_uri_mapping}  ${redfish_sensor_id}
      ${redfish_sensor_reading}=  Get Redfish Sensor Reading Value  ${redfish_sensor_uri}
      ${redfish_reading}=  Convert To String  ${redfish_sensor_reading}
      ${sensor_unit}=  Get Sensor Unit  ${redfish_sensor_uri}
      Run Keyword And Continue On Failure  Should Not Be Equal As Strings  ${redfish_reading}  None
      ...  message=${redfish_sensor_id} sensor reading value was showing as null in Redfish.
      Run Keyword If  '${redfish_reading}' != 'None'
      ...  Check Reading Value Length  ${redfish_reading}  ${redfish_sensor_id}  ${sensor_unit}
    END

Get Sensor Threshold Values Via Redfish
    [Documentation]  Get sensor threshold values.

    FOR  ${redfish_sensor_id}  IN  @{redfish_sensor_id_list}
      ${redfish_sensor_id_status}=  Run Keyword And Return Status  List Should Not Contain Value  ${sensor_service_path_not_mapped_in_sensor_tree}
      ...  ${redfish_sensor_id}
      Continue For Loop If  '${redfish_sensor_id_status}' == 'False'
      ${redfish_sensor_uri}=  Get From Dictionary  ${redfish_sensor_name_sensor_uri_mapping}  ${redfish_sensor_id}
      ${sensor_dbus_uri}=  Get From Dictionary  ${sensor_dbus_command_mapping}  ${redfish_sensor_id}
      Get Redfish Sensor Threshold Value  ${redfish_sensor_uri}  ${redfish_sensor_id}
    END

Get Redfish Sensor Threshold Value
    [Documentation]  Get threshold values via redfish.
    [Arguments]  ${sensor_uri}  ${redfish_sensor_id}

    ${sensor_properties}=  Redfish.Get Properties  ${sensor_uri}
    ${sensor_threshold}=  Run Keyword And Ignore Error  Set Variable  ${sensor_properties['Thresholds']}
    ${sensor_threshold}=  Get From List  ${sensor_threshold}  1
    ${sensor_threshold_status}=  Run Keyword And Return Status  Should Not Contain  ${sensor_threshold}  KeyError:
    Run Keyword If  '${sensor_threshold_status}' != 'False'
    ...  Create Redfish Threshold Dictionary Based On Sensor ID  ${sensor_threshold}  ${redfish_sensor_id}

Create Redfish Threshold Dictionary Based On Sensor ID
    [Documentation]  Create dictionary for redfish sensor threshold values.
    [Arguments]  ${sensor_threshold}  ${sensor_id}

    &{temp_dict}=  Create Dictionary

    ${lower_non_recoverable_status}=  Run Keyword And Return Status  Should Contain  ${sensor_threshold}  LowerFatal
    ${lower_critical_status}=  Run Keyword And Return Status  Should Contain  ${sensor_threshold}  LowerCritical
    ${lower_non_critical_status}=  Run Keyword And Return Status  Should Contain  ${sensor_threshold}  LowerCaution
    ${upper_non_critical_status}=  Run Keyword And Return Status  Should Contain  ${sensor_threshold}  UpperCaution
    ${upper_critical_status}=  Run Keyword And Return Status  Should Contain  ${sensor_threshold}  UpperCritical
    ${upper_non_recoverable_status}=  Run Keyword And Return Status  Should Contain  ${sensor_threshold}  UpperFatal

    Run Keyword If  '${lower_non_recoverable_status}' == 'True'
    ...  Set To Dictionary  ${temp_dict}  LowerFatal  ${EMPTY}
    Run Keyword If  '${lower_critical_status}' == 'True'
    ...  Set To Dictionary  ${temp_dict}  LowerCritical  ${EMPTY}
    Run Keyword If  '${lower_non_critical_status}' == 'True'
    ...  Set To Dictionary  ${temp_dict}  LowerCaution  ${EMPTY}
    Run Keyword If  '${upper_non_critical_status}' == 'True'
    ...  Set To Dictionary  ${temp_dict}  UpperCaution  ${EMPTY}
    Run Keyword If  '${upper_critical_status}' == 'True'
    ...  Set To Dictionary  ${temp_dict}  UpperCritical  ${EMPTY}
    Run Keyword If  '${upper_non_recoverable_status}' == 'True'
    ...  Set To Dictionary  ${temp_dict}  UpperFatal  ${EMPTY}

    FOR  ${sensor_threshold_key}  IN  @{sensor_threshold}
      ${sensor_threshold_value}=  Get From Dictionary  ${sensor_threshold}  ${sensor_threshold_key}
      ${value}=  Get From Dictionary  ${sensor_threshold_value}  Reading
      Set To Dictionary  ${temp_dict}  ${sensor_threshold_key}  ${value}
      Set To Dictionary  ${redfish_sensor_id_sensor_threshold_mapping}  ${sensor_id}  ${temp_dict}
    END

Get Sensor Threshold Values via Dbus
    [Documentation]  Get dbus sensor threshold values.

    FOR  ${redfish_sensor_id}  IN  @{redfish_sensor_id_sensor_threshold_mapping}
      ${supported_sensor_threshold_type}=  Get From Dictionary  ${redfish_sensor_id_sensor_threshold_mapping}  ${redfish_sensor_id}
      ${dbus_uri}=  Get From Dictionary  ${sensor_dbus_command_mapping}  ${redfish_sensor_id}
      ${busctl_command}=  Build DBus Command  ${dbus_uri}
      Get DBUS Threshold Values  ${supported_sensor_threshold_type}  ${busctl_command}  ${redfish_sensor_id}
    END

Get DBUS Threshold Values
    [Documentation]  Get sensor threshold values via dbus.
    [Arguments]  ${redfish_sensor_id_sensor_threshold_mapping}  ${busctl_command}  ${redfish_sensor_id}

    &{dbus_threshold}=  Create Dictionary
    &{temp_dict}=  Create Dictionary

    ${lower_non_recoverable_status}=  Run Keyword And Return Status  Should Contain  ${redfish_sensor_threshold_values}  LowerFatal
    ${lower_critical_status}=  Run Keyword And Return Status  Should Contain  ${redfish_sensor_id_sensor_threshold_mapping}  LowerCritical
    ${lower_non_critical_status}=  Run Keyword And Return Status  Should Contain  ${redfish_sensor_id_sensor_threshold_mapping}  LowerCaution
    ${upper_non_critical_status}=  Run Keyword And Return Status  Should Contain  ${redfish_sensor_id_sensor_threshold_mapping}  UpperCaution
    ${upper_critical_status}=  Run Keyword And Return Status  Should Contain  ${redfish_sensor_id_sensor_threshold_mapping}  UpperCritical
    ${upper_non_recoverable_status}=  Run Keyword And Return Status  Should Contain  ${redfish_sensor_threshold_values}  UpperFatal

    Run Keyword If  '${lower_non_recoverable_status}' == 'True'
    ...  Set To Dictionary  ${dbus_threshold}  FatalLow  ${EMPTY}
    Run Keyword If  '${lower_critical_status}' == 'True'
    ...  Set To Dictionary  ${dbus_threshold}  CriticalLow  ${EMPTY}
    Run Keyword If  '${lower_non_critical_status}' == 'True'
    ...  Set To Dictionary  ${dbus_threshold}  WarningLow  ${EMPTY}
    Run Keyword If  '${upper_non_critical_status}' == 'True'
    ...  Set To Dictionary  ${dbus_threshold}  WarningHigh  ${EMPTY}
    Run Keyword If  '${upper_critical_status}' == 'True'
    ...  Set To Dictionary  ${dbus_threshold}  CriticalHigh  ${EMPTY}
    Run Keyword If  '${upper_non_recoverable_status}' == 'True'
    ...  Set To Dictionary  ${dbus_threshold}  FatalHigh  ${EMPTY}

    ${dbus_sensor_threshold_values}=  Get Dbus Sensor Threshold  ${busctl_command}  ${dbus_threshold}

    FOR  ${sensor_threshold_key}  IN  @{dbus_sensor_threshold_values.keys()}
      ${dbus_threshold_value}=  Get From Dictionary  ${dbus_sensor_threshold_values}  ${sensor_threshold_key}
      Run Keyword If  '${sensor_threshold_key}' == 'FatalLow'
      ...  Set To Dictionary  ${temp_dict}  LowerFatal  ${dbus_threshold_value}
      Run Keyword If  '${sensor_threshold_key}' == 'CriticalLow'
      ...  Set To Dictionary  ${temp_dict}  LowerCritical  ${dbus_threshold_value}
      Run Keyword If  '${sensor_threshold_key}' == 'WarningLow'
      ...  Set To Dictionary  ${temp_dict}  LowerCaution  ${dbus_threshold_value}
      Run Keyword If  '${sensor_threshold_key}' == 'WarningHigh'
      ...  Set To Dictionary  ${temp_dict}  UpperCaution  ${dbus_threshold_value}
      Run Keyword If  '${sensor_threshold_key}' == 'CriticalHigh'
      ...  Set To Dictionary  ${temp_dict}  UpperCritical  ${dbus_threshold_value}
      Run Keyword If  '${sensor_threshold_key}' == 'FatalHigh'
      ...  Set To Dictionary  ${temp_dict}  UpperFatal  ${dbus_threshold_value}
    END

    Set To Dictionary  ${sensor_dbus_threshold_values}  ${redfish_sensor_id}  ${temp_dict}

Get Sensor Reading Values And Sensor State via Redfish
    [Documentation]  Get reading values and sensor state via redfish.

    &{sensor_id_sensor_reading_value_mapping}=  Create Dictionary
    &{sensor_id_sensor_state_mapping}=  Create Dictionary
    Set Suite Variable  ${sensor_id_sensor_reading_value_mapping}
    Set Suite Variable  ${sensor_id_sensor_state_mapping}

    FOR  ${redfish_sensor_id}  IN  @{redfish_sensor_id_sensor_threshold_mapping}
      ${redfish_sensor_id_status}=  Run Keyword And Return Status  List Should Not Contain Value  ${sensor_service_path_not_mapped_in_sensor_tree}
      ...  ${redfish_sensor_id}
      Continue For Loop If  '${redfish_sensor_id_status}' == 'False'
      ${redfish_sensor_uri}=  Get From Dictionary  ${redfish_sensor_name_sensor_uri_mapping}  ${redfish_sensor_id}
      ${sensor_reading_value}=  Get Redfish Sensor Reading Value  ${redfish_sensor_uri}
      ${sensor_state}=  Get Redfish Sensor Health State  ${redfish_sensor_uri}
      Set To Dictionary  ${sensor_id_sensor_reading_value_mapping}  ${redfish_sensor_id}  ${sensor_reading_value}
      Set To Dictionary  ${sensor_id_sensor_state_mapping}  ${redfish_sensor_id}  ${sensor_state}
    END

Validate Redfish Sensor Status As Enabled
   [Documentation]  Check redfish sensor state was enabled.
   [Arguments]  ${redfish_sensor_uri}  ${sensor_id}

    # Description of argument(s):
    # redfish_sensor_uri    redfish sensor uri.
    # sensor_id             sensor name.

   ${redfish_sensor_state}=  Get Redfish Sensor Status  ${redfish_sensor_uri}
   Run Keyword And Continue On Failure  Should Be Equal As Strings  ${redfish_sensor_state}  Enabled
   ...  message=${sensor_id} Status Was Not Showing As Enabled In Redfish

Compare Redfish Threshold Values With Dbus Threshold Values
    [Documentation]  Compare threshold values of redfish and dbus.

    FOR  ${sensor_id}  IN  @{redfish_sensor_id_sensor_threshold_mapping}
      ${redfish_sensor_threshold_values}=  Get From Dictionary  ${redfish_sensor_id_sensor_threshold_mapping}  ${sensor_id}
      ${dbus_command_threshold_values}=  Get From Dictionary  ${sensor_dbus_threshold_values}  ${sensor_id}
      FOR  ${threshold_key}  IN  @{redfish_sensor_threshold_values.keys()}
        ${redfish_threshold_value}=  Get From Dictionary  ${redfish_sensor_threshold_values}  ${threshold_key}
        ${redfish_threshold_value}=  Convert To Number  ${redfish_threshold_value}
        ${dbus_threshold_value}=  Get From Dictionary  ${dbus_command_threshold_values}  ${threshold_key}
        ${dbus_threshold_value}=  Convert To Number  ${dbus_threshold_value}
        Run Keyword And Continue On Failure  Should Be Equal As Numbers  ${redfish_threshold_value}  ${dbus_threshold_value}
        ...  message= For ${sensor_id} ${threshold_key} threshold value for redfish - ${redfish_threshold_value} and in dbus - ${dbus_threshold_value}
      END
    END

Compare Redfish Reading Value And Threshold Value And Check Sensor State Was Showing Correctly
    [Documentation]  Compare reading value against threshold value and check sensor state.

    FOR  ${sensor_id}  IN  @{redfish_sensor_id_sensor_threshold_mapping}
      ${redfish_sensor_threshold_values}=  Get From Dictionary  ${redfish_sensor_id_sensor_threshold_mapping}  ${sensor_id}
      ${sensor_reading_values}=  Get From Dictionary  ${sensor_id_sensor_reading_value_mapping}  ${sensor_id}
      ${redfish_sensor_reading_values}=  Convert To String  ${sensor_reading_values}
      ${redfish_sensor_state}=  Get From Dictionary  ${sensor_id_sensor_state_mapping}  ${sensor_id}
      ${reading_value_status}=  Run Keyword And Return Status  Should Not Contain  ${redfish_sensor_reading_values}  None
      Run Keyword If  '${reading_value_status}' == 'False'
      ...  Check Redfish Sensor Status Was Showing Correctly  ${redfish_sensor_state}  None  ${sensor_id}
      Continue For Loop If  '${reading_value_status}' == 'False'

      ${lower_non_recoverable_status}=  Run Keyword And Return Status  Should Contain  ${redfish_sensor_threshold_values}  LowerFatal
      ${lower_critical_status}=  Run Keyword And Return Status  Should Contain  ${redfish_sensor_threshold_values}  LowerCritical
      ${lower_non_critical_status}=  Run Keyword And Return Status  Should Contain  ${redfish_sensor_threshold_values}  LowerCaution
      ${upper_non_critical_status}=  Run Keyword And Return Status  Should Contain  ${redfish_sensor_threshold_values}  UpperCaution
      ${upper_critical_status}=  Run Keyword And Return Status  Should Contain  ${redfish_sensor_threshold_values}  UpperCritical
      ${upper_non_recoverable_status}=  Run Keyword And Return Status  Should Contain  ${redfish_sensor_threshold_values}  UpperFatal
      ${status}=  Set Variable  True
      Run Keyword If  '${lower_non_recoverable_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Lower Threshold Values  Critical
      ...  ${redfish_sensor_threshold_values}  LowerFatal  ${sensor_reading_values}  ${redfish_sensor_state}  ${sensor_id}
      Run Keyword If  '${lower_critical_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Lower Threshold Values  Critical
      ...  ${redfish_sensor_threshold_values}  LowerCritical  ${sensor_reading_values}  ${redfish_sensor_state}  ${sensor_id}
      Run Keyword If  '${lower_non_critical_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Lower Threshold Values  Warning
      ...  ${redfish_sensor_threshold_values}  LowerCaution  ${sensor_reading_values}  ${redfish_sensor_state}  ${sensor_id}
      Run Keyword If  '${upper_non_recoverable_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Upper Threshold Values  Critical
      ...  ${redfish_sensor_threshold_values}  UpperFatal  ${sensor_reading_values}  ${redfish_sensor_state}  ${sensor_id}
      Run Keyword If  '${upper_critical_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Upper Threshold Values  Critical
      ...  ${redfish_sensor_threshold_values}  UpperCritical  ${sensor_reading_values}  ${redfish_sensor_state}  ${sensor_id}
      Run Keyword If  '${upper_non_critical_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Upper Threshold Values  Warning
      ...  ${redfish_sensor_threshold_values}  UpperCaution  ${sensor_reading_values}  ${redfish_sensor_state}  ${sensor_id}
      Run Keyword If  '${status}' == 'True'
      ...  Check Redfish Sensor Status Was Showing Correctly  ${redfish_sensor_state}  OK  ${sensor_id}
    END

Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Lower Threshold Values
    [Documentation]  Check reading value with threshold value.
    [Arguments]  ${expected_state}  ${redfish_sensor_threshold_values}  ${threshold_key}  ${redfish_sensor_reading_values}
    ...  ${redfish_sensor_state}  ${sensor_id}

    # Description of argument(s):
    # expected_state                     Expected sensor state based on threshold, if lnr - lowerfatal, lcr - lowercritical
    # and if lnc expected state will be lowercaution.
    # redfish_sensor_threshold_values    Sensor threshold value from redfish.
    # threshold_key                      Threshold keys such as lnc, lcr and lnr.
    # redfish_sensor_reading_values      Sensor reading value from redfish.
    # redfish_sensor_state               Sensor state got from redfish.
    # sensor_id                          Sensor name.

    ${threshold_value}=  Get From Dictionary  ${redfish_sensor_threshold_values}  ${threshold_key}
    ${status}=  Run Keyword And Return Status  Should Be True  ${threshold_value} < ${redfish_sensor_reading_values}

    Run Keyword If  '${status}' == 'False'
    ...  Check Redfish Sensor Status Was Showing Correctly  ${redfish_sensor_state}  ${expected_state}  ${sensor_id}

    Set Test Variable  ${status}

Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Upper Threshold Values
    [Documentation]  Check reading value with threshold value.
    [Arguments]  ${expected_state}  ${redfish_sensor_threshold_values}  ${threshold_key}  ${redfish_sensor_reading_values}
    ...  ${redfish_sensor_state}  ${sensor_id}

    # Description of argument(s):
    # expected_state                     Expected sensor state based on threshold, if lnr - lowerfatal, lcr - lowercritical
    # and if lnc expected state will be lowercaution.
    # redfish_sensor_threshold_values    Sensor threshold value from redfish.
    # threshold_key                      Threshold keys such as lnc, lcr and lnr.
    # redfish_sensor_reading_values      Sensor reading value from redfish.
    # redfish_sensor_state               Sensor state got from redfish.
    # sensor_id                          Sensor name.

    ${threshold_value}=  Get From Dictionary  ${redfish_sensor_threshold_values}  ${threshold_key}
    ${status}=  Run Keyword And Return Status  Should Be True  ${redfish_sensor_reading_values} < ${threshold_value}

    Run Keyword If  '${status}' == 'False'
    ...  Check Redfish Sensor Status Was Showing Correctly  ${redfish_sensor_state}  ${expected_state}  ${sensor_id}

    Set Test Variable  ${status}

Check Redfish Sensor Status Was Showing Correctly
    [Documentation]  Check sensor status was showing correctly.
    [Arguments]  ${redfish_sensor_state}  ${expected_state}  ${sensor_id}

    # Description of argument(s):
    # redfish_sensor_state  Sensor state got from redfish sensor uri.
    # expected_state        Expected sensor state based on threshold, if ucr or unr expected state will be cr and if unc expected state
    # will be nc. If reading value was not available for an sensor then expected sensor state will be na.
    # sensor_id             Sensor name.

    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${redfish_sensor_state}  ${expected_state}
    ...  message=${sensor_id} sensor state was showing wrongly in redfish. Actual Redfish State :- ${redfish_sensor_state} Expected Redfish State :- ${expected_state}

Get Sensor List From Redfish And IPMI
    [Documentation]  Create sensor list for IPMI and Redfish.

    @{available_redfish_sensor_list}=  Create List
    Set Suite Variable  ${available_redfish_sensor_list}
    @{available_ipmi_sensor_list}=  Create List
    Set Suite Variable  ${available_ipmi_sensor_list}

    ${ipmi_sensor_response}=  Run IPMI Standard Command  sensor
    @{split_ipmi_sensor_response_lines}=  Split To Lines  ${ipmi_sensor_response}
    FOR  ${sensor_properties}  IN  @{split_ipmi_sensor_response_lines}
      @{split_properties}=  Split String  ${sensor_properties}  |
      ${get_sensor_name}=  Get From List  ${split_properties}  0
      ${sensor_name}=  Evaluate  '${get_sensor_name}'.strip()
      Append To List  ${available_ipmi_sensor_list}  ${sensor_name}
    END

    ${chassis_members_list}=  redfish_utils.get_member_list  /redfish/v1/Chassis/
    FOR  ${chassis_member}  IN  @{chassis_members_list}
      ${sensor_uri_list}=  redfish_utils.get_member_list  ${chassis_member}/Sensors
      FOR  ${sensor_uri}  IN  @{sensor_uri_list}
        @{sensor_id}=  Split String  ${sensor_uri}  /
        ${sensor_id}=  Get From List  ${sensor_id}  -1
        ${sensor_id}=  Evaluate  '${sensor_id}'.replace('_',' ')
        ${sensor_id}=  Convert Sensor Name As Per IPMI Spec  ${sensor_id}
        ${list_status}=  Run Keyword And Return Status  List Should Not Contain Value  ${available_redfish_sensor_list}  ${sensor_id}
        Run Keyword If  '${list_status}' == 'True'
        ...  Append To List  ${available_redfish_sensor_list}  ${sensor_id}
      END
    END

Check All Sensors Present In Redfish Was Showing In IPMI Sensor List
    [Documentation]  Check sensor id showing in redfish was showing in IPMI.

    FOR  ${sensor_id}  IN  @{available_redfish_sensor_list}
      Run Keyword And Continue On Failure  List Should Contain Value  ${available_ipmi_sensor_list}  ${sensor_id}
      ...  message=${sensor_id} sensor was not showing in IPMI Sensor List.
    END

Get Sensor Unit
    [Documentation]  Return the sensor unit.
    [Arguments]  ${sensor_uri}

    # Description of argument(s):
    # sensor_uri    redfish sensor uri.

    ${sensor_properties}=  Redfish.Get Properties  ${sensor_uri}
    [Return]  ${sensor_properties['ReadingUnits']}

Get Sensor ID
    [Documentation]  Return the sensor id.
    [Arguments]  ${sensor_uri}

    # Description of argument(s):
    # sensor_uri    redfish sensor uri.

    ${sensor_properties}=  Redfish.Get Properties  ${sensor_uri}
    [Return]  ${sensor_properties['Id']}

Get Redfish Sensor Status
    [Documentation]  Return sensor health state.
    [Arguments]  ${sensor_uri}

    # Description of argument(s):
    # sensor_uri    redfish sensor uri.

    ${sensor_properties}=  Redfish.Get Properties  ${sensor_uri}
    [Return]  ${sensor_properties['Status']['State']}

Get Redfish Sensor Health State
    [Documentation]  Return sensor health status.
    [Arguments]  ${sensor_uri}

    # Description of argument(s):
    # sensor_uri    redfish sensor uri.

    ${sensor_properties}=  Redfish.Get Properties  ${sensor_uri}
    [Return]  ${sensor_properties['Status']['Health']}

Get Redfish Sensor Reading Value
    [Documentation]  Return redfish sensor value.
    [Arguments]  ${sensor_uri}

    # Description of argument(s):
    # sensor_uri    redfish sensor uri.

    ${sensor_properties}=  Redfish.Get Properties  ${sensor_uri}
    [Return]  ${sensor_properties['Reading']}
