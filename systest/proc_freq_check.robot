*** Settings ***

Documentation  Compare processor speed in turbo and non-turbo modes.

# Test Parameters:
# OPENBMC_HOST   The BMC host name or IP address.
# OS_HOST        The OS host name or IP Address.
# OS_USERNAME    The OS login userid (usually root).
# OS_PASSWORD    The password for the OS login.

Resource        ../syslib/utils_os.robot
Library         ../syslib/utils_keywords.py
Variables       ../data/variables.py
Library         ../lib/bmc_ssh_utils.py
Resource        ../lib/connection_client.robot
Resource        ../lib/resource.txt
Resource        ../lib/rest_client.robot
Resource        ../lib/utils.robot


Test Setup      Pre Test Case Execution
Test Teardown   Post Test Case Execution


*** Test Cases ***

Turbo And Non-Turbo Processor Speed Test
    [Documentation]  Compare processor turbo and non-turbo speeds.
    [Tags]  Turbo_And_Non-Turbo_Processor_Speed_Test

    Set Turbo Setting Via REST  True
    ${mode}=  Read Turbo Setting Via REST
    Should Be Equal  ${mode}  True
    ...  msg=Issued call to set Turbo mode but it was not set.

    # The OS governor determines the maximum processor speed at boot-up time.
    REST Power On  stack_mode=skip
    ${proc_speed_turbo}=  Get Processor Max Speed Setting

    Smart Power Off

    Set Turbo Setting Via REST  False
    ${mode}=  Read Turbo Setting Via REST
    Should Be Equal  ${mode}  False
    ...  msg=Issued call to disable Turbo mode but it was not disabled.

    REST Power On  stack_mode=skip
    ${proc_speed_non_turbo}=  Get Processor Max Speed Setting

    Rprintn
    Rpvars  proc_speed_turbo  proc_speed_non_turbo

    ${err_msg}=  Catenate  Reported turbo processor speed should be
    ...  greater than non-turbo speed.
    Should Be True  ${proc_speed_turbo} > ${proc_speed_non_turbo}
    ...  msg=${err_msg}


*** Keywords ***

Get Processor Max Speed Setting
    [Documentation]  Get processor maximum speed setting from the OS.
    # - On the OS run: ppc64_cpu --frequency
    # - Return the maximum frequency value reported.
    # The command ppc64_cpu is provided in both Ubuntu and RHEL on Power.

    ${command}=  Set Variable
    ...  ppc64_cpu --frequency | grep max | cut -f 2 | cut -d ' ' -f 1
    # The ppc64_cpu --frequency command returns min, max, and average
    # cpu frequencies. For example,
    # min:    2.500 GHz (cpu 143)
    # max:    2.700 GHz (cpu 1)
    # avg:    2.600 GHz
    # The ${command} selects the max: line, selects only the
    # 2.700 GHz (cpu 1) part, then selects the 2.700 number.

    # Get the maximum processor frequency reported.
    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  ${command}  print_out=${1}

    ${frequency}=  Convert To Number  ${output}
    [Return]  ${frequency}


Pre Test Case Execution
    [Documentation]  Do the pre test setup.
    # Save the initial system turbo setting.
    # Start (setup) console logging.

    ${initial_turbo_setting}=  Read Turbo Setting Via REST
    Set Suite Variable  ${initial_turbo_setting}  children=true
    Start SOL Console Logging


Post Test Case Execution
    [Documentation]  Do the post test teardown.
    # - Restore original turbo setting on the system.
    # - Capture FFDC on test failure.
    # - Power off the OS and close all open SSH connections.

    Set Turbo Setting Via REST  ${initial_turbo_setting}

    FFDC On Test Case Fail
    Smart Power Off
    Close All Connections
