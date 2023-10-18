*** Settings ***

Documentation   Test OpenBMC GUI "Date and time" sub-menu of "Settings".

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Suite Teardown Execution
Test Setup      Navigate To Date and Time Page

Force Tags      Date_And_Time_Sub_Menu

*** Variables ***

${xpath_date_time_heading}       //h1[text()="Date and time"]
${xpath_select_manual}           //*[@data-test-id="dateTime-radio-configureManual"]
${xpath_select_ntp}              //*[@data-test-id="dateTime-radio-configureNTP"]
${xpath_manual_date}             //input[@data-test-id="dateTime-input-manualDate"]
${xpath_manual_time}             //input[@data-test-id="dateTime-input-manualTime"]
${xpath_ntp_server1}             //input[@data-test-id="dateTime-input-ntpServer1"]
${xpath_ntp_server2}             //input[@data-test-id="dateTime-input-ntpServer2"]
${xpath_ntp_server3}             //input[@data-test-id="dateTime-input-ntpServer3"]
${xpath_select_save_settings}    //button[@data-test-id="dateTime-button-saveSettings"]
${xpath_invalid_format_message}  //*[contains(text(), "Invalid format")]
${LOOP_COUNT}                    2

*** Test Cases ***

Verify Navigation To Date And Time Page
    [Documentation]  Verify navigation to date and time page.
    [Tags]  Verify_Navigation_To_Date_And_Time_Page

    Page Should Contain Element  ${xpath_date_time_heading}


Verify Text Under Date And Time Page
    [Documentation]  Verify the presence of the required text on the date and time page.
    [Tags]  Verify_Text_Under_Date_And_Time_Page


    Page Should Contain  To change how date and time are displayed
    ...  (either UTC or browser offset) throughout the application, visit Profile Settings

    Page Should Contain  If NTP is selected but an NTP server is not given or the
    ...  given NTP server is not reachable, then time.google.com will be used.


Verify Existence Of All Sections In Date And Time Page
    [Documentation]  Verify existence of all sections in date and time page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Date_And_Time_Page

    Page Should Contain  Configure settings


Verify Existence Of All Buttons In Date And Time Page
    [Documentation]  Verify existence of all buttons in date and time settings page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Date_And_Time_Page

    Page Should Contain Element  ${xpath_select_manual}
    Page Should Contain Element  ${xpath_select_ntp}
    Page Should Contain Element  ${xpath_select_save_settings}


Verify Existence Of All Input Boxes In Date And Time Page
    [Documentation]  Verify existence of all input boxes in date time page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_Date_And_Time_Page

    Click Element At Coordinates  ${xpath_select_manual}  0  0
    Page Should Contain Element  ${xpath_manual_date}
    Page Should Contain Element  ${xpath_manual_time}

    Click Element At Coordinates  ${xpath_select_ntp}  0  0
    Page Should Contain Element  ${xpath_ntp_server1}
    Page Should Contain Element  ${xpath_ntp_server2}
    Page Should Contain Element  ${xpath_ntp_server3}


Verify Date And Time From Configuration Section
    [Documentation]  Get date and time from configuration section and verify it via BMC CLI.
    [Tags]  Verify_Date_And_Time_From_Configuration_Section

    Click Element At Coordinates  ${xpath_select_manual}  0  0
    ${manual_date}=  Get Value  ${xpath_manual_date}
    ${manual_time}=  Get Value  ${xpath_manual_time}

    ${cli_date_time}=  CLI Get BMC DateTime
    Should contain  ${cli_date_time}  ${manual_date}  ${manual_time}


Verify Display Of Date And Time In GUI Page
     [Documentation]  Get date and time from Redfish and verify it via GUI date and time page.
     [Tags]  Verify_Display_Of_Date_And_Time_In_GUI_Page

    # Set Default timezone in profile settings page.
    Set Timezone In Profile Settings Page  Default
    Navigate To Date and Time Page

    # Get date and time from Redfish.
    ${redfish_date_time}=  CLI Get BMC DateTime
    ${redfish_date}=  Convert Date  ${redfish_date_time}  result_format=%Y-%m-%d
    ${redfish_time}=  Convert Date  ${redfish_date_time}  result_format=%H:%M

    # Verify date and time via GUI date and time page.

    Page Should Contain  ${redfish_date}
    Page Should Contain  ${redfish_time}


