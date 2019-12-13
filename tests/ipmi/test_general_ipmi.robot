*** Settings ***
Documentation       This suite is for testing general IPMI functions.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/utils.robot
Resource            ../../lib/bmc_network_utils.robot
Resource            ../../lib/logging_utils.robot
Library             ../../lib/ipmi_utils.py
Variables           ../../data/ipmi_raw_cmd_table.py
Library             ../../lib/gen_misc.py
Library             ../../lib/gen_robot_valid.py

Test Setup          Log to Console  ${EMPTY}
Test Teardown       FFDC On Test Case Fail

*** Variables ***

${allowed_temp_diff}=  ${1}
${allowed_power_diff}=  ${10}

*** Test Cases ***

Verify Chassis Identify via IPMI
    [Documentation]  Verify "chassis identify" using IPMI command.
    [Tags]  Verify_Chassis_Identify_via_IPMI

    # Set to default "chassis identify" and verify that LED blinks for 15s.
    Run IPMI Standard Command  chassis identify
    Verify Identify LED State  ${1}

    Sleep  15s
    Verify Identify LED State  ${0}

    # Set "chassis identify" to 10s and verify that the LED blinks for 10s.
    Run IPMI Standard Command  chassis identify 10
    Verify Identify LED State  ${1}

    Sleep  10s
    Verify Identify LED State  ${0}


Verify Chassis Identify Off And Force Identify On via IPMI
    [Documentation]  Verify "chassis identify" off
    ...  and "force identify on" via IPMI.
    [Tags]  Verify_Chassis_Identify_Off_And_Force_Identify_On_via_IPMI

    # Set the LED to "Force Identify On".
    Run IPMI Standard Command  chassis identify force
    Verify Identify LED State  ${1}

    # Set "chassis identify" to 0 and verify that the LED turns off.
    Run IPMI Standard Command  chassis identify 0
    Verify Identify LED State  ${0}


Test Watchdog Reset Via IPMI And Verify Using REST
    [Documentation]  Test watchdog reset via IPMI and verify using REST.
    [Tags]  Test_Watchdog_Reset_Via_IPMI_And_Verify_Using_REST

    Initiate Host Boot

    Set Watchdog Enabled Using REST  ${1}

    Watchdog Object Should Exist

    # Resetting the watchdog via IPMI.
    Run IPMI Standard Command  mc watchdog reset

    # Verify the watchdog is reset using REST after an interval of 1000ms.
    Sleep  1000ms
    ${watchdog_time_left}=
    ...  Read Attribute  ${HOST_WATCHDOG_URI}  TimeRemaining
    Should Be True
    ...  ${watchdog_time_left}<${1200000} and ${watchdog_time_left}>${2000}
    ...  msg=Watchdog timer didn't reset.


Test Watchdog Off Via IPMI And Verify Using REST
    [Documentation]  Test watchdog off via IPMI and verify using REST.
    [Tags]  Test_Watchdog_Off_Via_IPMI_And_Verify_Using_REST

    Initiate Host Boot

    Set Watchdog Enabled Using REST  ${1}

    Watchdog Object Should Exist

    # Turn off the watchdog via IPMI.
    Run IPMI Standard Command  mc watchdog off

    # Verify the watchdog is off using REST
    ${watchdog_state}=  Read Attribute  ${HOST_WATCHDOG_URI}  Enabled
    Should Be Equal  ${watchdog_state}  ${0}
    ...  msg=msg=Verification failed for watchdog off check.


Test Ambient Temperature Via IPMI
    [Documentation]  Test ambient temperature via IPMI and verify using REST.
    [Tags]  Test_Ambient_Temperature_Via_IPMI

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

    ${ambient_temp_ipmi}=  Fetch From Right  ${ambient_temp_line}  +
    ${ambient_temp_ipmi}=  Remove String  ${ambient_temp_ipmi}  ${SPACE}C

    ${ambient_temp_rest}=  Read Attribute
    ...  ${SENSORS_URI}temperature/ambient  Value

    # Example of ambient temperature via REST
    #  "CriticalAlarmHigh": 0,
    #  "CriticalAlarmLow": 0,
    #  "CriticalHigh": 35000,
    #  "CriticalLow": 0,
    #  "Scale": -3,
    #  "Unit": "xyz.openbmc_project.Sensor.Value.Unit.DegreesC",
    #  "Value": 21775,
    #  "WarningAlarmHigh": 0,
    #  "WarningAlarmLow": 0,
    #  "WarningHigh": 25000,
    #  "WarningLow": 0

    # Get temperature value based on scale i.e. Value * (10 power Scale Value)
    # e.g. from above case 21775 * (10 power -3) = 21775/1000

    ${ambient_temp_rest}=  Evaluate  ${ambient_temp_rest}/1000
    ${ipmi_rest_temp_diff}=
    ...  Evaluate  abs(${ambient_temp_rest} - ${ambient_temp_ipmi})

    Should Be True  ${ipmi_rest_temp_diff} <= ${allowed_temp_diff}
    ...  msg=Ambient temperature above allowed threshold ${allowed_temp_diff}.


