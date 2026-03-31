*** Settings ***

Documentation   Test OpenBMC "KVM" sub menu of "Operations".

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close All Browsers

Test Tags       KVM_Sub_Menu

*** Variables ***

${xpath_kvm_ctl_alt_delete_button}       //button[contains(normalize-space(), 'Send Ctrl+Alt+Delete')]
${xpath_kvm_new_tab_button}              //button[contains(normalize-space(), 'Open in new tab')]

*** Test Cases ***

Verify Navigation To KVM Page
    [Documentation]  Verify navigation to KVM page.
    [Tags]  Verify_Navigation_To_KVM_Page

    Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_kvm_sub_menu}  kvm

Verify Existence Of All Sections And Buttons In KVM Page
    [Documentation]  Verify existence of all sections and buttons in KVM page.
    [Tags]  Verify_Existence_Of_All_Sections_And_Buttons_In_KVM_Page

    Navigate To KVM Page And Verify All Sections

Verify Navigation To Open New Tab In KVM Page
    [Documentation]  Verify navigation to open new tab in KVM page.
    [Tags]  Verify_Navigation_To_Open_New_Tab_In_KVM_Page

    Navigate To KVM Page And Verify All Sections
    Click Element  ${xpath_kvm_new_tab_button}
    Wait Until Keyword Succeeds  30 sec  5 sec  Switch Window  NEW

    # Maximize the new window
    Maximize Browser Window
    Wait Until Page Contains  Status  timeout=30s
    Page Should Contain Element  ${xpath_kvm_ctl_alt_delete_button}
    # open new tab button should not be present in the sub kvm page.
    Page Should Not Contain Element  ${xpath_kvm_new_tab_button}

*** Keywords ***

Navigate To KVM Page And Verify All Sections
    [Documentation]  Navigate to KVM page and verify all sections.

    Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_kvm_sub_menu}  kvm
    Page Should Contain  Status
    Page Should Contain Element  ${xpath_kvm_ctl_alt_delete_button}
    Page Should Contain Element  ${xpath_kvm_new_tab_button}
