*** Settings ***

Documentation    Test OpenBMC GUI "Policies" sub-menu of "Security and Access" menu.

Resource         ../../lib/gui_resource.robot
Suite Setup      Launch Browser And Login GUI
Suite Teardown   Close Browser
Test Setup       Test Setup Execution


*** Variables ***

${xpath_policies_heading}       //h1[text()="Policies"]
${xpath_bmc_ssh_toggle}         //*[@data-test-id='policies-toggle-bmcShell']//following-sibling::label
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


Verify SSH Enable
    [Documentation]  Verify that SSH to BMC starts working after enabling SSH.
    [Tags]  Verify_SSH_Enable

    # Disable ssh via Redfish.
    Redfish.Patch  /redfish/v1/Managers/bmc/NetworkProtocol  body={"SSH":{"ProtocolEnabled":False}}
    ...   valid_status_codes=[200, 204]

    # Wait for max 2 mins for GUI to reflect changed SSH status.
    FOR  ${i}  IN RANGE  ${8}
        Click Element  ${xpath_refresh_button}
        Wait Until Element Does Not Contain  ${xpath_bmc_ssh_value}  Enabled  timeout=30
    END

    # Enable ssh via GUI.
    Click Element  ${xpath_bmc_ssh_toggle}
    Wait Until Keyword Succeeds  1 Min  5 Sec  Verify SSH Login


*** Keywords ***


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_secuity_and_accesss_menu}
    Click Element  ${xpath_policies_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  policies


Verify SSH Login
    [Documentation]  Verify SSH login and command execution on SSH session.
    [Teardown]  Close All Connections

    Open Connection And Login
    BMC Execute Command  /sbin/ip addr

