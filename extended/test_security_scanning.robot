*** Settings ***
Documentation     Runs security & vulnerability scan
Library           XML
Library           String
Library           Collections
Library      	  DateTime
Library           XvfbRobot
Library           OperatingSystem
Library      	  Selenium2Library    120    120
Library      	  Telnet    30 Seconds

*** Variables ***
${BROWSER}              ff
${Nessus_IP}            9.126.171.193
${NESSUS_URL}           https://9.126.171.193:8834/nessus6.html
${nessus_logo}          xpath=//*[@id="logo"]
${running_status}       xpath=//*[@id='main']/div[1]/section/div[2]/table/tbody/tr[1]/td[4]
${username}             test
${password}             passw0rd
${xpath_exception}      id=advancedButton
${xpath_add_exce}       id="exceptionDialogButton"
${xpath_uname}          xpath=//*[@id="nosession"]/form/input[1]
${xpath_password}       xpath=//*[@id="nosession"]/form/input[2]
${xpath_signin}         xpath=//*[@id="sign-in"]
${xpath_search}         xpath=//*[@id="searchbox"]/input
${scan_name}            OP Full Scan
${xpath_op_scan}        xpath=//*[@id="main"]/div[1]/section/table/tbody
${xpath_launch}         xpath=//*[@id="scans-show-launch-dropdown"]/span
${xpath_default}        xpath=//*[@id="scans-show-launch-default"]

*** Test Cases ***
Nessus Scan
    [Documentation]        Run nessus network & vulnerability scan.
    [Tags]                 security_scan
    Break Firewall
    Open Browser with URL
    Login to Nessus
    Select Full Scan
    Start Scan

*** Keywords ***

Open Browser with URL
    [Documentation]       Logs in to Nessus tool.
    Start Virtual Display   1920   1080
    ${BrowserID}          Open Browser   ${NESSUS_URL}
    Set Global Variable      ${BrowserID}
    Set Window Size          1920    1080

Open Browser with URL on Windows
    [Documentation]    Opens the browser in the URL and
    ...                login with credential on windows platform.
    ${BrowserID} =             Open Browser    ${NESSUS_URL}    ${BROWSER}
    Maximize Browser Window
    Set Global Variable        ${BrowserID}

Login to Nessus
     [Documentation]    Logs into Nessus tool.
     Go To              ${NESSUS_URL}
     Input Text         ${xpath_uname}   ${username}
     Input Password     ${xpath_password}   ${password}
     Click Button       ${xpath_signin}
     Wait Until Page Contains Element   ${nessus_logo}

Select Full Scan
    [Documentation]    Seacrh OP full scan.
    Input Text         ${xpath_search}   ${scan_name}
    Click Element      ${xpath_op_scan}

Start Scan
    [Documentation]   Start Nessus scan.
    Click Element     ${xpath_launch}
    Click Element     ${xpath_default}
    Wait Until Page Contains Element   ${running_status}

Break Firewall
    [Documentation]    Break Manayata D2 firewall.
    Run Keyword And Ignore Error    Telnet.Open Connection   ${Nessus_IP}
    Run Keyword And Ignore Error    Telnet.Login      ${UNAME}   {PASSWD}
    ...                             login_prompt=Username:   password_prompt=Password:
