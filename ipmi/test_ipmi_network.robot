*** Settings ***

Documentation          Module to test IPMI network functionality.
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/bmc_network_utils.robot
Library                ../lib/ipmi_utils.py
Library                ../lib/gen_robot_valid.py

Test Teardown          FFDC On Test Case Fail

Force Tags             IPMI_Network


*** Variables ***

${initial_lan_config}   &{EMPTY}


*** Test Cases ***

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


Retrieve Default Gateway Via IPMI And Verify Using REST
    [Documentation]  Retrieve default gateway from LAN print using IPMI.
    [Tags]  Retrieve_Default_Gateway_Via_IPMI_And_Verify_Using_REST
    # Fetch "Default Gateway" from IPMI LAN print.
    ${default_gateway_ipmi}=  Fetch Details From LAN Print  Default Gateway IP

    # Verify "Default Gateway" using REST.
    Read Attribute  ${NETWORK_MANAGER}config  DefaultGateway
    ...  expected_value=${default_gateway_ipmi}


Retrieve MAC Address Via IPMI And Verify Using REST
    [Documentation]  Retrieve MAC Address from LAN print using IPMI.
    [Tags]  Retrieve_MAC_Address_Via_IPMI_And_Verify_Using_REST
    # Fetch "MAC Address" from IPMI LAN print.
    ${mac_address_ipmi}=  Fetch Details From LAN Print  MAC Address

    # Verify "MAC Address" using REST.
    ${mac_address_rest}=  Get BMC MAC Address
    Should Be Equal  ${mac_address_ipmi}  ${mac_address_rest}
    ...  msg=Verification of MAC address from lan print using IPMI failed.


Retrieve Network Mode Via IPMI And Verify Using REST
    [Documentation]  Retrieve network mode from LAN print using IPMI.
    [Tags]  Retrieve_Network_Mode_Via_IPMI_And_Verify_Using_REST
    # Fetch "Mode" from IPMI LAN print.
    ${network_mode_ipmi}=  Fetch Details From LAN Print  Source

    # Verify "Mode" using REST.
    ${network_mode_rest}=  Read Attribute
    ...  ${NETWORK_MANAGER}eth0  DHCPEnabled
    Run Keyword If  '${network_mode_ipmi}' == 'Static Address'
    ...  Should Be Equal  ${network_mode_rest}  ${0}
    ...  msg=Verification of network setting failed.
    ...  ELSE  IF  '${network_mode_ipmi}' == 'DHCP'
    ...  Should Be Equal  ${network_mode_rest}  ${1}
    ...  msg=Verification of network setting failed.


Retrieve IP Address Via IPMI And Verify With BMC Details
    [Documentation]  Retrieve IP address from LAN print using IPMI.
    [Tags]  Retrieve_IP_Address_Via_IPMI_And_Verify_With_BMC_Details
    # Fetch "IP Address" from IPMI LAN print.
    ${ip_addr_ipmi}=  Fetch Details From LAN Print  IP Address

    # Verify the IP address retrieved via IPMI with BMC IPs.
    ${ip_address_rest}=  Get BMC IP Info
    Validate IP On BMC  ${ip_addr_ipmi}  ${ip_address_rest}


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


Fetch Details From LAN Print
    [Documentation]  Fetch details from LAN print.
    [Arguments]  ${field_name}

    # Description of argument(s):
    # ${field_name}   Field name to be fetched from LAN print
    #                 (e.g. "MAC Address", "Source").

    ${stdout}=  Run IPMI Standard Command  lan print
    ${fetch_value}=  Get Lines Containing String  ${stdout}  ${field_name}
    ${value_fetch}=  Fetch From Right  ${fetch_value}  :${SPACE}
    [Return]  ${value_fetch}
