*** Settings ***
Documentation    Module to test IPMI chassis functionality.

Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/boot_utils.robot
Resource         ../lib/bmc_dbus.robot
Library          ../lib/ipmi_utils.py
Library          Collections
Variables        ../data/ipmi_raw_cmd_table.py

Suite Setup      Redfish.Login
Suite Teardown   Redfish.Logout
Test Teardown    Test Teardown Execution

Test Tags        IPMI_Chassis

*** Variables ***

# Timeout value in minutes. Default 3 minutes.
${IPMI_POWEROFF_WAIT_TIMEOUT}      3
${busctl_settings}                 xyz.openbmc_project.Settings
${chassis_capabilities_dbus_URL}   /xyz/openbmc_project/Control/ChassisCapabilities
&{BYTE_DESCRIPTION}                set_complete=0    set_in_progress=1
${DEFAULT_Chassis_Boot_Flag}       ${EMPTY}

# valid selector values (0 - None, 4- pxe, 8- harddisk,
# 20- CD/DVD, 60 - removable media (usb)).
@{Valid_Selector_Values}           0  4  8  20  24  60

# Boot flags data for single time boot and persistent boot.
@{System_Boot_Flags_Data}         160  224

*** Test Cases ***

IPMI Chassis Status On
    [Documentation]  This test case verifies system power on status
    ...              using IPMI Get Chassis status command.
    [Tags]  IPMI_Chassis_Status_On

    Redfish Power On  stack_mode=skip  quiet=1
    ${resp}=  Run External IPMI Standard Command  chassis status
    ${power_status}=  Get Lines Containing String  ${resp}  System Power
    Should Contain  ${power_status}  on

IPMI Chassis Status Off
    [Documentation]  This test case verifies system power off status
    ...              using IPMI Get Chassis status command.
    [Tags]  IPMI_Chassis_Status_Off

    Redfish Power Off  stack_mode=skip  quiet=1
    ${resp}=  Run External IPMI Standard Command  chassis status
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
    Run External IPMI Standard Command  chassis power soft
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
    ...  Run External IPMI Standard Command  chassis policy ${initial_power_policy}
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
    ...  Run External IPMI Standard Command  chassis policy ${initial_power_policy}
    [Template]  Check Chassis Status Via IPMI

    # power_policy
    always-off
    always-on
    previous


Verify Get Chassis Capabilities
    [Documentation]  Verify get chassis capabilities IPMI cmd with valid data length and verify
    ...  its response comparing with busctl command.
    [Tags]  Verify_Get_Chassis_Capabilities
    [Teardown]  FFDC On Test Case Fail

    ${ipmi_resp}=  Run External IPMI Raw Command
    ...  ${IPMI_RAW_CMD['Chassis Capabilities']['Get'][0]}

    ${ipmi_resp}=  Split String  ${ipmi_resp}
    ${busctl_cmd}=  Catenate  ${BUSCTL_INTROSPECT_COMMAND} ${busctl_settings}
    ...  ${chassis_capabilities_dbus_URL}

    ${busctl_resp}=  BMC Execute Command  sh --login -c "${busctl_cmd}"

    Verify Chassis Capabilities Response  ${ipmi_resp[0]}  ${busctl_resp[0]}  CapabilitiesFlags
    Verify Chassis Capabilities Response  ${ipmi_resp[1]}  ${busctl_resp[0]}  FRUDeviceAddress
    Verify Chassis Capabilities Response  ${ipmi_resp[2]}  ${busctl_resp[0]}  SDRDeviceAddress
    Verify Chassis Capabilities Response  ${ipmi_resp[3]}  ${busctl_resp[0]}  SELDeviceAddress
    Verify Chassis Capabilities Response  ${ipmi_resp[4]}  ${busctl_resp[0]}  SMDeviceAddress
    Verify Chassis Capabilities Response  ${ipmi_resp[5]}  ${busctl_resp[0]}  BridgeDeviceAddress


