*** Settings ***

Documentation   This testsuite is for testing network setting override.

Resource            ../lib/rest_client.robot
Resource            ../lib/ipmi_client.robot
Resource            ../lib/utils.robot
Resource            ../lib/openbmc_ffdc.robot
Library             ../lib/utilities.py

Suite Setup         Open Connection And Log In
Suite Teardown      Close All Connections

Test Teardown       FFDC On Test Case Fail

*** Variables ***
${SET_ADDR_PREFIX}  0x00 0x08 0x61 0x80 0x21 0x70 0x62 0x21 0x00 0x01 0x06 0x04
${STATIC}           0x00 0x01                       #equivalent address type 1
${DHCP}             0x00 0x00                       #equivalent address type 0
${CLEAR_ADDR}       0x00 0x08 0x61 0x80 0x00 0x00 0x00 0x00
${INVALID_MAC}      f4:52:14

*** Test Cases ***

Set Static Address With REST
    [Documentation]   This testcase is to set static address for network
    ...               setting override using REST. Later verify using REST
    ...               that it is set correctly.
    [Tags]  Set_Static_Address_With_REST

    ${ip_address}=  utilities.random_ip
    ${gateway}=  utilities.random_ip
    ${mac_address}=  utilities.random_mac
    ${subnet}=  Evaluate    random.randint(0, 32)    modules=random

    ${settings}=  Catenate   SEPARATOR=
    ...    ipaddress=${ip_address},prefix=${subnet},
    ...    gateway=${gateway},mac=${mac_address},addr_type=1

    Set Network Override Setting   ${settings}

    ${resp}=  Read Attribute  /org/openbmc/settings/host0    network_config
    Should Be Equal    ${resp}   ${settings}


Set DHCP Address With REST
    [Documentation]   This testcase is to set dhcp address for network setting
    ...               override using REST. Later verify using REST that it
    ...               is set correctly.
    [Tags]  Set_DHCP_Address_With_REST

    ${mac_address}=  utilities.random_mac

    ${settings}=  Catenate   SEPARATOR=
    ...    ipaddress=,prefix=,gateway=,mac=${mac_address},addr_type=0

    Set Network Override Setting   ${settings}

    ${resp}=  Read Attribute  /org/openbmc/settings/host0    network_config
    Should Be Equal    ${resp}    ${settings}


Set Static Address With IPMI
    [Documentation]   This testcase is to set static address for network setting
    ...               override using IPMI. Later verify using REST that it is
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

    ${resp}=  Read Attribute  /org/openbmc/settings/host0    network_config

    ${settings}=  Catenate   SEPARATOR=
    ...    ipaddress=${ip_address},prefix=${subnet},gateway=${gateway},
    ...    mac=${mac_address},addr_type=1

    Should Be Equal    ${resp}    ${settings}


Set DHCP Address With IPMI
    [Documentation]   This testcase is to set dhcp address for network setting
    ...               override using IPMI. Later verify using REST that it is
    ...               set correctly.
    [Tags]  Set_DHCP_Address_With_IPMI

    ${mac_address}=  utilities.random_mac
    ${mac_address_hex}=  Mac Address To Hex String    ${mac_address}

    ${ipmi_raw_cmd}=  Catenate  SEPARATOR=
    ...    ${SET_ADDR_PREFIX}${SPACE}${mac_address_hex}${SPACE}${DHCP}
    Run IPMI command   ${ipmi_raw_cmd}

    ${resp}=  Read Attribute  /org/openbmc/settings/host0    network_config
    Should Contain    ${resp}    addr_type=0


Clear Address With IPMI
    [Documentation]   This testcase is to clear network setting override
    ...               using IPMI. Later verify using REST that it is
    ...               cleared.
    [Tags]  Clear_Address_With_IPMI

    Run IPMI command   ${CLEAR_ADDR}

    ${resp}=  Read Attribute  /org/openbmc/settings/host0    network_config
    Should Be Equal    ${resp}    ipaddress=,prefix=,gateway=,mac=,addr_type=


Set Invalid Address With REST
    [Documentation]   This testcase is to verify that proper error message is
    ...               prompted by REST with invalid mac address for
    ...               network setting override.
    [Tags]  Set_Invalid_Address_With_REST

    ${ip_address}=  utilities.random_ip
    ${gateway}=  utilities.random_ip
    ${subnet}=  Evaluate    random.randint(0, 32)    modules=random

    ${invalid_settings}=  Catenate   SEPARATOR=
    ...    ipaddress=${ip_address},prefix=${subnet},gateway=${gateway},
    ...    mac=${INVALID_MAC},addr_type=1

    ${resp}=  Set Network Override Setting   ${invalid_settings}
    Should Be Equal    ${resp}    error


Set Invalid Address With IPMI
    [Documentation]   This testcase is to verify that invalid mac address for
    ...               network setting override can not be set by IPMI.
    [Tags]  Set_Invalid_Address_With_IPMI

    ${ip_address}=  utilities.random_ip
    ${gateway}=  utilities.random_ip
    ${subnet}=  Evaluate    random.randint(0, 32)    modules=random

    ${ip_address_hex}=  IP Address To Hex String      ${ip_address}
    ${gateway_hex}=  IP Address To Hex String      ${gateway}
    ${invalid_mac_hex}=  Mac Address To Hex String    ${INVALID_MAC}
    ${subnet_hex}=  Convert To Hex    ${subnet}    prefix=0x
    ...    lowercase=yes

    ${ipmi_raw_cmd}=  Catenate  SEPARATOR=
    ...    ${SET_ADDR_PREFIX}${SPACE}${invalid_mac_hex}${SPACE}${STATIC}${SPACE}
    ...    ${ip_address_hex}${SPACE}${subnet_hex}${SPACE}${gateway_hex}
    Run IPMI command   ${ipmi_raw_cmd}

    ${invalid_settings}=  Catenate   SEPARATOR=
    ...    ipaddress=${ip_address},prefix=${subnet},gateway=${gateway},
    ...    mac=${INVALID_MAC},addr_type=1

    ${resp}=  Read Attribute  /org/openbmc/settings/host0    network_config
    Should Not Be Equal    ${resp}    ${invalid_settings}


*** Keywords ***

Set Network Override Setting
    [Arguments]    ${args}
    ${network_override}=  Set Variable   ${args}
    ${valueDict}=  create dictionary   data=${network_override}
    ${resp}=   OpenBMC Put Request
    ...    /org/openbmc/settings/host0/attr/network_config    data=${valueDict}
    ${jsondata}=  to json    ${resp.content}
    [return]    ${jsondata['status']}
