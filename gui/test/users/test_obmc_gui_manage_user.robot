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
&{user_password}                      testUser1=testUserPwd1
            ...                       root=rootPwd1
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
    [Setup]  Run Keywords  Test Setup Execution  AND  Delete Given Users

    Add Or Modify User  root  &{user_password}[root]  action=add_dup

Delete User And Verify
    [Documentation]  Delete user and verify.
    [Tags]  Delete_User_And_Verify
    [Setup]  Run Keywords  Test Setup Execution  AND  Delete Given Users

    Add Or Modify User  testUser1  &{user_password}[testUser1]
    Delete Given Users  delete_user=testUser1
    Page Should Not Contain  testUser1

Verify Invalid Password Error
    [Documentation]  Verify the error message when user logs in with invalid password.
    [Tags]  Verify_Invalid_Password_Error
    [Setup]  Run Keywords  Test Setup Execution  AND  Delete Given Users
    [Teardown]  Login OpenBMC GUI

    Login And Verify Message  root  &{user_password}[root]  Invalid username or password

*** Keywords ***

Test Setup Execution
   [Documentation]  Do test case setup tasks.

    Click Button  ${xpath_select_users}
    Sleep  2s
    Wait Until Page Contains Element  ${xpath_select_manage_users}
    Click Element  ${xpath_select_manage_users}
    Wait Until Page Contains  User account information

Add Or Modify User
   [Documentation]  Creates or edits user.
   [Arguments]  ${username}  ${password}  ${role}=Administrator  ${enabled}=${True}
   ...          ${action}=add
   # Description of argument(s):
   # username  Name of the user to be created.
   # role      Role of the new user.
   # enabled   If True, User is enabled (Default).
   #              False, User is disabled.
   # action    add - Creates a new user.
   #           modify - Edits an existing user.
   #           add_dup - Tries to add a duplicate user and verifies the error message.

   Run Keyword If  '${action}' == 'add' or '${action}' == 'add_dup'
              ...  Input Text  ${xpath_input_username}  ${username}
   Input Password  ${xpath_input_password}  ${password}
   Input Password  ${xpath_input_retype_password}  ${password}
   Log  ${role}
   Select From List By Value  ${xpath_input_user_role}  ${role}
   Run Keyword If  '${enabled}' == 'True'  Click Element  ${xpath_input_enabled_checkbox}
   Run Keyword If  '${action}' == 'modify'
              ...  Click Button  ${xpath_edit_save_button}
        ...  ELSE  Click Button  ${xpath_create_user_button}
   Capture Page Screenshot
   Page Should Contain  &{action_msg_relation}[${action}]

Delete Given Users
   [Documentation]  Deletes users based on the input.
   [Arguments]  ${delete_user}=nonRoot
   # Description of argument(s):
   # delete_user  values - nonRoot/username
   #              If nonRoot - Deletes all non-root users.
   #                 username - Deletes the given user.

   Wait Until Page Does Not Contain  No User exist in system
   Run Keyword If  '${delete_user}' != 'nonRoot'  Page Should Contain  ${delete_user}
   # Row id that gets deleted in every iteration.
   ${deleting_row_id}=  Set Variable  1
   :FOR  ${num}  IN RANGE  1  16
   \    ${xpath_user}=  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${deleting_row_id}]/div[1]
   \    ${status}=  Run Keyword And Return Status  Page Should Contain Element  ${xpath_user}
   \    Exit For Loop If  '${status}' == 'False'
   \    ${user}=  Get Text  ${xpath_user}
   \    ${deleting_row_id}  Run Keyword If  '${user}' == 'root' or '${deleting_row_id}' == '2'  Set Variable  2
   \    ...  ELSE  Set Variable  1
   \    Continue For Loop If  '${user}' == 'root'
   \    ${xpath_delete_user}  Run Keyword If  '${user}' == '${delete_user}' or '${delete_user}' == 'nonRoot'
   \    ...  Set Variable  //*[@id="user-accounts"]/div[4]/div[2]/div[${deleting_row_id}]/div[5]/button[2]
   \    Run Keyword If  '${user}' == '${delete_user}' or '${delete_user}' == 'nonRoot'
   \    ...  Run Keywords  Click Button  ${xpath_delete_user}
   \    ...  AND  Page Should Contain  User has been deleted successfully
   \    ...  AND  Reload Page
   \    ...  AND  Exit For Loop If  '${user}' == '${delete_user}'

Login And Verify Message
   [Documentation]  Verifies the error message displayed on screen while logging in.
   [Arguments]  ${username}  ${password}  ${msg}

    LogOut OpenBMC GUI
    Input Text  ${xpath_textbox_username}  ${username}
    Input Password  ${xpath_textbox_password}  ${password}
    Click Element  ${xpath_button_login}
    Page Should Contain  ${msg}