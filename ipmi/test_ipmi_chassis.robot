*** Settings ***

Documentation    Module to test IPMI chassis functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/boot_utils.robot
Library          ../lib/ipmi_utils.py
Variables        ../data/ipmi_raw_cmd_table.py

Suite Setup      Redfish.Login
Suite Teardown   Redfish.Logout
Test Teardown    Test Teardown Execution

*** Variables ***

# Timeout value in minutes. Default 3 minutes.
${IPMI_POWEROFF_WAIT_TIMEOUT}    3

*** Test Cases ***

IPMI Chassis Status On
    [Documentation]  This test case verifies system power on status
    ...               using IPMI Get Chassis status command.
    [Tags]  IPMI_Chassis_Status_On

    Redfish Power On  stack_mode=skip  quiet=1
    ${resp}=  Run IPMI Standard Command  chassis status
    ${power_status}=  Get Lines Containing String  ${resp}  System Power
    Should Contain  ${power_status}  on

IPMI Chassis Status Off
    [Documentation]  This test case verifies system power off status
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
    [Tags]  Verify_Soft_Shutdown

    Redfish Power On  stack_mode=skip
    Run IPMI Standard Command  chassis power soft
    Wait Until Keyword Succeeds  ${IPMI_POWEROFF_WAIT_TIMEOUT} min  10 sec  Is Host Off Via IPMI


Verify Chassis Power Cycle And Check Chassis Status Via IPMI
    [Documentation]   Verify chassis power Cycle operation and check the Chassis
    ...               Power Status using external IPMI command.
    [Tags]  Verify_Chassis_Power_Cycle_And_Check_Chassis_Status_Via_IPMI

    # Chassis power cycle command via IPMI
    IPMI Power Cycle
    ${ipmi_state}=  Get Host State Via External IPMI
    Valid Value  ipmi_state  ['on']


Verify Chassis Power Reset And Check Chassis Status Via IPMI
    [Documentation]   Verify chassis power Reset operation and check the Chassis
    ...               Power Status using external IPMI command.
    [Tags]  Verify_Chassis_Power_Reset_And_Check_Chassis_Status_Via_IPMI

    # Chassis power reset command via IPMI
    IPMI Power Reset
    ${ipmi_state}=  Get Host State Via External IPMI
    Valid Value  ipmi_state  ['on']


Verify Chassis Power Policy
    [Documentation]  Verify setting chassis power policy via IPMI command.
    [Tags]  Verify_Chassis_Power_Policy
    [Setup]  Test Setup Execution
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Run IPMI Standard Command  chassis policy ${initial_power_policy}
    [Template]  Set Chassis Power Policy Via IPMI And Verify

    # power_policy
    always-off
    always-on
    previous


Verify Chassis Status Via IPMI
    [Documentation]  Verify Chassis Status via IPMI command.
    [Tags]  Verify_Chassis_Status_Via_IPMI
    [Setup]  Test Setup Execution
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Run IPMI Standard Command  chassis policy ${initial_power_policy}
    [Template]  Check Chassis Status Via IPMI

    # power_policy
    always-off
    always-on
    previous


*** Keywords ***

Set Chassis Power Policy Via IPMI And Verify
    [Documentation]  Set chasiss power policy via IPMI and verify.
    [Arguments]  ${power_policy}

    # Description of argument(s):
    # power_policy    Chassis power policy to be set(e.g. "always-off", "always-on").

    Run IPMI Standard Command  chassis policy ${power_policy}
    ${resp}=  Get Chassis Status
    Valid Value  resp['power_restore_policy']  ['${power_policy}']


Check Chassis Status Via IPMI
    [Documentation]  Set Chassis Status via IPMI and verify and verify chassis status.
    [Arguments]  ${power_policy}

    # Sets power policy according to requested policy
    Set Chassis Power Policy Via IPMI And Verify  ${power_policy}

    # Gets chassis status via IPMI raw command and validate byte 1
    ${status}=  Run External IPMI Raw Command  ${IPMI_RAW_CMD['Chassis_status']['get'][0]}
    ${status}=  Split String  ${status}
    ${state}=  Convert To Binary  ${status[0]}  base=16
    ${state}=  Zfill Data  ${state}  8

    # Last bit corresponds whether Power is on
    Should Be Equal As Strings  ${state[-1]}  1
    # bit 1-2 corresponds to power restore policy
    ${policy}=  Set Variable  ${state[1:3]}

    # condition to verify each power policy
    IF  '${power_policy}' == 'always-off'
        Should Be Equal As Strings  ${policy}  00
    ELSE IF  '${power_policy}' == 'always-on'
        Should Be Equal As Strings  ${policy}  10
    ELSE IF  '${power_policy}' == 'previous'
        Should Be Equal As Strings  ${policy}  01
    ELSE
        Log  Power Restore Policy is Unknown
        Should Be Equal As Strings  ${policy}  11
    END

    # Last Power Event - 4th bit should be 1b i.e, last ‘Power is on’ state was entered via IPMI command
    ${last_power_event}=  Convert To Binary  ${status[1]}  base=16
    ${last_power_event}=  Zfill Data  ${last_power_event}  8
    Should Be Equal As Strings  ${last_power_event[3]}  1


Test Setup Execution
    [Documentation]  Do test setup tasks.

    ${chassis_status}=  Get Chassis Status
    Set Test Variable  ${initial_power_policy}  ${chassis_status['power_restore_policy']}


Test Teardown Execution
    [Documentation]  Do Test Teardown tasks.

    ${resp}=  Run IPMI Standard Command  chassis status
    ${power_status}=  Get Lines Containing String  ${resp}  System Power
    @{powertolist}=  Split String  ${power_status}   :
    ${status}=  Get From List  ${powertolist}  1
    # Chassis Power ON if status is off
    Run Keyword If    '${status.strip()}' != 'on'
    ...  Redfish Power On
    FFDC On Test Case Fail
