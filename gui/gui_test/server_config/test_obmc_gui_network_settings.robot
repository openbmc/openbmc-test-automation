*** Settings ***

Documentation   Test OpenBMC GUI "Network settings" sub-menu of
...             "Server configuration".

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/bmc_network_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser

*** Variables ***

${xpath_network_setting_heading}  //h1[text()="Network settings"]
${xpath_interface}                //h2[text()="Interface"]
${xpath_system}                   //h2[text()="System"]
${xpath_static_ipv4}              //h2[text()="Static IPv4"]
${xpath_static_dns}               //h2[text()="Static DNS"]
${xpath_hostname_input}           //*[@data-test-id="networkSettings-input-hostname"]
${xpath_network_save_settings}    //button[@data-test-id="networkSettings-button-saveNetworkSettings"]
${xpath_default_gateway_input}    //*[@data-test-id="networkSettings-input-gateway"]
${xpath_mac_address_input}        //*[@data-test-id="networkSettings-input-macAddress"]
${xpath_static_input_ip0}         //*[@data-test-id="networkSettings-input-staticIpv4-0"]
${xpath_add_static_ip}            //button[contains(text(),"Add static IP")]
${xpath_setting_success}          //*[contains(text(),"Successfully saved network settings.")]
${xpath_add_dns_server}           //button[contains(text(),"Add DNS server")]
${xpath_network_interface}        //*[@data-test-id="networkSettings-select-interface"]
${xpath_input_netmask_addr0}      //*[@data-test-id="networkSettings-input-subnetMask-0"]
${xpath_delete_static_ip}         //*[@title="Delete IPv4 row"]
${xpath_input_dns_server}         //*[@data-test-id="networkSettings-input-dnsAddress-0"]
${xpath_delete_dns_server}        //*[@title="Delete DNS row"]
${xpath_ip_table}                 //*[@aria-colcount="3"]

@{static_name_servers}            10.10.10.10
@{null_value}                     null
@{empty_dictionary}               {}
@{string_value}                   aa.bb.cc.dd
@{special_char_value}             @@@.%%.44.11

@{test_ipv4_addr}                 10.7.7.7
@{test_subnet_mask}               255.255.0.0

# Valid netmask is 4 bytes long and has continuous block of 1s.
# Maximum valid value in each octet is 255 and least value is 0.
@{alpha_netmask}                  ff.ff.ff.ff
# Maximum value of octet in netmask is 255.
@{out_of_range_netmask}           255.256.255.0
@{more_byte_netmask}              255.255.255.0.0
@{lowest_netmask}                 128.0.0.0

*** Test Cases ***

Verify Navigation To Network Settings Page
    [Documentation]  Verify navigation to network settings page.
    [Tags]  Verify_Navigation_To_Network_Settings_Page

    Page Should Contain Element  ${xpath_network_setting_heading}


Verify Existence Of All Sections In Network Settings Page
    [Documentation]  Verify existence of all sections in network settings page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Network_Settings_Page

    Page Should Contain Element  ${xpath_interface}
    Page Should Contain Element  ${xpath_system}
    Page Should Contain Element  ${xpath_static_ipv4}
    Page Should Contain Element  ${xpath_static_dns}
    Page Should Contain Button   ${xpath_delete_static_ip}


Verify Existence Of All Buttons In Network Settings Page
    [Documentation]  Verify existence of all buttons in network settings page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Network_Settings_Page

    Page Should Contain Element  ${xpath_add_static_ip}
    Page Should Contain Element  ${xpath_add_dns_server}


Verify Network Settings From Server Configuration
    [Documentation]  Verify ability to select "Network Settings" sub-menu option
    ...  of "Server Configuration".
    [Tags]  Verify_Network_Settings_From_Server_Configuration

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
    FOR  ${network_configuration}  IN  @{network_configurations}
      Textfield Value Should Be  ${xpath_static_input_ip0}  ${network_configuration["Address"]}
      Textfield Value Should Be  ${xpath_input_netmask_addr0}  ${network_configuration['SubnetMask']}
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
    [Setup]  Test Setup Execution
    [Tags]  Configure_And_Verify_Static_IP_Address
    [Teardown]  Run Keywords  Delete And Verify Static IP Address On BMC
    ...  AND  Test Teardown Execution

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
    [Setup]  Test Setup Execution
    [Tags]  Modify_IP_Address_And_Verify
    [Teardown]  Run Keywords  Delete And Verify Static IP Address On BMC
    ...  AND  Test Teardown Execution

    ${test_ipv4_addr2}=  Create List  10.7.7.8
    Add Static IP Address And Verify  ${test_ipv4_addr}  ${test_subnet_mask}
    Update IP Address And Verify  ${test_ipv4_addr}  ${test_ipv4_addr2}  ${test_subnet_mask}


