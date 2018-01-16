*** Settings ***
Documentation  This is a resource file of OpenBMC ASMI It contains the
...            user-defined keywords which are available to all gui modules

Library      String
Library      Collections
Library      DateTime
Library      XvfbRobot
Library      OperatingSystem
Library      Selenium2Library  120  120
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
${openbmc_gui_url}    http://localhost:8080/#/login
# Default Browser.
${default_browser}  chrome

${OBMC_PowerOff_state}       Off
${OBMC_PowerRunning_state}   Running
${OBMC_PowerQuiesced_state}  Quiesced

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
    [Documentation]  Open the browse with the URL and login on windows platform.
    ${BROWSER_ID}=  Open Browser  ${openbmc_gui_url}  ${default_browser}
    Maximize Browser Window
    Set Global Variable  ${BROWSER_ID}

Launch Headless Browser
    [Documentation]  Launch headless browser.
    Start Virtual Display  1920  1080
    ${BROWSER_ID}=  Open Browser  ${openbmc_gui_url}
    Set Global Variable  ${BROWSER_ID}
    Set Window Size  1920  1080

Test Setup Execution
    [Arguments]  ${OBMC_test_setup_state}=NONE
    [Documentation]  Verify all the preconditions to be tested.
    # Description of argument(s):
    # OBMC_test_setup      The OpenBMC required state.

    Rprint Timen  ${TEST NAME} ==> [STARTED]
    Login OpenBMC GUI
    Log To Console  Verifying the system state and stablity...
    ${OBMC_current_state}=  Get Text  ${xpath_display_server_power_status}
    Rpvars  OBMC_current_state
    ${OBMC_state}=  Run Keyword And Return Status
    ...  Should Contain  ${OBMC_current_state}  ${OBMC_test_setup_state}
    Return From Keyword If  '${OBMC_state}' == 'True'
    ${OBMC_Quiesced_state}=  Run Keyword And Return Status
    ...  Should Contain  ${OBMC_current_state}  ${OBMC_Quiesced_state}
    Run Keyword If  '${OBMC_Quiesced_state}' == 'True'  Reboot OpenBMC
    Run Keyword If  '${OBMC_test_setup_state}' == '${OBMC_PowerRunning_state}'
    ...  Power On OpenBMC
    Run Keyword If  '${OBMC_test_setup_state}' == '${OBMC_PowerOff_state}'
    ...  Power Off OpenBMC

Login OpenBMC GUI
    [Documentation]  Perform login to open BMC GUI.
    [Arguments]  ${username}=${OPENBMC_USERNAME}
    ...  ${password}=${OPENBMC_PASSWORD}
    # Description of argument(s):
    # username      The username.
    # password      The password.

    Go To  ${obmc_gui_url}
    Input Text  ${xpath_textbox_hostname}  ${OPENBMC_HOST_NAME}
    Input Text  ${xpath_textbox_username}  ${username}
    Input Password  ${xpath_textbox_password}  ${password}
    Click Button  ${xpath_button_login}
    Wait Until Element Is Enabled  ${xpath_button_logout}


Power Off OpenBMC
    [Documentation]  Powering off the OBMC system.

    Log To Console  Powering Off OpenBMC...
    Click Element  ${xpath_display_server_power_status}
    Execute JavaScript  window.scrollTo(0, document.body.scrollHeight)
    Click Button  ${xpath_select_button_orderly_power_shutdown}
    Click Yes Button  ${xpath_select_button_orderly_power_shutdown_yes}
    Wait OpenBMC To Become Stable  ${string_OBMC_off}

Power On OpenBMC
    [Documentation]  Powering on the OBMC system.

    Log To Console  Powering On OpenBMC...
    Click Element  ${xpath_display_server_power_status}
    Click Button  ${xpath_select_button_power_on }
    Wait OpenBMC To Become Stable  ${string_OBMC_running}

Reboot OpenBMC
    [Documentation]  Rebooting the OBMC system.

    Log To Console  Reboting the OpenBMC...
    Click Element  ${xpath_display_server_power_status}
    Click Button  ${xpath_select_button_orderly_power_shutdown}
    Click Yes Button  ${xpath_select_button_orderly_power_shutdown_yes}
    Wait OpenBMC To Become Stable  ${string_OBMC_off}

Wait OpenBMC To Become Stable
    [Documentation]  Powering off the OBMC
    [Arguments]  ${OBMC_expected_state}=  ${retry_time}=5 min
    ...  ${retry_interval}=45 sec
    # Description of argument(s):
    # OBMC_expected_state      The OBMC state which is required for test.
    # retry_time               Total wait time after executing the command.
    # retry_interval           Time interval for to keep checking with in the
    #                          above total wait time.

    Wait Until Keyword Succeeds  ${retry_time}  ${retry_interval}
    ...  Wait Until Element Contains  ${xpath_display_server_power_status}
    ...  ${OBMC_expected_state}
    Wait Until Keyword Succeeds  ${retry_time}  ${retry_interval}
    ...  Verify OpenOBMC State From REST Interface  ${OBMC_expected_state}

Verify OpenOBMC State From REST Interface
    [Documentation]  Verify system state from REST Interface
    [Arguments]  ${OBMC_requried_state}=
    # Description of argument(s):
    # OBMC_requried_state      The OBMC state which is required for test.

    ${OBMC_current_state_REST}=  Get Host State
    Should Be Equal  ${OBMC_current_state_REST}  ${OBMC_requried_state}

Click Yes Button
    [Documentation]  Will select button 'Yes" Option.
    [Arguments]  ${xpath_button_yes}=
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
