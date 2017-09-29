*** Settings ***
Documentation       Test SBE side switching with watchdog errors.

Library             ../lib/state.py
Library             ../lib/utils.py
Variables           ../data/variables.py
Resource            ../lib/boot_utils.robot

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

    ${match_state}=  Create Dictionary  host=^Off$
    Wait State  ${match_state}  wait_time=5 min
    ${match_state}=  Create Dictionary  host=^Running$
    Wait State  ${match_state}  wait_time=5 min
