*** Settings ***

Documentation          Module to test IPMI network functionality.
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Library                ../lib/ipmi_utils.py
Library                ../lib/gen_robot_valid.py

Test Teardown          Test Teardown Execution


*** Variables ***

${initial_lan_config}   &{EMPTY}


*** Test Cases ***

Verify IPMI Inband Network Configuration
    [Documentation]  Verify BMC network configuration via inband IPMI.
    [Tags]  Verify_IPMI_Inband_Network_Configuration

    ${initial_lan_config}=  Get LAN Print Dict  inband
    Set Suite Variable  ${initial_lan_config}

    Set IPMI Inband Network Configuration  10.10.10.10  255.255.255.0  10.10.10.10
    Sleep  10

    ${changed_lan_print}=  Get LAN Print Dict  inband
    Valid Value  changed_lan_print['IP Address']  ["10.10.10.10"]
    Valid Value  changed_lan_print['Subnet Mask']  ["255.255.255.0"]
    Valid Value  changed_lan_print['Default Gateway IP']  ["10.10.10.10"]


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


Test Teardown Execution
    [Documentation]  Do the test teardown execution.

    Restore Configuration
    FFDC On Test Case Fail
