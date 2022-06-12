*** Settings ***

Documentation    Test suite for IPMI default threshold sensor validation.

Resource         ../lib/resource.robot
Resource         ../lib/ipmi_client.robot
Resource         ../lib/sensor_info_record.robot
Library          ../lib/sensor_info_record.py

Library          OperatingSystem
Library          Collections

Suite Setup     Suite Setup Execution
Force Tags      Default_Sensor_Validation

*** Variable ***

@{threshold_sensor_list}
@{sensors_service_path_not_mapped_in_sensor_tree}
&{sensor_dbus_command_mapping}
&{ipmi_sensor_name_sensor_id_mapping}
&{ipmi_sensor_threshold_values}
&{dbus_threshold_values}
@{expected_sensor_list}

*** Test Case ***

Check Expected Sensors Are Showing In IPMI Sensor
    [Documentation]  Check expected sensors are listing in ipmi sensor.
    [Tags]  Check_Expected_Sensors_Are_Showing_In_IPMI_Sensor

    @{expected_sensors_not_listing_in_ipmi}=  Create List

    FOR  ${sensor_id}  IN  @{expected_sensor_list}
      ${sensor_status}=  Run Keyword And Return Status  List Should Contain Value
      ...  ${threshold_sensor_list}  ${sensor_id}
      Run Keyword If  ${sensor_status} == False
      ...  Append To List  ${expected_sensors_not_listing_in_ipmi}  ${sensor_id}
    END

    ${not_listed_sensor_count}=  Get Length  ${expected_sensors_not_listing_in_ipmi}

    Run Keyword If  ${not_listed_sensor_count} != 0
    ...  Run Keywords  Log  ${expected_sensors_not_listing_in_ipmi}  AND
    ...  Fail  message=${not_listed_sensor_count} expected sensors are not showing in ipmi sensor.

Check Any Additional Sensors Are Showing In IPMI
    [Documentation]  Check Additional Sensors Are Showing In IPMI.
    [Tags]  Check_Any_Additional_Sensors_Are_Showing_In_IPMI

    ${additional_ipmi_sensors_count}=  Get Length  ${additional_ipmi_sensors}
    Run Keyword If  ${additional_ipmi_sensors_count} != 0
    ...  Run Keywords  Log  ${additional_ipmi_sensors}  AND
    ...  Fail  message=${additional_ipmi_sensors_count} additional sensor is showing in ipmi sensor command.

Check If Reading Value Available In IPMI
    [Documentation]  Check if reading value is not 'na' for IPMI sensor command.
    [Tags]  Check_If_Reading_Value_Available_In_IPMI

    Check IPMI Threshold Sensor Reading

Compare IPMI Sensor And D-Bus Threshold Values
    [Documentation]  Check IPMI sensor threshold value are same for IPMI and D-Bus.
    [Tags]  Compare_IPMI_Sensor_And_DBus_Threshold_Values

    Get Sensor Threshold Values Via Dbus
    Compare IPMI Threshold Values With Dbus Threshold Values

Validate IPMI Sensor Health State
    [Documentation]  Validate sensor health state in IPMI sensor command.
    [Tags]  Validate_IPMI_Sensor_Health_State

    Get Sensor Reading Values And Sensor State via IPMI
    Compare IPMI Reading And Threshold Values And Validate Sensor State

Get List Of Sensor ID Which Are Not Mapped In Sensor Tree
    [Documentation]  Get sensor id list which are not mapped in sensor tree.
    [Tags]  Get_List_Of_Sensor_ID_Which_Are_Not_Mapped_In_Sensor_Tree

    ${sensor_id_count}=  Get Length  ${sensors_service_path_not_mapped_in_sensor_tree}

    Run Keyword If  '${sensor_id_count}' != '0'
    ...  Run Keywords  Log  ${sensors_service_path_not_mapped_in_sensor_tree}
    ...  AND  Fail  message=${sensor_id_count} Sensors Are Not Having DBUS URI.

