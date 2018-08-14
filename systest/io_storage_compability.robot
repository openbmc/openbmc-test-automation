*** Settings ***
Documentation  Test to stress IO Storage compatibility.

# Test Parameters:

# OS_HOST         The OS host name or IP address.
# OS_USERNAME     The OS username to login.
# OS_PASSWORD     The OS password for the OS login.
# LOOP_COUNT      The times loop will be executed delimited by user.

Library           ../lib/gen_print.py
Library           ../lib/gen_robot_print.py
Resource          ../syslib/utils_os.robot

Suite Setup       Suite Setup Execution
Suite Teardown    Suite Teardown Execution


*** Variables ***
${LOOP_COUNT}  ${1}
${ITERATION}  ${0}
${HTX_MDT_PROFILE}  mdt.hdbuster


*** Test Cases ***

IO Storage Compatibility Stress
    [Documentation]  Stress storage cards.
    [Tags]  IO_Storage_Compatibility_Stress

    Run MDT Profile
    Rprint Timen  Running HTX. Please wait.
    Repeat Keyword  ${LOOP_COUNT} times
    ...  Run Keywords
    ...  Set Suite Variable  ${ITERATION}  ${ITERATION +1}
    ...  AND  Rprint Vars  ITERATION
    ...  AND  Loop HTX
    Shutdown HTX Exerciser


*** Keywords ***

Loop HTX
    [Documentation]  Run HTX for an hour and check status every 10 minutes.
    Repeat Keyword  1 hour
    ...  Run Keywords  Check HTX Run Status
    ...  AND  Sleep  10 min


Suite Setup Execution
    [Documentation]  Start setup tasks.

    Create Default MDT Profile


Suite Teardown Execution
    [Documentation]  Execute suite teardown tasks.

    Collect HTX Log Files
    FFDC On Test Case Fail
