*** Settings ***
Documentation    Module to test network stability.
...              By default running HTX mdt.bu profile for stress test.

Resource         ../syslib/utils_os.robot
Library          ../syslib/utils_keywords.py

Test Setup      Pre Test Case Execution
Test Teardown   Post Test Case Execution

*** Variables ****

${stack_mode}        skip

# Default duration and interval of HTX exerciser to run.
${HTX_DURATION}     2 hours
${HTX_INTERVAL}     15 min

# Default iteration HTX exerciser to run.
${HTX_LOOP}         4

*** Test Cases ***

Network Stability Test
    [Documentation]  Execute network stress in loop.
    [Tags]  Network_Stability_Test

    # Run the network stress test HTX_LOOP times in loop.
    Repeat Keyword  ${HTX_LOOP} times  Execute Netowrk Test


*** Keywords ***

Execute Netowrk Test
    [Documentation]  Execute network stress test.
    # Test Flow:
    #              - Power on
    #              - Establish SSH connection session
    #              - Create HTX mdt profile
    #              - Run HTX exerciser
    #              - Inject network activity on BMC
    #              - Check HTX status for errors
    #              - Shutdown HTX if no error when timer expires

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

    # HTX is running, inject network traffic and check every HTX_INTERVAL
    ${status}=  Run Until Keyword Fails  ${HTX_DURATION}  ${HTX_INTERVAL}
    ...  Start Network Test

    Run Keyword If  '${status}' == '{False}'
    ...  Fail  Network is unstable. Please check for errors.

    Shutdown HTX Exerciser

    Rprint Timen  HTX Test ran for: ${HTX_DURATION}


Start Network Test
    [Documentation]  Start network stress test.
    BMC Network Payload
    Check HTX Run Status


BMC Network Payload
    [Documentation]  Start creating network activity over BMC network.

    # REST GET enumerate call.
    OpenBMC Get Request  /xyz/openbmc_project/enumerate  quiet=${1}

    # Upload 32 MB data via REST to BMC.
    REST Upload File To BMC


Check HTX Run Status
    [Documentation]  Get HTX exerciser status and check for error.

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

    Rprint Timen  Shutdown HTX Run.
    ${shutdown}=  Execute Command On OS  htxcmdline -shutdown -mdt mdt.bu
    Rprint Timen  ${shutdown}
    Should Contain  ${shutdown}  shutdown successfully


Pre Test Case Execution
    [Documentation]  Do the initial test setup.
    # 1. Check if HTX tool exist.
    # 2. Power on

    Boot To OS
    Tool Exist  htxcmdline


Post Test Case Execution
    [Documentation]  Do the post test teardown.
    # 1. Shut down HTX exerciser if test Failed.
    # 2. Capture FFDC on test failure.
    # 3. Close all open SSH connections.

    Run Keyword If  '${TEST_STATUS}' == 'FAIL'
    ...  Shutdown HTX Exerciser

    FFDC On Test Case Fail
    Close All Connections

