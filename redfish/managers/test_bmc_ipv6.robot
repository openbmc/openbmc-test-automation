*** Settings ***
Documentation  Network interface IPv6 configuration and verification
               ...  tests.

Resource       ../../lib/bmc_redfish_resource.robot
Resource       ../../lib/openbmc_ffdc.robot
Resource       ../../lib/bmc_ipv6_utils.robot
Resource       ../../lib/external_intf/vmi_utils.robot
Resource       ../../lib/bmc_network_utils.robot
Library        ../../lib/bmc_network_utils.py
Library        Collections
Library        Process

Test Setup      Test Setup Execution
Test Teardown   Test Teardown Execution
Suite Setup     Suite Setup Execution
Suite Teardown  Redfish.Logout

Test Tags     BMC_IPv6

*** Variables ***
${test_ipv6_addr}            2001:db8:3333:4444:5555:6666:7777:8888
${test_ipv6_invalid_addr}    2001:db8:3333:4444:5555:6666:7777:JJKK
${test_ipv6_addr1}           2001:db8:3333:4444:5555:6666:7777:9999
${invalid_hexadec_ipv6}      x:x:x:x:x:x:10.5.5.6
${ipv6_multi_short}          2001::33::111
# Valid prefix length is a integer ranges from 1 to 128.
${test_prefix_length}        64
${ipv6_gw_addr}              2002:903:15F:32:9:3:32:1
${prefix_length_def}         None
${invalid_staticv6_gateway}  9.41.164.1
${linklocal_addr_format}     fe80::[0-9a-f:]+$
${new_mac_addr}              AA:E2:84:14:28:79

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
    [Tags]  Get_IPv6_Default_Gateway_And_Verify

    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ${ipv6_gateway}=  Get From Dictionary  ${resp.dict}  IPv6DefaultGateway
    Verify IPv6 Default Gateway On BMC  ${ipv6_gateway}


Verify All Configured IPv6 And PrefixLength On BMC
    [Documentation]  Verify IPv6 address and its prefix length on BMC.
    [Tags]  Verify_All_Configured_IPv6_And_PrefixLength_On_BMC

    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
      Verify IPv6 And PrefixLength  ${ipv6_network_configuration['Address']}
      ...  ${ipv6_network_configuration['PrefixLength']}
    END


Configure IPv6 Address And Verify
    [Documentation]  Configure IPv6 address and verify.
    [Tags]  Configure_IPv6_Address_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IPv6 Address  ${test_ipv6_addr}  AND  Test Teardown Execution
    [Template]  Configure IPv6 Address On BMC


    # IPv6 address     Prefix length
    ${test_ipv6_addr}  ${test_prefix_length}


Delete IPv6 Address And Verify
    [Documentation]  Delete IPv6 address and verify.
    [Tags]  Delete_IPv6_Address_And_Verify

    Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}

    Delete IPv6 Address  ${test_ipv6_addr}


Modify IPv6 Address And Verify
    [Documentation]  Modify IPv6 address and verify.
    [Tags]  Modify_IPv6_Address_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IPv6 Address  ${test_ipv6_addr1}  AND  Test Teardown Execution

    Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}

    Modify IPv6 Address  ${test_ipv6_addr}  ${test_ipv6_addr1}  ${test_prefix_length}


Verify Persistency Of IPv6 After BMC Reboot
    [Documentation]  Verify persistency of IPv6 after BMC reboot.
    [Tags]  Verify_Persistency_Of_IPv6_After_BMC_Reboot
    [Teardown]  Run Keywords
    ...  Delete IPv6 Address  ${test_ipv6_addr}  AND  Test Teardown Execution

    Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}

    Redfish OBMC Reboot (off)  stack_mode=skip

    # Verifying persistency of IPv6.
    Verify IPv6 On BMC  ${test_ipv6_addr}


Enable SLAAC On BMC And Verify
    [Documentation]  Enable SLAAC on BMC and verify.
    [Tags]  Enable_SLAAC_On_BMC_And_Verify

    Set SLAAC Configuration State And Verify  ${True}


Enable DHCPv6 Property On BMC And Verify
    [Documentation]  Enable DHCPv6 property on BMC and verify.
    [Tags]  Enable_DHCPv6_Property_On_BMC_And_Verify

    Set And Verify DHCPv6 Property  Enabled


Disable DHCPv6 Property On BMC And Verify
    [Documentation]  Disable DHCPv6 property on BMC and verify.
    [Tags]  Disable_DHCPv6_Property_On_BMC_And_Verify

    Set And Verify DHCPv6 Property  Disabled


Verify Persistency Of DHCPv6 On Reboot
    [Documentation]  Verify persistency of DHCPv6 property on reboot.
    [Tags]  Verify_Persistency_Of_DHCPv6_On_Reboot

    Set And Verify DHCPv6 Property  Enabled
    Redfish OBMC Reboot (off)       stack_mode=skip
    Verify DHCPv6 Property          Enabled


Configure Invalid Static IPv6 And Verify
    [Documentation]  Configure invalid static IPv6 and verify.
    [Tags]  Configure_Invalid_Static_IPv6_And_Verify
    [Template]  Configure IPv6 Address On BMC

    #invalid_ipv6            prefix length           valid_status_code
    ${ipv4_hexword_addr}     ${test_prefix_length}   ${HTTP_BAD_REQUEST}
    ${invalid_hexadec_ipv6}  ${test_prefix_length}   ${HTTP_BAD_REQUEST}
    ${ipv6_multi_short}      ${test_prefix_length}   ${HTTP_BAD_REQUEST}



Configure IPv6 Static Default Gateway And Verify
    [Documentation]  Configure IPv6 static default gateway and verify.
    [Tags]  Configure_IPv6_Static_Default_Gateway_And_Verify
    [Template]  Configure IPv6 Static Default Gateway On BMC

    # static_def_gw              prefix length           valid_status_code
    ${ipv6_gw_addr}              ${prefix_length_def}    ${HTTP_OK}
    ${invalid_staticv6_gateway}  ${test_prefix_length}   ${HTTP_BAD_REQUEST}


Modify Static Default Gateway And Verify
    [Documentation]  Modify static default gateway and verify.
    [Tags]  Modify_Static_Default_Gateway_And_Verify
    [Setup]  Configure IPv6 Static Default Gateway On BMC  ${ipv6_gw_addr}  ${prefix_length_def}

    Modify IPv6 Static Default Gateway On BMC  ${test_ipv6_addr1}  ${prefix_length_def}  ${HTTP_OK}  ${ipv6_gw_addr}


