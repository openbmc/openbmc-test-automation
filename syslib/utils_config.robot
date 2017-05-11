*** Settings ***
Documentation      Keywords for system data information.

Resource           ../syslib/utils_os.robot

*** Variables ***

*** Keywords ***
Get PNOR Info
    [Documentation]  Get PNOR information.
    ${version}  ${stderr}=  Execute Command  pflash -r /dev/stdout -P VERSION
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Log  ${\n}version: ${version}  console=yes
    [Return]  ${version}

Get Inventory
    [Documentation]  Get system inventory.
    ${inventory}  ${stderr}=  Execute Command  lshw -short  return_stderr=True
    Should Be Empty  ${stderr}
    Log  ${\n}inventory: ${inventory}  console=yes
    [Return]  ${inventory}

Get Memory Count
    [Documentation]  Get Memory Count.
    ${memory_count}  ${stderr}=
    ...  Execute Command  lshw -short | grep memory | wc -l  return_stderr=True
    Should Be Empty  ${stderr}
    Log  ${\n}memory count: ${memory_count}  console=yes
    [Return]  ${memory_count}

Verify Memory Count
    [Documentation]  Verify memory count.
    [Arguments]  ${expected_memory_count}
    ${memory_count}=  Get Memory Count
    Log  ${\n}memory count: ${memory_count}  console=yes
    Should Be Equal As Integers  ${memory_count}  ${expected_memory_count}
    ...  Error: memory count doesn't match expected count.

Get Dimm Count
    [Documentation]  Get DIMM count.
    ${dimm_count}  ${stderr}=  Execute Command  lshw -short | grep DIMM | wc -l
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Log  ${\n}dimm_count: ${dimm_count}  console=yes
    [Return]  ${dimm_count}

Verify Dimm Count
    [Documentation]  Verify DIMM count.
    [Arguments]  ${expected_dimm_count}
    ${dimm_count}=  Get Dimm Count
    Log  ${\n}dimm_count: ${dimm_count}  console=yes
    Should Be Equal As Integers  ${dimm_count}  ${expected_dimm_count}
    ...  msg=Error: dimm count doesn't match expected count.

Verify Opal-Prd Installed
    [Documentation]  Check whether opal-prd.service is running on OS.
    ${output}  ${stderr}=  Execute Command  systemctl status opal-prd.service
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Log  ${\n}${output}  console=yes
    Should Not Contain  ${output}  could not be found
    ...  msg=Error: opal-prd.service is not installed.

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
