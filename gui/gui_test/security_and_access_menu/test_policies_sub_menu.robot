*** Settings ***

Documentation    Test OpenBMC GUI "Policies" sub-menu of "Security and Access" menu.

Resource         ../../lib/gui_resource.robot
Resource         ../lib/ipmi_client.robot
Resource         ../lib/protocol_setting_utils.robot
Resource         ../lib/common_utils.robot
Suite Setup      Run Keywords  Launch Browser And Login GUI  AND  Redfish.Login
Suite Teardown   Close Browser
Test Setup       Test Setup Execution


*** Variables ***
 
${xpath_policies_heading}                     //h1[text()="Policies"]
${xpath_bmc_ssh_toggle}                       //*[@data-test-id='policies-toggle-bmcShell']
...  /following-sibling::label
${xpath_network_ipmi_toggle}                  //*[@data-test-id='polices-toggle-networkIpmi']
...  /following-sibling::label
${xpath_host_tpm_toggle}                      //input[@id='host-tpm-policy']
${xpath_virtual_tpm_toggle}                   //*[@data-test-id='policies-toggle-vtpm']
${xpath_rtad_toggle}                          //*[@data-test-id='policies-toggle-rtad']
${xpath_usb_firmware_update_policy_toggle}    //*[@data-test-id='policies-toggle-usbFirmwareUpdatePolicy']
${xpath_secure_version_lockin_toggle}         //*[@data-test-id='policies-toggle-svle']
${xpath_host_usb_enablement_toggle}           //*[@data-test-id='policies-toggle-hostUsb']

*** Test Cases ***

Verify Navigation To Policies Page
    [Documentation]  Verify navigation to policies page.
    [Tags]  Verify_Navigation_To_Policies_Page

    Page Should Contain Element  ${xpath_policies_heading}


Verify Existence Of All Sections In Policies Page
    [Documentation]  Verify existence of all sections in policies page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Policies_Page

    Page Should Contain  BMC shell (via SSH)
    Page Should Contain  Network IPMI (out-of-band IPMI)
    Page Should Contain  Host TPM
    Page Should Contain  VirtualTPM
    Page Should Contain  RTAD
    Page Should Contain  USB firmware update policy
    Page Should Contain  Secure version lock-in
    Page Should Contain  Host USB enablement


Verify Existence Of All Buttons In Policies Page
    [Documentation]  Verify existence of All Buttons in policies page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Policies_Page

    Page Should Contain Element  ${xpath_bmc_ssh_toggle}
    Page Should Contain Element  ${xpath_network_ipmi_toggle}
    Page Should Contain Element  ${xpath_host_tpm_toggle}
    Page Should Contain Element  ${xpath_virtual_tpm_toggle}
    Page Should Contain Element  ${xpath_rtad_toggle}
    Page Should Contain Element  ${xpath_usb_firmware_update_policy_toggle}
    Page Should Contain Element  ${xpath_secure_version_lockin_toggle}
    Page Should Contain Element  ${xpath_host_usb_enablement_toggle}


Enable SSH Via GUI And Verify
    [Documentation]  Login to GUI Policies page,enable SSH toggle and
    ...  verify that SSH to BMC starts working after enabling SSH.
    [Tags]  Enable_SSH_Via_GUI_And_Verify

    Set Policy Via GUI  SSH  Enabled
    Wait Until Keyword Succeeds  18 sec  3 sec  Open Connection And Login


Disable SSH Via GUI And Verify
    [Documentation]  Login to GUI Policies page,disable SSH and
    ...  verify that SSH to BMC stops working after disabling SSH.
    [Tags]  Disable_SSH_Via_GUI_And_Verify
    [Teardown]  Run Keywords  Enable SSH Protocol  ${True}  AND
    ...  Wait Until Keyword Succeeds  30 sec  18 sec  Open Connection And Login

    Set Policy Via GUI  SSH  Disabled

    ${status}=  Run Keyword And Return Status
    ...  Open Connection And Login

    Should Be Equal As Strings  ${status}  False
    ...  msg=SSH login still working after disabling SSH.


Disable IPMI Via GUI And Verify
    [Documentation]  Login to GUI Policies page,disable IPMI and
    ...  verify that IPMI command does not work after disabling IPMI.
    [Tags]  Disable_IPMI_Via_GUI_And_Verify

    Set Policy Via GUI  IPMI  Disabled

    ${status}=  Run Keyword And Return Status
    ...  Wait Until Keyword Succeeds  18 sec  3 sec  Run IPMI Standard Command  sel info

    Should Be Equal As Strings  ${status}  False
    ...  msg=IPMI command is working after disabling IPMI.


