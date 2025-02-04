*** Settings ***
Documentation     Validate IPMI sensor IDs using Redfish.

Resource          ../lib/ipmi_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/boot_utils.robot
Library           ../lib/ipmi_utils.py
Variables         ../data/ipmi_raw_cmd_table.py

Test Setup        Redfish.Login
Test Teardown     Run Keywords  FFDC On Test Case Fail  AND
...  Redfish.Logout

Test Tags        IPMI_Sensor

*** Variables ***

${allowed_temp_diff}    ${2}
${allowed_power_diff}   ${10}


*** Test Cases ***
Verify IPMI Temperature Readings using Redfish
    [Documentation]  Verify temperatures from IPMI sensor reading command using Redfish.
    [Tags]  Verify_IPMI_Temperature_Readings_using_Redfish
    [Template]  Get Temperature Reading And Verify In Redfish

    # command_type  sensor_id  member_id
    IPMI            PCIE       PCIE
    IPMI            Ambient    Ambient


Verify DCMI Temperature Readings using Redfish
    [Documentation]  Verify temperatures from DCMI sensor reading command using Redfish.
    [Tags]  Verify_DCMI_Temperature_Readings_using_Redfish
    [Template]  Get Temperature Reading And Verify In Redfish

    # command_type  sensor_id  member_id
    DCMI            PCIE       PCIE
    DCMI            Ambient    Ambient


Test Ambient Temperature Via IPMI
    [Documentation]  Test ambient temperature via IPMI and verify using Redfish.
    [Tags]  Test_Ambient_Temperature_Via_IPMI

    # Example of IPMI dcmi get_temp_reading output:
    #        Entity ID                       Entity Instance    Temp. Readings
    # Inlet air temperature(40h)                      1               +22 C
    # Inlet air temperature(40h)                      2               +23 C
    # Inlet air temperature(40h)                      3               +22 C
    # CPU temperature sensors(41h)                    0               +0 C
    # Baseboard temperature sensors(42h)              1               +26 C
    # Baseboard temperature sensors(42h)              2               +27 C

    ${temp_reading}=  Run IPMI Standard Command  dcmi get_temp_reading -N 10
    Should Contain  ${temp_reading}  Inlet air temperature
    ...  msg="Unable to get inlet temperature via DCMI".

    ${ambient_temp_line}=
    ...  Get Lines Containing String  ${temp_reading}
    ...  Inlet air temperature  case-insensitive

    ${ambient_temp_line}=  Split To Lines  ${ambient_temp_line}
    ${ipmi_temp_list}=  Create List
    FOR  ${line}  IN  @{ambient_temp_line}
        ${ambient_temp_ipmi}=  Set Variable  ${line.split('+')[1].strip(' C')}
        Append To List  ${ipmi_temp_list}  ${ambient_temp_ipmi}
    END
    ${list_length}=  Get Length  ${ipmi_temp_list}

    # Getting temperature readings from Redfish.
    ${ambient_temp_redfish}=  Get Temperature Reading From Redfish  Ambient
    ${ambient_temp_redfish}=  Get Dictionary Values  ${ambient_temp_redfish}  sort_keys=True
    FOR  ${index}  IN RANGE  ${list_length}
        ${ipmi_redfish_temp_diff}=
        ...  Evaluate  abs(${ambient_temp_redfish[${index}]} - ${ipmi_temp_list[${index}]})

        Should Be True  ${ipmi_redfish_temp_diff} <= ${allowed_temp_diff}
        ...  msg=Ambient temperature above allowed threshold ${allowed_temp_diff}.
    END


Test Power Reading Via IPMI With Host Off
    [Documentation]  Verify power reading via IPMI with host in off state
    [Tags]  Test_Power_Reading_Via_IPMI_With_Host_Off

    Redfish Power Off  stack_mode=skip

    ${ipmi_reading}=  Get IPMI Power Reading

    Should Be Equal  ${ipmi_reading['instantaneous_power_reading']}  0
    ...  msg=Power reading not zero when power is off.