Verify Get Chassis Capabilities With Invalid Data Length
    [Documentation]  Verify get chassis capabilities IPMI command with invalid data length
    [Tags]  Verify_Get_Chassis_Capabilities_With_Invalid_Data_Length
    [Teardown]  FFDC On Test Case Fail

    Verify Invalid IPMI Command  ${IPMI_RAW_CMD['Chassis Capabilities']['Get'][1]}  0xc7

Verify Chassis Capabilities With Invalid Data Length
    [Documentation]  Verify Set Chassis Capabilities With Invalid Data Length
    [Tags]  Verify_Chassis_Capabilities_With_Invalid_Data_Length
    [Template]  Verify Invalid IPMI Command

    # Invalid data length                              Expected error code
    ${IPMI_RAW_CMD['Chassis Capabilities']['Set'][0]}  0xc7
    ${IPMI_RAW_CMD['Chassis Capabilities']['Set'][1]}  0xc7

Verify Get Chassis Status With Invalid Data Length
    [Documentation]  Verify Get Chassis Status With Invalid Data Length
    [Tags]  Verify_Get_Chassis_Status_With_Invalid_Data_Length
    [Teardown]  FFDC On Test Case Fail

    Verify Invalid IPMI Command  ${IPMI_RAW_CMD['Chassis_status']['get_invalid_length'][0]}  0xc7

Verify Chassis Control With Invalid Data Length
    [Documentation]  Verify Chassis Control With Invalid Data Length
    [Tags]  Verify_Chassis_Control_With_Invalid_Data_Length
    [Teardown]  FFDC On Test Case Fail
    [Template]  Verify Invalid IPMI Command

    # Invalid data length                                                Expected error code
    ${IPMI_RAW_CMD['Chassis Control']['power_down'][1]}                  0xc7
    ${IPMI_RAW_CMD['Chassis Control']['power_down'][2]}                  0xc7
    ${IPMI_RAW_CMD['Chassis Control']['power_up'][1]}                    0xc7
    ${IPMI_RAW_CMD['Chassis Control']['power_up'][2]}                    0xc7
    ${IPMI_RAW_CMD['Chassis Control']['power_cycle'][1]}                 0xc7
    ${IPMI_RAW_CMD['Chassis Control']['power_cycle'][2]}                 0xc7
    ${IPMI_RAW_CMD['Chassis Control']['hard_reset'][1]}                  0xc7
    ${IPMI_RAW_CMD['Chassis Control']['hard_reset'][2]}                  0xc7
    ${IPMI_RAW_CMD['Chassis Control']['pulse_diagnostic_interrupt'][1]}  0xc7
    ${IPMI_RAW_CMD['Chassis Control']['pulse_diagnostic_interrupt'][2]}  0xc7
    ${IPMI_RAW_CMD['Chassis Control']['initiate_soft_shutdown'][1]}      0xc7
    ${IPMI_RAW_CMD['Chassis Control']['initiate_soft_shutdown'][2]}      0xc7

Verify Chassis System Boot Option To Set In Progress Status
    [Documentation]    Verify Chassis System Boot Option To Set In Progress Status.
    [Tags]    Verify_Chassis_System_Boot_Option_To_Set_In_Progress_Status
    [Setup]    Get Default Chassis System Boot Options
    [Teardown]    Set Chassis System Boot Options

    FOR  ${status}  ${progress}  IN  &{BYTE_DESCRIPTION}
        ${data_hex}=  Convert To Hex  ${progress}  length=2

        # Set Chassis System Boot Options for set_complete and set_in_progress
        Set Chassis System Boot Options  set_argument= 0x${data_hex}

        # Check Chassis System Boot Option
        Check Chassis System Boot Option  expect= 01 00 ${data_hex}
    END

Verify Set Power Policy With Invalid Data Length
    [Documentation]  Verify Set Chassis Power Policy With Invalid Data Length.
    [Tags]  Verify_Set_Power_Policy_With_Invalid_Data_Length
    [Template]  Verify Invalid IPMI Command

    # Invalid data length                             Expected error code
    ${IPMI_RAW_CMD['chssis_power_policy']['Set'][0]}  0xc7
    ${IPMI_RAW_CMD['chssis_power_policy']['Set'][1]}  0xc7

