*** Settings ***
Documentation    Test BMC multiple interface functionalities.

Library         ../../lib/bmc_redfish.py  https://${OPENBMC_HOST_1}:${HTTPS_PORT}
...             ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  WITH NAME  Redfish1

Resource        ../../lib/resource.robot
Resource        ../../lib/common_utils.robot
Resource        ../../lib/connection_client.robot
Resource        ../../lib/bmc_redfish_resource.robot
Resource        ../../lib/bmc_network_utils.robot
Resource        ../../lib/openbmc_ffdc.robot
Library         ../../lib/bmc_network_utils.py

Suite Setup     Suite Setup Execution

*** Variables ***



*** Test Cases ***

Verify Both Interfaces Able To Pingable
    [Documentation]  Verify both interfaces able to ping.
    [Tags]  Verify_Both_Interfaces_Able_To_Pingable
    [Setup]  Configure Eth1 With Eth0 Netmask
    [Teardown]  Restore Eth1 IP Address Using Eth0 IP Address

    ${new_bmc_ip}=  Create New IP Address Using BMC IP
    Ping Host  ${OPENBMC_HOST}
    Ping Host  ${new_bmc_ip}


Verify Both Interfaces Able To Access Via SSH
    [Documentation]  Verify able to SSH both interfaces.
    [Tags]  Verify_Both_Interfaces_Able_To_Access_Via_SSH
    [Setup]  Configure Eth1 With Eth0 Netmask
    [Teardown]  Restore Eth1 IP Address Using Eth0 IP Address

    ${new_bmc_ip}=  Create New IP Address Using BMC IP
    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  host=${OPENBMC_HOST}
    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  host=${new_bmc_ip}
    Close All Connections


*** Keywords ***

Get Network Configuration Using Channel Number
    [Documentation]  Get ethernet intreface.
    [Arguments]  ${channel_number}

    # Description of argument(s):
    # channel_number  The user's channel number (e.g. "1").

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}

    @{network_configurations}=  Get From Dictionary  ${resp.dict}  IPv4StaticAddresses
    [Return]  @{network_configurations}


Suite Setup Execution
    [Documentation]  Do suite setup task.

    Redfish1.Login
    Redfish.Login
    ${host_name}  ${eth1_ip_address}=  Get Host Name IP  host=${OPENBMC_HOST_1}
    Set Suite Variable  ${eth1_ip_address}

    @{network_configurations}=  Get Network Configuration Using Channel Number  2
    FOR  ${network_configuration}  IN  @{network_configurations}
      Run Keyword If  '${network_configuration['Address']}' == '${eth1_ip_address}'
      ...  Run Keywords  Set Suite Variable  ${eth1_subnet_mask}  ${network_configuration['SubnetMask']}
      ...  AND  Set Suite Variable  ${eth1_gateway}  ${network_configuration['Gateway']}
      ...  AND  Exit For Loop
    END


Create New IP Address Using BMC IP
    [Documentation]  Create and get IP Addess with eth0 ip address.
    [Arguments]  ${bmc_ip}=${OPENBMC_HOST}

    # Description of argument(s):
    # bmc_ip     BMC ip address.

    ${host_name}  ${ip_addr}=  Get Host Name IP  ${bmc_ip}

    ${split_ip}=  Split String From Right  ${ip_addr}  .  1
    ${network_part}=  Get From List  ${split_ip}  0
    ${octets}=  Split String  ${ip_addr}  .
    ${last_octet}=  Get From List  ${octets}  -1
    ${octet4}=  Evaluate  int(${last_octet}) - ${1}
    ${new_ip}=  Catenate  ${network_part}.${octet4}

    [Return]  ${new_ip}


Update Eth1 IP Address Using Eth0 IP Address
    [Documentation]  Update eth1 IP address using eth0 IP address.
    [Arguments]  ${old_ip}  ${new_ip}  ${new_gateway}  ${new_netmask}

    # Description of argument(s):
    # ip                  IP address to be replaced (e.g. "10.7.7.7").
    # new_ip              New IP address to be configured.
    # new_netmask         New Netmask value to be configured.
    # new_gateway         New Gateway IP address to be configured.

    ${patch_list}=  Create List
    ${empty_dict}=  Create Dictionary

    ${ip_data}=  Create Dictionary
    ...  Address=${new_ip}
    ...  SubnetMask=${new_netmask}
    ...  Gateway=${new_gateway}

    ${network_configurations}=  Get Network Configuration Using Channel Number  ${2}

    FOR  ${network_configuration}  IN  @{network_configurations}
      Run Keyword If  '${network_configuration['Address']}' == '${old_ip}'
      ...  Append To List  ${patch_list}  ${ip_data}
      ...  ELSE  Append To List  ${patch_list}  ${empty_dict}
    END

    ${data}=  Create Dictionary  IPv4StaticAddresses=${patch_list}
    Redfish.Patch  ${REDFISH_NW_ETH_IFACE}eth1  body=&{data}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]

    Sleep  ${NETWORK_TIMEOUT}s
    Verify IP On BMC Via SSH  ${new_ip}
    Wait For Host To Ping  ${new_ip}  ${NETWORK_TIMEOUT}


Configure Eth1 With Eth0 Netmask
    [Documentation]  Configure eth1 with eth0 network details.

    ${ip_address}=  Create New IP Address Using BMC IP
    ${network_configurations}=  Get Network Configuration

    ${host_name}  ${ip_addr}=  Get Host Name IP  ${OPENBMC_HOST}

    @{network_configurations}=  Get Network Configuration Using Channel Number  1
    FOR  ${network_configuration}  IN  @{network_configurations}
      Run Keyword If  '${network_configuration['Address']}' =='${ip_addr}'
      ...  Run Keywords  Set Suite Variable  ${netmask}  ${network_configuration['SubnetMask']}
      ...  AND  Set Suite Variable  ${gateway}  ${network_configuration['Gateway']}
      ...  AND  Exit For Loop
    END

    Update Eth1 IP Address Using Eth0 IP Address  ${OPENBMC_HOST_1}
    ...  ${ip_address}  ${gateway}  ${netmask}


Restore Eth1 IP Address Using Eth0 IP Address
    [Documentation]  Restore BMC IP address.

    ${ip_address}=  Create New IP Address Using BMC IP
    Update Eth1 IP Address Using Eth0 IP Address  ${ip_address}
    ...  ${OPENBMC_HOST_1}  ${eth1_gateway}  ${eth1_subnet_mask}


Verify IP On BMC Via SSH
    [Documentation]  Verify IP on bmc using ssh.
    [Arguments]  ${ip}

    # Description of argument(s):
    # ip    IP address to be verified (e.g. "10.7.7.7").

    ${output}=  Get BMC Route Info
    Should Contain  ${output}  ${ip}
