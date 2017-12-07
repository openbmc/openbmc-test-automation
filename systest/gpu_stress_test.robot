*** Settings ***
Documentation    Stress the system using HTX exerciser.

Resource         ../syslib/utils_os.robot

Suite Setup      Run Keyword  Start SOL Console Logging
Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution
Suite Teardown   Suite Teardown Execution

*** Variables ****

${stack_mode}        skip

*** Test Cases ***

GPU Stress Test
    [Documentation]  Stress the GPU using HTX exerciser.
    [Tags]  GPU_Stress_Test

    Rprintn
    Rpvars  HTX_DURATION  HTX_INTERVAL

    Repeat Keyword  ${HTX_LOOP} times  Execute GPU Test


*** Keywords ***

Execute GPU Test
    [Documentation]  Start HTX exerciser.
    # Test Flow:
    #              - Power on
    #              - Establish SSH connection session
    #              - Collect GPU nvidia status output
    #              - Create HTX mdt profile
    #              - Run GPU specific HTX exerciser
    #              - Check HTX status for errors

    # Collect data before the test starts.
    Collect NVIDIA Log File  start

    Run Keyword If  '${HTX_MDT_PROFILE}' == 'mdt.bu'
    ...  Create Default MDT Profile

    Run MDT Profile

    Loop HTX Health Check

    # Post test loop look out for dmesg error logged.
    Check For Errors On OS Dmesg Log

    Shutdown HTX Exerciser

    Rprint Timen  HTX Test ran for: ${HTX_DURATION}


Loop HTX Health Check
    [Documentation]  Run until HTX exerciser fails.

    Repeat Keyword  ${HTX_DURATION}
    ...  Run Keywords  Check HTX Run Status
    ...  AND  Sleep  ${HTX_INTERVAL}


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    #  Shut down HTX exerciser if test Failed.
    #  Collect NVIDIA log.

    # Keep HTX running if user set HTX_KEEP_RUNNING to 1.
    Run Keyword If  '${TEST_STATUS}' == 'FAIL' and ${HTX_KEEP_RUNNING} == ${0}
    ...  Shutdown HTX Exerciser

    # Collect nvidia-smi output data on exit.
    Collect NVIDIA Log File  end


Suite Teardown Execution
    [Documentation]  Do the final teardown and cleanup.
    #  Stop SOL Console Logging.
    #  Collect FFDC if Test Case Fail.
    #  Close Connections.

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Key  ${keyword_buf}

    FFDC On Test Case Fail
    Close All Connections
