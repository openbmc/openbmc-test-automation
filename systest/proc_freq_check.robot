*** Settings ***

Documentation  Check processor speed.

# Test Parameters:
# OPENBMC_HOST   The BMC host name or IP address.
# OS_HOST        The OS host name or IP Address.
# OS_USERNAME    The OS login userid (usually root).
# OS_PASSWORD    The password for the OS login.

Resource        ../syslib/utils_os.robot

Suite Setup      Run Keyword  Start SOL Console Logging
Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


*** Test Cases ***

Processor Speed Check
    [Documentation]  Check processor speed.
    [Tags]  Processor_Speed_Check

    ${actual_min_freq}=  Get CPU Min Frequency
    ${min_freq_designated_lower_limit}=  Get CPU Min Frequency Limit

    Rprintn
    Rpvars  actual_min_freq  min_freq_designated_lower_limit

    ${err_msg}=  Catenate  Reported CPU frequency below designated limit.
    Should Be True  ${actual_min_freq} >= ${min_freq_designated_lower_limit}
    ...  msg=${err_msg}

    ${actual_max_freq}=  Get CPU Max Frequency
    ${max_freq_designated_limit}=  Get CPU Max Frequency Limit

    Rpvars  actual_max_freq  max_freq_designated_limit

    ${err_msg}=  Catenate  Reported CPU frequency above designated limit.
    Should Be True  ${actual_max_freq} <= ${max_freq_designated_limit}
    ...  msg=${err_msg}

    Error Logs Should Not Exist


*** Keywords ***

Test Setup Execution
    [Documentation]  Do the pre-test setup.

    REST Power On  stack_mode=skip
    Delete All Error Logs
    Tool Exist  ppc64_cpu
    Tool Exist  lscpu


Test Teardown Execution
    [Documentation]  Do the post-test teardown.

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Key  ${keyword_buf}

    FFDC On Test Case Fail
    Power Off Host
    Close All Connections
