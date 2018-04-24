*** Settings ***

Documentation  Compare processor speed in turbo and non-turbo modes.

# Test Parameters:
# OPENBMC_HOST   The BMC host name or IP address.
# OS_HOST        The OS host name or IP Address.
# OS_USERNAME    The OS login userid (usually root).
# OS_PASSWORD    The password for the OS login.

# Approximate run time:  8 minutes.

Resource         ../syslib/utils_os.robot
Resource         ../lib/rest_client.robot


Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


*** Test Cases ***

Test Turbo Processor Speed
    [Documentation]  Turbo and non-turbo speed compare.
    [Tags]  Turbo_Processor_Speed_Test

    # Enable turbo mode.
    Set Turbo Setting Via REST  1  verify=${True}

    Start SOL Console Logging
    REST Power On  stack_mode=normal
    Tool Exist  ppc64_cpu

    ${proc_speed_turbo}=  Get CPU Max Frequency

    Rest Power Off

    # Disable turbo mode.
    Set Turbo Setting Via REST  0  verify=${True}

    REST Power On  stack_mode=normal
    ${proc_speed_non_turbo}=  Get CPU Max Frequency

    Rprintn
    Rpvars  proc_speed_turbo  proc_speed_non_turbo

    ${err_msg}=  Catenate  Reported turbo processor speed should be
    ...  greater than non-turbo speed.
    Should Be True  ${proc_speed_turbo} > ${proc_speed_non_turbo}
    ...  msg=${err_msg}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do the pre-test setup.

    REST Power Off  stack_mode=skip


Test Teardown Execution
    [Documentation]  Do the post-test teardown.

    FFDC On Test Case Fail

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Key  ${keyword_buf}

    Set Turbo Setting Via REST  True
