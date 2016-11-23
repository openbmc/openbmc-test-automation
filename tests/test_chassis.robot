*** Settings ***
Documentation          This suite tests IPMI chassis status in Open BMC.

Resource               ../lib/rest_client.robot
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/utils.robot

Suite Setup            Open Connection And Log In
Suite Teardown         Close All Connections
Test Teardown          FFDC On Test Case Fail

*** Test Cases ***

IPMI Chassis Status On
    [Documentation]   This test case verfies system power on status
    ...               using IPMI Get Chassis status command
    [Tags]  IPMI_Chassis_Status_On

    Initiate Power On
    ${resp} =    Run IPMI Standard Command    chassis status
    ${lines} =    Get Lines Containing String    ${resp}    System Power
    Should Contain    ${lines}    on

IPMI Chassis Status Off
    [Documentation]   This test case verfies system power off status
    ...               using IPMI Get Chassis status command
    [Tags]  IPMI_Chassis_Status_Off

    Initiate Power Off
    ${resp} =    Run IPMI Standard Command    chassis status
    ${lines} =    Get Lines Containing String    ${resp}    System Power
    Should Contain    ${lines}    off


