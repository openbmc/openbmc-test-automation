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
${xpath_add_group_name}                 //*[@id="role-group-name"]
${xpath_add_group_Privilege}            //*[@id="privilege"]
${xpath_add_privilege_button}           //button[text()=" Add "]
${xpath_delete_group_button}            //*[@title="Delete"]
${xpath_delete_button}                  //button[text()="Delete"]

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


Verify LDAP User With Admin Privilege Able To Do BMC Reboot
    [Documentation]  Verify that LDAP user with administrator privilege able to do BMC reboot.
    [Tags]  Verify_LDAP_User_With_Admin_Privilege_Able_To_Do_BMC_Reboot
    [Teardown]  Delete LDAP Role Group  ${GROUP_NAME}

    Update LDAP Configuration with LDAP User Role And Group  ${GROUP_NAME}  ${GROUP_PRIVILEGE}
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish OBMC Reboot (off)
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

    Select Checkbox  ${xpath_enable_ldap_checkbox}
    Checkbox Should Be Selected  ${xpath_enable_ldap_checkbox}
    ${radio_buttons}=    Get WebElements    ${xpath_service_radio_button}

    Run Keyword If  '${ldap_service_type}' == 'LDAP'
    ...  Click Element At Coordinates  ${radio_buttons}[${0}]  0  0
    ...  ELSE  Click Element At Coordinates  ${radio_buttons}[${1}]  0  0

    Wait Until Page Contains Element  ${xpath_ldap_url}
    Input Text  ${xpath_ldap_url}  ${ldap_server_uri}
    Input Text  ${xpath_ldap_bind_dn}  ${ldap_bind_dn}
    Input Text  ${xpath_ldap_password}  ${ldap_bind_dn_password}
    Input Text  ${xpath_ldap_base_dn}  ${ldap_base_dn}
    Click Element  ${xpath_ldap_save_settings}

    Run Keyword If  '${ldap_service_type}'=='LDAP'
    ...  Wait Until Page Contains  Successfully saved Open LDAP settings
    ...  ELSE
    ...  Wait Until Page Contains  Successfully saved Active Directory settings

    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains Element  ${xpath_ldap_heading}


Get LDAP Configuration
    [Documentation]  Retrieve LDAP Configuration.
    [Arguments]   ${ldap_type}

    # Description of argument(s):
    # ldap_type  The LDAP type ("ActiveDirectory" or "LDAP").

    ${radio_buttons}=  Get WebElements  ${xpath_service_radio_button}

    ${status}=  Run Keyword And Return Status
    ...  Run Keyword If  '${ldap_type}'=='LDAP'
    ...  Checkbox Should Be Selected  ${radio_buttons}[${0}]
    ...  ELSE
    ...  Checkbox Should Be Selected  ${radio_buttons}[${1}]
    Should Be Equal  ${status}  ${True}


Update LDAP Configuration with LDAP User Role And Group
    [Documentation]  Update LDAP configuration update with LDAP user Role and group.
    [Arguments]  ${group_name}  ${group_privilege}

    # Description of argument(s):
    # group_name       The group name of user.
    # group_privilege  The group privilege ("Administrator", "Operator", "ReadOnly" or "NoAcccess").

    Create LDAP Configuration
    Click Element  ${xpath_add_role_group_button}
    Input Text  ${xpath_add_group_name}  ${group_name}
    Select From List By Value  ${xpath_add_group_Privilege}  ${group_privilege}
    Click Element  ${xpath_add_privilege_button}

    ${ldap_privilege}  ${ldap_group_name}=  Get LDAP Privilege And Group Name Via Redfish
    List Should Contain Value  ${ldap_group_name}  ${group_name}
    List Should Contain Value  ${ldap_privilege}  ${group_privilege}


Get LDAP Configuration Using Redfish
    [Documentation]  Retrieve LDAP Configuration.
    [Arguments]   ${ldap_type}

    # Description of argument(s):
    # ldap_type  The LDAP type ("ActiveDirectory" or "LDAP").

    ${ldap_config}=  Redfish.Get Properties  ${REDFISH_BASE_URI}AccountService
    [Return]  ${ldap_config["${ldap_type}"]}


Get LDAP Privilege And Group Name Via Redfish
    [Documentation]  Get LDAP privilege and groupname.

    ${ldap_config}=  Get LDAP Configuration Using Redfish  ${LDAP_TYPE}
    ${num_list_entries}=  Get Length  ${ldap_config["RemoteRoleMapping"]}
    ${ldap_group_names}=  Create List
    ${ldap_privileges}=  Create List

    FOR  ${i}  IN RANGE  ${num_list_entries}
      Append To List  ${ldap_group_names}  ${ldap_config["RemoteRoleMapping"][${i}]["RemoteGroup"]}
      Append To List  ${ldap_privileges}  ${ldap_config["RemoteRoleMapping"][${i}]["LocalRole"]}
    END

    [Return]  ${ldap_privileges}  ${ldap_group_names}


Delete LDAP Role Group
    [Documentation]  Delete LDAP role group.
    [Arguments]  ${group_name}

    # Description of argument(s):
    # group_name         The group name of user.

    ${ldap_privilege}  ${ldap_groupame}=  Get LDAP Privilege And Group Name Via Redfish
    ${get_groupname_index}=  Get Index From List  ${ldap_groupame}  ${group_name}
    ${delete_group_elements}=  Get WebElements  ${xpath_delete_group_button}
    Click Element  ${delete_group_elements}[${get_groupname_index}]
    Click Element  ${xpath_delete_button}
    ${ldap_privileges}  ${ldap_groupnames}=  Get LDAP Privilege And Group Name Via Redfish
    List Should Not Contain Value  ${ldap_groupnames}  ${group_name}
