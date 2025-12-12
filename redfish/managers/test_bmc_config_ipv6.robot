*** Settings ***
Documentation  Network interface IPv6 configuration connected to DHCP server
               ...   and verification tests.

Resource       ../../lib/bmc_redfish_resource.robot
Resource       ../../lib/openbmc_ffdc.robot
Resource       ../../lib/bmc_ipv6_utils.robot
Resource       ../../lib/bmc_network_utils.robot
Resource       ../../lib/protocol_setting_utils.robot

Library        Collections
Library        Process
Library        OperatingSystem
Suite Setup     Suite Setup Execution
Test Teardown   Test Teardown Execution

Test Tags     BMC_IPv6_Config

*** Variables ***
# Remote DHCP test bed server. Leave variables EMPTY if server is configured local
# to the test where it is running else if remote pass the server credentials
# -v SERVER_IPv6:xx.xx.xx.xx
# -v SERVER_USERNAME:root
# -v SERVER_PASSWORD:*********

${SERVER_USERNAME}      ${EMPTY}
${SERVER_PASSWORD}      ${EMPTY}
${SERVER_IPv6}          ${EMPTY}


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


Configure Static IPv6 From SLAAC Address
    [Documentation]  Configure Static IPv6 From SLAAC Address.
    [Tags]  Configure_Static_IPv6_From_SLAAC_Address

    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=
    ...  Get Address Origin List And Address For Type  SLAAC  ${2}
    Connect BMC Using IPv6 Address  ${ipv6_slaac_addr}
    RedfishIPv6.Login
    Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}  Version=IPv6


Disable DHCP On Eth1 From SLAAC IPv6
    [Documentation]  Disable DHCP On Eth1 From SLAAC IPv6
    [Tags]  Disable_DHCP_On_Eth1_From_SLAAC_IPv6

    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=
    ...  Get Address Origin List And Address For Type  SLAAC  ${2}
    Connect BMC Using IPv6 Address  ${ipv6_slaac_addr}
    Disable Or Enable DHCP On Eth1 From IPv6 Address  False


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup execution.

    Redfish.Login
    ${active_channel_config}=  Get Active Channel Config
    Set Suite Variable  ${active_channel_config}
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}
    Set Suite variable  ${ethernet_interface}


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
    [Arguments]  ${DHCP_state}

    # Description of argument(s):
    # DHCP_state  Enable or Disable DHCP

    RedfishIPv6.Login
    Set DHCPEnabled To Enable Or Disable  ${DHCP_state}  eth1  Version=IPv6
