*** Settings ***
Documentation  Validate IPMI sensor IDs using Redfish.

Resource          ../lib/ipmi_client.robot
Resource          ../lib/openbmc_ffdc.robot

Suite Setup       Redfish.Login
Suite Teardown    Redfish.Logout
Test Setup        Printn
Test Teardown     FFDC On Test Case Fail


*** Variables ***
${allowed_temp_diff}    ${1}


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
        ${redfish_value}=  Set Variable If  '&{data}[MemberId]' == '${member_id}'
        ...  &{data}[ReadingCelsius]
        Exit For Loop If  '&{data}[MemberId]' == '${member_id}'
    END
    [Return]  ${redfish_value}