Test Power Reading Via IPMI With Host Off
    [Documentation]  Test power reading via IPMI with host off state and
    ...  verify using REST.
    [Tags]  Test_Power_Reading_Via_IPMI_With_Host_Off

    REST Power Off  stack_mode=skip  quiet=1

    Wait Until Keyword Succeeds  1 min  30 sec  Verify Power Reading


Test Power Reading Via IPMI With Host Booted
    [Documentation]  Test power reading via IPMI with host booted state and
    ...  verify using REST.
    [Tags]  Test_Power_Reading_Via_IPMI_With_Host_Booted

    REST Power On  stack_mode=skip  quiet=1

    # For a good power reading take a 3 samples for 15 seconds interval and
    # average it out.

    Wait Until Keyword Succeeds  2 min  30 sec  Verify Power Reading


Test Power Reading Via IPMI Raw Command
    [Documentation]  Test power reading via IPMI raw command and verify
    ...  using REST.
    [Tags]  Test_Power_Reading_Via_IPMI_Raw_Command

    # Response data structure of power reading command output via IPMI.
    # 1        Completion Code. Refer to section 8, DCMI Completion Codes.
    # 2        Group Extension Identification = DCh
    # 3:4      Current Power in watts

    REST Power On  stack_mode=skip  quiet=1

    Wait Until Keyword Succeeds  2 min  30 sec  Verify Power Reading Via Raw Command


Test Baseboard Temperature Via IPMI
    [Documentation]  Test baseboard temperature via IPMI and verify using REST.
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

    ${baseboard_temp_ipmi}=  Fetch From Right  ${baseboard_temp_line}  +
    ${baseboard_temp_ipmi}=  Remove String  ${baseboard_temp_ipmi}  ${SPACE}C

    ${baseboard_temp_rest}=  Read Attribute
    ...  /xyz/openbmc_project/sensors/temperature/pcie  Value
    ${baseboard_temp_rest}=  Evaluate  ${baseboard_temp_rest}/1000

    Should Be True
    ...  ${baseboard_temp_rest} - ${baseboard_temp_ipmi} <= ${allowed_temp_diff}
    ...  msg=Baseboard temperature above allowed threshold ${allowed_temp_diff}.


Retrieve Network Mode Via IPMI And Verify Using REST
    [Documentation]  Retrieve network mode from LAN print using IPMI.
    [Tags]  Retrieve_Network_Mode_Via_IPMI_And_Verify_Using_REST

    # Fetch "Mode" from IPMI LAN print.
    ${network_mode_ipmi}=  Fetch Details From LAN Print  Source

    # Verify "Mode" using REST.
    ${network_mode_rest}=  Read Attribute
    ...  ${NETWORK_MANAGER}eth0  DHCPEnabled
    Run Keyword If  '${network_mode_ipmi}' == 'Static Address'
    ...  Should Be Equal  ${network_mode_rest}  ${0}
    ...  msg=Verification of network setting failed.
    ...  ELSE IF  '${network_mode_ipmi}' == 'DHCP'
    ...  Should Be Equal  ${network_mode_rest}  ${1}
    ...  msg=Verification of network setting failed.


