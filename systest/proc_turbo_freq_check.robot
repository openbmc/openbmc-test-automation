*** Settings ***

Documentation  Compare processor speed in turbo and non-turbo modes.

# Test Parameters:
# OPENBMC_HOST   The BMC host name or IP address.
# OS_HOST        The OS host name or IP Address.
# OS_USERNAME    The OS login userid (usually root).
# OS_PASSWORD    The password for the OS login.

# Approximate run time:  8 minutes.

Resource        ../syslib/utils_os.robot
Resource        ../lib/rest_client.robot


Test Setup      Test Setup Execution
Test Teardown   Test Teardown Execution


*** Test Cases ***

Turbo Processor Speed Test
    [Documentation]  Turbo and non-turbo speed compare.
    [Tags]  Turbo_Processor_Speed_Test

    Set Turbo Setting Via REST  True
    ${mode}=  Read Turbo Setting Via REST
    Should Be Equal  ${mode}  ${1}
    ...  msg=Issued call to set TurboAllowed but it was not set.

    Start SOL Console Logging
    REST Power On  stack_mode=skip
    Tool Exist  ppc64_cpu

    ${proc_speed_turbo}=  Get CPU Max Frequency

    Smart Power Off

    Set Turbo Setting Via REST  False
    ${mode}=  Read Turbo Setting Via REST
    Should Be Equal  ${mode}  ${0}
    ...  msg=Issued call to disable TurboAllowed but it was not disabled.

    REST Power On  stack_mode=skip
    ${proc_speed_non_turbo}=  Get CPU Max Frequency

    Rprintn
    Rpvars  proc_speed_turbo  proc_speed_non_turbo

    ${err_msg}=  Catenate  Reported turbo processor speed should be
    ...  greater than non-turbo speed.
    Should Be True  ${proc_speed_turbo} > ${proc_speed_non_turbo}
    ...  msg=${err_msg}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do the pre test setup.

    REST Power Off  stack_mode=skip


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail

    REST Power Off  stack_mode=skip

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Key  ${keyword_buf}

    Set Turbo Setting Via REST  True
