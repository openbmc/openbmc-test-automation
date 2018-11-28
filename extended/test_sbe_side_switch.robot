*** Settings ***
Documentation       Test SBE side switching with watchdog errors.

Library             ../lib/state.py
Library             ../lib/utils.py
Variables           ../data/variables.py
Resource            ../lib/boot_utils.robot
Resource            ../lib/state_manager.robot

Test Setup          Test Setup Execution
Test Teardown       Test Teardown Execution

*** Variables ***

${sbe_side_bit_mask}  ${0x00004000}

*** Test Cases ***

Test SBE Side Switch
    [Documentation]  Trigger watchdog errors on the host until it side
    ...  switches.
    [Tags]  Test_SBE_Side_Switch

    REST Power On

    ${attempts_left}=  Read Attribute  /xyz/openbmc_project/state/host0
    ...  AttemptsLeft
    Should Be Equal As Strings  ${attempts_left}  3
    ...  msg=Expects boot attempts left 3, but got ${attempts_left}.

    # Get which side the SBE is booted with. By default 0.
    ${sbe_val}=  Get SBE
    ${sbe_cur_side}=  Evaluate  ${sbe_side_bit_mask} & ${sbe_val}

    Trigger Watchdog Error To Switch SBE Boot Side

    # Next Power on check if host booting is in progress.
    Wait Until Keyword Succeeds  2 min  30 sec  Watchdog Object Should Exist

    # Verify that the side has switched.
    ${sbe_val}=  Get SBE
    ${sbe_orig_side}=  Evaluate  ${sbe_side_bit_mask} & ${sbe_val}

    Run Keyword If  ${sbe_orig_side} == ${0}
    ...      Should Be True  ${sbe_cur_side} == ${sbe_side_bit_mask}
    ...      msg=SBE seeprom side is 1.
    ...  ELSE
    ...      Should Be True  ${sbe_cur_side} == ${0}
    ...      msg=SBE seeprom side is 0.

    # Verify that host booted on the current SBE side.
    Wait Until Keyword Succeeds  10 min  10 sec  Is Host Running


*** Keywords ***

Test Setup Execution
    [Documentation]  Do the test setup execution.

    Delete All Error Logs
    Set Auto Reboot  ${1}
    Smart Power Off


Test Teardown Execution
    [Documentation]  Do the test teardown execution.
    FFDC On Test Case Fail
    Smart Power Off


Watchdog Object Should Exist
    [Documentation]  Watchdog object should exist.

    ${resp}=  OpenBMC Get Request  ${WATCHDOG_URI}  quiet=${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ...  msg=Failed to get ${WATCHDOG_URI}, response = ${resp.status_code}.


Trigger Watchdog Error To Switch SBE Boot Side
    [Documentation]  Trigger watchdog error to force SBE boot side switch.

    # 20 second wait is introduced to ensure host boot progress at least
    # crossed the initial istep booting sequence.

    Trigger Host Watchdog Error
    ${attempts_left}=  Read Attribute  /xyz/openbmc_project/state/host0
    ...  AttemptsLeft
    Should Be Equal As Strings  ${attempts_left}  2
    ...  msg=Expects boot attempts left 2, but got ${attempts_left}.

    Wait Until Keyword Succeeds  2 min  30 sec  Watchdog Object Should Exist
    Sleep  20 s
    Trigger Host Watchdog Error
    ${attempts_left}=  Read Attribute  /xyz/openbmc_project/state/host0
    ...  AttemptsLeft
    Should Be Equal As Strings  ${attempts_left}  1
    ...  msg=Expects boot attempts left 1, but got ${attempts_left}.

    Wait Until Keyword Succeeds  2 min  30 sec  Watchdog Object Should Exist
    Sleep  20 s
    Trigger Host Watchdog Error
    ${attempts_left}=  Read Attribute  /xyz/openbmc_project/state/host0
    ...  AttemptsLeft
    Should Be Equal As Strings  ${attempts_left}  0
    ...  msg=Expects boot attempts left 0, but got ${attempts_left}.
