*** Settings ***

Documentation   Test OpenBMC GUI "Network settings" sub-menu of
...             "Server configuration".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution

*** Variables ***

${xpath_select_server_configuration}  //*[@id="nav__top-level"]/li[4]/button
${xpath_select_network_settings}  //a[@href='#/configuration/network']
${xpath_hostname_input}  //*[@id="net-config__mac"]
${xpath_network_save_settings}  //*[@id="configuration-network"]/form/section[3]/div[2]/button[1]
${xpath_continue}  //*[@id=""]/main/section/div/div[4]/button[2]
${xpath_network_config_ipv4_address}  //*[@id="ipv4-address-1"]
${xpath_default_gateway_input}  //*[@id="net-config__domain"]
${xpath_mac_address_input}  //*[@id="net-config__host"]
${xpath_ipv4-address-input}  //*[@id="net-config__ipv4-address"]
${xpath_network_DHCP_button}  //*[@id="configuration-network"]/form/section[2]/fieldset/div[1]/label/span
${xpath_network_static_button}  //*[@id="configuration-network"]/form/section[2]/fieldset/div[2]/label/span

*** Test Cases ***

Verify Network Settings From Server Configuration
    [Documentation]  Verify ability to select "Network Settings" sub-menu option
    ...  of "Server Configuration".
    [Tags]  Verify_Network_Settings_From_Server_Configuration

    Wait Until Page Contains  BMC network settings
    Page Should Contain  IPV4 settings  Common settings


Verify Hostname Text Configuration
    [Documentation]  Verify hostname text is configurable from "network settings"
    ...  sub-menu.
    [Tags]  Verify_Hostname_Text_Configuration

    Input Text  ${xpath_hostname_input}  witherspoon1
    Click Element  ${xpath_network_save_settings}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_continue}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain  witherspoon1


Verify Default Gateway Editable
    [Documentation]  Verify default gateway text input allowed from "network
    ...  settings".
    [Tags]  Verify_Default_Gateway_Editable

    Page Should Contain Element  ${xpath_default_gateway_input}
    Input Text  ${xpath_default_gateway_input}  10.6.6.7


Verify MAC Address Editable
    [Documentation]  Verify MAC address text input allowed from "network
    ...  settings".
    [Tags]  Verify_MAC_Address_Editable

    Page Should Contain Element  ${xpath_mac_address_input}
    Input Text  ${xpath_mac_address_input}  70:e2:84:14:16:6c


Verify IP Address Editable With Static IP Selection
    [Documentation]  Verify IP address editable with static IP selection.
    [Tags]  Verify_IP_Address_Editable_With_Static_IP_Selection

    Page Should Contain Element  ${xpath_network_static_button}
    Click Element  ${xpath_network_static_button}
    ${status}=  Run Keyword And Return Status  Input Text
    ...  ${xpath_ipv4-address-input}  ${OPENBMC_HOST}
    Should Be True  '${status}' == '${True}'


Verify IP Address Noneditable With DHCP IP Selection
    [Documentation]  Verify IP address noneditable with DHCP IP selection.
    [Tags]  Verify_IP_Address_Noneditable_With_DHCP_IP_Selection

    Page Should Contain Element  ${xpath_network_DHCP_button}
    Click Element  ${xpath_network_DHCP_button}
    Element Should Be Disabled  ${xpath_ipv4-address-input}


*** Keywords ***

Test Setup Execution
   [Documentation]  Do test case setup tasks.

    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_server_configuration}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_network_settings}
    Wait Until Page Contains Element  ${xpath_network_config_ipv4_address}

