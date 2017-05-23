*** Settings ***
Documentation       This suite tests IPMI SOL in OpenBMC.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/utils.robot

Test Teardown       Post Test Case Execution

*** Variables ***

*** Test Cases ***

Verify SOL Retry Count
    # Description of template fields:
    # Setting         Min Value    Max Value
    retry-count       0            7
    [Documentation]  Verify SOL's retry count via IPMI.
    [Tags]  Verify_SOL_Retry_Count

    [Template]  Verify SOL Setting


Verify SOL Retry Interval
    # Description of template fields:
    # Setting         Min Value    Max Value
    retry-interval    0            255
    [Documentation]  Verify SOL's retry interval via IPMI.
    [Tags]  Verify_SOL_Retry_Interval

    [Template]  Verify SOL Setting


Verify SOL Character Accumulate Level
    # Description of template fields:
    # Setting                   Min Value    Max Value
    character-accumulate-level  1            255
    [Documentation]  Verify SOL's character accumulate level via IPMI.
    [Tags]  Verify_SOL_Character_Accumulate_Level

    [Template]  Verify SOL Setting


Verify SOL Character Send Threshold
    # Description of template fields:
    # Setting                   Min Value    Max Value
    character-send-threshold    0            255
    [Documentation]  Verify SOL's character send threshold via IPMI.
    [Tags]  Verify_SOL_Character_Send_Threshold

    [Template]  Verify SOL Setting


*** Keywords ***

Verify SOL Setting
    [Documentation]  Verify SOL Setting via IPMI.
    [Arguments]  ${setting}  ${min_value}  ${max_value}
    # Description of Arguments:
    # setting    setting to verify(e.g. "retry-count").
    # min_value  min_value for given setting.
    # max_value  max value for given setting.

    ${value}=
    ...  Evaluate  random.randint(${min_value}, ${max_value})  modules=random

    ${expected_value}=  Run Keyword If
    ...  $setting == 'character-accumulate-level'  Evaluate  $value*5
    ...  ELSE IF  $setting == 'retry-interval'  Evaluate  $value*10
    ...  ELSE  Set Variable  ${value}

    Set SOL Setting Value  ${setting}  ${value}

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
