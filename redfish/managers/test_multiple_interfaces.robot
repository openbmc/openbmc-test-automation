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
Resource        ../../lib/snmp/resource.robot
Resource        ../../lib/snmp/redfish_snmp_utils.robot
Library         ../../lib/jobs_processing.py

Suite Setup     Suite Setup Execution
Test Teardown   FFDC On Test Case Fail

*** Variables ***
${nameserver1}     10.7.7.10
${nameserver2}     10.7.7.11

*** Test Cases ***

Verify Both Interfaces BMC IP Addreeses Accessible Via SSH
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


Generate Error On Eth0 IP And Verify SNMP Trap When Eth1 IP Broken
    [Documentation]  Generate error on BMC and verify trap when eth1 IP broken.
    [Tags]  Generate_Error_On_Eth0_IP_And_Verify_SNMP_Trap_When_Eth1_IP_Broken
    [Setup]  Run Keywords  Set Test Variable  ${CHANNEL_NUMBER}  ${2}
    ...  AND  Delete IP Address  ${OPENBMC_HOST_1}
    [Teardown]  Run Keywords  Redfish.Login  AND
    ...  Add IP Address  ${OPENBMC_HOST_1}  ${eth1_subnet_mask}  ${eth1_gateway}

    Create Error On BMC And Verify Trap


Verify Both Interfaces Wroks Concurrently Using Redfish
    [Documentation]  Verify both interface works concurrently using redfish.
    [Tags]  Verify_Both_Interfaces_Using_Redfish_Concurrently

    Redfish1.Login
    Redfish.Login

    # Configuring nameservers on eth0 and eth1
    ${dict}=  Execute Process Multi Keyword  ${2}
    ...  Redfish.Patch ${REDFISH_NW_ETH_IFACE}eth0 body={'StaticNameServers':['${nameserver1}']}
    ...  Redfish1.Patch ${REDFISH_NW_ETH_IFACE}eth1 body={'StaticNameServers':['${nameserver2}']}

    Dictionary Should Not Contain Value  ${dict}  False
    ...  msg=One or more operations has failed.

    Sleep  3s
    ${nameservers}=  CLI Get Nameservers
    Should Contain  ${nameservers}  ${nameserver1}
    Should Contain  ${nameservers}  ${nameserver2}

    # Deleteing nameservrs on eth0 and eth1
    ${dict}=  Execute Process Multi Keyword  ${2}
    ...  Redfish.Patch ${REDFISH_NW_ETH_IFACE}eth0 body={'StaticNameServers':[]}
    ...  Redfish1.Patch ${REDFISH_NW_ETH_IFACE}eth1 body={'StaticNameServers':[]}

    Dictionary Should Not Contain Value  ${dict}  False
    ...  msg=One or more operations has failed.

    Sleep  3s
    ${nameservers}=  CLI Get Nameservers
    Should Not Contain  ${nameservers}  ${nameserver1}
    Should Not Contain  ${nameservers}  ${nameserver2}


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
