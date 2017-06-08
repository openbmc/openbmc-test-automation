*** Settings ***
Documentation  Network testing including IP address, netmask and MAC.

Resource  ../lib/rest_client.robot
Resource  ../lib/utils.robot

Library  String
Library  SSHLibrary

Suite Setup  Network Setup

*** Test Cases ***

Get IP Address And Verify
    [Documentation]  Get IP address and verify.
    [Tags]  Get_IP_Address_And_Verify

    :FOR  ${ipv4_object}  IN  @{IPV4_OBJECTS}
    \  ${ipv4_addr}=  Read Attribute  ${ipv4_object}  Address
    \  Validate IP Address  ${ipv4_addr}

Get Prefix Length And Verify
    [Documentation]  Get prefix length and verify.
    [Tags]  Get_Prefix_Length_And_Verify

    :FOR  ${ipv4_object}  IN  @{IPV4_OBJECTS}
    \  ${prefix_length}=  Read Attribute  ${ipv4_object}  PrefixLength
    \  Validate Prefix Length  ${prefix_length}

Get GW Address And Verify
    [Documentation]  Get gateway address and verify.
    [Tags]  Get_GW_Address_And_Verify

    :FOR  ${ipv4_object}  IN  @{ipv4_objects}
    \  ${gw_ip}=  Read Attribute  ${ipv4_object}  Gateway
    \  Validate Route  ${gw_ip}

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

    @{ip_objects}=  Read Properties  ${XYZ_NETWORK_MANAGER}/eth0/ipv4/

    [Return]  @{ip_objects}

Validate IP Address
    [Documentation]  Validate IP and Netmask.
    [Arguments]  ${ip_address}

    # Description of the argument(s):
    # ip_address  IP address of the system.

    Should Contain Match  ${IP_AND_PREFIXES}  ${ip_address}*
    ...  msg=IP address does not exist.

Validate Prefix Length
    [Documentation]  Validate prefix length.
    [Arguments]  ${prefix_length}

    # Description of the argument(s):
    # prefix_length  It indicates netmask, netmask value 255.255.255.0
    # is equal to prefix length 24.

    Should Contain Match  ${IP_AND_PREFIXES}  */${prefix_length}
    ...  msg=Prefix length does not exist.

Validate Route
    [Documentation]  Validate route.
    [Arguments]  ${gw_ip}

    # Description of the argument(s):
    # gw_ip  Gateway IP address.

    ${route_info}=  Get System Route details
    Should Contain  ${route_info}  ${gw_ip}
    ...  msg=GW IP address not matching.
