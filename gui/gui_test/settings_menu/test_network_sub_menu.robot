*** Settings ***

Documentation   Test OpenBMC GUI "Network" sub-menu of "Settings".

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/bmc_network_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser

*** Variables ***

${xpath_network_heading}          //h1[text()="Network"]
${xpath_interface}                //h2[text()="Interface"]
${xpath_system}                   //h2[text()="System"]
${xpath_static_ipv4}              //h2[text()="IPV4"]
${xpath_static_dns}               //h2[text()="Static DNS"]
${xpath_hostname_input}           //*[@data-test-id="network-input-hostname"]
${xpath_network_save_settings}    //button[@data-test-id="network-button-saveNetworkSettings"]
${xpath_default_gateway_input}    //*[@data-test-id="network-input-gateway"]
${xpath_mac_address_input}        //*[@data-test-id="network-input-macAddress"]
${xpath_static_input_ip0}         //*[@data-test-id="network-input-staticIpv4-0"]
${xpath_static_input_ip1}         //*[@data-test-id="network-input-staticIpv4-1"]
${xpath_add_static_ip}            //button[contains(text(),"Add static IP")]
${xpath_setting_success}          //*[contains(text(),"Successfully saved network settings.")]
${xpath_add_dns_server}           //button[contains(text(),"Add DNS server")]
${xpath_network_interface}        //*[@data-test-id="network-select-interface"]
${xpath_input_netmask_addr0}      //*[@data-test-id="network-input-subnetMask-0"]
${xpath_input_netmask_addr1}      //*[@data-test-id="network-input-subnetMask-1"]
${xpath_delete_static_ip}         //*[@title="Delete IPv4 row"]
${xpath_input_dns_server}         //*[@data-test-id="network-input-dnsAddress-0"]
${xpath_delete_dns_server}        //*[@title="Delete DNS row"]
${xpath_delete_static_ip}         //*[@title="Delete IPv4 row"]

@{static_name_servers}            10.10.10.10
@{null_value}                     null
@{empty_dictionary}               {}
@{string_value}                   aa.bb.cc.dd
@{special_char_value}             @@@.%%.44.11

${test_ipv4_addr}                 10.7.7.7
${test_ipv4_addr2}                10.7.7.8
${test_subnet_mask}               255.255.0.0

# Valid netmask is 4 bytes long and has continuous block of 1s.
# Maximum valid value in each octet is 255 and least value is 0.
# Maximum value of octet in netmask is 255.
${alpha_netmask}                  ff.ff.ff.ff
${out_of_range_netmask}           255.256.255.0
${more_byte_netmask}              255.255.255.0.0
${lowest_netmask}                 128.0.0.0
${test_hostname}                  openbmc

*** Test Cases ***

Verify Navigation To Network Page
    [Documentation]  Verify navigation to network page.
    [Tags]  Verify_Navigation_To_Network_Page

    Page Should Contain Element  ${xpath_network_heading}


Verify Existence Of All Sections In Network Page
    [Documentation]  Verify existence of all sections in network settings page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Network_Page

    Page Should Contain Element  ${xpath_interface}
    Page Should Contain Element  ${xpath_system}
    Page Should Contain Element  ${xpath_static_ipv4}
    Page Should Contain Element  ${xpath_static_dns}
    Page Should Contain Button   ${xpath_delete_static_ip}


Verify Existence Of All Buttons In Network Page
    [Documentation]  Verify existence of all buttons in network page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Network_Page

    Page Should Contain Element  ${xpath_add_static_ip}
    Page Should Contain Element  ${xpath_add_dns_server}


Verify Network From Server Configuration
    [Documentation]  Verify ability to select "Network" sub-menu option
    ...  of "Settings".
    [Tags]  Verify_Network_From_Server_Configuration

    Page Should Contain  IP address


Verify Hostname Text Configuration
    [Documentation]  Verify hostname text is configurable from "network settings"
    ...  sub-menu.
    [Tags]  Verify_Hostname_Text_Configuration

    Wait Until Element Is Enabled  ${xpath_hostname_input}
    Input Text  ${xpath_hostname_input}  witherspoon1
    Click Button  ${xpath_network_save_settings}
    Wait Until Page Contains Element  ${xpath_setting_success}  timeout=10
    Wait Until Keyword Succeeds  15 sec  5 sec  Textfield Should Contain  ${xpath_hostname_input}
    ...  witherspoon1


