*** Settings ***
Documentation       This suite is for testing general IPMI functions.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../lib/boot_utils.robot
Library             ../../lib/ipmi_utils.py
Resource            ../../lib/bmc_network_utils.robot

Suite Setup         Suite Setup Execution
Test Teardown       FFDC On Test Case Fail

*** Variables ***

${new_mc_id}=  HOST
${allowed_temp_diff}=  ${1}
${allowed_power_diff}=  ${10}

*** Test Cases ***

Set Asset Tag With Valid String Length
    [Documentation]  Set asset tag with valid string length and verify.
    [Tags]  Set_Asset_Tag_With_Valid_String_Length

    # Allowed MAX characters length for asset tag name is 63.
    ${random_string}=  Generate Random String  63
    Run Keyword  Run IPMI Standard Command  dcmi set_asset_tag ${random_string}

    ${asset_tag}=  Run Keyword  Run IPMI Standard Command  dcmi asset_tag
    Should Contain  ${asset_tag}  ${random_string}


Set Asset Tag With Invalid String Length
    [Documentation]  Verify error while setting invalid asset tag via IPMI.
    [Tags]  Set_Asset_Tag_With_Invalid_String_Length

    # Any string more than 63 character is invalid for asset tag.
    ${random_string}=  Generate Random String  64

    ${resp}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  dcmi set_asset_tag ${random_string}
    Should Contain  ${resp}  Parameter out of range  ignore_case=True


Set Asset Tag With Valid String Length Via REST
    [Documentation]  Set valid asset tag via REST and verify.
    [Tags]  Set_Asset_Tag_With_Valid_String_Length_Via_REST

    ${random_string}=  Generate Random String  63
    ${args}=  Create Dictionary  data=${random_string}
    Write Attribute  /xyz/openbmc_project/inventory/system  AssetTag
    ...  data=${args}

    ${asset_tag}=  Read Attribute  /xyz/openbmc_project/inventory/system
    ...  AssetTag
    Should Be Equal As Strings  ${asset_tag}  ${random_string}


Verify Get And Set Management Controller ID String
    [Documentation]  Verify get and set management controller ID string.
    [Tags]  Verify_Get_And_Set_Management_Controller_ID_String

    # Get the value of the managemment controller ID string.
    # Example:
    # Get Management Controller Identifier String: witherspoon

    ${cmd_output}=  Run IPMI Standard Command  dcmi get_mc_id_string

    # Extract management controller ID from cmd_output.
    ${initial_mc_id}=  Fetch From Right  ${cmd_output}  :${SPACE}

    # Set the management controller ID string to other value.
    # Example:
    # Set Management Controller Identifier String Command: HOST

    Set Management Controller ID String  ${new_mc_id}

    # Get the management controller ID and verify.
    Get Management Controller ID String And Verify  ${new_mc_id}

    # Set the value back to the initial value and verify.
    Set Management Controller ID String  ${initial_mc_id}

    # Get the management controller ID and verify.
    Get Management Controller ID String And Verify  ${initial_mc_id}


Verify Chassis Identify via IPMI
    [Documentation]  Verify "chassis identify" using IPMI command.
    [Tags]  Verify_Chassis_Identify_via_IPMI

    # Set to default "chassis identify" and verify that LED blinks for 15s.
    Run IPMI Standard Command  chassis identify
    Verify Identify LED State  Blink

    Sleep  15s
    Verify Identify LED State  Off

    # Set "chassis identify" to 10s and verify that the LED blinks for 10s.
    Run IPMI Standard Command  chassis identify 10
    Verify Identify LED State  Blink

    Sleep  10s
    Verify Identify LED State  Off


Verify Chassis Identify Off And Force Identify On via IPMI
    [Documentation]  Verify "chassis identify" off
    ...  and "force identify on" via IPMI.
    [Tags]  Verify_Chassis_Identify_Off_And_Force_Identify_On_via_IPMI

    # Set the LED to "Force Identify On".
    Run IPMI Standard Command  chassis identify force
    Verify Identify LED State  Blink

    # Set "chassis identify" to 0 and verify that the LED turns off.
    Run IPMI Standard Command  chassis identify 0
    Verify Identify LED State  Off


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


