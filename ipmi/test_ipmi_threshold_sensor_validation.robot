*** Settings ***
Documentation    IPMI Default Threshold Sensor Validation.

Resource         ../lib/resource.robot
Resource         ../lib/ipmi_client.robot
Resource         ../lib/sensor_info_record.robot

Library          OperatingSystem
Library          Collections

Suite Setup     Suite Setup Execution
Force Tags      Sensor_Validation

*** Variable ***
@{threshold_sensor_list}
&{ipmi_sensor_name_sensor_id_mapping}
&{ipmi_sensor_threshold_values}
&{dbus_threshold_values}

*** Test Case ***
Check Reading Value Was Available In IPMI
    [Documentation]  Check reading value was not showing as NA in IPMI sensor command.
    [Tags]  Check_Reading_Value_Was_Available_In_IPMI

    Check IPMI Threshold Sensor Reading

Check IPMI Sensor Threshold With D-Bus Threshold Value
    [Documentation]  Check IPMI sensor threshold value are same for IPMI and D-Bus.
    [Tags]  Check_IPMI_Sensor_Threshold_With_D-Bus_Threshold_Value

    Get Sensor Threshold Values Via IPMI
    Get Sensor Threshold Values Via Dbus
    Compare IPMI Threshold Values With Dbus Threshold Values

Validate IPMI Sensor Health State
    [Documentation]  Check sensor health state was showing correctly in IPMI sensor command.
    [Tags]  Validate_IPMI_Sensor_Health_State

    Get Sensor Threshold Values Via IPMI
    Get Sensor Reading Values And Sensor State via IPMI
    Compare IPMI Reading Value And Threshold Value And Check Sensor State Was Showing Correctly

Get List Of Sensor ID Which Not Mapped In Sensor Tree
    [Documentation]  Get sensor id list which not mapped in sensor tree.
    [Tags]  Get_List_Of_Sensor_ID_Which_Not_Mapped_In_Sensor_Tree

    ${sensor_id_count}=  Get Length  ${sensor_service_path_not_mapped_in_sensor_tree}
    Skip If  '${sensor_id_count}' == '0'
    ...  message=all sensors are having proper dbus uri.
    Run Keyword If  '${sensor_id_count}' != '0'
    ...  Run Keywords  Log  ${sensor_service_path_not_mapped_in_sensor_tree}
    ...  AND  Fail  message=Listed Sensors Are Not Having DBUS URI

Get List Of Sensor ID Which Doesnt Have Single Threshold Values
    [Documentation]  Get sensor id list for sensors not having single threshold values.
    [Tags]  Get_List_Of Sensor_ID_Which_Doesnt_Have_Single_Threshold_Values

    Get Sensor ID For Sensors Not Having Single Threshold
    ${sensor_id_length}=  Get Length  ${sensor_id_not_having_single_threshold}
    Skip If  '${sensor_id_length}' == '0'
    ...  message=All Sensors Are Having Threshold Values.
    Run Keyword If  '${sensor_id_length}' != '0'
    ...  Run Keywords  Log  ${sensor_id_not_having_single_threshold}
    ...  AND  Fail  message=Listed Sensors Are Not Having Single Threshold
  
Check Default Threshold Values Are Alligned Properly
    [Documentation]  Threshold values should not be same and it should be properly alligned as per ipmi spec.
    [Tags]  Check_Default_Threshold_Values_Are_Alligned_Properly

    Get Sensor Threshold Values Via IPMI
    Validate Threshold Values Are Properly Assigned As Per IPMI Spec  ${ipmi_sensor_threshold_values}

