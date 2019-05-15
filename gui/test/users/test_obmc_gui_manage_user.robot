*** Settings ***

Documentation  Test OpenBMC GUI "Manage user account" sub-menu  of
...            "Users".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_input_username}               //input[@name='UserName']
${xpath_input_password}               //input[@name='Password']
${xpath_input_retype_password}        //input[@name='VerifyPassword']
${xpath_input_user_role}              //select[@id='role']
${xpath_input_enabled_checkbox}       //label[@for="user-manage__enabled"]
${xpath_input_lockout_time}           //input[@id='lockoutTime']
${xpath_input_failed_login_attempts}  //input[@id='lockoutThreshold']
${xpath_select_manage_users}          //a[contains(text(), "Manage user account")]
${xpath_select_users}                 //button[contains(@class, "users")]
${xpath_save_setting_button}          //button[text() ="Save settings"]
${xpath_create_user_button}           //button[text() ="Create user"]
${xpath_edit_button}                  //button[text() ="Edit"]
${xpath_delete_button}                //button[text() ="Delete"]
${label}                              //label[@class="control-check"]
${xpath_edit_save_button}             //*[@id="user-accounts"]/form/section/div[7]/button[2]
&{action_msg_relation}                add=User has been created successfully
                  ...                 modify=User has been updated successfully
                  ...                 add_dup=Username exists



*** Test Cases ***

Verify Existence Of All Section In User Page
    [Documentation]  Verify existence of all sections in user page..
    [Tags]  Verify_Existence_Of_All_Section_In_User_Page

    Page should contain  User account properties
    Page should contain  User account information
    Page should contain  User account settings


Verify Existence Of All Input Boxes In User Page
    [Documentation]  Verify existence of all input boxes in user page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_User_Page

    # Input boxes under user account settings
    Page Should Contain Element  ${xpath_input_username}
    Page Should Contain Element  ${xpath_input_password}
    Page Should Contain Element  ${xpath_input_retype_password}
    Page Should Contain Element  ${xpath_input_user_role}
    Page Should Contain Element  ${xpath_input_enabled_checkbox}

    # Input boxes under user account properties
    Page Should Contain Element  ${xpath_input_lockout_time}
    Page Should Contain Element  ${xpath_input_failed_login_attempts}


Verify Existence Of All Button In User Page
    [Documentation]  Verify existence of all botton in user page.
    [Tags]  Verify_Existence_Of_All_Button_In_User_Page

    # Buttons under user account properties
    Page Should Contain Element  ${xpath_save_setting_button}

    # Buttons under user account settings
    Page Should Contain Element  ${xpath_create_user_button}

    # Buttons under user account properties
    Page Should Contain Element  ${xpath_edit_button}
    Page Should Contain Element  ${xpath_delete_button}

Verify Error When Duplicate User Is Created
    [Documentation]  Verify error when duplicate user is created.
    [Tags]  Verify_Error_When_Duplicate_User_Is_Created
    [Setup]  Run Keywords  Test Setup Execution  AND  Delete Non Root Users

    Add Or Modify User  user1  Passw0rd1
    Reload Page
    Wait Until Page Contains  user1
    Add Or Modify User  user1  newUserPwd  action=add_dup

Delete User And Verify
    [Documentation]  Delete user and verify.
    [Tags]  Delete_User_And_Verify
    [Setup]  Run Keywords  Test Setup Execution  AND  Delete Non Root Users

    Add Or Modify User  unknownUser  passw0rd1
    Delete Non Root Users
    Page Should Not Contain  unknownUser

Verify Invalid Password Error
    [Documentation]  Verify the error message when user logs in with invalid password.
    [Tags]  Verify_Invalid_Password_Error
    [Setup]  Run Keywords  Test Setup Execution  AND  Delete Non Root Users

    Add Or Modify User  newUser1  newUserPwd
    Reload Page
    Wait Until Page Contains  newUser1
    Click Element  ${xpath_button_logout}
    Input Text  ${xpath_textbox_username}  newUser1
    Input Password  ${xpath_textbox_password}  newuserPwd
    Click Element  ${xpath_button_login}
    Page Should Contain  Invalid username or password
    Login OpenBMC GUI

Edit And Verify User Property
    [Documentation]  Edits and verifies the user property.
    [Tags]  Edit_And_Verify_User_Property
    [Setup]  Run Keywords  Test Setup Execution  AND  Delete Non Root Users

    Add Or Modify User  newUser1  newUserPwd  User
    Reload Page
    Edit User Role  newUser1  newUserPwd  Callback
    ${userRole}=  Get User Attribute Value  newUser1  Role
    Should Be Equal  ${userRole}  Callback

