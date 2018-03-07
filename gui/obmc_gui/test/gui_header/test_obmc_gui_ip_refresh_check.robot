*** Settings ***

Documentation  Test Open BMC GUI BMC host information under GUI Header.

Library        DateTime

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Logout And Close Browser

*** Variables ***
${xpath_select_server_control}  //*[@id="header__wrapper"]/div/div[2]/p[2]
${xpath_select_refresh_button}  //*[@id="header__wrapper"]/div/div[3]/button
${xpath_select_date_text}       //*[@id="header__wrapper"]/div/div[3]/p/span
${xpath_header_scroll_front}    //*[@id="header__wrapper"]/div/div[3]/a[1]/span
${xpath_header_scroll_back}     //*[@id="header__wrapper"]/div/div[3]/a[1]/i

*** Test Cases ***

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
    Should Contain  ${date_info_1st_read}  ${date_conversion}

    # Refresh button pressed.
    Click Element  ${xpath_select_refresh_button}
    Sleep  2s

    ${date_info_2nd_read}=  Get Text  ${xpath_select_date_text}
    ${current_date}=  Get Time
    ${date_conversion}=  Convert Date  ${current_date}  result_format=%b %d %Y
    Should Contain  ${date_info_2nd_read}  ${date_conversion}

    # Comparison between 1st and 2nd read.
    Should Not Be Equal As Strings  ${date_info_1st_read}
    ...  ${date_info_2nd_read}


Verify_GUI_Header_Scrolls
    [Documentation]  Verify GUI header scrolls on click "Server Info" element.
    [Tags]  Verify_GUI_Header_Scrolls

    ${current_browser_width}  ${current_browser_height}=  Get Window Size
    # Reduce the browser size which enables scroll element
    Set Window Size  800  800
    Click Element  ${xpath_header_scroll_front}
    # Below element is to scroll back
    # //*[@id="header__wrapper"]/div/div[3]/a[1]/i
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_header_scroll_back}
    # Restore to original browser size
    Set Window Size  ${current_browser_width}  ${current_browser_height}
