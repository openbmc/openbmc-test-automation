*** Settings ***
Documentation       This suite tests IPMI SOL in OpenBMC.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/state_manager.robot
Resource            ../lib/boot_utils.robot
Resource            ../lib/bmc_redfish_resource.robot
Library             ../lib/ipmi_utils.py

Test Setup          Start SOL Console Logging
Test Teardown       Test Teardown Execution

Force Tags          SOL_Test


*** Variables ***

@{valid_bit_rates}    ${9.6}  ${19.2}  ${38.4}  ${57.6}  ${115.2}
@{setinprogress}      set-complete  set-in-progress  commit-write
${invalid_bit_rate}   7.5


*** Test Cases ***

Set SOL Enabled
    [Documentation]  Verify enabling SOL via IPMI.
    [Tags]  Set_SOL_Enabled

    ${msg}=  Run Keyword  Run IPMI Standard Command
    ...  sol set enabled true

    # Verify SOL status from ipmitool sol info command.
    ${sol_info_dict}=  Get SOL Info
    ${sol_enable_status}=  Get From Dictionary
    ...  ${sol_info_dict}  Enabled

    Should Be Equal  '${sol_enable_status}'  'true'


Set SOL Disabled
    [Documentation]  Verify disabling SOL via IPMI.
    [Tags]  Set_SOL_Disabled

    ${msg}=  Run Keyword  Run IPMI Standard Command
    ...  sol set enabled false

    # Verify SOL status from ipmitool sol info command.
    ${sol_info_dict}=  Get SOL Info
    ${sol_enable_status}=  Get From Dictionary
    ...  ${sol_info_dict}  Enabled
    Should Be Equal  '${sol_enable_status}'  'false'

    # Verify error while activating SOL with SOL disabled.
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  sol activate
    Should Contain  ${msg}  SOL payload disabled  ignore_case=True


Set Valid SOL Privilege Level
    [Documentation]  Verify valid SOL's privilege level via IPMI.
    [Tags]  Set_Valid_SOL_Privilege_Level

    ${privilege_level_list}=  Create List  user  operator  admin  oem

    FOR  ${item}  IN  @{privilege_level_list}
      Set SOL Setting  privilege-level  ${item}
      ${output}=  Get SOL Setting  Privilege Level
      Should Contain  ${output}  ${item}  ignore_case=True
    END


Set Invalid SOL Privilege Level
    [Documentation]  Verify invalid SOL's retry count via IPMI.
    [Tags]  Set_Invalid_SOL_Privilege_Level

    ${value}=  Generate Random String  ${8}
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  sol set privilege-level ${value}
    Should Contain  ${msg}  Invalid value  ignore_case=True


Set Invalid SOL Retry Count
    [Documentation]  Verify invalid SOL's retry count via IPMI.
    [Tags]  Set_Invalid_SOL_Retry_Count

    # Any integer above 7 is invalid for SOL retry count.
    ${value}=  Evaluate  random.randint(8, 10000)  modules=random

    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  sol set retry-count ${value}
    Should Contain  ${msg}  Invalid value  ignore_case=True


Set Invalid SOL Retry Interval
    [Documentation]  Verify invalid SOL's retry interval via IPMI.
    [Tags]  Set_Invalid_SOL_Retry_Interval

    # Any integer above 255 is invalid for SOL retry interval.
    ${value}=  Evaluate  random.randint(256, 10000)  modules=random

    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  sol set retry-interval ${value}
    Should Contain  ${msg}  Invalid value  ignore_case=True


Set Invalid SOL Character Accumulate Level
    [Documentation]  Verify invalid SOL's character accumulate level via IPMI.
    [Tags]  Set_Invalid_SOL_Character_Accumulate_Level

    # Any integer above 255 is invalid for SOL character accumulate level.
    ${value}=  Evaluate  random.randint(256, 10000)  modules=random

    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  sol set character-accumulate-level ${value}
    Should Contain  ${msg}  Invalid value  ignore_case=True


Set Invalid SOL Character Send Threshold
    [Documentation]  Verify invalid SOL's character send threshold via IPMI.
    [Tags]  Set_Invalid_SOL_Character_Send_Threshold

    # Any integer above 255 is invalid for SOL character send threshold.
    ${value}=  Evaluate  random.randint(256, 10000)  modules=random

    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  sol set character-send-threshold ${value}
    Should Contain  ${msg}  Invalid value  ignore_case=True


Verify SOL During Boot
    [Documentation]  Verify SOL during boot.
    [Tags]  Verify_SOL_During_Boot

    IPMI Power Off  stack_mode=skip
    Activate SOL Via IPMI
    Initiate Host Boot Via External IPMI  wait=${0}

    Wait Until Keyword Succeeds  3 mins  15 secs
    ...  Check IPMI SOL Output Content  Welcome to Hostboot

    Wait Until Keyword Succeeds  3 mins  15 secs
    ...  Check IPMI SOL Output Content  ISTEP

    IPMI Power Off


