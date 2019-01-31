*** Settings ***

Library  XvfbRobot
Library  OperatingSystem
Library  Selenium2Library  120  120
Library  Telnet  30 Seconds
Library  Screenshot

Resource  resource.robot

*** Keywords ***

Open Browser With URL
    [Documentation]  Opens browser with specified URL.
    [Arguments]  ${URL}
    Start Virtual Display  1920  1080
    ${browser_ID}=  Open Browser  ${URL}
    Set Window Size  1920  1080
    [Return]  browser_ID

Break Firewall
    [Documentation]  Break firewall.
    [Arguments]  ${HOST}  ${HOST_USERNAME}  ${HOST_PASSWORD}
    ${status}  ${value}=  Run Keyword And Ignore Error  Telnet.Open Connection
    ...         ${HOST}  prompt=#
    Run Keyword If  '${status}'=='PASS'  Telnet.Login  ${HOST_USERNAME}
    ...  ${HOST_PASSWORD}  login_prompt=Username:  password_prompt=Password:

Login To GUI
    [Documentation]  Log into web GUI.
    [Arguments]  ${URL}  ${xpath_uname}  ${username}
    ...  ${xpath_password}  ${password}  ${xpath_signin}  ${logo}
    Go To  ${URL}
    Input Text  ${xpath_uname}  ${username}
    Input Password  ${xpath_password}  ${password}
    Click Button  ${xpath_signin}
    Wait Until Page Contains Element  ${logo}
