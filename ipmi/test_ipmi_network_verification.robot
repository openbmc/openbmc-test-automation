*** Settings ***

Documentation          Module to test IPMI network functionality.
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/bmc_network_utils.robot
Library                ../lib/ipmi_utils.py
Library                ../lib/gen_robot_valid.py
Library                ../lib/var_funcs.py
Library                ../lib/bmc_network_utils.py
Variables              ../data/ipmi_raw_cmd_table.py

Suite Setup            Redfish.Login
Test Setup             Printn
Test Teardown          FFDC On Test Case Fail

Force Tags             Ipmi_Network_Verification


*** Variables ***
${set_mac_address}                      02:f4:43:24:e7:1a
${Invalid_mac_address}                  11:f4:43:24:e7:1a


*** Test Cases ***

Retrieve IP Address Via IPMI And Verify Using Redfish
    [Documentation]  Retrieve IP address using IPMI and verify using Redfish.
    [Tags]  Retrieve_IP_Address_Via_IPMI_And_Verify_Using_Redfish

    ${active_channel_config}=  Get Active Channel Config
    FOR  ${channel_number}  IN  @{active_channel_config.keys()}
      Verify Channel Info  ${channel_number}  IPv4StaticAddresses  ${active_channel_config}
    END

Retrieve Default Gateway Via IPMI And Verify
    [Documentation]  Retrieve default gateway via IPMI and verify it's existence on the BMC.
    [Tags]  Retrieve_Default_Gateway_Via_IPMI_And_Verify

    ${lan_print_ipmi}=  Get LAN Print Dict

    Verify Gateway On BMC  ${lan_print_ipmi['Default Gateway IP']}


Retrieve MAC Address Via IPMI And Verify Using Redfish
    [Documentation]  Retrieve MAC address via IPMI and verify using Redfish.
    [Tags]  Retrieve_MAC_Address_Via_IPMI_And_Verify_Using_Redfish

    ${active_channel_config}=  Get Active Channel Config
    FOR  ${channel_number}  IN  @{active_channel_config.keys()}
      Verify Channel Info  ${channel_number}  MACAddress  ${active_channel_config}
    END


Test Valid IPMI Channels Supported
    [Documentation]  Verify IPMI channels supported on a given system.
    [Tags]  Test_Valid_IPMI_Channels_Supported

    ${channel_count}=  Get Physical Network Interface Count
    Should Be True  ${channel_count} > 0
    ...  msg=IPMI Lan channel support expected > 0 but found ${channel_count}
    ${channel_count}=  Evaluate  ${channel_count} + 1

    # Note: IPMI network channel logically starts from 1.
    FOR  ${channel_number}  IN RANGE  1  ${channel_count}
      Run IPMI Standard Command  lan print ${channel_number}
    END


Test Invalid IPMI Channel Response
    [Documentation]  Verify invalid IPMI channels supported response.
    [Tags]  Test_Invalid_IPMI_Channel_Response

    ${channel_count}=  Get Physical Network Interface Count

    # To target invalid channel, increment count.
    ${channel_number}=  Evaluate  ${channel_count} + 1

    # Example of invalid channel:
    # $ ipmitool -I lanplus -H xx.xx.xx.xx -P password lan print 3
    # Get Channel Info command failed: Parameter out of range
    # Invalid channel: 3

    ${stdout}=  Run External IPMI Standard Command
    ...  lan print ${channel_number}  fail_on_err=${0}
    Should Contain  ${stdout}  Invalid channel
    ...  msg=IPMI channel ${channel_number} is invalid but seen working.


Get IP Address Source And Verify Using Redfish
    [Documentation]  Get IP address source and verify it using Redfish.
    [Tags]  Get_IP_Address_Source_And_Verify_Using_Redfish

    ${active_channel_config}=  Get Active Channel Config
    ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}

    ${ipv4_addresses}=  Redfish.Get Attribute
    ...  /redfish/v1/Managers/${MANAGER_ID}/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}
    ...  IPv4Addresses

    FOR  ${ipv4_address}  IN  @{ipv4_addresses}
      ${ip_address_source}=
      ...  Set Variable if  '${ipv4_address['Address']}' == '${lan_config['IP Address']}'
      ...  ${ipv4_address['AddressOrigin']} Address
      Exit For Loop IF  "${ip_address_source}" != 'None'
    END

    Valid Value  lan_config['IP Address Source']  ['${ip_address_source}']


