*** Settings ***
Documentation  Validate IPMI sensor IDs using Redfish.

Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot

Test Setup             Redfish.Login
Test Teardown          Test Teardown Execution

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

*** Keywords ***

Get Temperature Reading And Verify In Redfish
    [Documentation]  Get IPMI or DCMI sensor reading and verify in Redfish.
    [Arguments]  ${command_type}  ${sensor_id}  ${member_id}

    # Description of argument(s):
    # command_type  Type of command used to get sensor data (eg. IPMI, DCMI).
    # sensor_id     Sensor id used to get reading in IPMI or DCMI.
    # member_id     Member id of sensor data in Redfish.

    ${ipmi_value}=  Run Keyword If  '${command_type}' == 'IPMI'  Get IPMI Sensor Readings  ${sensor_id}
    ...  ELSE  Get DCMI Sensor Readings  ${sensor_id}

    @{redfish_readings}=  Redfish.Get Attribute  /redfish/v1/Chassis/chassis/Thermal  Temperatures
    FOR  ${data}  IN  @{redfish_readings}
        ${redfish_value}=  Set Variable If  '&{data}[MemberId]' == '${member_id}'
        ...  &{data}[ReadingCelsius]
        Exit For Loop If  '&{data}[MemberId]' == '${member_id}'
    END

    Valid Range  ${ipmi_value}  ${redfish_value-1.000}  ${redfish_value+1.000}


Get IPMI Sensor Readings
    [Documentation]  Get reading from IPMI sensor reading command.
    [Arguments]  ${sensor_id}

    # Description of argument(s):
    # sensor_id     Sensor id used to get reading in IPMI.

    ${data}=  Run IPMI Standard Command  sensor reading ${sensor_id}

    # Example reading:
    # pcie             | 28.500

    ${sensor_value}=  Set Variable  ${data.split('| ')[1].strip()}
    [Return]  ${sensor_value}


Get DCMI Sensor Readings
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


Test Teardown Execution
    [Documentation]  Test teardown for testcases using Redfish.

    Redfish.Logout
    FFDC On Test Case Fail

