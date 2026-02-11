*** Settings ***
Documentation       This suite tests IPMI Cold Reset in OpenBMC.
...
...                 The Cold reset command directs the Responder to perform
...                 a 'Cold Reset' action, which causes default setting of
...                 interrupt enables, event message generation,sensor scanning,
...                 threshold values, and other 'power up' default state to be restored.
...
...                 The script consist of 3 testcases:
...                 -  Cold_Reset_Via_IPMI
...                 -  Cold_Reset_With_Invalid_Data_Request_Via_IPMI
...                 -  Verify_Cold_Reset_Impact_On_Sensor_Threshold_Via_IPMI
...
...                 The script verifies command execution for cold reset,
...                 invalid data request verification of cold reset and
...                 impact on sensor threshold value change with cold reset.
...
...                 The script changes sensor threshold value for Fan sensor,
...                 executes cold reset IPMI command,
...                 compares sensor threshold values of initial and reading after cold reset.
...
...                 Request data for cold reset present under data/ipmi_raw_cmd_table.py

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Library             Collections
Library             ../lib/ipmi_utils.py
Variables           ../data/ipmi_raw_cmd_table.py

Test Teardown       FFDC On Test Case Fail

Test Tags           IPMI_Cold_Reset

*** Variables ***

${NETWORK_RESTART_TIME}    30s
@{thresholds_list}         lcr   lnc   unc   ucr


*** Test Cases ***

Cold Reset Via IPMI
    [Documentation]  Verify Cold Reset via IPMI.
    [Tags]  Cold_Reset_Via_IPMI

    # Cold Reset Via IPMI raw command.
    Run IPMI Command  ${IPMI_RAW_CMD['Cold Reset']['reset'][0]}

    # Get the BMC Status.
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Unpingable
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Operational

    # Verify if BMC restarted with Get Device ID command.

    ${resp}=  Run IPMI Command  ${IPMI_RAW_CMD['Device ID']['Get'][0]}
    Should Not Contain  ${resp}  ${IPMI_RAW_CMD['Device ID']['Get'][1]}


Cold Reset With Invalid Data Request Via IPMI
    [Documentation]  Verify Cold Reset with invalid data request via IPMI.
    [Tags]  Cold_Reset_With_Invalid_Data_Request_Via_IPMI

    # Verify cold reset with invalid length of the request data and expect error.
    ${resp}=  Run Keyword And Expect Error  *Request data length invalid*
    ...  Run IPMI Command  ${IPMI_RAW_CMD['Cold Reset']['reset'][0]} 0x00


Verify Cold Reset Impact On Sensor Threshold Via IPMI
    [Documentation]  Modify sensor threshold, perform cold reset,
    ...  and verify if sensor threshold reverts back to initial value.
    [Tags]  Verify_Cold_Reset_Impact_On_Sensor_Threshold_Via_IPMI

    # Get sensor list.
    ${sensor_list}=  Get Sensor List

    # Get initial sensor threshold readings.
    ${sensor_name}  ${sensor_threshold}=  Get The Sensor Name And Threshold  ${sensor_list}

    ${threshold_key_list}=  Get Dictionary Keys  ${sensor_threshold}
    ${random_threshold_key}=  Evaluate  random.choice(${threshold_key_list})  random

    ${old_threshold_value}=  Get From Dictionary  ${sensor_threshold}  ${random_threshold_key}

    # Modify Default Threshold Value For An Sensor To Set An New Threshold Value
    ${new_settable_threshold_value}=  Modify Default Sensor Threshold Value  ${old_threshold_value}

    # Set/Get sensor threshold for given sensor and compare with initial reading.
    ${new_threshold_value}=  Set And Get Sensor Threshold For Given Sensor
    ...  ${sensor_name}  ${random_threshold_key}  ${new_settable_threshold_value}

    Should Not Be Equal  ${new_threshold_value}  ${old_threshold_value}

    # Cold Reset Via IPMI raw command.
    Run IPMI Command  ${IPMI_RAW_CMD['Cold Reset']['reset'][0]}

    # Get the BMC Status.
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Unpingable
    Wait Until Keyword Succeeds  10 min  10 sec  Is BMC Operational

    # Get sensor data for the sensor identified.
    ${data_after_coldreset}=  Wait Until Keyword Succeeds  2 min  30 sec
    ...  Run IPMI Standard Command  sensor | grep -i "${sensor_name}"

    # Get sensor threshold readings after BMC restarts.
    ${threshold_value_after_reset}=  Getting Sensor Threshold Value Based On Threshold Key
    ...  ${random_threshold_key}  ${sensor_name}

    # Compare with initial sensor threshold values.
    Should Be Equal  ${threshold_value_after_reset}  ${old_threshold_value}

