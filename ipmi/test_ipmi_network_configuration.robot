*** Settings ***

Documentation          Module to test IPMI network functionality.
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/bmc_network_utils.robot
Library                ../lib/ipmi_utils.py
Library                ../lib/gen_robot_valid.py
Library                ../lib/var_funcs.py
Library                ../lib/bmc_network_utils.py
Variables              ../data/ipmi_raw_cmd_table.py

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


Create VLAN Via IPMI
    [Documentation]  Create and verify VLAN via IPMI.
    [Tags]  Create_VLAN_Via_IPMI_And_Verify
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Create VLAN Via IPMI  off  AND  Restore Configuration

    Create VLAN Via IPMI  ${vlan_id}

    ${lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Valid Value  lan_config['802.1q VLAN ID']  ['${vlan_id}']
    Valid Value  lan_config['IP Address']  ['${network_configurations[0]['Address']}']
    Valid Value  lan_config['Subnet Mask']  ['${network_configurations[0]['SubnetMask']}']


Create VLAN Via IPMI And Disable VLAN
    [Documentation]  Disable VLAN and verify via IPMI.
    [Tags]  Test_Disable_VLAN_Via_IPMI
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Create VLAN Via IPMI  off  AND  Restore Configuration

    Create VLAN Via IPMI  ${vlan_id}
    Create VLAN Via IPMI  off

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ['Disabled']


Test Get LAN Configuration Parameters
    [Documentation]  Get LAN configuration parameters and verify.
    [Tags]  Test_Get_LAN_Configuration_Parameters
    [Template]  Get LAN Configuration Parameters

    # TODO: Add other parameters.
    # Parameter selector
    0x00
    0x01
    0x16


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


Get LAN Configuration Parameters
    [Documentation]  Test Get LAN Configuration Parameters by executing IPMI raw command with
    ...  different Parameters.
    [Arguments]  ${parameter_selector}

    # Description of argument(s):
    # parameter_selector       The parameter selector of LAN configuration.

    Run Keyword If  '${parameter_selector}' == '0x00'
    ...    Verify Get Set In Progress
    ...  ELSE IF  '${parameter_selector}' == '0x01'
    ...    Verify Cipher Suite Entry Count
    ...  ELSE IF  '${parameter_selector}' == '0x16'
    ...    Verify Authentication Type Support


Verify Get Set In Progress
    [Documentation]  Verify Get Set In Progress via IPMI raw Command.

    ${Get_Set_In_Progress}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['LAN_Config_Params']['Get'][0]} ${CHANNEL_NUMBER} 0x00 0x00 0x00

    ${Get_Set_In_Progress}=  Split String  ${Get_Set_In_Progress}

    # 00b = set complete.
    # 01b = set in progress.
    Should Contain Any  ${Get_Set_In_Progress[1]}  00  01


Verify Cipher Suite Entry Count
    [Documentation]  Verify cipher suite entry count via IPMI raw Command.

    ${cipher_suite_entry_count}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['LAN_Config_Params']['Get'][0]} ${CHANNEL_NUMBER} 0x16 0x00 0x00
    ${cipher_suite_entry_count}=  Split String  ${cipher_suite_entry_count}

    # Convert minor cipher suite entry count from BCD format to integer. i.e. 01 to 1
    ${cipher_suite_entry_count[1]}=  Convert To Integer  ${cipher_suite_entry_count[1]}
    ${cnt}=  Get length  ${valid_ciphers}

    should be Equal  ${cipher_suite_entry_count[1]}  ${cnt}


Verify Authentication Type Support
    [Documentation]  Verify authentication type support via IPMI raw Command.

    ${authentication_type_support}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['LAN_Config_Params']['Get'][0]} ${CHANNEL_NUMBER} 0x01 0x00 0x00

    ${authentication_type_support}=  Split String  ${authentication_type_support}
    # All bits:
    # 1b = supported
    # 0b = authentication type not available for use
    # [5] - OEM proprietary (per OEM identified by the IANA OEM ID in the RMCP Ping Response)
    # [4] - straight password / key
    # [3] - reserved
    # [2] - MD5
    # [1] - MD2
    # [0] - none
    Should Contain Any  ${authentication_type_support[1]}  00  01  02  03  04  05
