*** Settings ***

Documentation  Test OpenBMC "KVM" sub menu of "Operations".

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close All Browsers

Test Tags      KVM_Sub_Menu

*** Variables ***

${xpath_kvm_ctl_alt_delete_button}       //button[contains(text(),' Send Ctrl+Alt+Delete')]
${xpath_kvm_new_tab_button}              //button[contains(text(),'  Open in new tab')]
${xpath_kvm_heading}                     //h1[contains(text(),'KVM')]

*** Test Cases ***

Verify Navigation To KVM Page
    [Documentation]  Verify navigation to KVM page.
    [Tags]  Verify_Navigation_To_KVM_Page

    Page Should Contain Element  ${xpath_kvm_heading}


Verify Existence Of All Sections And Buttons In KVM Page
    [Documentation]  Verify existence of all sections and buttons in KVM page.
    [Tags]  Verify_Existence_Of_All_Sections_And_Buttons_In_KVM_Page

    Page Should Contain  Status
    Page Should Contain Element  ${xpath_kvm_ctl_alt_delete_button}
    Page Should Contain Element  ${xpath_kvm_new_tab_button}


*** Keywords ***

Suite Setup Execution
   [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_operations_menu}
    Click Element  ${xpath_kvm_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  kvm
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30