Verify Get Set In Progress
    [Documentation]  Verify Get Set In Progress which belongs to LAN Configuration Parameters
    ...              via IPMI raw Command.
    [Tags]  Verify_Get_Set_In_Progress

    ${ipmi_output}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['LAN_Config_Params']['Get'][0]} ${CHANNEL_NUMBER} 0x00 0x00 0x00

    ${ipmi_output}=  Split String  ${ipmi_output}
    ${set_in_progress_value}=  Set Variable  ${ipmi_output[1]}

    # 00b = set complete.
    # 01b = set in progress.
    Should Contain Any  ${set_in_progress_value}  00  01


Verify Cipher Suite Entry Count
    [Documentation]  Verify cipher suite entry count which belongs to LAN Configuration Parameters
    ...              via IPMI raw Command.
    [Tags]  Verify_Cipher_Suite_Entry_Count

    ${ipmi_output}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['LAN_Config_Params']['Get'][0]} ${CHANNEL_NUMBER} 0x16 0x00 0x00
    ${cipher_suite_entry_count}=  Split String  ${ipmi_output}

    # Convert minor cipher suite entry count from BCD format to integer. i.e. 01 to 1.
    ${cipher_suite_entry_count[1]}=  Convert To Integer  ${cipher_suite_entry_count[1]}
    ${cnt}=  Get length  ${valid_ciphers}

    Should be Equal  ${cipher_suite_entry_count[1]}  ${cnt}


Verify Authentication Type Support
    [Documentation]  Verify authentication type support which belongs to LAN Configuration Parameters
    ...              via IPMI raw Command.
    [Tags]  Verify_Authentication_Type_Support

    ${ipmi_output}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['LAN_Config_Params']['Get'][0]} ${CHANNEL_NUMBER} 0x01 0x00 0x00

    ${authentication_type_support}=  Split String  ${ipmi_output}
    # All bits:
    # 1b = supported
    # 0b = authentication type not available for use
    # [5] - OEM proprietary (per OEM identified by the IANA OEM ID in the RMCP Ping Response)
    # [4] - straight password / key
    # [3] - reserved
    # [2] - MD5
    # [1] - MD2
    # [0] - none
    Should Contain Any  ${authentication_type_support[1]}  00  01  02  03  04  05


Verify Set In Progress
    [Documentation]  Verify Set In Progress which belongs to LAN Configuration Parameters
    ...              via IPMI raw Command.
    [Tags]  Verify_Set_In_Progress

   # Set the Set In Progress
    ${output_msg}=  Run Inband IPMI Raw Command
    ...  ${IPMI_RAW_CMD['LAN_Config_Params']['Set'][0]} ${CHANNEL_NUMBER} 0x00 0x01

    # Get the Set In Progress
    ${ipmi_output}=  Run Inband IPMI Raw Command
    ...  ${IPMI_RAW_CMD['LAN_Config_Params']['Get'][0]} ${CHANNEL_NUMBER} 0x00 0x00 0x00

    # Verify the response
    ${ipmi_output}=  Split String  ${ipmi_output}
    ${set_in_progress_value}=  Set Variable  ${ipmi_output[1]}

    # 01b = set in progress.
    Should be Equal  ${set_in_progress_value}  01

    # set back to default.
    Run IPMI Command  ${IPMI_RAW_CMD['LAN_Config_Params']['Set'][0]} ${CHANNEL_NUMBER} 0x00 0x00

    # Get the Set In Progress.
    ${ipmi_output}=  Run Inband IPMI Raw Command
    ...  ${IPMI_RAW_CMD['LAN_Config_Params']['Get'][0]} ${CHANNEL_NUMBER} 0x00 0x00 0x00

    # Verify the response.
    ${ipmi_output}=  Split String  ${ipmi_output}
    ${set_in_progress_value}=  Set Variable  ${ipmi_output[1]}

    # 00b = set complete.
    Should be Equal  ${set_in_progress_value}  00


Verify Invalid Set MAC Address Via IPMI
    [Documentation]  Verify Get and Set MAC address via IPMI.
    [Tags]  Verify_Invalid_Set_MAC_Address_Via_IPMI

    # MAC to hexa string.
    ${Invalid_mac_address_hex}=  Mac Address To Hex String  ${Invalid_mac_address}

    # Set MAC Address with invalid data.
    ${cmd}=  Catenate  ${IPMI_RAW_CMD['LAN_Config_Params']['Set'][0]} ${CHANNEL_NUMBER}
    ...  0x05 ${Invalid_mac_address_hex}  fail_on_err=0
    ${ipmi_set_output}=  Run Inband IPMI Raw Command  ${cmd}

    Should Contain  ${ipmi_set_output}  ${IPMI_RAW_CMD['LAN_Config_Params']['Set'][3]}