Test Power Reading Via IPMI With Host Booted
    [Documentation]  Test power reading via IPMI with host in booted state and
    ...  verify using Redfish.
    [Tags]  Test_Power_Reading_Via_IPMI_With_Host_Booted

    IPMI Power On  stack_mode=skip

    Wait Until Keyword Succeeds  2 min  30 sec  Verify Power Reading Using IPMI And Redfish


Test Baseboard Temperature Via IPMI
    [Documentation]  Test baseboard temperature via IPMI and verify using Redfish.
    [Tags]  Test_Baseboard_Temperature_Via_IPMI

    # Example of IPMI dcmi get_temp_reading output:
    #        Entity ID                       Entity Instance    Temp. Readings
    # Inlet air temperature(40h)                      1               +22 C
    # Inlet air temperature(40h)                      2               +23 C
    # Inlet air temperature(40h)                      3               +22 C
    # CPU temperature sensors(41h)                    0               +0 C
    # Baseboard temperature sensors(42h)              1               +26 C
    # Baseboard temperature sensors(42h)              2               +27 C

    ${temp_reading}=  Run IPMI Standard Command  dcmi get_temp_reading -N 10
    Should Contain  ${temp_reading}  Baseboard temperature sensors
    ...  msg="Unable to get baseboard temperature via DCMI".
    ${baseboard_temp_lines}=
    ...  Get Lines Containing String  ${temp_reading}
    ...  Baseboard temperature  case-insensitive=True
    ${lines}=  Split To Lines  ${baseboard_temp_lines}

    ${ipmi_temp_list}=  Create List
    FOR  ${line}  IN  @{lines}
        ${baseboard_temp_ipmi}=  Set Variable  ${line.split('+')[1].strip(' C')}
        Append To List  ${ipmi_temp_list}  ${baseboard_temp_ipmi}
    END
    ${list_length}=  Get Length  ${ipmi_temp_list}

    # Getting temperature readings from Redfish.
    ${baseboard_temp_redfish}=  Get Temperature Reading From Redfish  PCIE
    ${baseboard_temp_redfish}=  Get Dictionary Values  ${baseboard_temp_redfish}  sort_keys=True

    FOR  ${index}  IN RANGE  ${list_length}
        ${baseboard_temp_diff}=  Evaluate  abs(${baseboard_temp_redfish[${index}]} - ${ipmi_temp_list[${index}]})
        Should Be True
        ...  ${baseboard_temp_diff} <= ${allowed_temp_diff}
        ...  msg=Baseboard temperature above allowed threshold ${allowed_temp_diff}.
    END

Test Power Reading Via IPMI Raw Command
    [Documentation]  Test power reading via IPMI raw command and verify
    ...  using Redfish.
    [Tags]  Test_Power_Reading_Via_IPMI_Raw_Command

    IPMI Power On  stack_mode=skip

    Wait Until Keyword Succeeds  2 min  30 sec  Verify Power Reading Via Raw Command


Verify CPU Present
    [Documentation]  Verify the IPMI sensor for CPU present using Redfish.
    [Tags]  Verify_CPU_Present
    [Template]  Set Present Bit Via IPMI and Verify Using Redfish

    # component  state
    cpu          Enabled


Verify CPU Not Present
    [Documentation]  Verify the IPMI sensor for CPU not present using Redfish.
    [Tags]  Verify_CPU_Not_Present
    [Template]  Set Present Bit Via IPMI and Verify Using Redfish

    # component  state
    cpu          Absent


Verify GPU Present
    [Documentation]  Verify the IPMI sensor for GPU present using Redfish.
    [Tags]  Verify_GPU_Present
    [Template]  Set Present Bit Via IPMI and Verify Using Redfish

    # sensor_id  component
    0xC5         gv100card0


