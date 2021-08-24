*** Settings ***

Documentation  Test OpenBMC GUI "User management" sub-menu of "Security and access".

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***
${xpath_user_management_heading}         //h1[text()="User management"]
${xpath_select_user}                     //input[contains(@class,"custom-control-input")]
${xpath_account_policy}                  //button[contains(text(),'Account policy settings')]
${xpath_add_user}                        //button[contains(text(),'Add user')]
${xpath_edit_user}                       //*[@data-test-id='userManagement-tableRowAction-edit-0']
${xpath_delete_user}                     //*[@data-test-id='userManagement-tableRowAction-delete-1']
${xpath_account_status_enabled_button}   //*[@data-test-id='userManagement-radioButton-statusEnabled']
${xpath_account_status_disabled_button}  //*[@data-test-id='userManagement-radioButton-statusDisabled']
${xpath_username_input_button}           //*[@data-test-id='userManagement-input-username']
${xpath_privilege_list_button}           //*[@data-test-id='userManagement-select-privilege']
${xpath_password_input_button}           //*[@data-test-id='userManagement-input-password']
${xpath_password_confirm_button}         //*[@data-test-id='userManagement-input-passwordConfirmation']
${xpath_cancel_button}                   //*[@data-test-id='userManagement-button-cancel']
${xpath_submit_button}                   //*[@data-test-id='userManagement-button-submit']
${xpath_add_user_heading}                //h5[contains(text(),'Add user')]
${xpath_policy_settings_header}          //*[text()="Account policy settings"]
${xpath_auto_unlock}                     //*[@data-test-id='userManagement-radio-automaticUnlock']
${xpath_manual_unlock}                   //*[@data-test-id='userManagement-radio-manualUnlock']
${xpath_max_failed_login}                //*[@data-test-id='userManagement-input-lockoutThreshold']
${test_user_password}                    TestPwd1

*** Test Cases ***

Verify Navigation To User Management Page
    [Documentation]  Verify navigation to user management page.
    [Tags]  Verify_Navigation_To_User_Management_Page

    Page Should Contain Element  ${xpath_user_management_heading}


Verify Existence Of All Sections In User Management Page
    [Documentation]  Verify existence of all sections in user management page.
    [Tags]  Verify_Existence_Of_All_Sections_In_User_Management_Page

    Page should contain  View privilege role descriptions


Verify Existence Of All Input Boxes In User Management Page
    [Documentation]  Verify existence of all sections in user managemnet page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_User_Management_Page

    Page Should Contain Checkbox  ${xpath_select_user}


Verify Existence Of All Buttons In User Management Page
    [Documentation]  Verify existence of all buttons in user management page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_User_Management_Page

    Page should contain Button  ${xpath_account_policy}
    Page should contain Button  ${xpath_add_user}
    Page Should Contain Element  ${xpath_edit_user}
    Page Should Contain Element  ${xpath_delete_user}


Verify Existence Of All Button And Fields In Add User
    [Documentation]  Verify existence of all buttons and fields in add user page.
    [Tags]  Verify_Existence_Of_All_Button_And_Fields_In_Add_User
    [Teardown]  Click Element  ${xpath_cancel_button}

    Click Element  ${xpath_add_user}
    Wait Until Page Contains Element  ${xpath_add_user_heading}
    Page Should Contain Element  ${xpath_account_status_enabled_button}
    Page Should Contain Element  ${xpath_account_status_disabled_button}
    Page Should Contain Element  ${xpath_username_input_button}
    Page Should Contain Element  ${xpath_privilege_list_button}
    Page Should Contain Element  ${xpath_password_input_button}
    Page Should Contain Element  ${xpath_password_confirm_button}
    Page Should Contain Element  ${xpath_cancel_button}
    Page Should Contain Element  ${xpath_submit_button}


Verify Existence Of All Buttons And Fields In Account Policy Settings
    [Documentation]  Verify existence of all buttons and fields in account policy settings page.
    [Tags]  Verify_Existence_Of_All_Buttons_And_Fields_In_Account_Policy_Settings
    [Teardown]  Click Element  ${xpath_cancel_button}

    Click Element  ${xpath_account_policy}
    Wait Until Page Contains Element  ${xpath_policy_settings_header}
    Page Should Contain Element  ${xpath_auto_unlock}
    Page Should Contain Element  ${xpath_manual_unlock}
    Page Should Contain Element  ${xpath_max_failed_login}
    Page Should Contain Element  ${xpath_submit_button}
    Page Should Contain Element  ${xpath_cancel_button}


Verify User Access Privilege
    [Documentation]  Create a new user with a privilege and verify that user is created.
    [Tags]  Verify_User_Access_Privilege
    [Template]  Create User And Verify

    # username      privilege_level  enabled
    admin_user      Administrator    ${True}
    operator_user   Operator         ${True}
    readonly_user   ReadOnly         ${True}
    noaccess_user   NoAccess         ${True}
    disabled_user   Administrator    ${False}


Verify User Account And Properties Saved Through Reboots
    [Documentation]  Verify that user account and properties saved through reboots.
    [Tags]  Verify_User_Account_And_Properties_Saved_Through_Reboots

    # Create an User account.
    Create User And Verify  my_admin_user  Administrator  ${True}

    # Reboot BMC.
    Redfish OBMC Reboot (off)  stack_mode=normal

    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains  my_admin_user  timeout=15


*** Keywords ***

Create User And Verify
    [Documentation]  Create a user with given user name and privilege and verify that the
    ...  user is created successfully via GUI and Redfish.
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login  AND
    ...  Redfish.Delete  /redfish/v1/AccountService/Accounts/${user_name}
    [Arguments]  ${user_name}  ${user_privilege}  ${enabled}

    # Description of argument(s):
    # user_name           The name of the user to be created (e.g. "test", "robert", etc.).
    # user_privilege      Privilege of the user.
    # enabled             If the user is enabled (e.g True if enabled, False if disabled).

    Click Element  ${xpath_add_user}
    Wait Until Page Contains Element  ${xpath_add_user_heading}

    # Select disabled radio button if user needs to be disabled
    Run Keyword If  ${enabled} == ${False}
    ...  Click Element At Coordinates  ${xpath_account_status_disabled_button}  0  0

    # Input username, password and privilege.
    Input Text  ${xpath_username_input_button}  ${user_name}
    Select From List by Value  ${xpath_privilege_list_button}  ${user_privilege}

    Input Text  ${xpath_password_input_button}  ${test_user_password}

    Input Text  ${xpath_password_confirm_button}  ${test_user_password}

    # Submit.
    Click Element  ${xpath_submit_button}

    # Refresh page and check new user is available.
    Wait Until Page Contains Element  ${xpath_add_user}
    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains  ${user_name}  timeout=15

    # Cross check the privilege of newly added user via Redfish.
    ${user_priv_redfish}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/${user_name}  RoleId
    Should Be Equal  ${user_privilege}  ${user_priv_redfish}

    # Check enable/disable status for user.
    Redfish.Logout
    ${status}=  Run Keyword And Return Status  Redfish.Login  ${user_name}  ${test_user_password}
    Run Keyword If  ${enabled} == ${False}
    ...  Should Be Equal  ${status}  ${False}
    ...  ELSE  Should Be Equal  ${status}  ${True}


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    # Navigate to https://xx.xx.xx.xx/#/access-control/user-management  user management page.

    Click Element  ${xpath_secuity_and_accesss_menu}
    Click Element  ${xpath_user_management_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  user-managemen
