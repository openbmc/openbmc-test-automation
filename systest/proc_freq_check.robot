*** Settings ***

Documentation  Compare processor speeds in turbo and non-turbo modes.

# Test Parameters:
# OPENBMC_HOST   The BMC host name or IP address.
# OS_HOST        The OS host name or IP Address.
# OS_USERNAME    The OS login userid (usually root).
# OS_PASSWORD    The password for the OS login.

Resource        ../syslib/utils_os.robot
Library         ../syslib/utils_keywords.py
Variables       ../data/variables.py
Resource        ../lib/connection_client.robot
Resource        ../lib/resource.txt
Resource        ../lib/rest_client.robot


Suite Setup     Run Key  Start SOL Console Logging
Test Setup      Pre Test Case Execution
Test Teardown   Post Test Case Execution


*** Variables ****

${stack_mode}  skip
${command}     ppc64_cpu --frequency | grep max | cut -f 2 | cut -d' ' -f 1
# The ppc64_cpu --frequency command returns min, max, and average
# cpu frequencies. For example,
# min:    2.500 GHz (cpu 143)
# max:    2.700 GHz (cpu 1)
# avg:    2.600 GHz 
# The ${command} selects the max: line, selects only the
# 2.700 GHz (cpu 1) part, then selects the 2.700 number.


*** Test Cases ***

Processor Turbo Non-Turbo Speed Test
    [Documentation]  Compare processor turbo and non-turbo speeds.
    [Tags]  Progessor_Turbo_Non-Turbo_Speed_Test

    # Save the initial system turbo setting.  Restore this value
    # when testing is done.
    ${initial_turbo_setting}=  Read The Turbo Mode Setting
    Set Suite Variable  ${initial_turbo_setting}  children=true

    Set Turbo Enablement  True
    ${mode_now}=  Read The Turbo Mode Setting
    Run Keyword If  '${mode_now}' != 'True'
    ...  Fail  Issued call to set Turbo mode but it was not set.

    ${cpu_freq_turbo}=  Get Processor Max Speed Setting

    Set Turbo Enablement  False
    ${mode_now}=  Read The Turbo Mode Setting
    Run Keyword If  '${mode_now}' != 'False'
    ...  Fail  Issued call to disable Turbo mode but it was not disabled

    ${cpu_freq_non_turbo}=  Get Processor Max Speed Setting

    Rprintn
    Rpvars  cpu_freq_turbo  cpu_freq_non_turbo

    Run Keyword If  '${cpu_freq_turbo}' <= '${cpu_freq_non_turbo}'  Fail
    ...  Reported turbo processor speed should be greater than non-turbo speed


*** Keywords ***

Get Processor Max Speed Setting
    [Documentation]  Get Processor Maximum Speed Setting from the OS.
    # Test Flow:
    # - Power on the OS.
    # - Establish SSH connection session.
    # - On the OS run: ppc64_cpu --frequency
    # - Return the max frequency value reported by that command.
    # - Power off.

    Boot To OS

    # After power off or on, the OS SSH session needs to be established.
    Login To OS

    # Get the maximum processor frequency reported.
    ${status}=  Execute Command On OS  ${command}

    Rprintn
    Rpvars  ${command}  ${status}

    Power Off Host

    Close All Connections

    ${frequency}=  Convert To Number  ${status}
    [Return]  ${frequency}


Set Turbo Enablement
    [Documentation]  Set turbo mode.
    [Arguments]    ${mode}
    # Description of argument(s):
    # mode     Value to be set (False, True, or ${0}).
    Open Connection And Log In
    ${valueDict}=  Create Dictionary  data=${mode}
    Write Attribute  ${SENSORS_URI}host/TurboAllowed  value  data=${valueDict}


Read The Turbo Mode Setting
    [Documentation]  Read the value of the turbo mode setting.
    Open Connection And Log In
    ${resp}=  OpenBMC Get Request  ${SENSORS_URI}host/TurboAllowed
    ${jsondata}=  To JSON  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    [Return]  ${jsondata["data"]["value"]}


Restore Original Turbo Setting
    [Documentation]  Restore original turbo setting.
    Open Connection And Log In
    Set Turbo Setting Via REST  ${initial_turbo_setting}
    Close All Connections


Post Test Case Execution
    [Documentation]  Do the post test teardown.
    # 1. Restore original turbo setting on the system.
    # 2. Capture FFDC on test failure.
    # 3. Close all open SSH connections.

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Key  ${keyword_buf}

    Restore Original Turbo Setting

    FFDC On Test Case Fail
    Close All Connections
