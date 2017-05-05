*** Settings ***
Documentation      Get and verify system information.

Resource           ../syslib/utils_os.robot

*** Variables ***

*** Keywords ***
Get Pnor Info
    [Documentation]  Get Pnor Information.
    ${version}  ${stderr}=  Execute Command  pflash -r /dev/stdout -P VERSION
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Log  ${\n}version: ${version}  console=yes
    [Return]  ${version}

Get Inventory
    [Documentation]  Return Inventory.
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
    [Documentation]  Verify Memory Count.
    [Arguments]  ${expected_memory_count}
    ${memory_count}=  Get Memory Count
    Log  ${\n}memory count: ${memory_count}  console=yes
    Should Be Equal As Integers  ${memory_count}  ${expected_memory_count}  
    ...  Error: memory count doesn't match expected count.

Get Dimm Count
    [Documentation]  Get Dimm Count.
    ${dimm_count}  ${stderr}=  Execute Command  lshw -short | grep DIMM | wc -l
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Log  ${\n}dimm_count: ${dimm_count}  console=yes
    [Return]  ${dimm_count}

Verify Dimm Count
    [Documentation]  Verify Dimm Count.
    [Arguments]  ${expected_dimm_count}
    ${dimm_count}=  Get Dimm Count
    Log  ${\n}dimm_count: ${dimm_count}  console=yes
    Should Be Equal As Integers  ${dimm_count}  ${expected_dimm_count}
    ...  Error: dimm count doesn't match expected count. 

Verify Opal-Prd Installed
    [Documentation]  Check whether opal-prd.service is installed on OS.
    ${output}  ${stderr}=  Execute Command  systemctl status opal-prd.service
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Log  ${\n}${output}  console=yes
    Should Not Contain  ${output}  could not be found 
    ...  msg=Error: opal-prd.service is not installed.

Verify HTX Tool Installed
    [Documentation]  Check whether HTX exerciser is installed on OS.
    Login To OS
    ${output}  ${stderr}=  Execute Command On OS  which htxcmdline
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${output}  htxcmdline
    ...  msg=Please install HTX exerciser.