Verify BMC Boot Flag Valid Bit Clearing Via IPMI
    [Documentation]    Verify BMC Boot Flag Valid Bit Clearing Via IPMI.
    [Tags]    Verify_BMC_Boot_Flag_Valid_Bit_Clearing_Via_IPMI
    [Setup]    Get Default BMC Boot Flag Valid Bit Clearing Via IPMI
    [Teardown]    Set BMC Boot Flag Valid Bit Clearing Via IPMI

    FOR    ${status}    IN RANGE    1    32    1
        ${data_hex}=    Convert To Hex    ${status}    length=2
        ${data_hex}=    Convert To Lower Case    ${data_hex}

        # Set Chassis System Boot Options BMC Boot Flag Valid Bit Clearing To Selector
        Set BMC Boot Flag Valid Bit Clearing Via IPMI   flag_valid_bit= 0x${data_hex}

        # Check Chassis System Boot Options BMC Boot Flag Valid Bit Clearing
        ${resp}=  Run IPMI Command
        ...  ${IPMI_RAW_CMD['system_boot_options']['Get_Boot_Flag_Valid_Bit_Clearing'][0]}

        ${resp}=  Strip String  ${resp}
        ${expected_output}=  Catenate  01 03  ${data_hex}
        Should Be Equal As Strings    ${resp}    ${expected_output}
    END

Verify BMC Boot Flag With Invalid Data Length
    [Documentation]  Verify BMC Boot Flag With Invalid Data Length.
    [Tags]  Verify_BMC_Boot_Flag_With_Invalid_Data_Length
    [Template]  Verify Invalid IPMI Command

    # Invalid data                                                 Expected error code
    ${IPMI_RAW_CMD['system_boot_options']['Get_Boot_Flag'][1]}     0xc7
    ${IPMI_RAW_CMD['system_boot_options']['Set_Boot_Flag'][1]}     0xc7

Verify Chassis System Boot Option With Invalid Data Length
    [Documentation]    Verify Chassis System Boot Option With Invalid Data Length.
    [Tags]  Verify_Chassis_System_Boot_Option_With_Invalid_Data_Length
    [Template]  Verify Invalid IPMI Command

    # Invalid data                                                    Expected error code
    ${IPMI_RAW_CMD['system_boot_options']['Get_Boot_Options'][1]}     0xc7
    ${IPMI_RAW_CMD['system_boot_options']['Set_Boot_Options'][1]}     0xc7

Verify Chassis System Boot Options Boot Flags Via IPMI
    [Documentation]    Verify Chassis System Boot Options Boot Flags Via IPMI.
    [Tags]    Verify_Chassis_System_Boot_Options_Boot_Flags_Via_IPMI
    [Setup]    Get Default Chassis System Boot Options Boot Flags Via IPMI
    [Teardown]    Set Default Chassis System Boot Options Boot Flags Via IPMI

    FOR  ${value}  IN  @{System_Boot_Flags_Data}

        # Set system boot flags data for system boot flags values.
        ${data_hex}=    Convert To Hex    ${value}    length=2    lowercase=${True}
        Set Chassis System Boot Flags Data Via Ipmi    data=0x${data_hex}

        # Check chassis system boot options bmc boot Flag Data.
        ${resp}=  Run IPMI Command
        ...  ${IPMI_RAW_CMD['system_boot_options']['Get_Chassis_Boot_Flag'][0]}

        ${resp}=  Strip String  ${resp}
        ${expected_output}=  Catenate  01 05 ${data_hex} 00 00 00 00
        Should Be Equal As Strings    ${resp}    ${expected_output}
    END

    FOR  ${value}  IN  @{Valid_Selector_Values}

        # Set system boot flags data for valid selector values.
        ${data_hex}=    Convert To Hex    ${value}    length=2    lowercase=${True}
        Set Chassis System Boot Flags Data For Valid Selector Via Ipmi    data=0x${data_hex}

        # Check chassis system boot options bmc boot flag data.
        ${resp}=  Run IPMI Command
        ...  ${IPMI_RAW_CMD['system_boot_options']['Get_Chassis_Boot_Flag'][0]}

        ${resp}=  Strip String  ${resp}
        ${expected_output}=  Catenate  01 05 60 ${data_hex} 00 00 00
        Should Be Equal As Strings    ${resp}    ${expected_output}

    END