Verify GPU Not Present
    [Documentation]  Verify the IPMI sensor for GPU not present using Redfish.
    [Tags]  Verify_GPU_Not_Present
    [Template]  Set Present Bit Via IPMI and Verify Using Redfish

    # sensor_id  component
    0xC5         gv100card0


Test Sensor Threshold Via IPMI
    [Documentation]  Test sensor threshold via IPMI and verify using Redfish.
    [Tags]  Test_Sensor_Threshold_Via_IPMI
    [Template]  Verify Power Supply Sensor Threshold

    # threshold_id             component
    Upper Non-Critical         UpperThresholdNonCritical
    Upper Critical             UpperThresholdCritical
    Lower Non-Critical         LowerThresholdNonCritical
    Lower Critical             LowerThresholdCritical


*** Keywords ***

Get Temperature Reading And Verify In Redfish
    [Documentation]  Get IPMI or DCMI sensor reading and verify in Redfish.
    [Arguments]  ${command_type}  ${sensor_id}  ${member_id}

    # Description of argument(s):
    # command_type  Type of command used to get sensor data (eg. IPMI, DCMI).
    # sensor_id     Sensor id used to get reading in IPMI or DCMI.
    # member_id     Member id of sensor data in Redfish.

    ${ipmi_value}=  Run Keyword If  '${command_type}' == 'IPMI'  Get IPMI Sensor Reading  ${sensor_id}
    ...  ELSE  Get DCMI Sensor Reading  ${sensor_id}

    ${redfish_value}=  Get Temperature Reading From Redfish  ${member_id}

    ${keys}=  Get Dictionary Keys  ${ipmi_value}
    FOR  ${index}  IN  @{keys}
        ${value_diff}=  Evaluate  abs(${redfish_value["${index}"]} - ${ipmi_value["${index}"]})
        Should Be True  ${value_diff} <= ${allowed_temp_diff}
    END



Get IPMI Sensor Reading
    [Documentation]  Get IPMI sensor readings as a dictionary.
    [Arguments]  ${sensor_id}

    # Description of argument(s):
    # sensor_id     Sensor id used to get reading in IPMI.

    ${sensor_list}=  Get Available Sensors  ${sensor_id}
    ${sensor_value_dict}=  Create Dictionary

    FOR  ${ids}  IN  @{sensor_list}
        ${data}=  Run IPMI Standard Command  sensor reading ${ids}

        # Example reading:
        # PCIE_0_Temp      | 5Ch | ok  | 41.1 | 27 degrees C

        ${sensor_key}=  Set Variable  ${data.split('| ')[0].strip()}
        ${sensor_value}=  Set Variable  ${data.split('| ')[1].strip()}
        Set To Dictionary  ${sensor_value_dict}  ${sensor_key}  ${sensor_value}
    END

    RETURN  ${sensor_value_dict}


Get DCMI Sensor Reading
    [Documentation]  Get DCMI sensor readings as a dictionary.
    [Arguments]  ${sensor_id}

    # Description of argument(s):
    # sensor_id     Sensor id used to get reading in DCMI.

    ${data}=  Run IPMI Standard Command  dcmi sensors
    ${sensor_data}=  Get Lines Containing String  ${data}  ${sensor_id}  case_insensitive
    ${sensor_lines}=  Split To Lines  ${sensor_data}

    # Example reading:
    # Record ID 0x005c: PCIE_0_Temp      | 27 degrees C      | ok

    ${sensor_value_dict}=  Create Dictionary

    FOR  ${line}  IN  @{sensor_lines}
        ${sensor}=  Set Variable  ${line.split(' | ')}
        ${sensor_key}=  Set Variable  ${sensor[0].split(':')[1].strip()}
        ${sensor_value}=  Set Variable  ${sensor[1].split()[0].strip()}
        ${contains}=  Evaluate  """disabled""" in "${sensor_value}"

        Run Keyword IF  "${contains}" != """True"""
        ...  Set To Dictionary  ${sensor_value_dict}  ${sensor_key}  ${sensor_value}
    END

    RETURN  ${sensor_value_dict}