Verify Get And Set MAC Address Via IPMI
    [Documentation]  Verify Get and Set MAC address via IPMI.
    [Tags]  Verify_Get_And_Set_MAC_Address_Via_IPMI
    [Setup]  Fetch The Default Mac Address
    [Teardown]  Set Default Mac And Verify  ${ipmi_default_mac_split}

    # MAC to hexa string.
    ${mac_address_hex}=  Mac Address To Hex String  ${set_mac_address}

    # Set the MAC address.
    ${cmd}=  Catenate  ${IPMI_RAW_CMD['LAN_Config_Params']['Set'][0]} ${CHANNEL_NUMBER}
    ...  0x05 ${mac_address_hex}  fail_on_err=0
    ${ipmi_set_output}=  Run Inband IPMI Raw Command  ${cmd}

    # Get the MAC address and verify.
    ${ipmi_output}=  Run Inband IPMI Raw Command
    ...  ${IPMI_RAW_CMD['LAN_Config_Params']['Get'][0]} ${CHANNEL_NUMBER} 0x05 0x00 0x00
    ${ipmi_output_split}=  Split String  ${ipmi_output}
    ${get_mac}=   Evaluate  ":".join(${ipmi_output_split[1:]})

    Should be Equal  ${get_mac}  ${set_mac_address}


Verify Cipher Suite Privilege
    [Documentation]  Verify cipher suite privilege which belongs to LAN Configuration Parameters
    ...              via IPMI raw Command.
    [Tags]  Verify_Cipher_Suite_Privilege

    # Get the Cipher Suite privilege and verify the response.
    ${ipmi_output}=  Run Inband IPMI Raw Command
    ...  ${IPMI_RAW_CMD['LAN_Config_Params']['Get'][0]} ${CHANNEL_NUMBER} 0x18 0x00 0x00
    ${cipher_suite_privilege}=  Split String  ${ipmi_output}

    Should be Equal  '${${cipher_suite_privilege}[0]}'  '11'
    # 00b = reserved.
    Should Contain Any  '${cipher_suite_privilege[1]}'  '00'  '0'

    ${cipher_suite_privilege_length}=  Get length  ${cipher_suite_privilege}
    Should be Equal  '${cipher_suite_privilege_length}'  '10'

    #44b = Maximum privilege for cipher suite.
    FOR  ${channel_number}  IN RANGE  2  ${cipher_suite_privilege_length}
      Should be Equal  '${cipher_suite_privilege[${channel_number}]}'  '44'
    END


Verify Set On Authentication Type
    [Documentation]  Verify Set On Authentication Type which belongs to LAN Configuration Parameters
    ...              via IPMI raw Command.
    [Tags]  Verify_Set_On_Authentication_Type

    # Set Authentication Type and expect error.
    ${ipmi_output}=  Run Inband IPMI Raw Command
    ...  ${IPMI_RAW_CMD['LAN_Config_Params']['Set'][0]} ${CHANNEL_NUMBER} 0x01 0x01  fail_on_err=0

    Should Contain  ${ipmi_output}  ${IPMI_RAW_CMD['LAN_Config_Params']['Set'][2]}


Verify IP Address Source Set To Address Loaded By BIOS
    [Documentation]  Verify Set IP Address Source to address loaded by BIOS or system software via IPMI.
    [Tags]  Verify_IP_Address_Source_Set_To_Address_Loaded_By_BIOS

    # Set IP address source to address loaded by BIOS or system software.
    ${ipmi_output}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['LAN_Config_Params']['Set'][3]}*
    ...  Run Inband IPMI Raw Command
    ...  ${IPMI_RAW_CMD['LAN_Config_Params']['Set'][0]} 0x0${CHANNEL_NUMBER} 0x04 0x03


Verify IP Address Source Set To Address Obtained By BMC
    [Documentation]  Verify Set IP Address Source to address obtained by,
    ...              BMC running other address assignment protocol via IPMI.
    [Tags]  Verify_IP_Address_Source_Set_To_Address_Obtained_By_BMC

    # Set IP address source to address obtained by BMC running other address assignment protocol
    ${ipmi_output}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['LAN_Config_Params']['Set'][3]}*
    ...  Run Inband IPMI Raw Command
    ...  ${IPMI_RAW_CMD['LAN_Config_Params']['Set'][0]} 0x0${CHANNEL_NUMBER} 0x04 0x04


