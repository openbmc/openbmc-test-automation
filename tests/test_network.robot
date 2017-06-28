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

Add New Valid IP And Verify
    [Documentation]  Add new IP address and verify.
    [Tags]  Add_New_Valid_IP_And_Verify

    Add New IP On BMC  ${valid_ip}

    # Verify whether new IP address is populated on BMC system.
    Test Init Setup
    Validate IP On BMC  ${valid_ip}

Configure Invalid IP String  ${string_ip}
    # IP Address  Prefix_length  Gateway_IP
    ${string_ip}  ${prefix_l}    ${valid_gw}

    [Documentation]  Configure invalid IP address which is a string.
    [Tags]  Configure_Invalid_String

    [Template]  Configure_Network_Settings

Configure Out Of Range IP  ${out_of_range_ip}
    # IP Address        Prefix_length  Gateway_IP
    ${out_of_range_ip}  ${prefix_l}    ${valid_gw}

    [Documentation]  Configure out of range IP address.
    [Tags]  Configure_Out_Of_Range_IP

    [Template]  Configure_Network_Settings

Configure Broadcast IP  ${broadcast_ip}
    # IP Address     Prefix_length  Gateway_IP
    ${broadcast_ip}  ${prefix_l}    ${valid_gw}

    [Documentation]  Configure broadcast IP address.
    [Tags]  Configure_Broadcast_IP

    [Template]  Configure_Network_Settings

Configure Multicast IP  ${multicast_ip}
    # IP Address     Prefix_length  Gateway_IP
    ${multicast_ip}  ${prefix_l}    ${valid_gw}

    [Documentation]  Configure multicast IP address.
    [Tags]  Configure_Multicast_IP

    [Template]  Configure_Network_Settings

Configure Loopback IP  ${loopback_ip}
    # IP Address     Prefix_length  Gateway_IP
    ${loopback_ip}  ${prefix_l}    ${valid_gw}

    [Documentation]  Configure loopback IP address.
    [Tags]  Configure_Loopback_IP


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

Add New IP On BMC
    [Documentation]  Add new IP address on BMC.
    [Arguments]  ${ipaddr}=10.6.6.6  ${len}=24  ${gw_ip}=${valid_gw}

    # Description of argument(s):
    # ipaddr  IP address of BMC.
    # len     Prefix length.
    # gw_ip   Gateway IP address.

    ${len}=  Convert To Bytes  ${len}

    @{ip_parms}=  Create List  xyz.openbmc_project.Network.IP.Protocol.IPv4  ${ip_addr}
    ...  ${len}  ${gw_ip}

    ${data}=  create dictionary  data=@{ip_parms}
    ${resp}=  OpenBMC Post Request  ${XYZ_NETWORK_MANAGER}/eth0/action/IP  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Configure Network Settings
    [Documentation]  Configure network settings.
    [Arguments]  ${ipaddr}=10.6.6.6  ${len}=24  ${gw_ip}=10.6.6.1
    ...          ${scenario}=error

    # Description of argument(s):
    # ipaddr  IP address of BMC.
    # len     Prefix length.
    # gw_ip   Gateway IP address.

    ${len}=  Convert To Bytes  ${len}

    @{ip_parms}=  Create List  xyz.openbmc_project.Network.IP.Protocol.IPv4  ${ip_addr}
    ...  ${len}  ${gw_ip}

    ${data}=  create dictionary  data=@{ip_parms}
    ${resp}=  OpenBMC Post Request  ${XYZ_NETWORK_MANAGER}/eth0/action/IP  data=${data}
    ${json}=  to json  ${resp.content}

    Run Keywords
    ...  Should Not Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ...  AND  should be equal as strings  ${json['status']}  ${scenario}