*** Keywords ***

Get Sensor List
    [Documentation]  To get the list of sensors via IPMI sensor list.

    # BMC may take time to populate all the sensors once BMC Cold reset completes.
    ${data}=  Wait Until Keyword Succeeds  2 min  30 sec
    ...  Run IPMI Standard Command   sensor

    RETURN  ${data}

Get The Sensor Name And Threshold
    [Documentation]  To get the sensor threshold for given sensor using IPMI.
    [Arguments]  ${sensor_list}

    # Description of Argument(s):
    #    ${sensor_list}    All the sensors listed with ipmi sensor list command.

    @{tmp_list}=  Create List

    @{sensor_list_lines}=  Split To Lines  ${sensor_list}

    # Omit the discrete sensor and create an threshold sensor name list
    FOR  ${sensor}  IN  @{sensor_list_lines}
      ${discrete_sensor_status}=  Run Keyword And Return Status  Should Contain  ${sensor}  discrete
      IF  '${discrete_sensor_status}' == 'True'  CONTINUE
      ${sensor_details}=  Split String  ${sensor}  |
      ${get_sensor_name}=  Get From List  ${sensor_details}  0
      ${sensor_name}=  Set Variable  ${get_sensor_name.strip()}
      Append To List  ${tmp_list}  ${sensor_name}
    END

    ${sensor_count}=  Get Length  ${tmp_list}

    FOR  ${RANGE}  IN RANGE  0  ${sensor_count}
      ${random_sensor}  ${sensor_threshold}=  Selecting Random Sensor Name And Threshold Value
      ...  ${tmp_list}  ${sensor_list}
      ${threshold_dict_count}=  Get Length  ${sensor_threshold}
      IF  '${threshold_dict_count}' != '0'  BREAK
      Remove Values From List  ${tmp_list}  ${random_sensor}
    END

    RETURN  ${random_sensor}  ${sensor_threshold}

