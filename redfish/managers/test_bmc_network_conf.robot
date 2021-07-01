*** Settings ***
Documentation  Network interface configuration and verification
               ...  tests.

Resource       ../../lib/bmc_redfish_resource.robot
Resource       ../../lib/bmc_network_utils.robot
Resource       ../../lib/openbmc_ffdc.robot
Library        ../../lib/bmc_network_utils.py
Library        Collections

Test Setup     Test Setup Execution
Test Teardown  Test Teardown Execution
Suite Setup    Suite Setup Execution

Force Tags     Network_Conf_Test

*** Variables ***
${test_hostname}           openbmc
${test_ipv4_addr}          10.7.7.7
${test_ipv4_invalid_addr}  0.0.1.a
${test_subnet_mask}        255.255.0.0
${broadcast_ip}            10.7.7.255
${loopback_ip}             127.0.0.2
${multicast_ip}            224.6.6.6
${out_of_range_ip}         10.7.7.256
${test_ipv4_addr2}         10.7.7.8

# Valid netmask is 4 bytes long and has continuous block of 1s.
# Maximum valid value in each octet is 255 and least value is 0.
# 253 is not valid, as binary value is 11111101.
${invalid_netmask}         255.255.253.0
${alpha_netmask}           ff.ff.ff.ff
# Maximum value of octet in netmask is 255.
${out_of_range_netmask}    255.256.255.0
${more_byte_netmask}       255.255.255.0.0
${less_byte_netmask}       255.255.255
${threshold_netmask}       255.255.255.255
${lowest_netmask}          128.0.0.0

# There will be 4 octets in IP address (e.g. xx.xx.xx.xx)
# but trying to configure xx.xx.xx
${less_octet_ip}           10.3.36

# For the address 10.6.6.6, the 10.6.6.0 portion describes the
# network ID and the 6 describe the host.

${network_id}              10.7.7.0
${hex_ip}                  0xa.0xb.0xc.0xd
${negative_ip}             10.-7.-7.7
@{static_name_servers}     10.5.5.5
@{null_value}              null
@{empty_dictionary}        {}
@{string_value}            aa.bb.cc.dd

*** Test Cases ***

Get IP Address And Verify
    [Documentation]  Get IP Address And Verify.
    [Tags]  Get_IP_Address_And_Verify

    FOR  ${network_configuration}  IN  @{network_configurations}
      Verify IP On BMC  ${network_configuration['Address']}
    END

Get Netmask And Verify
    [Documentation]  Get Netmask And Verify.
    [Tags]  Get_Netmask_And_Verify

    FOR  ${network_configuration}  IN  @{network_configurations}
      Verify Netmask On BMC  ${network_configuration['SubnetMask']}
    END

Get Gateway And Verify
    [Documentation]  Get gateway and verify it's existence on the BMC.
    [Tags]  Get_Gateway_And_Verify

    FOR  ${network_configuration}  IN  @{network_configurations}
      Verify Gateway On BMC  ${network_configuration['Gateway']}
    END

Get MAC Address And Verify
    [Documentation]  Get MAC address and verify it's existence on the BMC.
    [Tags]  Get_MAC_Address_And_Verify

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ${macaddr}=  Get From Dictionary  ${resp.dict}  MACAddress
    Validate MAC On BMC  ${macaddr}

Verify All Configured IP And Netmask
    [Documentation]  Verify all configured IP and netmask on BMC.
    [Tags]  Verify_All_Configured_IP_And_Netmask

    FOR  ${network_configuration}  IN  @{network_configurations}
      Verify IP And Netmask On BMC  ${network_configuration['Address']}
      ...  ${network_configuration['SubnetMask']}
    END

Get Hostname And Verify
    [Documentation]  Get hostname via Redfish and verify.
    [Tags]  Get_Hostname_And_Verify

    ${hostname}=  Redfish_Utils.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  HostName

    Validate Hostname On BMC  ${hostname}

Configure Hostname And Verify
    [Documentation]  Configure hostname via Redfish and verify.
    [Tags]  Configure_Hostname_And_Verify
    [Teardown]  Run Keywords
    ...  Configure Hostname  ${hostname}  AND  Validate Hostname On BMC  ${hostname}

    ${hostname}=  Redfish_Utils.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  HostName

    Configure Hostname  ${test_hostname}
    Validate Hostname On BMC  ${test_hostname}


