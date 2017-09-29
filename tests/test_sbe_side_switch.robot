*** Settings ***
Documentation       Test SBE side switching with watchdog errors.

Library             ../lib/utils.py
Variables           ../data/variables.py
Resource            ../lib/boot_utils.robot
Resource            ../lib/state_manager.robot

*** Test Cases ***

Test SBE Side Switch
    [Documentation]  Trigger watchdog errors on the host until it side
    ...  switches.
    [Tags]  Test_SBE_Side_Switch

    Delete All Error Logs
    Set Auto Reboot  ${1}
    REST Power On

    Start Journal Log

    ${attempts_left}=  Read Attribute  /xyz/openbmc_project/state/host0
    ...  AttemptsLeft
    Should Be Equal As Strings  ${attempts_left}  2
    Trigger Host Watchdog Error
    Wait For Host Reboot
    ${attempts_left}=  Read Attribute  /xyz/openbmc_project/state/host0
    ...  AttemptsLeft
    Should Be Equal As Strings  ${attempts_left}  1
    Trigger Host Watchdog Error
    Wait For Host Reboot
    ${attempts_left}=  Read Attribute  /xyz/openbmc_project/state/host0
    ...  AttemptsLeft
    Should Be Equal As Strings  ${attempts_left}  0

    # Verify the side switched
    ${journal_text}=  Stop Journal Log
    Should Contain  ${journal_text}  Setting SBE seeprom side to 1


*** Keywords ***

Wait For Host Reboot
    [Documentation]  Wait for the host to reboot.

    Wait Until Keyword Succeeds  60x  5s  Is Host Off
    Wait Until Keyword Succeeds  60x  5s  Is Host State Running


Is Host State Running
    [Documentation]  Check that the chassis is on and host state is set
    ...              to 'Running'.

    Is Chassis On
    ${host_state}=  Get Host State
    Should Be Equal  Running  ${host_state}