Verify Deactivate Non Existing SOL
    [Documentation]  Verify deactivate non existing SOL session.
    [Tags]  Verify_Deactivate_Non_Existing_SOL

    ${resp}=  Deactivate SOL Via IPMI
    Should Contain  ${resp}  SOL payload already de-activated
    ...  case_insensitive=True


Set Valid SOL Retry Count
    [Documentation]  Verify valid SOL's retry count via IPMI.
    [Tags]  Set_Valid_SOL_Retry_Count
    [Template]  Verify SOL Setting

    # Setting name    Min valid value    Max valid value
    retry-count       0                  7


Set Valid SOL Retry Interval
    [Documentation]  Verify valid SOL's retry interval via IPMI.
    [Tags]  Set_Valid_SOL_Retry_Interval
    [Template]  Verify SOL Setting

    # Setting name    Min valid value    Max valid value
    retry-interval    0                  255


Set Valid SOL Character Accumulate Level
    [Documentation]  Verify valid SOL's character accumulate level via IPMI.
    [Tags]  Set_Valid_SOL_Character_Accumulate_Level
    [Template]  Verify SOL Setting

    # Setting name              Min valid value    Max valid value
    character-accumulate-level  1                  255


Set Valid SOL Character Send Threshold
    [Documentation]  Verify valid SOL's character send threshold via IPMI.
    [Tags]  Set_Valid_SOL_Character_Send_Threshold
    [Template]  Verify SOL Setting

    # Setting name              Min valid value    Max valid value
    character-send-threshold    0                  255


Verify Continuous Activation And Deactivation Of SOL
    [Documentation]  Continuously on and off SOL.
    [Tags]  Verify_Continuous_Activation_And_Deactivation_Of_SOL

    ${iteration_count}=  Evaluate  random.randint(5,10)  modules=random
    FOR  ${iter}  IN RANGE  ${iteration_count}
        Activate SOL Via IPMI
        Deactivate SOL Via IPMI
    END


Verify SOL Payload Channel
    [Documentation]  Verify SOL Payload Channel from SOL info
    [Tags]  Verify_SOL_Payload_Channel

    # Get Channel number from SOL Info
    ${data}=  Run Keyword  Run IPMI Standard Command
    ...  sol info | grep "Payload Channel"
    ${payload_channel}=  Fetch Payload  ${data}
    Should Not Be Empty  ${payload_channel}


Verify SOL Payload Port
    [Documentation]  Verify SOL Payload Port from SOL info
    [Tags]  Verify_SOL_Payload_Port

    # Get Payload Port from SOL Info
    ${data}=  Run Keyword  Run IPMI Standard Command
    ...  sol info | grep "Payload Port"
    ${payload_port}=  Fetch Payload  ${data}
    Should Be Equal  ${IPMI_PORT}  ${payload_port}


Set Valid SOL Non Volatile Bit Rate
    [Documentation]  Verify Ability to set valid SOL non-volatile bit rate
    [Tags]  Set_Valid_SOL_Non_Volatile_Bit_Rate

    FOR  ${bit_rate}  IN  @{valid_bit_rates}

      # Set non-volatile-bit-rate from SOL Info
      ${resp} =  Run Keyword  Run IPMI Standard Command
      ...  sol set non-volatile-bit-rate ${bit_rate}

      ${non_volatile}=  Grep SOL Info Parameter Value  Non-Volatile Bit Rate
      Should Be Equal  ${bit_rate}  ${non_volatile}

      #Reboot BMC and verify value
      Initiate BMC Reboot
      ${non_volatile_bitrate_after_reboot}=  Grep SOL Info Parameter Value  Non-Volatile Bit Rate
      Should Be Equal  ${bit_rate}  ${non_volatile_bitrate_after_reboot}

    END


Set Invalid SOL Non Volatile Bit Rate
    [Documentation]  Verify Ability to set Invalid SOL non-volatile bit rate
    [Tags]  Set_Invalid_SOL_Non_Volatile_Bit_Rate

    # Set Invalid non-volatile-bit-rate from SOL Info
    ${resp} =  Run Keyword and Expect Error  *${IPMI_RAW_CMD['SOL']['Set_SOL'][0]}*
    ...  Run IPMI Standard Command  sol set non-volatile-bit-rate ${invalid_bit_rate}

    Should Contain  ${resp}  ${IPMI_RAW_CMD['SOL']['Set_SOL'][1]}


Set Valid SOL Volatile Bit Rate
    [Documentation]  Verify Ability to set valid SOL volatile bit rate
    [Tags]  Set_Valid_SOL_Volatile_Bit_Rate

    FOR  ${bit_rate}  IN  @{valid_bit_rates}

      # Set volatile-bit-rate from SOL Info
      ${resp} =  Run Keyword  Run IPMI Standard Command
      ...  sol set volatile-bit-rate ${bit_rate}

      ${volatile}=  Grep SOL Info Parameter Value  Volatile Bit Rate
      Should Be Equal  ${bit_rate}  ${volatile}

      #Reboot BMC and verify the sol info parameter value
      Initiate BMC Reboot
      ${volatile_bitrate_after_reboot}=  Grep SOL Info Parameter Value  Volatile Bit Rate
      Should Not Be Equal  ${bit_rate}  ${volatile_bitrate_after_reboot}

    END


