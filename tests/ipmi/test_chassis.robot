*** Settings ***
Documentation          This suite tests IPMI chassis status in Open BMC.

Resource               ../../lib/rest_client.robot
Resource               ../../lib/ipmi_client.robot
Resource               ../../lib/openbmc_ffdc.robot
Resource               ../../lib/utils.robot
Resource               ../../lib/resource.txt
Resource               ../../lib/state_manager.robot

Suite Setup            Open Connection And Log In
Suite Teardown         Close All Connections
Test Teardown          Test Exit Logs

*** Test Cases ***

IPMI Chassis Status On
    [Documentation]  This test case verfies system power on status
    ...               using IPMI Get Chassis status command.
    [Tags]  IPMI_Chassis_Status_On

    Initiate Host Boot
    ${resp}=  Run IPMI Standard Command  chassis status
    ${power_status}=  Get Lines Containing String  ${resp}  System Power
    Should Contain  ${power_status}  on

IPMI Chassis Status Off
    [Documentation]  This test case verfies system power off status
    ...               using IPMI Get Chassis status command.
    [Tags]  IPMI_Chassis_Status_Off

    Initiate Host PowerOff
    ${resp}=  Run IPMI Standard Command  chassis status
    ${power_status}=  Get Lines Containing String  ${resp}  System Power
    Should Contain  ${power_status}    off

IPMI Chassis Restore Power Policy
     [Documentation]  Verfy IPMI chassis restore power policy.
     [Tags]  IPMI_Chassis_Restore_Power_Policy

     ${initial_power_policy}=  Read Attribute
     ...  ${CONTROL_HOST_URI}/power_restore_policy  PowerRestorePolicy

     Set BMC Power Policy  ${ALWAYS_POWER_ON}
     ${resp}=  Run IPMI Standard Command  chassis status
     ${power_status}=
     ...  Get Lines Containing String  ${resp}  Power Restore Policy
     Should Contain  ${power_status}  always-on

     Set BMC Power Policy  ${RESTORE_LAST_STATE}
     ${resp}=  Run IPMI Standard Command  chassis status
     ${power_status}=
     ...  Get Lines Containing String  ${resp}  Power Restore Policy
     Should Contain  ${power_status}  previous

     Set BMC Power Policy  ${ALWAYS_POWER_OFF}
     ${resp}=    Run IPMI Standard Command  chassis status
     ${power_status}=
     ...  Get Lines Containing String  ${resp}  Power Restore Policy
     Should Contain  ${power_status}    always-off

     Set BMC Power Policy  ${initial_power_policy}
     ${power_policy}=  Read Attribute
     ...  ${CONTROL_HOST_URI}/power_restore_policy  PowerRestorePolicy
     Should Be Equal  ${power_policy}  ${initial_power_policy}

Verify Host PowerOn Via IPMI
    [Documentation]   Verify host power on status using external IPMI command.
    [Tags]  Verify_Host_PowerOn_Via_IPMI

    Initiate Host Boot Via External IPMI

Verify Host PowerOff Via IPMI
    [Documentation]   Verify host power off status using external IPMI command.
    [Tags]  Verify_Host_PowerOff_Via_IPMI

    Initiate Host PowerOff Via External IPMI


*** Keywords ***

Test Exit Logs
    [Documentation]    Log FFDC if test failed.

    Set BMC Power Policy  ${ALWAYS_POWER_OFF}

    FFDC On Test Case Fail