Get Temperature Reading From Redfish
    [Documentation]  Get temperature reading from Redfish.
    [Arguments]  ${member_id}

    # Description of argument(s):
    # member_id    Member id of temperature.

    @{thermal_uri}=  redfish_utils.Get Member List  /redfish/v1/Chassis/
    @{redfish_readings}=  redfish_utils.Get Attribute
    ...  ${thermal_uri[0]}/${THERMAL_METRICS}  TemperatureReadingsCelsius


    # Example of Baseboard temperature via Redfish

    # "@odata.id": "/redfish/v1/Chassis/chassis/ThermalSubsystem/ThermalMetrics",
    # "@odata.type": "#ThermalMetrics.v1_0_0.ThermalMetrics",
    # "Id": "ThermalMetrics",
    # "Name": "Chassis Thermal Metrics",
    # "TemperatureReadingsCelsius": [
    # {
    # "@odata.id": "/redfish/v1/Chassis/chassis/Sensors/PCIE_0_Temp",
    # "DataSourceUri": "/redfish/v1/Chassis/chassis/Sensors/PCIE_0_Temp",
    # "DeviceName": "PCIE_0_Temp",
    # "Reading": 23.75
    # },

    ${redfish_value_dict}=  Create Dictionary
    FOR  ${data}  IN  @{redfish_readings}
        ${keys}=  Get Dictionary Keys  ${data}
        ${reading}=  Set Variable  ${data}[Reading]
        ${is_device_name_present}=  Evaluate  "DeviceName" in @{keys}
        IF  ${is_device_name_present}
            ${contains}=  Evaluate  "${member_id}" in """${data}[DeviceName]"""
            Run Keyword IF  "${contains}" == "True"
            ...  Set To Dictionary  ${redfish_value_dict}  ${data}[DeviceName]  ${reading}
        ELSE
            ${data_source_id}=  Evaluate  ("${data}[DataSourceUri]").split('temperature_')
            ${contains}=  Evaluate  "${member_id}" in "${data_source_id[1]}"
            IF  ${contains}
               Set To Dictionary  ${redfish_value_dict}  ${data_source_id[1]}  ${reading}
            END
        END
    END

    RETURN  ${redfish_value_dict}


Verify Power Reading Using IPMI And Redfish
    [Documentation]  Verify power reading using IPMI and Redfish.

    # Example of power reading command output via IPMI.
    # Instantaneous power reading:                   235 Watts
    # Minimum during sampling period:                235 Watts
    # Maximum during sampling period:                235 Watts
    # Average power reading over sample period:      235 Watts
    # IPMI timestamp:                                Thu Jan  1 00:00:00 1970
    # Sampling period:                               00000000 Seconds.
    # Power reading state is:                        deactivated

    ${ipmi_reading}=  Get IPMI Power Reading
    ${redfish_power_reading}=  redfish_utils.Get Attribute
    ...  /redfish/v1/Chassis/${CHASSIS_ID}/Sensors/power_total_power  Reading

    ${ipmi_redfish_power_diff}=
    ...  Evaluate  abs(${redfish_power_reading} - ${ipmi_reading['instantaneous_power_reading']})
    Should Be True  ${ipmi_redfish_power_diff} <= ${allowed_power_diff}
    ...  msg=Power reading above allowed threshold ${allowed_power_diff}.


