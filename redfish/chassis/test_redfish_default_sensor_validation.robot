*** Settings ***
Documentation    Redfish Default Sensor Validation.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/rest_client.robot
Library          ../../lib/bmc_redfish_utils.py
Resource         ../../lib/ipmi_client.robot
Resource         ../../lib/sensor_info_record.robot
Library          ../../lib/sensor_info_record.py

Library          OperatingSystem
Library          Collections

Suite Setup     Suite Setup Execution
Suite Teardown  Redfish.Logout
Force Tags      Sensor_Validation

*** Variable ***
@{redfish_threshold_key}  LowerCritical  LowerCaution  UpperCaution  UpperCritical
@{redfish_sensor_id_list}
&{redfish_sensor_name_sensor_uri_mapping}
&{redfish_sensor_id_threshold_mapping}
&{sensor_dbus_threshold_values}
@{redfish_sensor_uri_getting_wrong_response_code}

*** Test Case ***
Check Expected Sensors Are Showing In Redfish
    [Documentation]  Check expected sensors are showing in Redfish.
    [Tags]  Check_Expected_Sensors_Are_Showing_In_Redfish

    @{expected_sensors_not_listing_in_redfish}=  Create List

    ${expected_sensor_list}=  Create Expected Sensor List
    FOR  ${sensor_id}  IN  @{expected_sensor_list}
      ${sensor_status}=  Run Keyword And Return Status  List Should Contain Value  ${redfish_sensor_id_list}
      ...  ${sensor_id}
      Run Keyword If  ${sensor_status} == False
      ...  Append To List  ${expected_sensors_not_listing_in_redfish}  ${sensor_id}
    END

    ${expected_sensors_not_listing_count}=  Get Length  ${expected_sensors_not_listing_in_redfish}

    Run Keyword If  ${expected_sensors_not_listing_count} != 0
    ...  Run Keywords  Log  ${expected_sensors_not_listing_in_redfish}  AND
    ...  Fail  message=${expected_sensors_not_listing_count} expected sensors are not showing in redfish.

Check Any Additional Sensors Are Showing In Redfish
    [Documentation]  Check additional sensors are showing in Redfish.
    [Tags]  Check_Any_Additional_Sensors_Are_Showing_In_Redfish

    ${additional_redfish_sensors_count}=  Get Length  ${additional_redfish_sensors}
    Run Keyword If  ${additional_redfish_sensors_count} != 0
    ...  Run Keywords  Log  ${additional_redfish_sensors}  AND
    ...  Fail  message=${additional_redfish_sensors_count} additional sensor is showing in redfish.

Check Sensor Reading Value Is Available In Redfish
    [Documentation]  Check sensor reading value is present via Redfish.
    [Tags]  Check_Reading_Value_Is_Available_In_Redfish

    Check Redfish Sensor Reading

Check Redfish Sensor Status Is Enabled
    [Documentation]  Check redfish sensor status is enabled via Redfish.
    [Tags]  Check_Redfish_Sensor_Status_Is_Enabled

    Verify All Redfish Sensors Are Enabled

Check Redfish Sensor Threshold With D-Bus Threshold Value
    [Documentation]  Check threshold values are same in Redfish and Dbus.
    [Tags]  Check_Redfish_Sensor_Threshold_With_D-Bus_Threshold_Value

    Get Sensor Threshold Values via Dbus
    Compare Redfish Threshold Values With Dbus Threshold Values

Validate Redfish Sensor Health State
    [Documentation]  Check sensor health state is showing correctly via Redfish.
    [Tags]  Validate_Redfish_Sensor_Health_State

    Get Sensor Reading Values And Sensor State via Redfish
    Validate Redfish Reading And Threshold Value And Sensor State

Get List Of Sensor ID Which Are Not Mapped In Sensor Tree
    [Documentation]  Get sensor id list which are not mapped in sensor tree.
    [Tags]  Get_List_Of_Sensor_ID_Which_Are_Not_Mapped_In_Sensor_Tree

    ${sensor_id_count}=  Get Length  ${sensor_service_path_not_mapped_in_sensor_tree}
    Run Keyword If  '${sensor_id_count}' != '0'
    ...  Run Keywords  Log  ${sensor_service_path_not_mapped_in_sensor_tree}
    ...  AND  Fail  message=${sensor_id_count} Sensors Are Not Having DBUS URI.

