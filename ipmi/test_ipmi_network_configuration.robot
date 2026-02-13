*** Settings ***
Documentation          Module to test IPMI network functionality.

Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/bmc_network_utils.robot
Resource               ../lib/boot_utils.robot
Library                ../lib/ipmi_utils.py
Library                ../lib/gen_robot_valid.py
Library                ../lib/var_funcs.py
Library                ../lib/bmc_network_utils.py
Variables              ../data/ipmi_raw_cmd_table.py

Suite Setup            Suite Setup Execution
Suite Teardown         Redfish.Logout
Test Setup             Printn
Test Teardown          Test Teardown Execution

Test Tags              IPMI_Network_Configuration

*** Variables ***

${vlan_id_for_ipmi}     ${10}
@{vlan_ids}             ${20}  ${30}
${interface}            eth0
${initial_lan_config}   &{EMPTY}
${vlan_resource}        ${NETWORK_MANAGER}action/VLAN
${subnet_mask}          ${24}
${gateway_ip}           0.0.0.0
${vlan_id_for_rest}     ${30}


*** Test Cases ***

Verify IPMI Inband Network Configuration
    [Documentation]  Verify BMC network configuration via inband IPMI.
    [Tags]  Verify_IPMI_Inband_Network_Configuration
    [Teardown]  Run Keywords  Restore Configuration  AND  set_base_url    https://${OPENBMC_HOST}:${HTTPS_PORT}
    ...  AND  FFDC On Test Case Fail  AND
    ...  Redfish.Login  AND  Run IPMI Command  ${IPMI_RAW_CMD['Device ID']['Get'][0]}

    Redfish Power On

    Set IPMI Inband Network Configuration  ${STATIC_IP}  ${NETMASK}  ${GATEWAY}
    Sleep  10

    ${lan_print_output}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Valid Value  lan_print_output['IP Address']  ["${STATIC_IP}"]
    Valid Value  lan_print_output['Subnet Mask']  ["${NETMASK}"]
    Valid Value  lan_print_output['Default Gateway IP']  ["${GATEWAY}"]

    # To verify changed static ip is communicable through external IPMI cmd.
    Run External IPMI Raw Command  ${IPMI_RAW_CMD['Device ID']['Get'][0]}  H=${STATIC_IP}

    set_base_url    https://${STATIC_IP}:${HTTPS_PORT}
    Redfish.Login


    ${ipv4_addresses}=  Redfish.Get Attribute
    ...  ${REDFISH_NW_ETH_IFACE}${interface}  IPv4Addresses

    FOR  ${ipv4_address}  IN  @{ipv4_addresses}
        ${ip_address}=  Set Variable if  '${ipv4_address['Address']}' == '${STATIC_IP}'
                        ...  ${ipv4_address}
        IF  ${ip_address} != None  BREAK
    END

    Should Be Equal  ${ip_address['AddressOrigin']}  Static
    Should Be Equal  ${ip_address['SubnetMask']}  ${NETMASK}
    Should Be Equal  ${ip_address['Gateway']}  ${GATEWAY}

    Redfish.Logout


Disable VLAN Via IPMI When Multiple VLAN Exist On BMC
    [Documentation]  Disable  VLAN Via IPMI When Multiple VLAN Exist On BMC.
    [Tags]   Disable_VLAN_Via_IPMI_When_Multiple_VLAN_Exist_On_BMC

    FOR  ${vlan_id}  IN  @{vlan_ids}
      Create VLAN  ${vlan_id}
    END

    Create VLAN Via IPMI  off

    ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Valid Value  lan_config['802.1q VLAN ID']  ['Disabled']


Configure IP On VLAN Via IPMI
    [Documentation]   Configure IP On VLAN Via IPMI.
    [Tags]  Configure_IP_On_VLAN_Via_IPMI

    Create VLAN Via IPMI  ${vlan_id_for_ipmi}

    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} ipaddr ${STATIC_IP}  login_host=${0}

    ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Valid Value  lan_config['802.1q VLAN ID']  ['${vlan_id_for_ipmi}']
    Valid Value  lan_config['IP Address']  ["${STATIC_IP}"]


Create VLAN Via IPMI When LAN And VLAN Exist On BMC
    [Documentation]  Create VLAN Via IPMI When LAN And VLAN Exist On BMC.
    [Tags]   Create_VLAN_Via_IPMI_When_LAN_And_VLAN_Exist_On_BMC
    [Setup]  Create VLAN  ${vlan_id_for_rest}

    Create VLAN Via IPMI  ${vlan_id_for_ipmi}

    ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Valid Value  lan_config['802.1q VLAN ID']  ['${vlan_id_for_ipmi}']


