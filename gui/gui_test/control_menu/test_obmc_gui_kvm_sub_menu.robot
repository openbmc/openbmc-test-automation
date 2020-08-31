*** Settings ***

Documentation   Test OpenBMC GUI "KVM" sub-menu.

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_kvm_header}      //h1[text()="KVM"]
${xpath_new_tab_button}  //button[contains(text(),'Open in new tab')]
${xpath_send_button}     //button[contains(text(),'Send Ctrl+Alt+Delete')]


*** Test Cases ***

Verify Navigation To KVM Page
    [Documentation]  Verify navigation to KVM page.
    [Tags]  Verify_Navigation_To_KVM_Page

    Page Should Contain Element  ${xpath_kvm_header}


Verify Existence Of All Sections In KVM Page
    [Documentation]  Verify existence of all sections in KVM page.
    [Tags]  Verify_Existence_Of_All_Sections_In_KVM_Page

    Page Should Contain Element  ${xpath_kvm_header}
    Page Should Contain  Access the KVM console


Verify Existence Of All Buttons In KVM Page
    [Documentation]  Verify existence of all buttons in kvm page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Kvm_Page

    Page Should Contain Element  ${xpath_new_tab_button}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_kvm_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  kvm
