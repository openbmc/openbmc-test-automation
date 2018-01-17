*** Settings ***
Documentation  This is a resource file of OpenBMC ASMI It contains the
...            user-defined keywords which are available to all gui modules

Library      String
Library      Collections
Library      DateTime
Library      XvfbRobot
Library      OperatingSystem
Library      Selenium2Library  120  120  run_on_failure=Capture Page Screenshot
Library      AngularJSLibrary
Library      SSHLibrary  30 Seconds
Library      Process
Library      supporting_libs.py
Library      ../../../lib/gen_print.py
Library      ../../../lib/gen_robot_print.py
Library      ../../../lib/gen_valid.py
Library      ../../../lib/gen_robot_ssh.py
Library      ../../../lib/bmc_ssh_utils.py
Resource     ../../../lib/resource.txt
Resource     ../../../lib/rest_client.robot
Resource     ../../../lib/state_manager.robot
Variables    ../data/resource_variables.py

*** Variables ***
${openbmc_gui_url}  http://localhost:8080/#/login
# Default Browser.
${default_browser}  chrome

${obmc_PowerOff_state}  Off
${obmc_PowerRunning_state}  Running
${obmc_PowerQuiesced_state} Quiesced

*** Keywords ***
Launch OpenBMC GUI Browser
    [Documentation]  Launch the OpenBMC GUI URL on a browser.
    # By default uses headless mode, otherwise, the GUI browser.

    ${op_system}=  Get Operating System
    Run Keyword If  '${op_system}' == 'windows'
    ...     Launch Browser in Windows Platform
    ...  ELSE
    ...     Launch Headless Browser

Get Operating System
    [Documentation]  Identify platform/OS.

    ${curdir_lower_case}=  Convert To Lowercase  ${CURDIR}
    ${windows_platform}=  Run Keyword And Return Status
    ...  Should Contain  ${curdir_lower_case}  c:\
    ${op_system}=  Run Keyword If  '${windows_platform}' == 'True'
    ...     Set Variable  windows
    ...   ELSE
    ...     Set Variable  linux
    [Return]  ${op_system}

Launch Browser in Windows Platform
    [Documentation]  Open the browser with the URL and
    ...              login on windows platform.

    ${BROWSER_ID}=  Open Browser  ${openbmc_gui_url}  ${default_browser}
    Maximize Browser Window
    Set Global Variable  ${BROWSER_ID}

Launch Headless Browser
    [Documentation]  Launch headless browser.

    Start Virtual Display  1920  1080
    ${BROWSER_ID}=  Open Browser  ${openbmc_gui_url}
    Set Global Variable  ${BROWSER_ID}
    Set Window Size  1920  1080

Login OpenBMC GUI
    [Documentation]  Perform login to open BMC GUI.
    [Arguments]  ${username}=${OPENBMC_USERNAME}
    ...  ${password}=${OPENBMC_PASSWORD}
    # Description of argument(s):
    # username      The username.
    # password      The password.

    Go To  ${openbmc_gui_url}
    Input Text  ${xpath_textbox_hostname}  ${OPENBMC_HOST}
    Input Text  ${xpath_textbox_username}  ${username}
    Input Password  ${xpath_textbox_password}  ${password}
    Click Element  login__submit
    Wait Until Element Is Enabled  ${xpath_button_logout}
    Page Should Contain  Server information


Test Setup Execution
    [Documentation]  Verify all the preconditions to be tested.
    [Arguments]  ${obmc_test_setup_state}=NONE
    # Description of argument(s):
    # obmc_test_setup      The OpenBMC required state.

    Rprint Timen  ${TEST NAME} ==> [STARTED]
    Login OpenBMC GUI
    Log To Console  Verifying the system state and stablity...
    ${obmc_current_state}=  Get Text  ${xpath_display_server_power_status}
    Rpvars  obmc_current_state
    ${obmc_state}=  Run Keyword And Return Status
    ...  Should Contain  ${obmc_current_state}  ${obmc_test_setup_state}
    Return From Keyword If  '${obmc_state}' == 'True'
    ${obmc_quiesced_state}=  Run Keyword And Return Status
    ...  Should Contain  ${obmc_current_state}  ${obmc_quiesced_state}
    Run Keyword If  '${obmc_quiesced_state}' == 'True'  Reboot OpenBMC
    Run Keyword If  '${obmc_test_setup_state}' == '${obmc_PowerRunning_state}'
    ...  Power On OpenBMC
    Run Keyword If  '${obmc_test_setup_state}' == '${obmc_PowerOff_state}'
    ...  Power Off OpenBMC

