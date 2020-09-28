*** Settings ***

Documentation  Test OpenBMC GUI "Local user management" sub-menu of "Access control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***
${xpath_local_user_management_heading }  //h1[text()="Local user management"]
${xpath_select_user}                     //input[contains(@class,"custom-control-input")]
${xpath_account_policy}                  //button[contains(text(),'Account policy settings')]
${xpath_add_user}                        //button[contains(text(),'Add user')]
${xpath_edit_user}                       //button[@aria-label="Edit user"]
${xpath_delete_user}                     //button[@aria-label="Delete user"]
${xpath_radio_account_status_enabled}    //*[@data-test-id='localUserManagement-radioButton-statusEnabled']
${xpath_radio_account_status_disabled}   //*[@data-test-id='localUserManagement-radioButton-statusDisabled']
${xpath_input_username}                  //*[@data-test-id='localUserManagement-input-username']
${xpath_list_privilege}                  //*[@data-test-id='localUserManagement-select-privilege']
${xpath_input_password}                  //*[@data-test-id='localUserManagement-input-password']
${xpath_input_password_confirmation}     //*[@data-test-id='localUserManagement-input-passwordConfirmation']
${xpath_cancel_button}                   //*[@data-test-id='localUserManagement-button-cancel']
${xpath_submit_button}                   //*[@data-test-id='localUserManagement-button-submit']
${xpath_add_user_heading}                //h5[contains(text(),'Add user')]

*** Test Cases ***

Verify Navigation To Local User Management Page
    [Documentation]  Verify navigation to local user management page.
    [Tags]  Verify_Navigation_To_Local_User_Management_Page

    Page Should Contain Element  ${xpath_local_user_management_heading}


Verify Existence Of All Sections In Local User Management Page
    [Documentation]  Verify existence of all sections in local user management page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Local_User_Management_Page

    Page should contain  View privilege role descriptions


Verify Existence Of All Input Boxes In Local User Management Page
    [Documentation]  Verify existence of all sections in Manage Power Usage page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_Local_User_Management_Page

    Page Should Contain Checkbox  ${xpath_select_user}


Verify Existence Of All Buttons In Local User Management Page
    [Documentation]  Verify existence of all buttons in local user management page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Local_User_Management_Page

    Page should contain Button  ${xpath_account_policy}
    Page should contain Button  ${xpath_add_user}
    Page Should Contain Button  ${xpath_edit_user}
    Page Should Contain Button  ${xpath_delete_user}


Verify Newly Create User
    [Documentation]  Create a new user and verifying that user is created.
    [Tags]  Verify_Newly_Create_User
    [Teardown]  Redfish.Delete  /redfish/v1/AccountService/Accounts/TestUser

    Click Element  ${xpath_add_user}
    Wait Until Page Contains Element  ${xpath_add_user_heading}

    # Input username, password and privilege.
    Input Text  ${xpath_input_username}  TestUser
    Select From List by Value  ${xpath_list_privilege}  Administrator

    Input Text  ${xpath_input_password}  TestPwd1

    Input Text  ${xpath_input_password_confirmation}  TestPwd1

    # Submit.
    Click Element  ${xpath_submit_button}

    # Refresh page and check new user is available.
    Wait Until Page Contains Element  ${xpath_add_user}
    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains  TestUser  timeout=15

    # Cross check the privilege of newly added user via Redfish.
    ${user_priv_redfish}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/TestUser  RoleId
    Should Be Equal  Administrator  ${user_priv_redfish}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    # Navigate to https://xx.xx.xx.xx/#/access-control/local-user-management  Local users page.

    Click Element  ${xpath_access_control_menu}
    Click Element  ${xpath_local_user_management_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  local-user-management
