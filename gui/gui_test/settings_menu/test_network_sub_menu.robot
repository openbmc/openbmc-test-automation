*** Settings ***
Documentation       Test OpenBMC GUI "Network" sub-menu of "Settings".

Resource            ../../lib/gui_resource.robot
Resource            ../../../lib/bmc_network_utils.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Close Browser

Test Tags           network_sub_menu


*** Variables ***
${xpath_network_heading}                    //h1[text()="Network"]
${xpath_interface_settings}                 //h2[text()="Interface settings"]
${xpath_network_settings}                   //h2[text()="Network settings"]
${xpath_static_ipv4}                        //h2[text()="IPv4"]
${xpath_domain_name_toggle}                 //*[@data-test-id="networkSettings-switch-useDomainName"]
${xpath_ntp_servers_toggle}                 //*[@data-test-id="networkSettings-switch-useNtp"]
${xpath_add_static_ipv4_address_button}     //button[contains(text(),"Add static IPv4 address")]
${xpath_hostname}                           //*[@title="Edit hostname"]
${xpath_hostname_input}                     //*[@id="hostname"]
${xpath_input_ip_address}                   //*[@id="ipAddress"]
${xpath_input_gateway}                      //*[@id="gateway"]
${xpath_input_subnetmask}                   //*[@id="subnetMask"]
${xpath_cancel_button}                      //button[contains(text(),'Cancel')]
${xpath_delete_dns_server}                  //*[@title="Delete DNS address"]
${xpath_save_button}                        //button[contains(text(),'Save')]
${xpath_dhcp_toggle_switch}                 //*[@id='dhcpSwitch']

${dns_server}                               10.10.10.10
${test_ipv4_addr}                           10.7.7.7
${test_ipv4_addr_1}                         10.7.7.8
${out_of_range_ip}                          10.7.7.256
${string_ip}                                aa.bb.cc.dd
${negative_ip}                              10.-7.-7.-7
${less_octet_ip}                            10.3.36
${hex_ip}                                   0xa.0xb.0xc.0xd
${spl_char_ip}                              @@@.%%.44.11
${test_subnet_mask}                         255.255.0.0
${alpha_netmask}                            ff.ff.ff.ff
${out_of_range_netmask}                     255.256.255.0
${more_byte_netmask}                        255.255.255.0.0
${lowest_netmask}                           128.0.0.0
${test_hostname}                            openbmc


*** Test Cases ***
Verify Navigation To Network Page
    [Documentation]    Login to GUI and navigate to the settings sub-menu network page.
    [Tags]    verify_navigation_to_network_page

    Page Should Contain Element    ${xpath_network_heading}

Verify Existence Of All Sections In Network Page
    [Documentation]    Login to GUI and navigate to the settings sub-menu network page
    ...    and confirm the page contains sections that should be accessible.
    [Tags]    verify_existence_of_all_sections_in_network_page

    Wait Until Page Contains Element    ${xpath_network_settings}    timeout=1min
    Page Should Contain Element    ${xpath_interface_settings}
    Page Should Contain Element    ${xpath_static_ipv4}
    Page Should Contain Element    ${xpath_static_dns}

Verify Existence Of All Buttons In Network Page
    [Documentation]    Login to GUI and navigate to the settings sub-menu network page
    ...    and confirm the page contains basic features button that should be accessible.
    [Tags]    verify_existence_of_all_buttons_in_network_page

    Page Should Contain Button    ${xpath_add_static_ipv4_address_button}
    Page Should Contain Button    ${xpath_add_dns_ip_address_button}
    Page Should Contain Button    ${xpath_domain_name_toggle}
    Page Should Contain Button    ${xpath_dns_servers_toggle}
    Page Should Contain Button    ${xpath_ntp_servers_toggle}
    Page Should Contain Button    ${xpath_dhcp_toggle_switch}

Verify Existence Of All Fields In Hostname
    [Documentation]    Login to GUI and navigate to the settings sub-menu network page
    ...    and confirm hostname contains all the fields.
    [Tags]    verify_existence_of_all_fields_in_hostname

    Click Element    ${xpath_hostname}
    Wait Until Page Contains    Edit hostname    timeout=1min
    Page Should Contain Textfield    ${xpath_hostname_input}
    Page Should Contain Button    ${xpath_cancel_button}
    Page Should Contain Button    ${xpath_save_button}
    [Teardown]    Run Keywords    Click Button    ${xpath_cancel_button}    AND
    ...    Wait Until Keyword Succeeds    10 sec    5 sec
    ...    Refresh GUI And Verify Element Value    ${xpath_network_heading}    Network

