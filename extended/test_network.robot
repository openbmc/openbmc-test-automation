*** Settings ***
Documentation  Network interface and functionalities test module on BMC.

Resource  ../lib/ipmi_client.robot
Resource  ../lib/rest_client.robot
Resource  ../lib/utils.robot
Resource  ../lib/bmc_network_utils.robot
Resource  ../lib/openbmc_ffdc.robot

Force Tags  Network_Test

Library  String
Library  SSHLibrary

Test Setup     Test Setup Execution
Test Teardown  Test Teardown Execution

*** Variables ***

${alpha_ip}          xx.xx.xx.xx

# 10.x.x.x series is a private IP address range and does not exist in
# our network, so this is chosen to avoid IP conflict.

${valid_ip}          10.6.6.6
${valid_ip2}         10.6.6.7
@{valid_ips}         ${valid_ip}  ${valid_ip2}
${valid_gateway}     10.6.6.1
${valid_prefix_len}  ${24}
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
${negative_ip}       10.-6.-6.6

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
    ${macaddr}=  Read Attribute  ${NETWORK_MANAGER}/eth0  MACAddress
    Validate MAC On BMC  ${macaddr}

Add New Valid IP And Verify
    [Documentation]  Add new IP address and verify.
    [Tags]  Add_New_Valid_IP_And_Verify

    Configure Network Settings  ${valid_ip}  ${valid_prefix_len}
    ...  ${valid_gateway}  valid

    # Verify whether new IP object is created for the given IP via REST.
    # Delete IP address and IP object after verification.
    Verify IP Address Via REST And Delete  ${valid_ip}

Configure Invalid IP String
    # IP Address  Prefix_length        Gateway_IP        Expected_Result
    ${alpha_ip}   ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure invalid IP address which is a string.
    [Tags]  Configure_Invalid_IP_String

    [Template]  Configure Network Settings

Configure Out Of Range IP
    # IP Address        Prefix_length        Gateway_IP        Expected_Result
    ${out_of_range_ip}  ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure out-of-range IP address.
    [Tags]  Configure_Out_Of_Range_IP

    [Template]  Configure Network Settings

Configure Broadcast IP
    # IP Address     Prefix_length        Gateway_IP        Expected_Result
    ${broadcast_ip}  ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure broadcast IP address.
    [Tags]  Configure_Broadcast_IP

    [Template]  Configure Network Settings

Configure Multicast IP
    # IP Address     Prefix_length        Gateway_IP        Expected_Result
    ${multicast_ip}  ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure multicast IP address.
    [Tags]  Configure_Multicast_IP

    [Template]  Configure Network Settings

Configure Loopback IP
    # IP Address    Prefix_length        Gateway_IP        Expected_Result
    ${loopback_ip}  ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure loopback IP address.
    [Tags]  Configure_Loopback_IP

    [Template]  Configure Network Settings

Configure Network ID
    # IP Address   Prefix_length        Gateway_IP        Expected_Result
    ${network_id}  ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure network ID IP address.
    [Tags]  Configure_Network_ID

    [Template]  Configure Network Settings

Configure Less Octet IP
    # IP Address      Prefix_length        Gateway_IP        Expected_Result
    ${less_octet_ip}  ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure less octet IP address.
    [Tags]  Configure_Less_Octet_IP

    [Template]  Configure Network Settings

Configure Empty IP
    # IP Address   Prefix_length        Gateway_IP        Expected_Result
    ${EMPTY}       ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure less octet IP address.
    [Tags]  Configure_Empty_IP

    [Template]  Configure Network Settings

Configure Special Char IP
    # IP Address     Prefix_length         Gateway_IP        Expected_Result
    @@@.%%.44.11     ${valid_prefix_len}   ${valid_gateway}  error

    [Documentation]  Configure invalid IP address containing special chars.
    [Tags]  Configure_Special_Char_IP

    [Template]  Configure Network Settings

Configure Hexadecimal IP
    # IP Address  Prefix_length        Gateway_IP        Expected_Result
    ${hex_ip}     ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure invalid IP address containing hex value.
    [Tags]  Configure_Hexadecimal_IP

    [Template]  Configure Network Settings

Configure Negative Octet IP
    # IP Address    Prefix_length        Gateway_IP        Expected_Result
    ${negative_ip}  ${valid_prefix_len}  ${valid_gateway}  error

    [Documentation]  Configure invalid IP address containing negative octet.
    [Tags]  Configure_Negative_Octet_IP

    [Template]  Configure Network Settings