*** Keywords ***
Suite Setup Execution
    [Documentation]  Create an dbus uri dictionary, sensor list which was not mapped in sensor tree and threshold sensor name list.

    IPMI Power On  stack_mode=skip

    ${ipmi_sensor_command_response}=  Run IPMI Standard Command    sensor
    @{ipmi_sensor_response}=  Split To Lines  ${ipmi_sensor_command_response}
    FOR  ${ipmi_sensor_details}  IN  @{ipmi_sensor_response}
      ${sensor_status}=  Run Keyword And Return Status  Should Not Contain  ${ipmi_sensor_details}  discrete
      @{ipmi_sensor}=  Split String  ${ipmi_sensor_details}  |
      ${get_ipmi_sensor_name}=  Get From List  ${ipmi_sensor}  0
      ${ipmi_sensor_name}=  Set Variable  ${get_ipmi_sensor_name.strip()}
      ${sensor_name}=  Replace String  ${ipmi_sensor_name}  ${SPACE}  _
      Run Keyword If  '${sensor_status}' == 'True'
      ...    Append To List  ${threshold_sensor_list}  ${sensor_name}
    END

    ${sensor_dbus_command_mapping}  ${sensor_service_path_not_mapped_in_sensor_tree}=
    ...  Create an Dictionary With Sensor ID And Dbus Command For Sensors Via IPMI  ${threshold_sensor_list}

    Set Suite Variable  ${sensor_dbus_command_mapping}
    Set Suite Variable  ${sensor_service_path_not_mapped_in_sensor_tree}

Check IPMI Threshold Sensor Reading
    [Documentation]  Check reading value.

    FOR  ${ipmi_sensor_id}  IN  @{threshold_sensor_list}
      ${sensor_id}=  Evaluate  '${ipmi_sensor_id}'.replace('_',' ')
      ${ipmi_sensor_response}=  Run IPMI Standard Command  sensor | grep -i "${sensor_id}"
      @{ipmi_sensor}=  Split String  ${ipmi_sensor_response}  |
      ${get_ipmi_sensor_reading}=  Get From List  ${ipmi_sensor}  1
      ${get_ipmi_sensor_unit}=  Get From List  ${ipmi_sensor}  2
      ${ipmi_sensor_reading}=  Set Variable  ${get_ipmi_sensor_reading.strip()}
      ${ipmi_sensor_unit}=  Set Variable  ${get_ipmi_sensor_unit.strip()}
      Run Keyword And Continue On Failure  Should Not Be Equal As Strings  ${ipmi_sensor_reading}  na
      ...  message=${ipmi_sensor_id} sensor reading value was showing as na in ipmi.
      Run Keyword If  '${ipmi_sensor_reading}' != 'na'
      ...  Check Reading Value Length  ${ipmi_sensor_reading}  ${ipmi_sensor_id}  ${ipmi_sensor_unit}
    END

