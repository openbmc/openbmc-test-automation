*** Settings ***
Documentation      Keywords for system verification.

Library            ../lib/gen_robot_keyword.py
Library            ../lib/state.py
Resource           ../extended/obmc_boot_test_resource.robot
Resource           ../lib/utils.robot
Resource           ../lib/state_manager.robot

*** Variables ***

*** Keywords ***


Verify No Gard Records
    [Documentation]  Verify no gard records are present on OS.
    ${output}  ${stderr}=  Execute Command On OS opal-gard list
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${output}  No GARD Entries To Display
