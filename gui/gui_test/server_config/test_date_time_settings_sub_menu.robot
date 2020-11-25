*** Settings ***

Documentation   Test OpenBMC GUI "Date and time settings" sub-menu of "Configuration".

Resource        ../../lib/resource.robot

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
${gui_current_date}            //div[@class='page-section']//dt[text() = 'Date']/following-sibling::dd
${gui_current_time}            //div[@class='page-section']//dt[text() = '24-hour time']/following-sibling::dd


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


Verify Display of Date and Time in GUI Page
    [Documentation]  Verify display of date and time in gui Page
    [Tags]  Verify_Display_Of_Date_And_Time_In_Gui_Page

    #Get Date and Time from GUI page.
    ${gui_date}=  Get Text  ${gui_current_date}
    ${gui_Time}=  Get Text  ${gui_current_time}

    #Verify Date and Time with CLI.
    ${cli_date_time}=  CLI Get BMC DateTime
    Should contain  ${cli_date_time}  ${gui_date}  ${gui_Time}


*** Keywords ***

Suite Setup Execution
   [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_server_configuration}
    Click Element  ${xpath_date_time_settings_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  date-time-settings

