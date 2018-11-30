*** Settings ***

Documentation  Test OpenBMC GUI "Manage user account" sub-menu  of
...  "Users".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution

*** Variables ***
${xpath_select_users}  //*[@id="nav__top-level"]/li[5]/button/span[1]
${xpath_select_manage_users}  //a[@href='#/users/manage-accounts']
${xpath_current_password}  //*[@id="user-manage__current-password"]
${xpath_new_password}  //*[@id="user-manage__new-password"]
${xpath_retype_new_password}  //*[@id="user-manage__verify-password"]
${xpath_save_button}  //*[@id="user-accounts"]/section/form/div/button

*** Test Cases ***
Verify Select Manage Users Account From Users
    [Documentation]  Verify ability to select "Manage Users Account" sub-menu
    ...  option of "Users".
    [Tags]  Verify_Select_Manage_Users_Account_From_Users

    Wait Until Page Contains  Manage user account
    Page should contain  Change password


Verify Existence Of All Password Input Boxes
    [Documentation]  Verify all password input boxes exists.
    [Tags]  Verify_Existence_Of_All_Password_Input_Boxes

    Page Should Contain Element  ${xpath_current_password}
    Page Should Contain Element  ${xpath_new_password}
    Page Should Contain Element  ${xpath_retype_new_password}


Verify Existence Of Save Button
    [Documentation]  Verify save button exists.
    [Tags]  Verify_Existence_Of_Save_Button

    Page Should Contain Element  ${xpath_save_button}

*** Keywords ***

Test Setup Execution
   [Documentation]  Do test case setup tasks.

    Page Should Contain Element  ${xpath_select_users}
    Focus  ${xpath_select_users}
    Click Element  ${xpath_select_users}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_manage_users}

