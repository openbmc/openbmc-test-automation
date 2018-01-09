*** Settings ***
Documentation    Stress the system GPUs using the HTX exerciser.

# Test Parameters:
# OPENBMC_HOST        The BMC host name or IP address.
# OS_HOST             The OS host name or IP Address.
# OS_USERNAME         The OS login userid (usually root).
# OS_PASSWORD         The password for the OS login.
# HTX_DURATION        Duration of HTX run, for example, 2h, or 30m.
# HTX_LOOP            The number of times to loop HTX.
# HTX_INTERVAL        The time delay between consecutive checks of HTX
#                     status, for example, 15m.
#                     In summary: Run HTX for $HTX_DURATION, looping
#                     $HTX_LOOP times checking for errors every
#                     $HTX_INTERVAL.  Then allow extra time for OS
#                     Boot, HTX startup, shutdown.
# HTX_KEEP_RUNNING    If set to 1, this indicates that the HTX is to
#                     continue running after an error was found.


Resource         ../syslib/utils_os.robot

Suite Setup      Run Keyword  Start SOL Console Logging
Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

*** Variables ****

${HTX_DURATION}      1h 
${HTX_LOOP}          ${1}
${HTX_INTERVAL}      30m
${HTX_KEEP_RUNNING}  ${0}
${stack_mode}        skip

*** Test Cases ***

GPU Stress Test
    [Documentation]  Stress the GPU using HTX exerciser.
    [Tags]  GPU_Stress_Test

    # Get number of GPUs reported by the OS.
    ${cmd}=  Catenate  lspci | grep NVIDIA | wc -l
    ${num_os_gpus}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    Rprintn
    Rpvars  num_os_gpus

    # If no GPUs detected we cannot continue.
    # Perhaps test is being run on a system with no GPUs.
    Pass Execution If  '${num_os_gpus}' == '${0}'
    ...  msg=No GPUs detected so cannot run test. OS command used: ${cmd}.

    # Get number of GPU reported by the BMC.
    ${num_bmc_gpus}=  Count GPUs From BMC
    Rpvars  num_bmc_gpus

    # The BMC and OS should report the same number of GPUs.
    ${failmsg01}=  Catenate  OS reports ${num_os_gpus} GPUs, but BMC
    ...  reports ${num_bmc_gpus} present and functional GPUs.
    Run Keyword If  '${num_os_gpus}' != '${num_bmc_gpus}'
    ...  Fail  msg=${failmsg01}

    # Show parameters for HTX stress test.
    Rprintn
    Rpvars  HTX_DURATION  HTX_LOOP  HTX_INTERVAL

    # Set the iteration (loop) counter.
    Set Suite Variable  ${iteration}  ${0}  children=true

    # Check that needed tools are available on OS.
    Tool Exist  htxcmdline
    Tool Exist  nvidia-smi

    # Shutdown HTX if it is already running.
    ${status}=  Run Keyword And Return Status  Is HTX Running
    Run Keyword If  '${status}' == 'True'
    ...  Shutdown HTX Exerciser

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
    #              - Check for errors

    Set Suite Variable  ${iteration}  ${iteration + 1}
    ${loop_count}=  Catenate  Starting iteration: ${iteration}
    Rprintn
    Rpvars  loop_count

    Boot To OS

    Login To OS

    # Collect data before the test starts.
    Collect NVIDIA Log File  start

    # Collect NVIDIA maximum limits.
    ${power_max}=  Get GPU Power Limit
    ${temp_max}=  Get GPU Temperature Limit
    ${clk_max}=  Get GPU Clock Limit

    Run Keyword If  '${HTX_MDT_PROFILE}' == 'mdt.bu'
    ...  Create Default MDT Profile

    Run MDT Profile

    Loop HTX Health Check

    # Post test loop look out for dmesg error logged.
    Check For Errors On OS Dmesg Log

    # Check NVIDIA power, temp, and clocks.
    ${power}=  Get GPU Power
    ${temp}=  Get GPU Temperature
    ${clk}=  Get GPU Clock
    Rprintn
    Rpvars  power  power_max  temp  temp_max  clk  clk_max
    Run Keyword If  ${power} > ${power_max}  Fail
    ...  msg=GPU Power ${power} exceeds limit of ${power_max}.
    Run Keyword If  ${temp} > ${temp_max}  Fail
    ...  msg=GPU temperature of ${temp} exceeds limit of ${temp_max}.
    Run Keyword If  ${clk} > ${clk_max}  Fail
    ...  msg=GPU clock of ${clk} exceeds limit of ${clk_max}.

    Shutdown HTX Exerciser

    Collect NVIDIA Log File  end
    Error Logs Should Not Exist
    Power Off Host

    # Close all SSH and REST active sessions.
    Close All Connections
    Flush REST Sessions

    Rprint Timen  HTX Test ran for: ${HTX_DURATION}

    ${loop_count}=  Catenate  Ending iteration: ${iteration}
    Rprintn
    Rpvars  loop_count


Loop HTX Health Check
    [Documentation]  Run until HTX exerciser fails.

    Repeat Keyword  ${HTX_DURATION}
    ...  Run Keywords  Check HTX Run Status
    ...  AND  Sleep  ${HTX_INTERVAL}


Test Setup Execution
    [Documentation]  Do the initial test setup.

    Boot To OS
    Delete All Error Logs
    Tool Exist  lspci


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    #  Shut down HTX exerciser if test Failed.
    #  Collect NVIDIA log.
    #  Close connections.

    # Keep HTX running if user set HTX_KEEP_RUNNING to 1.
    Run Keyword If  '${TEST_STATUS}' == 'FAIL' and ${HTX_KEEP_RUNNING} == ${0}
    ...  Shutdown HTX Exerciser

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Key  ${keyword_buf}

    FFDC On Test Case Fail
    Close All Connections
