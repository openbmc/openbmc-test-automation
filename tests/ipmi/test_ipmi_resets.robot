*** Settings ***
Documentation    Module to test IPMI cold and warm reset functionalities.

Resource         ../../lib/ipmi_client.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/state_manager.robot
Resource         ../../lib/utils.robot

Suite Setup      Suite Setup Execution
Test Teardown    FFDC On Test Case Fail

*** Variables ***

# User may pass LOOP_COUNT.
${LOOP_COUNT}  ${1}

*** Test Cases ***

Test IPMI Warm Reset
    [Documentation]  Check IPMI warm reset and wait for BMC to become online.
    [Tags]  Test_IPMI_Warm_Reset

    Repeat Keyword  ${LOOP_COUNT} times
    ...  Reset BMC Via IPMI  warm


Test IPMI Cold Reset
    [Documentation]  Check IPMI cold reset and wait for BMC to become online.
    [Tags]  Test_IPMI_Cold_Reset

    Repeat Keyword  ${LOOP_COUNT} times
    ...  Reset BMC Via IPMI  cold


*** Keywords ***

Reset BMC Via IPMI
    [Documentation]  Reset BMC via IPMI (eg. "warm" or "cold").
    [Arguments]  ${reset_type}  ${value}

    # Description of argument(s):
    # reset_type  The type of reset to do (either "warm" or "cold").
    # value       Command output string (eg. "Sent warm reset command to MC").

    ${resp}=  Run IPMI Standard Command  mc reset ${cmd}

    Run Keyword If  "${reset_type}" == "cold"
    ...     Should Be Equal As Strings  ${resp}  Sent cold reset command to MC
    ...  ELSE
    ...     Should Be Equal As Strings  ${resp}  Sent warm reset command to MC

    # Takes few seconds to reset BMC.
    Wait Until Keyword Succeeds  30 sec  10 sec
    ...  Check If WarmReset Is Initiated

    Check If BMC Is Up

    Wait For BMC Ready


Suite Setup Execution
    [Documentation]  Power off and wait for chassis power to be off.

    ${resp}=  Run IPMI Standard Command  chassis power off
    Should Be Equal As Strings  ${resp}  Chassis Power Control: Down/Off

    Wait Until Keyword Succeeds  3 min  20 sec  Is Chassis Power Off


Is Chassis Power Off
    [Documentation]  Check for chassis power to be off.

    ${resp}=  Run IPMI Standard Command  chassis power status
    Should Be Equal As Strings  ${resp}  Chassis Power is off
