*** Settings ***
Documentation    Module to test IPMI cold and warm reset functionalities.

Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot

Test Teardown    FFDC On Test Case Fail

*** Variables ***

# User may pass LOOP_COUNT.
${LOOP_COUNT}  ${1}

${power_on_timeout}       15 mins
${power_off_timeout}      15 mins
${state_change_timeout}   3 mins

*** Test Cases ***

Test IPMI Warm Reset
    [Documentation]  Check IPMI warm reset and wait for BMC to become online.
    [Tags]  Test_IPMI_Warm_Reset
    Repeat Keyword  ${LOOP_COUNT} times  IPMI MC Reset Warm (off)


Test IPMI Cold Reset
    [Documentation]  Check IPMI cold reset and wait for BMC to become online.
    [Tags]  Test_IPMI_Cold_Reset

    Repeat Keyword  ${LOOP_COUNT} times  IPMI MC Reset Cold (off)


Verify BMC Power Cycle via IPMI
    [Documentation]  Verify IPMI power cycle command works fine.
    [Tags]  Verify_BMC_Power_Cycle_via_IPMI

    Redfish Power On  stack_mode=skip  quiet=1
    Run IPMI Standard Command  chassis power cycle
    Wait Until Keyword Succeeds  3 min  10 sec  Is IPMI Chassis Off
    Wait Until Keyword Succeeds  3 min  10 sec  Is IPMI Chassis On

    ${state}=  Get State
    ${match_state}=  Anchor State  ${state}
    ${state}=  Wait State  ${match_state}  wait_time=${state_change_timeout}  interval=10 seconds  invert=1
    ${state}=  Wait State  os_running_match_state  wait_time=${power_on_timeout}  interval=10 seconds



*** Keywords ***

Is IPMI Chassis Off
    [Documentation]  Check if chassis state is "Off" via IPMI.
    ${power_state}=  Get Chassis Power State
    Should Be Equal  ${power_state}  Off


Is IPMI Chassis On
    [Documentation]  Check if chassis state is "On" via IPMI.
    ${power_state}=  Get Chassis Power State
    Should Be Equal  ${power_state}  On