Power Off OpenBMC
    [Documentation]  Power off the OBMC system.

    Log To Console  Power Off OpenBMC...
    Click Element  ${xpath_display_server_power_status}
    Execute JavaScript  window.scrollTo(0, document.body.scrollHeight)
    Click Button  ${xpath_select_button_orderly_power_shutdown}
    Click Yes Button  ${xpath_select_button_orderly_power_shutdown_yes}
    Wait OpenBMC To Become Stable  ${obmc_off_state}

Power On OpenBMC
    [Documentation]  Power on the OBMC system.

    Log To Console  Power On OpenBMC...
    Click Element  ${xpath_display_server_power_status}
    Click Button  ${xpath_select_button_power_on }
    Wait OpenBMC To Become Stable  ${obmc_running_state}

Reboot OpenBMC
    [Documentation]  Rebooting the OBMC system.

    Log To Console  Reboting the OpenBMC...
    Click Element  ${xpath_display_server_power_status}
    Click Button  ${xpath_select_button_orderly_power_shutdown}
    Click Yes Button  ${xpath_select_button_orderly_power_shutdown_yes}
    Wait OpenBMC To Become Stable  ${obmc_off_state}

Wait OpenBMC To Become Stable
    [Documentation]  Power off the OBMC.
    [Arguments]  ${OBMC_expected_state}  ${retry_time}=5 min
    ...  ${retry_interval}=45 sec
    # Description of argument(s):
    # OBMC_expected_state      The OBMC state which is required for test.
    # retry_time               Total wait time after executing the command.
    # retry_interval           Time interval for to keep checking with in the
    #                          above total wait time.

    Wait Until Keyword Succeeds  ${retry_time}  ${retry_interval}
    ...  Wait Until Element Contains  ${xpath_display_server_power_status}
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
    [Documentation]  Click the 'yes' button.
    [Arguments]  ${xpath_button_yes}
    # Description of argument(s):
    # xpath_button_yes      The xpath of 'yes' button.

    Click Button  ${xpath_button_yes}

LogOut OpenBMC GUI
    [Documentation]  Log out of OpenBMC GUI.
    SSHLibrary.Close All Connections
    click button  ${xpath_button_logout}
    Wait Until Page Contains Element  ${xpath_button_login}

Test Teardown Execution
    [Documentation]  Do final closure activities of test case execution.
    Rprint Pgm Footer
    Print Dashes  0  100  1  =
    LogOut OpenBMC GUI

Open Browser With URL
    [Documentation]  Open browser with specified URL and returns browser id.
    [Arguments]  ${URL}  ${browser}=gc
    # Description of argument(s):
    # URL      Openbmc GUI URL to be open
    #          (e.g. https://openbmc-test.mybluemix.net/#/login )
    # browser  browser used to open above URL
    #          (e.g. gc for google chrome, ff for firefox)
    ${browser_ID}=  Open Browser  ${URL}  ${browser}
    [Return]  ${browser_ID}

Model Server Power Click Button
    [Documentation]  Click main server power in the header section.
    [Arguments]  ${div_element}  ${anchor_element}
    # Description of argument(s):
    # div_element     Server power header divisional element
    #                 (e.g. header_wrapper.)
    # anchor_element  Server power header anchor element
    #                 (e.g. header_wrapper_elt.)
    Wait Until Element Is Visible
    ...  //*[@id='header__wrapper']/div/div[${div_element}]/a[${anchor_element}]/span
    Click Element
    ...  //*[@id='header__wrapper']/div/div[${div_element}]/a[${anchor_element}]/span

Controller Server Power Click Button
    [Documentation]  Click main server power in the header section.
    [Arguments]  ${controller_element}
    # Description of argument(s):
    # controller_element  Server power controller element
    #                     (e.g. power__power-on.)

    Wait Until Element Is Visible  ${controller_element}
    Page Should Contain Button  ${controller_element}
    Click Element  ${controller_element}

Controller Power Operations Confirmation Click Button
    [Documentation]  Click Common Power Operations Confirmation.
    [Arguments]  ${main_element}  ${sub_element}  ${confirm_msg_elt}  ${confirmation}
    # Description of argument(s):
    # main_element     Server power operations element
    #                  (e.g. power_operations.)
    # sub_element      Server power operations sub element
    #                  (e.g. warm_boot, shut_down.)
    # confirm_msg_elt  Server power operations confirm message element
    #                  (e.g. confirm_msg.)
    # confirmation     Server power operations confirmation
    #                  (e.g. yes.)

    Click Element
    ...  //*[@id='power-operations']/div[${main_element}]/div[${sub_element}]/confirm/div/div[${confirm_msg_elt}]/button[${confirmation}]

GUI Power On
    [Documentation]  Power on the Host using GUI.

    Model Server Power Click Button  ${header_wrapper}  ${header_wrapper_elt}
    Page Should Contain  Attempts to power on the server
    Controller Server Power Click Button  power__power-on
    Page Should Contain  Running