Verify Get Device ID
    [Documentation]  Verify get device ID command output.
    [Tags]  Verify_Get_Device_ID

    # Example of get device ID command output:
    # Device ID                 : 0
    # Device Revision           : 0
    # Firmware Revision         : 2.01
    # IPMI Version              : 2.0
    # Manufacturer ID           : 42817
    # Manufacturer Name         : Unknown (0xA741)
    # Product ID                : 16975 (0x424f)
    # Product Name              : Unknown (0x424F)
    # Device Available          : yes
    # Provides Device SDRs      : yes
    # Additional Device Support :
    #     Sensor Device
    #     SEL Device
    #     FRU Inventory Device
    #     Chassis Device
    # Aux Firmware Rev Info     :
    #     0x04
    #     0x38
    #     0x00
    #     0x03

    # Verify Manufacturer and Product IDs, etc. directly from json file.
    ${device_id_config}=  Get Device Id Config
    ${mc_info}=  Get MC Info

    Rprint Vars  device_id_config  mc_info
    Valid Value  ${mc_info['device_id']}  [${device_id_config['id']}]
    Valid Value  ${mc_info['device_revision']}  [${device_id_config['device_revision']}]

    # Get firmware revision from mc info command output i.e. 2.01
    ${ipmi_fw_major_version}  ${ipmi_fw_minor_version}=
    ...  Split String  ${mc_info['firmware_revision']}  .
    # Convert minor firmware version from BCD format to integer. i.e. 01 to 1
    ${ipmi_fw_minor_version}=  Convert To Integer  ${ipmi_fw_minor_version}

    # Get BMC version from BMC CLI i.e. 2.2 from "v2.2-253-g00050f1"
    ${bmc_version_full}=  Get BMC Version
    ${bmc_version}=
    ...  Remove String Using Regexp  ${bmc_version_full}  ^[^0-9]+  [^0-9\.].*

    # Get major and minor version from BMC version i.e. 2 and 1 from 2.1
    @{major_minor_version}=  Split String  ${bmc_version}  .

    Should Be Equal As Strings  ${ipmi_fw_major_version}  ${major_minor_version[0]}
    ...  msg=Major version mismatch.
    Should Be Equal As Strings  ${ipmi_fw_minor_version}  ${major_minor_version[1]}
    ...  msg=Minor version mismatch.

    Valid Value  mc_info['ipmi_version']  ['2.0']

    Valid Value  ${mc_info['manufacturer_id']}  [${device_id_config['manuf_id']}]
    ${product_id_hex} =  Convert To Hex  ${device_id_config['prod_id']}  lowercase=True
    Valid Value  mc_info['product_id']  ['${device_id_config['prod_id']} (0x${product_id_hex})']

    Valid Value  mc_info['device_available']  ['yes']
    Valid Value  mc_info['provides_device_sdrs']  ['yes']
    Should Contain  ${mc_info['additional_device_support']}  Sensor Device
    Should Contain  ${mc_info['additional_device_support']}  SEL Device
    Should Contain
    ...  ${mc_info['additional_device_support']}  FRU Inventory Device
    Should Contain  ${mc_info['additional_device_support']}  Chassis Device

    # Auxiliary revision data verification.
    ${aux_version}=  Get Aux Version  ${bmc_version_full}

    # From aux_firmware_rev_info field ['0x04', '0x38', '0x00', '0x03']
    ${bmc_aux_version}=  Catenate
    ...  SEPARATOR=
    ...  ${mc_info['aux_firmware_rev_info'][0][2:]}
    ...  ${mc_info['aux_firmware_rev_info'][1][2:]}
    ...  ${mc_info['aux_firmware_rev_info'][2][2:]}
    ...  ${mc_info['aux_firmware_rev_info'][3][2:]}

    Should Be Equal As Integers
    ...  ${bmc_aux_version}  ${aux_version}
    ...  msg=BMC aux version ${bmc_aux_version} does not match expected value of ${aux_version}.


Test IPMI Restriction Mode
    [Documentation]  Set restricition mode via REST and verify IPMI operation.
    [Tags]  Test_IPMI_Restriction_Mode
    # Forego normal test setup:
    [Setup]  No Operation
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Set IPMI Restriction Mode  xyz.openbmc_project.Control.Security.RestrictionMode.Modes.None

    # By default no IPMI operations are restricted.
    # /xyz/openbmc_project/control/host0/restriction_mode/attr/RestrictionMode
    # {
    #    "data": "xyz.openbmc_project.Control.Security.RestrictionMode.Modes.None",
    #    "message": "200 OK",
    #    "status": "ok"
    # }

    # Refer to: #openbmc/phosphor-host-ipmid/blob/master/host-ipmid-whitelist.conf
    # Set the restriction mode to Whitelist IPMI commands only:
    # /xyz/openbmc_project/control/host0/restriction_mode/attr/RestrictionMode
    # {
    #    "data": "xyz.openbmc_project.Control.Security.RestrictionMode.Modes.Whitelist",
    #    "message": "200 OK",
    #    "status": "ok"
    # }

    Set IPMI Restriction Mode  xyz.openbmc_project.Control.Security.RestrictionMode.Modes.Whitelist

    # Attempt white-listed operation expecting success.
    IPMI Power On

    # Attempt non white-listed operation expecting failure.
    Run Keyword And Expect Error  *Insufficient privilege level*
    ...  Run Inband IPMI Standard Command  lan set 1 access on


*** Keywords ***

Set Watchdog Enabled Using REST
    [Documentation]  Set watchdog Enabled field using REST.
    [Arguments]  ${value}

    # Description of argument(s):
    # value  Integer value (eg. "0-Disabled", "1-Enabled").

    ${value_dict}=  Create Dictionary  data=${value}
    ${resp}=  OpenBMC Put Request  ${HOST_WATCHDOG_URI}attr/Enabled
    ...  data=${value_dict}


Fetch Details From LAN Print
    [Documentation]  Fetch details from LAN print.
    [Arguments]  ${field_name}

    # Description of argument(s):
    # ${field_name}   Field name to be fetched from LAN print
    #                 (e.g. "MAC Address", "Source").

    ${stdout}=  Run IPMI Standard Command  lan print
    ${fetch_value}=  Get Lines Containing String  ${stdout}  ${field_name}
    ${value_fetch}=  Fetch From Right  ${fetch_value}  :${SPACE}
    [Return]  ${value_fetch}


