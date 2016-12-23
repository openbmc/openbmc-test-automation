*** Settings ***

Library  OperatingSystem

*** Keywords ***

Open browser with URL
    [Documentation]  Opens browser with specified URL.
    [Arguments]  ${URL}
    Start Virtual Display  1920  1080
    ${BrowserID}=  Open Browser  ${URL}
    Set Global Variable  ${BrowserID}
    Set Window Size  1920  1080

Break Firewall
    [Documentation]  Break Manayata D2 firewall.
    [Arguments]      ${System_IP}  ${UNAME}  ${PASSWD}
    Run Keyword And Ignore Error  Telnet.Open Connection  ${System_IP}  prompt=#
    Run Keyword And Ignore Error  Telnet.Login  ${UNAME}  ${PASSWD}
    ...                           login_prompt=Username:  password_prompt=Password:

Login to GUI
    [Documentation]  Logs into Web GUI.
    [Arguments]      ${URL}  ${xpath_uname}  ${username}
    ...  ${xpath_password}  ${password}  ${xpath_signin}  ${logo}
    Go To            ${URL}
    Input Text       ${xpath_uname}  ${username}
    Input Password   ${xpath_password}  ${password}
    Capture Page Screenshot
    Click Button     ${xpath_signin}
    Capture Page Screenshot
    Wait Until Page Contains Element  ${logo}