Configure Netmask And Verify
    [Documentation]  Configure and verify more byte netmask.
    [Tags]  Configure_And_Verify_More_Byte_Netmask
    [Setup]  Test Setup Execution
    [Template]  Add Static IP Address And Verify
    [Teardown]  Run Keywords  Delete And Verify Static IP Address On BMC
    ...  AND  Test Teardown Execution

    # ip_addresses      subnet_masks             expected_status
    ${test_ipv4_addr}   ${lowest_netmask}        Valid format
    ${test_ipv4_addr}   ${more_byte_netmask}     Invalid format
    ${test_ipv4_addr}   ${alpha_netmask}         Invalid format
    ${test_ipv4_addr}   ${out_of_range_netmask}  Invalid format

*** Keywords ***

Suite Setup Execution
   [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_server_configuration}
    Click Element  ${xpath_select_network_settings}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  network-settings
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
    [Teardown]  Click Element  ${xpath_refresh_button}

    # Description of the argument(s):
    # static_name_servers  A list of static name server IPs to be
    #                      configured on the BMC.
    # expected_status      Expected status while adding DNS server address
    # ...                  (e.g. Invalid format / Field required).

    Wait Until Page Contains Element  ${xpath_add_dns_server}
    ${length}=  Get Length   ${static_name_servers}
    FOR  ${i}  IN RANGE  ${length}
      Click Button  ${xpath_add_dns_server}
      Input Text  //*[@data-test-id="networkSettings-input-dnsAddress-${i}"]
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
       Page Should Contain Element  //*[@data-test-id="networkSettings-input-dnsAddress-${i}"]
       Textfield Value Should Be   //*[@data-test-id="networkSettings-input-dnsAddress-${i}"]
       ...  ${static_name_servers}[${i}]
    END

Add Static IP Address And Verify
    [Documentation]  Add static IP on BMC and verify.
    [Arguments]  ${ip_addresses}  ${subnet_masks}  ${expected_status}=Valid format

    # Description of argument(s):
    # ip_addresses         A list of IP address to be added (e.g. ["10.7.7.7"]).
    # subnet_masks         A list of Subnet mask for the IP to be added (e.g. ["255.255.0.0"]).
    # expected_status      Expected status while adding static ipv4 address
    # ....                (e.g. Invalid format / Field required).

    ${ip_count}=  Get Length  ${ip_addresses}
    FOR  ${i}  IN RANGE  ${ip_count}
       ${ip_location}=  Evaluate  ${i} + ${1}
       Wait Until Element Is Enabled  ${xpath_add_static_ip}
       Click Button  ${xpath_add_static_ip}
       Wait Until Element Is Enabled  //*[@data-test-id="networkSettings-input-staticIpv4-${ip_location}"]
       Wait Until Element Is Enabled  //*[@data-test-id="networkSettings-input-subnetMask-${ip_location}"]
       Input Text  //*[@data-test-id="networkSettings-input-staticIpv4-${ip_location}"]  ${ip_addresses}[${i}]
       Input Text  //*[@data-test-id="networkSettings-input-subnetMask-${ip_location}"]  ${subnet_masks}[${i}]
    END

    Click Button  ${xpath_network_save_settings}
    Run keyword if  '${expected_status}' != 'Valid format'
    ...  Run keywords  Page Should Contain  ${expected_status}  AND  Return From Keyword
    Wait Until Page Contains Element  ${xpath_setting_success}  timeout=15
    Sleep  ${NETWORK_TIMEOUT}s
    Click Element  ${xpath_refresh_button}
    Verify IP And Netmask On BMC Using GUI  ${ip_addresses}  ${subnet_masks}

Delete And Verify Static IP Address On BMC
    [Documentation]  Delete static IP address and verify

    ${all_match_elements}=  Get Element Count  ${xpath_delete_static_ip}
    FOR  ${element}  IN RANGE  ${all_match_elements}
      ${ip_location}=  Evaluate  ${element} + ${1}
      Delete Static IPv4 Addresses Except BMC IP  ${element}
      ${status}=  Run Keyword And Return Status  Page Should Contain Textfield
      ...  //*[@data-test-id="networkSettings-input-staticIpv4-${ip_location}"]
      Exit For Loop IF  "${status}" == "${False}"
    END

    Click Button  ${xpath_network_save_settings}
    Wait Until Page Contains Element  ${xpath_setting_success}  timeout=15
    ${all_match_elements}=  Get Element Count  ${xpath_delete_static_ip}
    Should Be Equal  ${all_match_elements}  ${1}
    Textfield Value Should Be  ${xpath_static_input_ip0}  ${BMC_IP}
    Sleep  ${NETWORK_TIMEOUT}s
    Ping Host  ${OPENBMC_HOST}
    Validate Network Config On BMC

