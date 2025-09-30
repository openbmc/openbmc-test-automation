*** Settings ***

Documentation   Test OpenBMC GUI "Network" sub-menu of "Settings".

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/bmc_network_utils.robot
Resource        ../../../lib/bmc_ipv6_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser

Test Tags      Network_Sub_Menu

*** Variables ***

${xpath_network_heading}                 //h1[text()="Network"]
${xpath_interface_settings}              //h2[text()="Interface settings"]
${xpath_network_settings}                //h2[text()="Network settings"]
${xpath_static_ipv4}                     //h2[text()="IPv4"]
${xpath_static_ipv6}                     //h2[text()="IPv6"]
${xpath_static_ipv6_default_gateway}     //h2[text()="IPv6 static default gateways"]
${xpath_domain_name_toggle}              //*[@data-test-id="networkSettings-switch-useDomainName"]
${xpath_ntp_servers_toggle}              //*[@data-test-id="networkSettings-switch-useNtp"]
${xpath_add_static_ipv4_address_button}  //button[contains(text(),"Add static IPv4 address")]
${xpath_add_static_ipv6_address_button}  //button[contains(text(),"Add static IPv6 address")]
${xpath_add_static_def_gateway_button}   //button[contains(text(),"Add IPv6 static default gateway address")]
${xpath_hostname}                        //*[@title="Edit hostname"]
${xpath_hostname_input}                  //*[@id="hostname"]
${xpath_input_ip_address}                //*[@id="ipAddress"]
${xpath_input_gateway}                   //*[@id="gateway"]
${xpath_input_subnetmask}                //*[@id="subnetMask"]
${xpath_input_ipv6address}               //*[@id="ipAddress"]
${xpath_input_prefix_length}             //*[@id="prefixLength"]
${xpath_input_addressorigin}             //*[@id="Address Origin"]
${xpath_cancel_button}                   //button[contains(text(),'Cancel')]
${xpath_delete_dns_server}               //*[@title="Delete DNS address"]
${xpath_save_button}                     //button[contains(text(),'Save')]
${xpath_dhcp_toggle_switch}              //*[@id='dhcpSwitch']
${xpath_dhcpv6_toggle_switch}            //*[@id='dhcpIpv6Switch']
${xpath_slaac_toggle_switch}             //*[@id='ipv6AutoConfigSwitch']
${xpath_lldp_toggle_switch}              //*[@id='useLLDPSwitch']
${xpath_ntp_switch_button}               //*[@id="useNtpSwitch"]/following-sibling::label
${xpath_dns_switch_button}               //*[@id="useDnsSwitch"]/following-sibling::label
${xpath_domainname_switch_button}        //*[@id="useDomainNameSwitch"]/following-sibling::label
${xpath_success_popup}                   //*[contains(text(),'Success')]/following-sibling::button
${xpath_delete_ipv4_addres}              //*[text()='${test_ipv4_addr}']/following::td[4]
...                                      //*[@title="Delete IPv4 address"]
${xpath_delete_button}                   //*[text()="Delete"]
${xpath_eth1_interface}                  //*[text()="eth1"]
${xpath_linklocalv6}                     //*[text()="LinkLocal"]
${xpath_eth0_ipv6_autoconfig_button}     (//*[@id="ipv6AutoConfigSwitch"]/following-sibling::label)[1]
${dns_server}                            10.10.10.10
${test_ipv4_addr}                        10.7.7.7
${test_ipv4_addr_1}                      10.7.7.8
${test_ipv6_addr}                        2001:db8:3333:4444:5555:6666:7777:8888
${test_ipv6_addr_1}                      2001:db8:3333:4444:5555:6666:7777:8889
${ipv4_hexword_addr}                     10.5.5.6:1A:1B:1C:1D:1E:1F
${invalid_hexadec_ipv6}                  x:x:x:x:x:x:10.5.5.6
${ipv6_multi_short}                      2001::33::111
${test_prefix_length}                    64
${out_of_range_ip}                       10.7.7.256
${string_ip}                             aa.bb.cc.dd
${negative_ip}                           10.-7.-7.-7
${less_octet_ip}                         10.3.36
${hex_ip}                                0xa.0xb.0xc.0xd
${spl_char_ip}                           @@@.%%.44.11
${test_subnet_mask}                      255.255.0.0
${alpha_netmask}                         ff.ff.ff.ff
${out_of_range_netmask}                  255.256.255.0
${more_byte_netmask}                     255.255.255.0.0
${lowest_netmask}                        128.0.0.0
${test_hostname}                         openbmc

*** Test Cases ***

Verify Navigation To Network Page
    [Documentation]  Login to GUI and navigate to the settings sub-menu network page.
    [Tags]  Verify_Navigation_To_Network_Page

    Page Should Contain Element  ${xpath_network_heading}

Verify Existence Of All Sections In Network Page
    [Documentation]  Login to GUI and navigate to the settings sub-menu network page
    ...  and confirm the page contains sections that should be accessible.
    [Tags]  Verify_Existence_Of_All_Sections_In_Network_Page

    Wait Until Page Contains Element  ${xpath_network_settings}  timeout=1min
    Page Should Contain Element  ${xpath_interface_settings}
    Page Should Contain Element  ${xpath_static_ipv4}
    Page Should Contain Element  ${xpath_static_ipv6}
    Page Should Contain Element  ${xpath_static_ipv6_default_gateway}
    Page Should Contain Element  ${xpath_static_dns}


Verify Existence Of All Buttons In Network Page
    [Documentation]  Login to GUI and navigate to the settings sub-menu network page
    ...  and confirm the page contains basic features button that should be accessible.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Network_Page

    Page Should Contain Button  ${xpath_add_static_ipv4_address_button}
    Page Should Contain Button  ${xpath_add_static_ipv6_address_button}
    Page Should Contain Button  ${xpath_add_dns_ip_address_button}
    Page Should Contain Button  ${xpath_domain_name_toggle}
    Page Should Contain Button  ${xpath_dns_servers_toggle}
    Page Should Contain Button  ${xpath_ntp_servers_toggle}
    Page Should Contain Button  ${xpath_dhcp_toggle_switch}
    Page Should Contain Button  ${xpath_dhcpv6_toggle_switch}
    Page Should Contain Button  ${xpath_slaac_toggle_switch}
    Page Should Contain Button  ${xpath_lldp_toggle_switch}


Verify Existence Of All Fields In Hostname
    [Documentation]  Login to GUI and navigate to the settings sub-menu network page
    ...  and confirm hostname contains all the fields.
    [Tags]  Verify_Existence_Of_All_Fields_In_Hostname
    [Teardown]  Cancel And Verify Network Heading

    Click Element  ${xpath_hostname}
    Wait Until Page Contains  Edit hostname  timeout=1min
    Page Should Contain Textfield  ${xpath_hostname_input}
    Page Should Contain Button  ${xpath_cancel_button}
    Page Should Contain Button  ${xpath_save_button}


Verify Existence Of All Fields In Static IP Address
    [Documentation]  Login to GUI and navigate to the settings sub-menu network page
    ...  and confirm section static IPv4 contains all the fields.
    [Tags]  Verify_Existence_Of_All_Fields_In_Static_IP_Address
    [Teardown]  Cancel And Verify Network Heading

    Wait Until Keyword Succeeds  30 sec  10 sec  Click Element  ${xpath_add_static_ipv4_address_button}
    Wait Until Page Contains  Add static IPv4 address  timeout=15s
    Page Should Contain Textfield  ${xpath_input_ip_address}
    Page Should Contain Textfield  ${xpath_input_gateway}
    Page Should Contain Textfield  ${xpath_input_subnetmask}
    Page Should Contain Button  ${xpath_cancel_button}
    Page Should Contain Button  ${xpath_add_button}


Verify Existence Of All Fields In Static IPv6 Address
    [Documentation]  Login to GUI and navigate to the settings sub-menu network page
    ...  and confirm section static IPv6 contains all the fields.
    [Tags]  Verify_Existence_Of_All_Fields_In_Static_IPv6_Address
    [Teardown]  Cancel And Verify Network Heading

    Wait Until Keyword Succeeds  30 sec  10 sec  Click Element  ${xpath_add_static_ipv6_address_button}
    Wait Until Page Contains  Add static IPv6 address  timeout=15s
    Page Should Contain Textfield  ${xpath_input_ipv6_address}
    Page Should Contain Textfield  ${xpath_input_prefix_length}
    Page Should Contain Button  ${xpath_cancel_button}
    Page Should Contain Button  ${xpath_add_button}


Verify Existence Of All Fields In IPv6 Static Default Gateway
    [Documentation]  Login to GUI and navigate to the settings sub-menu network page
    ...  and confirm section IPv6 static default gateway contains all the fields.
    [Tags]  Verify_Existence_Of_All_Fields_In_IPv6_Static_Default_Gateway
    [Teardown]  Run Keywords  Click Button  ${xpath_cancel_button}  AND
    ...  Wait Until Keyword Succeeds  10 sec  5 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_network_heading}  Network

    Wait Until Keyword Succeeds  30 sec  10 sec  Click Element  ${xpath_add_static_def_gateway_button}
    Wait Until Page Contains  Add IPv6 static default gateway address  timeout=11s
    Page Should Contain Textfield  ${xpath_input_ip_address}
    Page Should Contain Button  ${xpath_cancel_button}
    Page Should Contain Button  ${xpath_add_button}


