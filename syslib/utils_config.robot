*** Settings ***
Documentation      Keywords for system verification tests.

Library            ../lib/gen_robot_keyword.py
Library            ../lib/state.py
Resource           ../extended/obmc_boot_test_resource.robot
Resource           ../lib/utils.robot
Resource           ../lib/state_manager.robot

*** Variables ***

*** Keywords ***


Verify BMC State
    [Documentation]  Verify BMC State. ex. Ready
    [Arguments]  ${expected_bmc_state}
    ${bmc_state}=  Get BMC State 
    Should Be Equal  ${bmc_state}  ${expected_bmc_state}

Verify Chassis State
    [Documentation]  Verify CHASSIS State. ex. On
    [Arguments]  ${expected_chassis_state}
    ${chassis_state}=  Get Chassis Power State 
    Should Be Equal  ${chassis_state}  ${expected_chassis_state}

Verify Host State
    [Documentation]  Verify HOST State.  ex. Quiesced
    [Arguments]  ${expected_host_state}
    ${state_dict}=  Get State  ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ${host_state}=  Evaluate  $state_dict.get('host')
    Should Be Equal  ${host_state}  ${expected_host_state}

Verify OS State
    [Documentation]  Verify OS State. ex. 'os_ping', 'os_login', 'os_run_cmd' 
    [Arguments]  ${expected_os_state}
    ${os_state_dict}=  Get OS State  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    ${os_state}=  Evaluate  $os_state_dict.get(${expected_os_state})
    Should Be Equal   ${os_state}  ${1} 

Verify No Gard Records
    [Documentation]  Verify no gard records are present on OS.
    ${output}=  Execute Command On OS opal-gard list
    Should Not Contain  ${output}  No GARD Entries To Display

