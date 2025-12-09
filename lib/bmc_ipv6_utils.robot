*** Settings ***
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/boot_utils.robot
Library                 ../lib/gen_misc.py
Library                 ../lib/utils.py
Library                 ../lib/bmc_network_utils.py

*** Variables ***
${test_ipv6_addr}           2001:db8:3333:4444:5555:6666:7777:9999
${test_prefix_length}       64

*** Keywords ***

Get BMC IPv6 Info
    [Documentation]  Get system IPv6 address and prefix length.

    # Get system IP address and prefix length details using "ip addr"
    # Sample Output of "ip addr":
    # 1: eth0: <BROADCAST,MULTIAST> mtu 1500 qdisc mq state UP qlen 1000
    #     link/ether xx:xx:xx:xx:xx:xx brd ff:ff:ff:ff:ff:ff
    #     inet xx.xx.xx.xx/24 brd xx.xx.xx.xx scope global eth0
    #     inet6 fe80::xxxx:xxxx:xxxx:xxxx/64 scope link
    #     inet6 xxxx::xxxx:xxxx:xxxx:xxxx/64 scope global

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command  /sbin/ip addr

    # Get line having IPv6 address details.
    ${lines}=  Get Lines Containing String  ${cmd_output}  inet6

    # List IP address details.
    @{ip_components}=  Split To Lines  ${lines}

    @{ipv6_data}=  Create List

    # Get all IP addresses and prefix lengths on system.
    FOR  ${ip_component}  IN  @{ip_components}
      @{if_info}=  Split String  ${ip_component}
      ${ip_n_prefix}=  Get From List  ${if_info}  1
      Append To List  ${ipv6_data}  ${ip_n_prefix}
    END

    RETURN  ${ipv6_data}