Get Sensor Threshold Values Via IPMI
    [Documentation]  Get sensor threshold values.

    ${ipmi_sensor_response}=  Run IPMI Standard Command  sensor
    FOR  ${ipmi_sensor_id}  IN  @{threshold_sensor_list}
      ${ipmi_sensor_id_status}=  Run Keyword And Return Status  List Should Not Contain Value  ${sensor_service_path_not_mapped_in_sensor_tree}
      ...  ${ipmi_sensor_id}
      Continue For Loop If  '${ipmi_sensor_id_status}' == 'False'
      ${sensor_id}=  Evaluate  '${ipmi_sensor_id}'.replace('_',' ')
      ${get_ipmi_sensor_details}=  Get Lines Containing String  ${ipmi_sensor_response}  ${sensor_id}
      @{ipmi_sensor}=  Split String  ${get_ipmi_sensor_details}  |

      &{tmp_dict}=  Create Dictionary

      ${get_ipmi_lower_non_recoverable_threshold}=  Get From List  ${ipmi_sensor}  4
      ${ipmi_lower_non_recoverable_threshold}=  Set Variable  ${get_ipmi_lower_non_recoverable_threshold.strip()}
      ${lower_non_recoverable_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_lower_non_recoverable_threshold}  na
      Run Keyword If  '${lower_non_recoverable_threshold_status}' == 'True'
      ...  Set To Dictionary  ${tmp_dict}  FatalLow  ${ipmi_lower_non_recoverable_threshold}

      ${get_ipmi_lower_critical_threshold}=  Get From List  ${ipmi_sensor}  5
      ${ipmi_lower_critical_threshold}=  Set Variable  ${get_ipmi_lower_critical_threshold.strip()}
      ${lower_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_lower_critical_threshold}  na
      Run Keyword If  '${lower_critical_threshold_status}' == 'True'
      ...  Set To Dictionary  ${tmp_dict}  CriticalLow  ${ipmi_lower_critical_threshold}

      ${get_ipmi_lower_non_critical_threshold}=  Get From List  ${ipmi_sensor}  6
      ${ipmi_lower_non_critical_threshold}=  Set Variable  ${get_ipmi_lower_non_critical_threshold.strip()}
      ${lower_non_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_lower_non_critical_threshold}  na
     Run Keyword If  '${lower_non_critical_threshold_status}' == 'True'
      ...  Set To Dictionary  ${tmp_dict}  WarningLow  ${ipmi_lower_non_critical_threshold}

      ${get_ipmi_upper_non_critical_threshold}=  Get From List  ${ipmi_sensor}  7
      ${ipmi_upper_non_critical_threshold}=  Set Variable  ${get_ipmi_upper_non_critical_threshold.strip()}
      ${upper_non_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_upper_non_critical_threshold}  na
      Run Keyword If  '${upper_non_critical_threshold_status}' == 'True'
      ...  Set To Dictionary  ${tmp_dict}  WarningHigh  ${ipmi_upper_non_critical_threshold}

      ${get_ipmi_upper_critical_threshold}=  Get From List  ${ipmi_sensor}  8
      ${ipmi_upper_critical_threshold}=  Set Variable  ${get_ipmi_upper_critical_threshold.strip()}
      ${upper_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_upper_critical_threshold}  na
      Run Keyword If  '${upper_critical_threshold_status}' == 'True'
      ...  Set To Dictionary  ${tmp_dict}  CriticalHigh  ${ipmi_upper_critical_threshold}

      ${get_ipmi_upper_non_recoverable_threshold}=  Get From List  ${ipmi_sensor}  9
      ${ipmi_upper_non_recoverable_threshold}=  Set Variable  ${get_ipmi_upper_non_recoverable_threshold.strip()}
      ${upper_non_recoverable_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_upper_non_recoverable_threshold}  na
      Run Keyword If  '${upper_non_recoverable_threshold_status}' == 'True'
      ...  Set To Dictionary  ${tmp_dict}  FatalHigh  ${ipmi_upper_non_recoverable_threshold}
      
      Set To Dictionary  ${ipmi_sensor_threshold_values}  ${ipmi_sensor_id}  ${tmp_dict}
    END

Get Sensor Threshold Values Via Dbus
    [Documentation]  Get threshold values via dbus.

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
        ${fan_sensor_identify_status}=  Run Keyword And Return Status  Should Contain  ${sensor_id}  FAN
        ${temp_sensor_identify_status}=  Run Keyword And Return Status  Should Contain  ${sensor_id}  TEMP
        ${nvme_sensor_identify_status}=  Run Keyword And Return Status  Should Contain  ${sensor_id}  NVME
        ${volt_sensor_identify_status}=  Run Keyword And Return Status  Should Contain  ${sensor_id}  VOLT
        Run Keyword If  '${fan_sensor_identify_status}' == 'True'
        ...    Compare Threshold Values For Fan  ${ipmi_threshold_value}  ${dbus_threshold_value}  ${sensor_id}  ${threshold_key}
        ...  ELSE IF  '${temp_sensor_identify_status}' == 'True' and '${nvme_sensor_identify_status}' == 'False'
        ...    Compare Temp Sensor Threshold Values  ${ipmi_threshold_value}  ${dbus_threshold_value}  ${sensor_id}  ${threshold_key}
        ...  ELSE IF  '${nvme_sensor_identify_status}' == 'True' or '${volt_sensor_identify_status}' == 'True'
        ...    Compare Nvme And Volt Sensor Threshold Values  ${ipmi_threshold_value}  ${dbus_threshold_value}  ${sensor_id}  ${threshold_key}
        ...  ELSE
        ...    Compare Other Sensor Threshold Values  ${ipmi_threshold_value}  ${dbus_threshold_value}  ${sensor_id}  ${threshold_key}
      END
    END

