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
${xpath_network_button}                  //a[normalize-space()='Network'][1]
${xpath_static_ipv4}                     //h2[text()="IPv4"]
${xpath_static_ipv6}                     //h2[text()="IPv6"]
${xpath_static_ipv6_default_gateway}     //h2[text()="IPv6 static default gateways"]
${xpath_domain_name_toggle}              //*[@data-test-id="networkSettings-switch-useDomainName"]
${xpath_ntp_servers_toggle}              //*[@data-test-id="networkSettings-switch-useNtp"]
${xpath_add_static_ipv4_addr_btn_eth0}   (//button[contains(text(),"Add static IPv4 address")])[1]
${xpath_add_static_ipv4_addr_btn_eth1}   (//button[contains(text(),"Add static IPv4 address")])[2]
${xpath_add_static_ipv6_addr_btn_eth0}   (//button[contains(text(),"Add static IPv6 address")])[1]
${xpath_add_static_ipv6_addr_btn_eth1}   (//button[contains(text(),"Add static IPv6 address")])[2]
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
${ipv4_elements}                         //h2[contains(., "IPv4")]/following::table[1]/tbody/tr/td[1]
${ipv6_elements}                         //h2[contains(., "IPv6")]/following::table[1]/tbody/tr/td[1]
${ipv4_addr_origin_elements}             //h2[contains(text(),'IPv4')]//following::table[1]
...                                      //td[@aria-colindex='4']
${ipv6_addr_origin_elements}             //h2[contains(text(),'IPv6')]//following::table[1]
...                                      //td[@aria-colindex='3']
${xpath_delete_ipv4_addres}              //*[text()='${test_ipv4_addr_2}']/following::td[4]
...                                      //*[@title="Delete IPv4 address"]
${xpath_delete_ipv6_addres}              //*[text()='${test_ipv6_addr_2}']/following::td[3]
...                                      //*[@title="Delete IPv6 address"]
${xpath_edit_ipv4_addres}                //*[text()='${test_ipv4_addr}']/following::td[4]
...                                      //*[@title="Edit static IPv4 address"]
${xpath_edit_ipv6_addres}                //*[text()='${test_ipv6_addr}']/following::td[3]
...                                      //*[@title="Edit static IPv6 address"]
${xpath_delete_ipv6_def_gateway_addr}    //*[text()='${test_ipv6_addr_1}']/following::td[1]
...                                      //*[@title="Delete IPv6 static default gateway address"]
${xpath_edit_ipv6_def_gateway_addr}      //*[text()='${test_ipv6_addr}']/following::td[1]
...                                      //*[@title="Edit IPv6 static default gateway address"]
${xpath_edit_ipv6_def_gateway_addr_1}    //*[text()='${test_ipv6_addr_1}']/following::td[1]
...                                      //*[@title="Edit IPv6 static default gateway address"]
${xpath_ipv6_addr_edit_button}           //*[text()='{}']/following::td[3]
...                                      //*[@title="Edit static IPv6 address"]
${xpath_ipv6_addr_delete_button}         //*[text()='{}']/following::td[3]
...                                      //*[@title="Delete IPv6 address"]
${xpath_delete_button}                   //*[text()="Delete"]
${xpath_eth0_interface}                  //*[text()="eth0"]
${xpath_eth1_interface}                  //*[text()="eth1"]
${xpath_linklocalv6}                     //*[text()="LinkLocal"]
${xpath_eth0_autoconfig_button}          (//*[@id="ipv6AutoConfigSwitch"]/following-sibling::label)[1]
${xpath_eth1_autoconfig_button}          (//*[@id="ipv6AutoConfigSwitch"]/following-sibling::label)[2]
${xpath_eth0_dhcpv6_button}              (//*[@id="dhcpIpv6Switch"]/following-sibling::label)[1]
${xpath_eth1_dhcpv6_button}              (//*[@id="dhcpIpv6Switch"]/following-sibling::label)[2]
${xpath_eth0_dhcpv4_button}              (//*[@id="dhcpSwitch"]/following-sibling::label)[1]
${xpath_eth1_dhcpv4_button}              (//*[@id="dhcpSwitch"]/following-sibling::label)[2]
${xpath_dhcpv4_alert}                    //button[normalize-space()='Enable' or normalize-space()='Disable']
${dns_server}                            10.10.10.10
${test_ipv4_addr}                        10.7.7.7
${test_ipv4_addr_1}                      10.7.7.8
${test_ipv4_addr_2}                      10.7.6.5
${test_ipv6_addr}                        2001:db8:3333:4444:5555:6666:7777:8888
${test_ipv6_addr_1}                      2001:db8:3333:4444:5555:6666:7777:8889
${test_ipv6_addr_2}                      2001:db8:3333:4444:5555:6666:7777:8890
${ipv6_multi_block}                      2001:0022:0000:0000:1:2:3:8
${ipv6_multi_block_addr}                 2001:22::1:2:3:8
${ipv4_hexword_addr}                     10.5.5.6:1A:1B:1C:1D:1E:1F
${invalid_hexadec_ipv6}                  x:x:x:x:x:x:10.5.5.6
${ipv6_multi_short}                      2001::33::111
${ipv6_with_leadingzeroes_addr}          2001:0022:0033::0111
${ipv6_without_leadingzeroes_addr}       2001:22:33::111
${ipv6_onehextet_zero}                   2001:0022:1133::1111
${ipv6_eliminate_onehextet_zero}         2001:22:1133::1111
${compressed_ipv4}                       ::10.5.5.6
${compressed_ipv6}                       ::a05:506
${link_local_addr}                       fe80::
${link_local_prefix_len}                 10
${test_prefix_length}                    64
${out_of_range_ip}                       10.7.7.256
${string_ip}                             aa.bb.cc.dd
${negative_ip}                           10.-7.-7.-7
${less_octet_ip}                         10.3.36
${hex_ip}                                0xa.0xb.0xc.0xd
${spl_char_ip}                           @@@.%%.44.11
${test_subnet_mask}                      255.255.255.0
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

    Page Should Contain Button  ${xpath_add_static_ipv4_addr_btn_eth0}
    Page Should Contain Button  ${xpath_add_static_ipv6_addr_btn_eth0}
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

    Wait Until Keyword Succeeds  30 sec  10 sec  Click Element  ${xpath_add_static_ipv4_addr_btn_eth0}
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

    Wait Until Keyword Succeeds  30 sec  10 sec  Click Element  ${xpath_add_static_ipv6_addr_btn_eth0}
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

    # ipv6                           prefix_length          status         expected_ipv6
    ${ipv6_with_leadingzeroes_addr}  ${test_prefix_length}  Success        ${ipv6_without_leadingzeroes_addr}
    ${ipv6_onehextet_zero}           ${test_prefix_length}  Success        ${ipv6_eliminate_onehextet_zero}
    ${ipv6_multi_block}              ${test_prefix_length}  Success        ${ipv6_multi_block_addr}
    ${compressed_ipv4}               ${test_prefix_length}  Success        ${compressed_ipv6}
    ${test_ipv6_addr}                ${test_prefix_length}  Success
    ${ipv4_hexword_addr}             ${test_prefix_length}  Invalid format
    ${invalid_hexadec_ipv6}          ${test_prefix_length}  Invalid format
    ${ipv6_multi_short}              ${test_prefix_length}  Invalid format


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
   [Setup]  Add Static IP Address And Verify  ${test_ipv4_addr_2}  ${test_subnet_mask}
   ...  ${default_gateway}  Success

   Delete IP Address And Verify  ipv4  ${test_ipv4_addr_2}


Delete IPv6 Address Via GUI And Verify
   [Documentation]  Delete IPv6 Address via GUI and verify.
   [Tags]  Delete_IPv6_Address_Via_GUI_And_Verify
   [Setup]  Add Static IPv6 Address And Verify Via GUI  ${test_ipv6_addr_2}
   ...  ${test_prefix_length}  Success

   Delete IP Address And Verify  ipv6  ${test_ipv6_addr_2}


Modify IPv4 Address Via GUI And Verify
    [Documentation]  Edit IPv4 address via GUI and verify.
    [Tags]  Modify_IPv4_Address_Via_GUI_And_Verify
    [Setup]  Add Static IP Address And Verify  ${test_ipv4_addr}  ${test_subnet_mask}
    ...  ${default_gateway}  Success

    Modify IP Address And Verify  ipv4  ${test_ipv4_addr}  ${test_ipv4_addr_1}


Modify IPv6 Address Via GUI And Verify
    [Documentation]  Edit IPv6 address via GUI and verify.
    [Tags]  Modify_IPv6_Address_Via_GUI_And_Verify
    [Setup]  Add Static IPv6 Address And Verify Via GUI  ${test_ipv6_addr}
    ...  ${test_prefix_length}  Success

    Modify IP Address And Verify  ipv6  ${test_ipv6_addr}  ${test_ipv6_addr_1}


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

    Set IPv6 AutoConfig State  Enabled  1


Disable AutoConfig On Eth0 And Verify
    [Documentation]  Disable SLAAC on eth0 via GUI & check it is set to disable state.
    [Tags]  Disable_AutoConfig_On_Eth0_And_Verify

    Set IPv6 AutoConfig State  Disabled  1


Enable AutoConfig On Eth1 And Verify
    [Documentation]  Enable SLAAC on eth1 via GUI & check it is set to enable state.
    [Tags]  Enable_AutoConfig_On_Eth1_And_Verify

    Set IPv6 AutoConfig State  Enabled  2


Disable AutoConfig On Eth1 And Verify
    [Documentation]  Disable SLAAC on eth1 via GUI & check it is set to disable state.
    [Tags]  Disable_AutoConfig_On_Eth1_And_Verify

    Set IPv6 AutoConfig State  Disabled  2


Enable SLAAC On Both Interfaces And Verify Eth0
    [Documentation]  Enable SLAAC on eth0, then on eth1, verify eth0 is not impacted.
    [Tags]  Enable_SLAAC_On_Both_Interfaces_And_Verify_Eth0

    Set SLAAC Property On Eth0 And Eth1
    Click Element  ${xpath_eth0_interface}

    # Verify SLAAC on eth0
    Set Suite Variable  ${CHANNEL_NUMBER}  1
    Verify SLAAC Address On Autoconfig Enable


Enable SLAAC On Both Interfaces Disable It On Eth0 And Verify Eth1
    [Documentation]  Enable and verify SLAAC property on eth0 and eth1,
    ...  disable it on eth0 and verify eth1 is not impacted.
    [Tags]  Enable_SLAAC_On_Both_Interfaces_Disable_It_On_Eth0_And_Verify_Eth1

    Set SLAAC Property On Eth0 And Eth1
    Set IPv6 AutoConfig State  Disabled  1
    Click Element  ${xpath_eth1_interface}

    # Verify SLAAC on eth1 after disabling eth0
    Set Suite Variable  ${CHANNEL_NUMBER}  2
    Verify SLAAC Address On Autoconfig Enable


Enable SLAAC On Both Interfaces Disable It On Eth1 And Verify Eth0
    [Documentation]  Enable and verify SLAAC property on eth0 and eth1,
    ...  disable it on eth1 and verify eth0 is not impacted.
    [Tags]  Enable_SLAAC_On_Both_Interfaces_Disable_It_On_Eth1_And_Verify_Eth0

    Set SLAAC Property On Eth0 And Eth1
    Set IPv6 AutoConfig State  Disabled  2

    # Verify SLAAC on eth0 after disabling eth1
    Set Suite Variable  ${CHANNEL_NUMBER}  1
    Verify SLAAC Address On Autoconfig Enable


Enable SLAAC On Both Interfaces Disable It On Both And Verify
    [Documentation]  Enable and verify SLAAC property on eth0 and eth1,
    ...  disable it on eth0,eth1 and verify.
    [Tags]  Enable_SLAAC_On_Both_Interfaces_Disable_It_On_Both_And_Verify

    Set SLAAC Property On Eth0 And Eth1

    # Verify SLAAC is disconfigured on both eth0 and eth1 after disabling
    Set IPv6 AutoConfig State  Disabled  1
    Set IPv6 AutoConfig State  Disabled  2


Add Static IPv6 Address Via GUI And Check Persistency
    [Documentation]  Add static IPv6 address and verify persistency of static IPv6 on BMC reboot.
    [Tags]  Add_Static_IPv6_Address_Via_GUI_And_Check_Persistency

    Add Static IPv6 Address And Verify Via GUI  ${test_ipv6_addr}  ${test_prefix_length}  Success
    Verify Persistency Of IPv6 On BMC Reboot  Static  1


Verify Persistency Of LinkLocal IPv6 On BMC Reboot For Both Interfaces
    [Documentation]  Verify persistency of linklocal IPv6 on BMC reboot for both interfaces.
    [Tags]  Verify_Persistency_Of_LinkLocal_IPv6_On_BMC_Reboot_For_Both_Interfaces

    Verify Persistency Of IPv6 On BMC Reboot  LinkLocal  1
    Verify Persistency Of IPv6 On BMC Reboot  LinkLocal  2


Verify Persistency Of SLAAC On BMC Reboot For Both Interfaces
    [Documentation]  Verify persistency of slaac on BMC reboot for both interfaces.
    [Tags]  Verify_Persistency_Of_SLAAC_On_BMC_Reboot_For_Both_Interfaces
    [Setup]  Set SLAAC Property On Eth0 And Eth1  Enabled

    Verify Persistency Of IPv6 On BMC Reboot  SLAAC  1
    Verify Persistency Of IPv6 On BMC Reboot  SLAAC  2


Verify Persistency Of DHCPv6 On BMC Reboot For Both Interfaces
    [Documentation]  Verify persistency of DHCPv6 on BMC reboot for both interfaces
    ...  DHCPv6 setup should be in place for this testcase to pass.
    [Tags]  Verify_Persistency_Of_DHCPv6_On_BMC_Reboot_For_Both_Interfaces
    [Setup]  Set And Verify DHCPv6 States  Enabled  Enabled

    Verify Persistency Of IPv6 On BMC Reboot  DHCPv6  1
    Verify Persistency Of IPv6 On BMC Reboot  DHCPv6  2


Verify DHCPv6 Enable And Disable On Both Interfaces Via GUI
    [Documentation]  Verify DHCPv6 toggle on both interfaces via GUI.
    [Tags]  Verify_DHCPv6_Enable_And_Disable_On_Both_Interfaces_Via_GUI
    [Template]  Set And Verify DHCPv6 States

    # eth0_state    eth1_state

    Disabled        Enabled
    Disabled        Disabled
    Enabled         Disabled
    Enabled         Enabled


Delete Default IPv6 Static Gateway Address And Verify
    [Documentation]  Delete default IPv6 static gateway address and verify.
    [Tags]  Delete_Default_IPv6_Static_Gateway_Address_And_Verify
    [Setup]  Add IPv6 Static Default Gateway And Verify  ${test_ipv6_addr_1}  Success

    Delete Default IPv6 Gateway And Verify  ${test_ipv6_addr_1}


Modify Default IPv6 Static Gateway Address And Verify
    [Documentation]  Modify default IPv6 static gateway address and verify.
    [Tags]  Modify_Default_IPv6_Static_Gateway_Address_And_Verify
    [Setup]  Add IPv6 Static Default Gateway And Verify  ${test_ipv6_addr}  Success
    [Teardown]  Delete Default IPv6 Gateway And Verify  ${test_ipv6_addr_1}

    Modify Default IPv6 Gateway And Verify  ${test_ipv6_addr}  ${test_ipv6_addr_1}


Verify Enable Or Disable DHCPv6 Does Not Impact IPv4 Settings
    [Documentation]  Verify enable or disable DHCPv6 and it does not have impact on IPv4 settings
    ...  Note: Enable testcase need DHCPv6 setup.
    [Tags]  Verify_Enable_Or_Disable_DHCPv6_Does_Not_Impact_IPv4_Settings
    [Template]  Enable Or Disable DHCPv6 And Verify Impact On IPv4 Settings

    # ip_version   channel_number  desired_status
    ipv4           1               Disabled
    ipv4           1               Enabled
    ipv4           2               Disabled
    ipv4           2               Enabled


Verify DHCPv4 Enable And Disable On Eth1 Via GUI
    [Documentation]  Verify DHCPv4 toggle on eth1 via GUI, Note: Enable testcase need DHCP setup.
    [Tags]  Verify_DHCPv4_Enable_And_Disable_On_Eth1_Via_GUI
    [Template]  Toggle DHCPv4 State And Verify
    [Teardown]  Assign Static IP Address on Eth1

    # desired_dhcpv4_state
    Enabled
    Disabled


Verify Coexistence Of IPv6 All Types Via GUI
    [Documentation]  Verify coexistence of IPv6 all types on both interfaces.
    [Tags]   Verify_Coexistence_Of_IPv6_All_Types_Via_GUI
    [Setup]  Run Keywords  Add Static IPv6 Address And Verify Via GUI
    ...      ${test_ipv6_addr}  ${test_prefix_length}  Success
    ...      AND  Set And Verify DHCPv6 States  Enabled  Enabled
    ...      AND  Set SLAAC Property On Eth0 And Eth1
    ...      AND  Add Static IPv6 Address And Verify Via GUI
    ...      ${test_ipv6_addr}  ${test_prefix_length}  Success  None  2
    [Template]  Coexistence Of IP Addresses

    # Note: DHCPv6 and SLAAC setup must be present.
    # Channel_number   ipv6_type1      ipv6_type2       ipv6_type3      ipv6_type4
    1                  Staticv6        LinkLocalv6      SLAACv6         DHCPv6
    2                  LinkLocalv6     SLAACv6          Staticv6        DHCPv6


Verify Independent SLAAC Configuration On Separate DHCPv6 Enabled Interfaces
    [Documentation]  Verify when both interfaces are connected to DHCPv6, enabling/disabling
    ...              SLAAC on one interface will not impact existing settings.
    [Tags]  Verify_Independent_SLAAC_Configuration_On_Separate_DHCPv6_Enabled_Interfaces
    [Setup]  Set And Verify DHCPv6 States  Enabled  Disabled
    [Template]  Enable Or Disable SLAAC And Verify Impact On Existing Settings

    # ip_version   channel_number  desired_status
    ipv4           1               Disabled
    ipv4           1               Enabled
    ipv4           2               Disabled
    ipv4           2               Enabled


Verify Coexistence Of LinkLocalv6 DHCPv6 Staticv6 And SLAACv6 On Both Interfaces
    [Documentation]  Verify coexistence of LinkLocalv6,DHCPv6,Staticv6 and SLAACv6 on both interfaces.
    [Tags]   Verify_Coexistence_Of_LinkLocalv6_DHCPv6_Staticv6_And_SLAACv6_On_Both_Interfaces
    [Setup]  Run Keywords  Set And Verify DHCPv6 States  Enabled  Enabled
    ...      AND  Add Static IPv6 Address And Verify Via GUI
    ...      ${test_ipv6_addr_2}  ${test_prefix_length}  Success
    ...      AND  Set SLAAC Property On Eth0 And Eth1
    ...      AND  Add Static IPv6 Address And Verify Via GUI
    ...      ${test_ipv6_addr}  ${test_prefix_length}  Success  None  2
    [Template]  Coexistence Of IP Addresses
    [Teardown]  Run Keywords  Click Element  ${xpath_refresh_button}
    ...         AND  Delete IP Address And Verify  ipv6  ${test_ipv6_addr_2}

    # Note: DHCPv6 and SLAAC setup must be present.
    # Channel_number   ipv6_type1    ipv6_type2   ipv6_type3     ipv6_type4
    1                  LinkLocalv6   DHCPv6       Staticv6       SLAACv6
    2                  LinkLocalv6   DHCPv6       Staticv6       SLAACv6


Verify Coexistence Of LinkLocalv6 DHCPv6 And SLAACv6 On Both Interfaces
    [Documentation]  Verify coexistence of LinkLocalv6,DHCPv6 and SLAACv6 on both interfaces.
    [Tags]   Verify_Coexistence_Of_LinkLocalv6_DHCPv6_And_SLAACv6_On_Both_Interfaces
    [Setup]  Run Keywords  Set And Verify DHCPv6 States  Enabled  Enabled
    ...      AND  Set SLAAC Property On Eth0 And Eth1
    [Template]  Coexistence Of IP Addresses

    # Note: DHCPv6 and SLAAC setup must be present.
    # Channel_number   ipv6_type1     ipv6_type2   ipv6_type3
    1                  LinkLocalv6    DHCPv6       SLAACv6
    2                  LinkLocalv6    DHCPv6       SLAACv6


Verify Coexistence Of DHCPv6 Staticv6 And LinkLocalv6 On Both Interfaces
    [Documentation]  Verify coexistence of DHCPv6, Staticv6 and LinkLocalv6 on both interfaces.
    [Tags]   Verify_Coexistence_Of_DHCPv6_Staticv6_And_LinkLocalv6_On_Both_Interfaces
    [Setup]  Run Keywords  Set And Verify DHCPv6 States  Enabled  Enabled
    ...      AND  Add Static IPv6 Address And Verify Via GUI  ${test_ipv6_addr_2}
    ...      ${test_prefix_length}  Success
    ...      AND  Add Static IPv6 Address And Verify Via GUI  ${test_ipv6_addr}
    ...      ${test_prefix_length}  Success  None  2
    [Template]  Coexistence Of IP Addresses
    [Teardown]  Run Keywords  Click Element  ${xpath_refresh_button}
    ...         AND  Delete IP Address And Verify  ipv6  ${test_ipv6_addr_2}

    # Note: DHCPv6 setup must be present.
    # Channel_number   ipv6_type1   ipv6_type2     ipv6_type3
    1                  DHCPv6       Staticv6       LinkLocalv6
    2                  DHCPv6       Staticv6       LinkLocalv6


Configure DHCPv6 On Eth0 And Verify Existing Network Configurations On BMC Reboot
   [Documentation]  Configure DHCPv6 on eth0 and verify existing network configurations
    ...    on BMC reboot.
    [Tags]  Configure_DHCPv6_On_Eth0_And_Verify_Existing_Network_Configurations_On_BMC_Reboot
    [Setup]  Set And Verify DHCPv6 States  Enabled  Disabled

    # Capture IPv4 addresses before BMC reboot.
    ${ipv4_before}=  Collect All IP Addresses On Both Interfaces  ipv4  1

    # Capture IPv6 addresses before BMC reboot.
    ${ipv6_before}=  Collect All IP Addresses On Both Interfaces  ipv6  1

    Reboot BMC via GUI
    Click Element  ${xpath_network_button}

    # Capture IPv4 addresses after BMC reboot.
    ${ipv4_after}=  Collect All IP Addresses On Both Interfaces  ipv4  1
    Lists Should Be Equal  ${ipv4_before}  ${ipv4_after}  ignore_order=True

    ${ipv6_after}=  Collect All IP Addresses On Both Interfaces  ipv6  1
    Lists Should Be Equal  ${ipv6_before}  ${ipv6_after}  ignore_order=True


Verify Coexistence Of Staticv4 SLAACv6 And LinkLocalv6 On Both Interfaces
    [Documentation]  Verify coexistence of Staticv4 SLAACv6 and LinkLocalv6 on both interfaces.
    [Tags]   Verify_Coexistence_Of_Staticv4_SLAACv6_And_LinkLocalv6_On_Both_Interfaces
    [Setup]  Run Keywords  Add Static IP Address And Verify  ${test_ipv4_addr}
    ...      ${test_subnet_mask}  ${default_gateway}  Success
    ...      AND  Add Static IP Address And Verify  ${test_ipv4_addr_1}
    ...      ${test_subnet_mask}  ${default_gateway_2}  Success  2
    ...      AND  Set SLAAC Property On Eth0 And Eth1
    [Template]  Coexistence Of IP Addresses

    # Channel_number   ip_type1       ip_type2
    1                  Staticv4       SLAACv6
    2                  Staticv4       SLAACv6
    1                  Staticv4       LinkLocalv6
    2                  Staticv4       LinkLocalv6


Verify Coexistence Of Staticv4 Staticv6 And SLAACv6 On Both Interfaces
    [Documentation]  Verify coexistence of Staticv4 Staticv6 and SLAACv6 on both interfaces.
    [Tags]   Verify_Coexistence_Of_Staticv4_Staticv6_And_SLAACv6_On_Both_Interfaces
    [Setup]  Run Keywords  Configure IPv4 And IPv6 On Both Interfaces
    ...      AND  Set SLAAC Property On Eth0 And Eth1
    [Template]  Coexistence Of IP Addresses

    # Channel_number   ip_type1       ip_type2      ip_type3
    1                  Staticv4       Staticv6
    2                  Staticv4       Staticv6
    1                  Staticv4       Staticv6       SLAACv6


Verify Coexistence Of Staticv4 Staticv6 And DHCPv6 On Both Interfaces
    [Documentation]  Verify coexistence of Staticv4 Staticv6 and DHCPv6 on both interfaces.
    [Tags]   Verify_Coexistence_Of_Staticv4_Staticv6_And_DHCPv6_On_Both_Interfaces
    [Setup]  Run Keywords  Configure IPv4 And IPv6 On Both Interfaces
    ...      AND  Set And Verify DHCPv6 States  Enabled  Enabled
    [Template]  Coexistence Of IP Addresses

    # Note: DHCPv6 setup must be present.
    # Channel_number   ip_type1       ip_type2      ip_type3
    1                  Staticv4       Staticv6      DHCPv6
    2                  Staticv4       Staticv6      DHCPv6


Verify Coexistence Of LinkLocalv4 Staticv6 SLAACv6 And DHCPv6 On Both Interfaces
    [Documentation]  Verify coexistence of LinkLocalv4 Staticv6 SLAACv6 and DHCPv6 on both interfaces.
    [Tags]  Verify_Coexistence_Of_LinkLocalv4_Staticv6_SLAACv6_And_DHCPv6_On_Both_Interfaces
    [Setup]  Run Keywords  Add Static IPv6 Address And Verify Via GUI  ${test_ipv6_addr_2}
    ...      ${test_prefix_length}  Success
    ...      AND  Add Static IPv6 Address And Verify Via GUI  ${test_ipv6_addr}
    ...      ${test_prefix_length}  Success  None  2
    ...      AND  Set SLAAC Property On Eth0 And Eth1
    ...      AND  Set And Verify DHCPv6 States  Enabled  Enabled
    [Template]  Coexistence Of IP Addresses

    # Note: DHCPv6 and SLAACv6 setup must be present.
    # Channel_number   ip_type1       ip_type2      ip_type3   ip_type4
    1                  LinkLocalv4    Staticv6      SLAACv6    DHCPv6
    2                  LinkLocalv4    Staticv6      SLAACv6    DHCPv6


Verify Coexistence Of Multiple IPs On Both Interfaces
    [Documentation]  Verify coexistence of staticv4,staticv6,dhcpv6,slaacv6,dhcpv4,
    ...  linklocalv4 on both interfaces.
    [Tags]   Verify_Coexistence_Of_Multiple_IPs_On_Both_Interfaces
    [Setup]  Run Keywords  Configure IPv4 And IPv6 On Both Interfaces
    ...      AND  Set And Verify DHCPv6 States  Enabled  Enabled
    ...      AND  Set SLAAC Property On Eth0 And Eth1
    ...      AND  Toggle DHCPv4 State And Verify  Enabled  2
    [Template]  Coexistence Of IP Addresses
    [Teardown]  Run Keywords  Add Static IP Address And Verify  ${test_ipv4_addr_1}
    ...      ${test_subnet_mask}  ${default_gateway_2}  Success  2
    ...      AND  Click Element  ${xpath_refresh_button}
    ...      AND  Delete IP Address And Verify  ipv6  ${test_ipv6_addr_2}

    # Note: DHCPv6 DHCPv4 and SLAACv6 setup must be present.
    # Channel_number   ip_type1       ip_type2      ip_type3   ip_type4
    1                  Staticv4       Staticv6      DHCPv6     SLAACv4
    2                  DHCPv4         Staticv6      DHCPv6     SLAACv6
    1                  LinkLocalv4    Staticv6      DHCPv6     SLAACv4


Verify Coexistence Of DHCPv4 LinkLocalv6 On Eth1
    [Documentation]  Verify coexistence of DHCPv4 and Linklocalv6 on eth1 via GUI.
    [Tags]   Verify_Coexistence_Of_DHCPv4_LinkLocalv6_On_Eth1
    [Setup]  Toggle DHCPv4 State And Verify  Enabled
    [Template]  Coexistence Of IP Addresses
    [Teardown]  Add Static IP Address And Verify  ${test_ipv4_addr_1}
    ...         ${test_subnet_mask}  ${default_gateway_2}  Success  2

    # Note: DHCPv4 setup must be present.
    # Channel_number   ip_type1       ip_type2
    2                  DHCPv4         LinkLocalv6


Verify Eth1 DHCPv4 Functionality In The Presence Of DHCPv6 Via GUI
    [Documentation]  Verify eth1 DHCPv4 functionality in the presence of DHCPv6 via GUI.
    ...    Run on setup with DHCPv4 available on eth1.
    [Tags]  Verify_Eth1_DHCPv4_Functionality_In_The_Presence_Of_DHCPv6_Via_GUI
    [Setup]  Run Keywords  Set And Verify DHCPv6 States  Disabled  Enabled
    ...  AND  Toggle DHCPv4 State And Verify  Enabled  2

    # Verify presence of DHCPv6 address and origin.
    Sleep  ${NETWORK_TIMEOUT}s
    @{ipv6_address_origin_list}  ${dhcpv6_addr}=
    ...  Get Address Origin List And Address For Type  DHCPv6  2
    Should Contain  ${ipv6_address_origin_list}  DHCPv6
    Should Not Be Empty  ${dhcpv6_addr}  msg=DHCPv6 address is not present.

    # Verify DHCPv6 button status in GUI.
    ${dhcpv6_status}=  Get Text  ${xpath_eth1_dhcpv6_button}
    Should Be Equal  ${dhcpv6_status}  Enabled

    Verify Functionality Of IPv4 Address  DHCP  2


Verify Eth0 Static IPv4 Functionality In The Presence Of DHCPv6 Via GUI
    [Documentation]  Verify eth0 static IPv4 functionality in the presence of DHCPv6 via GUI.
    [Tags]  Verify_Eth0_Static_IPv4_Functionality_In_The_Presence_Of_DHCPv6_Via_GUI
    [Setup]  Set And Verify DHCPv6 States  Enabled  Disabled

    # Verify presence of DHCPv6 address and origin.
    Sleep  ${NETWORK_TIMEOUT}s
    @{ipv6_address_origin_list}  ${dhcpv6_addr}=
    ...  Get Address Origin List And Address For Type  DHCPv6  1
    Should Contain  ${ipv6_address_origin_list}  DHCPv6
    Should Not Be Empty  ${dhcpv6_addr}  msg=DHCPv6 address is not present.

    # Verify DHCPv6 button status in GUI.
    ${dhcpv6_status}=  Get Text  ${xpath_eth0_dhcpv6_button}
    Should Be Equal  ${dhcpv6_status}  Enabled

    Verify Functionality Of IPv4 Address  Static  1


Verify Eth0 Static IPv4 Functionality In The Presence Of Staticv6 Via GUI
    [Documentation]  Verify eth0 static IPv4 functionality in the presence of Staticv6 via GUI.
    [Tags]   Verify_Eth0_Static_IPv4_Functionality_In_The_Presence_Of_Staticv6_Via_GUI
    [Setup]  Add Static IPv6 Address And Verify Via GUI  ${test_ipv6_addr_2}
    ...      ${test_prefix_length}  Success
    [Teardown]  Delete IP Address And Verify  ipv6  ${test_ipv6_addr_2}

    # Verify Presence of Staticv6 address and origin.
    @{ipv6_address_origin_list}  ${staticv6_addr}=
    ...  Get Address Origin List And Address For Type  Static  1
    Should Contain  ${ipv6_address_origin_list}  Static
    Should Not Be Empty  ${staticv6_addr}  msg=Staticv6 address is not present.

    Verify Functionality Of IPv4 Address  Static  1


Verify Eth1 Static IPv4 Functionality In The Presence Of Staticv6 Via GUI
    [Documentation]  Verify eth1 static IPv4 functionality in the presence of Staticv6 via GUI.
    [Tags]   Verify_Eth1_Static_IPv4_Functionality_In_The_Presence_Of_Staticv6_Via_GUI
    [Setup]  Add Static IPv6 Address And Verify Via GUI  ${test_ipv6_addr_2}
    ...      ${test_prefix_length}  Success  None  2
    [Teardown]  Run Keyword And Ignore Error
    ...         Delete IP Address And Verify  ipv6  ${test_ipv6_addr_2}

    # Verify Presence of Staticv6 address and origin.
    @{ipv6_address_origin_list}  ${staticv6_addr}=
    ...  Get Address Origin List And Address For Type  Static  2
    Should Contain  ${ipv6_address_origin_list}  Static
    Should Not Be Empty  ${staticv6_addr}  msg=Staticv6 address is not present.

    Verify Functionality Of IPv4 Address  Static  2


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
    ${default_gateway_2}=  Get BMC Default Gateway  2
    Set Suite Variable  ${default_gateway_2}
    ${ipv4_eth1}=  Get IPv4 Values From Eth1
    Set Suite Variable  ${ipv4_eth1}

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
    [Arguments]  ${ip_address}  ${subnet_mask}  ${gateway_address}
    ...          ${expected_status}=error  ${CHANNEL_NUMBER}=1

    # Description of argument(s):
    # ip_address          IP address to be added (e.g. 10.7.7.7).
    # subnet_mask         Subnet mask for the IP to be added (e.g. 255.255.0.0).
    # gateway_address     Gateway address for the IP to be added (e.g. 10.7.7.1).
    # expected_status     Expected status while adding static IPv4 address
    # ....                (e.g. Invalid format / Field required).
    # CHANNEL_NUMBER      Channel number: 1 for eth0, 2 for eth1.

    Wait Until Element Is Enabled  ${xpath_add_static_ipv4_addr_btn_eth0}  timeout=60sec
    IF  '${CHANNEL_NUMBER}' == '1'
      Click Element  ${xpath_eth0_interface}
      Click Element  ${xpath_add_static_ipv4_addr_btn_eth0}
    ELSE
      Click Element  ${xpath_eth1_interface}
      Click Element  ${xpath_add_static_ipv4_addr_btn_eth1}
    END

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
    ...          ${expected_ipv6}=None  ${CHANNEL_NUMBER}=1

    # Description of argument(s):
    # ipv6_address        IPv6 address to be added.
    # prefix_length       Prefix length of the IPv6 to be added.
    # expected_status     Expected status while adding static IPv6 address.
    # expected_ipv6       Expected IPv6 which gets added with truncated zeroes.
    # CHANNEL_NUMBER      Channel number: 1 for eth0, 2 for eth1.

    Wait Until Element Is Enabled  ${xpath_add_static_ipv6_addr_btn_eth0}  timeout=60sec
    IF  '${CHANNEL_NUMBER}' == '1'
      Click Element  ${xpath_eth0_interface}
      Click Element  ${xpath_add_static_ipv6_addr_btn_eth0}
    ELSE
      Click Element  ${xpath_eth1_interface}
      Click Element  ${xpath_add_static_ipv6_addr_btn_eth1}
    END

    Input Text  ${xpath_input_ip_address}  ${ipv6_address}
    Input Text  ${xpath_input_prefix_length}  ${prefix_length}

    Click Element  ${xpath_add_button}
    IF  '${expected_status}' == 'Success'
        IF  '${expected_ipv6}' == 'None'
            Wait Until Page Contains  ${ipv6_address}  timeout=40sec
        ELSE
            Wait Until Page Contains  ${expected_ipv6}  timeout=40sec
        END
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


Delete IP Address And Verify
    [Documentation]  Delete IPv4 or IPv6 address and verify deletion via GUI and BMC.
    [Arguments]  ${ip_version}  ${ip_addr}

    # Description of argument(s):
    # ip_version   Either 'ipv4' or 'ipv6'.
    # ip_addr      IP address to be deleted.

    ${delete_xpath}=  Set Variable If  '${ip_version}' == 'ipv4'
    ...  ${xpath_delete_ipv4_addres}  ${xpath_delete_ipv6_addres}

    Wait Until Element Is Not Visible  ${xpath_page_loading_progress_bar}  timeout=120s
    Wait Until Element Is Enabled  ${delete_xpath}

    Click Element  ${delete_xpath}
    Click Element  ${xpath_delete_button}
    Wait Until Page Contains Element  ${xpath_success_message}
    Sleep  ${NETWORK_TIMEOUT}s

    # Verify IP on BMC is deleted.
    IF  '${ip_version}' == 'ipv4'
        ${delete_status}=  Run Keyword And Return Status  Verify IP On BMC  ${ip_addr}
    ELSE
        ${delete_status}=  Run Keyword And Return Status  Verify IPv6 On BMC  ${ip_addr}
    END

    Should Be Equal  ${delete_status}  ${False}
    Wait Until Page Does Not Contain  ${ip_addr}


Modify IP Address And Verify
    [Documentation]  Modify IPv4 or IPv6 address via GUI.
    [Arguments]  ${ip_version}  ${old_ip}  ${new_ip}

    # Description of argument(s):
    # ip_version   Either 'ipv4' or 'ipv6'.
    # old_ip       The existing IP address visible on GUI(ipv4 or ipv6).
    # new_ip       The new IP address to update(ipv4 or ipv6).

    Wait Until Element Is Not Visible  ${xpath_page_loading_progress_bar}  timeout=120s

    # Edit button based on version.
    ${edit_button}=  Set Variable If  '${ip_version}' == 'ipv4'
    ...  ${xpath_edit_ipv4_addres}  ${xpath_edit_ipv6_addres}
    Wait Until Element Is Enabled  ${edit_button}
    Click Element  ${edit_button}

    # Add new IP and save.
    Input Text  ${xpath_input_ip_address}  ${new_ip}
    Click Element  ${xpath_add_button}

    Wait Until Page Contains Element  ${xpath_success_message}
    Sleep  ${NETWORK_TIMEOUT}s

    # Verify IP on BMC.
    IF  '${ip_version}' == 'ipv4'
      ${edit_status}=  Run Keyword And Return Status  Verify IP On BMC  ${new_ip}
    ELSE
      ${edit_status}=  Run Keyword And Return Status  Verify IPv6 On BMC  ${new_ip}
    END

    Should Be Equal  ${edit_status}  ${True}
    Wait Until Page Contains  ${new_ip}


Delete Default IPv6 Gateway And Verify
   [Documentation]  Delete default IPv6 gateway and verify.
   [Arguments]  ${ip_addr}

   # Description of argument(s):
   # ip_addr      IP address to be deleted.

   Wait Until Page Contains  ${ip_addr}
   Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=120s
   Wait Until Element Is Enabled  ${xpath_delete_ipv6_def_gateway_addr}
   Click Element  ${xpath_delete_ipv6_def_gateway_addr}
   Click Element  ${xpath_delete_button}
   Wait Until Page Contains Element   ${xpath_success_message}
   Sleep  ${NETWORK_TIMEOUT}s

   # Verify delete IP via redfish.
   ${delete_status}=  Run Keyword And Return Status  Get Static Default Gateway Property Via Redfish
   Should Be Equal  ${delete_status}  ${False}

   Wait Until Page Does Not Contain Element  ${xpath_delete_ipv6_def_gateway_addr}


Modify Default IPv6 Gateway And Verify
    [Documentation]  Modify Default IPv6 Gateway And Verify.
    [Arguments]  ${old_static_def_gw}  ${new_static_def_gw}

    # Description of argument(s):
    # old_static_def_gw       The existing IPv6 address visible on GUI.
    # new_static_def_gw       The new IPv6 address to update.

    Wait Until Element Is Not Visible  ${xpath_page_loading_progress_bar}  timeout=120s
    Wait Until Element Is Enabled  ${xpath_edit_ipv6_def_gateway_addr}
    Click Element  ${xpath_edit_ipv6_def_gateway_addr}

    # Add new IP and save.
    Input Text  ${xpath_input_ip_address}  ${new_static_def_gw}
    Click Element  ${xpath_add_button}

    Wait Until Page Contains Element  ${xpath_success_message}
    Sleep  ${NETWORK_TIMEOUT}s

    # Verify IP via redfish.
    ${new_static_def_gw_redfish}=  Get Static Default Gateway Property Via Redfish
    Should Be Equal  ${new_static_def_gw}  ${new_static_def_gw_redfish}

    Wait Until Page Contains Element  ${xpath_edit_ipv6_def_gateway_addr_1}


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
    [Documentation]  Set SLAAC state and verify.
    [Arguments]    ${desired_autoconfig_state}  ${channel_number}

    # Description of argument(s):
    # desired_autoconfig_state      IPv6 autoconfig Toggle state(eg: Enabled or Disabled).
    # xpath_ipv6_autoconfig_button  xpath of eth0 or eth1 ipv6 autoconfig button.

    IF  '${channel_number}' == '1'
      ${xpath_autoconfig_button}=  Set Variable  ${xpath_eth0_autoconfig_button}
      Click Element  ${xpath_eth0_interface}
      Set Suite Variable  ${CHANNEL_NUMBER}  1
    ELSE IF  '${channel_number}' == '2'
      ${xpath_autoconfig_button}=  Set Variable  ${xpath_eth1_autoconfig_button}
      Click Element  ${xpath_eth1_interface}
      Set Suite Variable  ${CHANNEL_NUMBER}  2
    END

    ${current_autoconfig_state}=    Get Text    ${xpath_autoconfig_button}

    IF  '${desired_autoconfig_state}' == '${current_autoconfig_state}'
      Perform SLAAC Toggle  ${xpath_autoconfig_button}  ${channel_number}
      Perform SLAAC Toggle  ${xpath_autoconfig_button}  ${channel_number}
    ELSE
      Perform SLAAC Toggle  ${xpath_autoconfig_button}  ${channel_number}
    END

    Wait Until Keyword Succeeds  2 min  30 sec
    ...  Element Text Should Be  ${xpath_autoconfig_button}  ${desired_autoconfig_state}

    IF  '${desired_autoconfig_state}' == 'Enabled'
      Verify SLAAC Address On Autoconfig Enable
    ELSE IF  '${desired_autoconfig_state}' == 'Disabled'
      Wait Until Page Does Not Contain  SLAAC  timeout=60s
    END
    Reload Page
    Wait Until Element Is Not Visible  ${xpath_page_loading_progress_bar}  timeout=120s


Perform SLAAC Toggle
    [Documentation]  Toggle SLAAC button.
    [Arguments]  ${xpath_autoconfig_button}  ${channel_number}

    # Description of argument(s):
    # xpath_autoconfig_button   SLAAC Toggle button xpath.
    # channel_number            Channel number: 1 for eth0, 2 for eth1.

    Reload Page
    Wait Until Element Is Enabled  ${xpath_autoconfig_button}  timeout=60s

    IF  '${channel_number}' == '2'
      Click Element  ${xpath_eth1_interface}
    END

    Click Element  ${xpath_autoconfig_button}
    Wait Until Element Is Not Visible  ${xpath_page_loading_progress_bar}  timeout=120s


Set SLAAC Property On Eth0 And Eth1
    [Documentation]  Enable or Disable and verify slaac on both interfaces.
    [Arguments]  ${State}=Enabled

    # Description of argument(s):
    # ${State}  Enabled or Disabled on both interfaces

    Set IPv6 AutoConfig State  ${State}  1
    Set IPv6 AutoConfig State  ${State}  2


Verify SLAAC Address On Autoconfig Enable
    [Documentation]  Verify SLAAC IPv6 on autoconfig enable.

    TRY
      Sleep  ${NETWORK_TIMEOUT}
      @{ipv6_address_origin_list}  ${ipv6_slaac_addr}=
    ...    Get Address Origin List And Address For Type  SLAAC
    EXCEPT
      Log  SLAAC gateway setup not Enabled!  WARN
      RETURN
    ELSE
      Wait Until Page Contains  ${ipv6_slaac_addr}  timeout=60sec
      Wait Until Page Contains  SLAAC  timeout=60sec
    END


Toggle DHCPv4 State And Verify
    [Documentation]  Toggle DHCPv4 state and verify for eth1.
    [Arguments]  ${desired_dhcpv4_state}  ${channel_number}=2

    # Description of argument(s):
    # desired_dhcpv4_state  DHCPv4 Toggle state (Enabled or Disabled).
    # channel_number        Channel number: 1 for eth0, 2 for eth1.

    IF  '${channel_number}' == '1'
      ${xpath_dhcpv4_button}=  Set Variable  ${xpath_eth0_dhcpv4_button}
      Click Element  ${xpath_eth0_interface}
      Set Suite Variable  ${CHANNEL_NUMBER}  1
    ELSE IF  '${channel_number}' == '2'
      ${xpath_dhcpv4_button}=  Set Variable  ${xpath_eth1_dhcpv4_button}
      Click Element  ${xpath_eth1_interface}
      Set Suite Variable  ${CHANNEL_NUMBER}  2
    END

    ${current_dhcpv4_state}=  Get Text  ${xpath_dhcpv4_button}

    IF  '${desired_dhcpv4_state}' == '${current_dhcpv4_state}'
      Perform DHCPv4 Toggle  ${xpath_dhcpv4_button}  ${channel_number}
      Perform DHCPv4 Toggle  ${xpath_dhcpv4_button}  ${channel_number}
    ELSE
      Perform DHCPv4 Toggle  ${xpath_dhcpv4_button}  ${channel_number}
    END

    Wait Until Keyword Succeeds  2 min  30 sec
    ...  Element Text Should Be  ${xpath_dhcpv4_button}  ${desired_dhcpv4_state}

    IF  '${desired_dhcpv4_state}' == 'Enabled'
      TRY
        @{ipv4_addressorigin_list}  ${ipv4_addr_list}=
        ...  Get Address Origin List And IPv4 or IPv6 Address  IPv4Addresses
        Should Contain  ${ipv4_addressorigin_list}  DHCP
      EXCEPT
        Log  DHCP setup is missing!  WARN
        RETURN
      ELSE
        Wait Until Element Contains  ${ipv4_elements}  DHCP  timeout=30s
      END
    ELSE IF  '${desired_dhcpv4_state}' == 'Disabled'
      Element Should Not Contain  ${ipv4_elements}  DHCP  timeout=60s
    END
    Reload Page
    Wait Until Element Is Not Visible  ${xpath_page_loading_progress_bar}  timeout=120s


Perform DHCPv4 Toggle
    [Documentation]  Toggle DHCPv4 button.
    [Arguments]  ${xpath_dhcpv4_button}  ${channel_number}

    # Description of argument(s):
    # xpath_dhcpv4_button   DHCPv4 Toggle button xpath.
    # channel_number        Channel number: 1 for eth0, 2 for eth1.

    Reload Page
    Wait Until Element Is Enabled  ${xpath_dhcpv4_button}  timeout=60s

    IF  '${channel_number}' == '2'
      Click Element  ${xpath_eth1_interface}
    END

    Click Element  ${xpath_dhcpv4_button}
    Click Element  ${xpath_dhcpv4_alert}
    Wait Until Element Is Not Visible  ${xpath_page_loading_progress_bar}  timeout=120s


Toggle DHCPv6 State And Verify
    [Documentation]  Toggle DHCPv6 state and verify.
    [Arguments]  ${desired_dhcpv6_state}  ${channel_number}

    # Description of argument(s):
    # desired_dhcpv6_state  DHCPv6 Toggle state (Enabled or Disabled).
    # channel_number        Channel number: 1 for eth0, 2 for eth1.

    IF  '${channel_number}' == '1'
      ${xpath_dhcpv6_button}=  Set Variable  ${xpath_eth0_dhcpv6_button}
      Click Element  ${xpath_eth0_interface}
      Set Suite Variable  ${CHANNEL_NUMBER}  1
    ELSE IF  '${channel_number}' == '2'
      ${xpath_dhcpv6_button}=  Set Variable  ${xpath_eth1_dhcpv6_button}
      Click Element  ${xpath_eth1_interface}
      Set Suite Variable  ${CHANNEL_NUMBER}  2
    END

    ${current_dhcpv6_state}=  Get Text  ${xpath_dhcpv6_button}

    IF  '${desired_dhcpv6_state}' == '${current_dhcpv6_state}'
      Perform DHCPv6 Toggle  ${xpath_dhcpv6_button}  ${channel_number}
      Perform DHCPv6 Toggle  ${xpath_dhcpv6_button}  ${channel_number}
    ELSE
      Perform DHCPv6 Toggle  ${xpath_dhcpv6_button}  ${channel_number}
    END

    Wait Until Keyword Succeeds  2 min  30 sec
    ...  Element Text Should Be  ${xpath_dhcpv6_button}  ${desired_dhcpv6_state}

    IF  '${desired_dhcpv6_state}' == 'Enabled'
      Verify DHCPv6 Address On Enable
    ELSE IF  '${desired_dhcpv6_state}' == 'Disabled'
      Wait Until Page Does Not Contain  DHCPv6  timeout=60s
    END
    Reload Page
    Wait Until Element Is Not Visible  ${xpath_page_loading_progress_bar}  timeout=120s


Perform DHCPv6 Toggle
    [Documentation]  Toggle DHCPv6 button.
    [Arguments]  ${xpath_dhcpv6_button}  ${channel_number}

    # Description of argument(s):
    # xpath_dhcpv6_button   DHCPv6 Toggle button xpath.
    # channel_number        Channel number: 1 for eth0, 2 for eth1.

    Reload Page
    Wait Until Element Is Enabled  ${xpath_dhcpv6_button}  timeout=60s

    IF  '${channel_number}' == '2'
      Click Element  ${xpath_eth1_interface}
    END

    Click Element  ${xpath_dhcpv6_button}
    Wait Until Element Is Not Visible  ${xpath_page_loading_progress_bar}  timeout=120s


Verify DHCPv6 Address On Enable
    [Documentation]  Verify DHCPv6 on enable, if missing log warning and continue.

    TRY
      @{ipv6_address_origin_list}  ${ipv6_dhcpv6_addr}=
      ...  Get Address Origin List And Address For Type  DHCPv6
    EXCEPT
      Log  DHCPv6 setup is missing!  WARN
      RETURN
    ELSE
      Wait Until Page Contains  ${ipv6_dhcpv6_addr}  timeout=30s
      Wait Until Page Contains  DHCPv6  timeout=30s
    END


Set And Verify DHCPv6 States
    [Documentation]  Set and verify DHCPv6 states.
    [Arguments]  ${eth0_state}  ${eth1_state}

    # Description of argument(s):
    # eth0_state    DHCPv6 toggle state of eth0(Enabled or Disabled).
    # eth1_state    DHCPv6 toggle state of eth1(Enabled or Disabled).

    # Channel 1: eth0.
    Toggle DHCPv6 State And Verify  ${eth0_state}  1
    # Channel 2: eth1.
    Toggle DHCPv6 State And Verify  ${eth1_state}  2


Verify Persistency Of IPv6 On BMC Reboot
    [Documentation]  Verify IPv6 persistency on BMC reboot for the specified interface.
    [Arguments]  ${ipv6_type}  ${channel_number}=${CHANNEL_NUMBER}

    # Description of argument(s):
    # ipv6_type       Type of IPv6 address(e.g:slaac/static/linklocal).
    # channel_number  Ethernet channel number, 1(eth0) or 2(eth1).

    IF  '${channel_number}' == '1'
        # Capture IPv6 addresses before reboot.
        Set Suite Variable  ${CHANNEL_NUMBER}  1
        @{ipv6_address_origin_list}  ${addr_before_reboot}=
        ...  Get Address Origin List And Address For Type  ${ipv6_type}

        Reboot BMC via GUI
        Launch Browser Login GUI And Navigate To Network Page

        # Capture IPv6 addresses after reboot.
        Set Suite Variable  ${CHANNEL_NUMBER}  1
        @{ipv6_address_origin_list}  ${addr_after_reboot}=
        ...  Get Address Origin List And Address For Type  ${ipv6_type}

        Should Be Equal    ${addr_before_reboot}    ${addr_after_reboot}
        Click Element  ${xpath_network_sub_menu}
    ELSE IF  '${channel_number}' == '2'
        # Capture IPv6 addresses before reboot.
        Set Suite Variable  ${CHANNEL_NUMBER}  2
        @{ipv6_address_origin_list}  ${addr_before_reboot}=
        ...  Get Address Origin List And Address For Type  ${ipv6_type}

        Reboot BMC via GUI
        Launch Browser Login GUI And Navigate To Network Page

        # Capture IPv6 addresses after reboot.
        Set Suite Variable  ${CHANNEL_NUMBER}  2
        @{ipv6_address_origin_list}  ${addr_after_reboot}=
        ...  Get Address Origin List And Address For Type  ${ipv6_type}

        Should Be Equal    ${addr_before_reboot}    ${addr_after_reboot}
        Click Element  ${xpath_network_sub_menu}
        Click Element  ${xpath_eth1_interface}
    END
    Wait Until Page Contains  ${addr_after_reboot}
    Wait Until Page Contains  ${ipv6_type}


Collect All IP Addresses On Both Interfaces
    [Documentation]  Collecting all the IP addresses on both interfaces.
    [Arguments]  ${ip_version}  ${channel_number}

    # Description of argument(s):
    # ip_version      Either 'ipv4' or 'ipv6'.
    # channel_number  Ethernet channel number, 1(eth0) or 2(eth1).

    IF  '${channel_number}' == '1'
      Wait Until Element Is Enabled  ${xpath_eth1_interface}  timeout=60s
      Click Element  ${xpath_eth0_interface}
    ELSE
      Wait Until Element Is Enabled  ${xpath_eth1_interface}  timeout=60s
      Click Element  ${xpath_eth1_interface}
    END

    IF  '${ip_version}' == 'ipv4'
      Wait Until Element Is Enabled  ${xpath_add_static_ipv4_addr_btn_eth0}  timeout=30s
      ${ip_elements}=  Get WebElements  ${ipv4_elements}
    ELSE IF  '${ip_version}' == 'ipv6'
      Wait Until Element Is Enabled  ${xpath_add_static_ipv6_addr_btn_eth0}  timeout=30s
      ${ip_elements}=  Get WebElements  ${ipv6_elements}
    ELSE
      Fail  Invalid IP version provided. Use 'ipv4' or 'ipv6'.
    END

    ${ip_list}=  Create List
    FOR  ${elem}  IN  @{ip_elements}
      ${ip}=  Get Text  ${elem}
      ${ip}=  Strip String  ${ip}
      IF  '${ip}' != '' and '${ip}' != 'No items available'
        Append To List  ${ip_list}  ${ip}
      END
    END
    RETURN  ${ip_list}


Enable Or Disable DHCPv6 And Verify Impact On IPv4 Settings
    [Documentation]  Enable or Disable DHCPv6 and it does not have impact on IPv4 settings.
    [Arguments]  ${ip_version}  ${channel_number}  ${desired_dhcpv6_state}

    # Description of argument(s):
    # ip_version            Either 'ipv4' or 'ipv6'.
    # channel_number        Ethernet channel number, 1(eth0) or 2(eth1).
    # desired_dhcpv6_state  DHCPv6 Toggle state (Enabled or Disabled).

    # Capture IPv4 addresses before disabling DHCPv6.
    ${ipv4_before}=  Collect All IP Addresses On Both Interfaces  ${ip_version}  ${channel_number}

    Toggle DHCPv6 State And Verify  ${desired_dhcpv6_state}  ${channel_number}
    Sleep  ${NETWORK_TIMEOUT}
    Reload Page
    Wait Until Element Is Enabled  ${xpath_static_ipv4}  timeout=30s

    # Capture IPv4 addresses after disabling DHCPv6.
    ${ipv4_after}=  Collect All IP Addresses On Both Interfaces  ${ip_version}  ${channel_number}
    Lists Should Be Equal  ${ipv4_before}  ${ipv4_after}  ignore_order=True


Get IPv4 Values From Eth1
    [Documentation]  Capturing IPv4 values before DHCP toggle.

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${2}']['name']}
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    @{network_configurations}=  Get From Dictionary  ${resp.dict}  IPv4StaticAddresses
    RETURN  @{network_configurations}


Assign Static IP Address on Eth1
    [Documentation]  Assigning static IPv4 on eth1.

    Sleep  ${NETWORK_TIMEOUT}
    FOR  ${ip}  IN  @{ipv4_eth1}
      Add Static IP Address And Verify  ${ip['Address']}  ${ip['SubnetMask']}  ${ip['Gateway']}  Success  2
    END


Coexistence Of IP Addresses
    [Documentation]  Checking coexistence of IP addresses on both interfaces.
    [Arguments]  ${channel_number}  @{address_types}

    # Description of argument(s):
    # channel_number   Ethernet channel number, 1(eth0) or 2(eth1).
    # address_types    Type of IPv4/IPv6 address(slaac/linklocal/dhcp/static).

    IF  '${channel_number}' == '1'
      Wait Until Element Is Enabled  ${xpath_eth0_interface}  timeout=60s
      Click Element  ${xpath_eth0_interface}
    ELSE
      Wait Until Element Is Enabled  ${xpath_eth1_interface}  timeout=60s
      Click Element  ${xpath_eth1_interface}
    END

    # Get IPv4 origins
    ${ipv4_elems}=  Get WebElements  ${ipv4_addr_origin_elements}
    ${ipv4_list}=  Get IP Origins  @{ipv4_elems}

    # Get IPv6 origins
    ${ipv6_elems}=  Get WebElements  ${ipv6_addr_origin_elements}
    ${ipv6_list}=  Get IP Origins  @{ipv6_elems}

    # Validate all expected types
    FOR  ${type}  IN  @{address_types}
      Validate Expected IPv4 And IPv6 Origin  ${type}  ${ipv4_list}  ${ipv6_list}
    END


Get IP Origins
    [Documentation]  Getting IP Origins.
    [Arguments]  @{elements}

    # Description of argument(s):
    # elements   List of IPv4 or IPv6 origins.

    ${list}=  Create List
    FOR  ${e}  IN  @{elements}
      ${t}=  Strip String  ${e.text}
      IF  '${t}' != '' and '${t}' != 'No items available'
        Append To List  ${list}  ${t}
      END
    END
    RETURN  ${list}


Validate Expected IPv4 And IPv6 Origin
    [Documentation]  Validate IPv4 and IPv6 origin.
    [Arguments]  ${type}  ${ipv4_list}  ${ipv6_list}

    # Description of argument(s):
    # type       Type of IP address(IPv4/IPv6).
    # ipv4_list  List of IPv4 origins.
    # ipv6_list  List of IPv6 origins.

    ${origin}=  Replace String  ${type}    v4  ${EMPTY}
    ${origin}=  Replace String  ${origin}  v6  ${EMPTY}

    IF  $type.endswith('v4')
      ${target_list}=  Set Variable  ${ipv4_list}
    ELSE
      ${target_list}=  Set Variable  ${ipv6_list}
    END

    Should Contain  ${target_list}  ${origin}


Configure IPv4 And IPv6 On Both Interfaces
    [Documentation]  Add IPv4 and IPv6 on both interfaces.

    Add Static IP Address And Verify  ${test_ipv4_addr}  ${test_subnet_mask}
    ...  ${default_gateway}  Success
    Add Static IP Address And Verify  ${test_ipv4_addr_1}  ${test_subnet_mask}
    ...  ${default_gateway_2}  Success  2
    Add Static IPv6 Address And Verify Via GUI  ${test_ipv6_addr_2}
    ...  ${test_prefix_length}  Success
    Add Static IPv6 Address And Verify Via GUI  ${test_ipv6_addr}
    ...  ${test_prefix_length}  Success  None  2


Enable Or Disable SLAAC And Verify Impact On Existing Settings
    [Documentation]  Enable or disable slaac and verify impact on existing settings.
    [Arguments]  ${ip_version}  ${channel_number}  ${desired_slaac_state}

    # Description of argument(s):
    # ip_version            Either 'ipv4' or 'ipv6'.
    # channel_number        Ethernet channel number, 1(eth0) or 2(eth1).
    # desired_slaac_state   Set autoconfig state (Enabled or Disabled).

    # Capture existing settings on both interfaces before changing slaac state.
    ${ip_addresses_before_eth0}=  Collect All IP Addresses On Both Interfaces  ${ip_version}  1
    ${ip_addresses_before_eth1}=  Collect All IP Addresses On Both Interfaces  ${ip_version}  2

    IF  '${channel_number}' == '1'
        Click Element  ${xpath_eth0_interface}
        Set IPv6 AutoConfig State  ${desired_slaac_state}  ${channel_number}
    ELSE
        Click Element  ${xpath_eth1_interface}
        Set IPv6 AutoConfig State  ${desired_slaac_state}  ${channel_number}
    END

    Sleep  ${NETWORK_TIMEOUT}

    # Capture settings on both interfaces after changing slaac state.
    ${ip_addresses_after_eth0}=  Collect All IP Addresses On Both Interfaces  ${ip_version}  1
    ${ip_addresses_after_eth1}=  Collect All IP Addresses On Both Interfaces  ${ip_version}  2

    # Verify existing  network settings remains intact after slaac state change.
    Lists Should Be Equal  ${ip_addresses_before_eth0}  ${ip_addresses_after_eth0}  ignore_order=True
    Lists Should Be Equal  ${ip_addresses_before_eth1}  ${ip_addresses_after_eth1}  ignore_order=True
