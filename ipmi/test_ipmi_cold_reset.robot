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
...                 Request data for cold reset present under data/ipmi_raw_cmd_table.py
...
...                 Python basic operations under new file lib/functions.py like
...                 threshold value calculation and striping extra characters
...                 across the strings.
...
...                 The script verifies command execution for cold reset,
...                 invalid data request verification of cold reset and
...                 impact on sensor threshold value change with cold reset.
...
...                 The script changes sensor threshold value for Fan sensor,
...                 executes cold reset IPMI command,
...                 compares sensor threshold values of initial and reading after cold reset.

Library             Collections
Library             ../lib/ipmi_utils.py
Library             ../lib/var_funcs.py
Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Variables           ../data/ipmi_raw_cmd_table.py

#Test Teardown       FFDC On Test Case Fail


*** Variables ***

${NETWORK_RESTART_TIME}    30s
@{thresholds_list}         lcr   lnc   unc   ucr


*** Test Cases ***

Cold Reset Via IPMI
    [Documentation]  Verify Cold Reset Via IPMI.
    [Tags]  Cold_Reset_Via_IPMI

    # Cold Reset Via IPMI raw command
    Run External IPMI Raw Command  ${IPMI_RAW_CMD['Resets']['cold'][0]}

    # Get the BMC Status
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Unpingable
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Operational

    # Verify if BMC restarted with Get Device ID command

    ${resp}=  Run External IPMI Raw Command
    ...  ${IPMI_RAW_CMD['Device_ID']['Get'][0]}
    Should Not Contain  ${resp}  ${IPMI_RAW_CMD['Device_ID']['Get'][1]}


Cold Reset With Invalid Data Request Via IPMI
    [Documentation]  Verify Cold Reset With Invalid Data Request Via IPMI
    [Tags]  Cold_Reset_With_Invalid_Data_Request_Via_IPMI

    ${resp}=  Run Keyword and Expect Error  *Request data length invalid*
    ...  Run External IPMI Raw Command  ${IPMI_RAW_CMD['Resets']['cold_extra'][0]}
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Resets']['cold_extra'][1]}


Verify Cold Reset Impact On Sensor Threshold Via IPMI
    [Documentation]  Modify Sensor Threshold, perform cold reset and verify if sensor threshold reverts back to Initial value.
    [Tags]  Verify_Cold_Reset_Impact_On_Sensor_Threshold_Via_IPMI

    # Get Sensor List
    ${Sensor_list}=  Get Sensor List

    # Get Initial Sensor Threshold Readings
    ${initial_sensor_threshold}  ${sensor_name}=  Get The Sensor Threshold For Sensor  ${sensor_list}

    # Identify Sensor Threshold Values to modify
    ${threshold_dict}=  Identify Sensor Threshold Values   ${initial_sensor_threshold}

    # Set Sensor Threshold For given Sensor and compare with initial reading
    ${set_sensor_threshold}=  Set Sensor Threshold For given Sensor  ${threshold_dict}  ${sensor_name}
    Should Not Be Equal  ${set_sensor_threshold}  ${initial_sensor_threshold}

    # Execute cold reset command via IPMI
    Run External IPMI Raw Command  ${IPMI_RAW_CMD['Resets']['cold'][0]}
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Unpingable
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Operational

    # Get Sensor Data for the sensor identified.
    ${data_after_coldreset}=  Wait Until Keyword Succeeds  2 min  30 sec
    ...  Run IPMI Standard Command   sensor | grep -i RPM | grep "${sensor_name}"

    # Get Sensor Threshold Readings after BMC restarts
    ${sensor_threshold_after_reset}  ${sensor_name_after_reset}=  Get The Sensor Threshold For Sensor  ${data_after_coldreset}

    # Compare with initial sensor threshold values
    Should Be Equal  ${sensor_threshold_after_reset}  ${initial_sensor_threshold}


*** Keywords ***

Get Sensor List
    [Documentation]  To Get the list of sensors via IPMI Sensor list

    # BMC may take time to populate all the sensors once BMC Cold reset completes
    ${data}=  Wait Until Keyword Succeeds  2 min  30 sec
    ...  Run IPMI Standard Command   sensor | grep -i RPM

    [Return]  ${data}

Identify Sensor
    [Documentation]  To Identify the sensor via IPMI Sensor list
    [Arguments]  ${data}

    # Find Sensor detail of sensor list first entry
    ${data}=  Split To Lines  ${data}
    ${data}=  Set Variable  ${data[0]}

    [Return]  ${data}


Get Sensor Readings For The Sensor
    [Documentation]  To Get the Sensor Reading of the given sensor using IPMI.
    [Arguments]  ${Sensor_list}

    # Split Sensor details in a list
    ${sensor}=  Identify Sensor  ${Sensor_list}
    ${data}=  Split String  ${sensor}  |

    # Sensor Name 
    ${sensor_name}=  Set Variable  ${data[0]}
    ${sensor_name}=  Remove Whitespace  ${sensor_name}

    [Return]  ${data}  ${sensor_name}


Get The Sensor Threshold For Sensor
    [Documentation]  To Get the Sensor Threshold For Given Sensor using IPMI
    [Arguments]  ${Sensor_list}

    # Gets the threshold values in a list
    ${data}  ${sensor_name}=  Get Sensor Readings For The Sensor  ${Sensor_list}
    ${threshold}=  Set Variable  ${data[5:9]}

    [Return]  ${threshold}  ${sensor_name}


Identify Sensor Threshold Values
    [Documentation]  Identify New Sensor Threshold Values with adding 1 to old threshold values.
    [Arguments]  ${old_threshold}

    # Retrives modified threshold values from functions.py function
    ${threshold_dict}=  Identify Threshold  ${old_threshold}  ${thresholds_list}

    [Return]  ${threshold_dict}


Set Sensor Threshold For given Sensor
    [Documentation]  Set Sensor Threshold for given sensor with given Upper and Lower critical and non-critical values Via IPMI
    [Arguments]  ${threshold_dict}  ${sensor}

    # Set Lower critical and non-critical values
    FOR  ${criticals}  IN  @{threshold_dict}
        # Set Lower critical and non-critical values
        Run keyword if  '${threshold_dict['${criticals}']}' != 'na'
        ...  Run IPMI Standard Command
        ...  sensor thresh "${sensor}" ${criticals} ${threshold_dict['${criticals}']}
        # Allow Network restart sleep time for the readings to get reflected
        Sleep  ${NETWORK_RESTART_TIME}
    END

    # Get Sensor List for the sensor name identified
    ${data}=  Wait Until Keyword Succeeds  2 min  30 sec
    ...  Run IPMI Standard Command   sensor | grep -i RPM | grep "${sensor}"

    # Get New threshold value set from sensor list
    ${threshold_new}  ${sensor_name}=  Get The Sensor Threshold For Sensor  ${data}

    [Return]  ${threshold_new}
