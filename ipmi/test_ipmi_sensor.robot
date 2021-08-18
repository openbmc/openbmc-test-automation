*** Settings ***
Documentation  Validate IPMI sensor IDs using Redfish.

Resource          ../lib/ipmi_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/boot_utils.robot
Library           ../lib/ipmi_utils.py
Variables         ../data/ipmi_raw_cmd_table.py

Test Setup        Redfish.Login
Test Teardown     Run Keywords  FFDC On Test Case Fail  AND
...  Redfish.Logout


*** Variables ***
${allowed_temp_diff}    ${2}
${allowed_power_diff}   ${10}


*** Test Cases ***

Verify IPMI Temperature Readings using Redfish
    [Documentation]  Verify temperatures from IPMI sensor reading command using Redfish.
    [Tags]  Verify_IPMI_Temperature_Readings_using_Redfish
    [Template]  Get Temperature Reading And Verify In Redfish

    # command_type  sensor_id  member_id
    IPMI            pcie       pcie
    IPMI            ambient    ambient


Verify DCMI Temperature Readings using Redfish
    [Documentation]  Verify temperatures from DCMI sensor reading command using Redfish.
    [Tags]  Verify_DCMI_Temperature_Readings_using_Redfish
    [Template]  Get Temperature Reading And Verify In Redfish

    # command_type  sensor_id  member_id
    DCMI            pcie       pcie
    DCMI            ambient    ambient


Test Ambient Temperature Via IPMI
    [Documentation]  Test ambient temperature via IPMI and verify using Redfish.
    [Tags]  Test_Ambient_Temperature_Via_IPMI

    # Example of IPMI dcmi get_temp_reading output:
    #        Entity ID                       Entity Instance    Temp. Readings
    # Inlet air temperature(40h)                      1               +19 C
    # CPU temperature sensors(41h)                    5               +51 C
    # CPU temperature sensors(41h)                    6               +50 C
    # CPU temperature sensors(41h)                    7               +50 C
    # CPU temperature sensors(41h)                    8               +50 C
    # CPU temperature sensors(41h)                    9               +50 C
    # CPU temperature sensors(41h)                    10              +48 C
    # CPU temperature sensors(41h)                    11              +49 C
    # CPU temperature sensors(41h)                    12              +47 C
    # CPU temperature sensors(41h)                    8               +50 C
    # CPU temperature sensors(41h)                    16              +51 C
    # CPU temperature sensors(41h)                    24              +50 C
    # CPU temperature sensors(41h)                    32              +43 C
    # CPU temperature sensors(41h)                    40              +43 C
    # Baseboard temperature sensors(42h)              1               +35 C

    ${temp_reading}=  Run IPMI Standard Command  dcmi get_temp_reading -N 10
    Should Contain  ${temp_reading}  Inlet air temperature
    ...  msg="Unable to get inlet temperature via DCMI".

    ${ambient_temp_line}=
    ...  Get Lines Containing String  ${temp_reading}
    ...  Inlet air temperature  case-insensitive

    ${ambient_temp_ipmi}=  Set Variable  ${ambient_temp_line.split('+')[1].strip(' C')}

    # Example of ambient temperature via Redfish

    #"@odata.id": "/redfish/v1/Chassis/chassis/Thermal#/Temperatures/0",
    #"@odata.type": "#Thermal.v1_3_0.Temperature",
    #"LowerThresholdCritical": 0.0,
    #"LowerThresholdNonCritical": 0.0,
    #"MaxReadingRangeTemp": 0.0,
    #"MemberId": "ambient",
    #"MinReadingRangeTemp": 0.0,
    #"Name": "ambient",
    #"ReadingCelsius": 24.987000000000002,
    #"Status": {
          #"Health": "OK",
          #"State": "Enabled"
    #},
    #"UpperThresholdCritical": 35.0,
    #"UpperThresholdNonCritical": 25.0

    ${ambient_temp_redfish}=  Get Temperature Reading From Redfish  ambient

    ${ipmi_redfish_temp_diff}=
    ...  Evaluate  abs(${ambient_temp_redfish} - ${ambient_temp_ipmi})

    Should Be True  ${ipmi_redfish_temp_diff} <= ${allowed_temp_diff}
    ...  msg=Ambient temperature above allowed threshold ${allowed_temp_diff}.


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
    # Inlet air temperature(40h)                      1               +19 C
    # CPU temperature sensors(41h)                    5               +51 C
    # CPU temperature sensors(41h)                    6               +50 C
    # CPU temperature sensors(41h)                    7               +50 C
    # CPU temperature sensors(41h)                    8               +50 C
    # CPU temperature sensors(41h)                    9               +50 C
    # CPU temperature sensors(41h)                    10              +48 C
    # CPU temperature sensors(41h)                    11              +49 C
    # CPU temperature sensors(41h)                    12              +47 C
    # CPU temperature sensors(41h)                    8               +50 C
    # CPU temperature sensors(41h)                    16              +51 C
    # CPU temperature sensors(41h)                    24              +50 C
    # CPU temperature sensors(41h)                    32              +43 C
    # CPU temperature sensors(41h)                    40              +43 C
    # Baseboard temperature sensors(42h)              1               +35 C

    ${temp_reading}=  Run IPMI Standard Command  dcmi get_temp_reading -N 10
    Should Contain  ${temp_reading}  Baseboard temperature sensors
    ...  msg="Unable to get baseboard temperature via DCMI".
    ${baseboard_temp_line}=
    ...  Get Lines Containing String  ${temp_reading}
    ...  Baseboard temperature  case-insensitive=True

    ${baseboard_temp_ipmi}=  Set Variable  ${baseboard_temp_line.split('+')[1].strip(' C')}

    # Example of Baseboard temperature via Redfish

    #"@odata.id": "/redfish/v1/Chassis/chassis/Thermal#/Temperatures/9",
    #"@odata.type": "#Thermal.v1_3_0.Temperature",
    #"LowerThresholdCritical": 0.0,
    #"LowerThresholdNonCritical": 0.0,
    #"MaxReadingRangeTemp": 0.0,
    #"MemberId": "pcie",
    #"MinReadingRangeTemp": 0.0,
    #"Name": "pcie",
    #"ReadingCelsius": 28.687,
    #"Status": {
          #"Health": "OK",
          #"State": "Enabled"
    #},
    #"UpperThresholdCritical": 70.0,
    #"UpperThresholdNonCritical": 60.0

    ${baseboard_temp_redfish}=  Get Temperature Reading From Redfish  pcie

    Should Be True
    ...  ${baseboard_temp_redfish} - ${baseboard_temp_ipmi} <= ${allowed_temp_diff}
    ...  msg=Baseboard temperature above allowed threshold ${allowed_temp_diff}.