Delete IPv6 Static Default Gateway And Verify
    [Documentation]  Delete IPv6 static default gateway and verify.
    [Tags]  Delete_IPv6_Static_Default_Gateway_And_Verify
    [Setup]  Configure IPv6 Static Default Gateway On BMC  ${ipv6_gw_addr}  ${prefix_length_def}

    Delete IPv6 Static Default Gateway  ${ipv6_gw_addr}


Verify Coexistence Of Linklocalv6 And Static IPv6 On BMC
    [Documentation]  Verify linklocalv6 And static IPv6 both exist.
    [Tags]  Verify_Coexistence_Of_Linklocalv6_And_Static_IPv6_On_BMC
    [Setup]  Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}
    [Teardown]  Delete IPv6 Address  ${test_ipv6_addr}

    Check Coexistence Of Linklocalv6 And Static IPv6


Verify IPv6 Linklocal Address Is In Correct Format
    [Documentation]  Verify linklocal address has network part as fe80 and
    ...  host part as EUI64.
    [Tags]  Verify_IPv6_Linklocal_Address_Is_In_Correct_Format

    Check If Linklocal Address Is In Correct Format


Verify BMC Gets SLAAC Address On Enabling SLAAC
    [Documentation]  On enabling SLAAC verify SLAAC address comes up.
    [Tags]  Verify_BMC_Gets_SLAAC_Address_On_Enabling_SLAAC
    [Setup]  Set SLAAC Configuration State And Verify  ${False}

    Set SLAAC Configuration State And Verify  ${True}
    Sleep  ${NETWORK_TIMEOUT}
    Check BMC Gets SLAAC Address


Enable And Verify DHCPv6 Property On Eth1 When DHCPv6 Property Enabled On Eth0
    [Documentation]  Verify DHCPv6 on eth1 when DHCPv6 property is enabled on eth0.
    [Tags]  Enable_And_Verify_DHCPv6_Property_On_Eth1_When_DHCPv6_Property_Enabled_On_Eth0
    [Setup]  Get The Initial DHCPv6 Settings
    [Teardown]  Run Keywords  Set And Verify DHCPv6 Property  ${dhcpv6_channel_1}  ${1}
    ...  AND  Set And Verify DHCPv6 Property  ${dhcpv6_channel_2}  ${2}

    Set And Verify DHCPv6 Property  Enabled  ${1}
    Set And Verify DHCPv6 Property  Enabled  ${2}


Verify Enable And Disable SLAAC On Both Interfaces
    [Documentation]  Verify enable and disable SLAAC on both the interfaces.
    [Tags]  Verify_Enable_And_Disable_SLAAC_On_Both_Interfaces
    [Setup]  Get The Initial SLAAC Settings
    [Template]  Set And Verify SLAAC Property On Both Interfaces
    [Teardown]  Run Keywords  Set SLAAC Configuration State And Verify  ${slaac_channel_1}  [${HTTP_OK}]  ${1}
    ...  AND  Set SLAAC Configuration State And Verify  ${slaac_channel_2}  [${HTTP_OK}]  ${2}

    # slaac_eth0       slaac_eth1
    ${True}            ${True}
    ${True}            ${False}
    ${False}           ${True}
    ${False}           ${False}


Verify Autoconfig Is Present On Ethernet Interface
    [Documentation]  Verify autoconfig is present on ethernet interface.
    [Tags]  Verify_Autoconfig_Is_Present_On_Ethernet_Interface

    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    Should Contain  ${resp.dict}  StatelessAddressAutoConfig


Verify Interface ID Of SLAAC And LinkLocal Addresses Are Same
    [Documentation]  Validate interface id of SLAAC and link-local addresses are same.
    [Tags]  Verify_Interface_ID_Of_SLAAC_And_LinkLocal_Addresses_Are_Same

    @{ipv6_addressorigin_list}  ${ipv6_linklocal_addr}=  Get Address Origin List And Address For Type  LinkLocal
    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=  Get Address Origin List And Address For Type  SLAAC

    ${linklocal_interface_id}=  Get Interface ID Of IPv6  ${ipv6_linklocal_addr}
    ${slaac_interface_id}=  Get Interface ID Of IPv6  ${ipv6_slaac_addr}

    Should Be Equal    ${linklocal_interface_id}    ${slaac_interface_id}


Verify Persistency Of Link Local IPv6 On BMC Reboot
    [Documentation]  Verify persistency of link local on BMC reboot.
    [Tags]  Verify_Persistency_Of_Link_Local_IPv6_On_BMC_Reboot

    # Capturing the linklocal before reboot.
    @{ipv6_address_origin_list}  ${linklocal_addr_before_reboot}=
    ...  Get Address Origin List And Address For Type  LinkLocal

    # Rebooting BMC.
    Redfish OBMC Reboot (off)  stack_mode=skip

    @{ipv6_address_origin_list}  ${linklocal_addr_after_reboot}=
    ...  Get Address Origin List And Address For Type  LinkLocal

    # Verifying the linklocal must be the same before and after reboot.
    Should Be Equal    ${linklocal_addr_before_reboot}    ${linklocal_addr_after_reboot}
    ...    msg=IPv6 Linklocal address has changed after reboot.


Modify MAC and Verify BMC Reinitializing Linklocal
    [Documentation]  Modify MAC and verify BMC reinitializing linklocal.
    [Tags]  Modify_MAC_and_Verify_BMC_Reinitializing_Linklocal
    [Teardown]  Configure MAC Settings  ${original_address}

    ${original_address}=  Get BMC MAC Address
    @{ipv6_addressorigin_list}  ${ipv6_before_linklocal_addr}=  Get Address Origin List And Address For Type  LinkLocal

    # Modify MAC Address Of Ethernet Interface.
    Configure MAC Settings  ${new_mac_addr}
    Sleep  30s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}
    @{ipv6_addressorigin_list}  ${ipv6_linklocal_after_addr}=  Get Address Origin List And Address For Type  LinkLocal

    # Verify whether the linklocal has changed and is in the the correct format.
    Check If Linklocal Address Is In Correct Format
    Should Not Be Equal    ${ipv6_before_linklocal_addr}    ${ipv6_linklocal_after_addr}


Add Multiple IPv6 Address And Verify
    [Documentation]  Add multiple IPv6 address and verify.
    [Tags]  Add_Multiple_IPv6_Address_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IPv6 Address  ${test_ipv6_addr}  AND  Delete IPv6 Address  ${test_ipv6_addr1}
    ...  AND  Test Teardown Execution

    Configure Multiple IPv6 Address on BMC  ${test_prefix_length}


