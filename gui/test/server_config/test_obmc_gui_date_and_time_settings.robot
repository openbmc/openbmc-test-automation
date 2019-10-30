*** Settings ***

Documentation  Test OpenBMC GUI "Date and time settings" sub-menu of
...            "Server configuration".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_set_time_from_ntp}        //*[@for="ntp-time"]
${xpath_add_new_ntp_server}       //button[contains(text(), "Add new NTP server")]
${xpath_set_time_manually}        //*[@for="manual-time"]
${xpath_set_date}                 //input[@type="date"]
${xpath_set_time}                 //input[@type="time"]
${xpath_set_time_owner}           //select[@id="date-time-owner"]


*** Test Cases ***

Verify Existence Of All Sections In Date And Time Settings Page
    [Documentation]  Verify existence of all sections in date and time settings
    ...              page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Date_And_Time_Settings_Page

    Page Should Contain  Set date and time manually or configure a Network Time
    ...                  Protocol (NTP) Server


Verify Existence Of All Buttons In Date And Time Settings Page
    [Documentation]  Verify existence of all buttons in date and time settings
    ...              page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Date_And_Time_Settings_Page

    Page Should Contain Element  ${xpath_set_time_from_ntp}
    Page Should Contain Element  ${xpath_add_new_ntp_server}
    Page Should Contain Element  ${xpath_set_time_manually}
    Page Should Contain Element  ${xpath_set_date}
    Page Should Contain Element  ${xpath_set_time}
    Page Should Contain Element  ${xpath_set_time_owner}
    Page Should Contain Element  ${xpath_cancel_button}
    Page Should Contain Element  ${xpath_save_setting_button}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_server_configuration}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_date_time_settings}
    Wait Until Page Contains  Date and time settings
