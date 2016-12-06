*** Settings ***
Documentation          This suite tests IPMI chassis status in Open BMC.

Resource               ../../lib/rest_client.robot
Resource               ../../lib/ipmi_client.robot
Resource               ../../lib/openbmc_ffdc.robot
Resource               ../../lib/utils.robot
Resource               ../../lib/resource.txt

Suite Setup            Open Connection And Log In
Suite Teardown         Close All Connections
Test Teardown          FFDC On Test Case Fail

*** Variables ***
${HOST_SETTING}    ${OPENBMC_BASE_URI}settings/host0

*** Test Cases ***

IPMI Chassis Status On
    [Documentation]   This test case verfies system power on status
    ...               using IPMI Get Chassis status command
    [Tags]  IPMI_Chassis_Status_On

    Initiate Power On
    ${resp}=    Run IPMI Standard Command    chassis status
    ${power_status}=    Get Lines Containing String    ${resp}    System Power
    Should Contain    ${power_status}    on

IPMI Chassis Status Off
    [Documentation]   This test case verfies system power off status
    ...               using IPMI Get Chassis status command
    [Tags]  IPMI_Chassis_Status_Off

    Initiate Power Off
    ${resp}=    Run IPMI Standard Command    chassis status
    ${power_status}=    Get Lines Containing String    ${resp}    System Power
    Should Contain    ${power_status}    off

IPMI Chassis Restore Power Policy
     [Documentation]    This test case verfies IPMI Chassis Restore Power Policy

     [Tags]    IPMI_Chassis_Restore_Power_Policy

     ${inital_power_policy}=   Read Attribute  ${HOST_SETTING}    power_policy

     Set BMC Power Policy    ALWAYS_POWER_ON
     ${resp}=    Run IPMI Standard Command    chassis status
     ${power_status}=    Get Lines Containing String    ${resp}    Power Restore Policy
     Should Contain    ${power_status}    always-on


     Set BMC Power Policy    RESTORE_LAST_STATE
     ${resp}=    Run IPMI Standard Command    chassis status
     ${power_status}=    Get Lines Containing String    ${resp}    Power Restore Policy
     Should Contain    ${power_status}    previous


     Set BMC Power Policy    LEAVE_OFF
     ${resp}=    Run IPMI Standard Command    chassis status
     ${power_status}=    Get Lines Containing String    ${resp}    Power Restore Policy
     Should Contain    ${power_status}    always-off

     Set BMC Power Policy    ${inital_power_policy}
     ${power_policy}=   Read Attribute  ${HOST_SETTING}    power_policy
     Should Be Equal    ${power_policy}  ${inital_power_policy}