Get List Of Sensor ID Which Doesnt Have Single Threshold Values
    [Documentation]  Get sensor id list for not having single threshold values.
    [Tags]  Get_List_Of_Sensor_ID_Which_Doesnt_Have_Single_Threshold_Values

    Get Sensor ID For Sensors Not Having Single Threshold
    ${sensor_id_length}=  Get Length  ${sensor_id_not_having_single_threshold}
    Run Keyword If  '${sensor_id_length}' != '0'
    ...    Run Keywords  Log  ${sensor_id_not_having_single_threshold}
    ...    AND  Fail  message=${sensor_id_length} Sensors Are Not Having Single Threshold.

Check Default Threshold Values Alignment As Per IPMI Spec
    [Documentation]  Threshold values should not be same and it should be properly aligned
    ...  as per ipmi spec.
    [Tags]  Check_Default_Threshold_Values_Alignment_As_Per_IPMI_Spec

    Validate Default Threshold Values Alignment As Per IPMI Spec  ${ipmi_sensor_threshold_values}

*** Keywords ***

Suite Setup Execution
    [Documentation]  Create a dbus URI dictionary, sensor list which are not mapped in sensor tree
    ...  and a list containing threshold with sensor name..

    @{additional_ipmi_sensors}=  Create List
    Set Suite Variable  ${additional_ipmi_sensors}
    @{dbus_sensor_list}=  Create List
    &{sensor_name_dict}=  Create Dictionary

    # Host needs to be power on for validating sensors.
    IPMI Power On  stack_mode=skip  quiet=1

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

    # create an expected sensor list
    ${sensor_list}=  Create Expected Sensor List

    # Give IPMI sensor command
    # From IPMI sensor command response, skip discrete sensor and create an list which has IPMI sensor name
    # list which contains sensor name present in expected sensor list for getting dbus uri and 
    # dictionary which has IPMI sensor name as key and expected sensor list sensor name as value.
    ${ipmi_sensor_command_response}=  Run IPMI Standard Command    sensor
    @{ipmi_sensor_response}=  Split To Lines  ${ipmi_sensor_command_response}
    FOR  ${ipmi_sensor_details}  IN  @{ipmi_sensor_response}
      ${sensor_status}=  Run Keyword And Return Status  Should Not Contain  ${ipmi_sensor_details}  discrete
      Continue For Loop IF  ${sensor_status} == False
      @{ipmi_sensor}=  Split String  ${ipmi_sensor_details}  |
      ${get_ipmi_sensor_name}=  Get From List  ${ipmi_sensor}  0
      ${sensor_name}=  Set Variable  ${get_ipmi_sensor_name.strip()}
      # In few of platforms on ipmi sensor command, sensor name will gets listed without _
      # i.e, instead of listing as temp_1 in few of platforms it will list as temp 1
      # ${sensor_name}=  Replace String  ${sensor_name}  ${SPACE}  _
      FOR  ${expected_sensor_name}  IN  @{sensor_list}
        ${expected_sensor_id}=  Convert Sensor Name As Per IPMI Spec  ${expected_sensor_name}
        ${sensor_id_status}=  Run Keyword And Return Status  List Should Not Contain Value
        ...  ${expected_sensor_list}  ${expected_sensor_id}
        Run Keyword If  ${sensor_id_status} == True
        ...  Append To List  ${expected_sensor_list}  ${expected_sensor_id}
        ${host_bmc_sensor_status}=  Run Keyword And Return Status  Should Be Equal
        ...  ${sensor_name}  ${expected_sensor_id}
        Exit For Loop If  ${host_bmc_sensor_status} == True
      END
      Run Keyword If  ${host_bmc_sensor_status} == False
      ...  Run Keywords  Append To List  ${additional_ipmi_sensors}  ${sensor_name}  AND
      ...  Continue For Loop
      Append To List  ${threshold_sensor_list}  ${sensor_name}
      Append To List  ${dbus_sensor_list}  ${expected_sensor_name}
      Set To Dictionary  ${sensor_name_dict}  ${expected_sensor_name}  ${sensor_name}
    END

    # create an dbus uri for an sensor list
    # If dbus uri was not present, sensor will be mapped to sensor_not_mapped_in_sensor_tree list.
    ${dbus_command_mapping}  ${sensors_not_mapped_in_sensor_tree}=
    ...  Create A Dictionary With Sensor ID And Dbus Command For Sensors  ${dbus_sensor_list}

    FOR  ${sensor_name}  ${dbus_uri}  IN  &{dbus_command_mapping}
      ${sensor_id}=  Get From Dictionary  ${sensor_name_dict}  ${sensor_name}
      Set To Dictionary  ${sensor_dbus_command_mapping}  ${sensor_id}  ${dbus_uri}
    END

    FOR  ${sensor_name}  IN  @{sensors_not_mapped_in_sensor_tree}
      ${sensor_id}=  Get From Dictionary  ${sensor_name_dict}  ${sensor_name}
      Append To List  ${sensors_service_path_not_mapped_in_sensor_tree}  ${sensor_id}
    END

    # Get threshold values for an sensor via IPMI Sensor command.
    Get Sensor Threshold Values Via IPMI

