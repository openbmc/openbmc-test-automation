*** Settings ***

Documentation   Test OpenBMC GUI "Network settings" sub-menu of
...             "Server configuration".

Resource        ../../lib/resource.robot
Resource        ../../../lib/bmc_network_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser

*** Variables ***

${xpath_hostname_input}         //*[@data-test-id="networkSettings-input-hostname"]
${xpath_network_save_settings}  //button[@data-test-id="networkSettings-button-saveNetworkSettings"]
${xpath_default_gateway_input}  //*[@data-test-id="networkSettings-input-gateway"]
${xpath_mac_address_input}      //*[@data-test-id="networkSettings-input-macAddress"]
${xpath_static_input_ip0}       //*[@data-test-id="networkSettings-input-staticIpv4-0"]
${xpath_netmask_input_addr0}    //*[@data-test-id="networkSettings-input-subnetMask-0"]
${xpath_add_static_ip}          //button[contains(text(),"Add static IP")]
${xpath_setting_success}        //*[contains(text(),"Successfully saved network settings.")]

*** Test Cases ***

Verify BMC MAC Address
    [Documentation]  Verify MAC Address
    [Tags]  Verify_MAC_Address.

    ${mac_address}=  Get BMC MAC Address
    Textfield Value Should Be   ${xpath_mac_address_input}  ${mac_address}


Verify BMC IP Address
    [Documentation]  Verify BMC IP Address.
    [Tags]  Verify_BMC_IP_Address

    ${host_name}  ${ip_address}=  Get Host Name IP  host=${OPENBMC_HOST}
    Textfield Value Should Be  ${xpath_static_input_ip0}  ${ip_address}


Verify Default Gateway
    [Documentation]  Verify Default Gateway.
    [Tags]  Verify_BMC_IP_Address

    @{network_configurations}=  Get Network Configuration
    FOR  ${network_configuration}  IN  @{network_configurations}
      Textfield Value Should Be  ${xpath_default_gateway_input}  ${network_configuration['Gateway']}
    END


Get Netmask And Verify
    [Documentation]  Get netmask and verify.
    [Tags]  Get_Netmask_And_Verify

    @{network_configurations}=  Get Network Configuration
    FOR  ${network_configuration}  IN  @{network_configurations}
      Textfield Value Should Be  ${xpath_netmask_input_addr0}  ${network_configuration['SubnetMask']}
    END


Get Hostname And Verify
    [Documentation]  Get hostname and verify.
    [Tags]  Get_Hstname_And_Verify

    ${hostname}=  Redfish_Utils.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  HostName
    Textfield Value Should Be  ${xpath_hostname_input}  ${hostname}


Verify Network Settings From Server Configuration
    [Documentation]  Verify ability to select "Network Settings" sub-menu option
    ...  of "Server Configuration".
    [Tags]  Verify_Network_Settings_From_Server_Configuration

    Page Should Contain  IP address


Verify Hostname Text Configuration
    [Documentation]  Verify hostname text is configurable from "network settings"
    ...  sub-menu.
    [Tags]  Verify_Hostname_Text_Configuration

    Input Text  ${xpath_hostname_input}  witherspoon1
    Click Button  ${xpath_network_save_settings}
    Wait Until Page Contains Element  ${xpath_setting_success}  timeout=10
    Element Should Be Disabled  ${xpath_network_save_settings}
    Click Element  ${xpath_select_refresh_button}
    Wait Until Keyword Succeeds  15 sec  5 sec  Textfield Should Contain  ${xpath_hostname_input}
    ...  witherspoon1


Verify Default Gateway Editable
    [Documentation]  Verify default gateway text input allowed from "network
    ...  settings".
    [Tags]  Verify_Default_Gateway_Editable

    Wait Until Page Contains Element  ${xpath_default_gateway_input}
    Input Text  ${xpath_default_gateway_input}  10.6.6.7


Verify MAC Address Editable
    [Documentation]  Verify MAC address text input allowed from "network
    ...  settings".
    [Tags]  Verify_MAC_Address_Editable

    Wait Until Page Contains Element  ${xpath_mac_address_input}
    Input Text  ${xpath_mac_address_input}  AA:E2:84:14:28:79


Verify Static IP Address Editable
    [Documentation]  Verify static IP address is editable.
    [Tags]  Verify_Static_IP_Address_Editable

    ${exists}=  Run Keyword And Return Status  Wait Until Page Contains Element  ${xpath_static_input_ip0}
    Run Keyword If  '${exists}' == '${False}'
    ...  Click Element  ${xpath_add_static_ip}

    Input Text  ${xpath_static_input_ip0}  ${OPENBMC_HOST}


*** Keywords ***

Suite Setup Execution
   [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_server_configuration}
    Sleep  5sec
    Click Element  ${xpath_select_network_settings}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  network-settings

