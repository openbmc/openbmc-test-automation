*** Settings ***
Documentation  Test to stress IO Storage compatibility.

# Test Parameters:

# OS_HOST         The OS host name or IP address.
# OS_USERNAME     The OS username to login.
# OS_PASSWORD     The OS password for the OS login.
# LOOP_COUNT      The times loop will be executed delimited by user.

Library           SSHLibrary
Library           ../lib/gen_print.py
Library           ../lib/gen_robot_print.py
Resource          ../syslib/utils_os.robot

Suite Setup       Suite Setup Execution
Suite Teardown    Collect HTX Log Files

*** Variables ***
${LOOP_COUNT}

*** Test Cases ***
IO Storage Compability Stress
    [Documentation]  Stress storage cards.
    [Tags]  IO_Storage_Compatibility_Stress

    Set Suite Variable  ${HTX_MDT_PROFILE}  mdt.hdbuster
    Run MDT Profile
    Set Suite Variable  ${iteration}  ${0}
    Rprint Timen  Running HTX. Please wait.
    Repeat Keyword  ${LOOP_COUNT} times
    ...  Run Keywords
    ...  Set Suite Variable  ${iteration}  ${iteration +1}
    ...  AND  Rprint Vars  Iteration ${iteration}
    ...  AND  Loop HTX
    Shutdown HTX Exerciser

*** Keywords ***
Loop HTX
    [Documentation]  Count the loops for the iteration.
    Repeat Keyword  1 hour
    ...  Run Keywords  Check HTX Run Status
    ...  AND  Sleep  10 min

Suite Setup Execution
    [Documentation]  Start setup tasks.

    Login To OS
    Create Default MDT Profile