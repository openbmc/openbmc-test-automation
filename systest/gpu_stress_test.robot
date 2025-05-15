*** Settings ***
Documentation    Stress the system GPUs using the HTX exerciser.

# Test Parameters:
# OPENBMC_HOST        The BMC host name or IP address.
# OS_HOST             The OS host name or IP Address.
# OS_USERNAME         The OS login userid (usually "root").
# OS_PASSWORD         The password for the OS login.
# HTX_DURATION        Duration of HTX run, for example, "2h", or "30m".
# HTX_LOOP            The number of times to loop HTX.
# HTX_INTERVAL        The time delay between consecutive checks of HTX
#                     status, for example, "15m".
#                     In summary: Run HTX for $HTX_DURATION, looping
#                     $HTX_LOOP times checking for errors every
#                     $HTX_INTERVAL.  Then allow extra time for OS
#                     Boot, HTX startup, shutdown.
# HTX_KEEP_RUNNING    If set to 1, this indicates that the HTX is to
#                     continue running after an error was found.


Resource         ../lib/os_utilities.robot

Suite Setup      Run Keyword  Start SOL Console Logging
Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

Test Tags       GPU_Stress

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

    # Get number of GPU reported by the BMC.
    ${num_bmc_gpus}=  Count GPUs From BMC
    Rpvars  num_bmc_gpus

    # The BMC and OS should report the same number of GPUs.
    ${failmsg01}=  Catenate  OS reports ${num_os_gpus} GPUs, but BMC
    ...  reports ${num_bmc_gpus} present and functional GPUs.
    IF  '${num_os_gpus}' != '${num_bmc_gpus}'  Fail  msg=${failmsg01}

    # Show parameters for HTX stress test.
    Printn
    Rpvars  HTX_DURATION  HTX_LOOP  HTX_INTERVAL

    # Set the iteration (loop) counter.
    Set Suite Variable  ${iteration}  ${0}  children=true


    # Shutdown HTX if it is already running.
    ${status}=  Is HTX Running
    IF  '${status}' == 'True'  Shutdown HTX Exerciser

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
    Printn
    Rpvars  loop_count

    REST Power On  stack_mode=skip
    Run Key U  Sleep \ 15s

    # Collect data before the test starts.
    Collect NVIDIA Log File  start

    # Collect NVIDIA maximum limits.
    ${power_max}=  Get GPU Power Limit
    ${temperature_max}=  Get GPU Temperature Limit
    ${clock_max}=  Get GPU Clock Limit

    IF  '${HTX_MDT_PROFILE}' == 'mdt.bu'  Create Default MDT Profile

    Run MDT Profile

    Loop HTX Health Check

    # Post test loop look out for dmesg error logged.
    Check For Errors On OS Dmesg Log

    # Check NVIDIA power, temperature, and clocks.
    ${power}=  Get GPU Max Power
    ${temperature}=  Get GPU Max Temperature
    ${temperature_via_rest}=  Get GPU Temperature Via REST
    ${clock}=  Get GPU Clock
    Printn
    Rpvars  power  power_max  temperature  temperature_via_rest
    ...  temperature_max  clock  clock_max

    IF  ${power} > ${power_max}
        Fail  msg=GPU Power ${power} exceeds limit of ${power_max}.
    END

    ${err_msg}=  Catenate  GPU temperature of ${temperature} exceeds limit
    ...  of ${temperature_max}.
    IF  ${temperature} > ${temperature_max}  Fail  msg=${err_msg}

    IF  ${clock} > ${clock_max}  Fail  msg=GPU clock of ${clock} exceeds limit of ${clock_max}.

    ${err_msg}=  Catenate  The GPU temperature reported by REST is not within
    ...  5 degrees of the nvidia_smi reported temperature.
    ${upper_limit}=  Evaluate  ${temperature_via_rest}+5
    ${lower_limit}=  Evaluate  ${temperature_via_rest}-5

    IF  ${temperature} > ${upper_limit} or ${temperature} < ${lower_limit}
        Fail  msg=${err_msg}
    END

    Shutdown HTX Exerciser

    Collect NVIDIA Log File  end
    Error Logs Should Not Exist
    REST Power Off

    Flush REST Sessions

    Print Timen  HTX Test ran for: ${HTX_DURATION}

    ${loop_count}=  Catenate  Ending iteration: ${iteration}
    Printn
    Rpvars  loop_count


Loop HTX Health Check
    [Documentation]  Run until HTX exerciser fails.

    Repeat Keyword  ${HTX_DURATION}
    ...  Run Keywords  Check HTX Run Status
    ...  AND  Sleep  ${HTX_INTERVAL}


Test Setup Execution
    [Documentation]  Do the initial test setup.

    REST Power On  stack_mode=skip
    Run Key U  Sleep \ 15s
    Delete All Error Logs
    Tool Exist  lspci
    Tool Exist  htxcmdline
    Tool Exist  nvidia-smi

    # Get number of GPUs reported by the OS.
    ${cmd}=  Catenate  lspci | grep NVIDIA | wc -l
    ${num_os_gpus}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    Printn
    Rpvars  num_os_gpus

    # If no GPUs detected, we cannot continue.
    IF  '${num_os_gpus}' == '${0}'  Fail  msg=No GPUs detected so cannot run test.

    Set Suite Variable  ${num_os_gpus}  children=true



Test Teardown Execution
    [Documentation]  Do the post test teardown.

    # Keep HTX running if user set HTX_KEEP_RUNNING to 1.
    IF  '${TEST_STATUS}' == 'FAIL' and ${HTX_KEEP_RUNNING} == ${0}  Shutdown HTX Exerciser

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Key  ${keyword_buf}

    FFDC On Test Case Fail
    Close All Connections
