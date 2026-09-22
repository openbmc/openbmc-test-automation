*** Settings ***
Documentation   Test BMC DHCP multiple network interface functionalities.
...             Run on setup eth0 in DHCP and eth1 in static.

Resource        ../../lib/resource.robot
Resource        ../../lib/common_utils.robot
Resource        ../../lib/bmc_network_utils.robot
Resource        ../../lib/bmc_ipv6_utils.robot
Resource        ../../lib/openbmc_ffdc.robot

# User input BMC IP for the eth1.
# User can input as  -v OPENBMC_HOST_ETH1:xx.xxx.xx from command line.
Library         ../../lib/bmc_redfish.py  https://${OPENBMC_HOST_ETH1}:${HTTPS_PORT}
...             ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  AS  Redfish1

Suite Setup     Suite Setup Execution
Test Teardown   Test Teardown Execution
Suite Teardown  Run Keyword And Ignore Error  Redfish1.Logout

Test Tags       Multiple_Interfaces_DHCP_Eth0


*** Variables ***

# Use eth1 as BMC address since eth0 DHCP will be modified during tests.
${OPENBMC_HOST}         ${OPENBMC_HOST_ETH1}
${test_ipv4_addr}       10.7.7.7
${test_subnet_mask}     255.255.255.0


*** Test Cases ***

Disable DHCP On Eth0 And Verify System Is Accessible By Eth1
    [Documentation]  Disable DHCP on eth0 using Redfish and verify
    ...              if system is accessible by eth1.
    [Tags]  Disable_DHCP_On_Eth0_And_Verify_System_Is_Accessible_By_Eth1

    Set DHCPEnabled Via Eth1  False  eth0
    ${DHCPEnabled}=  Get IPv4 DHCP Enabled Status Via Eth1  ${1}
    Should Be Equal  ${DHCPEnabled}  ${False}
    Wait For Host To Ping  ${OPENBMC_HOST_ETH1}  ${NETWORK_TIMEOUT}


Enable DHCP On Eth0 And Verify System Is Accessible By Eth1
    [Documentation]  Enable DHCP on eth0 using Redfish and verify if system
    ...              is accessible by eth1.
    [Tags]  Enable_DHCP_On_Eth0_And_Verify_System_Is_Accessible_By_Eth1
    [Setup]  Set DHCPEnabled Via Eth1  False  eth0

    Set DHCPEnabled Via Eth1  True  eth0
    ${DHCPEnabled}=  Get IPv4 DHCP Enabled Status Via Eth1  ${1}
    Should Be Equal  ${DHCPEnabled}  ${True}
    Wait For Host To Ping  ${OPENBMC_HOST_ETH1}  ${NETWORK_TIMEOUT}


Verify Eth0 Link Local Address Behavior On DHCP Toggle
    [Documentation]  Verify link local comes up on disabling DHCP on eth0 and
    ...              doesn't appear on enabling DHCP on eth0.
    [Tags]  Verify_Eth0_Link_Local_Address_Behavior_On_DHCP_Toggle
    [Setup]  Set DHCPEnabled Via Eth1  True  eth0

    # Disable DHCP on eth0.
    Set DHCPEnabled Via Eth1  False  eth0
    Sleep  ${NETWORK_TIMEOUT}

    # Verify Link Local comes up on disabling DHCP on eth0.
    @{ipv4_addressorigin_list}  ${ipv4_addr_list}=
    ...  Get Address Origin List And IPv4 or IPv6 Address Via Eth1  IPv4Addresses  ${1}
    ${ipv4_addressorigin_list}=  Combine Lists  @{ipv4_addressorigin_list}
    Should Contain  ${ipv4_addressorigin_list}  IPv4LinkLocal

    # Enable DHCP on eth0.
    Set DHCPEnabled Via Eth1  True  eth0
    Sleep  ${NETWORK_TIMEOUT}

    # Verify Link Local doesn't appear on enabling DHCP on eth0.
    @{ipv4_addressorigin_list}  ${ipv4_addr_list}=
    ...  Get Address Origin List And IPv4 or IPv6 Address Via Eth1  IPv4Addresses  ${1}
    ${ipv4_addressorigin_list}=  Combine Lists  @{ipv4_addressorigin_list}
    Should Not Contain  ${ipv4_addressorigin_list}  IPv4LinkLocal


