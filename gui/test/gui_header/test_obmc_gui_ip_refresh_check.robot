*** Settings ***

Documentation  Test Open BMC GUI BMC host information under GUI Header.

Library        DateTime

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser


*** Variables ***
${xpath_select_server_control}  //*[@id="header__wrapper"]/div/div[2]/p[2]
${xpath_select_refresh_button}  //*[@id="header__wrapper"]/div/div[3]/button
${xpath_select_date_text}       //*[@id="header__wrapper"]/div/div[3]/p/span
${xpath_header_scroll_front}    //*[@id="header__wrapper"]/div/div[3]/a[1]/span
${xpath_header_scroll_back}     //*[@id="header__wrapper"]/div/div[3]/a[1]/i

*** Test Cases ***

Verify Server Power Button
    [Documentation]  Verify server power page on clicking server power button.
    [Tags]  Verify_Server_Power_Button

    Click Button  ${xpath_select_server_power}
    Wait Until Page Contains Element  power-operations
    Page Should Contain  Server power operations

Verify Server Health Button
    [Documentation]  Verify server health page on clicking server health button.
    [Tags]  Verify_Server_Health_Button

    Click Button  ${xpath_select_server_health}
    Wait Until Page Contains Element  event-log
    Page Should Contain  Event log

Verify IP address
    [Documentation]  Verify BMC IP address displayed in GUI header.
    [Tags]  Verify_IP_address

    # NOTE: gui_displayed_ip can be either a host name or an IP address.
    #       (e.g. "machinex" or "xx.xx.xx.xx").
    ${gui_displayed_ip}=  Get Text  ${xpath_select_server_control}
    Should Contain  ${gui_displayed_ip}  ${OPENBMC_HOST}


Verify Refresh Button
    [Documentation]  Verify Refresh Button in GUI header.
    [Tags]  Verify_Refresh_Button

    # Verify power is on after refresh button.

    Expected Initial Test State  Off
    Click Element  ${xpath_select_refresh_button}
    GUI Power On
    Click Element  ${xpath_select_refresh_button}
    Wait Until Page Contains  Running

Verify Date Last Refreshed
    [Documentation]  Verify Date Last Refreshed text in GUI header.
    [Tags]  Verify_Date_Last_Refreshed

    ${date_info_1st_read}=  Get Text  ${xpath_select_date_text}
    ${current_date}=  Get Time
    ${date_conversion}=  Convert Date  ${current_date}  result_format=%b %d %Y

    ${mmmdd}  ${yyyy}=  Split String From Right  ${date_conversion}  ${SPACE}  1
    Should Contain  ${date_info_1st_read}  ${mmmdd}  msg=Month and day mismatch.
    Should Contain  ${date_info_1st_read}  ${yyyy}  msg=Year mismatch.

    # Refresh button pressed.
    Click Element  ${xpath_select_refresh_button}
    Sleep  2s

    ${date_info_2nd_read}=  Get Text  ${xpath_select_date_text}
    ${current_date}=  Get Time
    ${date_conversion}=  Convert Date  ${current_date}  result_format=%b %d %Y

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
    Click Element  ${xpath_header_scroll_front}
    # Below element is to scroll back.
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_header_scroll_back}
    # Restore to original browser size.
    Set Window Size  ${current_browser_width}  ${current_browser_height}
