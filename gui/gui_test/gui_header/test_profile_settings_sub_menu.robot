*** Settings ***

Documentation   Test OpenBMC GUI "Profile settings" menu.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/bmc_redfish_utils.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close All Browsers
Test Setup      Test Setup Execution

Test Tags      Profile_Settings_Sub_Menu

*** Variables ***

${xpath_new_password}                  //*[@data-test-id='profileSettings-input-newPassword']
${xpath_confirm_password}              //*[@data-test-id='profileSettings-input-confirmPassword']
${xpath_logged_usename}                //*[@data-test-id='appHeader-container-user']

*** Test Cases ***

Verify Navigation To Profile Settings Page
    [Documentation]  Verify navigation to profile settings page.
    [Tags]  Verify_Navigation_To_Profile_Settings_Page
    [Teardown]  Logout GUI

   Page Should Contain  Profile settings


Verify Existence Of All Sections In Profile Settings Page
    [Documentation]  Verify existence of all sections in profile settings page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Profile_Settings_Page
    [Setup]  Run Keywords  Login GUI  admin  ${OPENBMC_PASSWORD}  AND  Test Setup Execution
    [Teardown]  Logout GUI

    Page Should Contain  Profile information
    Page Should Contain  Change password
    Page Should Contain  Timezone display preference


Verify Existence Of All Buttons And Input Boxes In Profile Settings Page
    [Documentation]  Verify existence of all buttons and input boxes in profile settings page.
    [Tags]  Verify_Existence_Of_All_Buttons_And_Input_Boxes_In_Profile_Settings_Page
    [Setup]  Run Keywords  Login GUI  admin  ${OPENBMC_PASSWORD}  AND  Test Setup Execution
    [Teardown]  Logout GUI

    # Input Boxes in profile settings page.
    Page Should Contain Element  ${xpath_new_password}
    Page Should Contain Element  ${xpath_confirm_password}

    # Buttons in profile settings page.
    Page Should Contain Element  ${xpath_save_settings_button}


Verify Logged In Username
    [Documentation]  Verify logged in username in profile settings page.
    [Tags]  Verify_Logged_In_Username
    [Setup]  Launch Browser And Login GUI

    Wait Until Page Contains Element  ${xpath_logged_usename}
    ${gui_logged_username}=  Get Text  ${xpath_logged_usename}
    Should Contain  ${gui_logged_username}  ${OPENBMC_USERNAME}


Verify Default UTC Timezone Display
    [Documentation]  Set default UTC timezone via GUI and verify timezone value in overview page.
    [Tags]  Verify_Default_UTC_Timezone_Display
    [Teardown]  Logout GUI

    Verify Timezone Display On Overview Page  ${xpath_default_UTC}


Verify Profile Setting Menu With Readonly User
    [Documentation]  Verify All Buttons,sections and radio buttons with
    ...              Readonly user in Profile setting menu.
    [Tags]  Verify_Profile_Setting_Menu_With_Readonly_User
    [Setup]  Run Keywords  Create Readonly User And Login To GUI  AND  Test Setup Execution
    [Teardown]  Delete Readonly User And Logout Current GUI Session

    # Input username and password value and submit.
    Input Text  ${xpath_new_password}  ${OPENBMC_PASSWORD}
    Input Text  ${xpath_confirm_password}  ${OPENBMC_PASSWORD}
    Click Element At Coordinates    ${xpath_default_UTC}    0    0
    Click Element  ${xpath_save_settings_button}

    # Readonly user have access to change self password,
    # So expecting success messages on this page.
    Verify Success Message On BMC GUI Page
    Click Element At Coordinates  ${xpath_browser_offset}  0   0
    Click Element  ${xpath_save_settings_button}
    Verify Success Message On BMC GUI Page


Verify Browser Offset Timezone Display
    [Documentation]  Set browser offset timezone display via GUI and verify timezone value in overview page.
    [Tags]  Verify_Browser_Offset_Timezone_Display
    [Teardown]  Logout GUI

    Verify Timezone Display On Overview Page  ${xpath_browser_offset}  -5 hours


Verify Admin User Password Update In Profile Settings Page
    [Documentation]  Verify admin user can update password in profile settings page.
    [Tags]  Verify_Admin_User_Password_Update_In_Profile_Settings_Page
    [Setup]  Run Keywords  Create Admin User And Login To GUI   testadmin  Newpass123
    ...  AND  Test Setup Execution
    [Teardown]  Delete Admin User And Logout Current GUI Session  testadmin

    # Input new password value and submit.
    Input Text  ${xpath_new_password}  ${OPENBMC_PASSWORD}
    Input Text  ${xpath_confirm_password}  ${OPENBMC_PASSWORD}
    Click Element  ${xpath_save_settings_button}
    Verify Success Message On BMC GUI Page

    # Login GUI with new password.
    Login GUI  testadmin  ${OPENBMC_PASSWORD}
    Wait Until Page Contains Element  ${xpath_logged_usename}  timeout=30s


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    # Navigate to https://xx.xx.xx.xx/#/profile-settings  profile-settings page.

    Wait Until Page Contains Element  ${xpath_root_button_menu}
    Click Element  ${xpath_root_button_menu}
    Wait Until Page Contains Element  ${xpath_profile_settings}
    Click Element  ${xpath_profile_settings}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  profile-settings
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30


Verify Timezone Display On Overview Page
    [Documentation]  Set timezone display and verify time on overview page.
    [Arguments]  ${timezone_xpath}  ${time_offset}=0 hours

    Click Element At Coordinates  ${timezone_xpath}  0  0
    Click Element  ${xpath_save_settings_button}
    Verify Success Message On BMC GUI Page

    Click Element  ${xpath_overview_menu}
    Wait Until Page Contains  Overview  timeout=30s

    # Fetch current BMC date and time from CLI.
    ${cli_date_time}=  CLI Get BMC DateTime

    # Adjust CLI time according to browser offset.
    ${adjusted_time}=  Add Time To Date  ${cli_date_time}  ${time_offset}
    ${cli_hour_min}=  Convert Date  ${adjusted_time}  result_format=%H:%M
    Page Should Contain  ${cli_hour_min}


Create Admin User And Login To GUI
    [Documentation]   Created admin user with administrator privilege via Redfish and Login BMC GUI.
    [Arguments]  ${username}  ${password}

    # Created testadmin via redfish and login BMC GUI.
    Redfish.Login
    Redfish Create User  ${username}  ${password}  Administrator  ${True}
    Login GUI  ${username}  ${password}


Delete Admin User And Logout Current GUI Session
    [Documentation]  Logout current GUI session and delete testadmin user.
    [Arguments]  ${username}

    # Delete testadmin user and Logout current GUI session.
    Logout GUI
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${username}
    Close Browser

    # Login BMC GUI with default user.
    Launch Browser And Login GUI