Check IPMI Threshold Sensor Reading
    [Documentation]  Check reading value for IPMI Threshold Sensors.

    FOR  ${ipmi_sensor_id}  IN  @{threshold_sensor_list}
      ${sensor_id}=  Evaluate  '${ipmi_sensor_id}'.replace('_',' ')
      ${ipmi_sensor_response}=  Run IPMI Standard Command  sensor | grep -i "${sensor_id}"
      @{ipmi_sensor}=  Split String  ${ipmi_sensor_response}  |
      ${ipmi_sensor_reading}=  Set Variable  ${ipmi_sensor[1].strip()}
      ${ipmi_sensor_unit}=  Set Variable  ${ipmi_sensor[2].strip()}
      Run Keyword And Continue On Failure  Should Not Be Equal As Strings  ${ipmi_sensor_reading}  na
      ...  message=${ipmi_sensor_id} sensor reading value was showing as na in ipmi.
      Run Keyword If  '${ipmi_sensor_reading}' != 'na'
      ...  Run Keyword And Continue On Failure  Check Reading Value Length  ${ipmi_sensor_reading}
      ...  ${ipmi_sensor_id}  ${ipmi_sensor_unit}
    END

Get Sensor Threshold Values Via IPMI
    [Documentation]  Get sensor threshold values via ipmi.

    # Sensor threshold values will be returned as an dictionary for all sensors showing in IPMI Sensor command.
    # An tmp_dict was created for an sensor
    # From IPMI sensor command response will get threshold value and checks that threshold value is not 'na'.
    # If it was not 'na' then particular threshold value will be mapped to corresponding key.
    # At last in ipmi_sensor_threshold_values dict sensor name is mapped as key and tmp_dict will be mapped
    # as an value.
    # Example:
    # ipmi_sensor_threshold_values = {"sensor_1" : { "CriticalLow" : 20, "CriticalHigh": 40}}

    ${ipmi_sensor_response}=  Run IPMI Standard Command  sensor
    FOR  ${ipmi_sensor_id}  IN  @{threshold_sensor_list}
      ${ipmi_sensor_id_status}=  Run Keyword And Return Status  List Should Not Contain Value
      ...  ${sensors_service_path_not_mapped_in_sensor_tree}  ${ipmi_sensor_id}
      Continue For Loop If  '${ipmi_sensor_id_status}' == 'False'
      ${sensor_id}=  Evaluate  '${ipmi_sensor_id}'.replace('_',' ')
      ${get_ipmi_sensor_details}=  Get Lines Containing String  ${ipmi_sensor_response}  ${sensor_id}
      @{ipmi_sensor}=  Split String  ${get_ipmi_sensor_details}  |

      &{tmp_dict}=  Create Dictionary

      ${ipmi_lower_non_recoverable_threshold}=  Set Variable  ${ipmi_sensor[4].strip()}
      ${lower_non_recoverable_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_lower_non_recoverable_threshold}  na
      Run Keyword If  '${lower_non_recoverable_threshold_status}' == 'True'
      ...  Set To Dictionary  ${tmp_dict}  FatalLow  ${ipmi_lower_non_recoverable_threshold}

      ${ipmi_lower_critical_threshold}=  Set Variable  ${ipmi_sensor[5].strip()}
      ${lower_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_lower_critical_threshold}  na
      Run Keyword If  '${lower_critical_threshold_status}' == 'True'
      ...  Set To Dictionary  ${tmp_dict}  CriticalLow  ${ipmi_lower_critical_threshold}

      ${ipmi_lower_non_critical_threshold}=  Set Variable  ${ipmi_sensor[6].strip()}
      ${lower_non_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_lower_non_critical_threshold}  na
     Run Keyword If  '${lower_non_critical_threshold_status}' == 'True'
      ...  Set To Dictionary  ${tmp_dict}  WarningLow  ${ipmi_lower_non_critical_threshold}

      ${ipmi_upper_non_critical_threshold}=  Set Variable  ${ipmi_sensor[7].strip()}
      ${upper_non_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_upper_non_critical_threshold}  na
      Run Keyword If  '${upper_non_critical_threshold_status}' == 'True'
      ...  Set To Dictionary  ${tmp_dict}  WarningHigh  ${ipmi_upper_non_critical_threshold}

      ${ipmi_upper_critical_threshold}=  Set Variable  ${ipmi_sensor[8].strip()}
      ${upper_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_upper_critical_threshold}  na
      Run Keyword If  '${upper_critical_threshold_status}' == 'True'
      ...  Set To Dictionary  ${tmp_dict}  CriticalHigh  ${ipmi_upper_critical_threshold}

      ${ipmi_upper_non_recoverable_threshold}=  Set Variable  ${ipmi_sensor[9].strip()}
      ${upper_non_recoverable_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_upper_non_recoverable_threshold}  na
      Run Keyword If  '${upper_non_recoverable_threshold_status}' == 'True'
      ...  Set To Dictionary  ${tmp_dict}  FatalHigh  ${ipmi_upper_non_recoverable_threshold}

      Set To Dictionary  ${ipmi_sensor_threshold_values}  ${ipmi_sensor_id}  ${tmp_dict}
    END

