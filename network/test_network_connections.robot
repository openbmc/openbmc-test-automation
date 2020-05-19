*** Settings ***
Documentation          Module to test network functionality.

Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/bmc_network_utils.robot
Library                ../lib/ipmi_utils.py

Suite Setup            Suite Setup Execution
Suite Teardown         Redfish.Logout

*** Test Cases ***

Enable DHCP Via Redfish And Verify
    [Documentation]  enable DHCP via Redfish and verify
    [Tags]  Enable_DHCP_Via_Redfish_And_Verify
    [Teardown]  Restore Configuration  AND  FFDC On Test Case Fail

    Redfish.Patch  ${REDFISH_NW_ETH0_URI}  body={"DHCPv4":{"DHCPEnabled":${True}}}

    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH0_URI}
    Should Be Equal As Strings  ${resp.dict["DHCPv4"]["DHCPEnabled"]}  ${True}

*** Keywords ***

Suite Setup Execution
    [Documentation]  Suite Setup Execution.

    Redfish.Login

    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} ipsrc static  login_host=${1}

    @{network_configurations}=  Get Network Configuration
    Set Suite Variable  @{network_configurations}

    ${initial_lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Set Suite Variable  ${initial_lan_config}


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