Verify Profile Setting Button In Date And Time Page
    [Documentation]  Verify navigation to profile setting page after clicking
    ...  on profile setting button in date and time page.
    [Tags]  Verify_Profile_Setting_Button_In_Date_And_Time_Page

    Click Element   ${xpath_profile_settings_link}
    Wait Until Page Contains Element  ${xpath_profile_settings_heading}  timeout=10
    Location Should Contain   profile-settings


Verify Existence Of Timezone Buttons In Profile Settings Page
    [Documentation]  Verify default UTC button and browser offset IST button
    ...  in Profile settings page
    [Tags]  Verify_Existence_Of_Timezone_Buttons_In_Profile_Settings_Page

    Click Element   ${xpath_profile_settings_link}
    Wait Until Page Contains Element  ${xpath_profile_settings_heading}  timeout=30
    Page Should Contain Element  ${xpath_default_UTC}
    Page Should Contain Element  ${xpath_browser_offset}


Verify Date And Time Change To Browser Offset Time
    [Documentation]  Verify date and time change to broswer's offset time when
    ...  'Browser offset' option is selected in Profile settings page.
    [Tags]   Verify_Date_And_Time_Change_To_Browser_Offset_Time

    Click Element   ${xpath_profile_settings_link}
    Wait Until Page Contains Element  ${xpath_profile_settings_heading}  timeout=10
    Click Element At Coordinates  ${xpath_browser_offset}  0  0
    Click Element   ${xpath_profile_save_button}
    ${xpath_browser_offset_text}=  Get Text  ${xpath_browser_offset_textfield}

    # We get an output ${xpath_browser_offset_text} = Browser offset (CST UTC-6).
    # Need to compare "CST UTC-6" text so removing the spaces and other values.

    ${text}=  Set Variable  ${xpath_browser_offset_text.split("(")[1].split(")")[0]}
    Navigate To Date and Time Page
    Page Should Contain  ${text}


Verify NTP Server Input Fields In Date And Time Page
    [Documentation]  Verify NTP server input fields in date and time page.
    [Tags]  Verify_NTP_Server_Input_Fields_In_Date_And_Time_Page
    [Setup]  Setup To Power Off And Navigate

    Click Element At Coordinates  ${xpath_select_ntp}  0  0
    Input Text  ${xpath_ntp_server1}  10.10.10.10
    Input Text  ${xpath_ntp_server2}  20.20.20.20
    Input Text  ${xpath_ntp_server3}  30.30.30.30
    Click Element  ${xpath_select_save_settings}


    # Refresh the NTP Page.
    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains Element  ${xpath_select_ntp}  timeout=10s

    Textfield Value Should Be  ${xpath_ntp_server1}  10.10.10.10
    Textfield Value Should Be  ${xpath_ntp_server2}  20.20.20.20
    Textfield Value Should Be  ${xpath_ntp_server3}  30.30.30.30


Verify Setting Manual BMC Time
    [Documentation]  Verify changing manual time and comparing it with CLI time.
    [Tags]  Verify_Setting_Manual_BMC_Time
    [Setup]  Run Keywords  Set Timezone In Profile Settings Page
    ...  Default  AND  Setup To Power Off And Navigate

    Click Element At Coordinates  ${xpath_select_manual}  0  0
    Input Text  ${xpath_manual_date}  2023-05-12
    Input Text  ${xpath_manual_time}  15:30
    Click Element  ${xpath_select_save_settings}

    # Wait for changes to take effect.
    Sleep  120
    ${manual_date}=  Get Value  ${xpath_manual_date}
    ${manual_time}=  Get Value  ${xpath_manual_time}

    ${cli_date_time}=  CLI Get BMC DateTime
    Should contain  ${cli_date_time}  ${manual_date}  ${manual_time}


Verify Setting Invalid Date And Time Is Not Allowed
    [Documentation]  Verify if invalid date and invalid time input is given,
    ...  it should throw error.
    [Tags]  Verify_Setting_Invalid_Date_And_Time_Is_Not_Allowed
    [Setup]  Setup To Power Off And Navigate

    Click Element At Coordinates  ${xpath_select_manual}  0  0
    Input Text  ${xpath_manual_date}  2023-18-48
    Page Should Contain Element  ${xpath_invalid_format_message}
    Input Text  ${xpath_manual_time}  29:48
    Page Should Contain Element  ${xpath_invalid_format_message}


