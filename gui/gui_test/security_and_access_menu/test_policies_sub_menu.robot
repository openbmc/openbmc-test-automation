*** Settings ***

Documentation    Test OpenBMC GUI "Policies" sub-menu of "Security and Access" menu.

Resource         ../../lib/gui_resource.robot
Resource         ../lib/ipmi_client.robot
Resource         ../../../lib/common_utils.robot
Suite Setup      Launch Browser And Login GUI
Suite Teardown   Close Browser
Test Setup       Test Setup Execution


*** Variables ***

${xpath_policies_heading}       //h1[text()="Policies"]
${xpath_bmc_ssh_toggle}         //*[@data-test-id='policies-toggle-bmcShell']/following-sibling::label
${xpath_network_ipmi_toggle}    //*[@data-test-id='polices-toggle-networkIpmi']/following-sibling::label
${xpath_rebootbmc_button}       //*[@data-test-id='rebootBmc-button-reboot']
${xpath_confirm_bmc_reboot}     //*[@class='btn btn-primary']


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


Enable SSH Via GUI And Verify
    [Documentation]  Verify that SSH to BMC starts working after enabling SSH.
    [Tags]  Enable_SSH_Via_GUI_And_Verify
    [Teardown]  Run Keywords  Redfish.Patch  /redfish/v1/Managers/bmc/NetworkProtocol
    ...  body={"SSH":{"ProtocolEnabled":True}}  valid_status_codes=[200, 204]  AND
    ...  Wait Until Keyword Succeeds  30 sec  5 sec  Open Connection And Login

    # Disable ssh via Redfish.
    Redfish.Patch  /redfish/v1/Managers/bmc/NetworkProtocol  body={"SSH":{"ProtocolEnabled":False}}
    ...   valid_status_codes=[200, 204]

    # Wait for GUI to reflect disable SSH status.
    Wait Until Keyword Succeeds  30 sec  10 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_bmc_ssh_toggle}  Disabled

    # Enable ssh via GUI.
    Click Element  ${xpath_bmc_ssh_toggle}

    # Wait for GUI to reflect enable SSH status.
    Wait Until Keyword Succeeds  30 sec  10 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_bmc_ssh_toggle}  Enabled

    Wait Until Keyword Succeeds  10 sec  5 sec  Open Connection And Login


Disable SSH Via GUI And Verify
    [Documentation]  Verify that SSH to BMC stops working after disabling SSH.
    [Tags]  Disable_SSH_Via_GUI_And_Verify
    [Teardown]  Run Keywords  Redfish.Patch  /redfish/v1/Managers/bmc/NetworkProtocol
    ...  body={"SSH":{"ProtocolEnabled":True}}  valid_status_codes=[200, 204]  AND
    ...  Wait Until Keyword Succeeds  30 sec  5 sec  Open Connection And Login

    # Enable ssh via Redfish.
    Redfish.Patch  /redfish/v1/Managers/bmc/NetworkProtocol  body={"SSH":{"ProtocolEnabled":True}}
    ...   valid_status_codes=[200, 204]

    # Wait for GUI to reflect enable SSH status.
    Wait Until Keyword Succeeds  30 sec  10 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_bmc_ssh_toggle}  Enabled

    # Disable ssh via GUI.
    Click Element  ${xpath_bmc_ssh_toggle}

    # Wait for GUI to reflect disable SSH status.
    Wait Until Keyword Succeeds  30 sec  10 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_bmc_ssh_toggle}  Disabled

    ${status}=  Run Keyword And Return Status
    ...  Open Connection And Login

    Should Be Equal As Strings  ${status}  False
    ...  msg=SSH login still working after disabling SSH.


Disable IPMI Via GUI And Verify
    [Documentation]  Verify that IPMI command doesnot work after disabling IPMI.
    [Tags]  Disable_IPMI_Via_GUI_And_Verify
    [Teardown]  Redfish.Patch  /redfish/v1/Managers/bmc/NetworkProtocol
    ...  body={"IPMI":{"ProtocolEnabled":True}}  valid_status_codes=[200, 204]

    # Due to github issue 2125 we are using click element instead of select checkbox.
    # https://github.com/openbmc/openbmc-test-automation/issues/2125.
    # Enable IPMI via Redfish.
    Redfish.Patch  /redfish/v1/Managers/bmc/NetworkProtocol  body={"IPMI":{"ProtocolEnabled":True}}
    ...   valid_status_codes=[200, 204]

    # Wait for GUI to reflect enable IPMI status.
    Wait Until Keyword Succeeds  30 sec  10 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_network_ipmi_toggle}  Enabled

    # Disable IPMI via GUI.
    Click Element  ${xpath_network_ipmi_toggle}

    # Wait for GUI to reflect disable IPMI status.
    Wait Until Keyword Succeeds  30 sec  10 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_network_ipmi_toggle}  Disabled

    ${status}=  Run Keyword And Return Status
    ...  Wait Until Keyword Succeeds  10 sec  5 sec  Run IPMI Standard Command  sel info

    Should Be Equal As Strings  ${status}  False
    ...  msg=IPMI command is working after disabling IPMI.


Enable SSH Via GUI And Verify Persistency On BMC Reboot
    [Documentation]  Enable SSH Via GUI And Verify Persistency of SSH Connection On BMC Reboot.
    [Tags]  Enable_SSH_Via_GUI_And_Verify_Persistency_On_BMC_Reboot
    [Teardown]  Run Keywords  Enable SSH via Redfish  AND
    ...  Wait Until Keyword Succeeds  30 sec  5 sec  Open Connection And Login

    Disable ssh via Redfish

    Wait Until Keyword Succeeds  30 sec  10 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_bmc_ssh_toggle}  Disabled

    # Enable ssh via GUI.
    Click Element  ${xpath_bmc_ssh_toggle}

    # Wait for GUI to reflect enable SSH status.
    Wait Until Keyword Succeeds  30 sec  10 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_bmc_ssh_toggle}  Enabled

    Reboot BMC via GUI

    Open Connection And Login


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.
    Click Element  ${xpath_secuity_and_accesss_menu}
    Click Element  ${xpath_policies_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  policies


Reboot BMC via GUI
    [Documentation]  Reboot BMC via GUI.
    Click Element  ${xpath_operations_menu}
    Click Element  ${xpath_reboot_bmc_sub_menu}
    Click Button  ${xpath_rebootbmc_button}
    Click Button  ${xpath_confirm_bmc_reboot}
    Wait Until Keyword Succeeds  2 min  10 sec  Is BMC Unpingable
    Wait For Host To Ping  ${OPENBMC_HOST}  1 min
    Wait Until Keyword Succeeds  5 min  10 sec  Is BMC Ready


Disable SSH via Redfish
    [Documentation]  Disable SSH via GUI.
    Redfish.Patch  /redfish/v1/Managers/bmc/NetworkProtocol  body={"SSH":{"ProtocolEnabled":False}}
    ...   valid_status_codes=[200, 204]


Enable SSH via Redfish
    [Documentation]  Enable SSH via GUI.
    Redfish.Patch  /redfish/v1/Managers/bmc/NetworkProtocol  body={"SSH":{"ProtocolEnabled":True}}
    ...   valid_status_codes=[200, 204]

