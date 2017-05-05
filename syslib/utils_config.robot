*** Settings ***
Documentation      Display and verify system information.

Library            ../lib/gen_robot_keyword.py
Resource           ../extended/obmc_boot_test_resource.robot
Resource           ../lib/utils.robot
Resource           ../lib/state_manager.robot

Resource           ../lib/resource.txt

*** Variables ***

*** Keywords ***
Display Pnor Info
    [Documentation]  Display Pnor Information
    ${version}=  Execute Command  pflash -r /dev/stdout -P VERSION
    Log  ${\n}version: ${version}  console=yes

Display Inventory
    [Documentation]  Display Inventory
    ${inventory}=  Execute Command  lshw -short
    Log  ${\n}inventory: ${inventory}  console=yes

Display Memory Count
    [Documentation]  Display Memory Count
    ${memory_count}=  Execute Command  lshw -short | grep memory | wc -l
    Log  ${\n}memory count: ${memory_count}  console=yes

Verify Memory Count
    [Documentation]  Verify Memory Count
    [Arguments]  ${expected_memory_count}
    ${memory_count}=  Execute Command  lshw -short | grep memory | wc -l
    Log  ${\n}memory count: ${memory_count}  console=yes
    Should Be Equal As Integers  ${memory_count}  ${expected_memory_count}  Error: memory count doesn't match expected count.

Display Dimm Count
    [Documentation]  Display Dimm Count
    ${dimm_count}=  Execute Command  lshw -short | grep DIMM | wc -l
    Log  ${\n}dimm_count: ${dimm_count}  console=yes

Verify Dimm Count
    [Documentation]  Verify Dimm Count
    [Arguments]  ${expected_dimm_count}
    ${dimm_count}=  Execute Command  lshw -short | grep DIMM | wc -l
    Log  ${\n}dimm_count: ${dimm_count}  console=yes
    Should Be Equal As Integers  ${dimm_count}  ${expected_dimm_count}  Error: dimm count doesn't match expected count. 

Verify Opal-Prd Installed
    [Documentation]  Check whether opal-prd.service is installed on OS.
    ${output}=  Execute Command  systemctl status opal-prd.service
    Log  ${\n}${output}  console=yes
    Should Not Contain  ${output}  could not be found  msg=Error: opal-prd.service is not installed.

Verify HTX Tool Installed
    [Documentation]  Check whether HTX exerciser is installed on OS.
    Login To OS
    ${output}=  Execute Command On OS  which htxcmdline
    Should Contain  ${output}  htxcmdline
    ...  msg=Please install HTX exerciser.