*** Keywords ***

Get Default Chassis System Boot Options
    [Documentation]    Get Default Chassis System Boot Options Value.
    [Arguments]    ${default}=True

    # Description of argument(s):
    # default   To get the default chassis system boot option value(e.g. "True", "False").

    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['system_boot_options']['Get_Boot_Options'][0]}

    IF  ${default}
        Set Suite Variable  ${DEFAULT_SET_IN_PROGRESS}  ${resp}
    ELSE
        RETURN  ${resp}
    END

Set Chassis System Boot Options
    [Documentation]    Set Chassis System Boot Options.
    [Arguments]    ${set_argument}=${DEFAULT_SET_IN_PROGRESS}[1]

    # Description of argument(s):
    # set_argument    Default chassis system boot option value.

    ${ipmi_cmd}=  Catenate  ${IPMI_RAW_CMD['system_boot_options']['Set_Boot_Options'][0]}  ${set_argument}
    Run IPMI Command  ${ipmi_cmd}

Check Chassis System Boot Option
    [Documentation]    Check Chassis System Boot Option Values.
    [Arguments]    ${expect}

    # Description of argument(s):
    # expect    expected value.

    ${resp}=  Run IPMI Command
     ...  ${IPMI_RAW_CMD['system_boot_options']['Get_Boot_Options'][0]}
    Should Be Equal As Strings  ${resp}  ${expect}

Set Chassis Power Policy Via IPMI And Verify
    [Documentation]  Set chasiss power policy via IPMI and verify.
    [Arguments]  ${power_policy}

    # Description of argument(s):
    # power_policy    Chassis power policy to be set(e.g. "always-off", "always-on").

    Run External IPMI Standard Command  chassis policy ${power_policy}
    ${resp}=  Get Chassis Status
    Valid Value  resp['power_restore_policy']  ['${power_policy}']


Check Chassis Status Via IPMI
    [Documentation]  Set Chassis Status via IPMI and verify and verify chassis status.
    [Arguments]  ${power_policy}

    # Description of argument(s):
    # power_policy    Chassis power policy to be set(e.g. "always-off", "always-on").

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

    # Last Power Event - 4th bit should be 1b i.e, last ‘Power is on’ state
    # was entered via IPMI command
    ${last_power_event}=  Convert To Binary  ${status[1]}  base=16
    ${last_power_event}=  Zfill Data  ${last_power_event}  8
    Should Be Equal As Strings  ${last_power_event[3]}  1


Verify Chassis Capabilities Response
    [Documentation]  Compare the IPMI response with the busctl response for given property.
    [Arguments]  ${ipmi_response}  ${busctl_response}  ${property}

    # Description of argument(s):
    # ipmi_response    IPMI response.
    # busctl_response  busctl command response.
    # property         property type (e.g. CapabilitiesFlags).

    ${ipmi_response}=  Convert To Integer  ${ipmi_response}  16

    ${busctl_value}=  Get Regexp Matches  ${busctl_response}
    ...  \\.${property}\\s+property\\s+\\w\\s+(\\d+)\\s+  1

    Should Be Equal As Integers   ${ipmi_response}  ${busctl_value[0]}


Test Setup Execution
    [Documentation]  Do test setup tasks.

    ${chassis_status}=  Get Chassis Status
    Set Test Variable  ${initial_power_policy}  ${chassis_status['power_restore_policy']}


Test Teardown Execution
    [Documentation]  Do Test Teardown tasks.

    ${resp}=  Run External IPMI Standard Command  chassis status
    ${power_status}=  Get Lines Containing String  ${resp}  System Power
    @{powertolist}=  Split String  ${power_status}   :
    ${status}=  Get From List  ${powertolist}  1
    # Chassis Power ON if status is off
    IF  '${status.strip()}' != 'on'  Redfish Power On
    FFDC On Test Case Fail