Verify Existence Of All Fields In Static DNS
    [Documentation]  Login to GUI and navigate to the settings sub-menu network page
    ...  and confirm section static DNS contains all the fields.
    [Tags]  Verify_Existence_Of_All_Fields_In_Static_DNS
    [Teardown]  Cancel And Verify Network Heading

    Wait Until Keyword Succeeds  30 sec  10 sec  Click Element  ${xpath_add_dns_ip_address_button}
    Wait Until Page Contains  Add IP address  timeout=11s
    Page Should Contain Textfield  ${xpath_input_static_dns}
    Page Should Contain Button  ${xpath_cancel_button}
    Page Should Contain Button  ${xpath_add_button}


Configure And Verify DNS Server Via GUI
    [Documentation]  Login to GUI Network page, add DNS server IP
    ...  and verify that the page reflects server IP.
    [Tags]  Configure_And_Verify_DNS_Server_Via_GUI
    [Setup]  DNS Test Setup Execution
    [Teardown]  Run Keywords  Delete Static Name Servers  AND
    ...  Configure Static Name Servers

    Add DNS Servers And Verify  ${dns_server}


Configure Static IPv4 Netmask Via GUI And Verify
    [Documentation]  Login to GUI Network page, configure static IPv4 netmask and verify.
    [Tags]  Configure_Static_IPv4_Netmask_Via_GUI_And_Verify
    [Template]  Add Static IP Address And Verify

    # ip_addresses      subnet_masks             gateway          expected_status
    ${test_ipv4_addr}   ${lowest_netmask}        ${default_gateway}  Success
    ${test_ipv4_addr}   ${more_byte_netmask}     ${default_gateway}  Invalid format
    ${test_ipv4_addr}   ${alpha_netmask}         ${default_gateway}  Invalid format
    ${test_ipv4_addr}   ${out_of_range_netmask}  ${default_gateway}  Invalid format
    ${test_ipv4_addr}   ${test_subnet_mask}      ${default_gateway}  Success


