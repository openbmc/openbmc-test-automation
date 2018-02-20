*** Settings ***

Documentation  Test Open BMC GUI BMC host information under GUI Header.

Resource        ../../lib/resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser

*** Variables ***
${xpath_select_server_control}  //*[@id="header__wrapper"]/div/div[2]/p[2]
${xpath_select_refresh_button}  //*[@id="header__wrapper"]/div/div[3]/button

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

    # Verify the BMC host / ip information after refresh button

    ${gui_displayed_ip}=  Get Text  ${xpath_select_server_control}
    Click Element  ${xpath_select_refresh_button}
    Model Server Power Click Button  ${header_wrapper}  ${header_wrapper_elt}
    Should Contain  ${gui_displayed_ip}  ${OPENBMC_HOST}

*** Keywords ***

Suite Setup Execution

    Open Browser With URL  ${obmc_gui_url}
    Login OpenBMC GUI  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}




