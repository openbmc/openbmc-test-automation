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
${xpath_input_user_role}              //select[@id='user-manage__role']
${xpath_input_enabled_checkbox}       //input[@name='Enabled']
${xpath_input_lockout_time}           //input[@id='lockoutTime']
${xpath_input_failed_login_attempts}  //input[@id='lockoutThreshold']
${xpath_select_manage_users}          //a[contains(text(), "Manage user account")]
${xpath_select_users}                 //button[contains(@class, "users")]
${xpath_save_setting_button}          //button[text() ="Save settings"]
${xpath_create_user_button}           //button[text() ="Create User"]
${xpath_edit_button}                  //button[text() ="Edit"]
${xpath_delete_button}                //button[text() ="Delete"]


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
    [Documentation]  Verify existence of all button in user page.
    [Tags]  Verify_Existence_Of_All_Button_In_User_Page

    # Buttons under user account properties
    Page Should Contain Element  ${xpath_save_setting_button}

    # Buttons under user account settings
    Page Should Contain Element  ${xpath_create_user_button}

    # Buttons under user account properties
    Page Should Contain Element  ${xpath_edit_button}
    Page Should Contain Element  ${xpath_delete_button}


*** Keywords ***

Test Setup Execution
   [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_select_users}
    Wait Until Page Contains Element  ${xpath_select_manage_users}
    Click Element  ${xpath_select_manage_users}
    Wait Until Page Contains  User account information