Verify Default Gateway Editable
    [Documentation]  Verify default gateway text input allowed from "network
    ...  settings".
    [Tags]  Verify_Default_Gateway_Editable
    [Teardown]  Click Element  ${xpath_refresh_button}

    Wait Until Page Contains Element  ${xpath_default_gateway_input}
    Input Text  ${xpath_default_gateway_input}  10.6.6.7


Verify MAC Address Editable
    [Documentation]  Verify MAC address text input allowed from "network
    ...  settings".
    [Tags]  Verify_MAC_Address_Editable
    [Teardown]  Click Element  ${xpath_refresh_button}

    Wait Until Element Is Enabled  ${xpath_mac_address_input}
    Input Text  ${xpath_mac_address_input}  AA:E2:84:14:28:79


Verify Static IP Address Editable
    [Documentation]  Verify static IP address is editable.
    [Tags]  Verify_Static_IP_Address_Editable
    [Teardown]  Click Element  ${xpath_refresh_button}

    ${exists}=  Run Keyword And Return Status  Wait Until Page Contains Element  ${xpath_static_input_ip0}
    Run Keyword If  '${exists}' == '${False}'
    ...  Click Element  ${xpath_add_static_ip}

    Input Text  ${xpath_static_input_ip0}  ${OPENBMC_HOST}


Verify System Section In Network Setting page
    [Documentation]  Verify hostname, MAC address and default gateway
    ...  under system section of network setting page.
    [Tags]  Verify_System_Section

    ${host_name}=  Redfish_Utils.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  HostName
    Textfield Value Should Be  ${xpath_hostname_input}  ${host_name}

    ${mac_address}=  Get BMC MAC Address
    Textfield Value Should Be   ${xpath_mac_address_input}  ${mac_address}

    ${default_gateway}=  Get BMC Default Gateway
    Textfield Value Should Be  ${xpath_default_gateway_input}  ${default_gateway}


Verify Network Interface Details
    [Documentation]  Verify network interface name in network setting page.
    [Tags]  Verify_Network_Interface_Details

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface_redfish}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}
    ${ethernet_interface_gui}=  Get Text  ${xpath_network_interface}
    Should Contain  ${ethernet_interface_gui}  ${ethernet_interface_redfish}


Verify Network Static IPv4 Details
    [Documentation]  Verify network static IPv4 details.
    [Tags]  Verify_Network_static_IPv4_Details

    @{network_configurations}=  Get Network Configuration
    ${ip_addresses}=  Get Static IPv4 Addresses From GUI
    FOR  ${network_configuration}  IN  @{network_configurations}
      List Should Contain Value  ${ip_addresses}  ${network_configuration["Address"]}
    END


Configure Invalid Network Addresses And Verify
    [Documentation]  Configure invalid network addresses and verify.
    [Tags]  Configure_Invalid_Network_Addresses_And_Verify
    [Template]  Configure Invalid Network Address And Verify

    # locator                        invalid_address
    ${xpath_mac_address_input}       A.A.A.A
    ${xpath_default_gateway_input}   a.b.c.d
    ${xpath_static_input_ip0}        a.b.c.d
    ${xpath_input_netmask_addr0}     255.256.255.0


Configure And Verify Empty Network Addresses
    [Documentation]  Configure and verify empty network addresses.
    [Tags]  Configure_And_Verify_Empty_Network_Addresses
    [Template]  Configure Invalid Network Address And Verify

    # locator                       invalid_address  expected_error
    ${xpath_mac_address_input}        ${empty}       Field required
    ${xpath_default_gateway_input}    ${empty}       Field required
    ${xpath_static_input_ip0}         ${empty}       Field required
    ${xpath_input_netmask_addr0}      ${empty}       Field required
    ${xpath_hostname_input}           ${empty}       Field required


Config And Verify DNS Server Via GUI
    [Documentation]  Configure DNS server and verify.
    [Tags]  Config_And_Verify_DNS_Server_Via_GUI
    [Setup]   DNS Test Setup Execution
    [Teardown]   Run Keywords  Delete DNS Server And Verify  ${static_name_servers}
    ...  AND  DNS Test Teardown Execution

    Add DNS Server And Verify  ${static_name_servers}


