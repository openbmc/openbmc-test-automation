*** Settings ***

Documentation  Test Open BMC GUI BMC host information under GUI Header.

Library        DateTime

Resource        ../../lib/resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser

*** Variables ***
${xpath_select_server_control}  //*[@id="header__wrapper"]/div/div[2]/p[2]
${xpath_select_refresh_button}  //*[@id="header__wrapper"]/div/div[3]/button
${xpath_select_date_text}       //*[@id="header__wrapper"]/div/div[3]/p/span

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
    Sleep  2

    ${date_info_2nd_read}=  Get Text  ${xpath_select_date_text}
    ${current_date}=  Get Time
    ${date_conversion}=  Convert Date  ${current_date}  result_format=%b %d %Y
    Should Contain  ${date_info_2nd_read}  ${date_conversion}

    # Comparison between 1st and 2nd read.
    Should Not Be Equal As Strings  ${date_info_1st_read}
    ...  ${date_info_2nd_read}

*** Keywords ***

Suite Setup Execution

    Open Browser With URL  ${obmc_gui_url}
    Login OpenBMC GUI  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}