Verify Get DCMI Capabilities
    [Documentation]  Verify get DCMI capabilities command output.
    [Tags]  Verify_Get_DCMI_Capabilities

    ${cmd_output}=  Run IPMI Standard Command  dcmi discover

    @{supported_capabilities}=  Create List
    # Supported DCMI capabilities:
    ...  Mandatory platform capabilties
    ...  Optional platform capabilties
    ...  Power management available
    ...  Managebility access capabilties
    ...  In-band KCS channel available
    # Mandatory platform attributes:
    ...  200 SEL entries
    ...  SEL automatic rollover is enabled
    # Optional Platform Attributes:
    ...  Slave address of device: 0h (8bits)(Satellite/External controller)
    ...  Channel number is 0h (Primary BMC)
    ...  Device revision is 0
    # Manageability Access Attributes:
    ...  Primary LAN channel number: 1 is available
    ...  Secondary LAN channel is not available for OOB
    ...  No serial channel is available

    :FOR  ${capability}  IN  @{supported_capabilities}
    \  Should Contain  ${cmd_output}  ${capability}  ignore_case=True
    ...  msg=Supported DCMI capabilities not present.


Test Power Reading Via IPMI With Host Booted
    [Documentation]  Test power reading via IPMI with host booted state and
    ...  verify using REST.
    [Tags]  Test_Power_Reading_Via_IPMI_With_Host_Booted

    REST Power On  stack_mode=skip  quiet=1

    Verify Power Reading via IPMI


Test Power Reading Via IPMI With Host Off
    [Documentation]  Test power reading via IPMI with host off state and
    ...  verify using REST.
    [Tags]  Test_Power_Reading_Via_IPMI_With_Host_Off

    Initiate Host Power Off

    Verify Power Reading via IPMI


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


Retrieve Default Gateway Via IPMI And Verify Using REST
    [Documentation]  Retrieve default gateway from LAN print using IPMI.
    [Tags]  Retrieve_Default_Gateway_Via_IPMI_And_Verify_Using_REST

    # Fetch "Default Gateway" from IPMI LAN print.
    ${default_gateway_ipmi}=  Fetch Details From LAN Print  Default Gateway IP

    # Verify "Default Gateway" using REST.
    Read Attribute  ${NETWORK_MANAGER}/config  DefaultGateway
    ...  expected_value=${default_gateway_ipmi}


Retrieve MAC Address Via IPMI And Verify Using REST
    [Documentation]  Retrieve MAC Address from LAN print using IPMI.
    [Tags]  Retrieve_MAC_Address_Via_IPMI_And_Verify_Using_REST

    # Fetch "MAC Address" from IPMI LAN print.
    ${mac_address_ipmi}=  Fetch Details From LAN Print  MAC Address

    # Verify "MAC Address" using REST.
    ${mac_address_rest}=  Get BMC MAC Address
    Should Be Equal  ${mac_address_ipmi}  ${mac_address_rest}
    ...  msg=Verification of MAC address from lan print using IPMI failed.


Retrieve Network Mode Via IPMI And Verify Using REST
    [Documentation]  Retrieve network mode from LAN print using IPMI.
    [Tags]  Retrieve_Network_Mode_Via_IPMI_And_Verify_Using_REST

    # Fetch "Mode" from IPMI LAN print.
    ${network_mode_ipmi}=  Fetch Details From LAN Print  Source

    # Verify "Mode" using REST.
    ${network_mode_rest}=  Read Attribute
    ...  ${NETWORK_MANAGER}/eth0  DHCPEnabled
    Run Keyword If  '${network_mode_ipmi}' == 'Static Address'
    ...  Should Be Equal  ${network_mode_rest}  ${0}
    ...  msg=Verification of network setting failed.
    ...  ELSE  IF  '${network_mode_ipmi}' == 'DHCP'
    ...  Should Be Equal  ${network_mode_rest}  ${1}
    ...  msg=Verification of network setting failed.


Retrieve IP Address Via IPMI And Verify With BMC Details
    [Documentation]  Retrieve IP address from LAN print using IPMI.
    [Tags]  Retrieve_IP_Address_Via_IPMI_And_Verify_With_BMC_Details

    # Fetch "IP Address" from IPMI LAN print.
    ${ip_addr_ipmi}=  Fetch Details From LAN Print  IP Address

    # Verify the IP address retrieved via IPMI with BMC IPs.
    ${ip_address_rest}=  Get BMC IP Info
    Validate IP On BMC  ${ip_addr_ipmi}  ${ip_address_rest}


*** Keywords ***