Verify IPv6 On BMC
    [Documentation]  Verify IPv6 on BMC.
    [Arguments]  ${ipv6}

    # Description of argument(s):
    # ipv6  IPv6 address to be verified (e.g. "2001::1234:1234").

    # Get IPv6 address details on BMC using IP command.
    @{ip_data}=  Get BMC IPv6 Info
    Should Contain Match  ${ip_data}  ${ipv6}/*
    ...  msg=IPv6 address does not exist.


Verify IPv6 Default Gateway On BMC
    [Documentation]  Verify IPv6 default gateway on BMC.
    [Arguments]  ${gateway_ip}=0:0:0:0:0:0:0:0

    # Description of argument(s):
    # gateway_ip  Gateway IPv6 address.

    ${route_info}=  Get BMC IPv6 Route Info

    # If gateway IP is empty it will not have route entry.

    IF  '${gateway_ip}' == '0:0:0:0:0:0:0:0'
        Pass Execution  Gateway IP is not configured.
    ELSE
        Should Contain  ${route_info}  ${gateway_ip}  msg=Gateway IP address not matching.
    END


Get BMC IPv6 Route Info
    [Documentation]  Get IPv6 route info on BMC.

    # Sample output of "ip -6 route":
    # unreachable ::/96 dev lo metric 1024 error -113
    # unreachable ::ffff:0.0.0.0/96 dev lo metric 1024 error -113
    # 2xxx:xxxx:0:1::/64 dev eth0 proto kernel metric 256
    # fe80::/64 dev eth1 proto kernel metric 256
    # fe80::/64 dev eth0 proto kernel metric 256
    # fe80::/64 dev eth2 proto kernel metric 256


    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip -6 route

    RETURN  ${cmd_output}


Get Address Origin List And Address For Type
    [Documentation]  Get address origin list and address for type.
    [Arguments]  ${ipv6_address_type}  ${channel_number}=${CHANNEL_NUMBER}

    # Description of the argument(s):
    # ipv6_address_type  Type of IPv6 address to be checked.
    # channel_number      Channel number 1(eth0) or 2(eth1).

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${active_channel_config['${channel_number}']['name']}
    @{ipv6_addresses}=  Get From Dictionary  ${resp.dict}  IPv6Addresses

    ${ipv6_addressorigin_list}=  Create List
    FOR  ${ipv6_address}  IN  @{ipv6_addresses}
        ${ipv6_addressorigin}=  Get From Dictionary  ${ipv6_address}  AddressOrigin
        Append To List  ${ipv6_addressorigin_list}  ${ipv6_addressorigin}
        IF  '${ipv6_addressorigin}' == '${ipv6_address_type}'
            Set Test Variable  ${ipv6_type_addr}  ${ipv6_address['Address']}
        END
    END
    Should Contain  ${ipv6_addressorigin_list}  ${ipv6_address_type}
    Should Not Be Empty  ${ipv6_type_addr}  msg=${ipv6_address_type} address is not present
    RETURN  @{ipv6_addressorigin_list}  ${ipv6_type_addr}


Verify The Coexistence Of The Address Type
    [Documentation]  Verify the coexistence of the address type.
    [Arguments]  @{ipv6_address_types}

    # Description of the argument(s):
    # ipv6_address_types  Types of IPv6 address to be checked.

    FOR  ${ipv6_address_type}  IN  @{ipv6_address_types}
        @{ipv6_address_origin_list}  ${ipv6_type_addr}=
        ...  Get Address Origin List And Address For Type  ${ipv6_address_type}
        Should Contain    ${ipv6_address_origin_list}  ${ipv6_address_type}
        Should Not Be Empty    ${ipv6_type_addr}  msg=${ipv6_address_type} address is not present
    END


Get Address Origin List And IPv4 or IPv6 Address
    [Documentation]  Get address origin list and address for type.
    [Arguments]  ${ip_address_type}  ${channel_number}=${CHANNEL_NUMBER}

    # Description of the argument(s):
    # ip_address_type  Type of IPv4 or IPv6 address to be checked.
    # channel_number   Channel number 1(eth0) or 2(eth1).

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${active_channel_config['${channel_number}']['name']}
    @{ip_addresses}=  Get From Dictionary  ${resp.dict}  ${ip_address_type}

    ${ip_addressorigin_list}=  Create List
    ${ip_addr_list}=  Create List
    FOR  ${ip_address}  IN  @{ip_addresses}
        ${ip_addressorigin}=  Get From Dictionary  ${ip_address}  AddressOrigin
        Append To List  ${ip_addressorigin_list}  ${ip_addressorigin}
        Append To List  ${ip_addr_list}  ${ip_address['Address']}
    END
    RETURN  ${ip_addressorigin_list}  ${ip_addr_list}


Configure IPv6 Address On BMC
    [Documentation]  Add IPv6 Address on BMC.
    [Arguments]  ${ipv6_addr1}  ${prefix_len}  ${ipv6_addr2}=${None}
    ...  ${channel_number}=${CHANNEL_NUMBER}
    ...  ${valid_status_codes}=[${HTTP_OK},${HTTP_NO_CONTENT}]  ${Version}=IPv4

    # Description of argument(s):
    # ipv6_addr1          IPv6 address to be added (e.g. "2001:0022:0033::0111").
    # ipv6_addr2          IPv6 address to be Verified (e.g. "2001:22:33::111").
    # prefix_len          Prefix length for the IPv6 to be added
    #                     (e.g. "64").
    # channel_number      Channel number (1 - eth0 and 2 - eth1).
    # valid_status_codes  Expected return code from patch operation
    #                     (e.g. "200").

    ${prefix_length}=  Convert To Integer  ${prefix_len}
    ${empty_dict}=  Create Dictionary
    ${ipv6_data}=  Create Dictionary  Address=${ipv6_addr1}
    ...  PrefixLength=${prefix_length}

    ${patch_list}=  Create List

    # Get existing static IPv6 configurations on BMC.
    ${ipv6_network_configurations}=  Get IPv6 Network Configuration  ${channel_number}
    ${num_entries}=  Get Length  ${ipv6_network_configurations}

    FOR  ${INDEX}  IN RANGE  0  ${num_entries}
      Append To List  ${patch_list}  ${empty_dict}
    END

    # Check for existence of IPv6 on BMC while adding.
    Append To List  ${patch_list}  ${ipv6_data}
    ${data}=  Create Dictionary  IPv6StaticAddresses=${patch_list}

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}

    IF  '${Version}' == 'IPv4'
        Redfish.patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body=&{data}
        ...  valid_status_codes=${valid_status_codes}
    ELSE
        Redfish IPv6.patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body=&{data}
        ...  valid_status_codes=${valid_status_codes}
    END

    IF  ${valid_status_codes} != [${HTTP_OK}, ${HTTP_NO_CONTENT}]
        Fail  msg=Static address not added correctly
    END

    # Note: Network restart takes around 15-18s after patch request processing.
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

    # Verify ip address on CLI.
    IF  '${ipv6_addr2}' != '${None}'
        Verify IPv6 And PrefixLength  ${ipv6_addr2}  ${prefix_len}
    ELSE
        Verify IPv6 And PrefixLength  ${ipv6_addr1}  ${prefix_len}
    END

    # Verify if existing static IPv6 addresses still exist.
    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
      Verify IPv6 On BMC  ${ipv6_network_configuration['Address']}
    END

    #Verify redfish and CLI data matches.
    Validate IPv6 Network Config On BMC


Get IPv6 Network Configuration
    [Documentation]  Get Ipv6 network configuration.
    [Arguments]  ${channel_number}=${CHANNEL_NUMBER}

    # Description of argument(s):
    # channel_number  Channel number (1 - eth0 and 2 - eth1).

    # Sample output:
    # {
    #  "@odata.id": "/redfish/v1/Managers/${MANAGER_ID}/EthernetInterfaces/eth0",
    #  "@odata.type": "#EthernetInterface.v1_4_1.EthernetInterface",
    #   "DHCPv4": {
    #    "DHCPEnabled": false,
    #    "UseDNSServers": false,
    #    "UseDomainName": true,
    #    "UseNTPServers": false
    #  },
    #  "DHCPv6": {
    #    "OperatingMode": "Disabled",
    #    "UseDNSServers": false,
    #    "UseDomainName": true,
    #    "UseNTPServers": false
    #  },
    #  "Description": "Management Network Interface",
    #  "FQDN": "localhost",
    #  "HostName": "localhost",
    #  "IPv4Addresses": [
    #    {
    #      "Address": "xx.xx.xx.xx",
    #      "AddressOrigin": "Static",
    #      "Gateway": "xx.xx.xx.1",
    #      "SubnetMask": "xx.xx.xx.0"
    #    },
    #    {
    #      "Address": "169.254.xx.xx",
    #      "AddressOrigin": "IPv4LinkLocal",
    #      "Gateway": "0.0.0.0",
    #      "SubnetMask": "xx.xx.0.0"
    #    },
    #  ],
    #  "IPv4StaticAddresses": [
    #    {
    #      "Address": "xx.xx.xx.xx",
    #      "AddressOrigin": "Static",
    #      "Gateway": "xx.xx.xx.1",
    #      "SubnetMask": "xx.xx.0.0"
    #    }
    # }
    #  ],
    #  "IPv6AddressPolicyTable": [],
    #  "IPv6Addresses": [
    #    {
    #      "Address": "fe80::xxxx:xxxx:xxxx:xxxx",
    #      "AddressOrigin": "LinkLocal",
    #      "AddressState": null,
    #      "PrefixLength": xx
    #    }
    #  ],
    #  "IPv6DefaultGateway": "",
    #  "IPv6StaticAddresses": [
    #    { "Address": "xxxx:xxxx:xxxx:xxxx::xxxx",
    #      "AddressOrigin": "Static",
    #      "AddressState": null,
    #      "PrefixLength": xxx
    #    }
    #  ],
    #  "Id": "eth0",
    #  "InterfaceEnabled": true,
    #  "LinkStatus": "LinkUp",
    #  "MACAddress": "xx:xx:xx:xx:xx:xx",
    #  "Name": "Manager Ethernet Interface",
    #  "NameServers": [],
    #  "SpeedMbps": 0,
    #  "StaticNameServers": [],
    #  "Status": {
    #    "Health": "OK",
    #    "HealthRollup": "OK",
    #    "State": "Enabled"
    #  },
    #  "VLANs": {
    #    "@odata.id": "/redfish/v1/Managers/${MANAGER_ID}/EthernetInterfaces/eth0/VLANs"


    ${active_channel_config}=  Get Active Channel Config
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${active_channel_config['${channel_number}']['name']}

    @{ipv6_network_configurations}=  Get From Dictionary  ${resp.dict}  IPv6StaticAddresses
    RETURN  @{ipv6_network_configurations}


Verify IPv6 And PrefixLength
    [Documentation]  Verify IPv6 address and prefix length on BMC.
    [Arguments]  ${ipv6_addr}  ${prefix_len}

    # Description of the argument(s):
    # ipv6_addr   IPv6 address to be verified.
    # prefix_len  PrefixLength value to be verified.

    # Catenate IPv6 address and its prefix length.
    ${ipv6_with_prefix}=  Catenate  ${ipv6_addr}/${prefix_len}

    # Get IPv6 address details on BMC using IP command.
    @{ip_data}=  Get BMC IPv6 Info

    # Verify if IPv6 and prefix length is configured on BMC.

    Should Contain  ${ip_data}  ${ipv6_with_prefix}
    ...  msg=IPv6 and prefix length pair does not exist.


Validate IPv6 Network Config On BMC
    [Documentation]  Check that IPv6 network info obtained via redfish matches info
    ...              obtained via CLI.

    @{ipv6_network_configurations}=  Get IPv6 Network Configuration
    ${ipv6_data}=  Get BMC IPv6 Info
    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
      Should Contain Match  ${ipv6_data}  ${ipv6_network_configuration['Address']}/*
      ...  msg=IPv6 address does not exist.
    END

Verify Functionality Of IPv4 Address
    [Documentation]  Verify the functionality of IPv4 address.
    [Arguments]  ${ipv4_adress_type}  ${channel_number}

    # Description of argument(s):
    # ipv4_adress_type   Type of IPv4 address(dhcp/static).
    # channel_number     Ethernet channel number, 1(eth0) or 2(eth1).

    # Verify presence of IPv4 address origin.
    @{ipv4_addressorigin_list}  ${ipv4_addr_list}=
    ...  Get Address Origin List And IPv4 or IPv6 Address  IPv4Addresses  ${channel_number}
    ${ipv4_addressorigin_list}=  Combine Lists  @{ipv4_addressorigin_list}
    Should Contain  ${ipv4_addressorigin_list}  ${ipv4_adress_type}

    IF  '${ipv4_adress_type}' == 'Static'
        IF  '${channel_number}' == '${1}'
            Click Element  ${xpath_eth0_interface}
            ${dhcp_status}=  Get Text  ${xpath_eth0_dhcpv4_button}
            Should Be Equal  ${dhcp_status}  Disabled
        ELSE IF  '${channel_number}' == '${2}'
            Click Element  ${xpath_eth1_interface}
            ${dhcp_status}=  Get Text  ${xpath_eth1_dhcpv4_button}
            Should Be Equal  ${dhcp_status}  Disabled
        END
        List Should Not Contain Value  ${ipv4_addressorigin_list}  DHCP
    ELSE IF  '${ipv4_adress_type}' == 'DHCP'
        IF  '${channel_number}' == '${1}'
            ${dhcp_status}=  Get Text  ${xpath_eth0_dhcpv4_button}
            Should Be Equal  ${dhcp_status}  Enabled
        ELSE IF  '${channel_number}' == '${2}'
            ${dhcp_status}=  Get Text  ${xpath_eth1_dhcpv4_button}
            Should Be Equal  ${dhcp_status}  Enabled
        END
        List Should Not Contain Value  ${ipv4_addressorigin_list}  Static
    END