Configure And Verify Static IP Address
    [Documentation]  Login to GUI Network page, configure static ip address and verify.
    [Tags]  Configure_And_Verify_Static_IP_Address

    Add Static IP Address And Verify  ${test_ipv4_addr}  ${test_subnet_mask}  ${default_gateway}  Success


Configure And Verify Multiple Static IP Address
    [Documentation]  Login to GUI Network page, configure multiple static IP address and verify.
    [Tags]  Configure_And_Verify_Multiple_Static_IP_Address

    Add Static IP Address And Verify  ${test_ipv4_addr}  ${test_subnet_mask}  ${default_gateway}  Success
    Add Static IP Address And Verify  ${test_ipv4_addr_1}  ${test_subnet_mask}  ${default_gateway}  Success


Configure And Verify Invalid Static IP Address
    [Documentation]  Login to GUI Network page, configure invalid static IP address and verify.
    [Tags]  Configure_And_Verify_Invalid_Static_IP_Address
    [Template]  Add Static IP Address And Verify

    # ip                 subnet_mask          gateway             status
    ${out_of_range_ip}   ${test_subnet_mask}  ${default_gateway}  Invalid format
    ${less_octet_ip}     ${test_subnet_mask}  ${default_gateway}  Invalid format
    ${string_ip}         ${test_subnet_mask}  ${default_gateway}  Invalid format
    ${negative_ip}       ${test_subnet_mask}  ${default_gateway}  Invalid format
    ${hex_ip}            ${test_subnet_mask}  ${default_gateway}  Invalid format
    ${spl_char_ip}       ${test_subnet_mask}  ${default_gateway}  Invalid format