Add New Valid IP With Blank Gateway
    [Documentation]  Add new IP with blank gateway.
    [Tags]  Add_New_Valid_IP_With_Blank_Gateway

    Configure Network Settings  ${valid_ip}  ${valid_prefix_len}  ${EMPTY}
    ...  valid

    # Verify whether new IP object is created for the given IP via REST.
    # Delete IP address and IP object after verification.
    Verify IP Address Via REST And Delete  ${valid_ip}

Configure Invalid Gateway String
    # IP Address  Prefix_length        Gateway_IP   Expected_Result
    ${valid_ip}   ${valid_prefix_len}  ${alpha_ip}  error

    [Documentation]  Configure invalid IP address to a gateway which is
    ...  an alpha string and expect an error.
    [Tags]  Configure_Invalid_Gateway_String

    [Template]  Configure Network Settings

Configure Out Of Range IP For Gateway
    # IP Address  Prefix_length        Gateway_IP          Expected_Result
    ${valid_ip}   ${valid_prefix_len}  ${out_of_range_ip}  error

    [Documentation]  Configure out-of-range IP for gateway and expect an error.
    [Tags]  Configure_Out_Of_Range_IP_For_Gateway

    [Template]  Configure Network Settings

Configure Broadcast IP For Gateway
    # IP Address  Prefix_length        Gateway_IP       Expected_Result
    ${valid_ip}   ${valid_prefix_len}  ${broadcast_ip}  error

    [Documentation]  Configure broadcast IP for gateway and expect an error.
    [Tags]  Configure_Broadcast_IP_For_Gateway

    [Template]  Configure Network Settings

Configure Loopback IP For Gateway
    # IP Address  Prefix_length        Gateway_IP      Expected_Result
    ${valid_ip}   ${valid_prefix_len}  ${loopback_ip}  error

    [Documentation]  Configure loopback IP for gateway and expect an error.
    [Tags]  Configure_Loopback_IP_For_Gateway

    [Template]  Configure Network Settings

Configure Multicast IP For Gateway
    # IP Address  Prefix_length        Gateway_IP       Expected_Result
    ${valid_ip}   ${valid_prefix_len}  ${multicast_ip}  error

    [Documentation]  Configure multicast IP for gateway and expect an error.
    [Tags]  Configure_Multicast_IP_For_Gateway

    [Template]  Configure Network Settings

Configure Network ID For Gateway
    # IP Address  Prefix_length        Gateway_IP     Expected_Result
    ${valid_ip}   ${valid_prefix_len}  ${network_id}  error

    [Documentation]  Configure network ID for gateway and expect an error.
    [Tags]  Configure_Network_ID_For_Gateway

    [Template]  Configure Network Settings

Configure Less Octet IP For Gateway
    # IP Address  Prefix_length        Gateway_IP        Expected_Result
    ${valid_ip}   ${valid_prefix_len}  ${less_octet_ip}  error

    [Documentation]  Configure less octet IP for gateway and expect an error.
    [Tags]  Configure_Less_Octet_IP_For_Gateway

    [Template]  Configure Network Settings

Configure Special Char IP For Gateway
    # IP Address  Prefix_length        Gateway_IP    Expected_Result
    ${valid_ip}   ${valid_prefix_len}  @@@.%%.44.11  error

    [Documentation]  Configure special char IP for gateway and expect an error.
    [Tags]  Configure_Special_Char_IP_For_Gateway

    [Template]  Configure Network Settings

Configure Hexadecimal IP For Gateway
    # IP Address  Prefix_length        Gateway_IP  Expected_Result
    ${valid_ip}   ${valid_prefix_len}  ${hex_ip}   error

    [Documentation]  Configure hexadecimal IP for gateway and expect an error.
    [Tags]  Configure_Hexadecimal_IP_For_Gateway

    [Template]  Configure Network Settings

Configure Out Of Range Prefix Length
    # IP Address  Prefix_length  Gateway_IP        Expected_Result
    ${valid_ip}   33             ${valid_gateway}  error

    [Documentation]  Configure out-of-range prefix length and expect an error.
    [Tags]  Configure_Out_Of_Range_Prefix_Length

    [Template]  Configure Network Settings

Configure Negative Value For Prefix Length
    # IP Address  Prefix_length  Gateway_IP        Expected_Result
    ${valid_ip}   -10            ${valid_gateway}  error

    [Documentation]  Configure negative prefix length and expect an error.
    [Tags]  Configure_Negative_Value_For_Prefix_Length

    [Template]  Configure Network Settings

