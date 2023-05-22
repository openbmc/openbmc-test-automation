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
${test_ipv6_invalid_addr}  2001:db8:3333:4444:5555:6666:7777:JJKK
${test_ipv6_addr1}         2001:db8:3333:4444:5555:6666:7777:9999

# Valid prefix length is a integer ranges from 1 to 128.
${test_prefix_length}     64


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
    [Template]  Configure IPv6 Address On BMC


    # IPv6 address     Prefix length
    ${test_ipv6_addr}  ${test_prefix_length}


Delete IPv6 Address And Verify
    [Documentation]  Delete IPv6 address and verify.
    [Tags]  Delete_IPv6_Address_And_Verify

    Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}

    Delete IPv6 Address  ${test_ipv6_addr}



Modify IPv6 Address And verify
    [Documentation]  Modify IPv6 address and verify.
    [Tags]  Modify_IPv6_Address_And_Verify

    Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}

    Modify IPv6 Address  ${test_ipv6_addr}  ${test_ipv6_addr1}  ${test_prefix_length}


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
    [Return]  @{ipv6_network_configurations}


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

    ${valid_status_codes}=  Run Keyword If  '${valid_status_codes}' == '${HTTP_OK}'
    ...  Set Variable   ${HTTP_OK},${HTTP_NO_CONTENT}
    ...  ELSE  Set Variable  ${valid_status_codes}

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
    [Arguments]  ${ipv6_addr}  ${valid_status_codes}=${HTTP_OK}

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
    ...  valid_status_codes=[${valid_status_codes}]

    # Note: Network restart takes around 15-18s after patch request processing
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

    # IPv6 address that is deleted should not be there on BMC.
    ${delete_status}=  Run Keyword And Return Status  Verify IPv6 On BMC  ${ipv6_addr}
    IF  '${valid_status_codes}' == '${HTTP_OK}'
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
      Run Keyword If  '${ipv6_network_configuration['Address']}' == '${ipv6}'
      ...  Append To List  ${patch_list}  ${ipv6_data}
      ...  ELSE  Append To List  ${patch_list}  ${empty_dict}
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

    Validate IPv6 Network Config On BMC
