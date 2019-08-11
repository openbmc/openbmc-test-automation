*** Settings ***

Documentation    Module to test IPMI asset tag functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Library          ../lib/ipmi_utils.py
Library          ../lib/gen_robot_valid.py

Test Teardown    Run Keywords  Restore Configuration  AND  FFDC On Test Case Fail


*** Variables ***

${initial_ip}       ${EMPTY}


*** Test Cases ***

Verify IPMI Inband Network Configuration
    [Documentation]  Verify BMC network configuration via inband IPMI.
    [Tags]  Verify_IPMI_Inband_Network_Configuration

    ${initial_ip}  ${initial_netmask}  ${initial_gateway}=
    ...  Get IPMI Inband Network Configuration
    Set Suite Variable  ${initial_ip}
    Set Suite Variable  ${initial_netmask}
    Set Suite Variable  ${initial_gateway}

    Set IPMI Inband Network Configuration  10.10.10.10  255.255.255.0  10.10.10.10
    Sleep  10

    ${changed_ip}  ${changed_netmask}  ${changed_gateway}=
    ...  Get IPMI Inband Network Configuration
    Valid Value  changed_ip  ["10.10.10.10"]
    Valid Value  changed_netmask  ["255.255.255.0"]
    Valid Value  changed_gateway  ["10.10.10.10"]


*** Keywords ***

Set IPMI Inband Network Configuration
    [Documentation]  Run sequence of standard IPMI command in-band and set
    ...              the IP configuration.
    [Arguments]  ${ip}  ${netmask}  ${gateway}  ${login}=${True}

    # Description of argument(s):
    # ip       The IP address to be set using ipmitool-inband.
    # netmask  The Netmask to be set using ipmitool-inband.
    # gateway  The Gateway address to be set using ipmitool-inband.

    Run Inband IPMI Standard Command
    ...  lan set 1 ipsrc static  login_host=${login}
    Run Inband IPMI Standard Command
    ...  lan set 1 ipaddr ${ip}  login_host=${False}
    Run Inband IPMI Standard Command
    ...  lan set 1 netmask ${netmask}  login_host=${False}
    Run Inband IPMI Standard Command
    ...  lan set 1 defgw ipaddr ${gateway}  login_host=${False}


Get IPMI Inband Network Configuration
    [Documentation]  Run IPMI command in-band and get IP configuration list.

    ${lan_print_dict}=  Get LAN Print Dict  inband
    ${ip}=  Get From Dictionary  ${lan_print_dict}  IP Address
    ${netmask}=  Get From Dictionary  ${lan_print_dict}  Subnet Mask
    ${gateway}=  Get From Dictionary  ${lan_print_dict}  Default Gateway IP
    @{list}=  BuiltIn.Create List  ${ip}  ${netmask}  ${gateway}

    [Return]  @{list}


Restore Configuration
    [Documentation]  Restore the configuration to its pre-test statue.

    Return From Keyword If  not '${initial_ip}'

    Set IPMI Inband Network Configuration
    ...  ${initial_ip}  ${initial_netmask}  ${initial_gateway}  login=${False}
