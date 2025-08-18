*** Settings ***

Documentation   Test OpenBMC GUI "Profile settings" menu.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/bmc_redfish_utils.robot
Variables       ../../data/gui_p10_variables.py

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution

Test Tags      Profile_Settings_Sub_Menu

*** Variables ***

${xpath_new_password}                  //*[@data-test-id='profileSettings-input-newPassword']
${xpath_confirm_password}              //*[@data-test-id='profileSettings-input-confirmPassword']
${xpath_logged_usename}                //*[@data-test-id='appHeader-container-user']
${xpath_default_UTC}                   //*[@data-test-id='profileSettings-radio-defaultUTC']
${xpath_profile_settings_save_button}  //*[@data-test-id='profileSettings-button-saveSettings']
${xpath_browser_offset}                //*[@data-test-id='profileSettings-radio-browserOffset']

*** Test Cases ***

Verify Navigation To Profile Settings Page
    [Documentation]  Verify navigation to profile settings page.
    [Tags]  Verify_Navigation_To_Profile_Settings_Page

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


Verify Default UTC Timezone Display
    [Documentation]  Set default UTC timezone via GUI and verify timezone value in overview page.
    [Tags]  Verify_Default_UTC_Timezone_Display

    Click Element At Coordinates    ${xpath_default_UTC}    0    0
    Click Element  ${xpath_profile_settings_save_button}

    # Navigate to the overview page.

    Click Element  ${xpath_overview_menu}
    Wait Until Page Contains  Overview  timeout=30s

    ${cli_date_time}=  CLI Get BMC DateTime

    # Fetching hour and minute from BMC CLI to handle seconds difference during execution.

    ${cli_hour_and_min}=  Convert Date  ${cli_date_time}  result_format=%H:%M
    Page Should Contain  ${cli_hour_and_min}


Verify Profile Setting Menu With Readonly User
    [Documentation]  Verify all buttons,sections and radio buttons with
    ...              Readonly user in Profile setting menu.
    [Tags]  Verify_Profile_Setting_Menu_With_Readonly_User

    # Perform Readonly user creation and Login GUI with Readonly user,
    # Readonly user have access to change self password,
    # So expecting success messages on this page.
    Redfish Create User  readonly_user  ${OPENBMC_PASSWORD}  ReadOnly  ${True}
    Launch Browser And Login GUI With Given User  readonly_user  ${OPENBMC_PASSWORD}
    Maximize Browser Window
    Test Setup Execution

    # Now input  username and password value and submit.
    Input Text  ${xpath_new_password}  ${OPENBMC_PASSWORD}
    Input Text  ${xpath_confirm_password}  ${OPENBMC_PASSWORD}

    Click Element At Coordinates    ${xpath_default_UTC}    0    0
    Click Element  ${xpath_profile_settings_save_button}
    Wait Until Element Is Visible   ${xpath_success_message}  timeout=30
    Page Should Contain Element   ${xpath_success_message}

    Click Element At Coordinates  ${xpath_browser_offset}  0   0
    Click Element  ${xpath_profile_settings_save_button}
    Wait Until Element Is Visible   ${xpath_success_message}  timeout=30
    Page Should Contain Element   ${xpath_success_message}


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