Create VLAN Via IPMI And Verify
    [Documentation]  Create and verify VLAN via IPMI.
    [Tags]  Create_VLAN_Via_IPMI_And_Verify

    Create VLAN Via IPMI  ${vlan_id_for_ipmi}

    ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Valid Value  lan_config['802.1q VLAN ID']  ['${vlan_id_for_ipmi}']
    Valid Value  lan_config['IP Address']  ['${ip_address}']
    Valid Value  lan_config['Subnet Mask']  ['${subnet_mask}']

Test Disabling Of VLAN Via IPMI
    [Documentation]  Disable VLAN and verify via IPMI.
    [Tags]  Test_Disabling_Of_VLAN_Via_IPMI

    Create VLAN Via IPMI  ${vlan_id_for_ipmi}
    Create VLAN Via IPMI  off

    ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Valid Value  lan_config['802.1q VLAN ID']  ['Disabled']


Create VLAN When LAN And VLAN Exist With IP Address Configured
   [Documentation]  Create VLAN when LAN and VLAN exist with IP address configured.
   [Tags]  Create_VLAN_When_LAN_And_VLAN_Exist_With_IP_Address_Configured
   [Setup]  Run Keywords  Create VLAN  ${vlan_id_for_rest}  interface=${interface}
   ...  AND  Configure Network Settings On VLAN  ${vlan_id_for_rest}  ${STATIC_IP}
   ...  ${netmask}  ${gateway}  interface=${interface}

   Create VLAN Via IPMI   ${vlan_id_for_ipmi}

   ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
   Valid Value  lan_config['802.1q VLAN ID']  ['${vlan_id_for_ipmi}']
   Valid Value  lan_config['IP Address']  ['${STATIC_IP}']


Create Multiple VLANs Via IPMI And Verify
    [Documentation]  Create multiple VLANs through IPMI.
    [Tags]    Create_Multiple_VLANs_Via_IPMI_And_Verify

    FOR  ${vlan_id}  IN  @{vlan_ids}

      Create VLAN Via IPMI  ${vlan_id}

      ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband

      # Validate VLAN creation.
      Valid Value  lan_config['802.1q VLAN ID']  ['${vlan_id}']

      # Validate existing IP address.
      Valid Value  lan_config['IP Address']  ['${ip_address}']

      # Validate existing subnet mask.
      Valid Value  lan_config['Subnet Mask']  ['${subnet_mask}']
    END


*** Keywords ***

Create VLAN Via IPMI
    [Documentation]  Create VLAN via inband IPMI command.
    [Arguments]  ${vlan_id}  ${channel_number}=${CHANNEL_NUMBER}

    # Description of argument(s):
    # vlan_id  The VLAN ID (e.g. '10').

    Run Inband IPMI Standard Command
    ...  lan set ${channel_number} vlan id ${vlan_id}  login_host=${0}


Set IPMI Inband Network Configuration
    [Documentation]  Run sequence of standard IPMI command in-band and set
    ...              the IP configuration.
    [Arguments]  ${ip}  ${netmask}  ${gateway}  ${login}=${1}

    # Description of argument(s):
    # ip       The IP address to be set using ipmitool-inband.
    # netmask  The Netmask to be set using ipmitool-inband.
    # gateway  The Gateway address to be set using ipmitool-inband.

    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} ipsrc static  login_host=${login}
    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} ipaddr ${ip}  login_host=${0}
    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} netmask ${netmask}  login_host=${0}
    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} defgw ipaddr ${gateway}  login_host=${0}


Restore Configuration
    [Documentation]  Restore the configuration to its pre-test state.

    ${length}=  Get Length  ${initial_lan_config}
    IF  ${length} == ${0}  RETURN

    Set IPMI Inband Network Configuration  ${ip_address}  ${subnet_mask}
    ...  ${initial_lan_config['Default Gateway IP']}  login=${0}


Suite Setup Execution
    [Documentation]  Suite Setup Execution.

    Redfish.Login

    ${initial_lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Set Suite Variable  ${initial_lan_config}

    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} ipsrc static  login_host=${1}

    ${host_name}  ${ip_address}=  Get Host Name IP  host=${OPENBMC_HOST}
    Set Suite Variable  ${ip_address}

    @{network_configurations}=  Get Network Configuration
    FOR  ${network_configuration}  IN  @{network_configurations}
       IF  '${network_configuration['Address']}' == '${ip_address}'
           Set Suite Variable  ${subnet_mask}   ${network_configuration['SubnetMask']}
           BREAK
       END
    END

Test Teardown Execution
   [Documentation]  Test Teardown Execution.

   FFDC On Test Case Fail
   Create VLAN Via IPMI  off
   Restore Configuration