Configure Non Numeric Value For Prefix Length
    # IP Address  Prefix_length  Gateway_IP        Expected_Result
    ${valid_ip}   xx             ${valid_gateway}  error

    [Documentation]  Configure non numeric  value prefix length and expect
    ...  an error.
    [Tags]  Configure_String_Value_For_Prefix_Length

    [Template]  Configure Network Settings

Add Fourth Octet Threshold IP And Verify
    [Documentation]  Add fourth octet threshold IP and verify.
    [Tags]  Add_Fourth_Octet_Threshold_IP_And_Verify

    Configure Network Settings  10.6.6.254  ${valid_prefix_len}
    ...  ${valid_gateway}  valid

    # Verify whether new IP object is created for the given IP via REST.
    # Delete IP address and IP object after verification.

    Verify IP Address Via REST And Delete  10.6.6.254

Add Third Octet Threshold IP And Verify
    [Documentation]  Add third octet threshold IP and verify.
    [Tags]  Add_Third_Octet_Threshold_IP_And_Verify

    Configure Network Settings  10.6.255.6  ${valid_prefix_len}
    ...  ${valid_gateway}  valid

    # Verify whether new IP object is created for the given IP via REST.
    # Delete IP address and IP object after verification.

    Verify IP Address Via REST And Delete  10.6.255.6

Add Second Octet Threshold IP And Verify
    [Documentation]  Add second octet threshold IP and verify.
    [Tags]  Add_Second_Octet_Threshold_IP_And_Verify

    Configure Network Settings  10.255.6.6  ${valid_prefix_len}
    ...  ${valid_gateway}  valid

    # Verify whether new IP object is created for the given IP via REST.
    # Delete IP address and IP object after verification.

    Verify IP Address Via REST And Delete  10.255.6.6

Add First Octet Threshold IP And Verify
    [Documentation]  Add first octet threshold IP and verify.
    [Tags]  Add_First_Octet_Threshold_IP_And_Verify

    Configure Network Settings  223.6.6.6  ${valid_prefix_len}
    ...  ${valid_gateway}  valid

    # Verify whether new IP object is created for the given IP via REST.
    # Delete IP address and IP object after verification.

    Verify IP Address Via REST And Delete  223.6.6.6

Configure Lowest Prefix Length
    [Documentation]  Configure lowest prefix length.
    [Tags]  Configure_Lowest_Prefix_Length

    Configure Network Settings  ${valid_ip}  ${1}
    ...  ${valid_gateway}  valid

    # Verify whether new IP object is created for the given IP via REST.
    # Delete IP address and IP object after verification.
    Verify IP Address Via REST And Delete  ${valid_ip}

Configure Threshold Prefix Length
    [Documentation]  Configure threshold prefix length.
    [Tags]  Configure_Threshold_Prefix_Length

    Configure Network Settings  ${valid_ip}  ${32}
    ...  ${valid_gateway}  valid

    # Verify whether new IP object is created for the given IP via REST.
    # Delete IP address and IP object after verification.
    Verify IP Address Via REST And Delete  ${valid_ip}

Verify Default Gateway
    [Documentation]  Verify default gateway.
    [Tags]  Verify that the default gateway has a valid route.

    ${default_gw}=  Read Attribute  ${NETWORK_MANAGER}/config
    ...  DefaultGateway
    Validate Route On BMC  ${default_gw}

Verify Hostname
    [Documentation]  Verify that the hostname read via REST is the same as the
    ...  hostname configured on system.
    [Tags]  Verify_Hostname

    ${hostname}=  Read Attribute  ${NETWORK_MANAGER}/config  HostName
    Validate Hostname On BMC  ${hostname}

Run IPMI With Multiple IPs Configured
    [Documentation]  Test out-of-band IPMI command with multiple IPs configured.
    [Tags]  Run_IPMI_With_Multiple_IPs_Configured
    [Teardown]  Clear IP Address

    # Configure two IPs and verify.

    :FOR  ${loc_valid_ip}  IN  @{valid_ips}
    \  Configure Network Settings  ${loc_valid_ip}  ${valid_prefix_len}
    \  ...  ${valid_gateway}  valid

    @{ip_uri_list}=  Get IPv4 URI List
    @{ip_list}=  Get List Of IP Address Via REST  @{ip_uri_list}

    List Should Contain Sub List  ${ip_list}  ${valid_ips}
    ...  msg=IP address is not configured.

    Run External IPMI Standard Command  chassis bootparam get 5

*** Keywords ***