Verify Power Reading Via Raw Command
    [Documentation]  Get dcmi power reading via IPMI raw command.

    ${ipmi_raw_output}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['power_reading']['Get'][0]}

    ${power_reading_ipmi}=  Set Variable  ${ipmi_raw_output.split()[1]}
    ${power_reading_ipmi}=
    ...  Convert To Integer  0x${power_reading_ipmi}

    #  Example of power reading via Redfish
    #  "@odata.id": "/redfish/v1/Chassis/chassis/Power#/PowerControl/0",
    #  "@odata.type": "#Power.v1_0_0.PowerControl",
    #  "MemberId": "0",
    #  "Name": "Chassis Power Control",
    #  "PowerConsumedWatts": 145.0,

    ${power}=  Redfish.Get Properties  /redfish/v1/Chassis/${CHASSIS_ID}/Power
    ${redfish_reading}=  Set Variable  ${power['PowerControl'][0]['PowerConsumedWatts']}

    ${ipmi_redfish_power_diff}=
    ...  Evaluate  abs(${redfish_reading} - ${power_reading_ipmi})

    Should Be True  ${ipmi_redfish_power_diff} <= ${allowed_power_diff}
    ...  msg=Power reading above allowed threshold ${allowed_power_diff}.


Set Present Bit Via IPMI and Verify Using Redfish
    [Documentation]  Set present bit of sensor via IPMI and verify using Redfish.
    [Arguments]  ${component}  ${status}

    # Description of argument(s):
    # component    The Redfish component of IPMI sensor.
    # status  Status of the bit to be set(e.g. Absent, Present).

    ${sensor_list}=  Get Available Sensors  ${component}
    ${sensor_name}=  Set Variable  ${sensor_list[0]}
    ${sensor_id}=  Get Sensor Id For Sensor  ${sensor_name}

     Run Keyword If  '${status}' == 'Absent'
     ...  Run IPMI Command
     ...  0x04 0x30 ${sensor_id} 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
     ...  ELSE IF  '${status}' == 'Enabled'
     ...  Run IPMI Command
     ...  0x04 0x30 ${sensor_id} 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00

     # Redfish cpu components have "-" instead of "_" (e.g.: dcm0-cpu0).
     ${cpu_name}=  Replace String  ${sensor_name}  _  -
     ${sensor_properties}=  Redfish.Get Properties  /redfish/v1/Systems/${SYSTEM_ID}/Processors/${cpu_name}

     #  Example of CPU state via Redfish

     # "ProcessorType": "CPU",
     # "SerialNumber": "YA1936422499",
     # "Socket": "",
     # "SparePartNumber": "F210110",
     # "Status": {
     # "Health": "OK",
     # "State": "Absent"
     # }

     Should Be True  '${sensor_properties['Status']['State']}' == '${status}'


Verify Power Supply Sensor Threshold
    [Documentation]  Get power supply sensor threshold value via IPMI and verify using Redfish.
    [Arguments]  ${ipmi_threshold_id}  ${redfish_threshold_id}

    # Description of argument(s):
    # ipmi_threshold_id       The sensor threshold component of IPMI sensor.
    # redfish_threshold_id    The sensor threshold component of Redfish sensor.


    #  Example of ipmi sensor output
    # Locating sensor record...
    # Sensor ID              : ps0_input_voltag (0xf7)
    # Entity ID             : 10.19
    # Sensor Type (Threshold)  : Voltage
    # Sensor Reading        : 208 (+/- 0) Volts
    # Status                : ok
    # Lower Non-Recoverable : na
    # Lower Critical        : 180.000
    # Lower Non-Critical    : 200.000
    # Upper Non-Critical    : 290.000
    # Upper Critical        : 300.000
    # Upper Non-Recoverable : na
    # Positive Hysteresis   : Unspecified
    # Negative Hysteresis   : Unspecified


    ${ipmi_sensor_output}=  Run External IPMI Standard Command  sensor get ps0_input_voltag
    ${ipmi_threshold_output}=  Get Lines Containing String  ${ipmi_sensor_output}  ${ipmi_threshold_id}
    ${ipmi_threshold_reading}=  Fetch From Right  ${ipmi_threshold_output}  :${SPACE}

    ${ipmi_threshold_reading}=  Set Variable If  '${ipmi_threshold_reading}' == 'na'
    ...  ${0}  ${ipmi_threshold_reading}

    #  Example of redfish sensor output
    # "@odata.id": "/redfish/v1/Chassis/chassis/Power#/Voltages/0",
    # "@odata.type": "#Power.v1_0_0.Voltage",
    # "LowerThresholdCritical": 180.0,
    # "LowerThresholdNonCritical": 200.0,
    # "MaxReadingRange": 0.0,
    # "MemberId": "ps0_input_voltage",
    # "MinReadingRange": 0.0,
    # "Name": "ps0 input voltage",
    # "ReadingVolts": 209.5,
    # "Status": {
    # "Health": "OK",
    # "State": "Enabled"
    # },
    # "UpperThresholdCritical": 300.0,
    # "UpperThresholdNonCritical": 290.0

    @{redfish_readings}=  Redfish.Get Attribute  /redfish/v1/Chassis/${CHASSIS_ID}/Power  Voltages
    FOR  ${data}  IN  @{redfish_readings}
        Run keyword if  '${data}[MemberId]' == 'ps0_input_voltage'
        ...  Should Be Equal As Numbers  ${data['${redfish_threshold_id}']}  ${ipmi_threshold_reading}
    END


