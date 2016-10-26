*** Settings ***
Documentation      This module is for data collection on test case failure
...                for openbmc systems. Collects data with default name
...                ffdc_report.txt under directory logs/testSuite/testName/
...                on failure.
...                FFDC logging sample layout:
...                logs
...                ├── 20160909102538035251_TestWarmreset
...                │   └── 20160909102538035251_TestWarmResetviaREST
...                │       ├── 20160909102538035251_BMC_journalctl
...                │       ├── 20160909102538035251_BMC_proc_list
...                │       ├── 20160909102538035251_BMC_dmesg
...                │       ├── 20160909102538035251_BMC_inventory
...                │       ├── 20160909102538035251_BMC_led
...                │       ├── 20160909102538035251_BMC_record_log
...                │       ├── 20160909102538035251_BMC_sensor_list
...                │       ├── 20160909102538035251_BMC_general 
...                │       ├── 20160909102538035251_OS_dmesg
...                │       ├── 20160909102538035251_OS_msglog
...                │       ├── 20160909102538035251_OS_cpufrequency
...                │       ├── 20160909102538035251_OS_boot
...                │       ├── 20160909102538035251_OS_isusb
...                │       ├── 20160909102538035251_OS_kern
...                │       ├── 20160909102538035251_OS_authlog
...                │       ├── 20160909102538035251_OS_syslog
...                │       ├── 20160909102538035251_OS_info
...                │       ├── 20160909102538035251_OS_rsct
...                │       └── 20160909102538035251_OS_secure
...                └── test_history.txt

Resource           openbmc_ffdc_methods.robot
Resource           openbmc_ffdc_utils.robot

*** Keywords ***

Log FFDC
    [Documentation]   Generic FFDC entry point. Place holder to hook in
    ...               other data collection methods
    ...               1. Collect Logs if test fails
    ...               2. Added Test execution history logging
    ...                  By default this will log Test status PASS/FAIL format
    ...                  EX: 20160822041250932049:Test:Test case 1:PASS
    ...                      20160822041250969913:Test:Test case 2:FAIL

    Run Keyword If  '${TEST_STATUS}' == 'FAIL'
    ...    Log FFDC If Test Case Failed

    Log Test Case Status


Log FFDC If Test Case Failed
    [Documentation]   Main entry point to gather logs on Test case failure
    ...               1. Set global FFDC time reference for a failure
    ...               2. Create FFDC work space directory
    ...               3. Write test info details
    ...               4. Calls BMC methods to write/collect FFDC data

    ${cur_time}=      Get Current Time Stamp
    Set Global Variable    ${FFDC_TIME}     ${cur_time}
    Log To Console    ${\n}FFDC Collection Started \t: ${cur_time}

    # Log directory setup
    ${suitename}   ${testname}=    Get Test Dir and Name

    Set Global Variable
    ...   ${FFDC_DIR_PATH}  ${FFDC_LOG_PATH}${suitename}${/}${testname}

    ${prefix}=   Catenate  SEPARATOR=   ${FFDC_DIR_PATH}${/}   ${FFDC_TIME}_
    Set Global Variable    ${LOG_PREFIX}    ${prefix}

    Create FFDC Directory
    Header Message

    # -- FFDC processing entry point --
    Call FFDC Methods

    ${cur_time}=       Get Current Time Stamp
    Log To Console     FFDC Collection Completed \t: ${cur_time}
    Log                ${\n}${FFDC_DIR_PATH}