Test Power Reading Via IPMI Raw Command
    [Documentation]  Test power reading via IPMI raw command and verify
    ...  using Redfish.
    [Tags]  Test_Power_Reading_Via_IPMI_Raw_Command

    IPMI Power On  stack_mode=skip

    Wait Until Keyword Succeeds  2 min  30 sec  Verify Power Reading Via Raw Command


Verify CPU Present
    [Documentation]  Verify the IPMI sensor for CPU present using Redfish.
    [Tags]  Verify_CPU_Present
    [Template]  Enable Present Bit Via IPMI and Verify Using Redfish

    # sensor_id  component
    0x5a         cpu0


Verify CPU Not Present
    [Documentation]  Verify the IPMI sensor for CPU not present using Redfish.
    [Tags]  Verify_CPU_Not_Present
    [Template]  Disable Present Bit Via IPMI and Verify Using Redfish

    # sensor_id  component
    0x5a         cpu0


Verify GPU Present
    [Documentation]  Verify the IPMI sensor for GPU present using Redfish.
    [Tags]  Verify_GPU_Present
    [Template]  Enable Present Bit Via IPMI and Verify Using Redfish

    # sensor_id  component
    0xC5         gv100card0


Verify GPU Not Present
    [Documentation]  Verify the IPMI sensor for GPU not present using Redfish.
    [Tags]  Verify_GPU_Not_Present
    [Template]  Disable Present Bit Via IPMI and Verify Using Redfish

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

    Valid Range  ${ipmi_value}  ${redfish_value-1.000}  ${redfish_value+1.000}


Get IPMI Sensor Reading
    [Documentation]  Get reading from IPMI sensor reading command.
    [Arguments]  ${sensor_id}

    # Description of argument(s):
    # sensor_id     Sensor id used to get reading in IPMI.

    ${data}=  Run IPMI Standard Command  sensor reading ${sensor_id}

    # Example reading:
    # pcie             | 28.500

    ${sensor_value}=  Set Variable  ${data.split('| ')[1].strip()}
    [Return]  ${sensor_value}


Get DCMI Sensor Reading
    [Documentation]  Get reading from DCMI sensors command.
    [Arguments]  ${sensor_id}

    # Description of argument(s):
    # sensor_id     Sensor id used to get reading in DCMI.

    ${data}=  Run IPMI Standard Command  dcmi sensors
    ${sensor_data}=  Get Lines Containing String  ${data}  ${sensor_id}

    # Example reading:
    # Record ID 0x00fd: pcie             | 28.50 degrees C   | ok

    ${sensor_value}=  Set Variable  ${sensor_data.split(' | ')[1].strip('degrees C').strip()}
    [Return]  ${sensor_value}


