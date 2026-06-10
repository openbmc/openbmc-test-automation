*** Settings ***

Documentation  Test OpenBMC GUI "User management" sub-menu of "Security and access".

Resource        ../../lib/gui_resource.robot

Test Setup      Test Setup Execution
Test Teardown   Test Teardown Execution
Suite Teardown   Suite Teardown Execution

Test Tags      User_Management_Sub_Menu


*** Variables ***

${xpath_user_management_heading}         //h1[text()="User management"]
${xpath_select_user}                     //input[@data-test-id='userManagement-checkbox-tableHeaderCheckbox']
${xpath_account_policy}                  //button[contains(., 'Account policy settings')]
${xpath_add_user}                        //button[contains(., 'Account policy settings')]/following-sibling::button[1]
${xpath_edit_user}                       //*[@data-test-id='userManagement-tableRowAction-edit-0']
${xpath_delete_user}                     //*[@data-test-id='userManagement-tableRowAction-delete-1']
${xpath_account_status_enabled_button}   //*[@data-test-id='userManagement-radioButton-statusEnabled']
${xpath_account_status_disabled_button}  //*[@data-test-id='userManagement-radioButton-statusDisabled']
${xpath_username_input_button}           //*[@data-test-id='userManagement-input-username']
${xpath_privilege_list_button}           //*[@data-test-id='userManagement-select-privilege']
${xpath_password_input_button}           //*[@data-test-id='userManagement-input-password']
${xpath_password_confirm_button}         //*[@data-test-id='userManagement-input-passwordConfirmation']
${xpath_disable_user_radio}              //input[contains(@data-test-id,'statusDisabled')]
${xpath_cancel_button}                   //button[normalize-space(.)='Save']/preceding-sibling::button
${xpath_save_button}                     //button[normalize-space(.)='Save']
${xpath_delete_button}                   //button[text()='Delete user']
${xpath_cancel_button_1}                 (//div[contains(@class,'modal-footer')]//button[normalize-space(.)='Cancel'])[2]
${xpath_add_user_1}                      //button[normalize-space(.)='Cancel']/following-sibling::button[normalize-space(.)='Add user']
${xpath_edit_user_save_button}           //div[contains(@class,'show')]//button[normalize-space()='Cancel']/following-sibling::button[1]
${xpath_add_user_heading}                //h5[contains(normalize-space(),'Add user')]
${xpath_policy_settings_header}          //*[text()="Account policy settings"]
${xpath_auto_unlock}                     //*[@data-test-id='userManagement-radio-automaticUnlock']
${xpath_manual_unlock}                   //*[@data-test-id='userManagement-radio-manualUnlock']
${xpath_max_failed_login}                //*[@data-test-id='userManagement-input-lockoutThreshold']
${test_user_password}                    TestPwd1
${xpath_user_creation_error_message}     //*[contains(text(),'Error creating user')]
${xpath_close_error_message}             //div[contains(@class,'toast')]//button[@aria-label='Close']
@{username}                              admin_user  readonly_user  disabled_user
@{list_user_privilege}                   Administrator  ReadOnly


*** Test Cases ***

Verify Navigation To User Management Page
    [Documentation]  Verify navigation to user management page.
    [Tags]  Verify_Navigation_To_User_Management_Page

    Page Should Contain Element  ${xpath_user_management_heading}


Verify Existence Of All Sections In User Management Page
    [Documentation]  Verify existence of all sections in user management page.
    [Tags]  Verify_Existence_Of_All_Sections_In_User_Management_Page

    Page Should Contain  View privilege role descriptions


Verify Existence Of All Input Boxes In User Management Page
    [Documentation]  Verify existence of all sections in user managemnet page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_User_Management_Page

    Page Should Contain Checkbox  ${xpath_select_user}


Verify Existence Of All Buttons In User Management Page
    [Documentation]  Verify existence of all buttons in user management page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_User_Management_Page

    Page Should Contain Button  ${xpath_account_policy}
    Page Should Contain Button  ${xpath_add_user}
    Page Should Contain Element  ${xpath_edit_user}
    Page Should Contain Element  ${xpath_delete_user}


Verify Existence Of All Button And Fields In Add User
    [Documentation]  Verify existence of all buttons and fields in add user page.
    [Tags]  Verify_Existence_Of_All_Button_And_Fields_In_Add_User
    [Teardown]  Run Keywords  Click Element  ${xpath_cancel_button_1}  AND
    ...         Wait Until Element Is Visible  ${xpath_add_user}

    Click Element  ${xpath_add_user}
    Wait Until Element Is Visible  ${xpath_add_user_1}
    Wait Until Page Contains Element  ${xpath_add_user_heading}

    Page Should Contain Element  ${xpath_account_status_enabled_button}
    Page Should Contain Element  ${xpath_account_status_disabled_button}
    Page Should Contain Element  ${xpath_username_input_button}
    Page Should Contain Element  ${xpath_privilege_list_button}
    Page Should Contain Element  ${xpath_password_input_button}
    Page Should Contain Element  ${xpath_password_confirm_button}
    Page Should Contain Element  ${xpath_cancel_button_1}
    Page Should Contain Element  ${xpath_add_user_1}


Verify Existence Of All Buttons And Fields In Account Policy Settings
    [Documentation]  Verify existence of all buttons and fields in account policy settings page.
    [Tags]  Verify_Existence_Of_All_Buttons_And_Fields_In_Account_Policy_Settings
    [Teardown]  Run Keywords  Click Element  ${xpath_cancel_button}  AND
    ...         Wait Until Element Is Visible  ${xpath_account_policy}

    Click Element  ${xpath_account_policy}
    Wait Until Element Is Visible  ${xpath_save_button}
    Wait Until Page Contains Element  ${xpath_policy_settings_header}

    Page Should Contain Element  ${xpath_auto_unlock}
    Page Should Contain Element  ${xpath_manual_unlock}
    Page Should Contain Element  ${xpath_max_failed_login}
    Page Should Contain Element  ${xpath_save_button}
    Page Should Contain Element  ${xpath_cancel_button}


Verify User Access Privilege
    [Documentation]  Create a new user with a privilege and verify that user is created.
    [Tags]  Verify_User_Access_Privilege
    [Teardown]  Delete Users Via Redfish  @{username}
    [Template]  Create User And Verify

    # username       privilege_level  enabled
    ${username}[0]   Administrator    ${True}
    ${username}[1]   ReadOnly         ${True}
    ${username}[2]   Administrator    ${False}


Verify Operator User Privilege
    [Documentation]  Create users with different access privilege
    ...  and verify that the user is getting created.
    [Tags]  Verify_Operator_User_Privilege
    [Template]  Create User And Verify

    # username      privilege_level   enabled
    operator_user   Operator          ${True}


Verify User Account And Properties Saved Through Reboots
    [Documentation]  Verify that user account and properties saved through reboots.
    [Teardown]  Delete Users Via Redfish  my_admin_user
    [Tags]  Verify_User_Account_And_Properties_Saved_Through_Reboots

    # Create an User account.
    Create User And Verify  my_admin_user  Administrator  ${True}

    # Reboot BMC and Navigate to usermanagement page.
    Reboot Server
    Navigate To Required Sub Menu  ${xpath_security_and_access_menu}  ${xpath_user_management_sub_menu}  user-management

    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains  my_admin_user  timeout=15


Delete User Account Via GUI
    [Documentation]  Delete user account via GUI.
    [Tags]  Delete_User_Account_Via_GUI

    # Create new user account via GUI.
    Create User And Verify  ${username}[0]  Administrator  ${True}

    # Delete the user created via GUI.
    Delete Users Via GUI  ${username}[0]


Verify Error While Creating Users With Same Name
    [Documentation]  Verify proper error message while creating two user accounts with same username.
    [Tags]  Verify_Error_While_Creating_Users_With_Same_Name
    [Teardown]  Delete Users Via Redfish  ${username}

    # Get random username and user privilege level.
    ${username}=  Generate Random String  8  [LETTERS]
    ${privilege_level}=  Evaluate  random.choice(${list_user_privilege})  random

    # Create new user account.
    Create User And Verify  ${username}  ${privilege_level}  ${True}

    # Expect failure while creating second user account with same username.
    Create User And Verify  ${username}  ${privilege_level}  ${True}  Failure


Test Modifying User Privilege Of Existing User Via GUI
    [Documentation]  Modify user privilege of existing user via GUI and verify the changes using Redfish.
    [Tags]  Test_Modifying_User_Privilege_Of_Existing_User_Via_GUI
    [Teardown]  Delete Users Via Redfish  ${username}

    # Get random username and user privilege level.
    ${username}=  Generate Random String  8  [LETTERS]
    ${privilege_level}=  Evaluate  random.choice(${list_user_privilege})  random

    # Create new user account.
    Create User And Verify  ${username}  ${privilege_level}  ${True}

    # Get user privilege role details distinct from the current ones.
    FOR  ${privilege}  IN  @{list_user_privilege}
      IF  '${privilege}' != '${privilege_level}'
          VAR  ${modify_privilege}  ${privilege}
      END
    END

    # Modify user privilege via GUI.
    Wait Until Keyword Succeeds  30 sec   5 sec  Click Element
    ...  (//td[normalize-space()='${username}']/ancestor::tr//button)[2]
    Select From List By Value  ${xpath_privilege_list_button}  ${modify_privilege}

    # Submit changes.
    Wait And Click Element  ${xpath_edit_user_save_button}

    # Confirm the successful update.
    Verify Success Message On BMC GUI Page

    # Verify user privilege via Redfish.
    Redfish.Login
    ${resp}=  Redfish.Get  /redfish/v1/AccountService/Accounts/${username}
    Should Be Equal  ${resp.dict["RoleId"]}  ${modify_privilege}
    Redfish.Logout


Test Modifying User Account Status Of Existing User Via GUI
    [Documentation]  Test modifying user account status of existing user via GUI
    ...              and verify changes using Redfish.
    [Tags]  Test_Modifying_User_Account_Status_Of_Existing_User_Via_GUI
    [Teardown]  Delete Users Via Redfish  ${username}

    # Get random username, user privilege level and account status.
    ${username}=  Generate Random String  8  [LETTERS]
    VAR  ${privilege_level}  Administrator
    VAR  ${initial_account_status}  ${True}

    # Create new user account.
    Create User And Verify  ${username}  ${privilege_level}  ${True}

    # Modify user account status via GUI.
    Wait Until Keyword Succeeds  30 sec   5 sec  Click Element
    ...  (//td[normalize-space()='${username}']/ancestor::tr//button)[2]
    Wait Until Element Is Visible  ${xpath_edit_user_save_button}  timeout=30

    # Switch the user account status to its opposite state.
    IF  ${initial_account_status} == ${True}
        Click Element  ${xpath_account_status_disabled_button}  0  0
    ELSE
        Click Element  ${xpath_account_status_enabled_button}  0  0
    END

    # Save changes.
    Click Element  ${xpath_edit_user_save_button}

    # Confirm the successful update.
    Verify Success Message On BMC GUI Page

    # Verify account status via Redfish.
    IF  ${initial_account_status} == ${True}
        ${status}=  Run Keyword And Return Status  Redfish.Login  ${username}  ${test_user_password}
        Should Be Equal  ${status}  ${False}
    ELSE
        ${status}=  Run Keyword And Return Status  Redfish.Login  ${username}  ${test_user_password}
        Should Be Equal  ${status}  ${True}
    END

Test Modifying User Password Of Existing User Via GUI
    [Documentation]  Modify user password of existing user via GUI and verify changes using Redfish.
    [Tags]  Test_Modifying_User_Password_Of_Existing_User_Via_GUI
    [Teardown]  Delete Users Via Redfish  ${username}

    # Get random username, user privilege level and account status.
    ${username}=  Generate Random String  8  [LETTERS]
    ${privilege_level}=  Evaluate  random.choice(${list_user_privilege})  random

    # Initialize the new password for the account.
    VAR  ${new_password}  Testpassword1

    # Create new user account.
    Create User And Verify  ${username}  ${privilege_level}  ${True}

    # Wait for newly created user to appear on the page.
    Wait Until Element Is Visible  //td[text()='${username}']

    # Modify user password via GUI.
    Click Element  (//td[normalize-space()='${username}']/ancestor::tr//button)[2]
    Wait Until Element Is Visible  ${xpath_edit_user_save_button}  timeout=30

    Input Text  ${xpath_password_input_button}  ${new_password}
    Input Text  ${xpath_password_confirm_button}  ${new_password}

    # Save changes.
    Click Element  ${xpath_edit_user_save_button}

    # Confirm the successful update.
    Verify Success Message On BMC GUI Page

    # Verify changes via Redfish.
    ${status}=  Run Keyword And Return Status  Redfish.Login  ${username}  ${new_password}
    Should Be Equal  ${status}  ${True}


Verify Creating User Without Privileges Via GUI
    [Documentation]  Verify creating user without setting user privileges
    ...              via GUI.
    [Tags]  Verify_Creating_User_Without_Privileges_Via_GUI
    [Teardown]  Click Element  ${xpath_cancel_button_1}

    # Get random username.
    ${username}=  Generate Random String  8  [LETTERS]

    # Click the add user button.
    Click Element  ${xpath_add_user}
    Wait Until Page Contains Element  ${xpath_add_user_heading}

    # Set user name and password.
    Input Text  ${xpath_username_input_button}  ${user_name}
    Input Text  ${xpath_password_input_button}  ${test_user_password}
    Input Text  ${xpath_password_confirm_button}  ${test_user_password}

    # Save changes.
    Click Element  ${xpath_edit_user_save_button}

    # Expect get the field required messages.
    Page Should Contain  Field required


Verify Creating User With Invalid Password Length Via GUI
    [Documentation]  Verify creating user with invalid password length
    ...              via GUI.
    [Tags]  Verify_Creating_User_With_Invalid_Password_Length_Via_GUI
    [Teardown]  Click Element  ${xpath_cancel_button_1}

    # Get random username.
    ${username}=  Generate Random String  8  [LETTERS]

    # Click the add user button.
    Click Element  ${xpath_add_user}
    Wait Until Page Contains Element  ${xpath_add_user_heading}

    # Set user name.
    Input Text  ${xpath_username_input_button}  ${user_name}

    # Set user privilege.
    Select From List By Value  ${xpath_privilege_list_button}  Administrator

    # Set user password.
    ${password_input}=  Generate Random String  66  [LETTERS][NUMBERS]
    Input Text  ${xpath_password_input_button}  ${password_input}
    Input Text  ${xpath_password_confirm_button}  ${password_input}

    # Save changes.
    Click Element  ${xpath_edit_user_save_button}

    # Expect get the password invalid length messages.
    Page Should Contain  Password must be between 8 \u2013 64 characters
    Click Element  ${xpath_cancel_button_1}

    Wait And Click Element  ${xpath_add_user}
    Wait Until Page Contains Element  ${xpath_add_user_heading}

    # Set user name.
    Input Text  ${xpath_username_input_button}  ${user_name}

    # Set user privilege.
    Select From List By Value  ${xpath_privilege_list_button}  Administrator

    # Set user password.
    Input Text  ${xpath_password_input_button}  testusr
    Input Text  ${xpath_password_confirm_button}  testusr

    # Save changes.
    Click Element  ${xpath_edit_user_save_button}

    # Expect get the password invalid length messages.
    Page Should Contain  Password must be between 8 \u2013 64 characters


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test setup tasks.

    # Navigate to https://xx.xx.xx.xx/#/access-control/user-management  user management page.

    Launch Browser And Login GUI
    Execute Javascript    document.body.style.zoom="70%"
    Navigate To Required Sub Menu  ${xpath_security_and_access_menu}  ${xpath_user_management_sub_menu}  user-management
    Wait Until Element Is Visible  ${xpath_page_loading_progress_bar}  timeout=30
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
    Wait Until Page Does Not Contain  Loading


Create User And Verify
    [Documentation]  Create a user with given user name and privilege and verify that the
    ...  user is created successfully via GUI and Redfish.
    [Arguments]  ${user_name}  ${user_privilege}  ${enabled}  ${expected_status}=Success

    # Description of argument(s):
    # user_name           The name of the user to be created.
    # user_privilege      Privilege of the user.
    # enabled             True = enabled user, False = disabled user.
    # expected_status     Expected status of user creation.

    # Create user via GUI.
    Wait And Click Element  ${xpath_add_user}
    Wait Until Page Contains Element  ${xpath_add_user_heading}

    # Input username, password and privilege.
    Input Text  ${xpath_username_input_button}  ${user_name}
    Select From List By Value  ${xpath_privilege_list_button}  ${user_privilege}

    Input Text  ${xpath_password_input_button}  ${test_user_password}
    Input Text  ${xpath_password_confirm_button}  ${test_user_password}

    # Select disabled radio button if required.
    IF  not ${enabled}
        Click Element  ${xpath_disable_user_radio}
    END

    # Add user.
    Click Element  ${xpath_add_user_1}

    # Proceed with future steps based on the expected execution status.
    IF  '${expected_status}' == 'Success'

        # Verify success message.
        Verify Success Message On BMC GUI Page

        # Refresh page and check new user is available.
        Wait Until Page Contains Element  ${xpath_add_user}
        Refresh GUI
        Wait Until Page Contains  ${user_name}  timeout=15

        # Cross-check privilege via Redfish.
        Redfish.Login

        ${user_priv_redfish}=  Redfish_Utils.Get Attribute
        ...  /redfish/v1/AccountService/Accounts/${user_name}
        ...  RoleId

        Should Be Equal  ${user_privilege}  ${user_priv_redfish}

        # Verify enabled/disabled status.
        ${enabled_status}=  Redfish_Utils.Get Attribute
        ...  /redfish/v1/AccountService/Accounts/${user_name}
        ...  Enabled

        Should Be Equal  ${enabled}  ${enabled_status}

        # Verify login behavior.
        ${status}=  Run Keyword And Return Status
        ...  Redfish.Login
        ...  ${user_name}
        ...  ${test_user_password}

        IF  not ${enabled_status}
            Should Be Equal  ${status}  ${False}
        ELSE
            Should Be Equal  ${status}  ${True}
        END

        Redfish.Logout

    ELSE IF  '${expected_status}' == 'Failure'

        Wait Until Element Is Visible  ${xpath_user_creation_error_message}  timeout=60

        # Close error popup.
        Click Element  ${xpath_close_error_message}

        Wait Until Element Is Not Visible  ${xpath_user_creation_error_message}  timeout=60

    END


Delete Users Via Redfish
    [Documentation]  Delete given users using Redfish.
    [Arguments]  @{user_list}

    # Description of argument(s):
    # user_list          List of user name to be deleted.

    FOR  ${user}  IN  @{user_list}
      Redfish.Login
      Redfish.Delete  /redfish/v1/AccountService/Accounts/${user}
      Redfish.Logout
    END


Delete Users Via GUI
    [Documentation]  Delete given users via GUI.
    [Arguments]  @{user_list}

    # Description of argument(s):
    # user_list          List of user name to be deleted.

    FOR  ${user}  IN  @{user_list}
      Wait Until Keyword Succeeds  30 sec  5 sec  Click Element
      ...  //td[normalize-space()='${user}']/following::button[3]
      Wait Until Keyword Succeeds  30 sec  5 sec  Click Element  ${xpath_delete_button}
      Verify Success Message On BMC GUI Page
    END


Test Teardown Execution
    [Documentation]  Do test teardown tasks.

    Logout GUI
    Close Browser


Suite Teardown Execution
    [Documentation]  Do suite teardown tasks.

    Run Keyword And Ignore Error  Logout GUI
    Close All Browsers
    Redfish.Logout