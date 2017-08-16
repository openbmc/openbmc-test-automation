*** Settings ***
Documentation  This is a resource file of OpenBMC ASMI
...  It contains the user defined keywords
...  and which are access to all gui modules

Library  String
Library  Collections
Library  DateTime
Library  XvfbRobot
Library  OperatingSystem
Library  Selenium2Library  120  120
Library  AngularJSLibrary
Library  SSHLibrary  30 Seconds
Library  Process
Library  supporting_libs.py
Library  ${EXECDIR}${/}..${/}lib/gen_print.py
Library  ${EXECDIR}${/}..${/}lib/gen_robot_print.py
Variables  ${EXECDIR}${/}obmc_asmi/data/resource_variables.py

*** Keywords ***
Launch OpenBMC ASMi Browser
    [Documentation]  Launch the OpenBMC ASMi URL on a browser.
    ...  By default uses headless mode else the GUI browser.
    ${l_CurDirLowerCase}  Convert To Lowercase  ${CURDIR}
    ${l_WindowsPlatform}  Run Keyword And Return Status
    ...  Should Contain  ${l_CurDirLowerCase}  c:\
    Run Keyword If  ${l_WindowsPlatform}==True
    ...  Launch Browser in Windows Platform
    ...  ELSE  Launch Headless Browser

Launch Browser in Windows Platform
    [Documentation]  Open the browser with the URL and
    ...  login with credential on windows platform.
    ${BrowserID}=  Open Browser
    ...  ${OBMC_ASMi_BLUEMIX_URL}  ${BROWSER}
    Maximize Browser Window
    Set Global Variable  ${BROWSER_ID}

Launch Headless Browser
    [Documentation]  Launch headless browser.
    Start Virtual Display  1920  1080
    ${BrowserID}=  Open Browser  ${OBMC_ASMi_BLUEMIX_URL}
    Set Global Variable  ${BrowserID}
    Set Window Size  1920  1080

OpenBMC Test Setup
    [Documentation]  Verify all the preconditions to be tested.
    ${l_TestStart}=  Catenate
    ...  ${TEST NAME}:${TESTDOCUMENTATION}  ==>  [STARTED]
    ${TC_TIME_START}=  Get Current Date
    ...  result_format=%Y-%m-%d %H:%M:%S,%f
    Set Global Variable  ${TC_TIME_START}
    Log To Console  ${EMPTY}
    Print Dashes  0  100  1  =
    Log To Console  ${TC_TIME_START} ${l_TestStart}
    Login OpenBMC GUI

Login OpenBMC GUI
    [Documentation]  Perform login.
    [Arguments]  ${i_username}=${OPENBMC_USERNAME}
    ...  ${i_password}=${OPENBMC_PASSWORD}
    Go To  ${OBMC_ASMi_BLUEMIX_URL}
    Input Text  ${xpath_TXTBX_INPUT_USERNAME}
    ...  ${i_username}
    Input Password  ${xpath_TXTBX_INPUT_PASSWORD}
    ...  ${i_password}
    Click Button  ${xpath_BTN_LOGIN}
    Wait Until Element Is Enabled  ${xpath_BTN_LOGOUT}

Get SSH Connection
    [Documentation]  Establish the SSH connection.
    [Arguments]  ${l_IpAddress}=${OPENBMC_HOST_NAME}
    ...  ${i_username}=${OPENBMC_USERNAME}
    ...  ${i_passwd}=${OPENBMC_PASSWORD}
    SSHLibrary.Open Connection  ${l_IpAddress}
    SSHLibrary.Login  ${i_username}  ${i_passwd}

LogOut OpenBMC GUI
    [Documentation]  Log out OpenBMC ASMi GUI.
    SSHLibrary.Close All Connections
    click button  ${xpath_BTN_LOGOUT}
    Wait Until Page Contains Element  ${xpath_BTN_LOGIN}

OpenBMC Test Closure
    [Documentation]  Do final closure activities of test case execution.
    ${l_TestEnd}=  Catenate
    ...  ${TEST NAME}:${TESTDOCUMENTATION}  ==>  [${TEST STATUS}ED]
    ${l_TimeEnd}=  Get Current Date
    ...  result_format=%Y-%m-%d %H:%M:%S,%f
    ${l_TimeDiff}=  Subtract Date From Date
    ...  ${l_TimeEnd}  ${TC_TIME_START}
    Log To Console  ${l_TimeEnd} ${l_TestEnd}[Execution Time: ${l_TimeDiff} secs]
    Print Dashes  0  100  1  =
    LogOut OpenBMC GUI