Verify Redfish Sensors URI Are Not Having Invalid Response Code
    [Documentation]  Get list of sensor uri which have wrong response code.
    [Tags]  Verify_Redfish_Sensors_URI_Are_Not_Having_Invalid_Response_Code

    ${wrong_response_code}=  Get Length  ${redfish_sensor_uri_getting_wrong_response_code}

    Run Keyword If  '${wrong_response_code}' != '0'
    ...  Run Keywords  Log  ${redfish_sensor_uri_getting_wrong_response_code}
    ...  AND  Fail  message=${wrong_response_code} Sensors Are Having Wrong Redfish Response Code.

Check Default Threshold Values Are Alligned Properly
    [Documentation]  Threshold values should not be same and it should be properly assigned as per ipmi spec.
    [Tags]  Check_Default_Threshold_Values_Are_Alligned_Properly

    Validate Default Threshold Values Alignment As Per IPMI Spec
    ...  ${redfish_sensor_id_threshold_mapping}

Get List Of Sensor ID Which Doesnt Have Single Threshold Values
    [Documentation]  Get sensor id list for not having single threshold values.
    [Tags]  Get_List_Of_Sensor_ID_Which_Doesnt_Have_Single_Threshold_Values

    Get Sensor ID For Sensors Not Having Single Threshold
    ${sensor_id_length}=  Get Length  ${threshold_sensor_not_having_single_threshold_list}
    Run Keyword If  '${sensor_id_length}' != '0'
    ...    Run Keywords  Log  ${threshold_sensor_not_having_single_threshold_list}
    ...    AND  Fail  message=${sensor_id_length} Sensors Are Not Having Single Threshold.

*** Keywords ***
Suite Setup Execution
    [Documentation]  Do suite setup execution.

    # Host needs to be in powered on state for sensor validation.
    Redfish.Login
    Redfish Power On  stack_mode=skip  quiet=1

    @{additional_redfish_sensors}=  Create List
    Set Suite Variable  ${additional_redfish_sensors}

    # In sensor_details.py file give the full sensor name which are to be present in server.
    # Give sensor name that was present in dbus uri.
    # For example,
    # Take OPENBMC_MODEL as romulus.
    # xyz.openbmc_project.FanSensor /xyz/openbmc_project/sensors/fan_tach/fan_1
    # In data/sensor_details.py file give sensor name as fan_1.
    # Example,
    # sensor_info_map = {
    #     "romulus":{
    #           "HOST_BMC_SENSORS":[
    #               "fan_1",
    #        ]
    #    }
    # }

    # An expected sensor list will be created, this list will be validated to make sure
    # that all the expected sensors are listing in redfish.
    ${expected_sensor_list}=  Create Expected Sensor List


    # Discrete sensor list will be created to skip the discrete sensors from validation.
    ${discrete_sensor_list}=  Create Discrete Sensor List

    # An member list will be created from chassis uri(/redfish/v1/Chassis)
    # From that member list, all the members will be iterated until sensors
    # (/redfish/v1/Chassis/chassis_id/Sensors) and create an member list which was saved as 
    # sensor_uri_list
    # From sensor_uri_list all the uri's will be iterated and first it will check response code
    # If response code was 200, then it will get sensor id and matches with discrete sensor list.
    # If it was not an discrete sensor then further it will check whether that particular sensor id
    # is present in expected_sensor_list. 
    # If present it will append to redfish_sensor_id_list list
    # and in redfish_sensor_name_sensor_uri_mapping dictionary sensor_id will be mapped as an key
    # and respective redfish sensor uri will be mapped as an value.
    # Suppose if sensor is not present in expected sensor list then it will append that sensor id
    # to additional_redfish_sensor list and will continue to check next sensor uri.
    ${chassis_members_list}=  redfish_utils.get_member_list  /redfish/v1/Chassis/
    FOR  ${chassis_member}  IN  @{chassis_members_list}
      ${sensor_uri_list}=  redfish_utils.get_member_list  ${chassis_member}/Sensors
      FOR  ${sensor_uri}  IN  @{sensor_uri_list}
        ${resp}=  OpenBMC Get Request  ${sensor_uri}
        Run Keyword If  '${resp.status_code}' != '200'
        ...  Append To List  ${redfish_sensor_uri_getting_wrong_response_code}  ${sensor_uri}
        Continue For Loop If  ${resp.status_code} != 200
        ${sensor_id}=  Get Respective Sensor Property Value Via Redfish  ${sensor_uri}  Id
        ${discrete_sensor_status}=  Run Keyword And Return Status  List Should Not Contain Value
        ...  ${discrete_sensor_list}  ${sensor_id}
        Continue For Loop If  '${discrete_sensor_status}' == 'False'
        ${host_bmc_sensor_status}=  Run Keyword And Return Status  List Should Contain Value
        ...  ${expected_sensor_list}  ${sensor_id}
        Run Keyword If  ${host_bmc_sensor_status} == False
        ...  Run Keywords  Append To List  ${additional_redfish_sensors}  ${sensor_id}  AND
        ...  Continue For Loop
        ${sensor_uri_status}=  Run Keyword And Return Status  List Should Contain Value
        ...  ${redfish_sensor_id_list}  ${sensor_id}
        Run Keyword If  '${sensor_uri_status}' == 'False'
        ...    Run Keywords  Append To List  ${redfish_sensor_id_list}  ${sensor_id}
        ...    AND  Set To Dictionary  ${redfish_sensor_name_sensor_uri_mapping}  ${sensor_id}
        ...    ${sensor_uri}
        ...  ELSE
        ...    Continue For Loop
      END
    END

    ${redfish_sensor_count}=  Get Length  ${redfish_sensor_id_list}
    Run Keyword If  '${redfish_sensor_count}' == '0'
    ...  Fatal Error  msg=Either redfish sensors are not listed or response code is incorrect.
    
    # An dbus uri dictionary will be created for the sensors present in redfish_sensor_id_list.
    # Suppose, if dbus uri was not found for an sensor then that sensor id will be segregated and
    # it will be appended to sensor_service_path_not_mapped_in_sensor_tree list.
    ${sensor_dbus_command_mapping}  ${sensor_service_path_not_mapped_in_sensor_tree}=
    ...  Create A Dictionary With Sensor ID And Dbus Command For Sensors  ${redfish_sensor_id_list}

    Set Suite Variable  ${sensor_dbus_command_mapping}
    Set Suite Variable  ${sensor_service_path_not_mapped_in_sensor_tree}

    # Getting all default threshold values from redfish.
    Get Sensor Threshold Values Via Redfish