Compare Threshold Values For Fan
    [Documentation]  Check threshold values were showing correctly between IPMI And D-Bus.
    [Arguments]  ${ipmi_threshold_value}  ${dbus_threshold_value}  ${sensor_id}  ${threshold_key}

    # Description of argument(s):
    # ipmi_threshold_value    Sensor threshold value.
    # dbus_threshold_value    Dbus threshold value for respective sensor.
    # sensor_id               Sensor name.
    # threshold_key           Threshold keys such as unc, unr, ucr, lnc, lnr, lcr.

    ${max_dbus_threshold_value}=  Evaluate  ${dbus_threshold_value} + 100
    ${min_dbus_threshold_value}=  Evaluate  ${dbus_threshold_value} - 100

    Run Keyword And Continue On Failure  Should Be True  ${min_dbus_threshold_value} < ${ipmi_threshold_value} < ${max_dbus_threshold_value}
    ...  message= For ${sensor_id} ${threshold_key} threshold value for ipmi - ${ipmi_threshold_value} and in dbus - ${dbus_threshold_value}.

Compare Temp Sensor Threshold Values
    [Documentation]  Check threshold values between IPMI And D-Bus.
    [Arguments]  ${ipmi_threshold_value}  ${dbus_threshold_value}  ${sensor_id}  ${threshold_key}

    # Description of argument(s):
    # ipmi_threshold_value    Sensor threshold value.
    # dbus_threshold_value    Dbus threshold value for respective sensor.
    # sensor_id               Sensor name.
    # threshold_key           Threshold keys such as unc, unr, ucr, lnc, lnr, lcr.

    ${max_dbus_threshold_value}=  Evaluate  ${dbus_threshold_value} + 0.22
    ${min_dbus_threshold_value}=  Evaluate  ${dbus_threshold_value} - 0.22

    Run Keyword And Continue On Failure  Should Be True  ${min_dbus_threshold_value} < ${ipmi_threshold_value} < ${max_dbus_threshold_value}
    ...  message= For ${sensor_id} ${threshold_key} threshold value for ipmi - ${ipmi_threshold_value} and in dbus - ${dbus_threshold_value}.

Compare Nvme And Volt Sensor Threshold Values
    [Documentation]  Check threshold values between IPMI And D-Bus.
    [Arguments]  ${ipmi_threshold_value}  ${dbus_threshold_value}  ${sensor_id}  ${threshold_key}

    # Description of argument(s):
    # ipmi_threshold_value    Sensor threshold value.
    # dbus_threshold_value    Dbus threshold value for respective sensor.
    # sensor_id               Sensor name.
    # threshold_key           Threshold keys such as unc, unr, ucr, lnc, lnr, lcr.

    ${max_dbus_threshold_value}=  Evaluate  ${dbus_threshold_value} + 0.06
    ${min_dbus_threshold_value}=  Evaluate  ${dbus_threshold_value} - 0.06

    Run Keyword And Continue On Failure  Should Be True  ${min_dbus_threshold_value} < ${ipmi_threshold_value} < ${max_dbus_threshold_value}
    ...  message= For ${sensor_id} ${threshold_key} threshold value for ipmi - ${ipmi_threshold_value} and in dbus - ${dbus_threshold_value}.

Compare Other Sensor Threshold Values
    [Documentation]  Check threshold values between IPMI And D-Bus.
    [Arguments]  ${ipmi_threshold_value}  ${dbus_threshold_value}  ${sensor_id}  ${threshold_key}

    # Description of argument(s):
    # ipmi_threshold_value    Sensor threshold value.
    # dbus_threshold_value    Dbus threshold value for respective sensor.
    # sensor_id               Sensor name.
    # threshold_key           Threshold keys such as unc, unr, ucr, lnc, lnr, lcr.

    ${max_dbus_threshold_value}=  Evaluate  ${dbus_threshold_value} + 0.04
    ${min_dbus_threshold_value}=  Evaluate  ${dbus_threshold_value} - 0.04

    Run Keyword And Continue On Failure  Should Be True  ${min_dbus_threshold_value} < ${ipmi_threshold_value} < ${max_dbus_threshold_value}
    ...  message= For ${sensor_id} ${threshold_key} threshold value for ipmi - ${ipmi_threshold_value} and in dbus - ${dbus_threshold_value}.

