*** Settings ***

Documentation   Test OpenBMC GUI "Profile settings" menu.

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_new_password}      //input[@id="password"]
${xpath_confirm_password}  //input[@id="password-confirmation"]
${xpath_logged_usename}    //*[@data-test-id='appHeader-container-user']

*** Test Cases ***

Verify Navigation To Profile Settings Page
    [Documentation]  Verify navigation to profile settings page.
    [Tags]  Verify_Navigation_To_Profile_Settings_page

    Page Should Contain  Profile settings


Verify Existence Of All Sections In Profile Settings Page
    [Documentation]  Verify existence of all sections in profile settings page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Profile_Settings_Page

    Page Should Contain  Profile information
    Page Should Contain  Change password
    Page Should Contain  Timezone display preference


Verify Existence Of All Buttons And Input Boxes In Profile Settings Page
    [Documentation]  Verify existence of all buttons and input boxes in profile settings page.
    [Tags]  Verify_Existence_Of_All_Buttons_And_Input_Boxes_In_Profile_Settings_Page

    # Input Boxes in profile settings page.
    Page Should Contain Element  ${xpath_new_password}
    Page Should Contain Element  ${xpath_confirm_password}

    # Buttons in profile settings page.
    Page Should Contain Element  ${xpath_save_settings_button}


Verify Logged In Username
    [Documentation]  Verify logged in username in profile settings page.
    [Tags]  Verify_Logged_In_Username

    Wait Until Page Contains Element  ${xpath_logged_usename}
    ${gui_logged_username}=  Get Text  ${xpath_logged_usename}
    Should Contain  ${gui_logged_username}  ${OPENBMC_USERNAME}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    # Navigate to https://xx.xx.xx.xx/#/profile-settings  profile-settings page.

    Wait Until Page Contains Element  ${xpath_root_button_menu}
    Click Element  ${xpath_root_button_menu}
    Click Element  ${xpath_profile_settings}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  profile-settings
