*** Settings ***

Documentation    Module to test IPMI Get BIOS POST Code Command.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/boot_utils.robot
Library          ../lib/ipmi_utils.py
Variables        ../data/ipmi_raw_cmd_table.py

*** Variables ***
${power_state_change}  10
${host_reboot_time}  240

*** Test Cases ***

IPMI Chassis Status On
    [Documentation]  This test case verfies system power on status
    ...               using IPMI Get Chassis status command.
    [Tags]  IPMI_Chassis_Status_On

    # Check the chassis status.
    Verify Host PowerOn Via IPMI
    ${resp}=  Run IPMI Standard Command  chassis power status
    Should Be Equal As Strings  '${resp}'  'Chassis Power is on'

Test Get BIOS POST Code via IPMI Raw Command
    [Documentation]  Get BIOS POST Code via IPMI raw command.
    [Tags]  Test_Get_BIOS_POST_Code_via_IPMI_Raw_Command

    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['BIOS_POST_Code']['Get'][0]}
    Sleep  10

    Verify POST Code Response Length  ${resp}

Test Get BIOS POST Code via IPMI Raw Command After Power Cycle
    [Documentation]  Get BIOS POST Code via IPMI raw command after power cycle.
    [Tags]  Test_Get_BIOS_POST_Code_via_IPMI_Raw_Command_After_Power_Cycle

    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['BIOS_POST_Code']['Get'][0]}
    Sleep  ${host_reboot_time}

    Verify POST Code Response Length  ${resp}

Test Get BIOS POST Code via IPMI Raw Command With Host Powered Off
    [Documentation]  Get BIOS POST Code via IPMI raw command after power off.
    [Tags]  Test_Get_BIOS_POST_Code_via_IPMI_Raw_Command_With_Host_Powered_Off

    ${resp}=  Run IPMI Standard Command  chassis power off
    Sleep  ${power_state_change}
    Should Contain  ${resp}  Chassis Power Control: Down/Off

    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['BIOS_POST_Code']['Get'][0]}
    Should Contain  ${resp}  ${IPMI_RAW_CMD['BIOS_POST_Code']['Get'][3]}

*** Keywords ***

Verify Host PowerOn Via IPMI
    [Documentation]   Verify host power on operation using external IPMI command.
    [Tags]  Verify_Host_PowerOn_Via_IPMI

    IPMI Power On  stack_mode=skip  quiet=1
    ${ipmi_state}=  Get Host State Via External IPMI
    Valid Value  ipmi_state  ['on']


Verify POST Code Response Length
    [Documentation]  Verify the BIOS POST Code response byte length.
    [Tags]  Verify_POST_Code_Response_Length
    [Arguments]  ${resp}

    # Description of argument(s):
    # resp                          The complete response bytes from
    #                               Get BIOS POST Code command returned
    #                               in one string.

    @{resp_bytes}=  Split String  ${resp}
    ${string_length}=  Get Length  ${resp_bytes}

    # Convert response byte length to integer.
    ${value}=  Get Slice From List  ${resp_bytes}   2   4
    Reverse List   ${value}
    ${byte_length_string}=  Evaluate   "".join(${value})
    ${byte_length_integer}=  Convert To Integer  ${byte_length_string}  16
    ${true_length}=  Evaluate  (${string_length} - 4)

    Should Be Equal  ${true_length}  ${byte_length_integer}