Get Sensor Reading Values And Sensor State via IPMI
    [Documentation]  Get IPMI reading values and sensor state.

    &{ipmi_sensor_state_dict}=  Create Dictionary
    &{ipmi_sensor_reading_dict}=  Create Dictionary

    Set Suite Variable  ${ipmi_sensor_state_dict}
    Set Suite Variable  ${ipmi_sensor_reading_dict}

    ${ipmi_sensor_response}=  Run IPMI Standard Command  sensor
    FOR  ${ipmi_sensor_id}  IN  @{threshold_sensor_list}
      ${ipmi_sensor_id_status}=  Run Keyword And Return Status  List Should Not Contain Value  ${sensor_service_path_not_mapped_in_sensor_tree}
      ...  ${ipmi_sensor_id}
      Continue For Loop If  '${ipmi_sensor_id_status}' == 'False'
      ${sensor_id}=  Evaluate  '${ipmi_sensor_id}'.replace('_',' ')
      ${get_ipmi_sensor_details}=  Get Lines Containing String  ${ipmi_sensor_response}  ${sensor_id}
      @{ipmi_sensor}=  Split String  ${get_ipmi_sensor_details}  |

      ${get_ipmi_sensor_reading}=  Get From List  ${ipmi_sensor}  1
      ${ipmi_sensor_reading}=  Set Variable  ${get_ipmi_sensor_reading.strip()}
      ${get_ipmi_sensor_state}=  Get From List  ${ipmi_sensor}  3
      ${ipmi_sensor_state}=  Set Variable  ${get_ipmi_sensor_state.strip()}

      Set To Dictionary  ${ipmi_sensor_state_dict}  ${ipmi_sensor_id}  ${ipmi_sensor_state}
      Set To Dictionary  ${ipmi_sensor_reading_dict}  ${ipmi_sensor_id}  ${ipmi_sensor_reading}
    END

