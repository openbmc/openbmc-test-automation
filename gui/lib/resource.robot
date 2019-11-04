*** Settings ***
Documentation  This is a resource file of OpenBMC ASMI It contains the
...            user-defined keywords which are available to all gui modules

Library      String
Library      Collections
Library      DateTime
Library      XvfbRobot
Library      OperatingSystem
Library      SeleniumLibrary
Library      AngularJSLibrary
Library      SSHLibrary  30 Seconds
Library      Process
Library      supporting_libs.py
Library      ../../lib/gen_print.py
Library      ../../lib/gen_robot_print.py
Library      ../../lib/gen_valid.py
Library      ../../lib/gen_robot_ssh.py
Library      ../../lib/bmc_ssh_utils.py
Resource     ../../lib/resource.robot
Resource     ../../lib/rest_client.robot
Resource     ../../lib/state_manager.robot
Variables    ../data/resource_variables.py

*** Variables ***
${obmc_gui_url}              https://${OPENBMC_HOST}

${obmc_PowerOff_state}       Off
${obmc_PowerRunning_state}   Running
${obmc_PowerStandby_state}   Standby

# Default GUI broswer and mode is set to "Firefox" and "headless"
# respectively here.
${GUI_BROWSER}               ff
${GUI_MODE}                  headless

*** Keywords ***
Launch OpenBMC GUI Browser
    [Documentation]  Launch the OpenBMC GUI URL on a browser.
    # By default uses headless mode, otherwise, the GUI browser.

    ${op_system}=  Get Operating System
    Run Keyword If  '${op_system}' == 'windows'
    ...     Launch Header Browser
    ...  ELSE IF  '${op_system}' == 'Darwin'
            # Mac OS is currently having some issues with firefox, so using
            # chrome.
            # TODO: Need to add support for other browsers. Issue #1280.
    ...     Launch Header Browser  chrome
    ...  ELSE
            # Linux OS.
    ...     Launch Headless Browser

Get Operating System
    [Documentation]  Identify platform/OS.

    ${curdir_lower_case}=  Convert To Lowercase  ${CURDIR}
    ${windows_platform}=  Run Keyword And Return Status
    ...  Should Contain  ${curdir_lower_case}  c:\
    ${op_system}=  Run Keyword If  '${windows_platform}' == 'True'
    ...     Set Variable  windows
    ...   ELSE
    ...     Run  uname
    [Return]  ${op_system}

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
    ${browser_ID}=  Open Browser  ${URL}
    Set Window Size  1920  1080

    [Return]  ${browser_ID}

Login OpenBMC GUI
    [Documentation]  Perform login to open BMC GUI.
    [Arguments]  ${username}=${OPENBMC_USERNAME}
    ...  ${password}=${OPENBMC_PASSWORD}

    # Description of argument(s):
    # username      The username.
    # password      The password.

    Go To  ${obmc_gui_url}
    Wait Until Element Is Enabled  ${xpath_textbox_hostname}
    Input Text  ${xpath_textbox_hostname}  ${OPENBMC_HOST}
    Input Text  ${xpath_textbox_username}  ${username}
    Input Password  ${xpath_textbox_password}  ${password}
    Click Element  login__submit
    Wait Until Element Is Enabled  ${xpath_button_logout}
    Page Should Contain  Server information


Test Setup Execution
    [Documentation]  Verify all the preconditions to be tested.
    [Arguments]  ${obmc_test_setup_state}=${OBMC_PowerOff_state}

    # Description of argument(s):
    # obmc_test_setup      The OpenBMC required state.

    Print Timen  ${TEST NAME} ==> [STARTED]
    Launch Browser And Login OpenBMC GUI
    Log To Console  Verifying the system state and stablity...

    Click Element  ${xpath_select_server_power}
    Wait Until Page Does Not Contain  Unreachable
    ${obmc_current_state}=  Get Text  ${xpath_power_indicator}
    Rpvars  obmc_current_state

    ${obmc_state_status}=  Run Keyword And Return Status
    ...  Should Contain  ${obmc_current_state}  ${obmc_test_setup_state}
    Return From Keyword If  '${obmc_state_status}' == 'True'

    ${obmc_standby_state}=  Run Keyword And Return Status
    ...  Should Contain  ${obmc_current_state}  ${obmc_standby_state}

    Run Keyword If  '${obmc_standby_state}' == 'True'
    ...  Reboot OpenBMC
    Run Keyword If  '${obmc_test_setup_state}' == '${obmc_PowerRunning_state}'
    ...  Run Keywords  Power On OpenBMC  AND
    ...  Wait Until Keyword Succeeds  10 min  60 sec  Is Host Running
    Run Keyword If  '${obmc_test_setup_state}' == '${obmc_PowerOff_state}'
    ...  Run Keywords  Redfish.Login  AND  Redfish Power Off  AND  Redfish.Logout