Delete Static IPv4 Addresses Except BMC IP
    [Documentation]  Delete static IP addresses from IPv4 section on GUI except BMC IP.
    [Arguments]   ${element}

    # Description of argument(s):
    # element          IP address location on GUI(e.g. 0 or 1).

    ${ip_location}=  Evaluate  ${element} + ${1}
    Wait Until Element Is Enabled  //*[@data-test-id="networkSettings-input-staticIpv4-${element}"]
    ${input_ip}=  Get Value  //*[@data-test-id="networkSettings-input-staticIpv4-${element}"]
    Continue For Loop If  "${BMC_IP}" == "${input_ip}"  
    Click Button  ${xpath_ip_table}/tbody/tr[${ip_location}]/td[3]/span/button

    # Get delete ip elements.
    ${delete_ip_elements}=  Get Element Count  ${xpath_delete_static_ip}

    # Delete IP Address on BMC if avilable more than 1.
    Run Keyword If  ${delete_ip_elements} != ${1}
    ...  Delete Static IPv4 Addresses Except BMC IP  ${element}

Test Setup Execution
    [Documentation]  Get and delete existing IPv4 addresses and netmask if any..

    ${ip_data}=  Create List
    ${netmask_data}=  Create List

    # Get all IPv4 addresses and netmask on BMC.
    ${network_configurations}=  Get Network Configuration
    FOR  ${network_configuration}  IN  @{network_configurations}
      Continue For Loop If  '${BMC_IP}' == '${network_configuration['Address']}'
      Append To List  ${ip_data}  ${network_configuration['Address']}
      Append To List  ${netmask_data}  ${network_configuration['SubnetMask']}
    END
    Set Suite Variable  ${ip_data}
    Set Suite Variable  ${netmask_data}

    # Delete existing static IPv4 addresses and netmask if avilable.
    Run keyword If  ${ip_data} != @{empty} and ${netmask_data} != @{empty}
    ...  Delete And Verify Static IP Address On BMC


Test Teardown Execution
    [Documentation]  Restore existing IPv4 addresses and netmasks.

    ${ip_length}=  Get Length  ${ip_data}
    ${netmask_length}=  Get Length  ${netmask_data}

    # Restore existing IPv4 addresses and netmasks if any..
    Run keyword If  ${ip_length} != ${0} and ${netmask_length} != ${0}
    ...  Add Static IP Address And Verify  ${ip_data}  ${netmask_data}


Verify IP And Netmask On BMC Using GUI
    [Documentation]  Verify IP and netmask on GUI.
    [Arguments]   ${ip_addresses}  ${subnet_masks}

    # Description of argument(s):
    # ip_addresses         A list of IP address to be added (e.g. ["10.7.7.7"]).
    # subnet_masks         A list of Subnet mask for the IP to be added (e.g. ["255.255.0.0]").

    ${ip_count}=  Get Length  ${ip_addresses}
    FOR  ${i}  IN RANGE  ${ip_count}
       ${input_ip}=  Get Value  //*[@data-test-id="networkSettings-input-staticIpv4-${i}"]
       Continue For Loop If  '${BMC_IP}' == '${input_ip}'
       Textfield Value Should Be  //*[@data-test-id="networkSettings-input-staticIpv4-${i}"]
       ...  ${ip_addresses}[${i}]
       Textfield Value Should Be  //*[@data-test-id="networkSettings-input-subnetMask-${i}"]
       ...  ${subnet_masks}[${i}]
    END
    Validate Network Config On BMC

Update IP Address And Verify
    [Arguments]  ${ip}  ${new_ip}  ${netmask}

    ${ip_count}=  Get Length  ${ip}
    FOR  ${i}  IN RANGE  ${ip_count}
      ${input_ip}=  Get Value  //*[@data-test-id="networkSettings-input-staticIpv4-${i}"]
      Continue For Loop If  '${BMC_IP}' == '${input_ip}'
      Run Keyword If  '${ip[${i}]}' == '${input_ip}'  
      ...  Run Keywords  Clear Element Text  //*[@data-test-id="networkSettings-input-staticIpv4-${i}"]
      ...  AND  Input Text  //*[@data-test-id="networkSettings-input-staticIpv4-${i}"]  ${new_ip}[${i}]
    END

    Click Button  ${xpath_network_save_settings}
    Wait Until Page Contains Element  ${xpath_setting_success}  timeout=15
    Sleep  ${NETWORK_TIMEOUT}s
    Click Element  ${xpath_refresh_button}
    Verify IP And Netmask On BMC Using GUI  ${new_ip}  ${netmask}
    Validate Network Config On BMC