Verify All Redfish Sensors Are Enabled
    [Documentation]  Redfish sensors needs to be enabled.

    FOR  ${redfish_sensor_id}  IN  @{redfish_sensor_id_list}
      ${redfish_sensor_uri}=  Get From Dictionary  ${redfish_sensor_name_sensor_uri_mapping}
      ...  ${redfish_sensor_id}
      Validate Redfish Sensor Status Is Enabled  ${redfish_sensor_uri}  ${redfish_sensor_id}
    END

Validate Redfish Sensor Status Is Enabled
   [Documentation]  Check redfish sensor state is enabled.
   [Arguments]  ${redfish_sensor_uri}  ${sensor_id}

    # Description of argument(s):
    # redfish_sensor_uri    redfish sensor uri.
    # sensor_id             sensor name.

   ${redfish_sensor_state}=  Get Respective Sensor Property Value Via Redfish  ${redfish_sensor_uri}  State
   Run Keyword And Continue On Failure  Should Be Equal As Strings  ${redfish_sensor_state}  Enabled
   ...  message=${sensor_id} Status Was Not Showing As Enabled In Redfish

Check Redfish Sensor Reading
    [Documentation]  Validate redfish sensor reading.

    FOR  ${redfish_sensor_id}  IN  @{redfish_sensor_id_list}
      ${redfish_sensor_uri}=  Get From Dictionary  ${redfish_sensor_name_sensor_uri_mapping}
      ...  ${redfish_sensor_id}
      ${redfish_sensor_reading}=  Get Respective Sensor Property Value Via Redfish  ${redfish_sensor_uri}
      ...  Reading
      ${redfish_reading}=  Convert To String  ${redfish_sensor_reading}
      ${sensor_unit}=  Get Respective Sensor Property Value Via Redfish  ${redfish_sensor_uri}  ReadingUnits
      Run Keyword And Continue On Failure  Should Not Be Equal As Strings  ${redfish_reading}  None
      ...  message=${redfish_sensor_id} sensor reading value was showing as null in Redfish.
      Run Keyword If  '${redfish_reading}' != 'None'
      ...  Run Keyword And Continue On Failure  Check Reading Value Length  ${redfish_reading}
      ...  ${redfish_sensor_id}  ${sensor_unit}
    END

