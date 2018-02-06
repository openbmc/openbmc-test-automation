*** Settings ***
Documentation       This suite is for testing general IPMI functions.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/bmc_network_utils.robot

Test Teardown       FFDC On Test Case Fail

*** Variables ***

${new_mc_id}=  HOST

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


Retrieve Default Gateway Via IPMI And Verify Using REST
    [Documentation]  Retrieve default gateway from LAN print using IPMI.
    [Tags]  Retrieve_Default_Gateway_Via_IPMI_And_Verify_Using_REST

    # Fetch "Default Gateway" from IPMI LAN print.
    ${default_gateway_ipmi}=  Fetch Details From LAN Print  Default Gateway IP

    # Verify "Default Gateway" using REST.
    Read Attribute  ${XYZ_NETWORK_MANAGER}/config  DefaultGateway
    ...  expected_value=${default_gateway_ipmi}

    Set Global Variable  ${default_gateway_ipmi}


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
    ...  ${XYZ_NETWORK_MANAGER}/eth0  DHCPEnabled
    Run Keyword If  '${network_mode_ipmi}' == 'Static Address'
    ...  Should Be Equal  ${network_mode_rest}  ${0}
    ...  msg=Verification of DHCP network setting failed.


Retrieve IP Address Via IPMI And Verify With BMC Details
    [Documentation]  Retrieve IP address from LAN print using IPMI.
    [Tags]  Retrieve_IP_Address_Via_IPMI_And_Verify_With_BMC_Details

    # Fetch "IP Address" from IPMI LAN print.
    ${ip_addr_ipmi}=  Fetch Details From LAN Print  IP Address

    # Verify the IP address retrieved via IPMI with BMC IPs.
    ${ip_address_rest}=  Get BMC IP Info
    Validate IP On BMC  ${ip_addr_ipmi}  ${ip_address_rest}

    Set Global Variable  ${ip_addr_ipmi}


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