Get Sensor Threshold Values Via Dbus
    [Documentation]  Get threshold values as an dict via dbus.

    FOR  ${sensor_name}  IN  @{ipmi_sensor_threshold_values.keys()}
      &{dbus_threshold}=  Create Dictionary
      ${sensor_dbus_uri}=  Get From Dictionary  ${sensor_dbus_command_mapping}  ${sensor_name}
      ${busctl_command}=  Build DBus Command  ${sensor_dbus_uri}
      ${threshold_keys}=  Get From Dictionary  ${ipmi_sensor_threshold_values}  ${sensor_name}
      FOR  ${threshold_key}  IN  @{threshold_keys.keys()}
        Set To Dictionary  ${dbus_threshold}  ${threshold_key}  ${EMPTY}
      END
      ${dbus_sensor_threshold_values}=  Get Dbus Sensor Threshold  ${busctl_command}  ${dbus_threshold}
      Set To Dictionary  ${dbus_threshold_values}  ${sensor_name}  ${dbus_sensor_threshold_values}
    END

Compare IPMI Threshold Values With Dbus Threshold Values
    [Documentation]  Compare threshold values of ipmi and dbus.

    FOR  ${sensor_id}  IN  @{ipmi_sensor_threshold_values}
      ${ipmi_threshold_values}=  Get From Dictionary  ${ipmi_sensor_threshold_values}  ${sensor_id}
      ${dbus_command_threshold_values}=  Get From Dictionary  ${dbus_threshold_values}  ${sensor_id}
      FOR  ${threshold_key}  IN  @{ipmi_threshold_values.keys()}
        ${ipmi_thresholds_value}=  Get From Dictionary  ${ipmi_threshold_values}  ${threshold_key}
        ${ipmi_threshold_value}=  Convert To Number  ${ipmi_thresholds_value}
        ${dbus_thresholds_value}=  Get From Dictionary  ${dbus_command_threshold_values}  ${threshold_key}
        ${dbus_threshold_value}=  Convert To Number  ${dbus_thresholds_value}
        ${fan_sensor_status}=  Run Keyword And Return Status  Should Contain  ${sensor_id}  FAN
        ${temp_sensor_status}=  Run Keyword And Return Status  Should Contain  ${sensor_id}  TEMP
        ${nvme_sensor_status}=  Run Keyword And Return Status  Should Contain  ${sensor_id}  NVME
        ${volt_sensor_status}=  Run Keyword And Return Status  Should Contain  ${sensor_id}  VOLT
        Run Keyword If  '${fan_sensor_status}' == 'True'
        ...    Compare Threshold Values For Fan  ${ipmi_threshold_value}  ${dbus_threshold_value}
        ...    ${sensor_id}  ${threshold_key}
        ...  ELSE IF  '${temp_sensor_status}' == 'True' and '${nvme_sensor_status}' == 'False'
        ...    Compare Temp Sensor Threshold Values  ${ipmi_threshold_value}  ${dbus_threshold_value}
        ...    ${sensor_id}  ${threshold_key}
        ...  ELSE IF  '${nvme_sensor_status}' == 'True' or '${volt_sensor_status}' == 'True'
        ...    Compare Nvme And Volt Sensor Threshold Values  ${ipmi_threshold_value}  ${dbus_threshold_value}
        ...    ${sensor_id}  ${threshold_key}
        ...  ELSE
        ...    Compare Other Sensor Threshold Values  ${ipmi_threshold_value}  ${dbus_threshold_value}
        ...    ${sensor_id}  ${threshold_key}
      END
    END