Get Sensor Threshold Values Via Redfish
    [Documentation]  Get sensor threshold values.

    FOR  ${redfish_sensor_id}  IN  @{redfish_sensor_id_list}
      ${redfish_sensor_id_status}=  Run Keyword And Return Status  List Should Not Contain Value
      ...  ${sensor_service_path_not_mapped_in_sensor_tree}  ${redfish_sensor_id}
      Continue For Loop If  '${redfish_sensor_id_status}' == 'False'
      ${redfish_sensor_uri}=  Get From Dictionary  ${redfish_sensor_name_sensor_uri_mapping}
      ...  ${redfish_sensor_id}
      ${sensor_dbus_uri}=  Get From Dictionary  ${sensor_dbus_command_mapping}  ${redfish_sensor_id}
      Get Redfish Sensor Threshold Value  ${redfish_sensor_uri}  ${redfish_sensor_id}
    END

Get Redfish Sensor Threshold Value
    [Documentation]  Get threshold values via redfish.
    [Arguments]  ${sensor_uri}  ${redfish_sensor_id}

    # Description of argument(s):
    # sensor_uri           redfish sensor uri.
    # redfish_sensor_id    sensor name.

    ${sensor_properties}=  Redfish.Get Properties  ${sensor_uri}
    ${sensor_threshold}=  Run Keyword And Ignore Error  Set Variable  ${sensor_properties['Thresholds']}
    ${sensor_threshold}=  Get From List  ${sensor_threshold}  1
    ${sensor_threshold_status}=  Run Keyword And Return Status
    ...  Should Not Contain  ${sensor_threshold}  KeyError:
    Run Keyword If  '${sensor_threshold_status}' != 'False'
    ...  Create Redfish Threshold Dictionary Based On Sensor ID  ${sensor_threshold}  ${redfish_sensor_id}

Create Redfish Threshold Dictionary Based On Sensor ID
    [Documentation]  Create dictionary for redfish sensor threshold values.
    [Arguments]  ${sensor_threshold}  ${sensor_id}

    # Description of argument(s):
    # sensor_threshold    sensor threshold dictionary.
    # sensor_id           sensor name.

    &{threshold_dict}=  Create Dictionary

    FOR  ${key}  IN  @{redfish_threshold_key}
      ${key_status}=  Run Keyword And Return Status  Dictionary Should Contain Key
      ...  ${sensor_threshold}  ${key}
      Continue For Loop IF  ${key_status} == False
      ${sensor_threshold_value}=  Get From Dictionary  ${sensor_threshold}  ${key}
      ${value}=  Get From Dictionary  ${sensor_threshold_value}  Reading
      ${threshold_value_status}=  Run Keyword And Return Status  Should Not Be Equal  ${value}  ${None}
      Continue For Loop If  ${threshold_value_status} == False
      Set To Dictionary  ${threshold_dict}  ${key}  ${value}
    END

    Set To Dictionary  ${redfish_sensor_id_threshold_mapping}  ${sensor_id}  ${threshold_dict}

Get Sensor Threshold Values via Dbus
    [Documentation]  Get dbus sensor threshold values.

    FOR  ${redfish_sensor_id}  ${supported_sensor_threshold_keys}  IN  &{redfish_sensor_id_threshold_mapping}
      ${dbus_uri}=  Get From Dictionary  ${sensor_dbus_command_mapping}  ${redfish_sensor_id}
      ${busctl_command}=  Build DBus Command  ${dbus_uri}
      Get DBUS Threshold Values  ${supported_sensor_threshold_keys}  ${busctl_command}  ${redfish_sensor_id}
    END

