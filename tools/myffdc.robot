*** Settings ***
Documentation      This module is for triggering data collection on demand
...                by manually running this robot suite.
...                Usage:
...                python -m robot -v OPENBMC_HOST:xx.xx.xx.xx myffdc.robot
...                Logs will be generated as shown below
...                logs
...                └── 20161020045522673810_Myffdc
...                    └── 20161020045522673810_MyFFDCLogs
...                        ├── 20161020045522673810_BMC_journalctl.txt
...                        ├── 20161020045522673810_BMC_proc_list.txt
...                        ├── 20161020045522673810_BMC_dmesg.txt
...                        ├── 20161020045522673810_BMC_inventory.txt
...                        ├── 20161020045522673810_BMC_led.txt
...                        ├── 20161020045522673810_BMC_record_log.txt
...                        ├── 20161020045522673810_BMC_sensor_list.txt
...                        ├── 20161020045522673810_BMC_general.txt
...                        ├── 20161020045522673810_OS_dmesg.txt
...                        ├── 20161020045522673810_OS_msglog.txt
...                        ├── 20161020045522673810_OS_cpufrequency.txt
...                        ├── 20161020045522673810_OS_boot.txt
...                        ├── 20161020045522673810_OS_isusb.txt
...                        ├── 20161020045522673810_OS_kern.txt
...                        ├── 20161020045522673810_OS_authlog.txt
...                        ├── 20161020045522673810_OS_syslog.txt
...                        ├── 20161020045522673810_OS_info.txt
...                        ├── 20161020045522673810_OS_rsct.txt
...                        └── 20161020045522673810_OS_secure.txt


Resource           ../lib/openbmc_ffdc.robot

Test Teardown      Gather FFDC

*** Test Cases ***

My FFDC Logs
    [Documentation]  This test is needed to satisfy FFDC initial setup auto
    ...              variables required for FFDC collection.
    Log To Console   Manual FFDC collection

** Keywords ***

Gather FFDC
    [Documentation]  Collect FFDC.
    Run Keyword And Ignore Error   FFDC
