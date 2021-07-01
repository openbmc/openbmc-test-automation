*** Settings ***
Documentation   Test BMC multiple network interface functionalities.

# User input BMC IP for the eth1.
# Use can input as  -v OPENBMC_HOST_1:xx.xxx.xx from command line.
Library         ../../lib/bmc_redfish.py  https://${OPENBMC_HOST_1}:${HTTPS_PORT}
...             ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  WITH NAME  Redfish1

Resource        ../../gui/lib/gui_resource.robot
Resource        ../../gui/lib/resource.robot
Resource        ../../lib/resource.robot
Resource        ../../lib/common_utils.robot
Resource        ../../lib/connection_client.robot
Resource        ../../lib/bmc_network_utils.robot
Resource        ../../lib/openbmc_ffdc.robot
Variables       ../gui/data/gui_variables.py

Suite Setup     Suite Setup Execution
Test Teardown   FFDC On Test Case Fail

*** Variables ***

${bmc_url}             https://${OPENBMC_HOST}
${bmc_url_1}           https://${OPENBMC_HOST_1}


*** Test Cases ***

Verify Both Interfaces BMC IP Addreeses Accessible Via SSH
    [Documentation]  Verify both interfaces (eth0, eth1) BMC IP addresses accessible via SSH.
    [Tags]  Verify_Both_Interfaces_BMC_IP_Addresses_Accessible_Via_SSH

    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  host=${OPENBMC_HOST}
    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  host=${OPENBMC_HOST_1}
    Close All Connections


Verify BMC Accessible With Both Interfaces IP Addresses Via GUI
    [Documentation]  Verify able to access BMC with both interfaces IP addresses via GUI.
    [Tags]  Verify_BMC_Accessible_With_Both_Interfaces_IP Addresses_Via_GUI
    [Teardown]   Close All Browsers

    Start Virtual Display
    ${browser_ID}=  Open Browser  ${bmc_url}  alias=tab1
    Set Window Size  1920  1080

    ${browser_ID}=  Open Browser  ${bmc_url_1}  alias=tab2
    Set Window Size  1920  1080

    Switch Browser  tab1
    BMC Login GUI
    Switch Browser  tab2
    BMC Login GUI

    Switch Browser  tab1
    Logout GUI
    Switch Browser  tab2
    Logout GUI


*** Keywords ***

Get Network Configuration Using Channel Number
    [Documentation]  Get ethernet interface.
    [Arguments]  ${channel_number}

    # Description of argument(s):
    # channel_number   Ethernet channel number, 1 is for eth0 and 2 is for eth1 (e.g. "1").

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}

    @{network_configurations}=  Get From Dictionary  ${resp.dict}  IPv4StaticAddresses
    [Return]  @{network_configurations}


Suite Setup Execution
    [Documentation]  Do suite setup task.

    Valid Value  OPENBMC_HOST_1

    # Check both interfaces are configured and reachable.
    Ping Host  ${OPENBMC_HOST}
    Ping Host  ${OPENBMC_HOST_1}


BMC Login GUI
    [Documentation]  Login to OpenBMC GUI.
    [Arguments]  ${username}=${OPENBMC_USERNAME}  ${password}=${OPENBMC_PASSWORD}

    # Description of argument(s):
    # username  The username to be used for login.
    # password  The password to be used for login.

    Wait Until Element Is Enabled  ${xpath_textbox_username}
    Input Text  ${xpath_textbox_username}  ${username}
    Input Password  ${xpath_textbox_password}  ${password}
    Click Element  ${xpath_login_button}
    Wait Until Page Contains  Overview  timeout=60s

