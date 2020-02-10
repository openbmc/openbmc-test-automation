*** Settings ***

Documentation          Module to test IPMI network functionality.
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/bmc_network_utils.robot
Library                ../lib/ipmi_utils.py
Library                ../lib/gen_robot_valid.py
Library                ../lib/var_funcs.py
Library                ../lib/bmc_network_utils.py

Suite Setup            Suite Setup Execution
Test Setup             Printn
Test Teardown          FFDC On Test Case Fail

Force Tags             IPMI_Network_Config


*** Variables ***
${vlan_id}              ${10}
@{vlan_ids}             ${20}  ${30}
${interface}            eth0
${ip}                   10.0.0.1
${initial_lan_config}   &{EMPTY}
${vlan_resource}        ${NETWORK_MANAGER}action/VLAN

*** Test Cases ***

Verify IPMI Inband Network Configuration
    [Documentation]  Verify BMC network configuration via inband IPMI.
    [Tags]  Verify_IPMI_Inband_Network_Configuration
    [Teardown]  Run Keywords  Restore Configuration  AND  FFDC On Test Case Fail

    Redfish Power On

    Set IPMI Inband Network Configuration  10.10.10.10  255.255.255.0  10.10.10.10
    Sleep  10

    ${lan_print_output}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Valid Value  lan_print_output['IP Address']  ["10.10.10.10"]
    Valid Value  lan_print_output['Subnet Mask']  ["255.255.255.0"]
    Valid Value  lan_print_output['Default Gateway IP']  ["10.10.10.10"]


Disable VLAN Via IPMI When Multiple VLAN Exist On BMC
    [Documentation]  Disable  VLAN Via IPMI When Multiple VLAN Exist On BMC.
    [Tags]   Disable_VLAN_Via_IPMI_When_LAN_And_VLAN_Exist_On_BMC
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Create VLAN Via IPMI  off  AND  Restore Configuration

    FOR  ${id}  IN  @{vlan_ids}
      @{data_vlan_id}=  Create List  ${interface}  ${id}
      ${data}=  Create Dictionary   data=@{data_vlan_id}
      ${resp}=  OpenBMC Post Request  ${vlan_resource}  data=${data}
    END

    Create VLAN Via IPMI  off

    ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Valid Value  lan_config['802.1q VLAN ID']  ['Disabled']


Configure IP On VLAN Via IPMI
    [Documentation]   Configure IP On VLAN Via IPMI.
    [Tags]  Configure_IP_On_VLAN_Via_IPMI
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Create VLAN Via IPMI  off  AND  Restore Configuration

    Create VLAN Via IPMI  ${vlan_id}

    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} ipaddr ${ip}  login_host=${0}

    ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Valid Value  lan_config['802.1q VLAN ID']  ['${vlan_id}']
    Valid Value  lan_config['IP Address']  ["${ip}"]


Create VLAN Via IPMI When LAN And VLAN Exist On BMC
    [Documentation]  Create VLAN Via IPMI When LAN And VLAN Exist On BMC.
    [Tags]   Create_VLAN_Via_IPMI_When_LAN_And_VLAN_Exist_On_BMC
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Create VLAN Via IPMI  off  AND  Restore Configuration

    @{data_vlan_id}=  Create List  ${interface}  ${vlan_id}
    ${data}=  Create Dictionary   data=@{data_vlan_id}
    ${resp}=  OpenBMC Post Request  ${vlan_resource}  data=${data}

    Create VLAN Via IPMI  ${vlan_id}

    ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Valid Value  lan_config['802.1q VLAN ID']  ['${vlan_id}']


Create VLAN Via IPMI And Verify
    [Documentation]  Create and verify VLAN via IPMI.
    [Tags]  Create_VLAN_Via_IPMI_And_Verify
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Create VLAN Via IPMI  off  AND  Restore Configuration

    Create VLAN Via IPMI  ${vlan_id}

    ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Valid Value  lan_config['802.1q VLAN ID']  ['${vlan_id}']
    Valid Value  lan_config['IP Address']  ${network_configurations[0]['Address']}
    Valid Value  lan_config['Subnet Mask']  ${network_configurations[0]['SubnetMask']}


Test Disable VLAN Via IPMI
    [Documentation]  Disable VLAN and verify via IPMI.
    [Tags]  Test_Disable_VLAN_Via_IPMI
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Create VLAN Via IPMI  off  AND  Restore Configuration

    Create VLAN Via IPMI  ${vlan_id}
    Create VLAN Via IPMI  off

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ['Disabled']


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
    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} ipaddr ${ip}  login_host=${0}
    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} netmask ${netmask}  login_host=${0}
    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} defgw ipaddr ${gateway}  login_host=${0}


Restore Configuration
    [Documentation]  Restore the configuration to its pre-test state
    ${length}=  Get Length  ${initial_lan_config}
    Return From Keyword If  ${length} == ${0}

    Set IPMI Inband Network Configuration  ${network_configurations[0]['Address']}
    ...  ${network_configurations[0]['SubnetMask']}
    ...  ${initial_lan_config['Default Gateway IP']}  login=${0}


Suite Setup Execution
    [Documentation]  Suite Setup Execution.

    Redfish.Login

    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} ipsrc static  login_host=${1}

    @{network_configurations}=  Get Network Configuration
    Set Suite Variable  @{network_configurations}

    ${initial_lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Set Suite Variable  ${initial_lan_config}