Delete And Verify DNS Server Via GUI
    [Documentation]  Delete DNS server and verify.
    [Tags]  Delete_And_Verify_DNS_Server_Via_GUI
    [Setup]   Run Keywords  DNS Test Setup Execution  AND
    ...  Add DNS Server And Verify  ${static_name_servers}
    [Teardown]  DNS Test Teardown Execution

    Delete DNS Server And Verify  ${static_name_servers}

Configure And Verify Static IP Address
    [Documentation]  Configure and verify static ip addresses.
    [Tags]  Configure_And_Verify_Static_IP_Address
    [Teardown]  Delete And Verify Static IP Address On BMC  ${test_ipv4_addr}

    Add Static IP Address And Verify  ${test_ipv4_addr}  ${test_subnet_mask}


Configure And Verify Invalid DNS Server
    [Documentation]  Configure invalid DNS server and verify error.
    [Tags]  Configure_And_Verify_Invalid_DNS_Server
    [Template]  Add DNS Server And Verify
    [Setup]  DNS Test Setup Execution
    [Teardown]  Run Keywords  Click Element  ${xpath_refresh_button}
    ...  AND  DNS Test Teardown Execution

    # invalid_ address      expected_status
    ${string_value}         Invalid format
    ${special_char_value}   Invalid format
    ${empty_dictionary}     Field required
    ${null_value}           Invalid format

Modify IP Address And Verify
    [Documentation]  Modify IP address and verify.
    [Tags]  Modify_IP_Address_And_Verify
    [Teardown]  Delete And Verify Static IP Address On BMC  ${test_ipv4_addr2}

    Add Static IP Address And Verify  ${test_ipv4_addr}  ${test_subnet_mask}
    Update IP Address And Verify  ${test_ipv4_addr}  ${test_ipv4_addr2}


Configure Netmask And Verify
    [Documentation]  Configure and verify netmask.
    [Tags]  Configure_And_Verify_Netmask
    [Template]  Add Static IP Address And Verify
    [Teardown]  Run Keywords  Click Element  ${xpath_refresh_button}
    ...  AND  Delete And Verify Static IP Address On BMC  ${test_ipv4_addr}

    # ip_addresses      subnet_masks             expected_status
    ${test_ipv4_addr}   ${lowest_netmask}        Valid format
    ${test_ipv4_addr}   ${more_byte_netmask}     Invalid format
    ${test_ipv4_addr}   ${alpha_netmask}         Invalid format
    ${test_ipv4_addr}   ${out_of_range_netmask}  Invalid format


Configure Hostname And Verify
    [Documentation]  Configure hostname and verify.
    [Tags]  Configure_Hostname_And_Verify
    [Teardown]  Configure And Verify Network Settings
    ...  ${xpath_hostname_input}  ${hostname}

    ${hostname}=  Get Value  ${xpath_hostname_input}
    Configure And Verify Network Settings  ${xpath_hostname_input}  ${test_hostname}


*** Keywords ***