Verify Coexistence Of Static IPv6 And SLAAC On BMC
    [Documentation]  Verify static IPv6 And SLAAC both coexist.
    [Tags]  Verify_Coexistence_Of_Static_IPv6_And_SLAAC_On_BMC
    [Setup]  Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}
             Set SLAAC Configuration State And Verify  ${True}
    [Teardown]  Delete IPv6 Address  ${test_ipv6_addr}

    Sleep  ${NETWORK_TIMEOUT}s

    Check Coexistence Of Static IPv6 And SLAAC


Verify Coexistence Of Link Local And DHCPv6 On BMC
    [Documentation]  Verify link local And dhcpv6 both coexist.
    [Tags]  Verify_Coexistence_Of_Link_Local_And_DHCPv6_On_BMC
    [Setup]  Set DHCPv6 Property  Enabled  ${2}

    Sleep  ${NETWORK_TIMEOUT}s

    Check Coexistence Of Link Local And DHCPv6


Verify Coexistence Of Link Local And SLAAC On BMC
    [Documentation]  Verify link local And SLAAC both coexist.
    [Tags]  Verify_Coexistence_Of_Link_Local_And_SLAAC_On_BMC
    [Setup]  Set SLAAC Configuration State And Verify  ${True}

    Sleep  ${NETWORK_TIMEOUT}s

    Check Coexistence Of Link Local And SLAAC


Verify Coexistence Of All IPv6 Type Addresses On BMC
    [Documentation]  Verify coexistence of link local, static, DHCPv6 and SLAAC ipv6 addresses.
    [Tags]  Verify_Coexistence_Of_All_IPv6_Type_Addresses_On_BMC
    [Setup]  Run Keywords  Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}
    ...      AND  Get The Initial DHCPv6 Setting On Each Interface  ${1}
    ...      AND  Set And Verify DHCPv6 Property  Enabled
    ...      AND  Get The Initial SLAAC Setting On Each Interface  ${1}
    ...      AND  Set SLAAC Configuration State And Verify  ${True}
    [Teardown]  Run Keywords  Delete IPv6 Address  ${test_ipv6_addr}
    ...         AND  Set And Verify DHCPv6 Property  ${dhcpv6_channel_1}  ${1}
    ...         AND  Set SLAAC Configuration State And Verify  ${slaac_channel_1}  [${HTTP_OK}]  ${1}

    Sleep  ${NETWORK_TIMEOUT}s

    # Verify link local, static, DHCPv6 and SLAAC ipv6 addresses coexist.
    Verify The Coexistence Of The Address Type  LinkLocal  Static  DHCPv6  SLAAC


Verify Coexistence Of IPv6 Addresses Type Combination On BMC
    [Documentation]  Verify coexistence of ipv6 addresses type combination on BMC.
    [Tags]  Verify_Coexistence_Of_IPv6_Addresses_Type_Combination_On_BMC
    [Setup]  Run Keywords  Get The Initial DHCPv6 Setting On Each Interface  ${1}
    ...      AND  Get The Initial SLAAC Setting On Each Interface  ${1}
    [Teardown]  Run Keywords  Set And Verify DHCPv6 Property  ${dhcpv6_channel_1}  ${1}
    ...         AND  Set SLAAC Configuration State And Verify  ${slaac_channel_1}  [${HTTP_OK}]  ${1}
    [Template]  Verify IPv6 Addresses Coexist

#   Type1   type2.
    Static  DHCPv6
    DHCPv6  SLAAC
    SLAAC  Static
    Static  Static


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup execution.

    Redfish.Login
    ${active_channel_config}=  Get Active Channel Config
    Set Suite Variable  ${active_channel_config}

    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Set Suite variable  ${ethernet_interface}

    # Get initial IPv4 and IPv6 addresses and address origins for eth0.
    ${initial_ipv4_addressorigin_list}  ${initial_ipv4_addr_list}=  Get Address Origin List And IPv4 or IPv6 Address  IPv4Addresses
    ${initial_ipv6_addressorigin_list}  ${initial_ipv6_addr_list}=  Get Address Origin List And IPv4 or IPv6 Address  IPv6Addresses

    Set Suite Variable   ${initial_ipv4_addressorigin_list}
    Set Suite Variable   ${initial_ipv4_addr_list}
    Set Suite Variable   ${initial_ipv6_addressorigin_list}
    Set Suite Variable   ${initial_ipv6_addr_list}

    # Get initial IPv4 and IPv6 addresses and address origins for eth1.
    ${eth1_initial_ipv4_addressorigin_list}  ${eth1_initial_ipv4_addr_list}=
    ...  Get Address Origin List And IPv4 or IPv6 Address  IPv4Addresses  ${2}
    ${eth1_initial_ipv6_addressorigin_list}  ${eth1_initial_ipv6_addr_list}=
    ...  Get Address Origin List And IPv4 or IPv6 Address  IPv6Addresses  ${2}
    Set Suite Variable   ${eth1_initial_ipv4_addressorigin_list}
    Set Suite Variable   ${eth1_initial_ipv4_addr_list}
    Set Suite Variable   ${eth1_initial_ipv6_addressorigin_list}
    Set Suite Variable   ${eth1_initial_ipv6_addr_list}


Test Setup Execution
    [Documentation]  Test setup execution.

    @{ipv6_network_configurations}=  Get IPv6 Network Configuration
    Set Test Variable  @{ipv6_network_configurations}

    # Get BMC IPv6 address and prefix length.
    ${ipv6_data}=  Get BMC IPv6 Info
    Set Test Variable  ${ipv6_data}


Test Teardown Execution
    [Documentation]  Test teardown execution.

    FFDC On Test Case Fail


Get IPv6 Network Configuration
    [Documentation]  Get Ipv6 network configuration.
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
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${active_channel_config['${CHANNEL_NUMBER}']['name']}

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


