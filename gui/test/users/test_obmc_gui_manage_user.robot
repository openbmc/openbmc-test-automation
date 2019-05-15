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
${xpath_logout_button}                //*[@id="header"]/div[1]/a
${xpath_edit_save_button}             //*[@id="user-accounts"]/form/section/div[7]/button[2]
&{xpath_user_roles}                   Administrator=//*[@id="role"]/option[1]
               ...                    Operator=//*[@id="role"]/option[2]
               ...                    User=//*[@id="role"]/option[3]
               ...                    Callback=//*[@id="role"]/option[4]


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
    [Documentation]  Verify Error When Duplicate User Is Created.
    [Tags]  Verify_Error_When_Duplicate_User_Is_Created

    Delete Non Root Users
    Create New User  user1  Passw0rd1
    Reload Page
    Sleep  2
    Page Should Contain  user1
    Create New User  user1  newUserPwd

Delete User And Verify
    [Documentation]  Delete User And Verify
    [Tags]  Delete_User_And_Verify

    Delete Non Root Users
    Create New User  unknownUser  passw0rd1
    Delete Non Root Users
    Page Should Not Contain  unknownUser

Verify Invalid Password Error
    [Documentation]  Verify the message when user logs in with invalid password
    [Tags]  Verify_Invalid_Password_Error

    Delete Non Root Users
    Create New User  newUser1  newUserPwd
    Reload Page
    Page Should Contain  newUser1
    Click Element  ${xpath_logout_button}
    Sleep  2
    Input Text  ${xpath_textbox_username}  newUser1
    Input Password  ${xpath_textbox_password}  newuserPwd
    Click Element  ${xpath_button_login}
    Page Should Contain  Invalid username or password

Edit And Verify User Property
    [Documentation]  Verify the message when user logs in with invalid password
    [Tags]  Edit_And_Verify_User_Property

    Delete Non Root Users
    Create New User  newUser1  newUserPwd  User
    Reload Page
    Edit User Role  newUser1  newUserPwd  Callback
    ${userRole}=  Get User Attribute Value  newUser1  Role
    Should Be Equal  ${userRole}  Callback

Create And Verify User Without Enabling
    [Documentation]  Create and verify a user without enabling.
    [Tags]  Create_And_Verify_User_Without_Enabling

    Delete Non Root Users
    Create New User  newUser1  newUserPwd  User  False
    Click Element  ${xpath_logout_button}
    Sleep  2
    Input Text  ${xpath_textbox_username}  newUser1
    Input Password  ${xpath_textbox_password}  newUserPwd
    Click Element  ${xpath_button_login}
    Page Should Contain  Invalid username or password

*** Keywords ***

Test Setup Execution
   [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_select_users}
    Wait Until Page Contains Element  ${xpath_select_manage_users}
    Click Element  ${xpath_select_manage_users}
    Wait Until Page Contains  User account information

Create New User
   [Documentation]  Do test case setup tasks.
   [Arguments]  ${userName}  ${password}  ${role}=Administrator  ${enabled}=${True}

   Input Text  ${xpath_input_username}  ${userName}
   Input Password  ${xpath_input_password}  ${password}
   Input Password  ${xpath_input_retype_password}  ${password}
   Click Element  &{xpath_user_roles}[${role}]
   Run Keyword If  '${enabled}' == 'True'  Click Element  ${xpath_input_enabled_checkbox}
   Click Button  ${xpath_create_user_button}
   ${status}=  Run Keyword And Return Status  Page Should Contain  User has been created successfully
   Run Keyword If  '${status}' == 'False'  Run Keywords  Reload Page  AND
              ...  Page Should Contain  ${userName}

Delete Non Root Users
   [Documentation]  Do test case setup tasks.

   Sleep  5
   ${rowNum}=  Set Variable  1
   :FOR  ${num}  IN RANGE  1  99999
   \  ${xpath_user}=  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${rowNum}]/div[1]
   \  ${status}=  Run Keyword And Return Status  Page Should Contain Element  ${xpath_user}
   \  Exit For Loop If  '${status}' == 'False'
   \  ${user}=  Get Text  ${xpath_user}
   \  ${rowNum}  Run Keyword If  '${user}' == 'root' or '${rowNum}' == '2'  Set Variable  2
   \                  ...  ELSE  Set Variable  1
   \  Continue For Loop If  '${user}' == 'root'
   \  ${xpathDeleteUser}=  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${rowNum}]/div[5]/button[2]
   \  Click Button  ${xpathDeleteUser}
   \  Page Should Contain  User has been deleted successfully
   \  Reload Page

Edit User Role
   [Documentation]  Edits the given user.
   [Arguments]  ${userName}  ${passw0rd}  ${newRole}

   :FOR  ${rowNum}  IN RANGE  1  99999
   \  ${xpath_user}=  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${rowNum}]/div[1]
   \  ${status}=  Run Keyword And Return Status  Page Should Contain Element  ${xpath_user}
   \  Exit For Loop If  '${status}' == 'False'
   \  ${xpath_edit_user}=  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${rowNum}]/div[5]/button[1]
   \  ${user}=  Get Text  ${xpath_user}
   \  Run Keyword If  '${user}' == '${userName}'  Run Keywords  Click Element  ${xpath_edit_user}  AND
   \             ...  Input Password  ${xpath_input_password}  ${passw0rd}  AND
   \             ...  Input Password  ${xpath_input_retype_password}  ${passw0rd}  AND
   \             ...  Select From List By Value  ${xpath_input_user_role}  ${newRole}  AND
   \             ...  Click Button  ${xpath_edit_save_button}  AND
   \             ...  Page Should Contain  User has been updated successfully  AND
   \             ...  Exit For Loop

Get User Attribute Value
   [Documentation]  Gets the attribute for the given user.
   [Arguments]  ${userName}  ${attribute}=Role

   :FOR  ${rowNum}  IN RANGE  1  99999
   \  ${xpath_user}=  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${rowNum}]/div[1]
   \  ${status}=  Run Keyword And Return Status  Page Should Contain Element  ${xpath_user}
   \  Exit For Loop If  '${status}' == 'False'
   \  ${xpath_attribute}  Run Keyword If  '${attribute}' == 'Enabled'
   \                                 ...  ...  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${rowNum}]/div[2]
   \                           ...  ELSE  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${rowNum}]/div[3]
   \  ${user}=  Get Text  ${xpath_user}
   \  Run Keyword And Return If  '${user}' == '${userName}'  Get Text  ${xpath_attribute}

