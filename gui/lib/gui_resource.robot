*** Settings ***
Documentation  This is a resource file containing user-defined keywords for new Vue based OpenBMC GUI.

Library        XvfbRobot
Library        SeleniumLibrary
Library        SSHLibrary  30 Seconds
Resource       ../../lib/state_manager.robot
Variables      ../data/gui_variables.py


*** Variables ***
${obmc_gui_url}              https://${OPENBMC_HOST}:${HTTPS_PORT}
${xpath_power_page}          //*[@data-test-id='appHeader-container-power']
${xpath_power_shutdown}      //*[@data-test-id='serverPowerOperations-button-shutDown']
${xpath_power_power_on}      //*[@data-test-id='serverPowerOperations-button-powerOn']
${xpath_power_reboot}        //*[@data-test-id='serverPowerOperations-button-reboot']
${xpath_confirm}             //button[contains(text(),'Confirm')]

# Default GUI browser and mode is set to "Firefox" and "headless"
# respectively here.
${GUI_BROWSER}               ff
${GUI_MODE}                  headless


*** Keywords ***

Open Browser With URL
    [Documentation]  Open browser with specified URL and returns browser id.
    [Arguments]  ${URL}  ${browser}=ff  ${mode}=${GUI_MODE}

    # Description of argument(s):
    # URL      Openbmc GUI URL to be open
    #          (e.g. https://openbmc-test.mybluemix.net/#/login).
    # browser  Browser used to open above URL
    #          (e.g. gc for google chrome, ff for firefox).
    # mode     Browser opening mode(e.g. headless, header).

    ${browser_ID}=  Run Keyword If  '${mode}' == 'headless'
    ...  Launch Headless Browser  ${URL}  ${browser}
    ...  ELSE  Open Browser  ${URL}  ${browser}

    RETURN  ${browser_ID}


Launch Header Browser
    [Documentation]  Open the browser with the URL and
    ...              login on windows platform.
    [Arguments]  ${browser_type}=${GUI_BROWSER}

    # Description of argument(s):
    # browser_type  Type of browser (e.g. "firefox", "chrome", etc.).

    ${BROWSER_ID}=  Open Browser  ${obmc_gui_url}  ${browser_type}
    Maximize Browser Window
    Set Global Variable  ${BROWSER_ID}


Launch Headless Browser
    [Documentation]  Launch headless browser.
    [Arguments]  ${URL}=${obmc_gui_url}  ${browser}=${GUI_BROWSER}

    # Description of argument(s):
    # URL      Openbmc GUI URL to be open
    #          (e.g. https://openbmc-test.mybluemix.net/#/login).
    # browser  Browser to open given URL in headless way
    #          (e.g. gc for google chrome, ff for firefox).

    Start Virtual Display
    ${browser_ID}=  Open Browser  ${URL}    ${browser}
    Set Window Size  1920  1080

    RETURN  ${browser_ID}


Launch Browser And Login GUI
    [Documentation]  Launch browser and login to OpenBMC GUI, retry 2 attempts
    ...              in 1 minute time.

    Wait Until Keyword Succeeds  195 sec   65 sec  Retry Browser Login Attempts


Retry Browser Login Attempts
    [Documentation]  Launch browser and login to OpenBMC GUI.

    Open Browser With URL  ${obmc_gui_url}
    Login GUI  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}


Login GUI
    [Documentation]  Login to OpenBMC GUI.
    [Arguments]  ${username}=${OPENBMC_USERNAME}  ${password}=${OPENBMC_PASSWORD}

    # Description of argument(s):
    # username  The username to be used for login.
    # password  The password to be used for login.

    Go To  ${obmc_gui_url}
    Wait Until Element Is Enabled  ${xpath_login_username_input}
    Input Text  ${xpath_login_username_input}  ${username}
    Input Password  ${xpath_login_password_input}  ${password}
    Wait Until Element Is Enabled  ${xpath_login_button}
    Click Element  ${xpath_login_button}
    Wait Until Page Contains  Overview  timeout=60s
    Wait Until Element Is Not Visible
    ...  ${xpath_page_loading_progress_bar}  timeout=120s

Launch Browser And Login GUI With Given User
    [Documentation]  Launch browser and login eBMC with specified user
    ...  credentials through GUI.
    [Arguments]  ${user_name}  ${user_password}

    # Description of argument(s):
    # user_name        User name to login to eBMC.
    # user_password    User password to login to eBMC.

    Open Browser With URL  ${obmc_gui_url}
    LOGIN GUI  ${user_name}  ${user_password}

Logout GUI
    [Documentation]  Logout of OpenBMC GUI.

    Click Element  ${xpath_root_button_menu}
    Click Element  ${xpath_logout_button}
    Wait Until Page Contains Element  ${xpath_login_button}


Generate Test Error Log
    [Documentation]  Generate test error log.

    BMC Execute Command  ${CMD_UNRECOVERABLE_ERROR}