Get Default BMC Boot Flag Valid Bit Clearing Via IPMI
    [Documentation]    Get Default BMC Boot Flag Valid Bit Clearing Via IPMI.
    [Arguments]    ${default}=True

    # Description of argument(s):
    # default   To get the default bmc boot flag valid bit clearing value(e.g. "True", "False").

    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['system_boot_options']['Get_Boot_Flag'][0]}

    IF  ${default}
        Set Suite Variable  ${DEFAULT_SET_IN_PROGRESS}  ${resp}
    ELSE
        RETURN  ${resp}
    END

Set BMC Boot Flag Valid Bit Clearing Via IPMI
    [Documentation]    Set BMC Boot Flag Valid Bit Clearing Via IPMI.
    [Arguments]    ${flag_valid_bit}=${DEFAULT_SET_IN_PROGRESS}[1]

    # Description of argument(s):
    # flag_valid_bit   To set the default bmc boot flag valid bit clearing value.

    ${ipmi_cmd}=  Catenate  ${IPMI_RAW_CMD['system_boot_options']['Set_Boot_Flag'][0]}  ${flag_valid_bit}
    Run IPMI Command  ${ipmi_cmd}

Get Default Chassis System Boot Options Boot Flags Via IPMI
    [Documentation]    Get Default Chassis System Boot Options Boot Flags Via IPMI.
    [Arguments]    ${default}=True

    # Description of argument(s):
    # default   To get the default chassis system boot options boot flags value(e.g. "True", "False").

    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['system_boot_options']['Get_Chassis_Boot_Flag'][0]}

    IF  ${default}
        @{boot_flag_parts}=  Split String  ${resp}
        ${boot_flag_parts}=  Get Slice From List  ${boot_flag_parts}  2
        ${boot_flag_count}=  Get Length  ${boot_flag_parts}
        FOR  ${index}  IN RANGE  ${boot_flag_count}
            ${prefixed}=  Catenate  SEPARATOR=  0x${boot_flag_parts[${index}]}
            Set List Value  ${boot_flag_parts}  ${index}  ${prefixed}
        END
        ${boot_flag_data}=  Catenate  @{boot_flag_parts}
        Set Suite Variable  ${DEFAULT_Chassis_Boot_Flag}  ${boot_flag_data}
    ELSE
        RETURN  ${resp}
    END

Set Default Chassis System Boot Options Boot Flags Via IPMI
    [Documentation]    Set Default Chassis System Boot Options Boot Flags Via IPMI.
    [Arguments]    ${flag_valid_bit}=${DEFAULT_Chassis_Boot_Flag}

    # Description of argument(s):
    # flag_valid_bit   To set the default chassis system boot options boot flags value.

    ${ipmi_cmd}=  Catenate  ${IPMI_RAW_CMD['system_boot_options']['Set_Chassis_Boot_Flag'][1]}
    ...      ${flag_valid_bit}
    Run IPMI Command  ${ipmi_cmd}

Set Chassis System Boot Flags Data Via IPMI
    [Documentation]    Set Chassis System Boot Flags Data 1 Via IPMI.
    [Arguments]    ${data}

    # Description of argument(s):
    # data    To set the chassis system boot options boot flags data value.

    ${ipmi_cmd}=  Catenate  ${IPMI_RAW_CMD['system_boot_options']['Set_Chassis_Boot_Flag'][1]}
    ...      ${data}  ${IPMI_RAW_CMD['system_boot_options']['Set_Chassis_Boot_Flag'][4]}

    Run IPMI Command  ${ipmi_cmd}

Set Chassis System Boot Flags Data For Valid Selector Via IPMI
    [Documentation]    Set Chassis System Boot Flags Data For Valid Selector Via IPMI.
    [Arguments]    ${data}

    # Description of argument(s):
    # data    To set the chassis system boot options boot flags data value for valid selector.

    ${ipmi_cmd}=  Catenate  ${IPMI_RAW_CMD['system_boot_options']['Set_Chassis_Boot_Flag'][2]}
    ...      ${data}  ${IPMI_RAW_CMD['system_boot_options']['Set_Chassis_Boot_Flag'][3]}

    Run IPMI Command  ${ipmi_cmd}