Get DBUS Threshold Values
    [Documentation]  Get sensor threshold values via dbus.
    [Arguments]  ${supported_sensor_threshold_keys}  ${busctl_command}  ${redfish_sensor_id}

    # Description of argument(s):
    # supported_sensor_threshold_type    supported sensor threshold keys.
    # sensor_id                          sensor name.

    &{dbus_threshold}=  Create Dictionary
    &{threshold_key_dict}=  Create Dictionary

    ${lower_non_recoverable_status}=  Run Keyword And Return Status  Should Contain
    ...  ${supported_sensor_threshold_keys}  LowerFatal
    ${lower_critical_status}=  Run Keyword And Return Status  Should Contain
    ...  ${supported_sensor_threshold_keys}  LowerCritical
    ${lower_non_critical_status}=  Run Keyword And Return Status  Should Contain
    ...  ${supported_sensor_threshold_keys}  LowerCaution
    ${upper_non_critical_status}=  Run Keyword And Return Status  Should Contain
    ...  ${supported_sensor_threshold_keys}  UpperCaution
    ${upper_critical_status}=  Run Keyword And Return Status  Should Contain
    ...  ${supported_sensor_threshold_keys}  UpperCritical
    ${upper_non_recoverable_status}=  Run Keyword And Return Status  Should Contain
    ...  ${supported_sensor_threshold_keys}  UpperFatal

    # Mostly threshold based sensor will have either one threshold value or it may have two threshold
    # or it can have more that two threshold values and alsoe if we see the redfish threshold value 
    # property name it will list like LowerCritical, LowerCaution..etc.
    # But in dbus if we see the threshold value property name it will list like FatalLow, CriticalLow..etc
    # So we need to identify which threshold value was showing in redfish in order to get 
    # corresponding dbus threshold value.
    # Based on that identification , an threshold key dictionary will be created for dbus. 
    # For example,
    # supported_sensor_threshold_keys = {"sensor_1" : {"UpperCritical": 40}}
    # If we need to get corresponding dbus parameter value for UpperCritical parameter 
    # in dbus that property will be named as CriticalHigh.
    # so an dictionary will be created for dbus, 
    # dbus_sensor_threshold_values = {"sensor_1" : {"CriticalHigh": ${EMPTY}}}
    # this dictionary will be passed to getting dbus threshold value keyword.

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

    # After getting dbus threshold value, if we look the dictionary it will have dbus property name as key.
    # dbus_sensor_threshold_values = {"sensor_1" : {"CriticalHigh": 96}} 
    # so we were again changing that property name to redfish property name.
    # sensor_dbus_threshold_values = {"sensor_1" : {"UpperCritical": 96}}

    FOR  ${sensor_threshold_key}  ${dbus_threshold_value}  IN  &{dbus_sensor_threshold_values}
      Run Keyword If  '${sensor_threshold_key}' == 'FatalLow'
      ...  Set To Dictionary  ${threshold_key_dict}  LowerFatal  ${dbus_threshold_value}
      Run Keyword If  '${sensor_threshold_key}' == 'CriticalLow'
      ...  Set To Dictionary  ${threshold_key_dict}  LowerCritical  ${dbus_threshold_value}
      Run Keyword If  '${sensor_threshold_key}' == 'WarningLow'
      ...  Set To Dictionary  ${threshold_key_dict}  LowerCaution  ${dbus_threshold_value}
      Run Keyword If  '${sensor_threshold_key}' == 'WarningHigh'
      ...  Set To Dictionary  ${threshold_key_dict}  UpperCaution  ${dbus_threshold_value}
      Run Keyword If  '${sensor_threshold_key}' == 'CriticalHigh'
      ...  Set To Dictionary  ${threshold_key_dict}  UpperCritical  ${dbus_threshold_value}
      Run Keyword If  '${sensor_threshold_key}' == 'FatalHigh'
      ...  Set To Dictionary  ${threshold_key_dict}  UpperFatal  ${dbus_threshold_value}
    END

    Set To Dictionary  ${sensor_dbus_threshold_values}  ${redfish_sensor_id}  ${threshold_key_dict}