Set Timezone In Profile Settings Page
    [Documentation]  Set the given timezone in profile settings page.
    [Arguments]  ${timezone}=Default

    # Description of argument(s):
    # timezone  Timezone to select (eg. Default or Browser_offset).

    Wait Until Page Contains Element  ${xpath_root_button_menu}
    Click Element  ${xpath_root_button_menu}
    Click Element  ${xpath_profile_settings}
    Click Element At Coordinates  ${xpath_default_UTC}  0  0
    Click Element  ${xpath_profile_save_button}


Refresh GUI
    [Documentation]  Refresh GUI via refresh button in header.

    Click Element  ${xpath_refresh_button}
    # Added delay for page to load fully after refresh.
    Sleep  5s


Refresh GUI And Verify Element Value
    [Documentation]  Refresh GUI using refresh button and verify that given element contains expected value.
    [Arguments]  ${element}  ${expected_value}

    # Description of argument(s):
    # element         Element whose value need to be checked.
    # expected_value  Expected value of for the given element.

    # Refresh GUI.

    Click Element  ${xpath_refresh_button}

    # Check element value and verify that it contains expected value.
    ${element_value}=  Get Text  ${element}
    Log  ${element_value}
    Should Contain  ${element_value}  ${expected_value}


Reboot BMC via GUI
    [Documentation]  Reboot BMC via GUI.

    Click Element  ${xpath_operations_menu}
    Click Element  ${xpath_reboot_bmc_sub_menu}
    Click Button  ${xpath_reboot_bmc_button}
    Wait Until Keyword Succeeds  30 sec  10 sec  Click Button  ${xpath_confirm_bmc_reboot}
    Wait Until Keyword Succeeds  2 min  10 sec  Is BMC Unpingable
    Wait For Host To Ping  ${OPENBMC_HOST}  1 min


Add DNS Servers And Verify
    [Documentation]  Login to GUI Network page,add DNS server on BMC
    ...  and verify it via BMC CLI.
    [Arguments]  ${dns_server}   ${expected_status}=Valid format

    # Description of the argument(s):
    # dns_server           A list of static name server IPs to be
    #                      configured on the BMC.
    # expected_status      Expected status while adding DNS server address
    #                      (e.g. Invalid format / Field required).

    Wait Until Page Contains Element  ${xpath_add_dns_ip_address_button}  timeout=15sec

    Click Button  ${xpath_add_dns_ip_address_button}
    Input Text  ${xpath_input_static_dns}  ${dns_server}
    Click Button  ${xpath_add_button}
    Run keyword if  '${expected_status}' != 'Valid format'
    ...  Run keywords  Page Should Contain  ${expected_status}  AND  Return From Keyword

    Wait Until Page Contains Element  ${xpath_add_dns_ip_address_button}  timeout=10sec
    Wait Until Page Contains  ${dns_server}  timeout=40sec

    # Check if newly added DNS server is configured on BMC.
    ${cli_name_servers}=  CLI Get Nameservers
    ${cmd_status}=  Run Keyword And Return Status
    ...  List Should Contain Sub List  ${cli_name_servers}  ${dns_server}
    Run Keyword If  '${expected_status}' == '${HTTP_OK}'
    ...  Should Be True  ${cmd_status} == ${True}
    ...  ELSE  Should Not Be True  ${cmd_status}


Navigate To Server Power Page
    [Documentation]  Navigate To Server Power Page.

    Click Element  ${xpath_power_page}
    Wait Until Element Is Not Visible  ${xpath_progress_bar}  timeout=30


Power Off Server
    [Documentation]  Powering off server.

    Navigate To Server Power Page
    ${present}=    Run Keyword And Return Status
    ...  Element Should Be Visible    ${xpath_power_shutdown}
    IF  ${present}
      Click Element  ${xpath_power_shutdown}
      Click Button  ${xpath_confirm}
      Wait Until Element Is Visible  ${xpath_power_poweron}  timeout=60
    ELSE
      Log To console    Server is already powered Off.
    END


Power On Server
    [Documentation]  Powering on server.

    Navigate To Server Power Page
    ${present}=    Run Keyword And Return Status
    ...  Element Should Be Visible    ${xpath_power_power_on}
    IF  (${present})
      Click Element  ${xpath_power_power_on}
      Wait Until Element Is Visible  ${xpath_power_shutdown}  timeout=60
    ELSE
      Log To console    Server is already powered On.
    END


Reboot Server
    [Documentation]  Rebooting the server.

    Navigate To Server Power Page
    ${present}=    Run Keyword And Return Status
    ...  Element Should Be Visible    ${xpath_power_reboot}
    IF  ${present}
      Click Element  ${xpath_power_reboot}
      Wait Until Element Is Visible  ${xpath_confirm}  timeout=30
      Click Button  ${xpath_confirm}
      Wait Until Element Is Visible  ${xpath_power_reboot}  timeout=60
    ELSE
      Log To console    Server is already powered Off, can't reboot.
    END
