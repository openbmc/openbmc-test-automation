*** Settings ***
Documentation  Network interface IPv6 configuration and verification
               ...  tests.

Resource       ../../lib/bmc_redfish_resource.robot
Resource       ../../lib/openbmc_ffdc.robot
Resource       ../../lib/bmc_ipv6_utils.robot
Resource       ../../lib/external_intf/vmi_utils.robot
Library        ../../lib/bmc_network_utils.py
Library        Collections

Test Setup     Test Setup Execution
Test Teardown  Test Teardown Execution
Suite Setup    Suite Setup Execution

Test Tags     BMC_IPv6

*** Variables ***
${test_ipv6_addr}            2001:db8:3333:4444:5555:6666:7777:8888
${test_ipv6_invalid_addr}    2001:db8:3333:4444:5555:6666:7777:JJKK
${test_ipv6_addr1}           2001:db8:3333:4444:5555:6666:7777:9999

# Valid prefix length is a integer ranges from 1 to 128.
${test_prefix_length}        64
${ipv6_gw_addr}              2002:903:15F:32:9:3:32:1
${prefix_length_def}         None
${invalid_staticv6_gateway}  9.41.164.1

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


Enable SLAACv6 On BMC And Verify
    [Documentation]  Enable SLAACv6 on BMC and verify.
    [Tags]  Enable_SLAACv6_On_BMC_And_Verify

    Set SLAACv6 Configuration State And Verify  ${True}


Enable DHCPv6 Property On BMC And Verify
    [Documentation]  Enable DHCPv6 property on BMC and verify.
    [Tags]  Enable_DHCPv6_Property_On_BMC_And_Verify

    Set And Verify DHCPv6 Property  Enabled


Disable DHCPv6 Property On BMC And Verify
    [Documentation]  Disable DHCPv6 property on BMC and verify.
    [Tags]  Disable_DHCPv6_Property_On_BMC_And_Verify

    Set And Verify DHCPv6 Property  Disabled


Configure Invalid Static IPv6 And Verify
    [Documentation]  Configure invalid static IPv6 and verify.
    [Tags]  Configure_Invalid_Static_IPv6_And_Verify
    [Template]  Configure IPv6 Address On BMC

    #invalid_ipv6         prefix length           valid_status_code
    ${ipv4_hexword_addr}  ${test_prefix_length}   ${HTTP_BAD_REQUEST}


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


Set SLAACv6 Configuration State And Verify
    [Documentation]  Set SLAACv6 configuration state and verify.
    [Arguments]  ${slaac_state}  ${valid_status_codes}=[${HTTP_OK},${HTTP_ACCEPTED},${HTTP_NO_CONTENT}]

    # Description of argument(s):
    # slaac_state         SLAACv6 state('True' or 'False').
    # valid_status_code   Expected valid status codes.

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    ${data}=  Set Variable If  ${slaac_state} == ${False}  ${DISABLE_SLAAC}  ${ENABLE_SLAAC}
    ${resp}=  Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ...  body=${data}  valid_status_codes=${valid_status_codes}

    # Verify SLAACv6 is set correctly.
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ${slaac_verify}=  Get From Dictionary  ${resp.dict}  StatelessAddressAutoConfig

    IF  '${slaac_verify['IPv6AutoConfigEnabled']}' != '${slaac_state}'
        Fail  msg=SLAACv6 not set properly.
    END


Set And Verify DHCPv6 Property
    [Documentation]  Set DHCPv6 attribute and verify.
    [Arguments]  ${dhcpv6_operating_mode}=${Disabled}

    # Description of argument(s):
    # dhcpv6_operating_mode    Enabled if user wants to enable DHCPv6('Enabled' or 'Disabled').

    ${data}=  Set Variable If  '${dhcpv6_operating_mode}' == 'Disabled'  ${DISABLE_DHCPv6}  ${ENABLE_DHCPv6}
    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ...  body=${data}  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]

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


Modify Static Default Gateway
    [Documentation]  Modify and verify IPv6 address of BMC.
    [Arguments]  ${ipv6_gw_addr}  ${new_static_def_gw}  ${prefix_length}
    ...  ${valid_status_codes}=[${HTTP_OK},${HTTP_ACCEPTED}]

    # Description of argument(s):
    # ipv6_gw_addr          IPv6 static default gateway address to be replaced (e.g. "2001:AABB:CCDD::AAFF").
    # new_static_def_gw     New static default gateway address to be configured.
    # prefix length         Prefix length value (Range 1 to 128).
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