Add Valid IPv4 Address And Verify
    [Documentation]  Add IPv4 Address via Redfish and verify.
    [Tags]  Add_Valid_IPv4_Addres_And_Verify
    [Teardown]   Run Keywords
    ...  Delete IP Address  ${test_ipv4_addr}  AND  Test Teardown Execution

     Add IP Address  ${test_ipv4_addr}  ${test_subnet_mask}  ${test_gateway}

Add Invalid IPv4 Address And Verify
    [Documentation]  Add Invalid IPv4 Address via Redfish and verify.
    [Tags]  Add_Invalid_IPv4_Addres_And_Verify

    Add IP Address  ${test_ipv4_invalid_addr}  ${test_subnet_mask}
    ...  ${test_gateway}  valid_status_codes=${HTTP_BAD_REQUEST}

Configure Out Of Range IP
    [Documentation]  Configure out-of-range IP address.
    [Tags]  Configure_Out_Of_Range_IP
    [Template]  Add IP Address

    # ip                subnet_mask          gateway          valid_status_codes
    ${out_of_range_ip}  ${test_subnet_mask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Broadcast IP
    [Documentation]  Configure broadcast IP address.
    [Tags]  Configure_Broadcast_IP
    [Template]  Add IP Address
    [Teardown]  Clear IP Settings On Fail  ${broadcast_ip}

    # ip             subnet_mask          gateway          valid_status_codes
    ${broadcast_ip}  ${test_subnet_mask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Multicast IP
    [Documentation]  Configure multicast IP address.
    [Tags]  Configure_Multicast_IP
    [Template]  Add IP Address
    [Teardown]  Clear IP Settings On Fail  ${multicast_ip}

    # ip             subnet_mask          gateway          valid_status_codes
    ${multicast_ip}  ${test_subnet_mask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Loopback IP
    [Documentation]  Configure loopback IP address.
    [Tags]  Configure_Loopback_IP
    [Template]  Add IP Address
    [Teardown]  Clear IP Settings On Fail  ${loopback_ip}

    # ip            subnet_mask          gateway          valid_status_codes
    ${loopback_ip}  ${test_subnet_mask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Add Valid IPv4 Address And Check Persistency
    [Documentation]  Add IPv4 address and check peristency.
    [Tags]  Add_Valid_IPv4_Addres_And_Check_Persistency

    Add IP Address  ${test_ipv4_addr}  ${test_subnet_mask}  ${test_gateway}

    # Reboot BMC and verify persistency.
    OBMC Reboot (off)
    Redfish.Login
    Verify IP On BMC  ${test_ipv4_addr}
    Delete IP Address  ${test_ipv4_addr}

Add Fourth Octet Threshold IP And Verify
    [Documentation]  Add fourth octet threshold IP and verify.
    [Tags]  Add_Fourth_Octet_Threshold_IP_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IP Address  10.7.7.254  AND  Test Teardown Execution

     Add IP Address  10.7.7.254  ${test_subnet_mask}  ${test_gateway}

Add Fourth Octet Lowest IP And Verify
    [Documentation]  Add fourth octet lowest IP and verify.
    [Tags]  Add_Fourth_Octet_Lowest_IP_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IP Address  10.7.7.1  AND  Test Teardown Execution

     Add IP Address  10.7.7.1  ${test_subnet_mask}  ${test_gateway}

Add Third Octet Threshold IP And Verify
    [Documentation]  Add third octet threshold IP and verify.
    [Tags]  Add_Third_Octet_Threshold_IP_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IP Address  10.7.255.7  AND  Test Teardown Execution

     Add IP Address  10.7.255.7  ${test_subnet_mask}  ${test_gateway}

Add Third Octet Lowest IP And Verify
    [Documentation]  Add third octet lowest IP and verify.
    [Tags]  Add_Third_Octet_Lowest_IP_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IP Address  10.7.0.7  AND  Test Teardown Execution

     Add IP Address  10.7.0.7  ${test_subnet_mask}  ${test_gateway}

Add Second Octet Threshold IP And Verify
    [Documentation]  Add second octet threshold IP and verify.
    [Tags]  Add_Second_Octet_Threshold_IP_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IP Address  10.255.7.7  AND  Test Teardown Execution

     Add IP Address  10.255.7.7  ${test_subnet_mask}  ${test_gateway}

Add Second Octet Lowest IP And Verify
    [Documentation]  Add second octet lowest IP and verify.
    [Tags]  Add_Second_Octet_Lowest_IP_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IP Address  10.0.7.7  AND  Test Teardown Execution

     Add IP Address  10.0.7.7  ${test_subnet_mask}  ${test_gateway}

Add First Octet Threshold IP And Verify
    [Documentation]  Add first octet threshold IP and verify.
    [Tags]  Add_First_Octet_Threshold_IP_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IP Address  223.7.7.7  AND  Test Teardown Execution

     Add IP Address  223.7.7.7  ${test_subnet_mask}  ${test_gateway}

Add First Octet Lowest IP And Verify
    [Documentation]  Add first octet lowest IP and verify.
    [Tags]  Add_First_Octet_Lowest_IP_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IP Address  1.7.7.7  AND  Test Teardown Execution

     Add IP Address  1.7.7.7  ${test_subnet_mask}  ${test_gateway}

Configure Invalid Netmask
    [Documentation]  Verify error while setting invalid netmask.
    [Tags]  Configure_Invalid_Netmask
    [Template]  Add IP Address

    # ip               subnet_mask         gateway          valid_status_codes
    ${test_ipv4_addr}  ${invalid_netmask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Out Of Range Netmask
    [Documentation]  Verify error while setting out of range netmask.
    [Tags]  Configure_Out_Of_Range_Netmask
    [Template]  Add IP Address

    # ip               subnet_mask              gateway          valid_status_codes
    ${test_ipv4_addr}  ${out_of_range_netmask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Alpha Netmask
    [Documentation]  Verify error while setting alpha netmask.
    [Tags]  Configure_Alpha_Netmask
    [Template]  Add IP Address

    # ip               subnet_mask       gateway          valid_status_codes
    ${test_ipv4_addr}  ${alpha_netmask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure More Byte Netmask
    [Documentation]  Verify error while setting more byte netmask.
    [Tags]  Configure_More_Byte_Netmask
    [Template]  Add IP Address

    # ip               subnet_mask           gateway          valid_status_codes
    ${test_ipv4_addr}  ${more_byte_netmask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Less Byte Netmask
    [Documentation]  Verify error while setting less byte netmask.
    [Tags]  Configure_Less_Byte_Netmask
    [Template]  Add IP Address

    # ip               subnet_mask           gateway          valid_status_codes
    ${test_ipv4_addr}  ${less_byte_netmask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Threshold Netmask And Verify
    [Documentation]  Configure threshold netmask and verify.
    [Tags]  Configure_Threshold_Netmask_And_verify
    [Teardown]  Run Keywords
    ...   Delete IP Address  ${test_ipv4_addr}  AND  Test Teardown Execution

     Add IP Address  ${test_ipv4_addr}  ${threshold_netmask}  ${test_gateway}

Configure Lowest Netmask And Verify
    [Documentation]  Configure lowest netmask and verify.
    [Tags]  Configure_Lowest_Netmask_And_verify
    [Teardown]  Run Keywords
    ...   Delete IP Address  ${test_ipv4_addr}  AND  Test Teardown Execution

     Add IP Address  ${test_ipv4_addr}  ${lowest_netmask}  ${test_gateway}

Configure Network ID
    [Documentation]  Verify error while configuring network ID.
    [Tags]  Configure_Network_ID
    [Template]  Add IP Address
    [Teardown]  Clear IP Settings On Fail  ${network_id}

    # ip           subnet_mask          gateway          valid_status_codes
    ${network_id}  ${test_subnet_mask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Less Octet IP
    [Documentation]  Verify error while Configuring less octet IP address.
    [Tags]  Configure_Less_Octet_IP
    [Template]  Add IP Address

    # ip              subnet_mask          gateway          valid_status_codes
    ${less_octet_ip}  ${test_subnet_mask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Empty IP
    [Documentation]  Verify error while Configuring empty IP address.
    [Tags]  Configure_Empty_IP
    [Template]  Add IP Address

    # ip      subnet_mask          gateway          valid_status_codes
    ${EMPTY}  ${test_subnet_mask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Special Char IP
    [Documentation]  Configure invalid IP address containing special chars.
    [Tags]  Configure_Special_Char_IP
    [Template]  Add IP Address

    # ip          subnet_mask          gateway          valid_status_codes
    @@@.%%.44.11  ${test_subnet_mask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Hexadecimal IP
    [Documentation]  Configure invalid IP address containing hex value.
    [Tags]  Configure_Hexadecimal_IP
    [Template]  Add IP Address

    # ip       subnet_mask          gateway          valid_status_codes
    ${hex_ip}  ${test_subnet_mask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Negative Octet IP
    [Documentation]  Configure invalid IP address containing negative octet.
    [Tags]  Configure_Negative_Octet_IP
    [Template]  Add IP Address

    # ip            subnet_mask          gateway          valid_status_codes
    ${negative_ip}  ${test_subnet_mask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Incomplete IP For Gateway
    [Documentation]  Configure incomplete IP for gateway and expect an error.
    [Tags]  Configure_Incomplete_IP_For_Gateway
    [Template]  Add IP Address

    # ip               subnet_mask          gateway           valid_status_codes
    ${test_ipv4_addr}  ${test_subnet_mask}  ${less_octet_ip}  ${HTTP_BAD_REQUEST}

Configure Special Char IP For Gateway
    [Documentation]  Configure special char IP for gateway and expect an error.
    [Tags]  Configure_Special_Char_IP_For_Gateway
    [Template]  Add IP Address

    # ip               subnet_mask          gateway       valid_status_codes
    ${test_ipv4_addr}  ${test_subnet_mask}  @@@.%%.44.11  ${HTTP_BAD_REQUEST}

Configure Hexadecimal IP For Gateway
    [Documentation]  Configure hexadecimal IP for gateway and expect an error.
    [Tags]  Configure_Hexadecimal_IP_For_Gateway
    [Template]  Add IP Address

    # ip               subnet_mask          gateway    valid_status_codes
    ${test_ipv4_addr}  ${test_subnet_mask}  ${hex_ip}  ${HTTP_BAD_REQUEST}

Get DNS Server And Verify
    [Documentation]  Get DNS server via Redfish and verify.
    [Tags]  Get_DNS_Server_And_Verify

    Verify CLI and Redfish Nameservers

Configure DNS Server And Verify
    [Documentation]  Configure DNS server and verify.
    [Tags]  Configure_DNS_Server_And_Verify
    [Setup]  DNS Test Setup Execution
    [Teardown]  Run Keywords
    ...  Configure Static Name Servers  AND  Test Teardown Execution

    Configure Static Name Servers  ${static_name_servers}
    Verify CLI and Redfish Nameservers

Delete DNS Server And Verify
    [Documentation]  Delete DNS server and verify.
    [Tags]  Delete_DNS_Server_And_Verify
    [Setup]  DNS Test Setup Execution
    [Teardown]  Run Keywords
    ...  Configure Static Name Servers  AND  Test Teardown Execution

    Delete Static Name Servers
    Verify CLI and Redfish Nameservers

Configure DNS Server And Check Persistency
    [Documentation]  Configure DNS server and check persistency on reboot.
    [Tags]  Configure_DNS_Server_And_Check_Persistency
    [Setup]  DNS Test Setup Execution
    [Teardown]  Run Keywords
    ...  Configure Static Name Servers  AND  Test Teardown Execution

    Configure Static Name Servers  ${static_name_servers}
    # Reboot BMC and verify persistency.
    OBMC Reboot (off)
    Redfish.Login
    Verify CLI and Redfish Nameservers

Configure Loopback IP For Gateway
    [Documentation]  Configure loopback IP for gateway and expect an error.
    [Tags]  Configure_Loopback_IP_For_Gateway
    [Template]  Add IP Address
    [Teardown]  Clear IP Settings On Fail  ${test_ipv4_addr}

    # ip               subnet_mask          gateway         valid_status_codes
    ${test_ipv4_addr}  ${test_subnet_mask}  ${loopback_ip}  ${HTTP_BAD_REQUEST}

Configure Network ID For Gateway
    [Documentation]  Configure network ID for gateway and expect an error.
    [Tags]  Configure_Network_ID_For_Gateway
    [Template]  Add IP Address
    [Teardown]  Clear IP Settings On Fail  ${test_ipv4_addr}

    # ip               subnet_mask          gateway        valid_status_codes
    ${test_ipv4_addr}  ${test_subnet_mask}  ${network_id}  ${HTTP_BAD_REQUEST}

Configure Multicast IP For Gateway
    [Documentation]  Configure multicast IP for gateway and expect an error.
    [Tags]  Configure_Multicast_IP_For_Gateway
    [Template]  Add IP Address
    [Teardown]  Clear IP Settings On Fail  ${test_ipv4_addr}

    # ip               subnet_mask          gateway           valid_status_codes
    ${test_ipv4_addr}  ${test_subnet_mask}  ${multicast_ip}  ${HTTP_BAD_REQUEST}

Configure Broadcast IP For Gateway
    [Documentation]  Configure broadcast IP for gateway and expect an error.
    [Tags]  Configure_Broadcast_IP_For_Gateway
    [Template]  Add IP Address
    [Teardown]  Clear IP Settings On Fail  ${test_ipv4_addr}

    # ip               subnet_mask          gateway          valid_status_codes
    ${test_ipv4_addr}  ${test_subnet_mask}  ${broadcast_ip}  ${HTTP_BAD_REQUEST}

Configure Null Value For DNS Server
    [Documentation]  Configure null value for DNS server and expect an error.
    [Tags]  Configure_Null_Value_For_DNS_Server
    [Setup]  DNS Test Setup Execution
    [Teardown]  Run Keywords
    ...  Configure Static Name Servers  AND  Test Teardown Execution

    Configure Static Name Servers  ${null_value}  ${HTTP_BAD_REQUEST}

Configure Empty Value For DNS Server
    [Documentation]  Configure empty value for DNS server and expect an error.
    [Tags]  Configure_Empty_Value_For_DNS_Server
    [Setup]  DNS Test Setup Execution
    [Teardown]  Run Keywords
    ...  Configure Static Name Servers  AND  Test Teardown Execution

    Configure Static Name Servers  ${empty_dictionary}  ${HTTP_BAD_REQUEST}

Configure String Value For DNS Server
    [Documentation]  Configure string value for DNS server and expect an error.
    [Tags]  Configure_String_Value_For_DNS_Server
    [Setup]  DNS Test Setup Execution
    [Teardown]  Run Keywords
    ...  Configure Static Name Servers  AND  Test Teardown Execution

    Configure Static Name Servers  ${string_value}  ${HTTP_BAD_REQUEST}

Modify IPv4 Address And Verify
    [Documentation]  Modify IP address via Redfish and verify.
    [Tags]  Modify_IPv4_Addres_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IP Address  ${test_ipv4_addr2}  AND  Test Teardown Execution

     Add IP Address  ${test_ipv4_addr}  ${test_subnet_mask}  ${test_gateway}

     Update IP Address  ${test_ipv4_addr}  ${test_ipv4_addr2}  ${test_subnet_mask}  ${test_gateway}


Configure Invalid Values For DNS Server
    [Documentation]  Configure invalid values for DNS server and expect an error.
    [Tags]  Configure_Invalid_Value_For_DNS_Server
    [Setup]  DNS Test Setup Execution
    [Template]  Configure Static Name Servers
    [Teardown]  Run Keywords
    ...  Configure Static Name Servers  AND  Test Teardown Execution

     # static_name_servers        valid_status_codes
      0xa.0xb.0xc.0xd             ${HTTP_BAD_REQUEST}
      10.-7.-7.-7                 ${HTTP_BAD_REQUEST}
      10.3.36                     ${HTTP_BAD_REQUEST}
      @@@.%%.44.11                ${HTTP_BAD_REQUEST}


Config Multiple DNS Servers And Verify
    [Documentation]  Config multiple DNS servers and verify.
    [Tags]  Config_Multiple_DNS_Servers_And_Verify
    [Setup]  DNS Test Setup Execution
    [Teardown]  Run Keywords
    ...  Configure Static Name Servers  AND  Test Teardown Execution

     @{list_name_servers}=  Create List  10.5.5.10  10.20.5.10  10.5.6.7
     Configure Static Name Servers  ${list_name_servers}
     Verify CLI and Redfish Nameservers


Configure And Verify Multiple Static IPv4 Addresses
    [Documentation]  Configure multiple static ipv4 address via Redfish and verify.
    [Tags]  Configure_And_Verify_Multiple_Static_IPv4_Addresses
    [Teardown]  Run Keywords  Delete Multiple Static IPv4 Addresses  ${test_ipv4_addresses}
    ...  AND  Test Teardown Execution

    ${test_ipv4_addresses}=  Create List  ${test_ipv4_addr}  ${test_ipv4_addr2}
    Configure Multiple Static IPv4 Addresses   ${test_ipv4_addresses}  ${test_subnet_mask}  ${test_gateway}


Configure Multiple Static IPv4 Addresses And Check Persistency
    [Documentation]  Configure multiple static ipv4 address via Redfish and check persistency.
    [Tags]  Configure_Multiple_Static_IPv4_Addresses_And_Check_Persistency
    [Teardown]  Run Keywords  Delete Multiple Static IPv4 Addresses  ${test_ipv4_addresses}
    ...  AND  Test Teardown Execution

    ${test_ipv4_addresses}=  Create List  ${test_ipv4_addr}  ${test_ipv4_addr2}
    Configure Multiple Static IPv4 Addresses  ${test_ipv4_addresses}  ${test_subnet_mask}  ${test_gateway}

    # Reboot BMC and verify persistency.
    OBMC Reboot (off)
    Redfish.Login
    FOR  ${ip}  IN  @{test_ipv4_addresses}
      Verify IP And Netmask On BMC  ${ip}  ${test_subnet_mask}
    END


Configure And Verify Multiple IPv4 Addresses
    [Documentation]  Configure multiple IPv4 addresses and verify.
    [Tags]  Configure_And_Verify_Multiple_IPv4_Addresse
    [Teardown]  Run Keywords
    ...  Delete IP Address  ${test_ipv4_addr}  AND  Delete IP Address  ${test_ipv4_addr2}
    ...  AND  Test Teardown Execution

    ${ip1}=  Create dictionary  Address=${test_ipv4_addr}
    ...  SubnetMask=255.255.0.0  Gateway=${test_gateway}
    ${ip2}=  Create dictionary  Address=${test_ipv4_addr2}
    ...  SubnetMask=255.255.252.0  Gateway=${test_gateway}

    ${empty_dict}=  Create Dictionary
    ${patch_list}=  Create List
    ${network_configurations}=  Get Network Configuration
    ${num_entries}=  Get Length  ${network_configurations}

    FOR  ${INDEX}  IN RANGE  0  ${num_entries}
      Append To List  ${patch_list}  ${empty_dict}
    END

    # We need not check for existence of IP on BMC while adding.
    Append To List  ${patch_list}  ${ip1}  ${ip2}
    ${payload}=  Create Dictionary  IPv4StaticAddresses=${patch_list}
    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}
    Redfish.patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body=&{payload}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    # Note: Network restart takes around 15-18s after patch request processing.
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}
    Verify IP On BMC  ${test_ipv4_addr}
    Verify IP On BMC  ${test_ipv4_addr2}


Config Multiple DNS Servers And Check Persistency
    [Documentation]  Config multiple DNS and check persistency.
    [Tags]  Config_Multiple_DNS_Servers_And_Check_Persistency
    [Setup]  DNS Test Setup Execution
    [Teardown]  Run Keywords
    ...  Configure Static Name Servers  AND  Test Teardown Execution

    @{list_name_servers}=  Create List  10.5.5.10  10.20.5.10  10.5.6.7
    Configure Static Name Servers  ${list_name_servers}

    # Reboot BMC and verify persistency.
    OBMC Reboot (off)
    Redfish.Login
    Verify CLI and Redfish Nameservers


Configure Static IP Without Using Gateway And Verify
    [Documentation]  Configure static IP without using gateway and verify error.
    [Tags]  Configure_Static_IP_Without_Using_Gateway_And_Verify

    ${ip}=  Create dictionary  Address=${test_ipv4_addr}
    ...  SubnetMask=${test_subnet_mask}
    ${empty_dict}=  Create Dictionary
    ${patch_list}=  Create List
    ${network_configurations}=  Get Network Configuration

    ${num_entries}=  Get Length  ${network_configurations}
    FOR  ${INDEX}  IN RANGE  0  ${num_entries}
      Append To List  ${patch_list}  ${empty_dict}
    END

    # We need not check for existence of IP on BMC while adding.
    Append To List  ${patch_list}  ${ip}
    ${payload}=  Create Dictionary  IPv4StaticAddresses=${patch_list}
    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}
    Redfish.patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ...  body=&{payload}  valid_status_codes=[${HTTP_BAD_REQUEST}]


Test Network Response On Specified Host State
    [Documentation]  Verifying the BMC network response when host is on and off.
    [Tags]  Test_Network_Response_On_Specified_Host_State
    [Template]  Verify Network Response On Specified Host State

    # host_state
    on
    off

*** Keywords ***

Test Setup Execution
    [Documentation]  Test setup execution.

    Redfish.Login

    @{network_configurations}=  Get Network Configuration
    Set Test Variable  @{network_configurations}

    # Get BMC IP address and prefix length.
    ${ip_data}=  Get BMC IP Info
    Set Test Variable  ${ip_data}


Verify Netmask On BMC
    [Documentation]  Verify netmask on BMC.
    [Arguments]  ${netmask}

    # Description of the argument(s):
    # netmask  netmask value to be verified.

    ${prefix_length}=  Netmask Prefix Length  ${netmask}

    Should Contain Match  ${ip_data}  */${prefix_length}
    ...  msg=Prefix length does not exist.

Verify IP And Netmask On BMC
    [Documentation]  Verify IP and netmask on BMC.
    [Arguments]  ${ip}  ${netmask}

    # Description of the argument(s):
    # ip       IP address to be verified.
    # netmask  netmask value to be verified.

    ${prefix_length}=  Netmask Prefix Length  ${netmask}
    @{ip_data}=  Get BMC IP Info

    ${ip_with_netmask}=  Catenate  ${ip}/${prefix_length}
    Should Contain  ${ip_data}  ${ip_with_netmask}
    ...  msg=IP and netmask pair does not exist.

Test Teardown Execution
    [Documentation]  Test teardown execution.

    FFDC On Test Case Fail
    Redfish.Logout

Clear IP Settings On Fail
    [Documentation]  Clear IP settings on fail.
    [Arguments]  ${ip}

    # Description of argument(s):
    # ip  IP address to be deleted.

    Run Keyword If  '${TEST STATUS}' == 'FAIL'
    ...  Delete IP Address  ${ip}

    Test Teardown Execution

Verify CLI and Redfish Nameservers
    [Documentation]  Verify that nameservers obtained via Redfish do not
    ...  match those found in /etc/resolv.conf.

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    ${redfish_nameservers}=  Redfish.Get Attribute
    ...  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  StaticNameServers
    ${resolve_conf_nameservers}=  CLI Get Nameservers
    Rqprint Vars  redfish_nameservers  resolve_conf_nameservers

    List Should Contain Sub List  ${resolve_conf_nameservers}  ${redfish_nameservers}
    ...  msg=The nameservers obtained via Redfish do not match those found in /etc/resolv.conf.

Configure Static Name Servers
    [Documentation]  Configure DNS server on BMC.
    [Arguments]  ${static_name_servers}=${original_nameservers}
     ...  ${valid_status_codes}=${HTTP_OK}

    # Description of the argument(s):
    # static_name_servers  A list of static name server IPs to be
    #                      configured on the BMC.

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    ${type} =  Evaluate  type($static_name_servers).__name__
    ${static_name_servers}=  Set Variable If  '${type}'=='str'
    ...  '${static_name_servers}'  ${static_name_servers}

    # Currently BMC is sending 500 response code instead of 400 for invalid scenarios.
    Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ...  body={'StaticNameServers': ${static_name_servers}}
    ...  valid_status_codes=[${valid_status_codes}, ${HTTP_INTERNAL_SERVER_ERROR}]

    # Patch operation takes 1 to 3 seconds to set new value.
    Sleep  3s

    # Check if newly added DNS server is configured on BMC.
    ${cli_nameservers}=  CLI Get Nameservers
    ${cmd_status}=  Run Keyword And Return Status
    ...  List Should Contain Sub List  ${cli_nameservers}  ${static_name_servers}

    Run Keyword If  '${valid_status_codes}' == '${HTTP_OK}'
    ...  Should Be True  ${cmd_status} == ${True}
    ...  ELSE  Should Be True  ${cmd_status} == ${False}

Delete Static Name Servers
    [Documentation]  Delete static name servers.

    Configure Static Name Servers  static_name_servers=@{EMPTY}

    # Check if all name servers deleted on BMC.
    ${nameservers}=  CLI Get Nameservers
    Should Be Empty  ${nameservers}

DNS Test Setup Execution
    [Documentation]  Do DNS test setup execution.

    Redfish.Login

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    ${original_nameservers}=  Redfish.Get Attribute
    ...  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  StaticNameServers

    Rprint Vars  original_nameservers
    # Set suite variables to trigger restoration during teardown.
    Set Suite Variable  ${original_nameservers}

Suite Setup Execution
    [Documentation]  Do suite setup execution.

    ${test_gateway}=  Get BMC Default Gateway
    Set Suite Variable  ${test_gateway}

Update IP Address
    [Documentation]  Update IP address of BMC.
    [Arguments]  ${ip}  ${new_ip}  ${netmask}  ${gw_ip}
    ...  ${valid_status_codes}=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    # Description of argument(s):
    # ip                  IP address to be replaced (e.g. "10.7.7.7").
    # new_ip              New IP address to be configured.
    # netmask             Netmask value.
    # gw_ip               Gateway IP address.
    # valid_status_codes  Expected return code from patch operation
    #                     (e.g. "200").  See prolog of rest_request
    #                     method in redfish_plus.py for details.

    ${empty_dict}=  Create Dictionary
    ${patch_list}=  Create List
    ${ip_data}=  Create Dictionary  Address=${new_ip}  SubnetMask=${netmask}  Gateway=${gw_ip}

    # Find the position of IP address to be modified.
    @{network_configurations}=  Get Network Configuration
    FOR  ${network_configuration}  IN  @{network_configurations}
      Run Keyword If  '${network_configuration['Address']}' == '${ip}'
      ...  Append To List  ${patch_list}  ${ip_data}
      ...  ELSE  Append To List  ${patch_list}  ${empty_dict}
    END

    ${ip_found}=  Run Keyword And Return Status  List Should Contain Value
    ...  ${patch_list}  ${ip_data}  msg=${ip} does not exist on BMC
    Pass Execution If  ${ip_found} == ${False}  ${ip} does not exist on BMC

    # Run patch command only if given IP is found on BMC
    ${data}=  Create Dictionary  IPv4StaticAddresses=${patch_list}

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Redfish.patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ...  body=&{data}  valid_status_codes=${valid_status_codes}

    # Note: Network restart takes around 15-18s after patch request processing.
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

    Verify IP On BMC  ${new_ip}
    Validate Network Config On BMC

Configure Multiple Static IPv4 Addresses
    [Documentation]  Configure multiple static ipv4 address via Redfish and verify.
    [Arguments]  ${ip_addreses}  ${subnet_mask}  ${gateway}

    # Description of argument(s):
    # ip_addreses         A list of IP addresses to be added (e.g.["10.7.7.7"]).
    # subnet_mask         Subnet mask for the IP to be added (e.g. "255.255.0.0").
    # gateway             Gateway for the IP to be added (e.g. "10.7.7.1").

    FOR  ${ip}  IN   @{ip_addreses}
       Add IP Address  ${ip}  ${subnet_mask}  ${gateway}
    END
    Validate Network Config On BMC


Delete Multiple Static IPv4 Addresses
    [Documentation]  Delete multiple static ipv4 address via Redfish.
    [Arguments]  ${ip_addreses}

    # Description of argument(s):
    # ip_addreses         A list of IP addresses to be deleted (e.g.["10.7.7.7"]).

    FOR  ${ip}  IN   @{ip_addreses}
       Delete IP Address  ${ip}
    END
    Validate Network Config On BMC

Verify Network Response On Specified Host State
    [Documentation]  Verifying the BMC network response when host is on and off.
    [Arguments]  ${host_state}

    # Description of argument(s):
    # host_state   if host_state is on then host is booted to operating system.
    #              if host_state is off then host is power off.
    #              (eg. on, off).

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Run Keyword If  '${host_state}' == 'on'
    ...    Redfish Power On  stack_mode=skip
    ...  ELSE
    ...    Redfish Power off  stack_mode=skip

    Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    Ping Host  ${OPENBMC_HOST}