Configure And Verify Multiple Static IPv6 Address
    [Documentation]  Login to GUI Network page, configure multiple static IPv6 address and verify.
    [Tags]  Configure_And_Verify_Multiple_Static_IPv6_Address

    Add Static IPv6 Address And Verify Via GUI  ${test_ipv6_addr}    ${test_prefix_length}  Success
    Add Static IPv6 Address And Verify Via GUI  ${test_ipv6_addr_1}  ${test_prefix_length}  Success


Configure And Verify Static IPv6 Address
    [Documentation]  Login to GUI Network page, configure static IPv6 address and verify.
    [Tags]  Configure_And_Verify_Static_IPv6_Address
    [Template]  Add Static IPv6 Address And Verify Via GUI

    # ipv6                  prefix_length          status
    ${test_ipv6_addr}       ${test_prefix_length}  Success
    ${ipv4_hexword_addr}    ${test_prefix_length}  Invalid format
    ${invalid_hexadec_ipv6} ${test_prefix_length}  Invalid format
    ${ipv6_multi_short}     ${test_prefix_length}  Invalid format


Configure And Verify Static Default Gateway
    [Documentation]  Login to GUI Network page, configure invalid static IPv6 default gateway and verify.
    [Tags]  Configure_And_Verify_Static_Default_Gateway
    [Template]  Add IPv6 Static Default Gateway And Verify

    # ipv6 static default gateway  status
    ${test_ipv6_addr}              Success


Verify Coexistence of Staticv6 and Linklocal
    [Documentation]  Verify coexistence of staticv6 and linklocal.
    [Tags]  Verify_Coexistence_of_Staticv6_and_Linklocal

    Add Static IPv6 Address And Verify Via GUI  ${test_ipv6_addr}  ${test_prefix_length}  Success
    @{ipv6_address_origin_list}  ${ipv6_linklocal_ipv6_addr}=
    ...    Get Address Origin List And Address For Type  LinkLocal
    Page Should Contain Element  ${xpath_linklocalv6}
    Page Should Contain  ${ipv6_linklocal_ipv6_addr}
    Page Should Contain  ${test_ipv6_addr}


Modify DHCP Properties By Toggling And Verify
    [Documentation]  Modify DHCP properties by toggling and verify.
    [Tags]  Modify_DHCP_Properties_By_Toggling_And_Verify
    [Template]  Toggle DHCPv4 property And Verify

    # property                 xpath_property

    UseNTPServers              ${xpath_ntp_switch_button}
    UseDNSServers              ${xpath_dns_switch_button}
    UseDomainName              ${xpath_domainname_switch_button}


Delete IPv4 Address Via GUI And Verify
   [Documentation]  Delete IPv4 Address via GUI and verify.
   [Tags]  Delete_IPv4_Address_Via_GUI_And_Verify

   Add Static IP Address And Verify  ${test_ipv4_addr}  ${test_subnet_mask}  ${default_gateway}  Success
   Delete IPv4 Address And Verify  ${test_ipv4_addr}


Verify MAC Address Is Displayed
   [Documentation]  Verify MAC address is displayed.
   [Tags]  Verify_MAC_Address_Is_Displayed

   ${network_details}=  Get Network Interface Details  ${CHANNEL_NUMBER}

   # Verify the MAC address on GUI.
   Page Should Contain  ${network_details['MACAddress']}


Verify MAC Address On Eth1 Interface
    [Documentation]  Verify MAC address on eth1 interface.
    [Tags]  Verify_MAC_Address_On_Eth1_Interface

    Click Element  ${xpath_eth1_interface}

    ${network_details}=  Get Network Interface Details  ${SECONDARY_CHANNEL_NUMBER}

    # Verify eth1 interface MAC address on GUI.
    Page Should Contain  ${network_details['MACAddress']}


