*** Settings ***
Documentation    Module to test IPMI cold and warm reset functionalities.

Resource         ../../lib/ipmi_client.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/state_manager.robot
Resource         ../../lib/utils.robot
Resource         ../../lib/boot_utils.robot

Suite Setup      Suite Setup Execution
Test Teardown    FFDC On Test Case Fail

*** Variables ***

# User may pass LOOP_COUNT.
${LOOP_COUNT}  ${1}

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

    REST Power On  stack_mode=skip
    Run External IPMI Standard Command  chassis power cycle
    Wait Until Keyword Succeeds  3 min  10 sec  Is Host Off
    Wait Until Keyword Succeeds  3 min  10 sec  Is Host Running

*** Keywords ***

Suite Setup Execution
    [Documentation]  Power off and wait for chassis power to be off.

    ${resp}=  Run IPMI Standard Command  chassis power off
    Should Be Equal As Strings  ${resp}  Chassis Power Control: Down/Off
    ...  msg=Unexpected chassis power control message output.

    Wait Until Keyword Succeeds  3 min  20 sec  Is Chassis Power Off


Is Chassis Power Off
    [Documentation]  Check for chassis power to be off.

    ${resp}=  Run IPMI Standard Command  chassis power status
    Should Be Equal As Strings  ${resp}  Chassis Power is off
    ...  msg=Chassis power is not off as expected.
