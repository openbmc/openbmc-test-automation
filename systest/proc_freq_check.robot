*** Settings ***

Documentation  Compare processor speeds in turbo and non-turbo modes.

# Test Parameters:
# OPENBMC_HOST   The BMC host name or IP address.
# OS_HOST        The OS host name or IP Address.
# OS_USERNAME    The OS login userid (usually root).
# OS_PASSWORD    The password for the OS login.

Resource        ../syslib/utils_os.robot
Resource        ../lib/boot_utils.robot
Library         ../syslib/utils_keywords.py
Variables       ../data/variables.py
Library         ../lib/bmc_ssh_utils.py
Resource        ../lib/connection_client.robot
Resource        ../lib/resource.txt
Resource        ../lib/rest_client.robot
Resource        ../lib/utils.robot


Suite Setup     Run Key  Start SOL Console Logging
Test Teardown   Post Test Case Execution


*** Test Cases ***

Turbo And Non-Turbo Processor Speed Test
    [Documentation]  Compare processor turbo and non-turbo speeds.
    [Tags]  Processor_Turbo_Non-Turbo_Speed_Test

    # Save the initial system turbo setting.  Restore this value
    # when testing is done.
    ${initial_turbo_setting}=  Read Turbo Setting Via REST
    Set Suite Variable  ${initial_turbo_setting}  children=true

    Set Turbo Setting Via REST  True
    ${mode}=  Read Turbo Setting Via REST
    Should Be Equal  ${mode}  True
    ...  Fail  Issued call to set Turbo mode but it was not set.

    # The OS govenor determines the maximum processor speed at boot-up time.
    REST Power On  stack_mode=skip
    ${cpu_freq_turbo}=  Get Processor Max Speed Setting From OS

    REST Power Off

    Set Turbo Setting Via REST  False
    ${mode}=  Read Turbo Setting Via REST
    Should Be Equal  ${mode}  False
    ...  Fail  Issued call to disable Turbo mode but it was not disabled

    REST Power On  stack_mode=skip
    ${cpu_freq_non_turbo}=  Get Processor Max Speed Setting From OS

    REST Power Off

    Rprintn
    Rpvars  cpu_freq_turbo  cpu_freq_non_turbo

    Run Keyword If  '${cpu_freq_turbo}' <= '${cpu_freq_non_turbo}'
    ...  Report Turbo Test Failure  ${cpu_freq_turbo}  ${cpu_freq_non_turbo}


*** Keywords ***

Report Turbo Test Failure
    [Documentation]  Report failure of turbo mode test.
    [Arguments]    ${cpu_freq_turbo}  ${cpu_freq_non_turbo}

    ${err_msg}=  Catenate   Reported turbo processor speed ${cpu_freq_turbo}
    ...  should be greater than non-turbo speed ${cpu_freq_non_turbo}
    Fail   ${err_msg}


Get Processor Max Speed Setting From OS
    [Documentation]  Get processor maximum speed setting from the OS.
    # - On the OS run: ppc64_cpu --frequency
    # - Return the max frequency value reported.

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

    Rpvars  command  rc  output  stderr

    Run Keyword If  '${stderr}' != '${empty}'  Fail  Failure running ${command}
 
    ${frequency}=  Convert To Number  ${output}
    [Return]  ${frequency}


Post Test Case Execution
    [Documentation]  Do the post test teardown.
    # - Restore original turbo setting on the system.
    # - Capture FFDC on test failure.
    # - Close all open SSH connections.

    Set Turbo Setting Via REST  ${initial_turbo_setting}

    FFDC On Test Case Fail
    Close All Connections
