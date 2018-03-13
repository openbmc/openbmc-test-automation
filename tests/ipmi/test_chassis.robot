*** Settings ***
Documentation          This suite tests IPMI chassis status in Open BMC.

Resource               ../../lib/rest_client.robot
Resource               ../../lib/ipmi_client.robot
Resource               ../../lib/openbmc_ffdc.robot
Resource               ../../lib/utils.robot
Resource               ../../lib/boot_utils.robot
Resource               ../../lib/resource.txt
Resource               ../../lib/state_manager.robot

Suite Setup            Open Connection And Log In
Suite Teardown         Close All Connections
Test Teardown          Test Teardown Execution

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

Verify Soft Shutdown via IPMI
    [Documentation]  Verify Host OS shutdown softly using IPMI command.
    [Tags]  Verify_Soft_Shutdown_via_IPMI

    REST Power On  stack_mode=skip
    Run External IPMI Standard Command  chassis power soft
    Wait Until Keyword Succeeds  3 min  10 sec  Is Host Off

Verify BMC Reset via IPMI
    [Documentation]  Verify BMC resets successfully using IPMI command.
    [Tags]  Verify_BMC_Reset_via_IPMI

    # Reset the BMC device with the IPMI command.
    Run External IPMI Standard Command  bmc reset warm
    # Verify if BMC is initiated to reboot
    ${session_active}=  Check If BMC Reboot Is Initiated
    Run Keyword If  '${session_active}' == '${True}'
    ...  Fail  msg=BMC Reset didn't occur.
    Check If BMC is Up   5 min    10 sec
    # After reset completes, check BMC is in ready state.
    Wait Until Keyword Succeeds  10 min  10 sec  Is BMC Ready

Verify BMC Power Cycle via IPMI
    [Documentation]  Verify IPMI power cycle command works fine.
    [Tags]  Verify_BMC_Power_Cycle_via_IPMI

    REST Power On  stack_mode=skip
    Run External IPMI Standard Command  chassis power cycle
    Wait Until Keyword Succeeds  3 min  10 sec  Is Host Off
    Wait Until Keyword Succeeds  3 min  10 sec  Is Host Running

*** Keywords ***

Test Teardown Execution
    [Documentation]    Log FFDC if test failed.

    Set BMC Power Policy  ${ALWAYS_POWER_OFF}

    FFDC On Test Case Fail
