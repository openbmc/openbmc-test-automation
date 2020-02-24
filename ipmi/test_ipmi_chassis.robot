*** Settings ***

Documentation    Module to test IPMI chassis functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot

Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

IPMI Chassis Status On
    [Documentation]  This test case verfies system power on status
    ...               using IPMI Get Chassis status command.
    [Tags]  IPMI_Chassis_Status_On

    Redfish Power On  stack_mode=skip  quiet=1
    ${resp}=  Run IPMI Standard Command  chassis status
    ${power_status}=  Get Lines Containing String  ${resp}  System Power
    Should Contain  ${power_status}  on

IPMI Chassis Status Off
    [Documentation]  This test case verfies system power off status
    ...               using IPMI Get Chassis status command.
    [Tags]  IPMI_Chassis_Status_Off

    Redfish Power Off  stack_mode=skip  quiet=1
    ${resp}=  Run IPMI Standard Command  chassis status
    ${power_status}=  Get Lines Containing String  ${resp}  System Power
    Should Contain  ${power_status}  off

Verify Host PowerOff Via IPMI
    [Documentation]   Verify host power off operation using external IPMI command.
    [Tags]  Verify_Host_PowerOff_Via_IPMI

    IPMI Power Off
    ${ipmi_state}=  Get Host State Via External IPMI
    Valid Value  ipmi_state  ['off']

Verify Host PowerOn Via IPMI
    [Documentation]   Verify host power on operation using external IPMI command.
    [Tags]  Verify_Host_PowerOn_Via_IPMI

    IPMI Power On
    ${ipmi_state}=  Get Host State Via External IPMI
    Valid Value  ipmi_state  ['on']


Verify Soft Shutdown
    [Documentation]  Verify host OS shutdown softly via IPMI command.
    [Tags]  Verify_Soft_Stutdown

    Redfish Power On  stack_mode=skip
    Run IPMI Standard Command  chassis power soft
    Wait Until Keyword Succeeds  3 min  10 sec  Is Host Off Via IPMI