Enable IPMI Via GUI And Verify
    [Documentation]  Login to GUI Policies page,enable IPMI and
    ...  verify that IPMI command works after enabling IPMI.
    [Tags]  Enable_IPMI_Via_GUI_And_Verify

    Set Policy Via GUI  IPMI  Enabled
    Wait Until Keyword Succeeds  18 sec  3 sec  Run IPMI Standard Command  sel info


Enable SSH Via GUI And Verify Persistency On BMC Reboot
    [Documentation]  Login to GUI Policies page,enable SSH and
    ...  verify persistency of SSH connection on BMC reboot.
    [Tags]  Enable_SSH_Via_GUI_And_Verify_Persistency_On_BMC_Reboot

    Set Policy Via GUI  SSH  Enabled

    Reboot BMC via GUI

    Wait Until Keyword Succeeds  5 min  30 sec  Open Connection And Login


Enable IPMI Via GUI And Verify Persistency On BMC Reboot
    [Documentation]  Login to GUI Policies page,enable IPMI and
    ...  verify persistency of IPMI command work on BMC reboot.
    [Tags]  Enable_IPMI_Via_GUI_And_Verify_Persistency_On_BMC_Reboot

    Set Policy Via GUI  IPMI  Enabled

    Reboot BMC via GUI

    Wait Until Keyword Succeeds  2 min  30 sec  Run IPMI Standard Command  sel info


Disable SSH Via GUI And Verify Persistency On BMC Reboot
    [Documentation]  Login to GUI Policies page,disable SSH and
    ...  verify that SSH to BMC stops working after disabling SSH on BMC reboot.
    [Tags]  Disable_SSH_Via_GUI_And_Verify_Persistency_On_BMC_Reboot
    [Teardown]  Run Keywords  Wait Until Keyword Succeeds  2 min  15 sec  Enable SSH Protocol  ${True}
    ...  AND  Wait Until Keyword Succeeds  2 min  15 sec  Open Connection And Login

    Set Policy Via GUI  SSH  Disabled

    Reboot BMC via GUI

    ${status}=  Run Keyword And Return Status
    ...  Wait Until Keyword Succeeds  18 sec  3 sec  Open Connection And Login

    Should Be Equal As Strings  ${status}  False
    ...  msg=SSH login still working after disabling SSH.


Disable IPMI Via GUI And Verify Persistency On BMC Reboot
    [Documentation]  Login to GUI Policies page,disable IPMI and
    ...  verify persistency of IPMI command does not work on BMC reboot.
    [Tags]  Disable_IPMI_Via_GUI_And_Verify_Persistency_On_BMC_Reboot
    [Teardown]  Run Keywords  Wait Until Keyword Succeeds  2 min  15 sec  Enable IPMI Protocol  ${True}
    ...  AND  Wait Until Keyword Succeeds  2 min  15 sec  Run IPMI Standard Command  sel info

    Set Policy Via GUI  IPMI  Disabled

    Reboot BMC via GUI

    ${status}=  Run Keyword And Return Status
    ...  Wait Until Keyword Succeeds  18 sec  3 sec  Run IPMI Standard Command  sel info

    Should Be Equal As Strings  ${status}  False
    ...  msg=IPMI command is working after disabling IPMI.


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_secuity_and_accesss_menu}
    Click Element  ${xpath_policies_sub_menu}
    Wait Until Keyword Succeeds  30 sec  18 sec  Location Should Contain  policies


Set Policy Via GUI

    [Documentation]  Login to GUI Policies page and set policy.
    [Arguments]  ${policy}  ${state}

    # Description of argument(s):
    # policy   policy to be set(e.g. SSH, IPMI).
    # state    state to be set(e.g. Enable, Disable).

    ${opposite_state_gui}  ${opposite_state_redfish}=  Run Keyword If
    ...  '${state}' == 'Enabled'  Set Variable  Disabled  ${False}
    ...  ELSE IF  '${state}' == 'Disabled'  Set Variable  Enabled  ${True}

    # Setting policy to an opposite value via Redfish.
    Run Keyword If  '${policy}' == 'SSH'
    ...  Enable SSH Protocol  ${opposite_state_redfish}
    ...  ELSE IF  '${policy}' == 'IPMI'
    ...  Enable IPMI Protocol  ${opposite_state_redfish}

    ${policy_toggle_button}=  Run Keyword If  '${policy}' == 'SSH'
    ...  Set variable  ${xpath_bmc_ssh_toggle}
    ...  ELSE IF  '${policy}' == 'IPMI'
    ...  Set variable  ${xpath_network_ipmi_toggle}

    Wait Until Keyword Succeeds  1 min  30 sec
    ...  Refresh GUI And Verify Element Value  ${policy_toggle_button}  ${opposite_state_gui}
    Click Element  ${policy_toggle_button}

    # Wait for GUI to reflect policy status.
    Wait Until Keyword Succeeds  1 min  30 sec
    ...  Refresh GUI And Verify Element Value  ${policy_toggle_button}  ${state}