Set Invalid SOL Volatile Bit Rate
    [Documentation]  Verify Ability to set Invalid SOL volatile bit rate
    [Tags]  Set_Invalid_SOL_Volatile_Bit_Rate

    # Set volatile-bit-rate from SOL Info
    ${resp} =  Run Keyword and Expect Error  *${IPMI_RAW_CMD['SOL']['Set_SOL'][0]}*
    ...  Run IPMI Standard Command  sol set volatile-bit-rate ${invalid_bit_rate}

    Should Contain  ${resp}  ${IPMI_RAW_CMD['SOL']['Set_SOL'][1]}


Verify SOL Set In Progress
    [Documentation]  Verify Ability to set the Set In Progress data for SOL
    [Tags]  Verify_SOL_Set_In_Progress
    [Teardown]  Run Keywords  Set SOL Setting  set-in-progress  set-complete
    ...         AND  Test Teardown Execution

    # Set the param 0 - set-in-progress from SOL Info
    FOR  ${prog}  IN  @{setinprogress}
       ${resp} =  Run Keyword  Run IPMI Standard Command  sol set set-in-progress ${prog}
       # Get the param 0 - set-in-progress from SOL Info and verify
       ${data}=  Run Keyword  Run IPMI Standard Command  sol info | grep "Set in progress"
       ${state}=  Fetch Payload  ${data}
       Should Be Equal  ${prog}  ${state}
    END


*** Keywords ***

Check IPMI SOL Output Content
    [Documentation]  Check if SOL has given content.
    [Arguments]  ${data}  ${file_path}=${IPMI_SOL_LOG_FILE}
    # Description of argument(s):
    # data       Content which need to be checked(e.g. Petitboot, ISTEP).
    # file_path  The file path on the local machine to check SOL content.
    #            By default it check SOL content from log/sol_<BMC_IP>.

    ${output}=  OperatingSystem.Get File  ${file_path}  encoding_errors=ignore
    Should Contain  ${output}  ${data}  case_insensitive=True


Verify SOL Setting
    [Documentation]  Verify SOL Setting via IPMI.
    [Arguments]  ${setting_name}  ${min_value}  ${max_value}
    # Description of Arguments:
    # setting_name    Setting to verify (e.g. "retry-count").
    # min_value       min valid value for given setting.
    # max_value       max valid value for given setting.

    ${value}=
    ...  Evaluate  random.randint(${min_value}, ${max_value})  modules=random

    # Character accumulate level setting is set in multiples of 5.
    # Retry interval setting is set in multiples of 10.
    # Reference IPMI specification v2.0

    ${expected_value}=  Run Keyword If
    ...  '${setting_name}' == 'character-accumulate-level'  Evaluate  ${value}*5
    ...  ELSE IF  '${setting_name}' == 'retry-interval'  Evaluate  ${value}*10
    ...  ELSE  Set Variable  ${value}

    Set SOL Setting  ${setting_name}  '${value}'

    # Replace "-" with space " " in setting name.
    # E.g. "retry-count" to "retry count"
    ${setting_name}=  Evaluate  $setting_name.replace('-',' ')

    ${sol_info_dict}=  Get SOL Info

    # Get exact SOL setting name from sol info output.
    ${list}=  Get Matches  ${sol_info_dict}  ${setting_name}*
    ...  case_insensitive=${True}
    ${setting_name_from_dict}=  Get From List  ${list}  0

    # Get SOL setting value from above setting name.
    ${setting_value}=  Get From Dictionary
    ...  ${sol_info_dict}  ${setting_name_from_dict}

    Should Be Equal  '${setting_value}'  '${expected_value}'

    IPMI Power Off  stack_mode=skip

    Initiate Host Boot Via External IPMI  wait=${0}

    Activate SOL Via IPMI
    Wait Until Keyword Succeeds  3 mins  15 secs
    ...  Check IPMI SOL Output Content  Welcome to Hostboot

    Wait Until Keyword Succeeds  3 mins  15 secs
    ...  Check IPMI SOL Output Content  ISTEP


Get SOL Setting
    [Documentation]  Returns status for given SOL setting.
    [Arguments]  ${setting}
    # Description of argument(s):
    # setting  SOL setting which needs to be read(e.g. "Retry Count").

    ${sol_info_dict}=  Get SOL Info
    ${setting_status}=  Get From Dictionary  ${sol_info_dict}  ${setting}

    [Return]  ${setting_status}


Restore Default SOL Configuration
    [Documentation]  Restore default SOL configuration.

    Set SOL Setting  enabled  true
    Set SOL Setting  retry-count  7
    Set SOL Setting  retry-interval  10
    Set SOL Setting  character-accumulate-level  20
    Set SOL Setting  character-send-threshold  1
    Set SOL Setting  privilege-level  user


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    Wait Until Keyword Succeeds  15 sec  5 sec  Restore Default SOL Configuration
    Deactivate SOL Via IPMI
    ${sol_log}=  Stop SOL Console Logging
    Log   ${sol_log}
    FFDC On Test Case Fail