Power On OpenBMC
    [Documentation]  Power on the OBMC system.

    Log To Console  Power On OpenBMC...
    Click Element  ${xpath_select_server_power}
    Click Button  ${xpath_select_button_power_on }
    Wait OpenBMC To Become Stable  ${obmc_running_state}

Reboot OpenBMC
    [Documentation]  Rebooting the OBMC system.

    Log To Console  Reboting the OpenBMC...
    Click Element  ${xpath_select_server_power}
    Click Button  ${xpath_select_button_orderly_shutdown}
    Click Yes Button  ${xpath_select_button_orderly_shutdown_yes}
    Wait OpenBMC To Become Stable  ${obmc_off_state}

Wait OpenBMC To Become Stable
    [Documentation]  Power off the OBMC.
    [Arguments]  ${obmc_expected_state}  ${retry_time}=15 min
    ...  ${retry_interval}=45 sec

    # Description of argument(s):
    # OBMC_expected_state      The OBMC state which is required for test.
    # retry_time               Total wait time after executing the command.
    # retry_interval           Time interval for to keep checking with in the
    #                          above total wait time.

    Wait Until Keyword Succeeds  ${retry_time}  ${retry_interval}
    ...  Wait Until Element Contains  ${xpath_select_server_power}
    ...  ${obmc_expected_state}
    Wait Until Keyword Succeeds  ${retry_time}  ${retry_interval}
    ...  Verify OpenBMC State From REST Interface  ${obmc_expected_state}

Verify OpenBMC State From REST Interface
    [Documentation]  Verify system state from REST Interface.
    [Arguments]  ${obmc_required_state}

    # Description of argument(s):
    # obmc_required_state      The OBMC state which is required for test.

    ${obmc_current_state_REST}=  Get Host State
    Should Be Equal  ${obmc_current_state_REST}  ${obmc_required_state}

Click Yes Button
    [Documentation]  Click the 'Yes' button.
    [Arguments]  ${xpath_button_yes}

    # Description of argument(s):
    # xpath_button_yes      The xpath of 'Yes' button.

    Click Button  ${xpath_button_yes}

LogOut OpenBMC GUI
    [Documentation]  Log out of OpenBMC GUI.
    SSHLibrary.Close All Connections
    # Passing direct id element "header" as an argument to Click Element.
    Click Element  ${xpath_button_logout}
    Wait Until Page Contains Element  ${xpath_button_login}

Test Teardown Execution
    [Documentation]  Do final closure activities of test case execution.
    Print Pgm Footer
    Print Dashes  0  100  1  =
    Close Browser


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

    [Return]  ${browser_ID}


Controller Server Power Click Button
    [Documentation]  Click main server power in the header section.
    [Arguments]  ${controller_element}

    # Description of argument(s):
    # controller_element  Server power controller element
    #                     (e.g. power__power-on.)

    Click Element  ${xpath_select_server_power}
    Wait Until Element Is Visible  ${controller_element}
    Page Should Contain Button  ${controller_element}
    Click Element  ${controller_element}


GUI Power On
    [Documentation]  Power on the host using GUI.

    Controller Server Power Click Button  power__power-on
    Wait Until Page Contains  Running   timeout=30s

Verify Display Content
    [Documentation]  Verify text content display.
    [Arguments]  ${display_text}

    # Description of argument(s):
    # display_text   The text which is expected to be found on the web page.

    Page Should Contain  ${display_text}


Verify Warning Message Display Text
    [Documentation]  Verify the warning message display text.
    [Arguments]  ${xpath_text_message}  ${text_message}

    # xpath_text_message  Xpath of warning message display.
    # text_message        Content of the display message info.

    Element Should Contain  ${xpath_text_message}  ${text_message}


Expected Initial Test State
    [Documentation]  Power on the host if "Running" expected, Power off the
    ...  host if "Off" expected as per the requirement of initial test state.
    [Arguments]  ${expectedState}
    # Description of argument(s):
    # expectedState    Test initial host state.

    Run Keyword If  '${expectedState}' == 'Running'
    ...  REST Power On  stack_mode=skip  quiet=1

    Run Keyword If  '${expectedState}' == 'Off'
    ...  REST Power Off  stack_mode=skip  quiet=1

Launch Browser And Login OpenBMC GUI
    [Documentation]  Launch browser and log into openbmc GUI.

    Open Browser With URL  ${obmc_gui_url}
    Login OpenBMC GUI  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

Logout And Close Browser
    [Documentation]  Logout from openbmc application and close the browser.

    Click Element  //*[text()='Log out']
    Close Browser