Compare Threshold Values For Fan
    [Documentation]  Check threshold values for fan between IPMI And D-Bus.
    [Arguments]  ${ipmi_value}  ${dbus_value}  ${sensor_id}  ${threshold_key}

    # Description of argument(s):
    # ipmi_value    Sensor threshold value.
    # dbus_value    Dbus threshold value for respective sensor.
    # sensor_id     Sensor name.
    # threshold_key Threshold keys such as unc, unr, ucr, lnc, lnr, lcr.

    ${max_value}=  Evaluate  ${dbus_value} + 100
    ${min_value}=  Evaluate  ${dbus_value} - 100

    Run Keyword And Continue On Failure  Should Be True  ${min_value} < ${ipmi_value} < ${max_value}
    ...  message= Threshold values are displayed wrong, In DBus - ${dbus_value} and IPMI - ${ipmi_value}.

Compare Temp Sensor Threshold Values
    [Documentation]  Check threshold values for temp sensors between IPMI And D-Bus.
    [Arguments]  ${ipmi_value}  ${dbus_value}  ${sensor_id}  ${threshold_key}

    # Description of argument(s):
    # ipmi_value    Sensor threshold value.
    # dbus_value    Dbus threshold value for respective sensor.
    # sensor_id     Sensor name.
    # threshold_key Threshold keys such as unc, unr, ucr, lnc, lnr, lcr.

    ${max_value}=  Evaluate  ${dbus_value} + 0.22
    ${min_value}=  Evaluate  ${dbus_value} - 0.22

    Run Keyword And Continue On Failure  Should Be True  ${min_value} < ${ipmi_value} < ${max_value}
    ...  message= Threshold values are displayed wrong, In DBus - ${dbus_value} and IPMI - ${ipmi_value}.

Compare Nvme And Volt Sensor Threshold Values
    [Documentation]  Check threshold values for nvme and volt sensors between IPMI And D-Bus.
    [Arguments]  ${ipmi_value}  ${dbus_value}  ${sensor_id}  ${threshold_key}

    # Description of argument(s):
    # ipmi_value    Sensor threshold value.
    # dbus_value    Dbus threshold value for respective sensor.
    # sensor_id     Sensor name.
    # threshold_key Threshold keys such as unc, unr, ucr, lnc, lnr, lcr.

    ${max_value}=  Evaluate  ${dbus_value} + 0.06
    ${min_value}=  Evaluate  ${dbus_value} - 0.06

    Run Keyword And Continue On Failure  Should Be True  ${min_value} < ${ipmi_value} < ${max_value}
    ...  message= Threshold values are displayed wrong, In DBus - ${dbus_value} and IPMI - ${ipmi_value}.

