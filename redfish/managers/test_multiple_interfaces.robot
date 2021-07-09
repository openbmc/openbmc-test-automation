*** Settings ***
Documentation   Test BMC multiple network interface functionalities.

# User input BMC IP for the eth1.
# Use can input as  -v OPENBMC_HOST_1:xx.xxx.xx from command line.
Library         ../../lib/bmc_redfish.py  https://${OPENBMC_HOST_1}:${HTTPS_PORT}
...             ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  WITH NAME  Redfish1

Resource        ../../lib/resource.robot
Resource        ../../lib/common_utils.robot
Resource        ../../lib/connection_client.robot
Resource        ../../lib/bmc_network_utils.robot
Resource        ../../lib/openbmc_ffdc.robot
Resource        ../../lib/bmc_ldap_utils.robot
Resource        ../../lib/snmp/resource.robot
Resource        ../../lib/snmp/redfish_snmp_utils.robot

Suite Setup     Suite Setup Execution
Test Teardown   FFDC On Test Case Fail
Suite Teardown  Run Keywords  Redfish1.Logout  AND  Redfish.Logout

*** Test Cases ***

Verify Both Interfaces BMC IP Addresses Accessible Via SSH
    [Documentation]  Verify both interfaces (eth0, eth1) BMC IP addresses accessible via SSH.
    [Tags]  Verify_Both_Interfaces_BMC_IP_Addresses_Accessible_Via_SSH

    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  host=${OPENBMC_HOST}
    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  host=${OPENBMC_HOST_1}
    Close All Connections


Verify Redfish Works On Both Interfaces
    [Documentation]  Verify access BMC with both interfaces (eth0, eth1) IP addresses via Redfish.
    [Tags]  Verify_Redfish_Works_On_Both_Interfaces
    [Teardown]  Run Keywords
    ...  Configure Hostname  ${hostname}  AND  Validate Hostname On BMC  ${hostname}

    Redfish1.Login
    Redfish.Login

    ${hostname}=  Redfish.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  HostName
    ${data}=  Create Dictionary  HostName=openbmc
    Redfish1.patch  ${REDFISH_NW_ETH_IFACE}eth1  body=&{data}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    Validate Hostname On BMC  openbmc

    ${resp1}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}eth0
    ${resp2}=  Redfish1.Get  ${REDFISH_NW_ETH_IFACE}eth1
    Should Be Equal  ${resp1.dict['HostName']}  ${resp2.dict['HostName']}


Verify LDAP Login Works When Eth1 IP Is Not Configured
    [Documentation]  Verify LDAP login works when eth1 IP is erased.
    [Tags]  Verify_LDAP_Login_Works_When_Eth1_IP_Is_Not_Configured
    [Setup]  Run Keywords  Set Test Variable  ${CHANNEL_NUMBER}  ${2}
    ...  AND  Delete IP Address  ${OPENBMC_HOST_1}
    [Teardown]  Run Keywords  Redfish.Login  AND
    ...  Add IP Address  ${OPENBMC_HOST_1}  ${eth1_subnet_mask}  ${eth1_gateway}

    Create LDAP Configuration
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Logout


Verify SNMP Works When Eth1 IP Is Not Configured
    [Documentation]  Verify SNMP works when eth1 IP is not configured.
    [Tags]  Verify_SNMP_Works_When_Eth1_IP_Is_Not_Configured
    [Setup]  Run Keywords  Set Test Variable  ${CHANNEL_NUMBER}  ${2}
    ...  AND  Delete IP Address  ${OPENBMC_HOST_1}
    [Teardown]  Run Keywords  Redfish.Login  AND
    ...  Add IP Address  ${OPENBMC_HOST_1}  ${eth1_subnet_mask}  ${eth1_gateway}

    Create Error On BMC And Verify Trap


Disable And Enable Eth0 Interface
    [Documentation]  Disable and Enable eth0 ethernet interface via redfish.
    [Tags]  Disable_And_Enable_Eth0_Interface
    [Template]  Set BMC Ethernet Interfaces State

    # interface_ip   interface  enabled
    ${OPENBMC_HOST}   eth0      ${False}
    ${OPENBMC_HOST}   eth0      ${True}


Verify BMC Accessible With SSH 2201 Port Via Both Interfaces
    [Documentation]  Verify BMC accessible with ssh 2201 port via both interfaces.
    [Tags]  Verify_BMC_Accessible_With_SSH_2201_Port_Via_Both_Interfaces

    Open Connection And Log In  host=${OPENBMC_HOST}  port=2201
    Open Connection And Log In  host=${OPENBMC_HOST_1}  port=2201
    Close All Connections


*** Keywords ***

Get Network Configuration Using Channel Number
    [Documentation]  Get ethernet interface.
    [Arguments]  ${channel_number}

    # Description of argument(s):
    # channel_number   Ethernet channel number, 1 is for eth0 and 2 is for eth1 (e.g. "1").

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}

    @{network_configurations}=  Get From Dictionary  ${resp.dict}  IPv4StaticAddresses
    [Return]  @{network_configurations}


Suite Setup Execution
    [Documentation]  Do suite setup task.

    Valid Value  OPENBMC_HOST_1

    # Check both interfaces are configured and reachable.
    Ping Host  ${OPENBMC_HOST}
    Ping Host  ${OPENBMC_HOST_1}

    ${network_configurations}=  Get Network Configuration Using Channel Number  ${2}
    FOR  ${network_configuration}  IN  @{network_configurations}

      Run Keyword If  '${network_configuration['Address']}' == '${OPENBMC_HOST_1}'
      ...  Run Keywords  Set Suite Variable  ${eth1_subnet_mask}  ${network_configuration['SubnetMask']}
      ...  AND  Set Suite Variable  ${eth1_gateway}  ${network_configuration['Gateway']}
      ...  AND  Exit For Loop

    END


Set BMC Ethernet Interfaces State
    [Documentation]  Set BMC ethernet interface state.
    [Arguments]  ${interface_ip}  ${interface}  ${enabled}
    [Teardown]  Redfish1.Logout

    # Description of argument(s):
    # interface_ip    IP address of ethernet interface.
    # interface       The ethernet interface name (eg. eth0 or eth1).
    # enabled         Indicates interface should be enabled (eg. True or False).

    Redfish1.Login

    ${data}=  Create Dictionary  InterfaceEnabled=${enabled}

    Redfish1.patch  ${REDFISH_NW_ETH_IFACE}${interface}  body=&{data}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    Sleep  ${NETWORK_TIMEOUT}s
    ${interface_status}=   Redfish1.Get Attribute  ${REDFISH_NW_ETH_IFACE}${interface}  InterfaceEnabled
    Should Be Equal  ${interface_status}  ${enabled}

    ${status}=  Run Keyword And Return Status  Ping Host  ${interface_ip}

    Run Keyword If  ${enabled} == ${True}  Should Be Equal  ${status}  ${True}
    ...  ELSE  Should Be Equal  ${status}  ${False}