Verify Eth0 DHCP Disable Assigns Link Local Before Static IP
  [Documentation]  Switch eth0 from DHCP to static mode. BMC must obtain a
  ...  link-local address before a static IP is configured.
  [Tags]  Verify_Eth0_DHCP_Disable_Assigns_Link_Local_Before_Static_IP
  [Teardown]  Run Keywords
  ...  Run Keyword And Ignore Error  Delete IP Address  ${test_ipv4_addr}  AND
  ...  Set DHCPEnabled To Enable Or Disable  ${True}  ${ethernet_interface}  AND
  ...  Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

  ${active_channel_config}=  Get Active Channel Config
  ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}
  Set Test Variable  ${ethernet_interface}

  ${eth0_dhcp_status}=  Get IPv4 DHCP Enabled Status  ${CHANNEL_NUMBER}
  Should Be Equal  ${eth0_dhcp_status}  ${True}
  ...  msg=${ethernet_interface} is expected to be in DHCP mode but it is not.

  Verify Static IPv4 Functionality  ${SECONDARY_CHANNEL_NUMBER}

  Set DHCPEnabled To Enable Or Disable  ${False}  ${ethernet_interface}
  Sleep  ${NETWORK_TIMEOUT}s

  ${origin_list}  ${addr_list}=  Wait Until Keyword Succeeds  60s  5s
  ...  Get Address Origin List And IPv4 or IPv6 Address  IPv4Addresses  ${CHANNEL_NUMBER}
  Should Contain  ${origin_list}  IPv4LinkLocal
  ...  msg=No IPv4LinkLocal address found on eth0 after disabling DHCP.

  Add IP Address  ${test_ipv4_addr}  ${test_subnet_mask}  0.0.0.0

  Verify IP On BMC  ${test_ipv4_addr}  ${CHANNEL_NUMBER}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup task.

    Valid Value  OPENBMC_HOST_ETH1

    # Check eth1 is configured and reachable.
    Ping Host  ${OPENBMC_HOST_ETH1}

    Redfish1.Login


Test Teardown Execution
    [Documentation]  Test teardown execution.

    FFDC On Test Case Fail
    Run Keyword And Ignore Error  Set DHCPEnabled Via Eth1  True  eth0


Set DHCPEnabled Via Eth1
    [Documentation]  Enable or Disable DHCP on the interface via eth1.
    [Arguments]  ${dhcp_enabled}=${False}  ${interface}=eth0
    ...          ${valid_status_code}=[${HTTP_OK},${HTTP_ACCEPTED},${HTTP_NO_CONTENT}]

    # Description of argument(s):
    # dhcp_enabled        False for disabling DHCP and True for Enabling DHCP.
    # interface           eth0 or eth1. Default is eth0.
    # valid_status_code   Expected valid status code from Patch request.

    ${data}=  Set Variable If  ${dhcp_enabled} == ${False}  ${DISABLE_DHCP}  ${ENABLE_DHCP}
    Redfish1.Patch  ${REDFISH_NW_ETH_IFACE}${interface}
    ...  body=${data}  valid_status_codes=${valid_status_code}


Get IPv4 DHCP Enabled Status Via Eth1
    [Documentation]  Return IPv4 DHCP enabled status via eth1.
    [Arguments]  ${channel_number}=${1}

    # Description of argument(s):
    # channel_number   Ethernet channel number, 1 is for eth0 and 2 is for eth1.

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}
    ${resp}=  Redfish1.Get Attribute  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  DHCPv4

    RETURN  ${resp['DHCPEnabled']}


Get Address Origin List And IPv4 or IPv6 Address Via Eth1
    [Documentation]  Get address origin list and IPv4 or IPv6 address via eth1.
    [Arguments]  ${ip_address_type}  ${channel_number}=${CHANNEL_NUMBER}

    # Description of argument(s):
    # ip_address_type  Type of IPv4 or IPv6 address (IPv4Addresses or IPv6Addresses).
    # channel_number   Ethernet channel number, 1 is for eth0 and 2 is for eth1.

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}
    ${resp}=  Redfish1.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    @{ip_addresses}=  Get From Dictionary  ${resp.dict}  ${ip_address_type}

    ${ip_addressorigin_list}=  Create List
    ${ip_addr_list}=  Create List
    FOR  ${ip_address}  IN  @{ip_addresses}
        ${ip_addressorigin}=  Get From Dictionary  ${ip_address}  AddressOrigin
        Append To List  ${ip_addressorigin_list}  ${ip_addressorigin}
        Append To List  ${ip_addr_list}  ${ip_address['Address']}
    END
    RETURN  ${ip_addressorigin_list}  ${ip_addr_list}