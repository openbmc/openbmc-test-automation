*** Settings ***
Documentation  Network interface and functionalities test module.

Resource  ../lib/rest_client.robot
Resource  ../lib/utils.robot
Resource  ../lib/bmc_network_utils.robot

Force Tags  Network_Test

Library  String
Library  SSHLibrary

Test Setup  Test Init Setup

*** Test Cases ***

Get BMC IPv4 Address And Verify
    [Documentation]  Get BMC IPv4 address and verify.
    [Tags]  Get_BMC_IPv4_Address_And_Verify

    :FOR  ${ipv4_uri}  IN  @{IPv4_URI_List}
    \  ${ipv4_addr}=  Read Attribute  ${ipv4_uri}  Address
    \  Validate IP on BMC  ${ipv4_addr}

Verify IPv4 Prefix Length
    [Documentation]  Get prefix length and verify.
    [Tags]  Verify_IPv4_Prefix_Length

    :FOR  ${ipv4_uri}  IN  @{IPv4_URI_List}
    \  ${prefix_length}=  Read Attribute  ${ipv4_uri}  PrefixLength
    \  Validate Prefix Length On BMC  ${prefix_length}

Verify Gateway Address
    [Documentation]  Get gateway address and verify.
    [Tags]  Verify_Gateway_Address

    :FOR  ${ipv4_uri}  IN  @{IPv4_URI_List}
    \  ${gw_ip}=  Read Attribute  ${ipv4_uri}  Gateway
    \  Validate Route On BMC  ${gw_ip}

Verify MAC Address
    [Documentation]  Get MAC address and verify.
    [Tags]  Verify_MAC_Address
    ${macaddr}=  Read Attribute  ${XYZ_NETWORK_MANAGER}/eth0  MACAddress
    Validate MAC On BMC  ${macaddr}

*** Keywords ***

Test Init Setup
    [Documentation]  Network setup.
    Open Connection And Login

    @{IPv4_URI_List}=  Get IPv4 URI List
    Set Test Variable  @{IPv4_URI_List}

    # Get BMC IP address and prefix length.
    ${ip_data}=  Get BMC IP Info
    Set Test Variable  ${ip_data}

Get IPv4 URI List
    [Documentation]  Get all IPv4 URIs.

    # Sample output:
    #   "data": [
    #     "/xyz/openbmc_project/network/eth0/ipv4/e9767624",
    #     "/xyz/openbmc_project/network/eth0/ipv4/31f4ce8b"
    #   ],

    @{ipv4_uri_list}=  Read Properties  ${XYZ_NETWORK_MANAGER}/eth0/ipv4/
    Should Not Be Empty  ${ipv4_uri_list}  msg=IPv4 URI list is empty.

    [Return]  @{ipv4_uri_list}

Validate IP on BMC
    [Documentation]  Validate IP on BMC.
    [Arguments]  ${ip_address}

    # Description of the argument(s):
    # ip_address  IP address of the system.
    #             ip_data  Suite variable which has list of IP address
    #             and prefix length values.

    Should Contain Match  ${ip_data}  ${ip_address}*
    ...  msg=IP address does not exist.

Validate Prefix Length On BMC
    [Documentation]  Validate prefix length on BMC.
    [Arguments]  ${prefix_length}

    # Description of the argument(s):
    # prefix_length    It indicates netmask, netmask value 255.255.255.0
    #                  is equal to prefix length 24.
    # ip_data          Suite variable which has list of IP address and
    #                  prefix length values.

    Should Contain Match  ${ip_data}  */${prefix_length}
    ...  msg=Prefix length does not exist.

Validate Route On BMC
    [Documentation]  Validate route.
    [Arguments]  ${gw_ip}

    # Description of the argument(s):
    # gw_ip  Gateway IP address.

    ${route_info}=  Get BMC Route Info
    Should Contain  ${route_info}  ${gw_ip}
    ...  msg=Gateway IP address not matching.

Validate MAC on BMC
    [Documentation]  Validate MAC on BMC.
    [Arguments]  ${macaddr}

    # Description of the argument(s):
    # macaddr  MAC address of the BMC.

    ${system_mac}=  Get BMC MAC Address

    Should Contain  ${system_mac}  ${macaddr}
    ...  ignore_case=True  msg=MAC address does not exist.
