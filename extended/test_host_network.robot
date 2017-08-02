*** Settings ***

Documentation       Test setting network address of host OS.

Resource            ../lib/rest_client.robot
Resource            ../lib/ipmi_client.robot
Resource            ../lib/utils.robot
Resource            ../lib/openbmc_ffdc.robot
Library             ../lib/utilities.py

Test Setup          Open Connection And Log In
Test Teardown       Post Test Execution


*** Variables ***
${SET_ADDR_PREFIX}  0x00 0x08 0x61 0x80 0x21 0x70 0x62 0x21 0x00 0x01 0x06 0x04
${STATIC}           0x00 0x01                       #equivalent address type 1
${DHCP}             0x00 0x00                       #equivalent address type 0
${CLEAR_ADDR}       0x00 0x08 0x61 0x80 0x00 0x00 0x00 0x00


*** Test Cases ***

Set Static Host Network Address Via IPMI
    [Documentation]  Set static host network address via IPMI and verify
    ...  with REST.
    [Tags]  Set_Static_Host_Network_Address_Via_IPMI

    ${ip_address}=  utilities.random_ip
    ${gateway_ip}=  utilities.random_ip
    ${mac_address}=  utilities.random_mac
    ${prefix_length}=  Evaluate  random.randint(0, 32)  modules=random

    ${mac_address_hex}=  Mac Address To Hex String  ${mac_address}
    ${ip_address_hex}=  IP Address To Hex String  ${ip_address}
    ${gateway_hex}=  IP Address To Hex String  ${gateway_ip}
    ${prefix_hex}=  Convert To Hex  ${prefix_length}  prefix=0x  lowercase=yes

    ${ipmi_raw_cmd}=  Catenate  SEPARATOR=
    ...  ${SET_ADDR_PREFIX}${SPACE}${mac_address_hex}${SPACE}${STATIC}${SPACE}
    ...  ${ip_address_hex}${SPACE}${prefix_hex}${SPACE}${gateway_hex}

    Run IPMI command   ${ipmi_raw_cmd}

    ${origin}=  Read Attribute  ${XYZ_NETWORK_MANAGER}host0/intf/addr  Origin 
    ${address}=  Read Attribute  ${XYZ_NETWORK_MANAGER}host0/intf/addr  Address
    ${gateway}=  Read Attribute  ${XYZ_NETWORK_MANAGER}host0/intf/addr  Gateway
    ${prefix}=  Read Attribute
    ...  ${XYZ_NETWORK_MANAGER}host0/intf/addr  PrefixLength
    ${mac}=  Read Attribute  ${XYZ_NETWORK_MANAGER}host0/intf  MACAddress

    Should Contain  ${origin}  Static
    Should Be Equal  ${address}  ${ip_address}
    Should Be Equal  ${gateway}  ${gateway_ip}
    Should Be Equal  ${prefix}  ${prefix_length}
    Should Be Equal  ${mac}  ${mac_address}


Set DHCP Host Address Via IPMI
    [Documentation]   Set dhcp host network address via IPMI and verify
    ...  with REST.
    [Tags]  Set_DHCP_Host_Address_Via_IPMI

    ${mac_address}=  utilities.random_mac
    ${mac_address_hex}=  Mac Address To Hex String  ${mac_address}

    ${ipmi_raw_cmd}=  Catenate  SEPARATOR=
    ...    ${SET_ADDR_PREFIX}${SPACE}${mac_address_hex}${SPACE}${DHCP}
    Run IPMI command   ${ipmi_raw_cmd}

    ${origin}=  Read Attribute  ${XYZ_NETWORK_MANAGER}host0/intf/addr  Origin
    ${mac}=  Read Attribute  ${XYZ_NETWORK_MANAGER}host0/intf  MACAddress
    Should Contain  ${origin}  DHCP
    Should Be Equal  ${mac}  ${mac_address}


*** Keywords ***

Post Test Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Run IPMI command  ${CLEAR_ADDR}
    Close All Connections
