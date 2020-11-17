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

${CMD_INTERNAL_FAILURE}      busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging
...  xyz.openbmc_project.Logging.Create Create ssa{ss} xyz.openbmc_project.Common.Error.InternalFailure
...  xyz.openbmc_project.Logging.Entry.Level.Error 0

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

    [Return]  ${browser_ID}

Launch Browser And Login GUI
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
    Wait Until Element Is Enabled  ${xpath_textbox_username}
    Input Text  ${xpath_textbox_username}  ${username}
    Input Password  ${xpath_textbox_password}  ${password}
    Click Element  ${xpath_login_button}
    Wait Until Page Contains  Overview  timeout=30s


Logout GUI
    [Documentation]  Logout of OpenBMC GUI.

    Click Element  ${xpath_logout_button}
    Wait Until Page Contains Element  ${xpath_login_button}


Generate Test Error Log
    [Documentation]  Generate test error log.

    BMC Execute Command  ${CMD_INTERNAL_FAILURE}