Configure Hostname Via GUI And Verify
    [Documentation]  Login to GUI Network page, configure hostname and verify.
    [Tags]  Configure_Hostname_Via_GUI_And_Verify
    [Teardown]  Configure the Hostname Back And Verify

    ${hostname}=  Get BMC Hostname
    Set Suite Variable  ${hostname}
    Configure And Verify Network Settings Via GUI  ${xpath_hostname}
    ...  ${xpath_hostname_input}  ${test_hostname}

    ${bmc_hostname}=  Get BMC Hostname
    Should Be Equal As Strings  ${bmc_hostname}  ${test_hostname}


Enable AutoConfig On Eth0 And Verify
    [Documentation]  Enable SLAAC on eth0 via GUI & check it is set to enable state.
    [Tags]  Enable_AutoConfig_On_Eth0_And_Verify

    Set IPv6 AutoConfig State  Enabled  ${xpath_eth0_ipv6_autoconfig_button}
    @{ipv6_address_origin_list}  ${ipv6_slaac_addr}=
    ...    Get Address Origin List And Address For Type  SLAAC
    Page Should Contain  ${ipv6_slaac_addr}
    Page Should Contain   SLAAC


Disable AutoConfig On Eth0 And Verify
    [Documentation]  Disable SLAAC on eth0 via GUI & check it is set to disable state.
    [Tags]  Disable_AutoConfig_On_Eth0_And_Verify

    Set IPv6 AutoConfig State  Disabled  ${xpath_eth0_ipv6_autoconfig_button}
    Page Should Not Contain    SLAAC



