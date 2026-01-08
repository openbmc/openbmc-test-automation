*** Settings ***
Documentation  Network interface IPv6 configuration connected to DHCP server
               ...   and verification tests.

Resource        ../../lib/bmc_redfish_resource.robot
Resource        ../../lib/openbmc_ffdc.robot
Resource        ../../lib/bmc_ipv6_utils.robot
Resource        ../../lib/bmc_network_utils.robot
Resource        ../../lib/protocol_setting_utils.robot

Library         Collections
Library         OperatingSystem
Library         Process
Suite Setup     Suite Setup Execution
Test Teardown   Test Teardown Execution

Test Tags       BMC_IPv6_Config

*** Variables ***
# Remote DHCP test bed server. Leave variables EMPTY if server is configured local
# to the test where it is running else if remote pass the server credentials
# -v SERVER_IPv6:xx.xx.xx.xx
# -v SERVER_USERNAME:root
# -v SERVER_PASSWORD:*********

${SERVER_USERNAME}      ${EMPTY}
${SERVER_PASSWORD}      ${EMPTY}
${SERVER_IPv6}          ${EMPTY}
${test_ipv4_addr}       10.7.7.7
${test_ipv4_addr1}      10.7.7.8
${test_ipv6_addr}       2001:db8:1:1:250:56ff:fe8a:668
${test_ipv6_addr1}      2001:db8:1:1:250:56ff:fe8a:669
${test_subnet_mask}     255.255.255.0

*** Test Cases ***

Get SLAAC And Static IPv6 Address And Verify Connectivity
    [Documentation]  Fetch the SLAAC and Static IPv6 address
    ...    and verify ping and SSH connection.
    [Tags]  Get_SLAAC_And_Static_IPv6_Address_And_Verify_Connectivity
    [Template]  Get IPv6 Address And Verify Connectivity

    # Address_type  channel_number
    SLAAC           ${1}
    Static          ${1}
    SLAAC           ${2}
    Static          ${2}


Enable SSH Protocol Via IPv6 And Verify
    [Documentation]  Enable SSH protocol via eth1 and verify.
    [Tags]  Enable_SSH_Protocol_Via_IPv6_And_Verify

    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=
    ...  Get Address Origin List And Address For Type  SLAAC  ${2}
    Connect BMC Using IPv6 Address  ${ipv6_slaac_addr}
    Set SSH Protocol Using IPv6 Session And Verify  ${True}
    Verify SSH Login And Commands Work
    Verify SSH Connection Via IPv6  ${ipv6_slaac_addr}


Disable SSH Protocol Via IPv6 And Verify
    [Documentation]  Disable SSH protocol via IPv6 and verify.
    [Tags]  Disable_SSH_Protocol_Via_IPv6_And_Verify
    [Teardown]  Set SSH Protocol Using IPv6 Session And Verify  ${True}

    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=
    ...  Get Address Origin List And Address For Type  SLAAC  ${2}
    Connect BMC Using IPv6 Address  ${ipv6_slaac_addr}

    Set SSH Protocol Using IPv6 Session And Verify  ${False}

    # Verify SSH Login And Commands Work.
    ${status}=  Run Keyword And Return Status
    ...    Verify SSH Connection Via IPv6  ${ipv6_slaac_addr}
    Should Be Equal As Strings  ${status}  False
    ...  msg=SSH Login and commands are working after disabling SSH via IPv6.

    # Verify SSH Connection Via IPv6.
    ${status}=  Run Keyword And Return Status
    ...  Verify SSH Login And Commands Work
    Should Be Equal As Strings  ${status}  False
    ...  msg=SSH Login and commands are working after disabling SSH.


Verify BMC IPv4 And IPv6 Addresses Accessible Via SSH
    [Documentation]  Verify BMC IPv4 and IPv6 addresses accessible via SSH.
    [Tags]  Verify_BMC_IPv4_And_IPv6_Addresses_Accessible_Via_SSH

    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  host=${OPENBMC_HOST}
    Verify SSH Connection Via IPv6


