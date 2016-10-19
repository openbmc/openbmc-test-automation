*** Settings ***
Documentation      This module is for triggering data collection on demand
...                by manually runing this robot suite.
...                Usage:
...                python -m robot -v OPENBMC_HOST:xx.xx.xx.xx myffdc.robot
...                Logs will be generated as show below
...                logs/
...                ├── 20161018222341758558_Myffdc
...                │   └── 20161018222341758558_MyFFDCLogs
...                │       ├── 20161018222341758558_BMC_dmesg
...                │       ├── 20161018222341758558_BMC_inventory
...                │       ├── 20161018222341758558_BMC_journalctl.log
...                │       ├── 20161018222341758558_BMC_led
...                │       ├── 20161018222341758558_BMC_proc_list
...                │       ├── 20161018222341758558_BMC_sensor_list
...                │       └── 20161018222341758558_ffdc_report.txt
...                └── test_history.txt

Resource           ../lib/openbmc_ffdc.robot

Test Teardown      Log FFDC

*** Test Cases ***

My FFDC Logs
    [Documentation]  Force fail to trigger FFDC collection
    Fail   msg=Manual FFDC collection

