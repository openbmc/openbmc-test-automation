*** Settings ***
Documentation       This suite tests IPMI SOL in OpenBMC.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/utils.robot

Test Teardown       Post Test Case Execution

*** Variables ***

*** Test Cases ***

Set Valid SOL Retry Count
    # Description of template fields:
    # Setting         Min Valid Value    Max Valid Value
    retry-count       0                  7
    [Documentation]  Verify valid SOL's retry count via IPMI.
    [Tags]  Set_Valid_SOL_Retry_Count

    [Template]  Verify SOL Setting


Set Valid SOL Retry Interval
    # Description of template fields:
    # Setting         Min Valid Value    Max Valid Value
    retry-interval    0                  255
    [Documentation]  Verify valid SOL's retry interval via IPMI.
    [Tags]  Set_Valid_SOL_Retry_Interval

    [Template]  Verify SOL Setting


Set Valid SOL Character Accumulate Level
    # Description of template fields:
    # Setting                   Min Valid Value    Max Valid Value
    character-accumulate-level  1                  255
    [Documentation]  Verify valid SOL's character accumulate level via IPMI.
    [Tags]  Set_Valid_SOL_Character_Accumulate_Level

    [Template]  Verify SOL Setting


Set Valid SOL Character Send Threshold
    # Description of template fields:
    # Setting                   Min Valid Value    Max Valid Value
    character-send-threshold    0                  255
    [Documentation]  Verify valid SOL's character send threshold via IPMI.
    [Tags]  Set_Valid_SOL_Character_Send_Threshold

    [Template]  Verify SOL Setting


*** Keywords ***

Verify SOL Setting
    [Documentation]  Verify SOL Setting via IPMI.
    [Arguments]  ${setting}  ${min_value}  ${max_value}
    # Description of Arguments:
    # setting    Setting to verify(e.g. "retry-count").
    # min_value  min valid value for given setting.
    # max_value  max valid value for given setting.

    ${value}=
    ...  Evaluate  random.randint(${min_value}, ${max_value})  modules=random

    # Character accumulate level setting is set in multiples of 5.
    # Retry interval setting is set in multiples of 10.
    # Reference IPMI specification v2.0

    ${expected_value}=  Run Keyword If
    ...  '${setting}' == 'character-accumulate-level'  Evaluate  ${value}*5
    ...  ELSE IF  '${setting}' == 'retry-interval'  Evaluate  ${value}*10
    ...  ELSE  Set Variable  ${value}

    Set SOL Setting Value  ${setting}  ${value}

    # Replace "-" with space " " in setting name.
    # E.g. "retry-count" to "retry count"
    ${setting}=  Evaluate  $setting.replace('-',' ')
    ${output}=  Get SOL Setting Value  ${setting}
    Should Be Equal  '${output}'  '${expected_value}'


Restore Default SOL Configuration
    [Documentation]  Restore default SOL configuration.

    Open Connection And Log In

    Set SOL Setting Value  retry-count  7
    Set SOL Setting Value  retry-interval  10
    Set SOL Setting Value  character-accumulate-level  20
    Set SOL Setting Value  character-send-threshold  1

    Close All Connections


Post Test Case Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Restore Default SOL Configuration
