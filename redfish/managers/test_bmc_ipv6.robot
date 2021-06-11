*** Settings ***
Documentation  Network interface IPv6 configuration and verification
               ...  tests.

Resource       ../../lib/bmc_redfish_resource.robot
Resource       ../../lib/openbmc_ffdc.robot
Resource       ../../lib/bmc_ipv6_utils.robot
Library        ../../lib/bmc_network_utils.py
Library        Collections

Test Setup     Test Setup Execution
Test Teardown  Test Teardown Execution
Suite Setup    Suite Setup Execution


*** Variables ***
${test_ipv6_addr}          2001:db8:3333:4444:5555:6666:7777:8888
${test_ipv6_invalid_addr}  2001:db8:3333:4444:5555:6666:7777:JJJJ

# Valid prefix length is a intiger ranges from 1 to 128.
${test_prefix_lenght}     64


*** Test Cases ***

Get IPv6 Address And Verify
    [Documentation]  Get IPv6 Address And Verify.
    [Tags]  Get_IPv6_Address_And_Verify

    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
      Verify IPv6 On BMC  ${ipv6_network_configuration['Address']}
    END


Get PrefixLength And Verify
    [Documentation]  Get IPv6 prefix length and verify.
    [Tags]  Get_PrefixLength_And_Verify

    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
      Verify IPv6 On BMC  ${ipv6_network_configuration['PrefixLength']}
    END


Get IPv6 Default Gateway And Verify
    [Documentation]  Get IPv6 default gateway and verify.

    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ${ipv6_gateway}=  Get From Dictionary  ${resp.dict}  IPv6DefaultGateway
    Verify IPv6 Default Gateway On BMC  ${ipv6_gateway}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup execution.

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Set Suite variable  ${ethernet_interface}


Test Setup Execution
    [Documentation]  Test setup execution.

    Redfish.Login

    @{ipv6_network_configurations}=  Get IPv6 Network Configuration
    Set Test Variable  @{ipv6_network_configurations}

    # Get BMC IPv6 address and prefix length.
    ${ipv6_data}=  Get BMC IPv6 Info
    Set Test Variable  ${ipv6_data}


Test Teardown Execution
    [Documentation]  Test teardown execution.

    FFDC On Test Case Fail
    Redfish.Logout


Get IPv6 Network Configuration
    [Documentation]  Get Ipv6 network configuration.
    # Sample output:
    # {
    #  "@odata.id": "/redfish/v1/Managers/bmc/EthernetInterfaces/eth0",
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
    #    "@odata.id": "/redfish/v1/Managers/bmc/EthernetInterfaces/eth0/VLANs"


    ${active_channel_config}=  Get Active Channel Config
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${active_channel_config['${CHANNEL_NUMBER}']['name']}

    @{ipv6_network_configurations}=  Get From Dictionary  ${resp.dict}  IPv6StaticAddresses
    [Return]  @{ipv6_network_configurations}