*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Wait Until Keyword Succeeds  1 min  15 sec
    ...  Click Element  ${xpath_settings_menu}
    Click Element  ${xpath_network_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  network
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
    ${default_gateway}=  Get BMC Default Gateway
    Set Suite Variable  ${default_gateway}

Launch Browser Login GUI And Navigate To Network Page
    [Documentation]  Launch browser Login GUI and navigate to network page.

    Launch Browser And Login GUI
    Wait Until Keyword Succeeds  1 min  15 sec
    ...  Click Element  ${xpath_settings_menu}
    Click Element  ${xpath_network_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  network
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30

Configure the Hostname Back And Verify
    [Documentation]  Configure the hostname back.

    Configure And Verify Network Settings Via GUI
    ...  ${xpath_hostname}  ${xpath_hostname_input}  ${hostname}
    ${bmc_hostname_after}=  Get BMC Hostname
    Should Be Equal As Strings  ${bmc_hostname_after}  ${hostname}
    Close Browser


Delete DNS Servers And Verify
    [Documentation]  Login to GUI Network page,delete static name servers
    ...  and verify that page does not reflect static name servers.

    Page Should Contain Element  ${xpath_delete_dns_server}
    Wait Until Element Is Enabled  ${xpath_delete_dns_server}
    Click Button  ${xpath_delete_dns_server}
    Wait Until Page Contains Element  ${xpath_add_dns_ip_address_button}  timeout=15
    # Check if all name servers deleted on BMC.
    ${nameservers}=  CLI Get Nameservers
    Should Not Contain  ${nameservers}  ${original_nameservers}

    DNS Test Setup Execution

    Should Be Empty  ${original_nameservers}


Add Static IP Address And Verify
    [Documentation]  Add static IP address, subnet mask and
    ...  gateway via GUI and verify.
    [Arguments]  ${ip_address}  ${subnet_mask}  ${gateway_address}  ${expected_status}=error

    # Description of argument(s):
    # ip_address          IP address to be added (e.g. 10.7.7.7).
    # subnet_mask         Subnet mask for the IP to be added (e.g. 255.255.0.0).
    # gateway_address     Gateway address for the IP to be added (e.g. 10.7.7.1).
    # expected_status     Expected status while adding static IPv4 address
    # ....                (e.g. Invalid format / Field required).

    Wait Until Element Is Enabled  ${xpath_add_static_ipv4_address_button}  timeout=60sec
    Click Element  ${xpath_add_static_ipv4_address_button}

    Input Text  ${xpath_input_ip_address}  ${ip_address}
    Input Text  ${xpath_input_subnetmask}  ${subnet_mask}
    Input Text  ${xpath_input_gateway}  ${gateway_address}

    Click Element  ${xpath_add_button}
    IF  '${expected_status}' == 'Success'
        Wait Until Page Contains  ${ip_address}  timeout=40sec
        Validate Network Config On BMC
    ELSE
        Page Should Contain  Invalid format
        Click Button  ${xpath_cancel_button}
        Wait Until Page Does Not Contain Element  ${xpath_cancel_button}
    END


Add Static IPv6 Address And Verify Via GUI
    [Documentation]  Add static IPv6 address and prefix length and verify.
    [Arguments]  ${ipv6_address}  ${prefix_length}  ${expected_status}=error

    # Description of argument(s):
    # ipv6_address        IPv6 address to be added.
    # prefix_length       Prefix length of the IPv6 to be added.
    # expected_status     Expected status while adding static IPv6 address.

    Wait Until Element Is Enabled  ${xpath_add_static_ipv6_address_button}  timeout=60sec
    Click Element  ${xpath_add_static_ipv6_address_button}

    Input Text  ${xpath_input_ip_address}  ${ipv6_address}
    Input Text  ${xpath_input_prefix_length}  ${prefix_length}

    Click Element  ${xpath_add_button}
    IF  '${expected_status}' == 'Success'
        Wait Until Page Contains  ${ipv6_address}  timeout=40sec
        Validate Network Config On BMC
    ELSE
        Page Should Contain  Invalid format
        Cancel And Verify Network Heading
    END


Add IPv6 Static Default Gateway And Verify
    [Documentation]  Add IPv6 static default gateway and verify.
    [Arguments]  ${ipv6_static_def_gw}  ${expected_status}=error

    # Description of argument(s):
    # ipv6_static_def_gw  IPv6 static default gateway.
    # expected_status     Expected status (Success or Fail).

    Wait Until Element Is Enabled  ${xpath_add_static_def_gateway_button}  timeout=60sec
    Click Element  ${xpath_add_static_def_gateway_button}

    Input Text  ${xpath_input_ip_address}  ${ipv6_static_def_gw}

    Click Element  ${xpath_add_button}
    IF  '${expected_status}' == 'Success'
        Wait Until Page Contains  ${ipv6_static_def_gw}  timeout=40sec
        Validate Network Config On BMC
    ELSE
        Page Should Contain  Invalid format
        Cancel And Verify Network Heading
    END
    ${redfish_ipv6_staticdef_gw}=  Get Static Default Gateway Property Via Redfish
    Should Be Equal  ${ipv6_static_def_gw}  ${redfish_ipv6_staticdef_gw}


Get Static Default Gateway Property Via Redfish
     [Documentation]  Get Static Default Gateway property value via redfish.

     ${active_channel_config}=  Get Active Channel Config
     ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}
     ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
     ${ipv6_static_def_gw}=  Get From Dictionary  ${resp.dict}  IPv6StaticDefaultGateways
     RETURN  ${resp.dict["IPv6StaticDefaultGateways"][0]["Address"]}


Configure And Verify Network Settings Via GUI
    [Documentation]  Configure and verify network settings via GUI.
    [Arguments]  ${xpath_nw_settings}  ${xpath_nw_settings_input_field}  ${input_value}

    # Description of argument(s):
    # xpath_nw_settings               xpath of the network settings.
    # xpath_nw_settings_input_field   xpath of the network setting's input field.
    # input_value                     Input value for configuration. E.g. hostname, IP etc.

    Wait Until Keyword Succeeds  30 sec  10 sec  Click Element  ${xpath_nw_settings}
    Input Text  ${xpath_nw_settings_input_field}  ${input_value}
    Click Button  ${xpath_save_button}

    # Re-Login gui and navigate to network page.
    Launch Browser Login GUI And Navigate To Network Page

    Wait Until Page Contains  ${input_value}  timeout=30sec


Toggle DHCPv4 Property And Verify
    [Documentation]  Toggle DHVPv4 property and verify.
    [Arguments]  ${property}   ${xpath_property}

    # Description of argument(s):
    # property          DHCP Property name (e.g. UseDNSServers, UseDomainName, etc.).
    # xpath_property    xpath of the DHCPv4 property.

    Wait Until Page Contains Element  ${xpath_property}

    ${redfish_before_set}=  Get DHCP Property Via Redfish  ${property}
    ${gui_before_set}=  Get Text  ${xpath_property}

    Click Element  ${xpath_property}
    Verify Popup Message And Close Popup  ${xpath_success_popup}
    Wait Until Element Is Not Visible
    ...  ${xpath_page_loading_progress_bar}  timeout=120s

    ${redfish_after_set}=  Get DHCP Property Via Redfish  ${property}
    Should Not Be Equal  ${redfish_before_set}  ${redfish_after_set}

    ${gui_after_set}=  Get Text  ${xpath_property}
    Should Not Be Equal  ${gui_before_set}  ${gui_after_set}

    Click Element At Coordinates   ${xpath_property}  0  0
    Verify Popup Message And Close Popup  ${xpath_success_popup}


Get DHCP Property Via Redfish
     [Documentation]  Get DHCPv4 property value via redfish.
     [Arguments]   ${property}

     # Description of argument(s):
     # ${property}       DHCP Property name.

     ${active_channel_config}=  Get Active Channel Config
     ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}
     ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
     RETURN  ${resp.dict["DHCPv4"]["${property}"]}


