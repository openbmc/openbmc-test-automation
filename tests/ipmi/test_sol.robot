*** Settings ***
Documentation       This suite tests IPMI SOL in OpenBMC.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Library             ../../lib/ipmi_utils.py

Test Setup          Start SOL Console Logging
Test Teardown       Test Teardown Execution

*** Variables ***

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
    : FOR  ${item}  IN  @{privilege_level_list}
    \  Set SOL Setting  privilege-level  ${item}
    \  ${output}=  Get SOL Setting  Privilege Level
    \  Should Contain  ${output}  ${item}  ignore_case=True


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

    ${current_state}=  Get Host State Via External IPMI
    Run Keyword If  '${current_state}' == 'on'
    ...  Initiate Host PowerOff Via External IPMI
    Initiate Host Boot Via External IPMI  wait=${0}

    Activate SOL Via IPMI
    Wait Until Keyword Succeeds  3 mins  30 secs
    ...  Check IPMI SOL Output Content  Welcome to Hostboot

    Wait Until Keyword Succeeds  3 mins  30 secs
    ...  Check IPMI SOL Output Content  ISTEP

    # Allow the host to boot.
    Wait Until Keyword Succeeds  5 min  20 sec  Is Host Running


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

*** Keywords ***

Check IPMI SOL Output Content
    [Documentation]  Check if SOL has given content.
    [Arguments]  ${data}  ${file_path}=/tmp/sol_${OPENBMC_HOST}
    # Description of argument(s):
    # data       Content which need to be checked(e.g. Petitboot, ISTEP).
    # file_path  The file path on the local machine to check SOL content.
    #            By default it check SOL content from /tmp/sol_<BMC_IP>.

    ${rc}  ${output}=  Run and Return RC and Output  cat ${file_path}
    Should Be Equal  ${rc}  ${0}  msg=${output}

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

    # Power on host to check if SOL is working fine with new setting.
    ${current_state}=  Get Host State Via External IPMI
    Run Keyword If  '${current_state}' == 'on'
    ...  Initiate Host PowerOff Via External IPMI
    Initiate Host Boot Via External IPMI  wait=${0}

    Activate SOL Via IPMI
    Wait Until Keyword Succeeds  10 mins  30 secs
    ...  Check IPMI SOL Output Content  Welcome to Hostboot

    Wait Until Keyword Succeeds  3 mins  30 secs
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

    Deactivate SOL Via IPMI
    ${sol_log}=  Stop SOL Console Logging
    Log   ${sol_log}
    FFDC On Test Case Fail
    Restore Default SOL Configuration