Verify IPv4 And IPv6 Access Concurrently Via Redfish
    [Documentation]  Verify both interfaces access conurrently via redfish.
    [Tags]  Verify_IPv4_And_IPv6_Access_Concurrently_Via_Redfish

    ${dict}=  Execute Process Multi Keyword  ${2}
    ...  Redfish.patch ${REDFISH_NW_ETH_IFACE}eth0 body={'DHCPv4':{'UseDNSServers':${True}}}
    ...  RedfishIPv6.patch ${REDFISH_NW_ETH_IFACE}eth0 body={'DHCPv4':{'UseDNSServers':${True}}}
    Dictionary Should Not Contain Value  ${dict}  False
    ...  msg=One or more operations has failed.
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}eth0
    ${resp1}=  Redfish1.Get  ${REDFISH_NW_ETH_IFACE}eth0
    Should Be Equal  ${resp.dict["DHCPv4"]['UseDNSServers']}  ${True}
    Should Be Equal  ${resp1.dict["DHCPv4"]['UseDNSServers']}  ${True}


Configure Static IPv6 From SLAAC And Static IPv6 Address
    [Documentation]  Configure static IPv6 by logging in from SLAAC and static IPv6 address.
    [Tags]  Configure_Static_IPv6_From_SLAAC_And_Static_IPv6_Address
    [Template]  Configure Static IPv6 Address From Different IPv6 Assigning Methods

    # Address_type  channel_number
    SLAAC           ${1}
    Static          ${1}
    SLAAC           ${2}
    Static          ${2}


Verify DHCP Toggle On Eth1 Using IPv6
    [Documentation]  Disable and Enable DHCP on Eth1 by logging in
    ...    from SLAAC and static IPv6 address from both interfaces and verify.
    [Tags]  Verify_DHCP_Toggle_On_Eth1_Using_IPv6
    [Template]  Disable Or Enable DHCP On Eth1 From IPv6 Address

    # Address_type  channel_number  DHCP_state.
    SLAAC           ${1}            False
    SLAAC           ${2}            False
    Static          ${1}            False
    Static          ${2}            False
    SLAAC           ${1}            True
    SLAAC           ${2}            True
    Static          ${1}            True
    Static          ${2}            True


Configure IPv4 Address From IPv6 Address And Verify
    [Documentation]  Configure IPv4 address from IPv6 address and verify configuration.
    [Tags]  Configure_IPv4_Address_From_IPv6_Address_And_Verify
    [Template]  Configure IPv4 Address From IPv6 And Verify
    [Teardown]  Delete IP Address  ${test_ipv4_addr}  version=IPv6

    SLAAC      ${1}  ${test_ipv4_addr}
    SLAAC      ${2}  ${test_ipv4_addr}
    Static     ${1}  ${test_ipv4_addr}
    Static     ${2}  ${test_ipv4_addr}


Modify IPv6 Address From IPv6 Address And Verify
    [Documentation]  Modify IPv6 Address From IPv6 Address And Verify.
    [Tags]  Modify_IPv6_Address_From_IPv6_Address_And_Verify
    [Template]  Modify IPv6 Address From IPv6 Address

    Static  ${1}  ${test_ipv4_addr}
    Static  ${2}  ${test_ipv4_addr}
    SLAAC   ${1}  ${test_ipv6_addr}
    SLAAC   ${2}  ${test_ipv4_addr}


Modify IPv4 Address From IPv6 Address And Verify
    [Documentation]  Modify IPv4 Address From IPv6 Address And Verify.
    [Tags]  Modify_IPv4_Address_From_IPv6_Address_And_Verify
    [Template]  Modify IPv4 Address From IPv6 Address

    Static  ${1}  ${test_ipv4_addr}
    Static  ${2}  ${test_ipv4_addr}
    SLAAC   ${1}  ${test_ipv4_addr}
    SLAAC   ${2}  ${test_ipv4_addr}


Verify IPv6 Addresses Can Be Configured And IPs Are Reachable
    [Documentation]  Verify IPv6 addresses are configured properly from different
    ...    IPv6 modes and IPs are reachable.
    [Tags]  Verify_IPv6_Addresses_Can_Be_Configured_And_IPs_Are_Reachable
    [Template]  Configure IPv6 Address In Different IPv6 Modes And Verify Ping

    # Address_type  channel_number
    SLAAC           ${1}
    Static          ${1}


Verify Static IPv4 Functionality In Presence Of Static IPv6
    [Documentation]  Verify static IPv4 functions properly in presence of static IPv6
    ...    by logging in from static/slaac IPv6 address.
    [Tags]  Verify_Static_IPv4_Functionality_In_Presence_Of_Static_IPv6
    [Setup]  Run Keywords
    ...  Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}
    ...  AND  Configure IPv6 Address On BMC  ${test_ipv6_addr1}  ${test_prefix_length}  ${None}  ${2}
    [Template]  Verify Static IPv4 Functionality In Presence Of IPv6 Address

    # Address_type  channel_number
    Static          ${1}
    Static          ${2}
    SLAAC           ${1}
    SLAAC           ${2}


Delete Static IPv4 On Eth0 Using IPv6 And Verify
    [Documentation]  Delete static IPv4 address by logging in
    ...    from SLAAC and static IPv6 address on eth0 and verify.
    [Tags]  Delete_Static_IPv4_On_Eth0_Using_IPv6_And_Verify
    [Setup]    Run Keywords
    ...  Add IP Address  ${test_ipv4_addr}  ${test_subnet_mask}  ${test_gateway}
    ...  AND  Add IP Address  ${test_ipv4_addr1}  ${test_subnet_mask}  ${test_gateway}
    [Template]  Delete IPv4 Address From IPv6 And Verify

    Static     ${1}  ${test_ipv4_addr}
    SLAAC      ${1}  ${test_ipv4_addr1}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup execution.

    Redfish.Login
    ${active_channel_config}=  Get Active Channel Config
    Set Suite Variable  ${active_channel_config}
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}
    Set Suite variable  ${ethernet_interface}
    ${test_gateway}=  Get BMC Default Gateway
    Set Suite Variable  ${test_gateway}


Test Teardown Execution
    [Documentation]  Test teardown execution.

    FFDC On Test Case Fail
    Redfish.Logout
    RedfishIPv6.Logout


Wait For IPv6 Host To Ping
    [Documentation]  Verify that the IPv6 host responds successfully to ping.
    [Arguments]  ${host}  ${timeout}=${OPENBMC_REBOOT_TIMEOUT}sec
    ...          ${interval}=5 sec  ${expected_rc}=${0}
    # Description of argument(s):
    # host         The IPv6 address of the host to ping.
    # timeout      Maximum time to wait for the host to respond to ping.
    # interval     Time to wait between ping attempts.
    # expected_rc  Expected return code of ping command.
    Wait Until Keyword Succeeds  ${timeout}  ${interval}  Ping Host Over IPv6  ${host}  ${expected_rc}


Ping Host Over IPv6
    [Documentation]  Ping6 the given host.
    [Arguments]     ${host}  ${expected_rc}=${0}
    # Description of argument(s):
    # host           IPv6 address of the host to ping.
    # expected_rc    Expected return code of ping command.
    Should Not Be Empty    ${host}   msg=No host provided.
    ${rc}   ${output}=     Run and return RC and Output    ping6 -c 4 ${host}
    Log     RC: ${rc}\nOutput:\n${output}
    Should Be Equal     ${rc}   ${expected_rc}


