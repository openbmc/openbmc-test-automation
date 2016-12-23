*** Settings ***

Library  XvfbRobot
Library  OperatingSystem
Library  Selenium2Library  120  120
Library  Telnet  30 Seconds

Resource  resource.txt 

*** Keywords ***

Open Browser With URL
    [Documentation]  Opens browser with specified URL.
    [Arguments]  ${URL}
    Start Virtual Display  1920  1080
    ${BrowserID}=  Open Browser  ${URL}
    Set Window Size  1920  1080

Break Firewall
    [Documentation]  Break firewall.
    [Arguments]  ${HOST_IP}  ${HOST_USERNAME}  ${HOST_PASSWORD}
    Run Keyword And Ignore Error  Telnet.Open Connection  ${System_IP}  prompt=#
    Run Keyword And Ignore Error  Telnet.Login  ${UNAME}  ${PASSWD}
    ...                           login_prompt=Username:  password_prompt=Password:

Login To GUI
    [Documentation]  Logs into Web GUI.
    [Arguments]  ${URL}  ${xpath_uname}  ${username}
    ...  ${xpath_password}  ${password}  ${xpath_signin}  ${logo}
    Go To  ${URL}
    Input Text  ${xpath_uname}  ${username}
    Input Password  ${xpath_password}  ${password}
    Click Button  ${xpath_signin}
    Wait Until Page Contains Element  ${logo}
