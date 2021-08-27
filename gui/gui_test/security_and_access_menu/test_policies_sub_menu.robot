*** Settings ***

Documentation    Test OpenBMC GUI "Policies" sub-menu of "Scurity and Access" menu.

Resource         ../../lib/gui_resource.robot
Suite Setup      Launch Browser And Login GUI
Suite Teardown   Close Browser
Test Setup       Test Setup Execution


*** Variables ***

${xpath_security_and_access}    //*[@data-test-id='nav-button-security-and-access']
${xpath_policies_sub_menu}      //*[@data-test-id='nav-item-policies']
${xpath_policies_heading}       //h1[text()="Policies"]
${xpath_bmc_ssh_toggle}         //*[@data-test-id='policies-toggle-bmcShell']
${xpath_network_ipmi_toggle}    //*[@data-test-id='polices-toggle-networkIpmi']
${xpath_bmc_ssh_value}          //*[@data-test-id='policies-toggle-bmcShell']/following-sibling::label/span


*** Test Cases ***

Verify Navigation To Policies Page
    [Documentation]  Verify navigation to policies page.
    [Tags]  Verify_Navigation_To_Policies_Page

    Page Should Contain Element  ${xpath_policies_heading}


Verify Existence Of All Sections In Policies Page
    [Documentation]  Verify existence of all sections in policies page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Policies_Page

    Page Should Contain  Network services
    Page Should Contain  BMC shell (via SSH)
    Page Should Contain  Network IPMI (out-of-band IPMI)


Verify Existence Of All Buttons In Policies Page
    [Documentation]  Verify existence of All Buttons in policies page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Policies_Page

    Page Should Contain Element  ${xpath_bmc_ssh_toggle}
    Page Should Contain Element  ${xpath_network_ipmi_toggle}


Enable SSH And Verify SSH to BMC Starts Working
    [Documentation]  Enable SSH And Verify SSH to BMC Starts Working
    [Tags]  Enable_SSH_And_Verify_SSH_To_BMC_Starts_Working

    #disable ssh via redfish
    Redfish.Patch  /redfish/v1/Managers/bmc/NetworkProtocol  body={"SSH":{"ProtocolEnabled":False}}
    ...   valid_status_codes=[200, 204]
    Sleep  15s
    Refresh GUI

    #enable ssh via GUI
    Click Element At Coordinates  ${xpath_bmc_ssh_toggle}  0  0
    Wait Until Element Is Enabled   ${xpath_bmc_ssh_value}  timeout=30
    Sleep  15s
    Refresh GUI

    Verify SSH Login And Commands Work


*** Keywords ***


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_security_and_access}
    Click Element  ${xpath_policies_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  policies


Verify SSH Login And Commands Work
    [Documentation]  Verify if SSH connection works and able to run command on SSH session.
    [Teardown]  Close All Connections

    # Check if we can open SSH connection and login.
    Open Connection And Login

    # Check if we can run command successfully on SSH session.
    BMC Execute Command  /sbin/ip addr

