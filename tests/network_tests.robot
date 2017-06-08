*** Settings ***
Documentation  Network testing including IP address, netmask and MAC.
...            Here settings, configurations, adding/deleting IP address
...            and modifying is done through REST and verified against the
...            system data.

Resource  ../lib/rest_client.robot
Resource  ../lib/utils.robot
Resource  ../lib/bmc_network_utils.robot

Library  String
Library  SSHLibrary

Suite Setup  Network Setup

*** Test Cases ***

Get IP Address And Verify
    [Documentation]  Get IP address and verify.
    [Tags]  Get_IP_Address_And_Verify

    :FOR  ${ipv4_object}  IN  @{IPV4_OBJECTS}
    \  ${ipv4_addr}=  Read Attribute  ${ipv4_object}  Address
    \  Validate IP on BMC  ${ipv4_addr}

Get Prefix Length And Verify
    [Documentation]  Get prefix length and verify.
    [Tags]  Get_Prefix_Length_And_Verify

    :FOR  ${ipv4_object}  IN  @{IPV4_OBJECTS}
    \  ${prefix_length}=  Read Attribute  ${ipv4_object}  PrefixLength
    \  Validate Prefix Length On BMC  ${prefix_length}

Get Gateway Address And Verify
    [Documentation]  Get gateway address and verify.
    [Tags]  Get_GW_Address_And_Verify

    :FOR  ${ipv4_object}  IN  @{ipv4_objects}
    \  ${gw_ip}=  Read Attribute  ${ipv4_object}  Gateway
    \  Validate Route On BMC  ${gw_ip}

*** Keywords ***

Network Setup
    [Documentation]  Network setup.
    Open Connection And Login

    @{IPV4_OBJECTS}=  Get All IPv4 Objects
    Set Suite Variable  @{IPV4_OBJECTS}

    # Get System IP address and prefix length.
    ${IP_AND_PREFIXES}=  Get System IP And Prefix_Length
    Set Suite Variable  ${IP_AND_PREFIXES}

Get All IPv4 Objects
    [Documentation]  Get all IPv4 objects.

    # Sample output:
    #   "data": [
    #     "/xyz/openbmc_project/network/eth0/ipv4/e9767624",
    #     "/xyz/openbmc_project/network/eth0/ipv4/31f4ce8b"
    #   ],

    @{ip_objects}=  Read Properties  ${XYZ_NETWORK_MANAGER}/eth0/ipv4/

    [Return]  @{ip_objects}

Validate IP on BMC
    [Documentation]  Validate IP on BMC.
    [Arguments]  ${ip_address}

    # Description of the argument(s):
    # ip_address  IP address of the system.
    # IP_AND_PREFIXES  Suite variable which has list of IP address and
    # prefix length values.

    Should Contain Match  ${IP_AND_PREFIXES}  ${ip_address}*
    ...  msg=IP address does not exist.

Validate Prefix Length On BMC
    [Documentation]  Validate prefix length on BMC.
    [Arguments]  ${prefix_length}

    # Description of the argument(s):
    # prefix_length  It indicates netmask, netmask value 255.255.255.0
    # is equal to prefix length 24.
    # IP_AND_PREFIXES  Suite variable which has list of IP address and
    # prefix length values.

    Should Contain Match  ${IP_AND_PREFIXES}  */${prefix_length}
    ...  msg=Prefix length does not exist.

Validate Route On BMC
    [Documentation]  Validate route.
    [Arguments]  ${gw_ip}

    # Description of the argument(s):
    # gw_ip  Gateway IP address.

    ${route_info}=  Get System Route Details
    Should Contain  ${route_info}  ${gw_ip}
    ...  msg=Gateway IP address not matching.