Configure IPv6 Address On BMC
    [Documentation]  Add IPv6 Address on BMC.
    [Arguments]  ${ipv6_addr}  ${prefix_len}  ${valid_status_codes}=${HTTP_OK}

    # Description of argument(s):
    # ipv6_addr           IPv6 address to be added (e.g. "2001:EEEE:2222::2022").
    # prefix_len          Prefix length for the IPv6 to be added
    #                     (e.g. "64").
    # valid_status_codes  Expected return code from patch operation
    #                     (e.g. "200").

    ${prefix_length}=  Convert To Integer  ${prefix_len}
    ${empty_dict}=  Create Dictionary
    ${ipv6_data}=  Create Dictionary  Address=${ipv6_addr}
    ...  PrefixLength=${prefix_length}

    ${patch_list}=  Create List

    # Get existing static IPv6 configurations on BMC.
    ${ipv6_network_configurations}=  Get IPv6 Network Configuration
    ${num_entries}=  Get Length  ${ipv6_network_configurations}

    FOR  ${INDEX}  IN RANGE  0  ${num_entries}
      Append To List  ${patch_list}  ${empty_dict}
    END

    ${valid_status_codes}=  Set Variable If  '${valid_status_codes}' == '${HTTP_OK}'
    ...  ${HTTP_OK},${HTTP_NO_CONTENT}
    ...  ${valid_status_codes}

    # We need not check for existence of IPv6 on BMC while adding.
    Append To List  ${patch_list}  ${ipv6_data}
    ${data}=  Create Dictionary  IPv6StaticAddresses=${patch_list}

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Redfish.patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body=&{data}
    ...  valid_status_codes=[${valid_status_codes}]

    Return From Keyword If  '${valid_status_codes}' != '${HTTP_OK},${HTTP_NO_CONTENT}'

    # Note: Network restart takes around 15-18s after patch request processing.
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

    Verify IPv6 And PrefixLength  ${ipv6_addr}  ${prefix_len}

    # Verify if existing static IPv6 addresses still exist.
    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
      Verify IPv6 On BMC  ${ipv6_network_configuration['Address']}
    END

    Validate IPv6 Network Config On BMC


Configure Multiple IPv6 Address on BMC
    [Documentation]  Add multiple IPv6 address on BMC.
    [Arguments]  ${prefix_len}
    ...          ${valid_status_codes}=[${HTTP_OK},${HTTP_NO_CONTENT}]

    # Description of argument(s):
    # prefix_len          Prefix length for the IPv6 to be added
    #                     (e.g. "64").
    # valid_status_codes  Expected return code from patch operation
    #                     (e.g. "200").

    ${ipv6_list}=  Create List  ${test_ipv6_addr}  ${test_ipv6_addr1}
    ${prefix_length}=  Convert To Integer  ${prefix_len}
    ${empty_dict}=  Create Dictionary
    ${patch_list}=  Create List

    # Get existing static IPv6 configurations on BMC.
    ${ipv6_network_configurations}=  Get IPv6 Network Configuration
    ${num_entries}=  Get Length  ${ipv6_network_configurations}

    FOR  ${INDEX}  IN RANGE  0  ${num_entries}
      Append To List  ${patch_list}  ${empty_dict}
    END

    # We need not check for existence of IPv6 on BMC while adding.
    FOR  ${ipv6_addr}  IN  @{ipv6_list}
      ${ipv6_data}=  Create Dictionary  Address=${ipv6_addr}  PrefixLength=${prefix_length}
      Append To List  ${patch_list}  ${ipv6_data}
    END
    ${data}=  Create Dictionary  IPv6StaticAddresses=${patch_list}

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Redfish.patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body=&{data}
    ...  valid_status_codes=${valid_status_codes}

    IF  ${valid_status_codes} != [${HTTP_OK}, ${HTTP_NO_CONTENT}]
        Fail  msg=Static address not added correctly
    END

    # Note: Network restart takes around 15-18s after patch request processing.
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

    # Verify newly added ip address on CLI.
    FOR  ${ipv6_addr}  IN  @{ipv6_list}
      Verify IPv6 And PrefixLength  ${ipv6_addr}  ${prefix_len}
    END

    # Verify if existing static IPv6 addresses still exist.
    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
      Verify IPv6 On BMC  ${ipv6_network_configuration['Address']}
    END

    # Get the latest ipv6 network configurations.
    @{ipv6_network_configurations}=  Get IPv6 Network Configuration

    # Verify newly added ip address on BMC.
    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
      Should Contain Match  ${ipv6_list}  ${ipv6_network_configuration['Address']}
    END

    Validate IPv6 Network Config On BMC