Get Sensor Reading Values And Sensor State via Redfish
    [Documentation]  Get reading values and sensor state via redfish.

    &{sensor_id_sensor_reading_value_mapping}=  Create Dictionary
    &{sensor_id_sensor_state_mapping}=  Create Dictionary
    Set Suite Variable  ${sensor_id_sensor_reading_value_mapping}
    Set Suite Variable  ${sensor_id_sensor_state_mapping}

    FOR  ${redfish_sensor_id}  IN  @{redfish_sensor_id_threshold_mapping}
      ${redfish_sensor_id_status}=  Run Keyword And Return Status  List Should Not Contain Value
      ...  ${sensor_service_path_not_mapped_in_sensor_tree}
      ...  ${redfish_sensor_id}
      Continue For Loop If  '${redfish_sensor_id_status}' == 'False'
      ${redfish_sensor_uri}=  Get From Dictionary  ${redfish_sensor_name_sensor_uri_mapping}
      ...  ${redfish_sensor_id}
      ${sensor_reading_value}=  Get Respective Sensor Property Value Via Redfish  ${redfish_sensor_uri}
      ...  Reading
      ${sensor_state}=  Get Respective Sensor Property Value Via Redfish  ${redfish_sensor_uri}  Health
      Set To Dictionary  ${sensor_id_sensor_reading_value_mapping}  ${redfish_sensor_id}
      ...  ${sensor_reading_value}
      Set To Dictionary  ${sensor_id_sensor_state_mapping}  ${redfish_sensor_id}  ${sensor_state}
    END

Compare Redfish Threshold Values With Dbus Threshold Values
    [Documentation]  Compare threshold values of redfish and dbus.

    FOR  ${sensor_id}  ${redfish_sensor_threshold_values}  IN  &{redfish_sensor_id_threshold_mapping}
      ${dbus_command_threshold_values}=  Get From Dictionary  ${sensor_dbus_threshold_values}  ${sensor_id}
      FOR  ${threshold_key}  ${redfish_threshold_value}  IN  &{redfish_sensor_threshold_values}
        ${threshold_value}=  Convert To Number  ${redfish_threshold_value}
        ${dbus_threshold_value}=  Get From Dictionary  ${dbus_command_threshold_values}  ${threshold_key}
        ${dbus_threshold}=  Convert To Number  ${dbus_threshold_value}
        Run Keyword And Continue On Failure  Should Be Equal As Numbers  ${threshold_value}  ${dbus_threshold}
        ...  message= Threshold Value Was Showing Wrongly DBus(${dbus_threshold}), Redfish(${threshold_value})
      END
    END