Verify Power Reading
    [Documentation]  Get dcmi power reading via IPMI.

    # Example of power reading command output via IPMI.
    # Instantaneous power reading:                   235 Watts
    # Minimum during sampling period:                235 Watts
    # Maximum during sampling period:                235 Watts
    # Average power reading over sample period:      235 Watts
    # IPMI timestamp:                                Thu Jan  1 00:00:00 1970
    # Sampling period:                               00000000 Seconds.
    # Power reading state is:                        deactivated

    ${power_reading}=  Get IPMI Power Reading

    ${host_state}=  Get Host State
    Run Keyword If  '${host_state}' == 'Off'
    ...  Should Be Equal  ${power_reading['instantaneous_power_reading']}  0
    ...  msg=Power reading not zero when power is off.

    Run Keyword If  '${power_reading['instantaneous_power_reading']}' != '0'
    ...  Verify Power Reading Using REST  ${power_reading['instantaneous_power_reading']}


Verify Power Reading Via Raw Command
    [Documentation]  Get dcmi power reading via IPMI raw command.

    ${ipmi_raw_output}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['power_reading']['Get'][0]}

    @{raw_output_list}=  Split String  ${ipmi_raw_output}  ${SPACE}

    # On successful execution of raw IPMI power reading command, completion
    # code does not come in output. So current power value will start from 2
    # byte instead of 3.

    ${power_reading_ipmi_raw_3_item}=  Get From List  ${raw_output_list}  2
    ${power_reading_ipmi_raw_3_item}=
    ...  Convert To Integer  0x${power_reading_ipmi_raw_3_item}

    ${power_reading_rest}=  Read Attribute
    ...  ${SENSORS_URI}power/total_power  Value

    # Example of power reading via REST
    #  "CriticalAlarmHigh": 0,
    #  "CriticalAlarmLow": 0,
    #  "CriticalHigh": 3100000000,
    #  "CriticalLow": 0,
    #  "Scale": -6,
    #  "Unit": "xyz.openbmc_project.Sensor.Value.Unit.Watts",
    #  "Value": 228000000,
    #  "WarningAlarmHigh": 0,
    #  "WarningAlarmLow": 0,
    #  "WarningHigh": 3050000000,
    #  "WarningLow": 0

    # Get power value based on scale i.e. Value * (10 power Scale Value)
    # e.g. from above case 228000000 * (10 power -6) = 228000000/1000000

    ${power_reading_rest}=  Evaluate  ${power_reading_rest}/1000000
    ${ipmi_rest_power_diff}=
    ...  Evaluate  abs(${power_reading_rest} - ${power_reading_ipmi_raw_3_item})

    Should Be True  ${ipmi_rest_power_diff} <= ${allowed_power_diff}
    ...  msg=Power Reading above allowed threshold ${allowed_power_diff}.


Verify Power Reading Using REST
    [Documentation]  Verify power reading using REST.
    [Arguments]  ${power_reading}

    # Description of argument(s):
    # power_reading  IPMI Power reading

    ${power_reading_rest}=  Read Attribute
    ...  ${SENSORS_URI}power/total_power  Value

    # Example of power reading via REST
    #  "CriticalAlarmHigh": 0,
    #  "CriticalAlarmLow": 0,
    #  "CriticalHigh": 3100000000,
    #  "CriticalLow": 0,
    #  "Scale": -6,
    #  "Unit": "xyz.openbmc_project.Sensor.Value.Unit.Watts",
    #  "Value": 228000000,
    #  "WarningAlarmHigh": 0,
    #  "WarningAlarmLow": 0,
    #  "WarningHigh": 3050000000,
    #  "WarningLow": 0

    # Get power value based on scale i.e. Value * (10 power Scale Value)
    # e.g. from above case 228000000 * (10 power -6) = 228000000/1000000
    ${power_reading_rest}=  Evaluate  ${power_reading_rest}/1000000
    ${ipmi_rest_power_diff}=
    ...  Evaluate  abs(${power_reading_rest} - ${power_reading})

    Should Be True  ${ipmi_rest_power_diff} <= ${allowed_power_diff}
    ...  msg=Power reading above allowed threshold ${allowed_power_diff}.


Set IPMI Restriction Mode
    [Documentation]  Set the IPMI restriction mode.
    [Arguments]  ${restriction_mode}

    # Description of argument(s):
    # restriction_mode   IPMI valid restriction modes.

    ${valueDict}=  Create Dictionary  data=${restriction_mode}

    Write Attribute  ${CONTROL_HOST_URI}restriction_mode/
    ...  RestrictionMode  data=${valueDict}