Check IPv6 Connectivity
    [Documentation]  Check ping6 status and verify.
    [Arguments]  ${OPENBMC_HOST_IPv6}

    # Description of argument(s):
    # OPENBMC_HOST_IPv6   IPv6 address to check connectivity.

    Open Connection And Log In  ${SERVER_USERNAME}  ${SERVER_PASSWORD}  host=${SERVER_IPv6}
    Wait For IPv6 Host To Ping  ${OPENBMC_HOST_IPv6}  30 secs


Verify SSH Connection Via IPv6
    [Documentation]  Verify connectivity to the IPv6 host via SSH.
    [Arguments]  ${OPENBMC_HOST_IPv6}

    # Description of argument(s):
    # OPENBMC_HOST_IPv6   IPv6 address to check connectivity.

    IF  '${SERVER_USERNAME}' == '${EMPTY}'
        SSHLibrary.Open Connection  ${OPENBMC_HOST_IPv6}
        SSHLibrary.Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ELSE
        Open Connection And Log In  ${SERVER_USERNAME}  ${SERVER_PASSWORD}  host=${SERVER_IPv6}  alias=IPv6Conn
        SSHLibrary.Open Connection  ${OPENBMC_HOST_IPv6}
        SSHLibrary.Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  jumphost_index_or_alias=IPv6Conn
    END


Set SSH Protocol Using IPv6 Session And Verify
    [Documentation]  Enable or disable SSH protocol via IPv6 and verify.
    [Arguments]  ${enable_value}=${True}

    # Description of argument(s}:
    # enable_value  Enable or disable SSH, e.g. (true, false).

    ${ssh_state}=  Create Dictionary  ProtocolEnabled=${enable_value}
    ${data}=  Create Dictionary  SSH=${ssh_state}

    RedfishIPv6.Login
    RedfishIPv6.Patch  ${REDFISH_NW_PROTOCOL_URI}  body=&{data}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]

    # Wait for new values to take effect.
    Sleep  30s

    # Verify SSH Protocol State Via IPv6
    ${resp}=  RedfishIPv6.Get  ${REDFISH_NW_PROTOCOL_URI}
    Should Be Equal As Strings  ${resp.dict['SSH']['ProtocolEnabled']}  ${enable_value}
    ...  msg=Protocol states are not matching.


Connect BMC Using IPv6 Address
    [Documentation]  Import bmc_redfish library with IPv6 configuration.
    [Arguments]  ${OPENBMC_HOST_IPv6}

    # Description of argument(s):
    # OPENBMC_HOST_IPv6  IPv6 address of the BMC.

    Import Library  ${CURDIR}/../../lib/bmc_redfish.py  https://[${OPENBMC_HOST_IPv6}]:${HTTPS_PORT}
    ...             ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  AS  RedfishIPv6


Get IPv6 Address And Verify Connectivity
    [Documentation]  Get IPv6 address and verify connectivity.
    [Arguments]  ${ipv6_adress_type}  ${channel_number}

    # Description of argument(s):
    # ipv6_adress_type   Type of IPv6 address(slaac/static).
    # channel_number     Ethernet channel number, 1(eth0) or 2(eth1).

    @{ipv6_addressorigin_list}  ${ipv6_addr}=
    ...  Get Address Origin List And Address For Type  ${ipv6_adress_type}  ${channel_number}
    IF  '${SERVER_USERNAME}' != '${EMPTY}'
        Check IPv6 Connectivity  ${ipv6_addr}
    ELSE
        Wait For IPv6 Host To Ping  ${ipv6_addr}
    END
    Verify SSH Connection Via IPv6  ${ipv6_addr}

