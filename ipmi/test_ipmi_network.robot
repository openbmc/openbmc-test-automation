*** Settings ***

Documentation          Module to test IPMI network functionality.
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Library                ../lib/ipmi_utils.py
Library                ../lib/gen_robot_valid.py

Test Teardown          FFDC On Test Case Fail

Force Tags             IPMI_Network


*** Variables ***

${initial_lan_config}   &{EMPTY}


*** Test Cases ***

Retrieve IP Address Via IPMI And Verify Using Redfish
    [Documentation]  Retrieve IP address using IPMI and verify using Redfish.
    [Tags]  Retrieve_IP_Address_Via_IPMI_And_Verify_Using_Redish

    ${lan_print_ipmi}=  Get LAN Print Dict

    # Fetch IP address list using redfish.
    ${ip_list_redfish}=  Create List
    Redfish.Login
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH0_URI}
    @{network_config_redfish}=  Get From Dictionary  ${resp.dict}  IPv4StaticAddresses
    : FOR  ${network_config_redfish}  IN  @{network_config_redfish}
    \  Append To List  ${ip_list_redfish}  ${network_config_redfish['Address']}

    Valid Value  lan_print_ipmi['IP Address']  ${ip_list_redfish}


Retrieve Default Gateway Via IPMI And Verify Using Redfish
    [Documentation]  Retrieve default gateway via IPMI and verify using Redfish.
    [Tags]  Retrieve_Default_Gateway_Via_IPMI_And_Verify_Using_Redfish

    ${lan_print_ipmi}=  Get LAN Print Dict

    # Fetch gateway address list using redfish.
    ${gateway_list_redfish}=  Create List
    Redfish.Login
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH0_URI}
    @{network_config_redfish}=  Get From Dictionary  ${resp.dict}  IPv4StaticAddresses
    : FOR  ${network_config_redfish}  IN  @{network_config_redfish}
    \  Append To List  ${gateway_list_redfish}  ${network_config_redfish['Gateway']}

    Valid Value  lan_print_ipmi['Default Gateway IP']  ${gateway_list_redfish}


Retrieve MAC Address Via IPMI And Verify Using Redfish
    [Documentation]  Retrieve MAC address via IPMI and verify using Redfish.
    [Tags]  Retrieve_MAC_Address_Via_IPMI_And_Verify_Using_Redfish

    ${lan_print_ipmi}=  Get LAN Print Dict

    Redfish.Login
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH0_URI}
    ${mac_address_redfish}=  Get From Dictionary  ${resp.dict}  MACAddress

    Valid Value  lan_print_ipmi['MAC Address']  ${mac_address_redfish}


Verify IPMI Inband Network Configuration
    [Documentation]  Verify BMC network configuration via inband IPMI.
    [Tags]  Verify_IPMI_Inband_Network_Configuration
    [Teardown]  Run Keywords  Restore Configuration  AND  FFDC On Test Case Fail

    Redfish Power On
    ${initial_lan_config}=  Get LAN Print Dict  inband
    Set Suite Variable  ${initial_lan_config}

    Set IPMI Inband Network Configuration  10.10.10.10  255.255.255.0  10.10.10.10
    Sleep  10

    ${lan_print_output}=  Get LAN Print Dict  inband
    Valid Value  lan_print_output['IP Address']  ["10.10.10.10"]
    Valid Value  lan_print_output['Subnet Mask']  ["255.255.255.0"]
    Valid Value  lan_print_output['Default Gateway IP']  ["10.10.10.10"]


*** Keywords ***

Set IPMI Inband Network Configuration
    [Documentation]  Run sequence of standard IPMI command in-band and set
    ...              the IP configuration.
    [Arguments]  ${ip}  ${netmask}  ${gateway}  ${login}=${1}

    # Description of argument(s):
    # ip       The IP address to be set using ipmitool-inband.
    # netmask  The Netmask to be set using ipmitool-inband.
    # gateway  The Gateway address to be set using ipmitool-inband.

    Run Inband IPMI Standard Command
    ...  lan set 1 ipsrc static  login_host=${login}
    Run Inband IPMI Standard Command
    ...  lan set 1 ipaddr ${ip}  login_host=${0}
    Run Inband IPMI Standard Command
    ...  lan set 1 netmask ${netmask}  login_host=${0}
    Run Inband IPMI Standard Command
    ...  lan set 1 defgw ipaddr ${gateway}  login_host=${0}


Restore Configuration
    [Documentation]  Restore the configuration to its pre-test state
    ${length}=  Get Length  ${initial_lan_config}
    Return From Keyword If  ${length} == ${0}

    Set IPMI Inband Network Configuration  ${initial_lan_config['IP Address']}
    ...  ${initial_lan_config['Subnet Mask']}
    ...  ${initial_lan_config['Default Gateway IP']}  login=${0}