Suite Setup Execution
   [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_settings_menu}
    Click Element  ${xpath_network_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  network
    ${host_name}  ${BMC_IP}=  Get Host Name IP  host=${OPENBMC_HOST}
    Set Suite Variable  ${BMC_IP}


Configure Invalid Network Address And Verify
    [Documentation]  Configure invalid network address And verify.
    [Arguments]  ${locator}  ${invalid_address}  ${expected_error}=Invalid format
    [Teardown]  Click Element  ${xpath_refresh_button}

    # Description of the argument(s):
    # locator            Xpath to identify an HTML element on a web page.
    # invalid_address    Invalid address to be added.
    # expected_error     Expected error optionally provided in testcase
    # ....               (e.g. Invalid format / Field required)

    Wait Until Element Is Enabled  ${locator}
    Clear Element Text  ${locator}
    Input Text  ${locator}  ${invalid_address}
    Click Element  ${xpath_network_save_settings}
    Page Should Contain  ${expected_error}


Add DNS Server And Verify
    [Documentation]  Add DNS server on BMC and verify it via BMC CLI.
    [Arguments]  ${static_name_servers}   ${expected_status}=Valid format

    # Description of the argument(s):
    # static_name_servers  A list of static name server IPs to be
    #                      configured on the BMC.
    # expected_status      Expected status while adding DNS server address
    # ...                  (e.g. Invalid format / Field required).

    Wait Until Page Contains Element  ${xpath_add_dns_server}
    ${length}=  Get Length   ${static_name_servers}
    FOR  ${i}  IN RANGE  ${length}
      Click Button  ${xpath_add_dns_server}
      Input Text  //*[@data-test-id="network-input-dnsAddress-${i}"]
      ...  ${static_name_servers}[${i}]
    END

    Click Button  ${xpath_network_save_settings}
    Run keyword if  '${expected_status}' != 'Valid format'
    ...  Run keywords  Page Should Contain  ${expected_status}  AND  Return From Keyword

    Wait Until Page Contains Element  ${xpath_setting_success}  timeout=15
    Sleep  ${NETWORK_TIMEOUT}s
    Verify Static Name Server Details On GUI  ${static_name_servers}
    # Check if newly added DNS server is configured on BMC.
    ${cli_name_servers}=  CLI Get Nameservers
    List Should Contain Sub List  ${cli_name_servers}  ${static_name_servers}


Delete DNS Server And Verify
    [Documentation]  Delete static name servers.
    [Arguments]  ${static_name_servers}

    # Description of the argument(s):
    # static_name_servers  A list of static name server IPs to be
    #                      configured on the BMC.

    ${length}=  Get Length  ${static_name_servers}
    FOR  ${i}  IN RANGE   ${length}
       ${status}=  Run Keyword And Return Status
       ...  Page Should Contain Element  ${xpath_delete_dns_server}
       Exit For Loop If   "${status}" == "False"
       Wait Until Element Is Enabled  ${xpath_delete_dns_server}
       Click Button  ${xpath_delete_dns_server}
    END

    Click Button  ${xpath_network_save_settings}
    Wait Until Page Contains Element  ${xpath_setting_success}  timeout=15

    Sleep  ${NETWORK_TIMEOUT}s
    Page Should Not Contain Element  ${xpath_input_dns_server}
    # Check if all name servers deleted on BMC.
    ${nameservers}=  CLI Get Nameservers
    Should Be Empty  ${nameservers}


DNS Test Setup Execution
    [Documentation]  Do DNS test setup execution.

    ${original_name_server}=  CLI Get Nameservers
    Set Suite Variable   ${original_name_server}
    Run Keyword If  ${original_name_server} != @{EMPTY}
    ...  Delete DNS Server And Verify  ${original_name_server}


DNS Test Teardown Execution
    [Documentation]  Do DNS test teardown execution.

    Run Keyword If  ${original_name_server} != @{EMPTY}
    ...  Add DNS Server And Verify  ${original_name_server}


Verify Static Name Server Details On GUI
    [Documentation]  Verify static name servers on GUI.
    [Arguments]   ${static_name_servers}

    # Description of the argument(s):
    # static_name_servers  A list of static name server IPs to be
    #                      configured on the BMC.

    ${length}=  Get Length  ${static_name_servers}
    FOR  ${i}  IN RANGE  ${length}
       Page Should Contain Element  //*[@data-test-id="network-input-dnsAddress-${i}"]
       Textfield Value Should Be   //*[@data-test-id="network-input-dnsAddress-${i}"]
       ...  ${static_name_servers}[${i}]
    END

Add Static IP Address And Verify
    [Documentation]  Add static IP on BMC and verify.
    [Arguments]  ${ip_address}  ${subnet_mask}  ${expected_status}=Valid format

    # Description of argument(s):
    # ip_address          IP address to be added (e.g. 10.7.7.7).
    # subnet_masks        Subnet mask for the IP to be added (e.g. 255.255.0.0).
    # expected_status     Expected status while adding static ipv4 address
    # ....                (e.g. Invalid format / Field required).

    ${available_ip_addresses}=  Get Static IPv4 Addresses From GUI

    # New IP address location is GUI is equivalent to the available IP address
    # in Redfish. i.e. if two IP address are available in GUI then location
    # on IP address in GUI is also 2.
    ${location}=  Get Length  ${available_ip_addresses}
    Wait Until Element Is Enabled  ${xpath_add_static_ip}
    Click Button  ${xpath_add_static_ip}

    Input Text
    ...  //*[@data-test-id="network-input-staticIpv4-${location}"]  ${ip_address}
    Input Text
    ...  //*[@data-test-id="network-input-subnetMask-${location}"]  ${subnet_mask}

    Click Button  ${xpath_network_save_settings}
    Run keyword if  '${expected_status}' != 'Valid format'
    ...  Run keywords  Page Should Contain  ${expected_status}  AND  Return From Keyword
    Wait Until Page Contains Element  ${xpath_setting_success}  timeout=15
    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains Element  ${xpath_static_input_ip0}
    Validate Network Config On BMC
    ${ip_addresses}=  Get Static IPv4 Addresses From GUI
    Should Contain  ${ip_addresses}  ${ip_address}


Delete And Verify Static IP Address On BMC
    [Documentation]  Delete static IP address and verify
    [Arguments]  ${ip_address}

    # Description of argument(s):
    # ip_address       IP address to be deleted (e.g. "10.7.7.7").

    ${ip_addresses}=  Get Static IPv4 Addresses From GUI
    Should Contain  ${ip_addresses}  ${ip_address}  msg=${ip_address} does not exist on BMC

    ${delete_ip_buttons}=  Get WebElements  ${xpath_delete_static_ip}
    FOR  ${location}  IN RANGE  len(${ip_addresses})
       ${gui_ip}=  Get Value  //*[@data-test-id="network-input-staticIpv4-${location}"]
       Run Keyword If  '${gui_ip}' == '${ip_address}' and '${gui_ip}' != '${BMC_IP}'
       ...  Run Keywords  Click Element  ${delete_ip_buttons}[${location}]
       ...  AND  Exit For Loop
    END

    Click Button  ${xpath_network_save_settings}
    Wait Until Page Contains Element  ${xpath_setting_success}  timeout=15
    Wait Until Page Contains Element  ${xpath_static_input_ip0}
    Validate Network Config On BMC
    ${ip_addresses}=  Get Static IPv4 Addresses From GUI
    Should Not Contain  ${ip_addresses}  ${ip_address}


Update IP Address And Verify
    [Documentation]  Update and verify static IP address on BMC.
    [Arguments]  ${ip}  ${new_ip}

    # Description of argument(s):
    # ip                  IP address to be replaced (e.g. "10.7.7.7").
    # new_ip              New IP address to be configured.

    ${ip_addresses}=  Get Static IPv4 Addresses From GUI
    Should Contain  ${ip_addresses}  ${ip}  msg=${ip} does not exist on BMC

    FOR  ${location}  IN RANGE  len(${ip_addresses})
       ${gui_ip}=  Get Value  //*[@data-test-id="network-input-staticIpv4-${location}"]
       Run Keyword If  '${gui_ip}' == '${ip}'
       ...  Run Keywords
       ...  Clear Element Text  //*[@data-test-id="network-input-staticIpv4-${location}"]
       ...  AND  Input Text
       ...  //*[@data-test-id="network-input-staticIpv4-${location}"]  ${new_ip}
       ...  AND  Exit For Loop
    END
    Click Button  ${xpath_network_save_settings}
    Wait Until Page Contains Element  ${xpath_setting_success}  timeout=15
    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains Element  ${xpath_static_input_ip0}
    Validate Network Config On BMC
    ${ip_addresses}=  Get Static IPv4 Addresses From GUI
    Should Contain  ${ip_addresses}  ${new_ip}


Get Static IPv4 Addresses From GUI
    [Documentation]  Get static IPV4 addresses from GUI.

    ${availble_ip_addresses}=  Get Network Configuration
    ${static_ipv4_addresses}=  Create List

    FOR   ${locator}   IN RANGE  len(${availble_ip_addresses})
       ${ip_address}=  Get value  //*[@data-test-id="network-input-staticIpv4-${locator}"]
       Append To List  ${static_ipv4_addresses}  ${ip_address}
    END

    [Return]  ${static_ipv4_addresses}


Configure And Verify Network Settings
    [Documentation]  Configure and verify network settings.
    [Arguments]  ${xpath}  ${nw_settings}

    # Description of argument(s):
    # xpath  xpath of the network settings.
    # nw_settings  The mac address, hostname etc.

    Wait Until Element Is Enabled  ${xpath}
    Input Text  ${xpath}  ${nw_settings}
    Click Button  ${xpath_network_save_settings}
    Wait Until Page Contains Element  ${xpath_setting_success}  timeout=10
    Textfield Value Should Be  ${xpath}  ${nw_settings}