Verify Popup Message And Close Popup
    [Documentation]  Verify popup message and close popup.
    [Arguments]   ${popup_msg}

    # Description of argument(s):
    # popup_msg        Popup message (Eg: Success or Error).

    Wait Until Keyword Succeeds  1 min  15 sec
    ...  Wait Until Page Contains Element  ${popup_msg}
    Click Element  ${popup_msg}


Delete IPv4 Address And Verify
   [Documentation]  Delete IPv4 address and verify.
   [Arguments]  ${ip_addr}

   # Description of argument(s):
   # ip_addr      IP address to be deleted.

   Wait Until Page Contains  ${ip_addr}
   Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=120s
   Wait Until Element Is Enabled  ${xpath_delete_ipv4_addres}
   Click Element  ${xpath_delete_ipv4_addres}
   Click Element  ${xpath_delete_button}
   Wait Until Page Contains Element   ${xpath_success_message}
   Sleep  ${NETWORK_TIMEOUT}s

   # Verify IP on BMC via Redfish.
   ${delete_status}=  Run Keyword And Return Status  Verify IP On BMC  ${ip_addr}
   Should Be Equal  ${delete_status}  ${False}

   Wait Until Page Does Not Contain  ${ip_addr}


Get Network Interface Details
   [Documentation]  Get network interface details.
   [Arguments]   ${channel_number}

   # Description of argument(s):
   # channel_number   Interface Channel Number(eg.eth0 or eth1).

   ${active_channel_config}=  Get Active Channel Config
   ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}
   ${resp}=  redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
   RETURN  ${resp.dict}


Cancel And Verify Network Heading
    [Documentation]  Cancel and verify network heading.

    Click Button  ${xpath_cancel_button}
    Wait Until Keyword Succeeds  10 sec  5 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_network_heading}  Network


Set IPv6 AutoConfig State
    [Arguments]    ${desired_autoconfig_state}  ${xpath_ipv6_autoconfig_button}

    # Description of argument(s):
    # desired_autoconfig_state      IPv6 autoconfig Toggle state(eg: Enabled or Disabled).
    # xpath_ipv6_autoconfig_button  xpath of eth0 or eth1 ipv6 autoconfig button.

    ${current_autoconfig_state}=    Get Text    ${xpath_ipv6_autoconfig_button}

    IF    '${desired_autoconfig_state}' == '${current_autoconfig_state}'
        # Already in desired state, reset by toggling twice
        Click Element  ${xpath_ipv6_autoconfig_button}
        Wait Until Element Is Not Visible
        ...  ${xpath_page_loading_progress_bar}  timeout=120s
        Click Element  ${xpath_ipv6_autoconfig_button}
        Wait Until Element Is Not Visible
        ...  ${xpath_page_loading_progress_bar}  timeout=120s
        Element Text Should Be  ${xpath_ipv6_autoconfig_button}
        ...  ${desired_autoconfig_state}  timeout=60s
    ELSE IF    '${desired_autoconfig_state}' != '${current_autoconfig_state}'
        Click Element  ${xpath_ipv6_autoconfig_button}
        Wait Until Element Is Not Visible
        ...  ${xpath_page_loading_progress_bar}  timeout=120s
        Element Text Should Be  ${xpath_ipv6_autoconfig_button}
        ...  ${desired_autoconfig_state}  timeout=60s
    END