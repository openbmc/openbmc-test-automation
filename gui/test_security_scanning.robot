*** Settings ***

Documentation     Runs security & vulnerability scan.

Variables         security_variables.py

Library           XML
Library           String
Library           Collections
Library      	  DateTime
Library           XvfbRobot
Library           OperatingSystem
Library      	  Selenium2Library    120    120
Library      	  Telnet    30 Seconds
Library           Screenshot

*** Test Cases ***

Nessus Scan
    [Documentation]  Run nessus network & vulnerability scan.
    [Tags]           security_scan
    Break Firewall
    #Open Browser with URL
    ${Nessus_url}=  Catenate  https://  ${Nessus_IP}  
    ${Nessus_url}=  Catenate  ${Nessus_url}  :8834/nessus6.html
    ${Nessus_url}=  Remove String  ${Nessus_url}  ${SPACE}
    Log  ${Nessus_url}
    Open Browser with URL  ${Nessus_url}
    Login to Nessus  ${Nessus_url}
    Select Full Scan
    Start Scan

*** Keywords ***

Open Browser with URL
    [Documentation]  Logs in to Nessus tool.
    [Arguments]  ${NESSUS_URL}
    Start Virtual Display  1920  1080
    ${BrowserID}=  Open Browser  ${NESSUS_URL}
    Set Global Variable  ${BrowserID}
    Set Window Size  1920  1080

Open Browser with URL on Windows
    [Documentation]  Opens the browser in the URL and
    ...              login with credential on windows platform.
    ${BrowserID} =   Open Browser  ${NESSUS_URL}  ${BROWSER}
    Maximize Browser Window
    Set Global Variable  ${BrowserID}

Login to Nessus
    [Documentation]  Logs into Nessus tool.
    [Arguments]      ${NESSUS_URL}
    Go To            ${NESSUS_URL}
    Input Text       ${xpath_uname}  ${username}
    Input Password   ${xpath_password}  ${password}
    Capture Page Screenshot
    Click Button     ${xpath_signin}
    Capture Page Screenshot
    Wait Until Page Contains Element  ${nessus_logo}

Select Full Scan
    [Documentation]  Seacrh OP full scan.
    Input Text       ${xpath_search}  ${scan_name}
    Capture Page Screenshot
    Click Element    ${xpath_op_scan}

Start Scan
    [Documentation]  Start Nessus scan.
    Click Element    ${xpath_launch}
    Click Element    ${xpath_default}
    Capture Page Screenshot
    Sleep  2
    Wait Until Page Does Not Contain Element  ${xpath_default}
    Capture Page Screenshot

Break Firewall
    [Documentation]  Break Manayata D2 firewall.
    Run Keyword And Ignore Error  Telnet.Open Connection  ${Nessus_IP}  prompt=#
    Run Keyword And Ignore Error  Telnet.Login  ${UNAME}  ${PASSWD}
    ...                           login_prompt=Username:  password_prompt=Password:
