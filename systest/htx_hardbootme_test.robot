*** Settings ***
Documentation    Stress the system using HTX exerciser.

Resource         ../syslib/utils_os.robot

Suite Setup     Run Key  Start SOL Console Logging
Test Setup      Pre Test Case Execution
Test Teardown   Post Test Case Execution

*** Variables ****

${stack_mode}        skip

*** Test Cases ***

Hard Bootme Test
    [Documentation]  Stress the system using HTX exerciser.
    [Tags]  Hard_Bootme_Test

    Rprintn
    Rpvars  HTX_DURATION  HTX_INTERVAL

    Repeat Keyword  ${HTX_LOOP} times  Start HTX Exerciser


*** Keywords ***

Start HTX Exerciser
    [Documentation]  Start HTX exerciser.
    # Test Flow:
    #              - Power on
    #              - Establish SSH connection session
    #              - Create HTX mdt profile
    #              - Run HTX exerciser
    #              - Check HTX status for errors
    #              - Power off

    Boot To OS

    # Post Power off and on, the OS SSH session needs to be established.
    Login To OS

    Run Keyword If  '${HTX_MDT_PROFILE}' == 'mdt.bu'
    ...  Create Default MDT Profile

    Run MDT Profile

    Loop HTX Health Check

    Shutdown HTX Exerciser

    Power Off Host

    # Close all SSH and REST active sessions.
    Close All Connections
    Flush REST Sessions

    Rprint Timen  HTX Test ran for: ${HTX_DURATION}


Loop HTX Health Check
    [Documentation]  Run until HTX exerciser fails.

    Repeat Keyword  ${HTX_DURATION}
    ...  Run Keywords  Check HTX Run Status
    ...  AND  Sleep  ${HTX_INTERVAL}


Post Test Case Execution
    [Documentation]  Do the post test teardown.
    # 1. Shut down HTX exerciser if test Failed.
    # 2. Capture FFDC on test failure.
    # 3. Close all open SSH connections.

    # Keep HTX running if user set HTX_KEEP_RUNNING to 1.
    Run Keyword If  '${TEST_STATUS}' == 'FAIL' and ${HTX_KEEP_RUNNING} == ${0}
    ...  Shutdown HTX Exerciser

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Key  ${keyword_buf}

    FFDC On Test Case Fail
    Close All Connections
