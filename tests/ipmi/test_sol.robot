*** Settings ***
Documentation       This suite tests IPMI SOL in OpenBMC.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot

Test Teardown       Post Test Case Execution

*** Variables ***

*** Test Cases ***

Verify Setting SOL Retry Count
    [Documentation]  Verify setting retry count for SOL.
    [Tags]  Verify_Setting_SOL_Retry_Count

    ${retry_count}=  Evaluate  random.randint(0, 7)  modules=random
    Set SOL Parameter Value  retry-count  ${retry_count}

    ${resp}=  Get SOL Parameter Value  Retry Count
    Should Be Equal  '${resp}'  '${retry_count}'


*** Keywords ***

Get SOL Parameter Value
    [Documentation]  Return value for given SOL parameter.
    [Arguments]  ${parameter}
    # Description of argument(s):
    # parameter  SOL parameter which need to be read.

    ${resp}=  Run IPMI Standard Command  sol info

    ${parameter_line}=  Get Lines Containing String  ${resp}  ${parameter}
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


Restore Default SOL Configuration
    [Documentation]  Restore default SOL configuration.

    Open Connection And Log In
    Run IPMI Standard Command  sol set retry-count 7
    Close All Connections


Post Test Case Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Restore Default SOL Configuration