Disable Or Enable DHCP On Eth1 From IPv6 Address
    [Documentation]  Disable Or Enable DHCP On Eth1 From IPv6 Address
    [Arguments]  ${ipv6_adress_type}  ${channel_number}  ${DHCP_state}

    # Description of argument(s):
    # ipv6_adress_type   Type of IPv6 address(slaac/static).
    # channel_number     Ethernet channel number, 1(eth0) or 2(eth1).
    # DHCP_state  Enable or Disable DHCP

    @{ipv6_addressorigin_list}  ${ipv6_addr}=
    ...  Get Address Origin List And Address For Type  ${ipv6_adress_type}  ${channel_number}
    Connect BMC Using IPv6 Address  ${ipv6_addr}
    RedfishIPv6.Login
    Set DHCPEnabled To Enable Or Disable  ${DHCP_state}  eth1  Version=IPv6
    ${DHCPEnabled}=  Get IPv4 DHCP Enabled Status  ${2}
    IF  '${DHCP_state}' == 'True'
        Should Be Equal  ${DHCPEnabled}  ${True}
    ELSE
        Should Be Equal  ${DHCPEnabled}  ${False}
    END
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}


Configure IPv4 Address From IPv6 And Verify
    [Documentation]  Configure IPv4 address from IPv6 and verify.
    [Arguments]   ${ipv6_adress_type}  ${channel_number}  ${test_ipv4_addr}

    # Description of argument(s):
    # ipv6_adress_type   Type of IPv6 address(slaac/static).
    # channel_number     Ethernet channel number, 1(eth0) or 2(eth1).
    # test_ipv4_addr     IPv4 address to add.

    @{ipv6_addressorigin_list}  ${ipv6_addr}=
    ...  Get Address Origin List And Address For Type  ${ipv6_adress_type}  ${channel_number}
    Connect BMC Using IPv6 Address  ${ipv6_addr}
    RedfishIPv6.Login
    ${test_gateway}=  Get BMC Default Gateway
    Add IP Address  ${test_ipv4_addr}  ${test_subnet_mask}  ${test_gateway}  version=IPv6


Configure Static IPv6 Address From Different IPv6 Assigning Methods
    [Documentation]  Configure static IPv6 on both interfaces by logging
    ...    in from different IPv6 address.
    [Arguments]  ${ipv6_adress_type}  ${channel_number}
    [Teardown]  Run Keywords
    ...    Delete IPv6 Address  ${test_ipv6_addr}  ${1}  Version=IPv6
    ...    AND  Delete IPv6 Address  ${test_ipv6_addr1}  ${2}  Version=IPv6
    ...    AND  Test Teardown Execution

    # Description of argument(s):
    # ipv6_adress_type   Type of IPv6 address(slaac/static).
    # channel_number     Ethernet channel number, 1(eth0) or 2(eth1).

    @{ipv6_addressorigin_list}  ${ipv6_addr}=
    ...  Get Address Origin List And Address For Type  ${ipv6_adress_type}  ${channel_number}
    Connect BMC Using IPv6 Address  ${ipv6_addr}
    RedfishIPv6.Login
    Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}  Version=IPv6
    Configure IPv6 Address On BMC  ${test_ipv6_addr1}  ${test_prefix_length}
    ...    channel_number=${2}  Version=IPv6


Modify IPv4 Address From IPv6 Address
    [Documentation]  Modify IPv4 address from IPv6 address.
    [Arguments]  ${ipv6_adress_type}  ${channel_number}  ${test_ipv4_addr}
    [Teardown]  Delete IP Address  ${test_ipv4_addr1}  version=IPv6

    @{ipv6_addressorigin_list}  ${ipv6_addr}=
    ...  Get Address Origin List And Address For Type  ${ipv6_adress_type}  ${channel_number}
    Connect BMC Using IPv6 Address  ${ipv6_addr}
    RedfishIPv6.Login
    ${test_gateway}=  Get BMC Default Gateway
    Add IP Address  ${test_ipv4_addr}  ${test_subnet_mask}  ${test_gateway}  version=IPv6
    Update IP Address  ${test_ipv4_addr}  ${test_ipv4_addr1}  ${test_subnet_mask}  ${test_gateway}  version=IPv6


