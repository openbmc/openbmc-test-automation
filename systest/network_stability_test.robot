*** Settings ***
Documentation    Module to test network stability.
...              By default running HTX mdt.bu profile for stress test.

Resource         ../lib/os_utilities.robot
Library          ../lib/os_utils_keywords.py

Test Setup      Test Setup Execution
Test Teardown   Test Teardown Execution

Test Tags      Network_Stability

*** Variables ****

${stack_mode}        skip

*** Test Cases ***

Network Stability Test
    [Documentation]  Execute network stress in loop.
    [Tags]  Network_Stability_Test

    # Run the network stress test HTX_LOOP times in loop.
    Repeat Keyword  ${HTX_LOOP} times  Execute Network Test


*** Keywords ***

Execute Network Test
    [Documentation]  Execute network stress test.
    # Test Flow:
    #              - Power on
    #              - Establish SSH connection session
    #              - Create HTX mdt profile
    #              - Run HTX exerciser
    #              - Inject network activity on BMC
    #              - Check HTX status for errors
    #              - Shutdown HTX if no error when timer expires

    REST Power On  stack_mode=skip

    # Post Power off and on, the OS SSH session needs to be established.
    Login To OS

    IF  '${HTX_MDT_PROFILE}' == 'mdt.bu'  Create Default MDT Profile

    Run MDT Profile

    # HTX is running, inject network traffic and check every HTX_INTERVAL
    ${status}=  Run Until Keyword Fails  ${HTX_DURATION}  ${HTX_INTERVAL}
    ...  Start Network Test

    IF  '${status}' == 'False'
        Fail  Network is unstable. Please check for errors.
    END

    Shutdown HTX Exerciser

    Print Timen  HTX Test ran for: ${HTX_DURATION}


Start Network Test
    [Documentation]  Start network stress test.
    BMC Network Payload
    Check HTX Run Status


BMC Network Payload
    [Documentation]  Start creating network activity over BMC network.

    # REST GET enumerate call.
    OpenBMC Get Request
    ...  /xyz/openbmc_project/inventory/enumerate  timeout=${20}  quiet=${1}

    # Upload 32 MB data via REST to BMC.
    REST Upload File To BMC


Test Setup Execution
    [Documentation]  Do the initial test setup.

    REST Power On  stack_mode=skip
    Delete All Error Logs
    Tool Exist  htxcmdline

    # Shutdown if HTX is running.
    ${status}=  Is HTX Running
    IF  '${status}' == 'True'  Shutdown HTX Exerciser


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    # 1. Shut down HTX exerciser if test Failed.
    # 2. Capture FFDC on test failure.
    # 3. Close all open SSH connections.

    # Keep HTX running if user set HTX_KEEP_RUNNING to 1.
    IF  '${TEST_STATUS}' == 'FAIL' and ${HTX_KEEP_RUNNING} == ${0}
        Shutdown HTX Exerciser
    END

    FFDC On Test Case Fail
    Close All Connections