Validate Redfish Reading And Threshold Value And Sensor State
    [Documentation]  Compare reading value against threshold value and check sensor state.

    FOR  ${sensor_id}  ${redfish_sensor_threshold_values}  IN  &{redfish_sensor_id_threshold_mapping}
      ${sensor_reading_values}=  Get From Dictionary  ${sensor_id_sensor_reading_value_mapping}  ${sensor_id}
      ${redfish_sensor_reading_values}=  Convert To String  ${sensor_reading_values}
      ${redfish_sensor_state}=  Get From Dictionary  ${sensor_id_sensor_state_mapping}  ${sensor_id}
      ${reading_value_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${redfish_sensor_reading_values}  None
      Run Keyword If  '${reading_value_status}' == 'False'
      ...  Validate Redfish Sensor Status  ${redfish_sensor_state}  None  ${sensor_id}
      Continue For Loop If  '${reading_value_status}' == 'False'

      ${lower_non_recoverable_status}=  Run Keyword And Return Status  Should Contain
      ...  ${redfish_sensor_threshold_values}  LowerFatal
      ${lower_critical_status}=  Run Keyword And Return Status  Should Contain
      ...  ${redfish_sensor_threshold_values}  LowerCritical
      ${lower_non_critical_status}=  Run Keyword And Return Status  Should Contain
      ...  ${redfish_sensor_threshold_values}  LowerCaution
      ${upper_non_critical_status}=  Run Keyword And Return Status  Should Contain
      ...  ${redfish_sensor_threshold_values}  UpperCaution
      ${upper_critical_status}=  Run Keyword And Return Status  Should Contain
      ...  ${redfish_sensor_threshold_values}  UpperCritical
      ${upper_non_recoverable_status}=  Run Keyword And Return Status  Should Contain
      ...  ${redfish_sensor_threshold_values}  UpperFatal
      ${status}=  Set Variable  True

      Run Keyword If  '${lower_non_recoverable_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State For Lower Threshold Values  Critical  ${redfish_sensor_threshold_values}
      ...  LowerFatal  ${sensor_reading_values}  ${redfish_sensor_state}  ${sensor_id}
      Continue For Loop IF  ${status} == False
      Run Keyword If  '${lower_critical_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State For Lower Threshold Values  Critical  ${redfish_sensor_threshold_values}
      ...  LowerCritical  ${sensor_reading_values}  ${redfish_sensor_state}  ${sensor_id}
      Continue For Loop IF  ${status} == False
      Run Keyword If  '${lower_non_critical_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State For Lower Threshold Values  Warning  ${redfish_sensor_threshold_values}
      ...  LowerCaution  ${sensor_reading_values}  ${redfish_sensor_state}  ${sensor_id}
      Continue For Loop IF  ${status} == False
      Run Keyword If  '${upper_non_recoverable_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State For Upper Threshold Values  Critical  ${redfish_sensor_threshold_values}
      ...  UpperFatal  ${sensor_reading_values}  ${redfish_sensor_state}  ${sensor_id}
      Continue For Loop IF  ${status} == False
      Run Keyword If  '${upper_critical_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State For Upper Threshold Values  Critical  ${redfish_sensor_threshold_values}
      ...  UpperCritical  ${sensor_reading_values}  ${redfish_sensor_state}  ${sensor_id}
      Continue For Loop IF  ${status} == False
      Run Keyword If  '${upper_non_critical_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State For Upper Threshold Values  Warning  ${redfish_sensor_threshold_values}
      ...  UpperCaution  ${sensor_reading_values}  ${redfish_sensor_state}  ${sensor_id}
      Continue For Loop IF  ${status} == False
      Run Keyword If  '${status}' == 'True'
      ...  Validate Redfish Sensor Status  ${redfish_sensor_state}  OK  ${sensor_id}
    END

Get Sensor ID For Sensors Not Having Single Threshold
    [Documentation]  Listing the sensors not having even single threshold.

    @{threshold_sensor_not_having_single_threshold_list}=  Create List
    Set Test Variable  ${threshold_sensor_not_having_single_threshold_list}

    FOR  ${redfish_sensor_id}  IN  @{redfish_sensor_id_list}
      ${redfish_sensor_uri}=  Get From Dictionary  ${redfish_sensor_name_sensor_uri_mapping}
      ...  ${redfish_sensor_id}
      ${sensor_properties}=  Redfish.Get Properties  ${redfish_sensor_uri}
      ${sensor_threshold}=  Run Keyword And Ignore Error  Set Variable  ${sensor_properties['Thresholds']}
      ${sensor_threshold}=  Get From List  ${sensor_threshold}  1
      ${sensor_threshold_status}=  Run Keyword And Return Status
      ...  Should Not Contain  ${sensor_threshold}  KeyError:
      Run Keyword If  '${sensor_threshold_status}' == 'False'
      ...  Run Keywords  Append To List  ${threshold_sensor_not_having_single_threshold_list}
      ...  ${redfish_sensor_id}  AND  Continue For Loop
      FOR  ${key}  IN  @{redfish_threshold_key}
        ${key_status}=  Run Keyword And Return Status  Dictionary Should Contain Key
        ...  ${sensor_threshold}  ${key}
        ${threshold_value_status}=  Run Keyword If  ${key_status} == True
        ...  Check Threshold Key Is Having Threshold Value  ${sensor_threshold}  ${key}
        Exit For Loop If  "${threshold_value_status}" == "True"
      END
      Run Keyword If  "${sensor_threshold_status}" == "False"
      ...  Append To List  ${threshold_sensor_not_having_single_threshold_list}  ${redfish_sensor_id}
    END

Check Threshold Key Is Having Threshold Value
    [Documentation]  Check threshold keys is having threshold value.
    [Arguments]  ${sensor_threshold}  ${key}

    # Description of argument(s):
    # sensor_threshold  sensor threshold dictionary
    # key - sensor threshold key such as LowerCritical, LowerFatal,etc..

    ${sensor_threshold_value}=  Get From Dictionary  ${sensor_threshold}  ${key}
    ${value}=  Get From Dictionary  ${sensor_threshold_value}  Reading
    ${threshold_value_status}=  Run Keyword And Return Status  Should Not Be Equal  ${value}  ${None}

    [Return]  ${threshold_value_status}