Modify IPv6 Address From IPv6 Address
    [Documentation]  Modify IPv6 address from IPv6 address.
    [Arguments]  ${ipv6_adress_type}  ${channel_number}  ${test_ipv6_addr}
    [Teardown]  Delete IPv6 Address  ${test_ipv6_addr1}  Version=IPv6

    # Description of argument(s):
    # ipv6_adress_type   Type of IPv6 address(slaac/static).
    # channel_number     Ethernet channel number, 1(eth0) or 2(eth1).
    # test_ipv6_addr     IPv4 address parameter (not used in IPv6 modification).

    @{ipv6_addressorigin_list}  ${ipv6_addr}=
    ...  Get Address Origin List And Address For Type  ${ipv6_adress_type}  ${channel_number}
    Connect BMC Using IPv6 Address  ${ipv6_addr}
    RedfishIPv6.Login
    Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}  Version=IPv6
    Modify IPv6 Address  ${test_ipv6_addr}  ${test_ipv6_addr1}  ${test_prefix_length}  version=IPv6


Configure IPv6 Address In Different IPv6 Modes And Verify Ping
    [Documentation]  Configure slaac/static IPv6 addresses in different IPv6 modes
    ...    and verify ping
    [Arguments]  ${ipv6_address_type}  ${channel_number}

    # Description of argument(s):
    # ipv6_address_type   Type of IPv6 address(slaac/static).
    # channel_number      Ethernet channel number, 1(eth0) or 2(eth1).

    @{ipv6_addressorigin_list}  ${ipv6_addr}=
    ...  Get Address Origin List And Address For Type  ${ipv6_address_type}  ${channel_number}
    Connect BMC Using IPv6 Address  ${ipv6_addr}
    RedfishIPv6.Login
    IF  '${ipv6_address_type}' == 'Static'
        Set SLAAC Configuration State And Verify  ${True}
        @{ipv6_addressorigin_list}  ${ipv6_addr}=
        ...  Get Address Origin List And Address For Type  SLAAC  ${channel_number}
    ELSE
        @{ipv6_addressorigin_list}  ${ipv6_addr}=
        ...  Get Address Origin List And Address For Type  Static  ${channel_number}
        Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}  Version=IPv6
    END
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}
    Wait For IPv6 Host To Ping  ${ipv6_addr}


Verify Static IPv4 Functionality In Presence Of IPv6 Address
    [Documentation]  Verify static IPv4 functionality on both interfaces in
    ...    presence of IPv6 address by logging in from slaac/static IPv6 address
    [Arguments]  ${ipv6_address_type}  ${channel_number}

    # Description of argument(s):
    # ipv6_adress_type   Type of IPv6 address(slaac/static).
    # channel_number     Ethernet channel number, 1(eth0) or 2(eth1).

    @{ipv6_addressorigin_list}  ${ipv6_addr}=
    ...  Get Address Origin List And Address For Type  ${ipv6_address_type}  ${channel_number}
    Connect BMC Using IPv6 Address  ${ipv6_addr}
    RedfishIPv6.Login
    Verify Static IPv4 Functionality  ${channel_number}


Delete IPv4 Address From IPv6 And Verify
    [Documentation]  Delete IPv4 address from IPv6 and verify.
    [Arguments]   ${ipv6_address_type}  ${channel_number}  ${test_ipv4_addr}

    # Description of argument(s):
    # ipv6_address_type   Type of IPv6 address(slaac/static).
    # channel_number     Ethernet channel number, 1(eth0) or 2(eth1).
    # test_ipv4_addr     IPv4 address to add.

    @{ipv6_addressorigin_list}  ${ipv6_addr}=
    ...  Get Address Origin List And Address For Type  ${ipv6_address_type}  ${channel_number}
    Connect BMC Using IPv6 Address  ${ipv6_addr}
    RedfishIPv6.Login
    IF  '${ipv6_address_type}' == 'Static'
        Delete IP Address  ${test_ipv4_addr}  version=IPv6
    ELSE
        Delete IP Address  ${test_ipv4_addr1}  version=IPv6
    END