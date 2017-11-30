*** Settings ***
Documentation       Test SBE side switching with watchdog errors.

Library             ../lib/state.py
Library             ../lib/utils.py
Variables           ../data/variables.py
Resource            ../lib/boot_utils.robot

Test Setup          Test Setup Execution

*** Test Cases ***

Test SBE Side Switch
    [Documentation]  Trigger watchdog errors on the host until it side
    ...  switches.
    [Tags]  Test_SBE_Side_Switch

    REST Power On

    Start Journal Log

    ${attempts_left}=  Read Attribute  /xyz/openbmc_project/state/host0
    ...  AttemptsLeft
    Should Be Equal As Strings  ${attempts_left}  3

    # Verify the side is at primary by default 0.
    ${journal_text}=  Stop Journal Log
    Should Contain  ${journal_text}  Setting SBE seeprom side to 0

    Wait Until Keyword Succeeds  2 min  30 sec  Watchdog Object Should Exist
    Trigger Host Watchdog Error
    ${attempts_left}=  Read Attribute  /xyz/openbmc_project/state/host0
    ...  AttemptsLeft
    Should Be Equal As Strings  ${attempts_left}  2

    Wait Until Keyword Succeeds  2 min  30 sec  Watchdog Object Should Exist
    Trigger Host Watchdog Error
    ${attempts_left}=  Read Attribute  /xyz/openbmc_project/state/host0
    ...  AttemptsLeft
    Should Be Equal As Strings  ${attempts_left}  1

    Start Journal Log
    Wait Until Keyword Succeeds  2 min  30 sec  Watchdog Object Should Exist
    Trigger Host Watchdog Error
    ${attempts_left}=  Read Attribute  /xyz/openbmc_project/state/host0
    ...  AttemptsLeft
    Should Be Equal As Strings  ${attempts_left}  0

    # Verify the side switched
    ${journal_text}=  Stop Journal Log
    Should Contain  ${journal_text}  Setting SBE seeprom side to 0

    Wait Until Keyword Succeeds  10 min  10 sec  Is Host Running


*** Keywords ***

Test Setup Execution
    [Documentation]  Do the test setup execution.

    Delete All Error Logs
    Set Auto Reboot  ${1}
    BMC Execute Command  /sbin/hwclock --utc --systohc
    Smart Power Off


Watchdog Object Should Exist
    [Documentation]  Watchdog object should exist.

    ${resp}=  OpenBMC Get Request  ${WATCHDOG_URI}  quiet=${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

