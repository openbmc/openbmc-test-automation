*** Settings ***

Documentation   Test OpenBMC GUI "Date and time settings" sub-menu of "Configuration".

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser


*** Variables ***

${xpath_date_time_heading}     //h1[text()="Date and time settings"]
${xpath_select_manual}         //*[@data-test-id="dateTimeSettings-radio-configureManual"]
${xpath_select_ntp}            //*[@data-test-id="dateTimeSettings-radio-configureNTP"]
${xpath_manual_date}           //input[@data-test-id="dateTimeSettings-input-manualDate"]
${xpath_manual_time}           //input[@data-test-id="dateTimeSettings-input-manualTime"]
${xpath_ntp_server1}           //input[@data-test-id="dateTimeSettings-input-ntpServer1"]
${xpath_ntp_server2}           //input[@data-test-id="dateTimeSettings-input-ntpServer2"]
${xpath_ntp_server3}           //input[@data-test-id="dateTimeSettings-input-ntpServer3"]
${xpath_select_save_settings}  //button[@data-test-id="dateTimeSettings-button-saveSettings"]


*** Test Cases ***

Verify Navigation To Date And Time Settings Page
    [Documentation]  Verify navigation to date and time settings page.
    [Tags]  Verify_Navigation_To_Date_And_Time_Settings_Page

    Page Should Contain Element  ${xpath_date_time_heading}


Verify Existence Of All Sections In Date And Time Settings Page
    [Documentation]  Verify existence of all sections in date and time settings page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Date_And_Time_Settings_Page

    Page Should Contain  Configure settings


Verify Existence Of All Buttons In Date And Time Settings Page
    [Documentation]  Verify existence of all buttons in date and time settings page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Date_And_Time_Settings_Page

    Page Should Contain Element  ${xpath_select_manual}
    Page Should Contain Element  ${xpath_select_ntp}
    Page Should Contain Element  ${xpath_select_save_settings}


Verify Existence Of All Input Boxes In Date And Time Settings Page
    [Documentation]  Verify existence of all input boxes in date time settings page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_Date_And_Time_Settings_Page

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


Verify Display Of Date and Time In GUI Page
     [Documentation]  Get date and time from Redfish and verify it via GUI date and time page.
     [Tags]  Verify_Display_Of_Date_And_Time_In_Gui_Page

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


*** Keywords ***

Suite Setup Execution
   [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI
    Navigate To Date and Time Page

Navigate To Date and Time Page
    [Documentation]  Navigate to the date and time page from main menu.

    Click Element  ${xpath_server_configuration}
    Click Element  ${xpath_date_time_settings_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  date-time-settings
