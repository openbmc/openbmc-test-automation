*** Settings ***

Documentation    Test OpenBMC GUI "Security settings" sub-menu of "Server configuration" menu.

Resource         ../../lib/gui_resource.robot

Suite Setup      Launch Browser And Login GUI
Suite Teardown   Close Browser
Test Setup       Test Setup Execution


*** Variables ***

${xpath_security_settings_heading}  //h1[text()="Security settings"]
${xpath_bmc_ssh_toggle}             //*[@data-test-id='security-toggle-bmcShell']
${xpath_network_ipmi_toggle}        //*[@data-test-id='security-toggle-networkIpmi']


*** Test Cases ***

Verify Navigation To Security Settings Page
    [Documentation]  Verify navigation to security settings page.
    [Tags]  Verify_Navigation_To_Security_Settings_Page

    Page Should Contain Element  ${xpath_security_settings_heading}


Verify Existence Of All Sections In Security Settings Page
    [Documentation]  Verify existence of all sections in security settings page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Security_Settings_Page

    Page Should Contain  Network services
    Page Should Contain  BMC shell (via SSH)
    Page Should Contain  Network IPMI (out-of-band IPMI)


Verify Existence Of All Buttons In Security Settings Page
    [Documentation]  Verify existence of All Buttons in security settings page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Security_Settings_Page

    Page Should Contain Element  ${xpath_bmc_ssh_toggle}
    Page Should Contain Element  ${xpath_network_ipmi_toggle}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_server_configuration}
    Click Element  ${xpath_security_settings_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  security-settings