Validate IPv6 Network Config On BMC
    [Documentation]  Check that IPv6 network info obtained via redfish matches info
    ...              obtained via CLI.

    @{ipv6_network_configurations}=  Get IPv6 Network Configuration
    ${ipv6_data}=  Get BMC IPv6 Info
    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
      Should Contain Match  ${ipv6_data}  ${ipv6_network_configuration['Address']}/*
      ...  msg=IPv6 address does not exist.
    END


Delete IPv6 Address
    [Documentation]  Delete IPv6 address of BMC.
    [Arguments]  ${ipv6_addr}
    ...          ${valid_status_codes}=[${HTTP_OK},${HTTP_ACCEPTED},${HTTP_NO_CONTENT}]

    # Description of argument(s):
    # ipv6_addr           IPv6 address to be deleted (e.g. "2001:1234:1234:1234::1234").
    # valid_status_codes  Expected return code from patch operation
    #                     (e.g. "200").  See prolog of rest_request
    #                     method in redfish_plus.py for details.

    ${empty_dict}=  Create Dictionary
    ${patch_list}=  Create List

    @{ipv6_network_configurations}=  Get IPv6 Network Configuration
    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
        IF  '${ipv6_network_configuration['Address']}' == '${ipv6_addr}'
            Append To List  ${patch_list}  ${null}
        ELSE
            Append To List  ${patch_list}  ${empty_dict}
        END
    END

    ${ip_found}=  Run Keyword And Return Status  List Should Contain Value
    ...  ${patch_list}  ${null}  msg=${ipv6_addr} does not exist on BMC
    Pass Execution If  ${ip_found} == ${False}  ${ipv6_addr} does not exist on BMC

    # Run patch command only if given IP is found on BMC
    ${data}=  Create Dictionary  IPv6StaticAddresses=${patch_list}

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Redfish.patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body=&{data}
    ...  valid_status_codes=${valid_status_codes}

    # Note: Network restart takes around 15-18s after patch request processing
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

    # IPv6 address that is deleted should not be there on BMC.
    ${delete_status}=  Run Keyword And Return Status  Verify IPv6 On BMC  ${ipv6_addr}
    IF  '${valid_status_codes}' == '[${HTTP_OK},${HTTP_ACCEPTED},${HTTP_NO_CONTENT}]'
        Should Be True  '${delete_status}' == '${False}'
    ELSE
        Should Be True  '${delete_status}' == '${True}'
    END

    Validate IPv6 Network Config On BMC


Modify IPv6 Address
    [Documentation]  Modify and verify IPv6 address of BMC.
    [Arguments]  ${ipv6}  ${new_ipv6}  ${prefix_len}
    ...  ${valid_status_codes}=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    # Description of argument(s):
    # ipv6                  IPv6 address to be replaced (e.g. "2001:AABB:CCDD::AAFF").
    # new_ipv6              New IPv6 address to be configured.
    # prefix_len            Prefix length value (Range 1 to 128).
    # valid_status_codes    Expected return code from patch operation
    #                       (e.g. "200", "201").

    ${empty_dict}=  Create Dictionary
    ${patch_list}=  Create List
    ${prefix_length}=  Convert To Integer  ${prefix_len}
    ${ipv6_data}=  Create Dictionary
    ...  Address=${new_ipv6}  PrefixLength=${prefix_length}

    # Sample IPv6 network configurations:
    #  "IPv6AddressPolicyTable": [],
    #  "IPv6Addresses": [
    #    {
    #      "Address": "X002:db8:0:2::XX0",
    #      "AddressOrigin": "DHCPv6",
    #      "PrefixLength": 128
    #    },
    #    {
    #      "Address": “X002:db8:0:2:a94:XXff:fe82:XXXX",
    #      "AddressOrigin": "SLAAC",
    #      "PrefixLength": 64
    #    },
    #    {
    #      "Address": “Y002:db8:0:2:a94:efff:fe82:5000",
    #      "AddressOrigin": "Static",
    #      "PrefixLength": 56
    #    },
    #    {
    #      "Address": “Z002:db8:0:2:a94:efff:fe82:5000",
    #      "AddressOrigin": "Static",
    #      "PrefixLength": 56
    #    },
    #    {
    #      "Address": “Xe80::a94:efff:YYYY:XXXX",
    #      "AddressOrigin": "LinkLocal",
    #      "PrefixLength": 64
    #    },
    #    {
    #     "Address": “X002:db8:1:2:eff:233:fee:546",
    #      "AddressOrigin": "Static",
    #      "PrefixLength": 56
    #    }
    #  ],
    #  "IPv6DefaultGateway": “XXXX::ab2e:80fe:87df:XXXX”,
    #  "IPv6StaticAddresses": [
    #    {
    #      "Address": “X002:db8:0:2:a94:efff:fe82:5000",
    #      "PrefixLength": 56
    #    },
    #    {
    #      "Address": “Y002:db8:0:2:a94:efff:fe82:5000",
    #      "PrefixLength": 56
    #    },
    #    {
    #      "Address": “Z002:db8:1:2:eff:233:fee:546",
    #      "PrefixLength": 56
    #    }
    #  ],
    #  "IPv6StaticDefaultGateways": [],

    # Find the position of IPv6 address to be modified.
    @{ipv6_network_configurations}=  Get IPv6 Network Configuration
    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
      IF  '${ipv6_network_configuration['Address']}' == '${ipv6}'
          Append To List  ${patch_list}  ${ipv6_data}
      ELSE
          Append To List  ${patch_list}  ${empty_dict}
      END
    END

    # Modify the IPv6 address only if given IPv6 is found
    ${ip_found}=  Run Keyword And Return Status  List Should Contain Value
    ...  ${patch_list}  ${ipv6_data}  msg=${ipv6} does not exist on BMC
    Pass Execution If  ${ip_found} == ${False}  ${ipv6} does not exist on BMC

    ${data}=  Create Dictionary  IPv6StaticAddresses=${patch_list}

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Redfish.patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ...  body=&{data}  valid_status_codes=${valid_status_codes}

    # Note: Network restart takes around 15-18s after patch request processing.
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

    # Verify if new IPv6 address is configured on BMC.
    Verify IPv6 On BMC  ${new_ipv6}

    # Verify if old IPv6 address is erased.
    ${cmd_status}=  Run Keyword And Return Status
    ...  Verify IPv6 On BMC  ${ipv6}
    Should Be Equal  ${cmd_status}  ${False}  msg=Old IPv6 address is not deleted.

    Validate IPv6 Network Config On BMC


Set SLAAC Configuration State And Verify
    [Documentation]  Set SLAAC configuration state and verify.
    [Arguments]  ${slaac_state}  ${valid_status_codes}=[${HTTP_OK},${HTTP_ACCEPTED},${HTTP_NO_CONTENT}]
    ...  ${channel_number}=${CHANNEL_NUMBER}

    # Description of argument(s):
    # slaac_state         SLAAC state('True' or 'False').
    # valid_status_code   Expected valid status codes.
    # channel_number      Channel number 1(eth0) or 2(eth1).

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    ${data}=  Set Variable If  ${slaac_state} == ${False}  ${DISABLE_SLAAC}  ${ENABLE_SLAAC}
    ${resp}=  Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ...  body=${data}  valid_status_codes=${valid_status_codes}

    # Verify SLAAC is set correctly.
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ${slaac_verify}=  Get From Dictionary  ${resp.dict}  StatelessAddressAutoConfig

    IF  '${slaac_verify['IPv6AutoConfigEnabled']}' != '${slaac_state}'
        Fail  msg=SLAAC not set properly.
    END

Set And Verify DHCPv6 Property
    [Documentation]  Set DHCPv6 property and verify.
    [Arguments]  ${dhcpv6_operating_mode}=${Disabled}  ${channel_number}=${CHANNEL_NUMBER}

    # Description of argument(s):
    # dhcpv6_operating_mode    Enabled if user wants to enable DHCPv6('Enabled' or 'Disabled').
    # channel_number           Channel number 1 or 2.

    Set DHCPv6 Property  ${dhcpv6_operating_mode}  ${channel_number}
    Verify DHCPv6 Property  ${dhcpv6_operating_mode}  ${channel_number}


Set DHCPv6 Property
    [Documentation]  Set DHCPv6 attribute is enables or disabled.
    [Arguments]  ${dhcpv6_operating_mode}=${Disabled}  ${channel_number}=${CHANNEL_NUMBER}

    # Description of argument(s):
    # dhcpv6_operating_mode    Enabled if user wants to enable DHCPv6('Enabled' or 'Disabled').
    # channel_number           Channel number 1 or 2.

    ${data}=  Set Variable If  '${dhcpv6_operating_mode}' == 'Disabled'  ${DISABLE_DHCPv6}  ${ENABLE_DHCPv6}
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ...  body=${data}  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]


Verify DHCPv6 Property
    [Documentation]  Verify DHCPv6 settings is enabled or disabled.
    [Arguments]  ${dhcpv6_operating_mode}  ${channel_number}=${CHANNEL_NUMBER}

    # Description of Argument(s):
    # dhcpv6_operating_mode  Enable/ Disable DHCPv6.
    # channel_number         Channel number 1 or 2.

    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ${dhcpv6_verify}=  Get From Dictionary  ${resp.dict}  DHCPv6

    Should Be Equal  '${dhcpv6_verify['OperatingMode']}'  '${dhcpv6_operating_mode}'


Get IPv6 Static Default Gateway
    [Documentation]  Get IPv6 static default gateway.

    ${active_channel_config}=  Get Active Channel Config
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${active_channel_config['${CHANNEL_NUMBER}']['name']}

    @{ipv6_static_defgw_configurations}=  Get From Dictionary  ${resp.dict}  IPv6StaticDefaultGateways
    RETURN  @{ipv6_static_defgw_configurations}


Configure IPv6 Static Default Gateway On BMC
    [Documentation]  Configure IPv6 static default gateway on BMC.
    [Arguments]  ${ipv6_gw_addr}  ${prefix_length_def}
    ...  ${valid_status_codes}=${HTTP_OK}

    # Description of argument(s):
    # ipv6_gw_addr          IPv6 Static Default Gateway address to be configured.
    # prefix_len_def        Prefix length value (Range 1 to 128).
    # valid_status_codes    Expected return code from patch operation
    #                       (e.g. "200", "204".)

    # Prefix Length is passed as None.
    IF   '${prefix_length_def}' == '${None}'
        ${ipv6_gw}=  Create Dictionary  Address=${ipv6_gw_addr}
    ELSE
        ${ipv6_gw}=  Create Dictionary  Address=${ipv6_gw_addr}  Prefix Length=${prefix_length_def}
    END

    ${ipv6_static_def_gw}=  Get IPv6 Static Default Gateway

    ${num_entries}=  Get Length  ${ipv6_static_def_gw}

    ${patch_list}=  Create List
    ${empty_dict}=  Create Dictionary

    FOR  ${INDEX}  IN RANGE  0  ${num_entries}
      Append To List  ${patch_list}  ${empty_dict}
    END

    ${valid_status_codes}=  Set Variable If  '${valid_status_codes}' == '${HTTP_OK}'
    ...  ${HTTP_OK},${HTTP_NO_CONTENT}
    ...  ${valid_status_codes}

    Append To List  ${patch_list}  ${ipv6_gw}
    ${data}=  Create Dictionary  IPv6StaticDefaultGateways=${patch_list}

    Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ...  body=${data}  valid_status_codes=[${valid_status_codes}]

    # Verify the added static default gateway is present in Redfish Get Output.
    ${ipv6_staticdef_gateway}=  Get IPv6 Static Default Gateway

    ${ipv6_static_def_gw_list}=  Create List
    FOR  ${ipv6_staticdef_gateway}  IN  @{ipv6_staticdef_gateway}
        ${value}=    Get From Dictionary    ${ipv6_staticdef_gateway}    Address
        Append To List  ${ipv6_static_def_gw_list}  ${value}
    END

    IF  '${valid_status_codes}' != '${HTTP_OK},${HTTP_NO_CONTENT}'
        Should Not Contain  ${ipv6_static_def_gw_list}  ${ipv6_gw_addr}
    ELSE
        Should Contain  ${ipv6_static_def_gw_list}  ${ipv6_gw_addr}
    END


Modify IPv6 Static Default Gateway On BMC
    [Documentation]  Modify and verify IPv6 address of BMC.
    [Arguments]  ${ipv6_gw_addr}  ${new_static_def_gw}  ${prefix_length}
    ...  ${valid_status_codes}=[${HTTP_OK},${HTTP_ACCEPTED}]

    # Description of argument(s):
    # ipv6_gw_addr          IPv6 static default gateway address to be replaced (e.g. "2001:AABB:CCDD::AAFF").
    # new_static_def_gw     New static default gateway address to be configured.
    # prefix_length         Prefix length value (Range 1 to 128).
    # valid_status_codes    Expected return code from patch operation
    #                       (e.g. "200", "204").

    ${empty_dict}=  Create Dictionary
    ${patch_list}=  Create List
    # Prefix Length is passed as None.
    IF   '${prefix_length_def}' == '${None}'
        ${modified_ipv6_gw_addripv6_data}=  Create Dictionary  Address=${new_static_def_gw}
    ELSE
        ${modified_ipv6_gw_addripv6_data}=  Create Dictionary  Address=${new_static_def_gw}  Prefix Length=${prefix_length_def}
    END

    @{ipv6_static_def_gw_list}=  Get IPv6 Static Default Gateway

    FOR  ${ipv6_static_def_gw}  IN  @{ipv6_static_def_gw_list}
      IF  '${ipv6_static_def_gw['Address']}' == '${ipv6_gw_addr}'
          Append To List  ${patch_list}  ${modified_ipv6_gw_addripv6_data}
      ELSE
          Append To List  ${patch_list}  ${empty_dict}
      END
    END

    # Modify the IPv6 address only if given IPv6 static default gateway is found.
    ${ip_static_def_gw_found}=  Run Keyword And Return Status  List Should Contain Value
    ...  ${patch_list}  ${modified_ipv6_gw_addripv6_data}  msg=${ipv6_gw_addr} does not exist on BMC
    Pass Execution If  ${ip_static_def_gw_found} == ${False}  ${ipv6_gw_addr} does not exist on BMC

    ${data}=  Create Dictionary  IPv6StaticDefaultGateways=${patch_list}

    Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ...  body=&{data}  valid_status_codes=${valid_status_codes}

    ${ipv6_staticdef_gateway}=  Get IPv6 Static Default Gateway

    ${ipv6_static_def_gw_list}=  Create List
    FOR  ${ipv6_staticdef_gateway}  IN  @{ipv6_staticdef_gateway}
        ${value}=  Get From Dictionary  ${ipv6_staticdef_gateway}  Address
        Append To List  ${ipv6_static_def_gw_list}  ${value}
    END

    Should Contain  ${ipv6_static_def_gw_list}  ${new_static_def_gw}
    # Verify if old static default gateway address is erased.
    Should Not Contain  ${ipv6_static_def_gw_list}  ${ipv6_gw_addr}


Delete IPv6 Static Default Gateway
    [Documentation]  Delete IPv6 static default gateway on BMC.
    [Arguments]  ${ipv6_gw_addr}
    ...          ${valid_status_codes}=[${HTTP_OK},${HTTP_ACCEPTED},${HTTP_NO_CONTENT}]

    # Description of argument(s):
    # ipv6_gw_addr          IPv6 Static Default Gateway address to be deleted.
    # valid_status_codes    Expected return code from patch operation
    #                       (e.g. "200").

    ${patch_list}=  Create List
    ${empty_dict}=  Create Dictionary

    ${ipv6_static_def_gw_list}=  Create List
    @{ipv6_static_defgw_configurations}=  Get IPv6 Static Default Gateway

    FOR  ${ipv6_staticdef_gateway}  IN  @{ipv6_static_defgw_configurations}
        ${value}=  Get From Dictionary  ${ipv6_staticdef_gateway}  Address
        Append To List  ${ipv6_static_def_gw_list}  ${value}
    END

    ${defgw_found}=  Run Keyword And Return Status  List Should Contain Value
    ...  ${ipv6_static_def_gw_list}  ${ipv6_gw_addr}  msg=${ipv6_gw_addr} does not exist on BMC
    Skip If  ${defgw_found} == ${False}  ${ipv6_gw_addr} does not exist on BMC

    FOR  ${ipv6_static_def_gw}  IN  @{ipv6_static_defgw_configurations}
        IF  '${ipv6_static_def_gw['Address']}' == '${ipv6_gw_addr}'
            Append To List  ${patch_list}  ${null}
        ELSE
            Append To List  ${patch_list}  ${empty_dict}
      END
    END

    # Run patch command only if given IP is found on BMC.
    ${data}=  Create Dictionary  IPv6StaticDefaultGateways=${patch_list}

    Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body=&{data}
    ...  valid_status_codes=${valid_status_codes}

    ${data}=  Create Dictionary  IPv6StaticDefaultGateways=${patch_list}

    @{ipv6_static_defgw_configurations}=  Get IPv6 Static Default Gateway
    Should Not Contain Match  ${ipv6_static_defgw_configurations}  ${ipv6_gw_addr}
    ...  msg=IPv6 Static default gateway does not exist.


Check Coexistence Of Linklocalv6 And Static IPv6
    [Documentation]  Verify both linklocalv6 and static IPv6 exist.

    # Verify the address origin contains static and linklocal.
    @{ipv6_addressorigin_list}  ${ipv6_linklocal_addr}=  Get Address Origin List And Address For Type  LinkLocal

    Should Match Regexp  ${ipv6_linklocal_addr}        ${linklocal_addr_format}
    Should Contain       ${ipv6_addressorigin_list}    Static


Check Coexistence Of Static IPv6 And SLAAC
    [Documentation]  Verify both static IPv6 and SLAAC coexist.

    # Verify the address origin contains static and slaac.
    @{ipv6_addressorigin_list}  ${ipv6_static_addr}=
    ...    Get Address Origin List And Address For Type  Static

    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=
    ...    Get Address Origin List And Address For Type  SLAAC


Check Coexistence Of Link Local And SLAAC
    [Documentation]  Verify both link local and SLAAC coexist.

    # Verify the address origin contains SLAAC and link local.
    @{ipv6_addressorigin_list}  ${ipv6_link_local_addr}=
    ...    Get Address Origin List And Address For Type  LinkLocal

    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=
    ...    Get Address Origin List And Address For Type  SLAAC

    Should Match Regexp    ${ipv6_link_local_addr}    ${linklocal_addr_format}


Check Coexistence Of Link Local And DHCPv6
    [Documentation]  Verify both link local and dhcpv6 coexist.

    # Verify the address origin contains dhcpv6 and link local.
    @{ipv6_address_origin_list}  ${ipv6_link_local_addr}=
    ...    Get Address Origin List And Address For Type  LinkLocal

    @{ipv6_address_origin_list}  ${ipv6_dhcpv6_addr}=
    ...    Get Address Origin List And Address For Type  DHCPv6

    Should Match Regexp    ${ipv6_link_local_addr}    ${linklocal_addr_format}


Check If Linklocal Address Is In Correct Format
    [Documentation]  Linklocal address has network part fe80 and host part EUI64.

    # Fetch the linklocal address.
    @{ipv6_addressorigin_list}  ${ipv6_linklocal_addr}=  Get Address Origin List And Address For Type  LinkLocal

    # Follow EUI64 from MAC.
    ${system_mac}=  Get BMC MAC Address
    ${split_octets}=  Split String  ${system_mac}  :
    ${first_octet}=  Evaluate  int('${split_octets[0]}', 16)
    ${flipped_hex}=  Evaluate  format(${first_octet} ^ 2, '02x')
    ${grp1}=  Evaluate  re.sub(r'^0+', '', '${flipped_hex}${split_octets[1]}')  modules=re
    ${grp2}=  Evaluate  re.sub(r'^0+', '', '${split_octets[2]}ff')  modules=re
    ${grp3}=  Evaluate  re.sub(r'^0+', '', '${split_octets[4]}${split_octets[5]}')  modules=re
    ${linklocal}=  Set Variable  fe80::${grp1}:${grp2}:fe${split_octets[3]}:${grp3}

    # Verify the linklocal obtained is the same as on the machine.
    Should Be Equal  ${linklocal}  ${ipv6_linklocal_addr}


Check BMC Gets SLAAC Address
    [Documentation]  Check BMC gets slaac address.

    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=  Get Address Origin List And Address For Type  SLAAC


Get The Initial DHCPv6 Setting On Each Interface
    [Documentation]  Get the initial DHCPv6 setting of each interface.
    [Arguments]  ${channel_number}

    # Description of the argument(s):
    # channel_number    Channel number 1 or 2.

    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ${initial_dhcpv6_iface}=  Get From Dictionary  ${resp.dict}  DHCPv6
    IF  ${channel_number}==${1}
        Set Test Variable  ${dhcpv6_channel_1}  ${initial_dhcpv6_iface['OperatingMode']}
    ELSE
        Set Test Variable  ${dhcpv6_channel_2}  ${initial_dhcpv6_iface['OperatingMode']}
    END


Get The Initial DHCPv6 Settings
    [Documentation]  Get the initial DHCPv6 settings of both the interfaces.

    Get The Initial DHCPv6 Setting On Each Interface  ${1}
    Get The Initial DHCPv6 Setting On Each Interface  ${2}


Get The Initial SLAAC Settings
    [Documentation]  Get the initial SLAAC settings of both the interfaces.

    Get The Initial SLAAC Setting On Each Interface   ${1}
    Get The Initial SLAAC Setting On Each Interface   ${2}


Get The Initial SLAAC Setting On Each Interface
    [Documentation]  Get the initial SLAAC setting of the interface.
    [Arguments]  ${channel_number}

    # Description of the argument(s):
    # channel_number     Channel number 1 or 2.

    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ${initial_slaac_iface}=  Get From Dictionary  ${resp.dict}  StatelessAddressAutoConfig
    IF  ${channel_number}==${1}
        Set Test Variable  ${slaac_channel_1}  ${initial_slaac_iface['IPv6AutoConfigEnabled']}
    ELSE
        Set Test Variable  ${slaac_channel_2}  ${initial_slaac_iface['IPv6AutoConfigEnabled']}
    END


Get Address Origin List And IPv4 or IPv6 Address
    [Documentation]  Get address origin list and address for type.
    [Arguments]  ${ip_address_type}  ${channel_number}=${CHANNEL_NUMBER}

    # Description of the argument(s):
    # ip_address_type  Type of IPv4 or IPv6 address to be checked.
    # channel_number   Channel number 1(eth0) or 2(eth1).

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


Verify All The Addresses Are Intact
    [Documentation]  Verify all the addresses and address origins remain intact.
    [Arguments]    ${channel_number}=${CHANNEL_NUMBER}
    ...  ${initial_ipv4_addressorigin_list}=${initial_ipv4_addressorigin_list}
    ...  ${initial_ipv4_addr_list}=${initial_ipv4_addr_list}

    # Description of argument(s):
    # channel_number                   Channel number 1(eth0) or 2(eth1).
    # initial_ipv4_addressorigin_list  Initial IPv4 address origin list.
    # initial_ipv4_addr_list           Initial IPv4 address list.

    # Verify that it will not impact the IPv4 configuration.
    Sleep  ${NETWORK_TIMEOUT}
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

    # IPv6 Linklocal address must be present.
    @{ipv6_addressorigin_list}  ${ipv6_linklocal_addr}=
    ...  Get Address Origin List And Address For Type  LinkLocal  ${channel_number}

    # IPv4 addresses must remain intact.
    ${ipv4_addressorigin_list}  ${ipv4_addr_list}=
    ...  Get Address Origin List And IPv4 or IPv6 Address  IPv4Addresses  ${channel_number}

    Should be Equal  ${initial_ipv4_addressorigin_list}  ${ipv4_addressorigin_list}
    Should be Equal  ${initial_ipv4_addr_list}  ${ipv4_addr_list}


Get Interface ID Of IPv6
    [Documentation]  Get interface id of IPv6 address.
    [Arguments]    ${ipv6_address}

    # Description of the argument(s):
    # ${ipv6_address}  IPv6 Address to extract the last 4 hextets.

    # Last 64 bits of SLAAC and Linklocal must be the same.
    # Sample IPv6 network configurations.
    #"IPv6AddressPolicyTable": [],
    #  "IPv6Addresses": [
    #    {
    #      "Address": "fe80::xxxx:xxxx:xxxx:xxxx",
    #      "AddressOrigin": "LinkLocal",
    #      "AddressState": null,
    #      "PrefixLength": xx
    #    }
    #  ],
    #    {
    #      "Address": "2002:xxxx:xxxx:xxxx:xxxx",
    #      "AddressOrigin": "SLAAC",
    #      "PrefixLength": 64
    #    }
    #  ],

    ${split_ip_address}=  Split String  ${ipv6_address}  :
    ${missing_ip}=  Evaluate  8 - len(${split_ip_address}) + 1
    ${expanded_ip}=  Create List

    FOR  ${hextet}  IN  @{split_ip_address}
       IF  '${hextet}' == ''
           FOR  ${i}  IN RANGE  ${missing_ip}
               Append To List  ${expanded_ip}  0000
           END
       ELSE
           Append To List  ${expanded_ip}  ${hextet}
       END
    END
    ${interface_id}=  Evaluate  ':'.join(${expanded_ip}[-4:])
    RETURN  ${interface_id}


Set And Verify SLAAC Property On Both Interfaces
    [Documentation]  Set and verify SLAAC property on both interfaces.
    [Arguments]  ${slaac_value_1}  ${slaac_value_2}

    # Description of the argument(s):
    # slaac_value_1  SLAAC value for channel 1.
    # slaac_value_2  SLAAC value for channel 2.

    Set SLAAC Configuration State And Verify  ${slaac_value_1}  [${HTTP_OK}]  ${1}
    Set SLAAC Configuration State And Verify  ${slaac_value_2}  [${HTTP_OK}]  ${2}

    Sleep  30s

    # Check SLAAC Settings for eth0.
    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=
    ...  Get Address Origin List And IPv4 or IPv6 Address  IPv6Addresses  ${1}
    IF  "${slaac_value_1}" == "${True}"
         Should Not Be Empty  ${ipv6_slaac_addr}  SLAAC
    ELSE
        Should Not Contain  ${ipv6_addressorigin_list}  SLAAC
    END

    # Check SLAAC Settings for eth1.
    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=
    ...  Get Address Origin List And IPv4 or IPv6 Address  IPv6Addresses  ${2}
    IF  "${slaac_value_2}" == "${True}"
         Should Not Be Empty  ${ipv6_slaac_addr}  SLAAC
    ELSE
        Should Not Contain  ${ipv6_addressorigin_list}  SLAAC
    END

    Verify All The Addresses Are Intact  ${1}
    Verify All The Addresses Are Intact  ${2}
    ...    ${eth1_initial_ipv4_addressorigin_list}  ${eth1_initial_ipv4_addr_list}


Verify IPv6 Addresses Coexist
    [Documentation]  Verify IPv6 address type coexist.
    [Arguments]   ${type1}  ${type2}

    # Description of the argument(s):
    # type1  IPv6 address type.
    # type2  IPv6 address type.

    IF  '${type1}' == 'Static' and '${type2}' == 'DHCPv6'
        Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}
        Set And Verify DHCPv6 Property  Enabled
    ELSE IF  '${type1}' == 'DHCPv6' and '${type2}' == 'SLAAC'
        Set And Verify DHCPv6 Property  Enabled
        Set SLAAC Configuration State And Verify  ${True}
    ELSE IF  '${type1}' == 'SLAAC' and '${type2}' == 'Static'
        Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}
        Set SLAAC Configuration State And Verify  ${True}
    ELSE IF  '${type1}' == 'Static' and '${type2}' == 'Static'
        Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}
        Configure IPv6 Address On BMC  ${test_ipv6_addr1}  ${test_prefix_length}
    END

    Sleep  ${NETWORK_TIMEOUT}s

    #Verify coexistence.
    Verify The Coexistence Of The Address Type  ${type1}  ${type2}

    IF  '${type1}' == 'Static' or '${type2}' == 'Static'
        Delete IPv6 Address  ${test_ipv6_addr}
    ELSE IF  '${type1}' == 'Static' and '${type2}' == 'Static'
        Delete IPv6 Address  ${test_ipv6_addr1}
    END

    Set And Verify DHCPv6 Property  Disabled
    Set SLAAC Configuration State And Verify  ${False}
