*** Settings ***
Documentation     Test to collect SOL Logs.

Resource          ../lib/utils.robot

*** Variables ***

*** Test Cases ***
Collect SOL
    [Tags]    open-power
    [Documentation]   Collect SOL Logs.
    Collect SOL Log

*** Keywords ***

