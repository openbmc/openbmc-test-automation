*** Settings ***
Documentation      This module is for triggering data collection on demand
...                by manually running this robot suite.
...                Usage:
...                python -m robot -v OPENBMC_HOST:xx.xx.xx.xx myffdc.robot
...                Logs will be generated as shown below
...                logs
...                └── 20161020045522673810_Myffdc
...                    └── 20161020045522673810_MyFFDCLogs
...                        ├── 20161020045522673810_MyFFDCLogs
...                        ├── 20161020045522673810_BMC_dmesg
...                        ├── 20161020045522673810_BMC_inventory
...                        ├── 20161020045522673810_BMC_journalctl.log
...                        ├── 20161020045522673810_BMC_led
...                        ├── 20161020045522673810_BMC_proc_list
...                        ├── 20161020045522673810_BMC_record_log
...                        ├── 20161020045522673810_BMC_sensor_list
...                        └── 20161020045522673810_ffdc_report.txt

Resource           ../lib/openbmc_ffdc.robot

Test Teardown      Log FFDC If Test Case Failed

*** Test Cases ***

My FFDC Logs
    [Documentation]  Force fail to trigger FFDC collection
    Log To Console   Manual FFDC collection

