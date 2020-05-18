*** Settings ***

Documentation  Test Open BMC GUI BMC host information under GUI Header.

Library        DateTime

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser


*** Variables ***
${xpath_header_text}            //*[contains(@class, "navbar-text")]
${xpath_select_refresh_button}  //*[text()[contains(.,"Refresh")]]
${xpath_select_date_text}       //*[@class="header__refresh"]
${xpath_header_scroll}          //*[contains(@class,"header__action")]

*** Test Cases ***

Verify Server Power Button
    [Documentation]  Verify server power page on clicking server power button.
    [Tags]  Verify_Server_Power_Button

    Wait Until Element Is Visible   ${xpath_select_server_power}
    Click Element  ${xpath_select_server_power}
    Wait Until Page Contains  Server power operations

Verify Server Health Button
    [Documentation]  Verify server health page on clicking server health button.
    [Tags]  Verify_Server_Health_Button

    Wait Until Element Is Visible   ${xpath_select_server_health}
    Click Element  ${xpath_select_server_health}
    Wait Until Page Contains  All events from the BMC


Verify Header Text
    [Documentation]  Verify text in GUI header.
    [Tags]  Verify_Header_Text

    ${gui_header_text}=  Get Text  ${xpath_header_text}
    Should Contain  ${gui_header_text}  BMC System Management


Verify Refresh Button
    [Documentation]  Verify Refresh Button in GUI header.
    [Tags]  Verify_Refresh_Button

    # Verify power is on after refresh button.

    Expected Initial Test State  Off
    Wait Until Element Is Visible  ${xpath_select_refresh_button}
    Click Element  ${xpath_select_refresh_button}
    GUI Power On
    Wait Until Element Is Visible  ${xpath_select_refresh_button}
    Click Element  ${xpath_select_refresh_button}
    Wait Until Page Contains  Running

Verify Date Last Refreshed
    [Documentation]  Verify Date Last Refreshed text in GUI header.
    [Tags]  Verify_Date_Last_Refreshed

    Wait Until Element Is Visible  ${xpath_select_date_text}
    ${date_info_1st_read}=  Get Text  ${xpath_select_date_text}
    Should Not Be Empty  ${date_info_1st_read}
    ${current_date}=  Get Time
    ${date_conversion}=  Convert Date  ${current_date}  result_format=%b %-d %Y

    ${mmmdd}  ${yyyy}=  Split String From Right  ${date_conversion}  ${SPACE}  1
    Should Contain  ${date_info_1st_read}  ${mmmdd}  msg=Month and day mismatch.
    Should Contain  ${date_info_1st_read}  ${yyyy}  msg=Year mismatch.

    # Refresh button pressed.
    Click Element  ${xpath_select_refresh_button}
    Sleep  2s

    ${date_info_2nd_read}=  Get Text  ${xpath_select_date_text}
    ${current_date}=  Get Time
    ${date_conversion}=  Convert Date  ${current_date}  result_format=%b %-d %Y

    ${mmmdd}  ${yyyy}=  Split String From Right  ${date_conversion}  ${SPACE}  1
    Should Contain  ${date_info_1st_read}  ${mmmdd}  msg=Month and day mismatch.
    Should Contain  ${date_info_1st_read}  ${yyyy}  msg=Year mismatch.

    # Comparison between 1st and 2nd read.
    Should Not Be Equal As Strings  ${date_info_1st_read}
    ...  ${date_info_2nd_read}

Verify GUI Header Scrolls
    [Documentation]  Verify GUI header scrolls on click "Server Info" element.
    [Tags]  Verify_GUI_Header_Scrolls

    ${current_browser_width}  ${current_browser_height}=  Get Window Size
    Maximize Browser Window
    ${max_browser_width}  ${max_browser_height}=  Get Window Size
    # Shrink the browser to half from max size.
    ${shrink_browser_width}=  Evaluate  ${max_browser_width} / 2
    ${shrink_browser_height}=  Evaluate  ${max_browser_height} / 2
    # Reduce the browser size which enables scroll element.
    Set Window Size  ${shrink_browser_width}  ${shrink_browser_height}
    Click Element  ${xpath_header_scroll}
    # Below element is to scroll back.
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_header_scroll}
    # Restore to original browser size.
    Set Window Size  ${current_browser_width}  ${current_browser_height}


OpenBMC GUI Logoff
    [Documentation]  Log out from openBMC GUI.
    [Tags]  OpenBMC_GUI_Logoff

    Click Element  ${xpath_button_logout}
    Wait Until Page Contains Element  ${xpath_button_login}  timeout=15s

