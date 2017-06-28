*** Settings ***
Documentation  Network interface and functionalities test module on BMC.

Resource  ../lib/rest_client.robot
Resource  ../lib/utils.robot
Resource  ../lib/bmc_network_utils.robot

Force Tags  Network_Test

Library  String
Library  SSHLibrary

Test Setup  Test Init Setup

*** Variables ***

${alpha_ip}          xx.xx.xx.xx

# 10.x.x.x series is a private IP address range and does not exist in
# our network, so this is chosen to avoid IP conflict.

${valid_ip}          10.6.6.6
${valid_gateway}     10.6.6.1
${valid_prefix_len}  24
${broadcast_ip}      10.6.6.255
${loopback_ip}       127.0.0.1
${multicast_ip}      224.6.6.255
${out_of_range_ip}   10.6.6.256

# There will be 4 octets in IP address (e.g. xx.xx.xx.xx)
# but trying to configure xx.xx.xx

${less_octet_ip}     10.3.36

# For the address 10.6.6.6, the 10.6.6.0 portion describes the
# network ID and the 6 describe the host.

${network_id}        10.6.6.0
${hex_ip}            0xa.0xb.0xc.0xd

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
    \  ${gateway_ip}=  Read Attribute  ${ipv4_uri}  Gateway
    \  Validate Route On BMC  ${gateway_ip}

Verify MAC Address
    [Documentation]  Get MAC address and verify.
    [Tags]  Verify_MAC_Address
    ${macaddr}=  Read Attribute  ${XYZ_NETWORK_MANAGER}/eth0  MACAddress
    Validate MAC On BMC  ${macaddr}

Add New Valid IP And Verify
    [Documentation]  Add new IP address and verify.
    [Tags]  Add_New_Valid_IP_And_Verify

    Configure Network Settings  ${valid_ip}  ${valid_prefix_len}  ${valid_gateway}
    ...  valid

    # Verify whether new IP address is populated on BMC system.
    ${ip_info}=  Get BMC IP Info
    Validate IP On BMC  ${valid_ip}  ${ip_info}

Configure Invalid IP String
    # IP Address  Prefix_length        Gateway_IP        Expected_Result
    ${alpha_ip}   ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure invalid IP address which is a string.
    [Tags]  Configure_Invalid_IP_String

    [Template]  Configure_Network_Settings

Configure Out Of Range IP
    # IP Address        Prefix_length        Gateway_IP        Expected_Result
    ${out_of_range_ip}  ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure out of range IP address.
    [Tags]  Configure_Out_Of_Range_IP

    [Template]  Configure_Network_Settings

Configure Broadcast IP
    # IP Address     Prefix_length        Gateway_IP        Expected_Result
    ${broadcast_ip}  ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure broadcast IP address.
    [Tags]  Configure_Broadcast_IP

    [Template]  Configure_Network_Settings

Configure Multicast IP
    # IP Address     Prefix_length        Gateway_IP        Expected_Result
    ${multicast_ip}  ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure multicast IP address.
    [Tags]  Configure_Multicast_IP

    [Template]  Configure_Network_Settings

Configure Loopback IP
    # IP Address    Prefix_length        Gateway_IP        Expected_Result
    ${loopback_ip}  ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure loopback IP address.
    [Tags]  Configure_Loopback_IP

    [Template]  Configure_Network_Settings

Configure Network ID
    # IP Address   Prefix_length        Gateway_IP        Expected_Result
    ${network_id}  ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure network ID IP address.
    [Tags]  Configure_Network_ID

    [Template]  Configure_Network_Settings

Configure Less Octet IP
    # IP Address      Prefix_length        Gateway_IP        Expected_Result
    ${less_octet_ip}  ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure less octet IP address.
    [Tags]  Configure_Less_Octet_IP

    [Template]  Configure_Network_Settings

Configure Empty IP
    # IP Address   Prefix_length        Gateway_IP        Expected_Result
    ${EMPTY}       ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure less octet IP address.
    [Tags]  Configure_Empty_IP

    [Template]  Configure_Network_Settings

Configure Special Char IP
    # IP Address     Prefix_length         Gateway_IP        Expected_Result
    @@@.%%.44.11     ${valid_prefix_len}   ${valid_gateway}  error

    [Documentation]  Configure invalid IP address contaning special chars.
    [Tags]  Configure_Special_Char_IP

    [Template]  Configure_Network_Settings

Configure Hexadecimal IP
    # IP Address  Prefix_length        Gateway_IP        Expected_Result
    ${hex_ip}     ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure invalid IP address contaning hex value.
    [Tags]  Configure_Hexadecimal_IP


    [Template]  Configure_Network_Settings


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

Validate IP On BMC
    [Documentation]  Validate IP on BMC.
    [Arguments]  ${ip_address}  ${ip_info}=${ip_data}

    # Description of argument(s):
    # ip_address  IP address of the system.
    # ip_info     List of IP address and prefix length values.

    Should Contain Match  ${ip_info}  ${ip_address}*
    ...  msg=IP address does not exist.

Validate Prefix Length On BMC
    [Documentation]  Validate prefix length on BMC.
    [Arguments]  ${prefix_length}

    # Description of argument(s):
    # prefix_length    It indicates netmask, netmask value 255.255.255.0
    #                  is equal to prefix length 24.
    # ip_data          Suite variable which has list of IP address and
    #                  prefix length values.

    Should Contain Match  ${ip_data}  */${prefix_length}
    ...  msg=Prefix length does not exist.

Validate Route On BMC
    [Documentation]  Validate route.
    [Arguments]  ${gateway_ip}

    # Description of argument(s):
    # gateway_ip  Gateway IP address.

    ${route_info}=  Get BMC Route Info
    Should Contain  ${route_info}  ${gateway_ip}
    ...  msg=Gateway IP address not matching.

Validate MAC on BMC
    [Documentation]  Validate MAC on BMC.
    [Arguments]  ${macaddr}

    # Description of argument(s):
    # macaddr  MAC address of the BMC.

    ${system_mac}=  Get BMC MAC Address

    Should Contain  ${system_mac}  ${macaddr}
    ...  ignore_case=True  msg=MAC address does not exist.

Configure Network Settings
    [Documentation]  Configure network settings.
    [Arguments]  ${ip_addr}  ${prefix_len}  ${gateway_ip}  ${expected_result}

    # Description of argument(s):
    # ip_addr          IP address of BMC.
    # prefix_len       Prefix length.
    # gateway_ip       Gateway IP address.
    # expected_result  Expected status of network setting configuration.

    ${len}=  Convert To Bytes  ${prefix_len}

    @{ip_parm_list}=  Create List  xyz.openbmc_project.Network.IP.Protocol.IPv4
    ...  ${ip_addr}  ${len}  ${gateway_ip}

    ${data}=  Create Dictionary  data=@{ip_parm_list}
    ${resp}=  OpenBMC Post Request
    ...  ${XYZ_NETWORK_MANAGER}/eth0/action/IP  data=${data}
    ${json}=  To JSON  ${resp.content}

    Run Keyword If  '${expected_result}' == 'error'  Run Keywords
    ...  Should Not Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ...  AND  Should Be Equal As Strings  ${json['status']}  ${expected_result}
    ...  ELSE
    ...  Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