Clear IP Address
    [Documentation]  Delete the IPs
    @{ip_uri_list}=  Get IPv4 URI List

    # Remove link local address.
    # Example:
    # /xyz/openbmc_project/network/eth0/ipv4/99b89af4
    # {
    #    "Address": "169.254.53.61",
    #    "Gateway": "0.0.0.0",
    #    "Origin": "xyz.openbmc_project.Network.IP.AddressOrigin.LinkLocal",
    #    "PrefixLength": 16,
    #    "Type": "xyz.openbmc_project.Network.IP.Protocol.IPv4"
    # }

    :FOR  ${ipv4}  IN  @{ip_uri_list}
    \  ${resp}=  Read Attribute  ${ipv4}  Origin
    \  Run Keyword If
    ...  "${resp}" == "xyz.openbmc_project.Network.IP.AddressOrigin.LinkLocal"
    ...  Remove From List  ${ipv4}  ${ip_uri_list}

    :FOR  ${loc_valid_ip}  IN  @{valid_ips}
    \  Delete IP And Object  ${loc_valid_ip}  @{ip_uri_list}

Test Setup Execution
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

    @{ipv4_uri_list}=  Read Properties  ${NETWORK_MANAGER}/eth0/ipv4/
    Should Not Be Empty  ${ipv4_uri_list}  msg=IPv4 URI list is empty.

    [Return]  @{ipv4_uri_list}


Validate IP On BMC
    [Documentation]  Validate IP on BMC.
    [Arguments]  ${ip_address}  ${ip_info}=${ip_data}

    # Description of argument(s):
    # ip_address  IP address of the system.
    # ip_info     List of IP address and prefix length values.

    Should Contain Match  ${ip_info}  ${ip_address}/*
    ...  msg=IP address does not exist.

Verify IP Address Via REST And Delete
    [Documentation]  Verify IP address via REST and delete.
    [Arguments]  ${ip_addr}

    # Description of argument(s):
    # ip_addr      IP address to be verified.

    @{ip_uri_list}=  Get IPv4 URI List
    @{ip_list}=  Get List Of IP Address Via REST  @{ip_uri_list}

    List Should Contain Value  ${ip_list}  ${ip_addr}
    ...  msg=IP address is not configured.

    # If IP address is configured, delete it.
    Delete IP And Object  ${ip_addr}  @{ip_uri_list}

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

    # If gateway IP is empty or 0.0.0.0 it will not have route entry.

    Run Keyword If  '${gateway_ip}' == '0.0.0.0'
    ...      Pass Execution  Gatway IP is "0.0.0.0".
    ...  ELSE
    ...      Should Contain  ${route_info}  ${gateway_ip}
    ...      msg=Gateway IP address not matching.


Configure Network Settings
    [Documentation]  Configure network settings.
    [Arguments]  ${ip_addr}  ${prefix_len}  ${gateway_ip}  ${expected_result}

    # Description of argument(s):
    # ip_addr          IP address of BMC.
    # prefix_len       Prefix length.
    # gateway_ip       Gateway IP address.
    # expected_result  Expected status of network setting configuration.

    @{ip_parm_list}=  Create List  xyz.openbmc_project.Network.IP.Protocol.IPv4
    ...  ${ip_addr}  ${prefix_len}  ${gateway_ip}

    ${data}=  Create Dictionary  data=@{ip_parm_list}

    Run Keyword And Ignore Error  OpenBMC Post Request
    ...  ${NETWORK_MANAGER}/eth0/action/IP  data=${data}

    # After any modification on network interface, BMC restarts network
    # module, wait until it is reachable.

    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_RETRY_TIME}
    ...  ${NETWORK_TIMEOUT}

    # Verify whether new IP address is populated on BMC system.
    # It should not allow to configure invalid settings.

    ${ip_data}=  Get BMC IP Info
    ${status}=  Run Keyword And Return Status
    ...  Validate IP On BMC  ${ip_addr}  ${ip_data}

    Run Keyword If  '${expected_result}' == 'error'
    ...      Should Be Equal  ${status}  ${False}
    ...      msg=Allowing the configuration of an invalid IP.
    ...  ELSE
    ...      Should Be Equal  ${status}  ${True}
    ...      msg=Not allowing the configuration of a valid IP.

Validate Hostname On BMC
    [Documentation]  Verify that the hostname read via REST is the same as the
    ...  hostname configured on system.
    [Arguments]  ${hostname}

    # Description of argument(s):
    # hostname  A hostname value which is to be compared to the hostname
    #           configured on system.

    ${sys_hostname}=  Get BMC Hostname

    Should Contain  ${sys_hostname}  ${hostname}
    ...  ignore_case=True  msg=Hostname does not exist.

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Close All Connections
