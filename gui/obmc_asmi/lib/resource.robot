*** Settings ***
Documentation  This is a resource file of OpenBMC ASMI
...  It contains the user defined keywords
...  and which are access to all gui modules

Library    String
Library    Collections
Library    DateTime
Library    XvfbRobot
Library    OperatingSystem
Library    Selenium2Library  120  120
Library    AngularJSLibrary
Library    SSHLibrary  30 Seconds
Library    Process
Library    supporting_libs.py
Library    ../../../lib/gen_print.py
Library    ../../../lib/gen_robot_print.py
Library    ../../../lib/gen_valid.py
Library    ../../../lib/gen_robot_ssh.py
Library    ../../../lib/bmc_ssh_utils.py
Resource   ../../../lib/resource.txt
Variables  ../data/resource_variables.py

*** Variables ***
# TO Do: Need to change the varilabe once the code
# finally switches to the BMC.
${obmc_gui_url}  https://openbmc-test.mybluemix.net/#/login
# Default Browser.
${default_browser}  chrome

*** Keywords ***
Launch OpenBMC ASMi Browser
    [Documentation]  Launch the OpenBMC ASMi URL on a browser.
    ...  By default uses headless mode else the GUI browser.
    ${op_system}=  Get Operating System
    Run Keyword If  '${op_system}' == 'windows'
    ...  Launch Browser in Windows Platform
    ...  ELSE  Launch Headless Browser

Get Operating System
    [Documentation]  Identify platform/OS
    ${curdir_lower_case}=  Convert To Lowercase  ${CURDIR}
    ${windows_platform}=  Run Keyword And Return Status
    ...  Should Contain  ${curdir_lower_case}  c:\
    Run Keyword If  ${windows_platform}==True
    ...   Set Suite Variable  ${op_system}  windows
    ...   ELSE  Set Suite Variable  ${op_system}  linux
    [Return]  ${op_system}

Launch Browser in Windows Platform
    [Documentation]  Open the browser with the URL and
    ...  login with credential on windows platform.
    ${BrowserID}=  Open Browser
    ...  ${obmc_gui_url}  ${default_browser}
    Maximize Browser Window
    Set Global Variable  ${BROWSER_ID}

Launch Headless Browser
    [Documentation]  Launch headless browser.
    Start Virtual Display  1920  1080
    ${BrowserID}=  Open Browser  ${obmc_gui_url}
    Set Global Variable  ${BrowserID}
    Set Window Size  1920  1080

OpenBMC Test Setup
    [Documentation]  Verify all the preconditions to be tested.
    ${test_start}=  Catenate
    ...  ${TEST NAME}:${TESTDOCUMENTATION}  ==>  [STARTED]
    ${TC_TIME_START}=  Get Current Date
    ...  result_format=%Y-%m-%d %H:%M:%S,%f
    Set Global Variable  ${TC_TIME_START}
    Log To Console  ${EMPTY}
    Print Dashes  0  100  1  =
    Log To Console  ${TC_TIME_START} ${test_start}
    Login OpenBMC GUI

Login OpenBMC GUI
    [Documentation]  Perform login.
    [Arguments]  ${username}=${OPENBMC_USERNAME}
    ...  ${password}=${OPENBMC_PASSWORD}
    Go To  ${obmc_gui_url}
    Input Text  ${xpath_textbox_username}
    ...  ${username}
    Input Password  ${xpath_textbox_password}
    ...  ${password}
    Click Button  ${xpath_button_login}
    Wait Until Element Is Enabled  ${xpath_button_logout}

Get SSH Connection
    [Documentation]  Establish the SSH connection.
    [Arguments]  ${ip}=${OPENBMC_HOST_NAME}
    ...  ${username}=${OPENBMC_USERNAME}
    ...  ${passwd}=${OPENBMC_PASSWORD}
    SSHLibrary.Open Connection  ${ip}
    SSHLibrary.Login  ${username}  ${passwd}

LogOut OpenBMC GUI
    [Documentation]  Log out OpenBMC ASMi GUI.
    SSHLibrary.Close All Connections
    click button  ${xpath_button_logout}
    Wait Until Page Contains Element  ${xpath_button_login}

OpenBMC Test Closure
    [Documentation]  Do final closure activities of test case execution.
    ${test_end}=  Catenate
    ...  ${TEST NAME}:${TESTDOCUMENTATION}  ==>  [${TEST STATUS}ED]
    ${time_end}=  Get Current Date
    ...  result_format=%Y-%m-%d %H:%M:%S,%f
    ${time_diff}=  Subtract Date From Date
    ...  ${time_end}  ${TC_TIME_START}
    Log To Console  ${time_end} ${test_end}[Execution Time: ${time_diff} secs]
    Print Dashes  0  100  1  =
    LogOut OpenBMC GUI