Verify Changing BMC Time From NTP To Manual
    [Documentation]  Verify that BMC time can be changed from NTP to
    ...  manual time via GUI.
    [Tags]  Verify_Changing_BMC_Time_From_NTP_To_Manual
    [Setup]  Setup To Power Off And Navigate

    # Add NTP server for BMC time to sync.
    Click Element At Coordinates  ${xpath_select_ntp}  0  0
    Input Text  ${xpath_ntp_server1}  time.google.com
    Click Element  ${xpath_select_save_settings}

    # Wait for changes to take effect.
    Wait Until Page Contains Element  ${xpath_select_ntp}  timeout=30s

    # Set the manual date and time.
    ${cli_date_time}=  CLI Get BMC DateTime
    ${date_changed}=  Add Time To Date  ${cli_date_time}  31 days
    ${date_changed}=  Add Time To Date  ${date_changed}  05:10:00
    Log  "Setting BMC date : ${date_changed} using Manual option"
    ${date}=  Convert Date  ${date_changed}  result_format=%Y-%m-%d
    ${time}=  Convert Date  ${date_changed}  result_format=%H:%M
    Click Element At Coordinates  ${xpath_select_manual}  0  0
    Input Text  ${xpath_manual_date}  ${date}
    Input Text  ${xpath_manual_time}  ${time}
    Click Element  ${xpath_select_save_settings}

    # Refresh the NTP Page.
    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains  ${date}  timeout=60s
    Page Should Contain  ${time}

    # Wait for the "Saved Successfully" window to close automatically.
    Sleep  15


Verify Moving From Manual To NTP
    [Documentation]  Verify switching between manual mode and NTP mode.
    [Tags]  Verify_Moving_From_Manual_To_NTP
    [Setup]  Setup To Power Off And Navigate
    [Template]  Switch From Manual To NTP

    # loop_count
    ${LOOP_COUNT}


*** Keywords ***

Suite Setup Execution
   [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI
    Maximize Browser Window

Suite Teardown Execution
   [Documentation]  Do the post suite teardown.

    Run Keyword And Ignore Error  Logout GUI
    Close Browser

Setup To Power Off And Navigate
   [Documentation]  Power off system if not powered off and go to date and
   ...  time page.

   Redfish Power off  stack_mode=skip
   Navigate To Date and Time Page

Navigate To Date and Time Page
    [Documentation]  Navigate to the date and time page from main menu.

    Click Element  ${xpath_settings_menu}
    Click Element  ${xpath_date_time_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  date-time
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30

Set Manual Date and Time Via GUI
    [Documentation]  Set BMC date and time to one month in future via GUI.

    ${cli_date_time}=  CLI Get BMC DateTime
    ${new_date}=  Add Time To Date  ${cli_date_time}  31 days
    ${new_date_time}=  Add Time To Date  ${new_date}  05:10:00
    Log  "Setting BMC date : ${new_date_time} using Manual option"
    ${date}=  Convert Date  ${new_date_time}  result_format=%Y-%m-%d
    ${time}=  Convert Date  ${new_date_time}  result_format=%H:%M
    Click Element At Coordinates  ${xpath_select_manual}  0  0
    Input Text  ${xpath_manual_date}  ${date}
    Input Text  ${xpath_manual_time}  ${time}
    Click Element  ${xpath_select_save_settings}

    # Wait for changes to take effect.
    Wait Until Element Is Enabled  ${xpath_select_ntp}  timeout=30s

Switch From Manual To NTP
    [Documentation]  Verify switching from manual mode to NTP mode.
    [Arguments]  ${loop_count}=${LOOP_COUNT}

    # Description of argument(s):
    # loop_count        Number of loops to move from manual to NTP.

    FOR  ${x}  IN RANGE  ${loop_count}
       Set Manual Date and Time Via GUI
       # Set BMC date time to sync with NTP server.
       Click Element At Coordinates  ${xpath_select_ntp}  0  0
       Input Text  ${xpath_ntp_server1}  216.239.35.0
       Click Element  ${xpath_select_save_settings}

       # Wait until progress bar is not visible.
       Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=60

       ${cli_date_time}=  CLI Get BMC DateTime
       ${ntp_date}=  Convert Date  ${cli_date_time}  result_format=%Y-%m-%d
       ${ntp_time}=  Convert Date  ${cli_date_time}  result_format=%H:%M
       Wait Until Page Contains  ${ntp_date}   timeout=60s
       Page Should Contain  ${ntp_time}

       Wait Until Element Is Not Visible   ${xpath_success_message}  timeout=60
       Log  "Completed Loop for ${x} time"
    END
