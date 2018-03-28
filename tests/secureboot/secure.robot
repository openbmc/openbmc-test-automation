*** Settings ***
Documentation  Secure boot related test cases.

Resource          ../../lib/rest_client.robot
Resource          ../../lib/utils.robot
Resource          ../../lib/boot_utils.robot
Resource          ../../lib/secure_utils.robot

Test Setup        Test Setup Execution
Test Teardown     Test Teardown Execution

*** Variables ***

${Secure}=  Secure_SOL

*** Test Cases ***

Verify IPL With TPM Policy Enabled
    [Documentation]  Verify IPL with TPM Policy enabled.
    [Tags]  Verify_IPL_With_TPM_Policy_Enabled


    REST Power Off
    Wait Until Keyword Succeeds  6 min  10 sec  Is Host Off
    Delete Error Logs And Verify
    Clear BMC Gard record
    Enable And Verify TPM Policy  ${1}

    REST Power On
    Wait Until Keyword Succeeds  10 min  10 sec  Is Host Running

    # Verify the value of Security Access Bit
    ${cmd}=  Catenate  grep "Security Access Bit"  ${tmp_result_dir_path}
    ${rc}  ${output}=  Run and Return RC and Output  ${cmd}
    Should Be Equal  ${rc}  ${0}

    @{output}=  Split String  ${output}  ${SPACE}
    ${output}=  Set Variable  @{output}[-1]
    ${output}=  Convert To Binary  ${output}  base=16
    ${output}=  Get Substring  ${output}  0  2
    Should Be Equal  '${output}'  '${11}'

    Error Logs Should Not Exist
    No Gard Records Present


Verify IPL With TPM Policy Disabled
    [Documentation]  Verify IPL with TPM Policy disabled.
    [Tags]  Verify_IPL_With_TPM_Policy_Disabled

    REST Power Off
    Wait Until Keyword Succeeds  6 min  10 sec  Is Host Off
    Delete Error Logs And Verify
    Clear BMC Gard record
    Enable And Verify TPM Policy  ${0}

    REST Power On
    Wait Until Keyword Succeeds  10 min  10 sec  Is Host Running

    # Verify the value of Security Access Bit
    ${cmd}=  Catenate  grep "Security Access Bit"  ${tmp_result_dir_path}
    ${rc}  ${output}=  Run and Return RC and Output  ${cmd}
    Should Be Equal  ${rc}  ${0}

    @{output}=  Split String  ${output}  ${SPACE}
    ${output}=  Set Variable  @{output}[-1]
    ${output}=  Convert To Binary  ${output}  base=16
    ${output}=  Get Substring  ${output}  0  2
    Should Be Equal  '${output}'  '${11}'


    Error Logs Should Not Exist
    No Gard Records Present


*** Keywords ***

Test Setup Execution
    [Documentation]  Test setup execution.

    ${timestamp}=  Get Current Date  result_format=%Y%m%d%H%M%S
    ${tmp_result_dir_path}=  Catenate  ${Secure}${timestamp}
    Start SOL Console Logging  ${tmp_result_dir_path}
    Set Suite Variable  ${tmp_result_dir_path}


Test Teardown Execution
    [Documentation]  Test teardown execution.

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    Run Key  ${keyword_buf}