Create And Verify User Without Enabling
    [Documentation]  Create and verify a user without enabling.
    [Tags]  Create_And_Verify_User_Without_Enabling
    [Setup]  Run Keywords  Test Setup Execution  AND  Delete Non Root Users

    Add Or Modify User  newUser1  newUserPwd  User  False
    Click Element  ${xpath_button_logout}
    Input Text  ${xpath_textbox_username}  newUser1
    Input Password  ${xpath_textbox_password}  newUserPwd
    Click Element  ${xpath_button_login}
    Page Should Contain  Invalid username or password

*** Keywords ***

Test Setup Execution
   [Documentation]  Do test case setup tasks.

    Click Button  ${xpath_select_users}
    Wait Until Page Contains Element  ${xpath_select_manage_users}  timeout=180
    Click Element  ${xpath_select_manage_users}
    Wait Until Page Contains  User account information  timeout=180

Add Or Modify User
   [Documentation]  Creates or edits user.
   [Arguments]  ${userName}  ${password}  ${role}=Administrator  ${enabled}=${True}
   ...          ${action}=add
   # Description of argument(s):
   # userName  Name of the user to be created.
   # role      Role of the new user.
   # enabled   If True, User is enabled when True (Default)
   #              False, User is disabled
   # action    add - Creates a new user.
   #           modify - Edits a existing user.
   #           add_dup - Tries to add a duplicate user and verifies the error message.

   Run Keyword If  '${action}' == 'add' or '${action}' == 'add_dup'
              ...  Input Text  ${xpath_input_username}  ${userName}
   Input Password  ${xpath_input_password}  ${password}
   Input Password  ${xpath_input_retype_password}  ${password}
   Select From List By Value  ${xpath_input_user_role}  ${role}
   Run Keyword If  '${enabled}' == 'True'  Click Element  ${xpath_input_enabled_checkbox}
   Run Keyword If  '${action}' == 'modify'
                   ...  Click Button  ${xpath_edit_save_button}
        ...  ELSE  Click Button  ${xpath_create_user_button}
   Capture Page Screenshot
   Page Should Contain  &{action_msg_relation}[${action}]

Delete Non Root Users
   [Documentation]  Do test case setup tasks.

   Wait Until Page Does Not Contain  No User exist in system
   ${rowNum}=  Set Variable  1
   :FOR  ${num}  IN RANGE  1  16
   \  ${xpath_user}=  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${rowNum}]/div[1]
   \  ${status}=  Run Keyword And Return Status  Page Should Contain Element  ${xpath_user}
   \  Exit For Loop If  '${status}' == 'False'
   \  ${user}=  Get Text  ${xpath_user}
   \  ${rowNum}  Run Keyword If  '${user}' == 'root' or '${rowNum}' == '2'  Set Variable  2
   \                  ...  ELSE  Set Variable  1
   \  Continue For Loop If  '${user}' == 'root'
   \  ${xpath_delete_user}=  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${rowNum}]/div[5]/button[2]
   \  Click Button  ${xpath_delete_user}
   \  Page Should Contain  User has been deleted successfully
   \  Reload Page

Edit User Role
   [Documentation]  Edits the given user.
   [Arguments]  ${userName}  ${passw0rd}  ${newRole}

   :FOR  ${rowNum}  IN RANGE  1  16
   \  ${xpath_user}=  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${rowNum}]/div[1]
   \  ${status}=  Run Keyword And Return Status  Page Should Contain Element  ${xpath_user}
   \  Exit For Loop If  '${status}' == 'False'
   \  ${xpath_edit_user}=  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${rowNum}]/div[5]/button[1]
   \  ${user}=  Get Text  ${xpath_user}
   \  Run Keyword If  '${user}' == '${userName}'  Run Keywords  Click Element  ${xpath_edit_user}  AND
   \             ...  Add Or Modify user  ${userName}  ${passw0rd}  ${newRole}  action=modify  AND
   \             ...  Exit For Loop

Get User Attribute Value
   [Documentation]  Gets the attribute for the given user.
   [Arguments]  ${userName}  ${attribute}=Role

   :FOR  ${rowNum}  IN RANGE  1  16
   \  ${xpath_user}=  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${rowNum}]/div[1]
   \  ${status}=  Run Keyword And Return Status  Page Should Contain Element  ${xpath_user}
   \  Exit For Loop If  '${status}' == 'False'
   \  ${xpath_attribute}  Run Keyword If  '${attribute}' == 'Enabled'
   \                                 ...  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${rowNum}]/div[2]
   \                           ...  ELSE  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${rowNum}]/div[3]
   \  ${user}=  Get Text  ${xpath_user}
   \  Run Keyword And Return If  '${user}' == '${userName}'  Get Text  ${xpath_attribute}

