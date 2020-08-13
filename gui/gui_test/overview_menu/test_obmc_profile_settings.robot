*** Settings ***

Documentation   Test OpenBMC GUI "Profile setting" menu.

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_profile_setting}   //a[@href='#/profile-settings']
${xpath_new_password}      //input[@id="password"]
${xpath_confirm_password}  //input[@id="password-confirmation"]

*** Test Cases ***

Verify navigation to Profile Settings page
    [Documentation]  Verify navigation to profile settings page
    [Tags]  Verify_Navigation_To_Profile_Settings_page

    Page Should Contain  Profile settings   


Verify Existence Of All Sections In Profile Settings Page
    [Documentation]  Verify Existence Of All Sections In Profile Settings page
    [Tags]  Verify_Existence_Of_All_Sections_In_Profile_Settings_Page

    Page Should Contain  Profile information
    Page Should Contain  Change password
    Page Should Contain  Timezone display preference


Verify Existence Of All Buttons And Input Boxes In Profile Settings Page
    [Documentation]  Verify Existence Of All Buttons And Input Boxes In Profile Settings Page
    [Tags]  Verify_Existence_Of_All_Buttons_And_Input_Boxes_In_Profile_Settings_Page

    # Input Boxes in profile settings page
    Page Should Contain Element  ${xpath_new_password}
    Input Text  ${xpath_new_password}  xxxxxxxx
    Page Should Contain Element  ${xpath_confirm_password}
    Input Text  ${xpath_confirm_password}  xxxxxxxx

    # Buttons in profile settings page
    Page Should Contain Element  ${xpath_save_settings_button}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    # Navigate to https://xx.xx.xx.xx/#/profile-settings  profile-settings page.
    
    Click Element  ${xpath_overview_menu}
    Wait Until Page Contains Element  ${xpath_root_button_menu}
    Click Element  ${xpath_root_button_menu}
    Click Element  ${xpath_profile_setting}
    Sleep  5s
