*** Settings ***
Documentation    Stress the system using HTX exerciser.

Resource         ../syslib/utils_os.robot

Test Setup      Pre Test Case Execution
Test Teardown   Post Test Case Execution

*** Variables ****

${stack_mode}        skip

# Default duration and interval of HTX exerciser to run.
${HTX_DURATION}     2 hours
${HTX_INTERVAL}     15 min

# Default harbootme loop times HTX exerciser to run.
${HTX_LOOP}         4

*** Test Cases ***

Hard Bootme Test
    [Documentation]  Stress the system using HTX exerciser.

    Log To Console  \n HTX Test run: ${HTX_DURATION} interval: ${HTX_INTERVAL}

    Repeat Keyword  ${HTX_LOOP} times  Start HTX Exerciser


*** Keywords ***

Start HTX Exerciser
    [Documentation]  Start HTX exerciser.
    ...  Test Flow :
    ...            - Power on
    ...            - Establish SSH connection session
    ...            - Create HTX mdt profile
    ...            - Run HTX exerciser
    ...            - Check HTX status for errors
    ...            - Power off

    Boot To OS

    # Post Power off and on, the OS SSH session needs to be established.
    Login To OS

    Log To Console  \n *** Create HTX mdt profile ***
    ${profile}=  Execute Command On OS  htxcmdline -createmdt
    Log To Console  \n ${profile}
    Should Contain  ${profile}  mdts are created successfully

    Log To Console  \n *** Start HTX mdt profile execution ***
    ${htx_run}=  Execute Command On OS  htxcmdline -run -mdt mdt.bu
    Log To Console  \n ${htx_run}
    Should Contain  ${htx_run}  Activated

    Loop HTX Health Check

    Shutdown HTX Exerciser

    Power Off Host


Loop HTX Health Check
    [Documentation]  Run until keyword fails.

    Repeat Keyword  ${HTX_DURATION}
    ...  Run Keywords  Check HTX Run Status
    ...  AND  Sleep  ${HTX_INTERVAL}


Check HTX Run Status
    [Documentation]  Get HTX exerciser status and check for error.

    Log To Console  \n *** Check HTX mdt Status and error ***
    ${status}=  Execute Command On OS  htxcmdline -status -mdt mdt.bu
    Log  ${status}

    ${errlog}=  Execute Command On OS  htxcmdline -geterrlog
    Log  ${errlog}

    Should Contain  ${errlog}  file </tmp/htxerr> is empty


Shutdown HTX Exerciser
    [Documentation]  Shut down HTX exerciser run.

    Log To Console  \n *** Shutdown HTX Run ***
    ${shutdown}=  Execute Command On OS  htxcmdline -shutdown -mdt mdt.bu
    Log To Console  \n ${shutdown}
    Should Contain  ${shutdown}  shutdown successfully


Pre Test Case Execution
    [Documentation]  Do the initial test setup.
    ...  1. Check if HTX tool exist.
    ...  2. Power on

    Boot To OS
    HTX Tool Exist


Post Test Case Execution
    [Documentation]  Do the post test teardown.
    ...  1. Shut down HTX exerciser if test Failed.
    ...  2. Capture FFDC on test failure.
    ...  3. Close all open SSH connections.

    Run Keyword If  '${TEST_STATUS}' == 'FAIL'
    ...  Shutdown HTX Exerciser

    FFDC On Test Case Fail
    Close All Connections

