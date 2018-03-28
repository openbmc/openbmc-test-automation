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
    ${rc}  ${security_access_bit}=  Run and Return RC and Output  ${cmd}
    Should Be Equal  ${rc}  ${0}

    Verify Security Access Bit  ${security_access_bit}

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
    ${rc}  ${security_access_bit}=  Run and Return RC and Output  ${cmd}
    Should Be Equal  ${rc}  ${0}

    Verify Security Access Bit  ${security_access_bit}

    Error Logs Should Not Exist
    No Gard Records Present


*** Keywords ***

Verify Security Access Bit
    [Documentation]  Verify security access bit.
    [Arguments]  ${security_access_bit}

    # Description of argument(s):
    # security_access_bit  Security Access Bit

    @{security_access_bit}=  Split String  ${security_access_bit}  ${SPACE}
    ${security_access_bit}=  Set Variable  @{security_access_bit}[-1]
    ${security_access_bit}=  Convert To Binary  ${security_access_bit}  base=16
    ${security_access_bit}=  Get Substring  ${security_access_bit}  0  2
    Should Be Equal  '${security_access_bit}'  '${11}'
    ...  msg= System is not booted in secure mode.

Test Setup Execution
    [Documentation]  Test setup execution.

    ${timestamp}=  Get Current Date  result_format=%Y%m%d%H%M%S
    ${tmp_result_dir_path}=  Catenate  ${Secure}${timestamp}
    Start SOL Console Logging  ${tmp_result_dir_path}
    Set Suite Variable  ${tmp_result_dir_path}


Test Teardown Execution
    [Documentation]  Test teardown execution.

    ${sol_log}=  Stop SOL Console Logging
    Log  ${sol_log}
