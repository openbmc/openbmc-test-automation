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

Library             Collections
Library             ../lib/ipmi_utils.py
Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Variables           ../data/ipmi_raw_cmd_table.py

Test Teardown       FFDC On Test Case Fail


*** Variables ***

${NETWORK_RESTART_TIME}    30s
@{thresholds_list}         lcr   lnc   unc   ucr


*** Test Cases ***

Cold Reset Via IPMI
    [Documentation]  Verify Cold Reset via IPMI.
    [Tags]  Cold_Reset_Via_IPMI

    # Cold Reset Via IPMI raw command.
    Run External IPMI Raw Command  ${IPMI_RAW_CMD['Cold Reset']['reset'][0]}

    # Get the BMC Status.
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Unpingable
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Operational

    # Verify if BMC restarted with Get Device ID command.

    ${resp}=  Run External IPMI Raw Command  ${IPMI_RAW_CMD['Device ID']['Get'][0]}
    Should Not Contain  ${resp}  ${IPMI_RAW_CMD['Device ID']['Get'][1]}


Cold Reset With Invalid Data Request Via IPMI
    [Documentation]  Verify Cold Reset with invalid data request via IPMI.
    [Tags]  Cold_Reset_With_Invalid_Data_Request_Via_IPMI

    # Verify cold reset with invalid length of the request data and expect error.
    ${resp}=  Run Keyword and Expect Error  *Request data length invalid*
    ...  Run External IPMI Raw Command  ${IPMI_RAW_CMD['Cold Reset']['reset'][0]} 0x00


Verify Cold Reset Impact On Sensor Threshold Via IPMI
    [Documentation]  Modify sensor threshold, perform cold reset,
    ...  and verify if sensor threshold reverts back to initial value.
    [Tags]  Verify_Cold_Reset_Impact_On_Sensor_Threshold_Via_IPMI

    # Get sensor list.
    ${Sensor_list}=  Get Sensor List

    # Get initial sensor threshold readings.
    ${initial_sensor_threshold}  ${sensor_name}=  Get The Sensor Name And Threshold  ${sensor_list}

    # Identify sensor threshold values to modify.
    ${threshold_dict}=  Identify Sensor Threshold Values   ${initial_sensor_threshold}

    # Set sensor threshold for given sensor and compare with initial reading.
    ${set_sensor_threshold}=  Set Sensor Threshold For given Sensor  ${threshold_dict}  ${sensor_name}
    Should Not Be Equal  ${set_sensor_threshold}  ${initial_sensor_threshold}

    # Execute cold reset command via IPMI and check status.
    Run External IPMI Raw Command  ${IPMI_RAW_CMD['Cold Reset']['reset'][0]}
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Unpingable
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Operational

    # Get sensor data for the sensor identified.
    ${data_after_coldreset}=  Wait Until Keyword Succeeds  2 min  30 sec
    ...  Run IPMI Standard Command   sensor | grep -i RPM | grep "${sensor_name}"

    # Get sensor threshold readings after BMC restarts.
    ${sensor_threshold_after_reset}  ${sensor_name_after_reset}=
    ...  Get The Sensor Name And Threshold  ${data_after_coldreset}

    # Compare with initial sensor threshold values.
    Should Be Equal  ${sensor_threshold_after_reset}  ${initial_sensor_threshold}


*** Keywords ***

Get Sensor List
    [Documentation]  To get the list of sensors via IPMI sensor list.

    # BMC may take time to populate all the sensors once BMC Cold reset completes.
    ${data}=  Wait Until Keyword Succeeds  2 min  30 sec
    ...  Run IPMI Standard Command   sensor | grep -i RPM

    [Return]  ${data}

Identify Sensor
    [Documentation]  To fetch first sensor listed from sensor list IPMI command and return the sensor.
    [Arguments]  ${data}

    # Description of Argument(s):
    # ${data}     All the sensors listed with ipmi sensor list command.

    # Find Sensor detail of sensor list first entry.

    ${data}=  Split To Lines  ${data}
    ${data}=  Set Variable  ${data[0]}

    [Return]  ${data}


Get The Sensor Reading And Name
    [Documentation]  To get the sensor reading of the given sensor using IPMI.
    [Arguments]  ${Sensors_all}

    # Description of Argument(s):
    # ${Sensors_all}     All the sensors listed with ipmi sensor list command.

    # Split Sensor details in a list.

    ${sensor}=  Identify Sensor  ${Sensors_all}
    ${data}=  Split String  ${sensor}  |

    # Locate the sensor name.
    ${sensor_name}=  Set Variable  ${data[0]}
    # Function defined in lib/utils.py.
    ${sensor_name}=  Remove Whitespace  ${sensor_name}

    [Return]  ${data}  ${sensor_name}


Get The Sensor Name And Threshold
    [Documentation]  To get the sensor threshold for given sensor using IPMI.
    [Arguments]  ${Sensor_list}

    # Description of Argument(s):
    #    ${Sensor_list}    All the sensors listed with ipmi sensor list command.

    # Gets the sensor data and sensor name for the required sensor.
    ${data}  ${sensor_name}=  Get The Sensor Reading And Name  ${Sensor_list}
    # Gets the threshold values in a list.
    ${threshold}=  Set Variable  ${data[5:9]}

    [Return]  ${threshold}  ${sensor_name}


Identify Sensor Threshold Values
    [Documentation]  Identify New Sensor Threshold Values with adding 100 to old threshold values.
    [Arguments]  ${old_threshold}

    # Description of Argument(s):
    #    ${old_threshold}   original threshold values list of the given sensor.

    # Retrieves modified threshold values of the original threshold value.
    ${threshold_dict}=  Modify And Fetch Threshold  ${old_threshold}  ${thresholds_list}

    [Return]  ${threshold_dict}


Set Sensor Threshold For given Sensor
    [Documentation]  Set Sensor Threshold for given sensor with given Upper and Lower critical
    ...              and non-critical values Via IPMI.
    [Arguments]  ${threshold_list}  ${sensor}

    # Description of Argument(s):
    #    ${threshold_list}    New thresholds to be set, eg: [ na, 101, 102, 103 ]
    #    ${sensor}            Sensor name, eg: SENSOR_1, FAN_1

    # The return data will be newly set threshold value for the given sensor.

    # Set critical and non-critical values for the given sensor.
    FOR  ${criticals}  IN  @{threshold_list}
        # Set Lower/Upper critical and non-critical values if a threshold is available.
        Run keyword if  '${threshold_list['${criticals}']}' != 'na'
        ...  Run IPMI Standard Command
        ...  sensor thresh "${sensor}" ${criticals} ${threshold_list['${criticals}']}
        # Allow Network restart sleep time for the readings to get reflected.
        Sleep  ${NETWORK_RESTART_TIME}
    END

    # Get sensor list for the sensor name identified.
    ${data}=  Wait Until Keyword Succeeds  2 min  30 sec
    ...  Run IPMI Standard Command   sensor | grep -i RPM | grep "${sensor}"

    # Get new threshold value set from sensor list.
    ${threshold_new}  ${sensor_name}=  Get The Sensor Name And Threshold  ${data}

    [Return]  ${threshold_new}
