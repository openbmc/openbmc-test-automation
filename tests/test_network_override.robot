*** Settings ***

Documentation   This testsuite is for testing network setting override.

Resource           ../lib/rest_client.robot
Resource           ../lib/ipmi_client.robot
Resource           ../lib/utils.robot
Resource           ../lib/openbmc_ffdc.robot

Suite Setup        Open Connection And Log In
Suite Teardown     Close All Connections

Test Teardown      Log FFDC

*** Variables ***
${PREFIX}          0x00 0x08 0x61 0x80 0x21 0x70 0x62 0x21 0x00 0x01 0x06 0x04
${MAC}             0xf4 0x52 0x14 0xf3 0x12 0xdf   #equivalent mac f4:52:14:f3:12:df
${STATIC}          0x00 0x01                       #equivalent address type 1
${DHCP}            0x00 0x00                       #equivalent address type 0
${IP_ADDRESS}      0x0a 0x3d 0xa1 0x42             #equivalent ip 10.61.161.66
${SUBNET_MASK}     0x10                            #equivalent prefix 16
${GATEWAY_ADDR}    0x0a 0x3d 0x2 0x1               #equivalent gateway 10.61.2.1
${INVALID_MAC}     0xf4 0x52 0x14                  #equivalent mac address f4:52:14
${CLEAR_ADDR}      0x00 0x08 0x61 0x80 0x00 0x00 0x00 0x00

*** Test Cases ***

Set static for network setting using REST
    [Documentation]   This testcase is to set static address for network
    ...               setting using REST and then verify using it.\n

    Set Network Override Setting   ipaddress=7.7.7.8,prefix=16,gateway=2.2.2.2,mac=11:22:33:44:55:66,addr_type=1

    ${setting} =   Read Attribute  /org/openbmc/settings/host0    network_config
    Should Contain    ${setting}    ipaddress=7.7.7.8,prefix=16,gateway=2.2.2.2,mac=11:22:33:44:55:66,addr_type=1

Set dhcp for network setting override using REST
    [Documentation]   This testcase is to set dhcp address for network setting
    ...               override using REST and then verify using it.\n

    Set Network Override Setting   ipaddress=,prefix=,gateway=,mac=11:22:33:44:55:66,addr_type=0
    #Set Network Override Setting   ipaddress=7.7.7.7,prefix=16,gateway=2.2.2.2,mac=11:22:33:44:55:66,addr_type=0

    ${setting} =   Read Attribute  /org/openbmc/settings/host0    network_config
    Should Contain    ${setting}    addr_type=0

Clear network override setting using REST
    [Documentation]   This testcase is to clear network override
    ...               setting using REST and then verify using it.\n

    Set Network Override Setting   ipaddress=,prefix=,gateway=,mac=,addr_type=

    ${setting} =   Read Attribute  /org/openbmc/settings/host0    network_config
    Should Contain    ${setting}    ipaddress=,prefix=,gateway=,mac=,addr_type=

Set static for network setting using ipmi
    [Documentation]   This testcase is to set static address for network override
    ...               setting using ipmi and then verify using REST.\n

    ${ipmi_raw_cmd} =    Catenate  SEPARATOR=
    ...    ${PREFIX}${SPACE}${MAC}${SPACE}${STATIC}${SPACE}${IP_ADDRESS}
    ...    ${SPACE}${SUBNET_MASK}${SPACE}${GATEWAY_ADDR}
    Run IPMI command   ${ipmi_raw_cmd}

    ${setting} =   Read Attribute  /org/openbmc/settings/host0    network_config
    Should Be Equal    ${setting}    ipaddress=10.61.161.66,prefix=16,gateway=10.61.2.1,mac=f4:52:14:f3:12:df,addr_type=1

Set dhcp for network setting override using ipmi
    [Documentation]   This testcase is to set dhcp address for network override
    ...               setting using ipmi and then verify using REST.\n

    ${ipmi_raw_cmd} =    Catenate  SEPARATOR=
    ...    ${PREFIX}${SPACE}${MAC}${SPACE}${DHCP}
    Run IPMI command   ${ipmi_raw_cmd}

    ${setting} =   Read Attribute  /org/openbmc/settings/host0    network_config
    Should Contain    ${setting}    addr_type=0

Clear network setting override using ipmi
    [Documentation]   This testcase is to clear network override setting
    ...               using ipmi and then verify using REST.\n

    Run IPMI command   ${CLEAR_ADDR}

    ${setting} =   Read Attribute  /org/openbmc/settings/host0    network_config
    Should Contain    ${setting}    ipaddress=,prefix=,gateway=,mac=,addr_type=

Set invalid address using REST
    [Documentation]   This testcase is to verify that proper error message is prompted
    ...               by REST when invalid address to provided to network override.

    ${resp} =   Set Network Override Setting   ipaddress=7.7.7.7,prefix=16,gateway=2.2.2.2,mac=11:22:33,addr_type=1
    Should Be Equal    ${resp}    error

Set invalid address using IPMItool
    [Documentation]   This testcase is to verify that invalid network override setting is not set
    ...               by ipmi.

    ${ipmi_raw_cmd} =    Catenate  SEPARATOR=
    ...    ${PREFIX}${SPACE}${INVALID_MAC}${SPACE}${STATIC}${SPACE}${IP_ADDRESS}
    ...    ${SPACE}${SUBNET_MASK}${SPACE}${GATEWAY_ADDR}
    Run IPMI command   ${ipmi_raw_cmd}

    ${setting} =   Read Attribute  /org/openbmc/settings/host0    network_config
    Should Not Be Equal    ${setting}    ipaddress=10.61.161.66,prefix=16,gateway=10.61.2.1,mac=f4:52:14,addr_type=1

*** Keywords ***

Set Network Override Setting
    [Arguments]    ${args}
    ${network_override} =   Set Variable   ${args}
    ${valueDict} =   create dictionary   data=${network_override}
    ${resp} =   OpenBMC Put Request    /org/openbmc/settings/host0/attr/network_config    data=${valueDict}
    ${jsondata} =    to json    ${resp.content}
    [return]    ${jsondata['status']}
