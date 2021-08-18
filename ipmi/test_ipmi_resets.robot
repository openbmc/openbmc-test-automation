*** Settings ***
Documentation    Module to test IPMI cold and warm reset functionalities.

Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot

Suite Setup      Redfish.Login
Suite Teardown   Redfish.Logout

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

    Repeat Keyword  ${LOOP_COUNT} times  IPMI MC Reset Cold (run)


Verify BMC Power Cycle via IPMI
    [Documentation]  Verify IPMI power cycle command works fine.
    [Tags]  Verify_BMC_Power_Cycle_via_IPMI

    Repeat Keyword  ${LOOP_COUNT} times  IPMI Power Cycle


Verify Power Reset via IPMI
    [Documentation]  Verify IPMI power reset command works fine.
    [Tags]  Verify_Power_Reset_via_IPMI

    Repeat Keyword  ${LOOP_COUNT} times  IPMI Power Reset
