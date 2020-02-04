*** Settings ***

Documentation          Module to test IPMI network functionality.
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/bmc_network_utils.robot
Library                ../lib/ipmi_utils.py
Library                ../lib/gen_robot_valid.py
Library                ../lib/var_funcs.py
Library                ../lib/bmc_network_utils.py

Suite Setup            Redfish.Login
Test Setup             Printn
Test Teardown          FFDC On Test Case Fail

Force Tags             IPMI_Network


*** Variables ***
${allowed_temp_diff}    ${1}


*** Test Cases ***

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

    ${thermal}=  Redfish.Get  /redfish/v1/Chassis/chassis/Thermal
    ${temperature_list}=  Get From Dictionary  ${thermal.dict}  Temperatures
    FOR  ${temperature}  IN  @{temperature_list}
        ${ambient_temp_redfish}=  Run Keyword If    '${temperature}[MemberId]' == 'ambient'
        ...  Set Variable  ${temperature}[ReadingCelsius]
        Exit For Loop IF    '${temperature}[MemberId]' == 'ambient'
    END

    Should be Equal  ${temperature}[MemberId]   ambient
    ${ipmi_redfish_temp_diff}=
    ...  Evaluate  abs(${ambient_temp_redfish} - ${ambient_temp_ipmi})

    Should Be True  ${ipmi_redfish_temp_diff} <= ${allowed_temp_diff}
    ...  msg=Ambient temperature above allowed threshold ${allowed_temp_diff}.