Verify IP Address Source Set To Unspecified Address Source
    [Documentation]  Verify Set IP Address source to unspecified address source via IPMI.
    [Tags]  Verify_IP_Address_Source_Set_To_Unspecified_Address_Source

    # Set IP address source to unspecified address source.
    ${ipmi_output}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['LAN_Config_Params']['Set'][3]}*
    ...  Run Inband IPMI Raw Command
    ...  ${IPMI_RAW_CMD['LAN_Config_Params']['Set'][0]} 0x0${CHANNEL_NUMBER} 0x04 0x00


*** Keywords ***

Get Physical Network Interface Count
    [Documentation]  Return valid physical network interfaces count.
    # Example:
    # link/ether 22:3a:7f:70:92:cb brd ff:ff:ff:ff:ff:ff
    # link/ether 0e:8e:0d:6b:e9:e4 brd ff:ff:ff:ff:ff:ff

    ${mac_entry_list}=  Get BMC MAC Address List
    ${mac_unique_list}=  Remove Duplicates  ${mac_entry_list}
    ${physical_interface_count}=  Get Length  ${mac_unique_list}

    [Return]  ${physical_interface_count}


Verify Channel Info
    [Documentation]  Verify the channel info.
    [Arguments]  ${channel_number}  ${network_parameter}  ${active_channel_config}

    Run Keyword If  '${network_parameter}' == 'IPv4StaticAddresses'
    ...    Verify IPv4 Static Address  ${channel_number}  ${active_channel_config}
    ...  ELSE IF  '${network_parameter}' == 'MACAddress'
    ...    Verify MAC Address  ${channel_number}  ${active_channel_config}


Verify IPv4 Static Address
    [Documentation]  Verify the IPv4 Static Address.
    [Arguments]  ${channel_number}  ${active_channel_config}

    ${lan_print_ipmi}=  Get LAN Print Dict  ${channel_number}
    ${ipv4_static_addresses}=  Redfish.Get Attribute
    ...  ${REDFISH_NW_ETH_IFACE}${active_channel_config['${channel_number}']['name']}  IPv4StaticAddresses
    ${redfish_ips}=  Nested Get  Address  ${ipv4_static_addresses}
    Rprint Vars  lan_print_ipmi  ipv4_static_addresses  redfish_ips
    Valid Value  lan_print_ipmi['IP Address']  ${redfish_ips}


Verify MAC Address
    [Documentation]  Verify the MAC Address.
    [Arguments]  ${channel_number}  ${active_channel_config}

    ${lan_print_ipmi}=  Get LAN Print Dict  ${channel_number}
    ${redfish_mac_address}=  Redfish.Get Attribute
    ...  ${REDFISH_NW_ETH_IFACE}${active_channel_config['${channel_number}']['name']}  MACAddress
    Rprint Vars  lan_print_ipmi  redfish_mac_address
    Valid Value  lan_print_ipmi['MAC Address']  ['${redfish_mac_address}']


Fetch The Default Mac Address
    [Documentation]  Fetch The Default MAC Address.

     # Get Default MAC Address.
    ${ipmi_get_default_mac}=  Run Inband IPMI Raw Command
    ...  ${IPMI_RAW_CMD['LAN_Config_Params']['Get'][0]} ${CHANNEL_NUMBER} 0x05 0x00 0x00
    Set Test Variable  ${ipmi_get_default_mac}

    # After splitting, list will have each byte of MAC address.
    ${ipmi_default_mac_split}=  Split String  ${ipmi_get_default_mac}
    Set Test Variable  ${ipmi_default_mac_split}


Set Default Mac And Verify
    [Documentation]  Set Default Mac And Verify.
    [Arguments]  ${default_mac}=${ipmi_default_mac_split}

    ${set_default_mac}=   Evaluate  ":".join(${default_mac[1:]})
    ${default_mac_address_hex}=  Mac Address To Hex String  ${set_default_mac}

    # Set the Default MAC address.
    ${cmd}=  Catenate  ${IPMI_RAW_CMD['LAN_Config_Params']['Set'][0]} ${CHANNEL_NUMBER}
    ...  0x05 ${default_mac_address_hex}  fail_on_err=0
    ${ipmi_set_output}=  Run Inband IPMI Raw Command  ${cmd}

    # check whether the default MAC is set.
    ${ipmi_get_mac}=  Run Inband IPMI Raw Command
    ...  ${IPMI_RAW_CMD['LAN_Config_Params']['Get'][0]} ${CHANNEL_NUMBER} 0x05 0x00 0x00

    ${ipmi_out}=  Split String  ${ipmi_get_mac}
    Should be Equal  ${default_mac}  ${ipmi_out}