Set Management Controller ID String
    [Documentation]  Set the management controller ID string.
    [Arguments]  ${string}

    # Description of argument(s):
    # string  Management Controller ID String to be set

    ${set_mc_id_string}=  Run IPMI Standard Command
    ...  dcmi set_mc_id_string ${string}


Get Management Controller ID String And Verify
    [Documentation]  Get the management controller ID sting.
    [Arguments]  ${string}

    # Description of argument(s):
    # string  Management Controller ID string

    ${get_mc_id}=  Run IPMI Standard Command  dcmi get_mc_id_string
    Should Contain  ${get_mc_id}  ${string}
    ...  msg=Command failed: get_mc_id.


Verify Identify LED State
    [Documentation]  Verify the identify LED state
    ...  matches caller's expectations.
    [Arguments]  ${expected_state}

    # Description of argument(s):
    # expected_state  The LED state expected by the caller ("Blink" or "Off").

    ${resp}=  Read Attribute  ${LED_PHYSICAL_URI}/front_id  State
    Should Be Equal  ${resp}  xyz.openbmc_project.Led.Physical.Action.${expected_state}
    ...  msg=Unexpected LED state.

    ${resp}=  Read Attribute  ${LED_PHYSICAL_URI}/rear_id  State
    Should Be Equal  ${resp}  xyz.openbmc_project.Led.Physical.Action.${expected_state}
    ...  msg=Unexpected LED state.


Set Watchdog Enabled Using REST
    [Documentation]  Set watchdog Enabled field using REST.
    [Arguments]  ${value}

    # Description of argument(s):
    # value  Integer value (eg. "0-Disabled", "1-Enabled").

    ${value_dict}=  Create Dictionary  data=${value}
    ${resp}=  OpenBMC Put Request  ${HOST_WATCHDOG_URI}/attr/Enabled
    ...  data=${value_dict}


Log LAN Print Details
    [Documentation]  Log IPMI LAN print details and return them as a string.

    # Example:

    # Set in Progress        : Set Complete
    # Auth Type Support      : MD5
    # Auth Type Enable       : Callback : MD5
    #                        : User     : MD5
    #                        : Operator : MD5
    #                        : Admin    : MD5
    #                        : OEM      : MD5
    # IP Address Source      : Static Address
    # IP Address             : xx.xx.xx.xx
    # Subnet Mask            : yy.yy.yy.yy
    # MAC Address            : xx.xx.xx.xx.xx.xx
    # Default Gateway IP     : xx.xx.xx.xx
    # 802.1q VLAN ID         : Disabled Cipher Suite
    # Priv Max               : Not Available
    # Bad Password Threshold : Not Available

    Login To OS Host
    Check If IPMI Tool Exist

    ${cmd_buf}=  Catenate  ${IPMI_INBAND_CMD}  lan print

    ${stdout}  ${stderr}  ${rc}=  OS Execute Command  ${cmd_buf}
    Log  ${stdout}
    [Return]  ${stdout}


Fetch Details From LAN Print
    [Documentation]  Fetch details from LAN print.
    [Arguments]  ${field_name}

    # Description of argument(s):
    # ${field_name}   Field name to be fetched from LAN print
    #                 (e.g. "MAC Address", "Source").

    ${stdout}=  Log LAN Print Details
    ${fetch_value}=  Get Lines Containing String  ${stdout}  ${field_name}
    ${value_fetch}=  Fetch From Right  ${fetch_value}  :${SPACE}
    [Return]  ${value_fetch}


Verify Power Reading via IPMI
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
    ${power_reading_ipmi}=  Set Variable
    ...  ${power_reading['instantaneous_power_reading']}
    ${power_reading_ipmi}=  Remove String  ${power_reading_ipmi}  ${SPACE}Watts

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
    ...  Evaluate  abs(${power_reading_rest} - ${power_reading_ipmi})

    Should Be True  ${ipmi_rest_power_diff} <= ${allowed_power_diff}
    ...  msg=Power reading above allowed threshold ${allowed_power_diff}.


Suite Setup Execution
    [Documentation]  Do the suite setup execution tasks.

    Should Not Be Empty
    ...  ${OS_HOST}  msg=You must provide DNS name/IP of the OS host.
    Should Not Be Empty
    ...  ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...  ${OS_PASSWORD}  msg=You must provide OS host user password.

    # Boot To OS
    REST Power On  quiet=${1}