Selecting Random Sensor Name And Threshold Value
    [Documentation]  Select Random Sensor Name And Threshold Values.
    [Arguments]  ${tmp_list}  ${sensor_list}

    # Selecting random sensors from sensor list
    ${random_sensor_name}=  Evaluate  random.choice(${tmp_list})  random

    # Create Dictionary For Threshold Key With Threshold Values
    &{tmp_dict}=  Create Dictionary
    ${sensor_threshold}=  Get Lines Containing String  ${sensor_list}  ${random_sensor_name}
    @{ipmi_sensor}=  Split String  ${sensor_threshold}  |
    ${get_ipmi_lower_non_recoverable_threshold}=  Get From List  ${ipmi_sensor}  4
    ${ipmi_lower_non_recoverable_threshold}=  Set Variable  ${get_ipmi_lower_non_recoverable_threshold.strip()}
    ${lower_non_recoverable_threshold_status}=  Run Keyword And Return Status  Should Not Contain
    ...  ${ipmi_lower_non_recoverable_threshold}  na
    IF  '${lower_non_recoverable_threshold_status}' == 'True'
        Set To Dictionary  ${tmp_dict}  lnr  ${ipmi_lower_non_recoverable_threshold}
    END

    ${get_ipmi_lower_critical_threshold}=  Get From List  ${ipmi_sensor}  5
    ${ipmi_lower_critical_threshold}=  Set Variable  ${get_ipmi_lower_critical_threshold.strip()}
    ${lower_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
    ...  ${ipmi_lower_critical_threshold}  na
    IF  '${lower_critical_threshold_status}' == 'True'
        Set To Dictionary  ${tmp_dict}  lcr  ${ipmi_lower_critical_threshold}
    END

    ${get_ipmi_lower_non_critical_threshold}=  Get From List  ${ipmi_sensor}  6
    ${ipmi_lower_non_critical_threshold}=  Set Variable  ${get_ipmi_lower_non_critical_threshold.strip()}
    ${lower_non_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
    ...  ${ipmi_lower_non_critical_threshold}  na
    IF  '${lower_non_critical_threshold_status}' == 'True'
        Set To Dictionary  ${tmp_dict}  lnc  ${ipmi_lower_non_critical_threshold}
    END

    ${get_ipmi_upper_non_critical_threshold}=  Get From List  ${ipmi_sensor}  7
    ${ipmi_upper_non_critical_threshold}=  Set Variable  ${get_ipmi_upper_non_critical_threshold.strip()}
    ${upper_non_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
    ...  ${ipmi_upper_non_critical_threshold}  na
    IF  '${upper_non_critical_threshold_status}' == 'True'
        Set To Dictionary  ${tmp_dict}  unc  ${ipmi_upper_non_critical_threshold}
    END

    ${get_ipmi_upper_critical_threshold}=  Get From List  ${ipmi_sensor}  8
    ${ipmi_upper_critical_threshold}=  Set Variable  ${get_ipmi_upper_critical_threshold.strip()}
    ${upper_critical_threshold_status}=  Run Keyword And Return Status  Should Not Contain
    ...  ${ipmi_upper_critical_threshold}  na
    IF  '${upper_critical_threshold_status}' == 'True'
        Set To Dictionary  ${tmp_dict}  ucr  ${ipmi_upper_critical_threshold}
    END

    ${get_ipmi_upper_non_recoverable_threshold}=  Get From List  ${ipmi_sensor}  9
    ${ipmi_upper_non_recoverable_threshold}=  Set Variable  ${get_ipmi_upper_non_recoverable_threshold.strip()}
    ${upper_non_recoverable_threshold_status}=  Run Keyword And Return Status  Should Not Contain
    ...  ${ipmi_upper_non_recoverable_threshold}  na
    IF  '${upper_non_recoverable_threshold_status}' == 'True'
        Set To Dictionary  ${tmp_dict}  unr  ${ipmi_upper_non_recoverable_threshold}
    END

    RETURN  ${random_sensor_name}  ${tmp_dict}

Modify Default Sensor Threshold Value
    [Documentation]  Modify Default Sensor Threshold Value with adding 100 to old threshold values.
    [Arguments]  ${old_threshold}

    ${new_threshold}=  Evaluate  ${old_threshold} + 100

    RETURN  ${new_threshold}

Set And Get Sensor Threshold For Given Sensor
    [Documentation]  Set/Get Sensor Threshold for given sensor Via IPMI.
    [Arguments]  ${sensor_name}  ${random_threshold_key}  ${new_settable_threshold_value}

    # Set New Threshold Value To The Randomly Selected Sensor.
    Run IPMI Standard Command
    ...  sensor thresh "${sensor_name}" ${random_threshold_key} ${new_settable_threshold_value}

    Sleep  10s

    ${sensor_new_threshold_value}=  Getting Sensor Threshold Value Based On Threshold Key
    ...  ${random_threshold_key}  ${sensor_name}

    RETURN  ${sensor_new_threshold_value}

Getting Sensor Threshold Value Based On Threshold Key
    [Documentation]  Getting Particular Sensor Threshold Value Based On Sensor Name And Threshold Key.
    [Arguments]  ${threshold_key}  ${sensor_name}

    # After Setting Threshold Value, Get New Sensor Threshold Value.
    ${new_data}=  Run IPMI Standard Command  sensor | grep -i "${sensor_name}"
    ${new_sensor_details}=  Split String  ${new_data}  |

    ${index_value}=  Set Variable If
    ...  '${threshold_key}' == 'lnr'  ${4}
    ...  '${threshold_key}' == 'lcr'  ${5}
    ...  '${threshold_key}' == 'lnc'  ${6}
    ...  '${threshold_key}' == 'unc'  ${7}
    ...  '${threshold_key}' == 'ucr'  ${8}
    ...  '${threshold_key}' == 'unr'  ${9}

    ${get_sensor_new_threshold_value}=  Get From List  ${new_sensor_details}  ${index_value}
    ${sensor_new_threshold_value}=  Set Variable  ${get_sensor_new_threshold_value.strip()}

    RETURN  ${sensor_new_threshold_value}