Get Temperature Reading From Redfish
    [Documentation]  Get temperature reading from Redfish.
    [Arguments]  ${member_id}

    # Description of argument(s):
    # member_id    Member id of temperature.

    @{redfish_readings}=  Redfish.Get Attribute  /redfish/v1/Chassis/chassis/Thermal  Temperatures
    FOR  ${data}  IN  @{redfish_readings}
        ${redfish_value}=  Set Variable If  '${data}[MemberId]' == '${member_id}'
        ...  ${data}[ReadingCelsius]
        Exit For Loop If  '${data}[MemberId]' == '${member_id}'
    END
    [Return]  ${redfish_value}


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

    ${power_uri_list}=  redfish_utils.Get Members URI  /redfish/v1/Chassis/  PowerControl
    Log List  ${power_uri_list}

    # Power entries could be seen across different redfish path, remove the URI
    # where the attribute is non-existent.
    # Example:
    #     ['/redfish/v1/Chassis/chassis/Power',
    #      '/redfish/v1/Chassis/motherboard/Power']
    FOR  ${idx}  IN  @{power_uri_list}
        ${power}=  redfish_utils.Get Attribute  ${idx}  PowerControl
        Log Dictionary  ${power[0]}

        # Ensure the path does have the attribute else set to EMPTY as default to skip.
        ${value}=  Get Variable Value  ${power[0]['PowerConsumedWatts']}  ${EMPTY}
        Run Keyword If  "${value}" == "${EMPTY}"
        ...  Remove Values From List  ${power_uri_list}  ${idx}

        # Check the next available element in the list.
        Continue For Loop If  "${value}" == "${EMPTY}"

        ${ipmi_redfish_power_diff}=
        ...  Evaluate  abs(${${power[0]['PowerConsumedWatts']}} - ${ipmi_reading['instantaneous_power_reading']})
        Should Be True  ${ipmi_redfish_power_diff} <= ${allowed_power_diff}
        ...  msg=Power reading above allowed threshold ${allowed_power_diff}.
    END

    # Double check, the validation has at least one valid path.
    Should Not Be Empty  ${power_uri_list}
    ...  msg=Should contain at least one element in the list.


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

    ${power}=  Redfish.Get Properties  /redfish/v1/Chassis/chassis/Power
    ${redfish_reading}=  Set Variable  ${power['PowerControl'][0]['PowerConsumedWatts']}

    ${ipmi_redfish_power_diff}=
    ...  Evaluate  abs(${redfish_reading} - ${power_reading_ipmi})

    Should Be True  ${ipmi_redfish_power_diff} <= ${allowed_power_diff}
    ...  msg=Power reading above allowed threshold ${allowed_power_diff}.


Enable Present Bit Via IPMI and Verify Using Redfish
    [Documentation]  Enable present bit of sensor via IPMI and verify using Redfish.
    [Arguments]  ${sensor_id}  ${component}

    # Description of argument(s):
    # sensor_id    The sensor id of IPMI sensor.
    # component    The Redfish component of IPMI sensor.

    Run IPMI Command
    ...  0x04 0x30 ${sensor_id} 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00

    #  Example of CPU state via Redfish

    #"Name": "Processor",
    #"ProcessorArchitecture": "Power",
    #"ProcessorType": "CPU",
    #"Status": {
    #    "Health": "OK",
    #    "State": "Enabled"
    #}

    ${redfish_value}=  Redfish.Get Properties  /redfish/v1/Systems/system/Processors/${component}
    Should Be True  '${redfish_value['Status']['State']}' == 'Enabled'


Disable Present Bit Via IPMI and Verify Using Redfish
    [Documentation]  Disable present bit of sensor via IPMI and verify using Redfish.
    [Arguments]  ${sensor_id}  ${component}

    # Description of argument(s):
    # sensor_id    The sensor id of IPMI sensor.
    # component    The Redfish component of IPMI sensor.

    Run IPMI Command
    ...  0x04 0x30 ${sensor_id} 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00

    #  Example of CPU state via Redfish

    #"Name": "Processor",
    #"ProcessorArchitecture": "Power",
    #"ProcessorType": "CPU",
    #"Status": {
    #    "Health": "OK",
    #    "State": "Absent"
    #}

    ${redfish_value}=  Redfish.Get Properties  /redfish/v1/Systems/system/Processors/${component}
    Should Be True  '${redfish_value['Status']['State']}' == 'Absent'


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

    @{redfish_readings}=  Redfish.Get Attribute  /redfish/v1/Chassis/chassis/Power  Voltages
    FOR  ${data}  IN  @{redfish_readings}
        Run keyword if  '${data}[MemberId]' == 'ps0_input_voltage'
        ...  Should Be Equal As Numbers  ${data['${redfish_threshold_id}']}  ${ipmi_threshold_reading}
    END