Compare Other Sensor Threshold Values
    [Documentation]  Check threshold values between IPMI And D-Bus.
    [Arguments]  ${ipmi_value}  ${dbus_value}  ${sensor_id}  ${threshold_key}

    # Description of argument(s):
    # ipmi_value    Sensor threshold value.
    # dbus_value    Dbus threshold value for respective sensor.
    # sensor_id     Sensor name.
    # threshold_key Threshold keys such as unc, unr, ucr, lnc, lnr, lcr.

    ${max_value}=  Evaluate  ${dbus_value} + 0.04
    ${min_value}=  Evaluate  ${dbus_value} - 0.04

    Run Keyword And Continue On Failure  Should Be True  ${min_value} < ${ipmi_value} < ${max_value}
    ...  message= Threshold values are displayed wrong, In DBus - ${dbus_value} and IPMI - ${ipmi_value}.

Get Sensor Reading Values And Sensor State via IPMI
    [Documentation]  Get IPMI reading values and sensor state.

    &{ipmi_sensor_state_dict}=  Create Dictionary
    &{ipmi_sensor_reading_dict}=  Create Dictionary

    Set Suite Variable  ${ipmi_sensor_state_dict}
    Set Suite Variable  ${ipmi_sensor_reading_dict}

    ${ipmi_sensor_response}=  Run IPMI Standard Command  sensor
    FOR  ${ipmi_sensor_id}  IN  @{threshold_sensor_list}
      ${ipmi_sensor_id_status}=  Run Keyword And Return Status  List Should Not Contain Value
      ...  ${sensors_service_path_not_mapped_in_sensor_tree}  ${ipmi_sensor_id}
      Continue For Loop If  '${ipmi_sensor_id_status}' == 'False'
      ${sensor_id}=  Evaluate  '${ipmi_sensor_id}'.replace('_',' ')
      ${get_ipmi_sensor_details}=  Get Lines Containing String  ${ipmi_sensor_response}  ${sensor_id}
      @{ipmi_sensor}=  Split String  ${get_ipmi_sensor_details}  |

      ${ipmi_sensor_reading}=  Set Variable  ${ipmi_sensor[1].strip()}
      ${ipmi_sensor_state}=  Set Variable  ${ipmi_sensor[3].strip()}

      Set To Dictionary  ${ipmi_sensor_state_dict}  ${ipmi_sensor_id}  ${ipmi_sensor_state}
      Set To Dictionary  ${ipmi_sensor_reading_dict}  ${ipmi_sensor_id}  ${ipmi_sensor_reading}
    END