Verify Existence Of All Fields In Static IP Address
    [Documentation]    Login to GUI and navigate to the settings sub-menu network page
    ...    and confirm section static IPv4 contains all the fields.
    [Tags]    verify_existence_of_all_fields_in_static_ip_address

    Wait Until Keyword Succeeds    30 sec    10 sec    Click Element    ${xpath_add_static_ipv4_address_button}
    Wait Until Page Contains    Add static IPv4 address    timeout=15s
    Page Should Contain Textfield    ${xpath_input_ip_address}
    Page Should Contain Textfield    ${xpath_input_gateway}
    Page Should Contain Textfield    ${xpath_input_subnetmask}
    Page Should Contain Button    ${xpath_cancel_button}
    Page Should Contain Button    ${xpath_add_button}
    [Teardown]    Run Keywords    Click Button    ${xpath_cancel_button}    AND
    ...    Wait Until Keyword Succeeds    10 sec    5 sec
    ...    Refresh GUI And Verify Element Value    ${xpath_network_heading}    Network

Verify Existence Of All Fields In Static DNS
    [Documentation]    Login to GUI and navigate to the settings sub-menu network page
    ...    and confirm section static DNS contains all the fields.
    [Tags]    verify_existence_of_all_fields_in_static_dns

    Wait Until Keyword Succeeds    30 sec    10 sec    Click Element    ${xpath_add_dns_ip_address_button}
    Wait Until Page Contains    Add IP address    timeout=11s
    Page Should Contain Textfield    ${xpath_input_static_dns}
    Page Should Contain Button    ${xpath_cancel_button}
    Page Should Contain Button    ${xpath_add_button}
    [Teardown]    Run Keywords    Click Button    ${xpath_cancel_button}    AND
    ...    Wait Until Keyword Succeeds    10 sec    5 sec
    ...    Refresh GUI And Verify Element Value    ${xpath_network_heading}    Network

Configure And Verify DNS Server Via GUI
    [Documentation]    Login to GUI Network page, add DNS server IP
    ...    and verify that the page reflects server IP.
    [Tags]    configure_and_verify_dns_server_via_gui
    [Setup]    DNS Test Setup Execution

    Add DNS Servers And Verify    ${dns_server}
    [Teardown]    Run Keywords    Delete Static Name Servers    AND
    ...    Configure Static Name Servers

Configure Static IPv4 Netmask Via GUI And Verify
    [Documentation]    Login to GUI Network page, configure static IPv4 netmask and verify.
    [Tags]    configure_static_ipv4_netmask_via_gui_and_verify
    [Template]    Add Static IP Address And Verify
    [Setup]    Redfish.Login

    # ip_addresses    subnet_masks    gateway    expected_status
    ${test_ipv4_addr}    ${lowest_netmask}    ${default_gateway}    Success
    ${test_ipv4_addr}    ${more_byte_netmask}    ${default_gateway}    Invalid format
    ${test_ipv4_addr}    ${alpha_netmask}    ${default_gateway}    Invalid format
    ${test_ipv4_addr}    ${out_of_range_netmask}    ${default_gateway}    Invalid format
    ${test_ipv4_addr}    ${test_subnet_mask}    ${default_gateway}    Success
    [Teardown]    Redfish.Logout

Configure And Verify Static IP Address
    [Documentation]    Login to GUI Network page, configure static ip address and verify.
    [Tags]    configure_and_verify_static_ip_address
    [Setup]    Redfish.Login

    Add Static IP Address And Verify    ${test_ipv4_addr}    ${test_subnet_mask}    ${default_gateway}    Success
    [Teardown]    Redfish.Logout

Configure And Verify Multiple Static IP Address
    [Documentation]    Login to GUI Network page, configure multiple static IP address and verify.
    [Tags]    configure_and_verify_multiple_static_ip_address
    [Setup]    Redfish.Login

    Add Static IP Address And Verify    ${test_ipv4_addr}    ${test_subnet_mask}    ${default_gateway}    Success
    Add Static IP Address And Verify    ${test_ipv4_addr_1}    ${test_subnet_mask}    ${default_gateway}    Success
    [Teardown]    Redfish.Logout

Configure And Verify Invalid Static IP Address
    [Documentation]    Login to GUI Network page, configure invalid static IP address and verify.
    [Tags]    configure_and_verify_invalid_static_ip_address
    [Template]    Add Static IP Address And Verify
    [Setup]    Redfish.Login

    # ip    subnet_mask    gateway    status
    ${out_of_range_ip}    ${test_subnet_mask}    ${default_gateway}    Invalid format
    ${less_octet_ip}    ${test_subnet_mask}    ${default_gateway}    Invalid format
    ${string_ip}    ${test_subnet_mask}    ${default_gateway}    Invalid format
    ${negative_ip}    ${test_subnet_mask}    ${default_gateway}    Invalid format
    ${hex_ip}    ${test_subnet_mask}    ${default_gateway}    Invalid format
    ${spl_char_ip}    ${test_subnet_mask}    ${default_gateway}    Invalid format
    [Teardown]    Redfish.Logout

