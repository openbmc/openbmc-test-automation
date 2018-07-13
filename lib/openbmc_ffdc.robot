*** Settings ***
Documentation      This module is for data collection on test case failure
...                for openbmc systems. Collects data with default name
...                ffdc_report.txt under directory logs/testSuite/testName/
...                on failure.
...                FFDC logging sample layout:
...                logs
...                ├── 20160909102538035251_TestWarmreset
...                │   └── 20160909102538035251_TestWarmResetviaREST
...                │       ├── 20160909102538035251_BMC_journalctl.txt
...                │       ├── 20160909102538035251_BMC_proc_list.txt
...                │       ├── 20160909102538035251_BMC_dmesg.txt
...                │       ├── 20160909102538035251_BMC_inventory.txt
...                │       ├── 20160909102538035251_BMC_led.txt
...                │       ├── 20160909102538035251_BMC_record_log.txt
...                │       ├── 20160909102538035251_BMC_sensor_list.txt
...                │       ├── 20160909102538035251_BMC_general.txt
...                │       ├── 20160909102538035251_OS_dmesg.txt
...                │       ├── 20160909102538035251_OS_msglog.txt
...                │       ├── 20160909102538035251_OS_cpufrequency.txt
...                │       ├── 20160909102538035251_OS_boot.txt
...                │       ├── 20160909102538035251_OS_isusb.txt
...                │       ├── 20160909102538035251_OS_kern.txt
...                │       ├── 20160909102538035251_OS_authlog.txt
...                │       ├── 20160909102538035251_OS_syslog.txt
...                │       ├── 20160909102538035251_OS_info.txt
...                │       ├── 20160909102538035251_OS_rsct.txt
...                │       ├── 20160909102538035251_OS_secure.txt
...                │       └── 20160909102538035251_OS_esel
...                └── test_history.txt

Resource           openbmc_ffdc_methods.robot
Resource           openbmc_ffdc_utils.robot
Resource           dump_utils.robot
Library            openbmc_ffdc.py

*** Keywords ***

FFDC On Test Case Fail
    [Documentation]   Generic FFDC entry point. Place holder to hook in
    ...               other data collection methods
    ...               1. Collect Logs if test fails or host reaches quiesced
    ...                  state.
    ...               2. Added test execution history logging.
    ...                  By default this will log Test status PASS/FAIL format
    ...                  EX: 20160822041250932049:Test:Test case 1:PASS
    ...                      20160822041250969913:Test:Test case 2:FAIL
    ...               3. Delete error logs and BMC dumps post FFDC collection.

    Run Keyword If  '${TEST_STATUS}' == 'FAIL'  FFDC

    Log Test Case Status

    # Clean up error logs and BMC dumps.
    Run Keyword If  '${TEST_STATUS}' == 'FAIL'
    ...  Run Keywords  Delete All Error Logs  AND  Delete All Dumps
