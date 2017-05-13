*** Settings ***
Documentation    Stress the system using HTX exerciser.

Resource         ../syslib/utils_os.robot
Library          ../lib/gen_robot_print.py

Test Setup      Pre Test Case Execution
Test Teardown   Post Test Case Execution

*** Variables ****

${stack_mode}        skip

# Default duration and interval of HTX exerciser to run.
${HTX_DURATION}     2 hours
${HTX_INTERVAL}     15 min

# Default hardbootme loop times HTX exerciser to run.
${HTX_LOOP}         4

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

    Rprint Timen  Create HTX mdt profile.
    ${profile}=  Execute Command On OS  htxcmdline -createmdt
    Rprint Timen  ${profile}
    Should Contain  ${profile}  mdts are created successfully

    Rprint Timen  Start HTX mdt profile execution.
    ${htx_run}=  Execute Command On OS  htxcmdline -run -mdt mdt.bu
    Rprint Timen  ${htx_run}
    Should Contain  ${htx_run}  Activated

    Loop HTX Health Check

    Shutdown HTX Exerciser

    Power Off Host

    Rprint Timen  HTX Test ran for: ${HTX_DURATION}

Loop HTX Health Check
    [Documentation]  Run until HTX exerciser fails.

    Repeat Keyword  ${HTX_DURATION}
    ...  Run Keywords  Check HTX Run Status
    ...  AND  Sleep  ${HTX_INTERVAL}


Check HTX Run Status
    [Documentation]  Get HTX exerciser status and check for error.

    Rprint Timen  Collect HTX status and error log files.
    Collect HTX Log Files

    Rprint Timen  Check HTX mdt Status and error.
    ${status}=  Execute Command On OS  htxcmdline -status -mdt mdt.bu
    Log  ${status}
    Rprint Timen  ${status}

    ${errlog}=  Execute Command On OS  htxcmdline -geterrlog
    Log  ${errlog}
    Rprint Timen  ${errlog}

    Should Contain  ${errlog}  file </tmp/htxerr> is empty


Shutdown HTX Exerciser
    [Documentation]  Shut down HTX exerciser run.

    Rprint Timen  Shutdown HTX Run
    ${shutdown}=  Execute Command On OS  htxcmdline -shutdown -mdt mdt.bu
    Rprint Timen  ${shutdown}
    Should Contain  ${shutdown}  shutdown successfully


Pre Test Case Execution
    [Documentation]  Do the initial test setup.
    # 1. Check if HTX tool exist.
    # 2. Power on

    Boot To OS
    HTX Tool Exist


Post Test Case Execution
    [Documentation]  Do the post test teardown.
    # 1. Shut down HTX exerciser if test Failed.
    # 2. Capture FFDC on test failure.
    # 3. Close all open SSH connections.

    Run Keyword If  '${TEST_STATUS}' == 'FAIL'
    ...  Shutdown HTX Exerciser

    FFDC On Test Case Fail
    Close All Connections

