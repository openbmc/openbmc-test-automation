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
Variables    ../data/resource_variables.py
Resource     ../../../lib/resource.txt

*** Variables ***
# TO Do: Change the variable once the code finally switches to the OpenBMC.
${openbmc_gui_url}    http://localhost:8080/#/login
# Default Browser.
${default_browser}  chrome

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

OpenBMC Test Setup
    [Documentation]  Verify all the preconditions to be tested.
    Rprint Timen  ${TEST NAME}:${TESTDOCUMENTATION} ==> [STARTED]
    Print Dashes  0  100  1  =
    Login OpenBMC GUI

Login OpenBMC GUI
    [Documentation]  Perform login to open BMC GUI.
    [Arguments]  ${username}=${OPENBMC_USERNAME}
    ...  ${password}=${OPENBMC_PASSWORD}
    # Description of argument(s):
    # username      The username.
    # password      The password.

    Register Keyword To Run On Failure  Reload Page
    Log  ${openbmc_gui_url}
    Open Browser With URL  ${openbmc_gui_url}  gc
    Page Should Contain Button  login__submit
    #  Wait Until Page Contains Element  ${obmc_uname}
    Input Text  ${xpath_bmc_ip}  ${OPENBMC_HOST}
    Input Text  ${xpath_textbox_username}  ${username}
    Input Password  ${xpath_textbox_password}  ${password}
    Click Element  login__submit
    Wait Until Element Is Enabled  ${xpath_button_logout}
    Page Should Contain  Server information

LogOut OpenBMC GUI
    [Documentation]  Log out of OpenBMC GUI.
    SSHLibrary.Close All Connections
    click button  ${xpath_button_logout}
    Wait Until Page Contains Element  ${xpath_button_login}

OpenBMC Test Closure
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

