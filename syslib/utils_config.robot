*** Settings ***
Documentation      Keywords for system verification.

Resource  ../syslib/utils_os.robot

*** Variables ***

*** Keywords ***


Verify No Gard Records
    [Documentation]  Verify no gard records are present on OS.
    ${output}  ${stderr}=  Execute Command  opal-gard list
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${output}  No GARD entries to display

Verify No Error Logs
    [Documentation]  Verify no error logs.
    ${output}  ${stderr}=  Execute Command  dmesg -xT -l emerg,alert,crit,err
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Should Be Empty  ${output}
