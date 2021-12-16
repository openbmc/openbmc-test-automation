*** Settings ***

Documentation   Test OpenBMC GUI "Network" sub-menu of "Settings".

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/bmc_network_utils.robot

Suite Setup      Suite Setup Execution
Suite Teardown   Close Browser


*** Variables ***

${xpath_network_heading}          //h1[text()="Network"]
${xpath_interface_settings}       //h2[text()="Interface settings"]
${xpath_network_settings}         //h2[text()="Network settings"]
${xpath_static_ipv4}              //h2[text()="IPv4"]
${xpath_static_dns}               //h2[text()="Static DNS"]
${xpath_domain_name}              //*[@data-test-id="networkSettings-switch-useDomainName"]
${xpath_DNS_servers}              //*[@data-test-id="networkSettings-switch-useDns"]
${xpath_NTP_servers}              //*[@data-test-id="networkSettings-switch-useNtp"]
${xpath_add_static_ipv4_address}  //button[contains(text(),"Add static IPv4 address")]
${xpath_add_dns_ip_address}       //button[contains(text(),"Add IP address")]


*** Test Cases ***

Verify Navigation To Network Page
    [Documentation]  Verify navigation to network page.
    [Tags]  Verify_Navigation_To_Network_Page

    Page Should Contain Element  ${xpath_network_heading}


Verify Existence Of All Sections In Network Page
    [Documentation]  Verify existence of all sections in network settings page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Network_Page

    Wait Until Page Contains Element  ${xpath_network_settings}  timeout=1min
    Page Should Contain Element  ${xpath_interface_settings}
    Page Should Contain Element  ${xpath_static_ipv4}
    Page Should Contain Element  ${xpath_static_dns}


Verify Existence Of All Buttons In Network Page
    [Documentation]  Verify existence of all buttons in network page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Network_Page

    Page Should Contain Button  ${xpath_add_static_ipv4_address}
    Page Should Contain Button  ${xpath_add_dns_ip_address}


Verify Network From Server Configuration
    [Documentation]  Verify ability to select "Network" sub-menu option
    ...  of "Settings".
    [Tags]  Verify_Network_From_Server_Configuration

    Wait Until Page Contains  IP address  timeout=45s


Verify Existence Of Sections In Network Settings
    [Documentation]  Verify existence of all sections under network settings.
    [Tags]  Verify_Existence_Of_All_Sections_In_Network_Settings

    Wait Until Page Contains  Hostname  timeout=45s
    Page Should Contain Element  ${xpath_domain_name}
    Page Should Contain Element  ${xpath_DNS_servers}
    Page Should Contain Element  ${xpath_NTP_servers}


*** Keywords ***

Suite Setup Execution
   [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_settings_menu}
    Click Element  ${xpath_network_sub_menu}
    Wait Until Page Contains  network  timeout=1min
