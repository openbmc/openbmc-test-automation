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

Suite Setup     Suite Setup Execution
Test Teardown   FFDC On Test Case Fail


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


Create LDAP Configuration On Eth1 IP Address And Verify
    [Documentation]  Create LDAP configurtion on eth1 when eth0 ip address broken and verify.
    [Tags]  Create_LDAP_Configuration_On_Eth1_IP_Address_And_Verify
    [Setup]  Delete IP Address On Eth0 Using Eth1 IP Address  ${eth0_ip_address}
    [Teardown]  Run Keywords  Redfish1.Login  AND  Add IP Address On Eth0 Using Eth1 IP Address
    ...  ${eth0_ip_address}  ${eth0_subnet_mask}  ${eth0_gateway}

    ${body}=  Catenate  {'${LDAP_TYPE}':
    ...  {'ServiceEnabled': ${True},
    ...   'ServiceAddresses': ['${LDAP_SERVER_URI}'],
    ...   'Authentication':
    ...       {'AuthenticationType': 'UsernameAndPassword',
    ...        'Username':'${LDAP_BIND_DN}',
    ...        'Password': '${LDAP_BIND_DN_PASSWORD}'},
    ...   'LDAPService':
    ...       {'SearchSettings':
    ...           {'BaseDistinguishedNames': ['${LDAP_BASE_DN}']}}}}

    Redfish1.Login
    Redfish1.Patch  ${REDFISH_BASE_URI}AccountService  body=${body}
    Sleep  20s
    Redfish1.Logout
    Redfish1.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish1.Logout


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

    ${active_channel_config}=  Get Active Channel Config
    Set Suite Variable  ${active_channel_config}

    ${eth0_host_name}  ${eth0_ip_address}=  Get Host Name IP  host=${OPENBMC_HOST}
    Set Suite Variable  ${eth0_ip_address}
 
    ${network_configurations}=  Get Network Configuration Using Channel Number  1
    FOR  ${network_configuration}  IN  @{network_configurations}
      Run Keyword If  '${network_configuration['Address']}' == '${eth0_ip_address}'
      ...  Run Keywords  Set Suite Variable  ${eth0_subnet_mask}  ${network_configuration['SubnetMask']}
      ...  AND  Set Suite Variable  ${eth0_gateway}  ${network_configuration['Gateway']}
      ...  AND  Exit For Loop
    END


Delete IP Address On Eth0 Using Eth1 IP Address
    [Documentation]  Delete IP address on eth0 interface using eth1 IP address.
    [Arguments]  ${ip_address}

    # Description of argument(s):
    # ip_address    IP address to be deleted (e.g. "10.7.7.7").

    ${patch_list}=  Create List
    ${empty_dict}=  Create Dictionary

    Redfish1.Login
    ${resp}=  Redfish1.Get  ${REDFISH_NW_ETH_IFACE}eth0
    @{network_configurations}=  Get From Dictionary  ${resp.dict}  IPv4StaticAddresses

    FOR  ${network_configuration}  IN  @{network_configurations}
      Run Keyword If  '${network_configuration['Address']}' == '${ip_address}'
      ...  Append To List  ${patch_list}  ${null}
      ...  ELSE  Append To List  ${patch_list}  ${empty_dict}
    END

    ${data}=  Create Dictionary  IPv4StaticAddresses=${patch_list}

    Redfish1.Patch  ${REDFISH_NW_ETH_IFACE}eth0  body=&{data}

    Sleep  ${NETWORK_TIMEOUT}s
    ${status}=  Run Keyword And Return Status
    ...  Verify IP On BMC Using Eth1 IP Address  ${1}  ${ip_address}
    Should Be Equal  ${status}  ${False}


Add IP Address On Eth0 Using Eth1 IP Address
    [Documentation]  Add IP address on eth0 interface using eth1 IP address.
    [Arguments]  ${ip}  ${subnet_mask}  ${gateway}

    # Description of argument(s):
    # ip                  IP address to be added (e.g. "10.7.7.7").
    # subnet_mask         Subnet mask for the IP to be added (e.g. "255.255.0.0").
    # gateway             Gateway for the IP to be added (e.g. "10.7.7.1").

    ${empty_dict}=  Create Dictionary
    ${patch_list}=  Create List

    ${ip_data}=  Create Dictionary  Address=${ip}
    ...  SubnetMask=${subnet_mask}  Gateway=${gateway}

    ${resp}=  Redfish1.Get  ${REDFISH_NW_ETH_IFACE}eth0
    @{network_configurations}=  Get From Dictionary  ${resp.dict}  IPv4StaticAddresses

    ${num_entries}=  Get Length  ${network_configurations}
    FOR  ${INDEX}  IN RANGE  0  ${num_entries}
      Append To List  ${patch_list}  ${empty_dict}
    END

    Append To List  ${patch_list}  ${ip_data}

    # Run patch command only if given IP is found on BMC
    ${data}=  Create Dictionary  IPv4StaticAddresses=${patch_list}

    Redfish1.patch  ${REDFISH_NW_ETH_IFACE}eth0  body=&{data}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]

    # Note: Network restart takes around 15-18s after patch request processing
    Sleep  ${NETWORK_TIMEOUT}s
    Verify IP On BMC Using Eth1 IP Address  ${1}  ${ip}


Verify IP On BMC Using Eth1 IP Address
    [Documentation]  Verify IP on bmc using ssh.
    [Arguments]  ${channel_number}  ${ip}

    # Description of argument(s):
    # channel_number   Ethernet channel number, 1 is for eth0 and 2 is for eth1 (e.g. "1").
    # ip               IP address to be verified (e.g. "10.7.7.7").

    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}

    SSHLibrary.Open Connection  ${OPENBMC_HOST_1}
    SSHLibrary.Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ${stdout}=   SSHLibrary.Execute Command  /sbin/ip addr | grep ${ethernet_interface}

    # Get line having IP address details.
    ${lines}=  Get Lines Containing String  ${stdout}  inet

    # List IP address details.
    @{ip_components}=  Split To Lines  ${lines}
    @{ip_data}=  Create List

    # Get all IP addresses and prefix lengths on system.
    FOR  ${ip_component}  IN  @{ip_components}
      @{if_info}=  Split String  ${ip_component}
      ${ip_n_prefix}=  Get From List  ${if_info}  1
      Append To List  ${ip_data}  ${ip_n_prefix}
    END

    Should Contain Match  ${ip_data}  ${ip}/*  msg=IP address does not exist.