Compare IPMI Reading Value And Threshold Value And Check Sensor State Was Showing Correctly
    [Documentation]  Check IPMI state was properly showing in IPMI sensor.

    # Based on sensor reading value and threshold value, sensor state needs to show correctly in ipmi sensor command.

    FOR  ${sensor_id}  IN  @{ipmi_sensor_threshold_values}
      ${ipmi_threshold_values}=  Get From Dictionary  ${ipmi_sensor_threshold_values}  ${sensor_id}
      ${ipmi_sensor_state}=  Get From Dictionary  ${ipmi_sensor_state_dict}  ${sensor_id}
      ${ipmi_sensor_reading}=  Get From Dictionary  ${ipmi_sensor_reading_dict}  ${sensor_id}
      ${reading_value_status}=  Run Keyword And Return Status  Should Not Contain  ${ipmi_sensor_reading}  na
      Run Keyword If  '${reading_value_status}' == 'False'
      ...  Check IPMI Sensor Status Was Showing Correctly  ${ipmi_sensor_state}  na  ${sensor_id}
      Continue For Loop If  '${reading_value_status}' == 'False'

      # Identifying sensor keys as some sensors may not have some threshold, hence we need to identify threshold keys.
      ${lower_non_recoverable_threshold_status}=  Run Keyword And Return Status  Should Contain  ${ipmi_threshold_values}  FatalLow
      ${lower_critical_threshold_status}=  Run Keyword And Return Status  Should Contain  ${ipmi_threshold_values}  CriticalLow
      ${lower_non_critical_threshold_status}=  Run Keyword And Return Status  Should Contain  ${ipmi_threshold_values}  WarningLow
      ${upper_non_critical_threshold_status}=  Run Keyword And Return Status  Should Contain  ${ipmi_threshold_values}  WarningHigh
      ${upper_critical_threshold_status}=  Run Keyword And Return Status  Should Contain  ${ipmi_threshold_values}  CriticalHigh
      ${upper_non_recoverable_threshold_status}=  Run Keyword And Return Status  Should Contain  ${ipmi_threshold_values}  FatalHigh
      ${status}=  Set Variable  True

      # Taking from lower starting threshold value for an sensor, reading value will be compared and checked the sensor state.
      # For example, Fan sensor is having lower critical, upper critical thresholds.
      # First reading value will be compared with lower critical threshold. As we know that if reading value was equal to 
      # lower critical threshold then sensor state needs to be in cr. hence we will give expected value as cr while passing arguments
      # to the keyword.
      # likewise based on threshold value, expected state will be passing additionaly to the keyword.

      Run Keyword If  '${lower_non_recoverable_threshold_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Lower Threshold Values  cr
      ...  ${ipmi_threshold_values}  FatalLow  ${ipmi_sensor_reading}  ${ipmi_sensor_state}  ${sensor_id}
      Run Keyword If  '${lower_critical_threshold_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Lower Threshold Values  cr
      ...  ${ipmi_threshold_values}  CriticalLow  ${ipmi_sensor_reading}  ${ipmi_sensor_state}  ${sensor_id}
      Run Keyword If  '${lower_non_critical_threshold_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Lower Threshold Values  nc
      ...  ${ipmi_threshold_values}  WarningLow  ${ipmi_sensor_reading}  ${ipmi_sensor_state}  ${sensor_id}
      Run Keyword If  '${upper_non_recoverable_threshold_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Upper Threshold Values  cr
      ...  ${ipmi_threshold_values}  FatalHigh  ${ipmi_sensor_reading}  ${ipmi_sensor_state}  ${sensor_id}
      Run Keyword If  '${upper_critical_threshold_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Upper Threshold Values  cr
      ...  ${ipmi_threshold_values}  CriticalHigh  ${ipmi_sensor_reading}  ${ipmi_sensor_state}  ${sensor_id}
      Run Keyword If  '${upper_non_critical_threshold_status}' == 'True' and '${status}' == 'True'
      ...  Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Upper Threshold Values  nc
      ...  ${ipmi_threshold_values}  WarningHigh  ${ipmi_sensor_reading}  ${ipmi_sensor_state}  ${sensor_id}
      Run Keyword If  '${status}' == 'True'
      ...  Check IPMI Sensor Status Was Showing Correctly  ${ipmi_sensor_state}  ok  ${sensor_id}
    END

Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Lower Threshold Values
    [Documentation]  Check reading value with threshold value.
    [Arguments]  ${expected_state}  ${ipmi_sensor_threshold_values}  ${threshold_key}  ${ipmi_sensor_reading_values}
    ...  ${ipmi_sensor_state}  ${sensor_id}

    # Description of argument(s):
    # expected_state                 Expected sensor state based on threshold, if lcr or lnr expected state will be cr
    # and if lnc expected state will be nc.
    # ipmi_sensor_threshold_value    Sensor threshold value from ipmi sensor command.
    # threshold_key                  Threshold keys such as lnc, lcr and lnr.
    # ipmi_sensor_reading_values     Sensor reading value from ipmi sensor command.
    # ipmi_sensor_state              Sensor state got from ipmi sensor command.
    # sensor_id                      Sensor name.

    ${threshold_value}=  Get From Dictionary  ${ipmi_sensor_threshold_values}  ${threshold_key}
    ${status}=  Run Keyword And Return Status  Should Be True  ${threshold_value} < ${ipmi_sensor_reading_values}

    Run Keyword If  '${status}' == 'False'
    ...  Check IPMI Sensor Status Was Showing Correctly  ${ipmi_sensor_state}  ${expected_state}  ${sensor_id}

    Set Test Variable  ${status}

Validate Sensor State Was Showing Correctly As Per Reading Value And Threshold Value For Upper Threshold Values
    [Documentation]  Check reading value with threshold value.
    [Arguments]  ${expected_state}  ${ipmi_sensor_threshold_values}  ${threshold_key}  ${ipmi_sensor_reading_values}
    ...  ${ipmi_sensor_state}  ${sensor_id}

    # Description of argument(s):
    # expected_state                 Expected sensor state based on threshold, if ucr or unr expected state will be cr
    # and if unc expected state will be nc.
    # ipmi_sensor_threshold_value    Sensor threshold value from ipmi sensor command.
    # threshold_key                  Threshold keys such as unc, ucr and unr.
    # ipmi_sensor_reading_values     Sensor reading value from ipmi sensor command.
    # ipmi_sensor_state              Sensor state got from ipmi sensor command.
    # sensor_id                      Sensor name.

    ${threshold_value}=  Get From Dictionary  ${ipmi_sensor_threshold_values}  ${threshold_key}
    ${status}=  Run Keyword And Return Status  Should Be True  ${ipmi_sensor_reading_values} < ${threshold_value}

    Run Keyword If  '${status}' == 'False'
    ...  Check IPMI Sensor Status Was Showing Correctly  ${ipmi_sensor_state}  ${expected_state}  ${sensor_id}

    Set Test Variable  ${status}

