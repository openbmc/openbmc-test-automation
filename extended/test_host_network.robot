*** Settings ***

Documentation   This testsuite is for testing network setting
...             of host OS.

Resource            ../lib/rest_client.robot
Resource            ../lib/ipmi_client.robot
Resource            ../lib/utils.robot
Resource            ../lib/openbmc_ffdc.robot
Library             ../lib/utilities.py

Suite Setup         Open Connection And Log In
Suite Teardown      Close All Connections

Test Teardown       Post Test Execution

Force Tags  Host_Network

*** Variables ***
${SET_ADDR_PREFIX}  0x00 0x08 0x61 0x80 0x21 0x70 0x62 0x21 0x00 0x01 0x06 0x04
${STATIC}           0x00 0x01                       #equivalent address type 1
${DHCP}             0x00 0x00                       #equivalent address type 0
${CLEAR_ADDR}       0x00 0x08 0x61 0x80 0x00 0x00 0x00 0x00
${INVALID_MAC}      f4:52:14
${INVALID_IP}       10.6.6.256

*** Test Cases ***


Set Static Address With IPMI
    [Documentation]   This testcase is to set static address for host's network
    ...               setting using IPMI. Later verify using REST that it is
    ...               set correctly.
    [Tags]  Set_Static_Address_With_IPMI

    ${ip_address}=  utilities.random_ip
    ${gateway}=  utilities.random_ip
    ${mac_address}=  utilities.random_mac
    ${subnet}=  Evaluate    random.randint(0, 32)    modules=random

    ${mac_address_hex}=  Mac Address To Hex String    ${mac_address}
    ${ip_address_hex}=  IP Address To Hex String      ${ip_address}
    ${gateway_hex}=  IP Address To Hex String      ${gateway}
    ${subnet_hex}=  Convert To Hex    ${subnet}    prefix=0x
    ...    lowercase=yes

    ${ipmi_raw_cmd}=  Catenate  SEPARATOR=
    ...    ${SET_ADDR_PREFIX}${SPACE}${mac_address_hex}${SPACE}${STATIC}${SPACE}
    ...    ${ip_address_hex}${SPACE}${subnet_hex}${SPACE}${gateway_hex}

    Run IPMI command   ${ipmi_raw_cmd}

    ${origin}=  Read Attribute  /xyz/openbmc_project/network/host0/intf/addr  Origin 
    ${address}=  Read Attribute  /xyz/openbmc_project/network/host0/intf/addr  Address
    ${gateway_ip}=  Read Attribute  /xyz/openbmc_project/network/host0/intf/addr  Gateway
    ${prefix_lenght}=  Read Attribute  /xyz/openbmc_project/network/host0/intf/addr  PrefixLength

    Should Contain  ${origin}  Static
    Should Be Equal  ${ip_address}  ${address}
    Should Be Equal  ${gateway}  ${gateway_ip}
    Should Be Equal  ${subnet}  ${prefix_lenght}


Set DHCP Address With IPMI
    [Documentation]   This testcase is to set dhcp address for host's network
    ...               setting using IPMI. Later verify using REST that it is
    ...               set correctly.
    [Tags]  Set_DHCP_Address_With_IPMI

    ${mac_address}=  utilities.random_mac
    ${mac_address_hex}=  Mac Address To Hex String    ${mac_address}

    ${ipmi_raw_cmd}=  Catenate  SEPARATOR=
    ...    ${SET_ADDR_PREFIX}${SPACE}${mac_address_hex}${SPACE}${DHCP}
    Run IPMI command   ${ipmi_raw_cmd}

    ${origin}=  Read Attribute  /xyz/openbmc_project/network/host0/intf/addr  Origin
    Should Contain  ${origin}  DHCP


Clear Address With IPMI
    [Documentation]   This testcase is to clear host's network setting
    ...               using IPMI. Later verify using REST that it is
    ...               cleared.
    [Tags]  Clear_Address_With_IPMI

    Run IPMI command   ${CLEAR_ADDR}

    ${origin}=  Read Attribute  /xyz/openbmc_project/network/host0/intf/addr  Origin
    ${address}=  Read Attribute  /xyz/openbmc_project/network/host0/intf/addr  Address
    ${gateway_ip}=  Read Attribute  /xyz/openbmc_project/network/host0/intf/addr  Gateway
    ${prefix_lenght}=  Read Attribute  /xyz/openbmc_project/network/host0/intf/addr  PrefixLength

    Should Be Empty  ${address}
    Should Be Empty  ${gateway_ip}
    Should Be Equal  '${prefix_lenght}'  '0'
    Should Contain  ${origin}  DHCP


Set Invalid Address With IPMI
    [Documentation]   This testcase is to verify that invalid ip address for
    ...               host's network setting can not be set by IPMI.
    [Tags]  Set_Invalid_Address_With_IPMI

    ${gateway}=  utilities.random_ip
    ${subnet}=  Evaluate    random.randint(0, 32)    modules=random
    ${mac_address}=  utilities.random_mac

    ${ip_address_hex}=  IP Address To Hex String    ${INVALID_IP}
    ${gateway_hex}=  IP Address To Hex String      ${gateway}
    ${mac_address_hex}=  Mac Address To Hex String  ${mac_address}
    ${subnet_hex}=  Convert To Hex    ${subnet}    prefix=0x
    ...    lowercase=yes

    ${invalid_ipmi_cmd}=  Catenate  SEPARATOR=
    ...    ${SET_ADDR_PREFIX}${SPACE}${mac_address_hex}${SPACE}${STATIC}${SPACE}
    ...    ${ip_address_hex}${SPACE}${subnet_hex}${SPACE}${gateway_hex}
    ${resp}=  Run Keyword And Expect Error  *  Run IPMI command  ${invalid_ipmi_cmd}
    Should Contain  ${resp}  invalid

    ${origin}=  Read Attribute  /xyz/openbmc_project/network/host0/intf/addr  Origin
    ${address}=  Read Attribute  /xyz/openbmc_project/network/host0/intf/addr  Address
    ${gateway_ip}=  Read Attribute  /xyz/openbmc_project/network/host0/intf/addr  Gateway
    ${prefix_lenght}=  Read Attribute  /xyz/openbmc_project/network/host0/intf/addr  PrefixLength

    Should Not Contain  ${origin}  Static
    Should Not Be Equal  ${address}  ${INVALID_IP}
    Should Not Be Equal  ${gateway_ip}  ${gateway}
    Should Not Be Equal  ${prefix_lenght}  ${subnet}


*** Keywords ***

Post Test Execution
    [Documentation]  Perform operations after test execution. Captures FFDC
    ...              in case of test case failure and sets defaults values
    ...              for host's network settings.

    FFDC On Test Case Fail

    Run IPMI command   ${CLEAR_ADDR}
