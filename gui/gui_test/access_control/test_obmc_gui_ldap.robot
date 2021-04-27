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
${xpath_ldap_url}                       //*[@data-test-id='ldap-input-serverUri']
${xpath_ldap_bind_dn}                   //*[@data-test-id='ldap-input-bindDn']
${xpath_ldap_password}                  //*[@id='bind-password']
${xpath_ldap_base_dn}                   //*[@data-test-id='ldap-input-baseDn']
${xpath_ldap_save_settings}             //*[@data-test-id='ldap-button-saveSettings']
${xpath_select_refresh_button}          //*[text()[contains(.,"Refresh")]]
${css_group_name}                       [aria-colindex="2"][role="cell"]
${css_group_privilege}                  [aria-colindex="3"][role="cell"]
${xpath_add_group_name}                 //*[@id="role-group-name"]
${xpath_add_group_Privilege}            //*[@id="privilege"]

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


Verify Create LDAP Configuration
    [Documentation]  Verify created LDAP configuration.
    [Tags]  Verify_Created_LDAP_Configuration

    Create LDAP Configuration
    Get LDAP Configuration  ${LDAP_TYPE}
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Logout
    Redfish.Login


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    # Navigate to https://xx.xx.xx.xx/#/access-control/ldap  LDAP page.

    Click Element  ${xpath_access_control_menu}
    Click Element  ${xpath_ldap_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  ldap


Create LDAP Configuration
    [Documentation]  Create LDAP configuration.
    [Arguments]  ${ldap_server_uri}=${LDAP_SERVER_URI}  ${ldap_servicetype}=${LDAP_TYPE}
    ...  ${ldap_bind_dn}=${LDAP_BIND_DN}  ${ldap_bind_dn_password}=${LDAP_BIND_DN_PASSWORD}
    ...  ${ldap_base_dn}=${LDAP_BASE_DN}

    # Description of argument(s):
    # ldap_server_uri        LDAP server uri (e.g. ldap://XX.XX.XX.XX).
    # ldap_type              The LDAP type ("ActiveDirectory" or "LDAP").
    # ldap_bind_dn           The LDAP bind distinguished name.
    # ldap_bind_dn_password  The LDAP bind distinguished name password.
    # ldap_base_dn           The LDAP base distinguished name.

    Wait Until Page Contains Element  ${xpath_enable_ldap_checkbox}
    Wait Until Element Is Enabled  ${xpath_enable_ldap_checkbox}
    Select Checkbox  ${xpath_enable_ldap_checkbox}
    Checkbox Should Be Selected  ${xpath_enable_ldap_checkbox}
    ${radio_buttons}=    Get WebElements    ${xpath_service_radio_button}

    Run Keyword If  '${ldap_service_type}' == 'OpenLDAP'
    ...  Click Element At Coordinates  ${radio_buttons}[${0}]  0  0
    ...  ELSE  Click Element At Coordinates  ${radio_buttons}[${1}]  0  0

    Wait Until Page Contains Element  ${xpath_ldap_url}
    Wait Until Element Is Enabled  ${xpath_ldap_url}
    Input Text  ${xpath_ldap_url}  ${ldap_server_uri}
    Input Text  ${xpath_ldap_bind_dn}  ${ldap_bind_dn}
    Input Text  ${xpath_ldap_password}  ${ldap_bind_dn_password}
    Input Text  ${xpath_ldap_base_dn}  ${ldap_base_dn}
    Click Element  ${xpath_ldap_save_settings}

    Run Keyword If  '${ldap_service_type}'=='OpenLDAP'
    ...  Wait Until Page Contains  Successfully saved Open LDAP settings
    ...  ELSE
    ...  Wait Until Page Contains  Successfully saved Active Directory settings

    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains Element  ${xpath_ldap_heading}


Get LDAP Configuration
    [Documentation]  Retrieve LDAP Configuration.
    [Arguments]   ${ldap_type}

    # Description of argument(s):
    # ldap_type  The LDAP type ("ActiveDirectory" or "OpenLDAP").

    ${radio_buttons}=  Get WebElements  ${xpath_service_radio_button}

    ${status}=  Run Keyword And Return Status
    ...  Run Keyword If  '${ldap_type}'=='OpenLDAP'
    ...  Checkbox Should Be Selected  ${radio_buttons}[${0}]
    ...  ELSE
    ...  Checkbox Should Be Selected  ${radio_buttons}[${1}]
    Should Be Equal  ${status}  ${True}


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


Restore LDAP Privileges
    [Documentation]  Restore the LDAP privilege to its original value.

    Return From Keyword If  ${old_ldap_privilege} == @{empty}
    Update LDAP Configuration with LDAP User Role And Group
    ...   ${old_ldap_group_names}  ${old_ldap_group_privileges}


Update LDAP Configuration with LDAP User Role And Group
    [Documentation]  Update LDAP configuration update with LDAP user Role and group.
    [Arguments]  ${group_name}  ${group_privilege}

    # Description of argument(s):
    # group_name       The group name of user.
    # group_privilege  The group privilege ("Administrator", "Operator", "User" or "Callback").

    Click Element  ${xpath_add_role_group_button}
    Input Text  ${xpath_add_group_name}  ${group_name}
    Select From List By Value  ${xpath_add_group_Privilege}  ${group_privilege}
    Wait Until Element Is Enabled  //button[contains(text(),"Add")]
    ${add_privilege}=  Get WebElements  //button[contains(text(),"Add")]
    Click Button   ${add_privilege_button}[${1}]
    Wait Until Page Contains  Successfully added role group '${group_name}'.

    ${ldap_group_name}=  Get LDAP User Group Name
    List Should Contain Value  ${ldap_group_name}  ${group_name}
    ${ldap_group_privilege}=  Get LDAP Group Privileges
    List Should Contain Value  ${ldap_group_privilege}  ${group_privilege}
