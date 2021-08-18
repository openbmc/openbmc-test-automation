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

Suite Setup            Suite Setup Execution
Suite Teardown         Redfish.Logout
Test Setup             Printn
Test Teardown          Test Teardown Execution

Force Tags             IPMI_Network_Config


*** Variables ***
${vlan_id_for_ipmi}     ${10}
@{vlan_ids}             ${20}  ${30}
${interface}            eth0
${ip}                   10.0.0.1
${initial_lan_config}   &{EMPTY}
${vlan_resource}        ${NETWORK_MANAGER}action/VLAN
${netmask}              ${24}
${gateway}              0.0.0.0
${vlan_id_for_rest}     ${30}


*** Test Cases ***

Verify IPMI Inband Network Configuration
    [Documentation]  Verify BMC network configuration via inband IPMI.
    [Tags]  Verify_IPMI_Inband_Network_Configuration
    [Teardown]  Run Keywords  Restore Configuration  AND  FFDC On Test Case Fail

    Redfish Power On

    Set IPMI Inband Network Configuration  ${STATIC_IP}  ${NETMASK}  ${GATEWAY}
    Sleep  10

    ${lan_print_output}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Valid Value  lan_print_output['IP Address']  ["${STATIC_IP}"]
    Valid Value  lan_print_output['Subnet Mask']  ["${NETMASK}"]
    Valid Value  lan_print_output['Default Gateway IP']  ["${GATEWAY}"]


Disable VLAN Via IPMI When Multiple VLAN Exist On BMC
    [Documentation]  Disable  VLAN Via IPMI When Multiple VLAN Exist On BMC.
    [Tags]   Disable_VLAN_Via_IPMI_When_LAN_And_VLAN_Exist_On_BMC

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
    ...  lan set ${CHANNEL_NUMBER} ipaddr ${ip}  login_host=${0}

    ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Valid Value  lan_config['802.1q VLAN ID']  ['${vlan_id_for_ipmi}']
    Valid Value  lan_config['IP Address']  ["${ip}"]


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
   [Setup]  Run Keywords  Create VLAN  ${vlan_id_for_rest}  AND  Configure Network Settings On VLAN
   ...  ${vlan_id_for_rest}  ${ip}  ${netmask}  ${gateway}

   Create VLAN Via IPMI   ${vlan_id_for_ipmi}

   ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
   Valid Value  lan_config['802.1q VLAN ID']  ['${vlan_id_for_ipmi}']
   Valid Value  lan_config['IP Address']  ['${ip}']


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
    Return From Keyword If  ${length} == ${0}

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
       Run Keyword If  '${network_configuration['Address']}' == '${ip_address}'
       ...  Run Keywords  Set Suite Variable  ${subnet_mask}   ${network_configuration['SubnetMask']}  AND
       ...  Exit For Loop
    END

Test Teardown Execution
   [Documentation]  Test Teardown Execution.

   FFDC On Test Case Fail
   Create VLAN Via IPMI  off
   Restore Configuration
