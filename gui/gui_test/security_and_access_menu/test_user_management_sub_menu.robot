*** Settings ***

Documentation  Test OpenBMC GUI "User management" sub-menu of "Security and access".

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Suite Teardown Execution
Test Setup      Test Setup Execution

Test Tags      User_Management_Sub_Menu

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
${xpath_delete_button}                   //button[text()='Delete user']
${xpath_add_user_heading}                //h5[contains(text(),'Add user')]
${xpath_policy_settings_header}          //*[text()="Account policy settings"]
${xpath_auto_unlock}                     //*[@data-test-id='userManagement-radio-automaticUnlock']
${xpath_manual_unlock}                   //*[@data-test-id='userManagement-radio-manualUnlock']
${xpath_max_failed_login}                //*[@data-test-id='userManagement-input-lockoutThreshold']
${test_user_password}                    TestPwd1
${xpath_user_creation_error_message}     //*[contains(text(),'Error creating user')]
${xpath_close_error_message}             //*/*[contains(text(),'Error')]/following-sibling::button
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

    # username      privilege_level  enabled
    operator_user   Operator         ${True}


Verify User Account And Properties Saved Through Reboots
    [Documentation]  Verify that user account and properties saved through reboots.
    [Teardown]  Delete Users Via Redfish  my_admin_user
    [Tags]  Verify_User_Account_And_Properties_Saved_Through_Reboots

    # Create an User account.
    Create User And Verify  my_admin_user  Administrator  ${True}

    # Reboot BMC.
    Redfish OBMC Reboot (off)  stack_mode=normal

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
          ${modify_privilege}=  Set Variable  ${privilege}
      END
    END

    # Modify user privilege via GUI.
    Wait Until Keyword Succeeds  30 sec   5 sec  Click Element
    ...  //td[text()='${username}']/following-sibling::*/*/*[@title='Edit user']
    Select From List by Value  ${xpath_privilege_list_button}  ${modify_privilege}

    # Submit changes.
    Click Element  ${xpath_submit_button}

    # Confirm the successful update.
    Wait Until Element Is Visible  ${xpath_success_message}  timeout=30
    Wait Until Element Is Not Visible  ${xpath_success_message}  timeout=30

    # Verify user privilege via Redfish.
    Redfish.Login
    ${resp}=  Redfish.Get  /redfish/v1/AccountService/Accounts/${username}
    Should Be Equal  ${resp.dict["RoleId"]}  ${modify_privilege}
    Redfish.Logout


Test Modifying User Account Status Of Existing User Via GUI
    [Documentation]  Test modifying user account status of existing user via GUI and verify changes using Redfish.
    [Tags]  Test_Modifying_User_Account_Status_Of_Existing_User_Via_GUI
    [Teardown]  Delete Users Via Redfish  ${username}

    # Get random username, user privilege level and account status.
    ${username}=  Generate Random String  8  [LETTERS]
    ${privilege_level}=  Evaluate  random.choice(${list_user_privilege})  random
    ${initial_account_status}=  Evaluate  random.choice([True, False])  random

    # Create new user account.
    Create User And Verify  ${username}  ${privilege_level}  ${initial_account_status}

    # Modify user account status via GUI.
    Wait Until Keyword Succeeds  30 sec   5 sec  Click Element
    ...  //td[text()='${username}']/following-sibling::*/*/*[@title='Edit user']
    Wait Until Element Is Visible  ${xpath_submit_button}  timeout=30

    # Switch the user account status to its opposite state.
    IF  ${initial_account_status} == ${True}
        Click Element At Coordinates  ${xpath_account_status_disabled_button}  0  0
    ELSE
        Click Element At Coordinates  ${xpath_account_status_enabled_button}  0  0
    END

    # Submit changes.
    Click Element  ${xpath_submit_button}

    # Confirm the successful update.
    Wait Until Element Is Visible  ${xpath_success_message}  timeout=30
    Wait Until Element Is Not Visible  ${xpath_success_message}  timeout=60

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
    ${initial_account_status}=  Evaluate  random.choice([True, False])  random

    # Initialize the new password for the account.
    ${new_password}=  Set Variable  Testpassword1

    # Create new user account.
    Create User And Verify  ${username}  ${privilege_level}  ${initial_account_status}

    # Wait for newly created user to appear on the page.
    Wait Until Element Is Visible  //td[text()='${username}']

    # Modify user password via GUI.
    Click Element  //td[text()='${username}']/following-sibling::*/*/*[@title='Edit user']
    Input Text  ${xpath_password_input_button}  ${new_password}
    Input Text  ${xpath_password_confirm_button}  ${new_password}

    # Submit changes.
    Click Element  ${xpath_submit_button}

    # Confirm the successful update.
    Wait Until Element Is Visible  ${xpath_success_message}  timeout=30
    Wait Until Element Is Not Visible  ${xpath_success_message}  timeout=60

    # Verify changes via Redfish.
    ${status}=  Run Keyword And Return Status  Redfish.Login  ${username}  ${new_password}
    Should Be Equal  ${status}  ${True}


