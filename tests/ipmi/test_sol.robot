*** Settings ***
Documentation       This suite tests IPMI SOL in OpenBMC.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot

Test Teardown       Post Test Case Execution

*** Variables ***

*** Test Cases ***

Verify SOL Retry Count
    # Description of template fields:
    # Parameter       Min Value    Max Value
    retry-count       0            7
    [Documentation]  Verify SOL's retry count via IPMI.
    [Tags]  Verify_SOL_Retry_Count

    [Template]  Verify SOL Parameter


Verify SOL Character Send Threshold
    # Description of template fields:
    # Parameter                 Min Value    Max Value
    character-send-threshold    0            255
    [Documentation]  Verify SOL's character send threshold via IPMI.
    [Tags]  Verify_SOL_Character_Send_Threshold

    [Template]  Verify SOL Parameter


*** Keywords ***

Get SOL Parameter Value
    [Documentation]  Return value for given SOL parameter.
    [Arguments]  ${parameter}
    # Description of argument(s):
    # parameter  SOL parameter which need to be read.

    ${resp}=  Run IPMI Standard Command  sol info

    ${parameter_line}=
    ...  Get Lines Containing String  ${resp}  ${parameter}  case-insensitive
    ${parameter_value}=  Fetch From Right  ${parameter_line}  :
    ${parameter_value}=  Evaluate  '${parameter_value}'.replace(' ','')

    [Return]  ${parameter_value}


Set SOL Parameter Value
    [Documentation]  Set SOL parameter to given value.
    [Arguments]  ${parameter}  ${value}
    # Description of argument(s):
    # parameter  SOL parameter which need to be set.
    # value      Value which needs to be set.

    Run IPMI Standard Command  sol set ${parameter} ${value}


Verify SOL Parameter
    [Documentation]  Verify SOL Parameter via IPMI.
    [Arguments]  ${parameter}  ${min_value}  ${max_value}
    # Description of Arguments:
    # parameter  parameter to verify(e.g. "retry-count").
    # min_value  min_value for given parameter.
    # max_value  max value for given parameter.

    ${value}=  Evaluate  random.randint(${min_value}, ${max_value})  modules=random
    Set SOL Parameter Value  ${parameter}  ${value}

    ${parameter}=  Evaluate  '${parameter}'.replace('-',' ')
    ${output}=  Get SOL Parameter Value  ${parameter}
    Should Be Equal  '${output}'  '${value}'

Restore Default SOL Configuration
    [Documentation]  Restore default SOL configuration.

    Open Connection And Log In

    Set SOL Parameter Value  retry-count  7
    Set SOL Parameter Value  retry-interval  10
    Set SOL Parameter Value  character-accumulate-level  20
    Set SOL Parameter Value  character-send-threshold  1

    Close All Connections


Post Test Case Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Restore Default SOL Configuration