Check IPMI Sensor Status Was Showing Correctly
    [Documentation]  Check sensor status was showing correctly.
    [Arguments]  ${ipmi_sensor_state}  ${expected_state}  ${sensor_id}

    # Description of argument(s):
    # ipmi_sensor_state  Sensor state got from ipmi sensor command.
    # expected_state     Expected sensor state based on threshold, if ucr or unr expected state will be cr and if unc expected state
    # will be nc. If reading value was not available for an sensor then expected sensor state will be na.
    # sensor_id          Sensor name.

    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${ipmi_sensor_state}  ${expected_state}
    ...  message=${sensor_id} sensor state was showing wrongly in IPMI. Actual IPMI State :- ${ipmi_sensor_state} Expected IPMI State :- ${expected_state}

Get Sensor ID For Sensors Not Having Single Threshold
    [Documentation]  Listing the sensors not having even single threshold.

    @{sensor_id_not_having_single_threshold}=  Create List
    Set Suite Variable  ${sensor_id_not_having_single_threshold}

    ${ipmi_sensor_response}=  Run IPMI Standard Command  sensor
    FOR  ${ipmi_sensor_id}  IN  @{threshold_sensor_list}
      ${sensor_id}=  Evaluate  '${ipmi_sensor_id}'.replace('_',' ')
      ${get_ipmi_sensor_details}=  Get Lines Containing String  ${ipmi_sensor_response}  ${sensor_id}
      @{ipmi_sensor}=  Split String  ${get_ipmi_sensor_details}  |

      ${get_ipmi_lower_non_recoverable_threshold}=  Get From List  ${ipmi_sensor}  4
      ${ipmi_lower_non_recoverable_threshold}=  Set Variable  ${get_ipmi_lower_non_recoverable_threshold.strip()}
      ${lower_non_recoverable_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_lower_non_recoverable_threshold}  na
      Continue For Loop If  '${lower_non_recoverable_threshold_status}' == 'True'
      
      ${get_ipmi_lower_critical_threshold}=  Get From List  ${ipmi_sensor}  5
      ${ipmi_lower_critical_threshold}=  Set Variable  ${get_ipmi_lower_critical_threshold.strip()}
      ${lower_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_lower_critical_threshold}  na
      Continue For Loop If  '${lower_critical_threshold_status}' == 'True'

      ${get_ipmi_lower_non_critical_threshold}=  Get From List  ${ipmi_sensor}  6
      ${ipmi_lower_non_critical_threshold}=  Set Variable  ${get_ipmi_lower_non_critical_threshold.strip()}
      ${lower_non_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_lower_non_critical_threshold}  na
      Continue For Loop If  '${lower_non_critical_threshold_status}' == 'True'

      ${get_ipmi_upper_non_critical_threshold}=  Get From List  ${ipmi_sensor}  7
      ${ipmi_upper_non_critical_threshold}=  Set Variable  ${get_ipmi_upper_non_critical_threshold.strip()}
      ${upper_non_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_upper_non_critical_threshold}  na
      Continue For Loop If  '${upper_non_critical_threshold_status}' == 'True'

      ${get_ipmi_upper_critical_threshold}=  Get From List  ${ipmi_sensor}  8
      ${ipmi_upper_critical_threshold}=  Set Variable  ${get_ipmi_upper_critical_threshold.strip()}
      ${upper_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_upper_critical_threshold}  na
      Continue For Loop If  '${upper_critical_threshold_status}' == 'True'

      ${get_ipmi_upper_non_recoverable_threshold}=  Get From List  ${ipmi_sensor}  9
      ${ipmi_upper_non_recoverable_threshold}=  Set Variable  ${get_ipmi_upper_non_recoverable_threshold.strip()}
      ${upper_non_recoverable_threshold_status}=  Run Keyword And Return Status  Should Not Contain
      ...  ${ipmi_upper_non_recoverable_threshold}  na
      Continue For Loop If  '${upper_non_recoverable_threshold_status}' == 'True'

      Append To List  ${sensor_id_not_having_single_threshold}  ${ipmi_sensor_id}
    END