Compare IPMI Reading And Threshold Values And Validate Sensor State
    [Documentation]  Check IPMI state was properly showing in IPMI sensor.

    # Based on sensor reading value and threshold value, sensor state needs to show correctly in
    # ipmi sensor command.

    FOR  ${sensor_id}  IN  @{ipmi_sensor_threshold_values}
      ${ipmi_threshold_values}=  Get From Dictionary  ${ipmi_sensor_threshold_values}  ${sensor_id}
      ${ipmi_sensor_state}=  Get From Dictionary  ${ipmi_sensor_state_dict}  ${sensor_id}
      ${ipmi_sensor_reading}=  Get From Dictionary  ${ipmi_sensor_reading_dict}  ${sensor_id}
      ${reading_value_status}=  Run Keyword And Return Status  Should Not Contain  ${ipmi_sensor_reading}  na
      Run Keyword If  '${reading_value_status}' == 'False'
      ...  Validate Redfish Sensor Status  ${ipmi_sensor_state}  na  ${sensor_id}
      Continue For Loop If  '${reading_value_status}' == 'False'

      # Identifying sensor keys as some sensors may not have some threshold, hence we need to identify
      # threshold keys.
      ${lower_non_recoverable_threshold_status}=  Run Keyword And Return Status  Should Contain
      ...  ${ipmi_threshold_values}  FatalLow
      ${lower_critical_threshold_status}=  Run Keyword And Return Status  Should Contain
      ...  ${ipmi_threshold_values}  CriticalLow
      ${lower_non_critical_threshold_status}=  Run Keyword And Return Status  Should Contain
      ...  ${ipmi_threshold_values}  WarningLow
      ${upper_non_critical_threshold_status}=  Run Keyword And Return Status  Should Contain
      ...  ${ipmi_threshold_values}  WarningHigh
      ${upper_critical_threshold_status}=  Run Keyword And Return Status  Should Contain
      ...  ${ipmi_threshold_values}  CriticalHigh
      ${upper_non_recoverable_threshold_status}=  Run Keyword And Return Status  Should Contain
      ...  ${ipmi_threshold_values}  FatalHigh
      ${status}=  Set Variable  True

      # Taking from lower starting threshold value for an sensor, reading value will be compared and checked
      # the sensor state.
      # For example, Fan sensor is having lower critical, upper critical thresholds.
      # First reading value will be compared with lower critical threshold. As we know that if reading value
      # was equal to lower critical threshold then sensor state needs to be in cr. hence we will give expected
      # value as cr while passing arguments to the keyword.
      # likewise based on threshold value, expected state will be passing additionaly to the keyword.

      Run Keyword If  '${lower_non_recoverable_threshold_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State For Lower Threshold Values  cr  ${ipmi_threshold_values}  FatalLow
      ...  ${ipmi_sensor_reading}  ${ipmi_sensor_state}  ${sensor_id}
      Continue For Loop IF  ${status} == False
      Run Keyword If  '${lower_critical_threshold_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State For Lower Threshold Values  cr  ${ipmi_threshold_values}  CriticalLow
      ...  ${ipmi_sensor_reading}  ${ipmi_sensor_state}  ${sensor_id}
      Continue For Loop IF  ${status} == False
      Run Keyword If  '${lower_non_critical_threshold_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State For Lower Threshold Values  nc  ${ipmi_threshold_values}  WarningLow
      ...  ${ipmi_sensor_reading}  ${ipmi_sensor_state}  ${sensor_id}
      Continue For Loop IF  ${status} == False
      Run Keyword If  '${upper_non_recoverable_threshold_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State For Upper Threshold Values  cr  ${ipmi_threshold_values}  FatalHigh
      ...  ${ipmi_sensor_reading}  ${ipmi_sensor_state}  ${sensor_id}
      Continue For Loop IF  ${status} == False
      Run Keyword If  '${upper_critical_threshold_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State For Upper Threshold Values  cr  ${ipmi_threshold_values}  CriticalHigh
      ...  ${ipmi_sensor_reading}  ${ipmi_sensor_state}  ${sensor_id}
      Continue For Loop IF  ${status} == False
      Run Keyword If  '${upper_non_critical_threshold_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State For Upper Threshold Values  nc  ${ipmi_threshold_values}  WarningHigh
      ...  ${ipmi_sensor_reading}  ${ipmi_sensor_state}  ${sensor_id}
      Continue For Loop IF  ${status} == False
      Run Keyword If  '${status}' == 'True'
      ...  Validate Redfish Sensor Status  ${ipmi_sensor_state}  ok  ${sensor_id}
    END

Get Sensor ID For Sensors Not Having Single Threshold
    [Documentation]  Get the list of the sensors IDs which are do not have single threshold value.

    ${ipmi_sensor_response}=  Run IPMI Standard Command  sensor
    ${sensor_id_not_having_single_threshold}=  Create Sensor List Not Having Single Threshold
    ...  ${ipmi_sensor_response}  ${threshold_sensor_list}
    Set Suite Variable  ${sensor_id_not_having_single_threshold}
