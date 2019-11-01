*** Settings ***

Documentation  Test OpenBMC GUI "LDAP" sub-menu of "Access control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_enable_ldap_checkbox}           //*[@id='ldap-auth-label']
${xpath_secure_ldap_checkbox}           //*[@id='use-ssl']
${xpath_openl_ldap_radio_button}        //input[@id='open-ldap']
${xpath_active_directory_radio_button}  //input[@id='active-directory']
${xpath_save_button}                    //button[contains(text(),'Save')]
${xpath_reset_button}                   //button[contains(text(),'Reset')]
${xpath_add_role_group_button}          //button[@type='button']//*[contains(text(),'Add role group')]
${xpath_remove_role_groups_button}      //button[@type='button']//*[contains(text(),'Remove role groups')]

*** Test Cases ***

Verify Existence Of All Sections In LDAP Page
    [Documentation]  Verify existence of all sections in LDAP page.
    [Tags]  Verify_Existence_Of_All_Sections_In_LDAP_Page

    Page Should Contain  Settings
    Page Should Contain  Role groups


Verify Existence Of All Buttons In LDAP Page
    [Documentation]  Verify existence of all buttons in LDAP page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_LDAP_Page

    # Buttons under settings section
    Page Should Contain Element  ${xpath_openl_ldap_radio_button}
    Page Should Contain Element  ${xpath_active_directory_radio_button}
    Page Should Contain Element  ${xpath_save_button}
    Page Should Contain Element  ${xpath_reset_button}

    # Buttons under role groups section
    Page Should Contain Element  ${xpath_add_role_group_button}
    Page Should Contain Element  ${xpath_remove_role_groups_button}


Verify Existence Of All Checkboxes In LDAP Page
    [Documentation]  Verify existence of all checkboxes in LDAP page.
    [Tags]  Verify_Existence_Of_All_Checkboxes_In_LDAP_Page

    # Checkboxes under settings section
    Page Should Contain Element  ${xpath_enable_ldap_checkbox}
    Page Should Contain Element  ${xpath_secure_ldap_checkbox}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_access_control}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_ldap}
    Wait Until Page Contains  Configure LDAP settings and manage role groups
