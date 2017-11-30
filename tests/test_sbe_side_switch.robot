*** Settings ***
Documentation       Test SBE side switching with watchdog errors.

Library             ../lib/state.py
Library             ../lib/utils.py
Variables           ../data/variables.py
Resource            ../lib/boot_utils.robot

Test Setup          Test Setup Execution
Test Teardown       FFDC On Test Case Fail

*** Test Cases ***

Test SBE Side Switch
    [Documentation]  Trigger watchdog errors on the host until it side
    ...  switches.
    [Tags]  Test_SBE_Side_Switch

    REST Power On

    ${attempts_left}=  Read Attribute  /xyz/openbmc_project/state/host0
    ...  AttemptsLeft
    Should Be Equal As Strings  ${attempts_left}  3

    # Get which side the SBE is booted with. By default 0.
    ${sbe_string}=  BMC Execute Command
    ...  pdbg -d p9w -p0 getcfam 0x2808 | sed -re 's/.* = //g'
    ${sbe_orig_side} =  Get Sbe Side Bit  ${sbe_string[0]}

    Trigger Watchdog Error To Switch SBE Boot Side

    # Next Power on check if host booting is in progress.
    Wait Until Keyword Succeeds  2 min  30 sec  Watchdog Object Should Exist

    # Verify that the side has switched.
    ${sbe_string}=  BMC Execute Command
    ...  pdbg -d p9w -p0 getcfam 0x2808 | sed -re 's/.* = //g'
    ${sbe_cur_side} =  Get Sbe Side Bit  ${sbe_string[0]}

    Run Keyword If  ${sbe_orig_side} == ${0}
    ...      Should Be True  ${sbe_cur_side} == ${1}
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


Watchdog Object Should Exist
    [Documentation]  Watchdog object should exist.

    ${resp}=  OpenBMC Get Request  ${WATCHDOG_URI}  quiet=${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Trigger Watchdog Error To Switch SBE Boot Side
    [Documentation]  Trigger watchdog error to force SBE boot side switch.

    # 20 seconds wait is introduce to ensure host boot progress atleast crossed
    # the initial istep booting sequence.

    Trigger Host Watchdog Error
    ${attempts_left}=  Read Attribute  /xyz/openbmc_project/state/host0
    ...  AttemptsLeft
    Should Be Equal As Strings  ${attempts_left}  2

    Wait Until Keyword Succeeds  2 min  30 sec  Watchdog Object Should Exist
    Sleep  20 s
    Trigger Host Watchdog Error
    ${attempts_left}=  Read Attribute  /xyz/openbmc_project/state/host0
    ...  AttemptsLeft
    Should Be Equal As Strings  ${attempts_left}  1

    Wait Until Keyword Succeeds  2 min  30 sec  Watchdog Object Should Exist
    Sleep  20 s
    Trigger Host Watchdog Error
    ${attempts_left}=  Read Attribute  /xyz/openbmc_project/state/host0
    ...  AttemptsLeft
    Should Be Equal As Strings  ${attempts_left}  0
