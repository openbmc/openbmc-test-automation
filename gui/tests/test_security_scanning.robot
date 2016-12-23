*** Settings ***

Documentation     Runs security & vulnerability scan.

Variables         data/variables.py

Library  XML
Library  String
Library  Collections
Library  DateTime
Library  XvfbRobot
Library  OperatingSystem
Library  Selenium2Library  120  120
Library  Telnet    30 Seconds
Library  Screenshot
Test Setup  Suite_Setup

Resource  ../lib/utils.robot

*** Test Cases ***

Nessus Scan
    [Documentation]  Run nessus network & vulnerability scan.
    [Tags]           security_scan
    Log  ${NESSUS_URL}
    Open Browser with URL  ${NESSUS_URL}
    Login to GUI  ${NESSUS_URL}  ${xpath_uname}  ${username}
    ...  ${xpath_password}  ${password}  ${xpath_signin}  ${nessus_logo}
    Select Full Scan
    Start Scan

*** Keywords ***

Suite_Setup
    [Documentation]  Breaks firewall & generate URL.
    Break Firewall  ${Nessus_IP}  ${UNAME}  ${PASSWD}
    ${NESSUS_URL}=  Set Variable  https://${Nessus_IP}:8834/nessus6.html
    Set Suite Variable  ${NESSUS_URL}

Select Full Scan
    [Documentation]  Seacrh OP full scan.
    Input Text       ${xpath_search}  ${scan_name}
    Capture Page Screenshot
    Click Element    ${xpath_op_scan}

Start Scan
    [Documentation]  Start Nessus scan.
    Click Element    ${xpath_launch}
    Click Element    ${xpath_default}
    Wait Until Page Contains  running  error=Scanning not started.
    Capture Page Screenshot
