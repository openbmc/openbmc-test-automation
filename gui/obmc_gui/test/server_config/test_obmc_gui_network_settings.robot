*** Settings ***

Documentation   Test OpenBMC GUI "Network settings" sub-menu of
...             "Server configuration".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Logout And Close Browser
Test Setup      Test Setup Execution

*** Variables ***

${xpath_select_server_configuration}  //*[@id="nav__top-level"]/li[4]/button
${xpath_select_network_settings}  //a[@href='#/configuration/network']
${xpath_hostname_input}  //*[@id="net-config__mac"]
${xpath_network_save_settings}  //*[@id="configuration-network"]/form/section[3]/div[2]/button[1]
${xpath_continue}  //*[@id=""]/main/section/div/div[4]/button[2]
${xpath_network_config_ipv4_address}  //*[@id="net-config__ipv4-address"]

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


*** Keywords ***

Test Setup Execution
   [Documentation]  Do test case setup tasks.

    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_server_configuration}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_network_settings}
    Wait Until Page Contains Element  ${xpath_network_config_ipv4_address}