Configure Hostname Via GUI And Verify
    [Documentation]    Login to GUI Network page, configure hostname and verify.
    [Tags]    configure_hostname_via_gui_and_verify

    ${hostname}=    Get BMC Hostname
    Set Suite Variable    ${hostname}
    Configure And Verify Network Settings Via GUI    ${xpath_hostname}
    ...    ${xpath_hostname_input}    ${test_hostname}

    ${bmc_hostname}=    Get BMC Hostname
    Should Be Equal As Strings    ${bmc_hostname}    ${test_hostname}
    [Teardown]    Configure the Hostname Back And Verify


*** Keywords ***
Suite Setup Execution
    [Documentation]    Do suite setup tasks.

    Launch Browser And Login GUI
    Wait Until Keyword Succeeds    1 min    15 sec
    ...    Click Element    ${xpath_settings_menu}
    Click Element    ${xpath_network_sub_menu}
    Wait Until Keyword Succeeds    30 sec    10 sec    Location Should Contain    network
    Wait Until Element Is Not Visible    ${xpath_page_loading_progress_bar}    timeout=30
    ${default_gateway}=    Get BMC Default Gateway
    Set Suite Variable    ${default_gateway}

Launch Browser Login GUI And Navigate To Network Page
    [Documentation]    Launch browser Login GUI and navigate to network page.

    Launch Browser And Login GUI
    Wait Until Keyword Succeeds    1 min    15 sec
    ...    Click Element    ${xpath_settings_menu}
    Click Element    ${xpath_network_sub_menu}
    Wait Until Keyword Succeeds    30 sec    10 sec    Location Should Contain    network
    Wait Until Element Is Not Visible    ${xpath_page_loading_progress_bar}    timeout=30

Configure the Hostname Back And Verify
    [Documentation]    Configure the hostname back.

    Configure And Verify Network Settings Via GUI
    ...    ${xpath_hostname}    ${xpath_hostname_input}    ${hostname}
    ${bmc_hostname_after}=    Get BMC Hostname
    Should Be Equal As Strings    ${bmc_hostname_after}    ${hostname}

Delete DNS Servers And Verify
    [Documentation]    Login to GUI Network page,delete static name servers
    ...    and verify that page does not reflect static name servers.

    Page Should Contain Element    ${xpath_delete_dns_server}
    Wait Until Element Is Enabled    ${xpath_delete_dns_server}
    Click Button    ${xpath_delete_dns_server}
    Wait Until Page Contains Element    ${xpath_add_dns_ip_address_button}    timeout=15
    # Check if all name servers deleted on BMC.
    ${nameservers}=    CLI Get Nameservers
    Should Not Contain    ${nameservers}    ${original_nameservers}

    DNS Test Setup Execution

    Should Be Empty    ${original_nameservers}

Add Static IP Address And Verify
    [Documentation]    Add static IP address, subnet mask and
    ...    gateway via GUI and verify.
    [Arguments]    ${ip_address}    ${subnet_mask}    ${gateway_address}    ${expected_status}=error

    # Description of argument(s):
    # ip_address    IP address to be added (e.g. 10.7.7.7).
    # subnet_mask    Subnet mask for the IP to be added (e.g. 255.255.0.0).
    # gateway_address    Gateway address for the IP to be added (e.g. 10.7.7.1).
    # expected_status    Expected status while adding static ipv4 address
    # ....    (e.g. Invalid format / Field required).

    Wait Until Keyword Succeeds    30 sec    10 sec    Click Element    ${xpath_add_static_ipv4_address_button}

    Input Text    ${xpath_input_ip_address}    ${ip_address}
    Input Text    ${xpath_input_subnetmask}    ${subnet_mask}
    Input Text    ${xpath_input_gateway}    ${gateway_address}

    Click Element    ${xpath_add_button}
    IF    '${expected_status}' == 'Success'
        Wait Until Page Contains    ${ip_address}    timeout=40sec
        Validate Network Config On BMC
    ELSE IF    '${expected_status}' == 'Invalid format'
        Page Should Contain    Invalid format
        Click Button    ${xpath_cancel_button}
    END

Configure And Verify Network Settings Via GUI
    [Documentation]    Configure and verify network settings via GUI.
    [Arguments]    ${xpath_nw_settings}    ${xpath_nw_settings_input_field}    ${input_value}

    # Description of argument(s):
    # xpath_nw_settings    xpath of the network settings.
    # xpath_nw_settings_input_field    xpath of the network setting's input field.
    # input_value    Input value for configuration. E.g. hostname, IP etc.

    Wait Until Keyword Succeeds    30 sec    10 sec    Click Element    ${xpath_nw_settings}
    Input Text    ${xpath_nw_settings_input_field}    ${input_value}
    Click Button    ${xpath_save_button}

    # Re-Login gui and navigate to network page.
    Launch Browser Login GUI And Navigate To Network Page

    Wait Until Page Contains    ${input_value}    timeout=30sec
