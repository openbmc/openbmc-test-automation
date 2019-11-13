*** Settings ***

Documentation  Test OpenBMC GUI "Local users" sub-menu of "Access control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution
Force Tags      Manage_User

*** Variables ***

${xpath_select_user}              //input[contains(@class,"bmc-table__checkbox-input")]
${xpath_edit_user}                //button[@aria-label="Edit"]
${xpath_delete_user}              //button[@aria-label="Delete"]
${xpath_account_policy}           //button[text()[contains(.,"Account policy settings")]]
${xpath_add_user}                 //button[text()[contains(.,"Add user")]]
${xpath_enable_user}              //label[text()[contains(.,"Enabled")]]
${xpath_disable_user}             //label[text()[contains(.,"Disabled")]]
${xpath_input_user}               //input[@id="username"]
${xpath_select_privilege}         //select[@id="privilege"]
${xpath_input_password}           //input[@id="password"]
${xpath_confirm_password}         //input[@id="passwordConfirm"]
${xpath_remove_button}            //button[text()[contains(.,"Remove")]]

*** Test Cases ***

Verify Existence Of All Sections In Local User Management Page
    [Documentation]  Verify existence of all sections in local user management page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Local_User_Management_Page

    Page should contain  View privilege role descriptions


Verify Existence Of All Buttons In Local User Management Page
    [Documentation]  Verify existence of all buttons in local user management page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Local_User_Management_Page

    Page should contain Button  ${xpath_account_policy}
    Page should contain Button  ${xpath_add_user}
    Page Should Contain Button  ${xpath_edit_user}
    Page Should Contain Button  ${xpath_delete_user}


Verify Existence Of All Input Boxes In Local User Management Page
    [Documentation]  Verify existence of all input boxes in local user management page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_Local_User_Management_Page

    Page Should Contain Checkbox  ${xpath_select_user}


Add User And Verify
    [Documentation]  Add user and verify.
    [Tags]  Add_User_And_Verify

    # Confirm same user does not exist.
    Delete User  testUser1
    Add User  testUser1  testUserPwd1  Administrator
    Test Login  testUser1  testUserPwd1


Delete User And Verify
    [Documentation]  Delete user and verify.
    [Tags]  Delete_User_And_Verify

    # Confirm same user does not exist.
    Delete User  testUser2
    Add User  testUser2  testUserPwd2  Callback
    Delete User  testUser2
    Click Element  ${xpath_select_refresh_button}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Not Contain  testUser2
    Test Login  testUser2  testUserPwd2  ${False}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_access_control}
    Click Element  ${xpath_select_local_users}
    Wait Until Page Contains  Local user management

Add User
   [Documentation]  Create user.
   [Arguments]  ${username}  ${password}  ${privilege}=Administrator
   ...  ${account_status}=Enabled

   # Description of argument(s):
   # username   Name of the user to be created.
   # password   New user password.
   # privilege  User privilege.
   # account_status  Enable or disable new user.

   Click Element  ${xpath_add_user}
   Add User Details  ${username}  ${password}  ${privilege}  ${account_status}

Add User Details
   [Documentation]  Add new user details.
   [Arguments]  ${username}  ${password}  ${privilege}  ${account_status}

   # Description of argument(s):
   # username   User name.
   # password   User password.
   # privilege  User privilege.
   # account_status  Enable or disable user.

   Run Keyword If  '${account_status}' == 'Enabled'
   ...  Click Element  ${xpath_enable_user}
   ...  ELSE  Click Element  ${xpath_disable_user}
   Input Text  ${xpath_input_user}  ${username}
   Input Password  ${xpath_input_password}  ${password}
   Input Password  ${xpath_confirm_password}  ${password}
   Select User Privilege  ${privilege}
   Click Element  ${xpath_add_user}

Select User Privilege
   [Documentation]  Select user privilege.
   [Arguments]  ${privilege}=Administrator

   # Description of argument(s):
   # privilege  User privilege.

   Click Element  ${xpath_select_privilege}
   Click Element  //option[text()[contains(.,"${privilege}")]]

Delete User
   [Documentation]  Delete user.
   [Arguments]  ${username}

   # Description of argument(s):
   # username   Name of the user to be created.

   ${result}=  Run Keyword And Return Status  Page Should Contain  ${username}
   Run Keyword If  '${result}' == '${True}'
   ...  Run Keywords  Click Element  //*[text()="${username}"]//following::td[3]//button[@aria-label="Delete"]
   ...  AND  Click Element  ${xpath_remove_button}
   ...  ELSE  Log  User does not exist

Test Login
   [Documentation]  Try to login to Openbmc.
   [Arguments]  ${username}  ${password}  ${expected_result}=${True}

   # Description of argument(s):
   # username   Username.
   # password   User password.
   # expected_result  Result of the test.

    Open Browser  ${obmc_gui_url}  alias=2
    Switch Browser  2
    ${status}=  Run Keyword And Return Status  Login OpenBMC GUI  ${username}  ${password}
    Should Be Equal  ${status}  ${expected_result}  Login expectation was not met
    Run Keyword If  '${status}' == '${True}'
    ...  LogOut OpenBMC GUI
    ...  ELSE  Page Should Contain  Invalid username or password
    Close Browser
    Switch Browser  1

