*** Settings ***

Documentation  Run security and vulnerability scan.

Library  XML
Library  String
Library  Collections
Library  DateTime

Test Setup  Security Setup

Resource  ../lib/utils.robot

*** Test Cases ***

Security Scan
    [Documentation]  Run nessus network and vulnerability scan.
    [Tags]  Security_Scan
    Log  ${NESSUS_URL}
    Open Browser with URL  ${NESSUS_URL}
    Login to GUI  ${NESSUS_URL}  ${xpath_uname}  ${username}
    ...  ${xpath_password}  ${password}  ${xpath_signin}  ${nessus_logo}
    Select Full Scan
    Start Scan

*** Keywords ***

Security Setup
    [Documentation]  Break firewall and generate URL.
    # Nessus Username, password and IP details are expected by program
    # and should be given as command line parameters.
    Break Firewall  ${NESSUS_HOST}  ${NESSUS_USERNAME}  ${NESSUS_PASSWORD}
    ${NESSUS_URL}=  Set Variable  https://${NESSUS_HOST}:8834/nessus6.html
    Set Suite Variable  ${NESSUS_URL}

Select Full Scan
    [Documentation]  Search OP full scan.
    Input Text  ${xpath_search}  ${scan_name}
    Capture Page Screenshot
    Click Element  ${xpath_op_scan}

Start Scan
    [Documentation]  Start Nessus scan.
    Click Element  ${xpath_launch}
    Click Element  ${xpath_default}
    Wait Until Page Contains  running  error=Scanning not started.
    Capture Page Screenshot