*** Keywords ***

Create User And Verify
    [Documentation]  Create a user with given user name and privilege and verify that the
    ...  user is created successfully via GUI and Redfish.
    [Arguments]  ${user_name}  ${user_privilege}  ${enabled}  ${expected_status}=Success

    # Description of argument(s):
    # user_name           The name of the user to be created (e.g. "test", "robert", etc.).
    # user_privilege      Privilege of the user.
    # enabled             If the user is enabled (e.g True if enabled, False if disabled).
    # expected_status     Expected status of user creation (e.g. Success, Failure).

    Click Element  ${xpath_add_user}
    Wait Until Page Contains Element  ${xpath_add_user_heading}

    # Select disabled radio button if user needs to be disabled
    IF  ${enabled} == ${False}
       Click Element At Coordinates  ${xpath_account_status_disabled_button}  0  0
    END

    # Input username, password and privilege.
    Input Text  ${xpath_username_input_button}  ${user_name}
    Select From List by Value  ${xpath_privilege_list_button}  ${user_privilege}

    Input Text  ${xpath_password_input_button}  ${test_user_password}

    Input Text  ${xpath_password_confirm_button}  ${test_user_password}

    # Submit.
    Click Element  ${xpath_submit_button}

    # Proceed with future steps based on the expected execution status.
    IF  '${expected_status}' == 'Success'
        Wait Until Element Is Visible  ${xpath_success_message}  timeout=30

        # Refresh page and check new user is available.
        Wait Until Page Contains Element  ${xpath_add_user}
        Click Element  ${xpath_refresh_button}
        Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
        Wait Until Page Contains  ${user_name}  timeout=15

        # Cross check the privilege of newly added user via Redfish.
        Redfish.Login
        ${user_priv_redfish}=  Redfish_Utils.Get Attribute
        ...  /redfish/v1/AccountService/Accounts/${user_name}  RoleId
        Should Be Equal  ${user_privilege}  ${user_priv_redfish}
        Redfish.Logout

        # Check enable/disable status for user.
        ${status}=  Run Keyword And Return Status  Redfish.Login  ${user_name}  ${test_user_password}
        IF  ${enabled} == ${False}
           Should Be Equal  ${status}  ${False}
        ELSE
           Should Be Equal  ${status}  ${True}
        END
        Redfish.Logout

    ELSE IF   '${expected_status}' == 'Failure'
        Wait Until Element Is Visible  ${xpath_user_creation_error_message}  timeout=60

        # Close error message popup.
        Click Element  ${xpath_close_error_message}
        Wait Until Element Is Not Visible  ${xpath_user_creation_error_message}  timeout=60
    END


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    # Navigate to https://xx.xx.xx.xx/#/access-control/user-management  user management page.

    Click Element  ${xpath_secuity_and_accesss_menu}
    Click Element  ${xpath_user_management_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  user-management
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30


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
      ...  //td[text()='${user}']/following-sibling::*/*/*[@title='Delete user']
      Wait Until Keyword Succeeds  30 sec  5 sec  Click Element  ${xpath_delete_button}
      Wait Until Element Is Visible  ${xpath_success_message}  timeout=30
      Wait Until Element Is Not Visible  ${xpath_success_message}  timeout=60
    END


Suite Teardown Execution
    [Documentation]  Do suite teardown tasks.

    Run Keyword And Ignore Error  Logout GUI
    Close Browser
    Redfish.Logout