Get Available Sensors
    [Documentation]  Get all the available sensors for the required component.
    ...  Returns a list of available sensors.
    [Arguments]  ${sensor_component}

    # Description of argument(s):
    # sensor_component     sensor component name.(e.g.:cpu)

    ${resp}=  Run IPMI Standard Command  sdr elist
    ${sensor_list}=  Create List
    ${sensors}=  Get Lines Containing String  ${resp}  ${sensor_component}  case-insensitive
    ${sensors}=  Split To Lines  ${sensors}

    # Example of IPMI sdr elist command.

    # dcm0_cpu0        | 41h | ok  |  3.1 | Presence detected
    # dcm0_cpu1        | 42h | ok  |  3.2 | Presence detected, Disabled
    # dcm1_cpu0        | 43h | ok  |  3.3 | Presence detected
    # dcm1_cpu1        | 44h | ok  |  3.4 | Presence detected, Disabled
    # dcm2_cpu0        | 45h | ns  |  3.5 | Disabled
    # dcm2_cpu1        | 46h | ns  |  3.6 | Disabled
    # dcm3_cpu0        | 47h | ns  |  3.7 | Disabled
    # dcm3_cpu1        | 48h | ns  |  3.8 | Disabled

    FOR  ${line}  IN  @{sensors}
        ${sensor_name}=  Set Variable  ${line.split('|')[0].strip()}

        # Adding sensors to the list whose presence is detected.
        ${contains}=  Evaluate  "Presence detected" in "${line}" or "ok" in "${line}"
        Run Keyword IF  "${contains}" == "True"
        ...  Append To List  ${sensor_list}  ${sensor_name}
    END

    # Example of output for ${sensor_list}
    # ['dcm0_cpu0', 'dcm0_cpu1', 'dcm1_cpu0', 'dcm1_cpu1']

    RETURN  ${sensor_list}


Get Sensor Id For Sensor
    [Documentation]  Returns the sensor ID value for the given sensor.
    [Arguments]  ${sensor_name}

    # Description of argument(s):
    # sensor_name     Name of sensor whose ID is required(e.g.: dcm0_cpu0, dcm0_cpu1 etc).

    ${get_resp}=  Run IPMI Standard Command  sensor get ${sensor_name}

    # Example of sensor get command.

    # Locating sensor record...
    # Sensor ID              : dcm0_cpu0 (0x41)
    # Entity ID             : 3.1
    # Sensor Type (Discrete): Processor
    # States Asserted       : Processor
    #                  [Presence detected]

    ${line}=  Get Lines Containing String  ${get_resp}  Sensor ID
    ${sensor_id}=  Set Variable  ${line[-5:-1]}

    # Example of output for ${sensor_id} is 0x41.

    RETURN  ${sensor_id}

