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

${initial_lan_config}   &{EMPTY}


*** Test Cases ***

Retrieve IP Address Via IPMI And Verify Using Redfish
    [Documentation]  Retrieve IP address using IPMI and verify using Redfish.
    [Tags]  Retrieve_IP_Address_Via_IPMI_And_Verify_Using_Redish

    ${active_channel_config}=  Get Active Channel Config
    :FOR  ${channel_number}  IN  @{active_channel_config.keys()}
    \  Verify Channel Info  ${channel_number}  IPv4StaticAddresses  ${active_channel_config}
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
    :FOR  ${channel_number}  IN  @{active_channel_config.keys()}
    \  Verify Channel Info  ${channel_number}  MACAddress  ${active_channel_config}
    END


Test Valid IPMI Channels Supported
    [Documentation]  Verify IPMI channels supported on a given system.
    [Tags]  Test_Valid_IPMI_Channels_Supported

    ${channel_count}=  Get Physical Network Interface Count

    # Note: IPMI network channel logically starts from 1.
    :FOR  ${channel_number}  IN RANGE  1  ${channel_count}
    \  Run IPMI Standard Command  lan print ${channel_number}


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


Verify IPMI Inband Network Configuration
    [Documentation]  Verify BMC network configuration via inband IPMI.
    [Tags]  Verify_IPMI_Inband_Network_Configuration
    [Teardown]  Run Keywords  Restore Configuration  AND  FFDC On Test Case Fail

    Redfish Power On
    ${initial_lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Set Suite Variable  ${initial_lan_config}

    Set IPMI Inband Network Configuration  10.10.10.10  255.255.255.0  10.10.10.10
    Sleep  10

    ${lan_print_output}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Valid Value  lan_print_output['IP Address']  ["10.10.10.10"]
    Valid Value  lan_print_output['Subnet Mask']  ["255.255.255.0"]
    Valid Value  lan_print_output['Default Gateway IP']  ["10.10.10.10"]


Get IP Address Source And Verify Using Redfish
    [Documentation]  Get IP address source and verify it using Redfish.
    [Tags]  Get_IP_Address_Source_And_Verify_Using_Redfish

    ${active_channel_config}=  Get Active Channel Config
    ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}

    ${ipv4_addresses}=  Redfish.Get Attribute
    ...  /redfish/v1/Managers/bmc/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}  IPv4Addresses

    FOR  ${ipv4_address}  IN  @{ipv4_addresses}
          ${ip_address_source}=  Set Variable if  '${ipv4_address['Address']}' == '${lan_config['IP Address']}'
          ...  ${ipv4_address['AddressOrigin']} Address
          Exit For Loop IF  "${ip_address_source}" != 'None'
    END

    Valid Value  lan_config['IP Address Source']  [${ip_address_source}]


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


Set IPMI Inband Network Configuration
    [Documentation]  Run sequence of standard IPMI command in-band and set
    ...              the IP configuration.
    [Arguments]  ${ip}  ${netmask}  ${gateway}  ${login}=${1}

    # Description of argument(s):
    # ip       The IP address to be set using ipmitool-inband.
    # netmask  The Netmask to be set using ipmitool-inband.
    # gateway  The Gateway address to be set using ipmitool-inband.

    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} ipsrc static  login_host=${login}
    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} ipaddr ${ip}  login_host=${0}
    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} netmask ${netmask}  login_host=${0}
    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} defgw ipaddr ${gateway}  login_host=${0}


Restore Configuration
    [Documentation]  Restore the configuration to its pre-test state
    ${length}=  Get Length  ${initial_lan_config}
    Return From Keyword If  ${length} == ${0}

    Set IPMI Inband Network Configuration  ${initial_lan_config['IP Address']}
    ...  ${initial_lan_config['Subnet Mask']}
    ...  ${initial_lan_config['Default Gateway IP']}  login=${0}


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
