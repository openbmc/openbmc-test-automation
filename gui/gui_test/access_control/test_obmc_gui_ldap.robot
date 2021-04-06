*** Settings ***

Documentation  Test OpenBMC GUI "LDAP" sub-menu of "Access control".

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_ldap_heading}                   //h1[text()="LDAP"]
${xpath_enable_ldap_checkbox}           //*[@data-test-id='ldap-checkbox-ldapAuthenticationEnabled']
${xpath_secure_ldap_checkbox}           //*[@data-test-id='ldap-checkbox-secureLdapEnabled']
${xpath_service_radio_button}           //*[@data-test-id="ldap-radio-activeDirectoryEnabled"]
${xpath_add_role_group_button}          //button[contains(text(),'Add role group')]
${xpath_ldap_save_settings}             //*[@data-test-id='ldap-button-saveSettings']
${xpath_select_refresh_button}          //*[text()[contains(.,"Refresh")]]
${css_group_name}                       [aria-colindex="2"][role="cell"]
${css_group_privilege}                  [aria-colindex="3"][role="cell"]

*** Test Cases ***

Verify Navigation To LDAP Page
    [Documentation]  Verify navigation to LDAP page.
    [Tags]  Verify_Navigation_To_LDAP_Page

    Page Should Contain Element  ${xpath_ldap_heading}


Verify Existence Of All Sections In LDAP Page
    [Documentation]  Verify existence of all sections in LDAP page.
    [Tags]  Verify_Existence_Of_All_Sections_In_LDAP_Page

    Page Should Contain  Settings
    Page Should Contain  Role groups


Verify Existence Of All Buttons In LDAP Page
    [Documentation]  Verify existence of all buttons in LDAP page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_LDAP_Page

    # Buttons under settings section.
    Page Should Contain Element  ${xpath_service_radio_button}
    Page Should Contain Element  ${xpath_save_settings_button}

    # Buttons under role groups section.
    Page Should Contain Element  ${xpath_add_role_group_button}


Verify Existence Of All Checkboxes In LDAP Page
    [Documentation]  Verify existence of all checkboxes in LDAP page.
    [Tags]  Verify_Existence_Of_All_Checkboxes_In_LDAP_Page

    # Checkboxes under settings section.
    Page Should Contain Element  ${xpath_enable_ldap_checkbox}
    Page Should Contain Element  ${xpath_secure_ldap_checkbox}


Verify LDAP Service Disable
    [Documentation]  Verify that LDAP is disabled and that LDAP user cannot
    ...  login.
    [Tags]  Verify_LDAP_Service_Disable

    Click Element  ${xpath_refresh_button}

    ${status}=  Run Keyword And Return Status
    ...  Checkbox Should Be Selected  ${xpath_enable_ldap_checkbox}

    Run Keyword If  ${status} == ${True}
    ...  Click Element At Coordinates  ${xpath_enable_ldap_checkbox}  0  0

    Checkbox Should Not Be Selected  ${xpath_enable_ldap_checkbox}
    Click Element  ${xpath_ldap_save_settings}
    Wait Until Page Contains  Successfully saved Open LDAP settings
    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains Element  ${xpath_ldap_heading}

    ${resp}=  Run Keyword And Return Status  Redfish.Login  ${LDAP_USER}
    ...  ${LDAP_USER_PASSWORD}
    Should Be Equal  ${resp}  ${False}
    ...  msg=LDAP user was able to login even though the LDAP service was disabled.
    Redfish.Logout

*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    # Navigate to https://xx.xx.xx.xx/#/access-control/ldap  LDAP page.

    Click Element  ${xpath_access_control_menu}
    Click Element  ${xpath_ldap_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  ldap


Get LDAP User Group Name
    [Documentation]  Get LDAP user Role and group.

    @{group_name_elements}=  Get WebElements  css=${css_group_name}
    ${group_names}=  Create List

    FOR  ${group_name_element}  IN  @{group_name_elements}
       ${group_name}=  Get Text  ${group_name_element}
       Append To List  ${group_names}  ${group_name}
    END

    [Return]  ${group_names}


Get LDAP Group Privileges
    [Documentation]  Get LDAP group privileges.

    @{group_privilege_elements}=  Get WebElements  css=${css_group_privilege}
    ${group_privileges}=  Create List

    FOR  ${group_privilege_element}  IN  @{group_privilege_elements}
      ${privilege}=  Get Text  ${group_privilege_element}
      Append To List  ${group_privileges}  ${privilege}
    END

    [Return]  ${group_privileges}
