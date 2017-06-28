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
Library  SSHLibrary    30 Seconds
Library  Process
Library  Supporting_Libs.py
Variables  OBMC_Commands_Constants.py
Variables  Resource_Variables.py

*** Keywords ***

Open Browser with mybluemix.net URL
    [Documentation]  Opens the browser in the URL
    ...  By default uses headless mode else the GUI browser.
    ${l_CurDirLowerCase}  Convert To Lowercase  ${CURDIR}
    ${l_WindowsPlatform}  Run Keyword And Return Status
    ...                   Should Contain  ${l_CurDirLowerCase}  c:\
    Run Keyword If  ${l_WindowsPlatform}==True
    ...             Launch Browser in Windows Platform
    ...  ELSE       Launch Headless Browser

Launch Browser in Windows Platform
    [Documentation]  Opens the browser in the URL and
    ...  login with credential on windows platform.
    ${BrowserID}=  Open Browser
    ...  ${OBMC_ASMi_BLUEMIX_URL}    ${BROWSER}
    Maximize Browser Window
    Set Global Variable  ${BrowserID}

Launch Headless Browser
    [Documentation]  Launches the headless browser.
    Start Virtual Display  1920  1080
    ${BrowserID}=  Open Browser  ${OBMC_ASMi_BLUEMIX_URL}
    Set Global Variable  ${BrowserID}
    Set Window Size  1920  1080

OpenBMC Test Setup
    [Documentation]  Verifies all the preconditions to be tested.
    ${l_TestStart}=  Catenate
    ...  ${TEST NAME}:${TESTDOCUMENTATION}  ==>  [STARTED]
    ${l_TimeStart}=  Get Current Date
    ...  result_format=%Y-%m-%d %H:%M:%S,%f
    Set Global Variable  ${l_TimeStart}
    Log To Console  ${EMPTY}
    Log To Console  ${PRINT_DOUBLE_LINE}
    Log To Console  ${l_TimeStart} ${l_TestStart}
    Login OpenBMC GUI

Login OpenBMC GUI
    [Documentation]  Performs login.
    [Arguments]  ${i_UserId}=${OBMC_ROOT_ID}
    ...  ${i_Password}=${OBMC_ROOT_PASSWORD}
    Go To  ${OBMC_ASMi_BLUEMIX_URL}
    Input Text  ${xpath_TXTBX_USERID_INPUT}
    ...  ${i_UserId}
    Input Password  ${xpath_TXTBX_PWD_INPUT}
    ...  ${i_Password}
    Click Button  ${xpath_BTN_LOGIN}
    Wait Until Element Is Enabled  ${xpath_BTN_LOGOUT}

Get SSH Connection
    [Documentation]  Establish the SSH connection.
    [Arguments]  ${l_IpAddress}=${OBMC_HOST_NAME}    ${i_UserID}=${OBMC_ROOT_ID}
    ...   ${i_Passwd}=${OBMC_ROOT_PASSWORD}
    SSHLibrary.Open Connection  ${l_IpAddress}
    SSHLibrary.Login  ${i_UserID}  ${i_Passwd}

LogOut OpenBMC GUI
    [Documentation]  This keyword just logs out the OpenBMC ASMi GUI.
    SSHLibrary.Close All Connections
    click button  ${xpath_BTN_LOGOUT}
    Wait Until Page Contains Element  ${xpath_BTN_LOGIN}

OpenBMC Test Closure
    [Documentation]  To be called as test teardown which does the closure
    ...  activities.
    ${l_TestEnd}  Catenate
    ...  ${TEST NAME}:${TESTDOCUMENTATION}  ==>  [${TEST STATUS}ED]
    ${l_TimeEnd}=  Get Current Date
    ...  result_format=%Y-%m-%d %H:%M:%S,%f
    ${l_TimeDiff}=  Subtract Date From Date
    ...  ${l_TimeEnd}  ${l_TimeStart}
    Log To Console  ${l_TimeEnd} ${l_TestEnd}[Execution Time: ${l_TimeDiff} secs]
    Log To Console  ${PRINT_DOUBLE_LINE}
    LogOut OpenBMC GUI
