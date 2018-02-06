*** Settings ***

Documentation  Test Open BMC GUI Power Operations under GUI Header.

Resource        ../../../../lib/state_manager.robot
Resource        ../../lib/resource.robot

Suite Setup     Login OpenBMC GUI with failure enable
Suite Teardown  Close Browser

*** Variables ***
${xpath_select_server_control}  //*[@id="header__wrapper"]/div/div[2]/p[2]

*** Test Cases ***

Verify IP address
    [Documentation]  Verify BMC IP address displayed in GUI header.
    [Tags]  Verify_IP_address

    ${gui_displayed_ip}=  Get Text  ${xpath_select_server_control}
    Should Contain  ${gui_displayed_ip}  ${OPENBMC_HOST}

*** Keywords ***

Login OpenBMC GUI with failure enable

    Open Browser With URL  ${xpath_openbmc_url}
    Login OpenBMC GUI  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}




