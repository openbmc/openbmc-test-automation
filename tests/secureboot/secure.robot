*** Settings ***
Documentation  Secure boot related test cases.

Resource          ../../lib/rest_client.robot
Resource          ../../lib/utils.robot
Resource          ../../lib/boot_utils.robot
Resource          ../../lib/secure_utils.robot

Test Setup        Test Setup Execution
Test Teardown     Test Teardown Execution

*** Variables ***

${Secure}         Secure_SOL

*** Test Cases ***

Verify Power On With TPM Policy Enabled
    [Documentation]  Verify Power On with TPM Policy enabled.
    [Tags]  Verify_Power_On_With_TPM_Policy_Enabled

    Verify TPM Policy With Power On Or Off  ${1}


Verify Power Off With TPM Policy Disabled
    [Documentation]  Verify Power Off with TPM Policy disabled.
    [Tags]  Verify_Power_Off_With_TPM_Policy_Disabled

    Verify TPM Policy With Power On Or Off  ${0}


*** Keywords ***

Get And Verify Security Access Bit
    [Documentation]  Get security access bit.
    [Arguments]  ${sol_log_file_path}

    # Description of argument(s):
    # sol_log_file_path  Store SOL file.

    # Example:
    #  19.68481|SECURE|Security Access Bit> 0xC000000000000000

    ${cmd}=  Catenate  grep "Security Access Bit"  ${sol_log_file_path}
    ${rc}  ${security_access_bit}=  Run and Return RC and Output  ${cmd}
    Should Be Equal  ${rc}  ${0}

    # Verify the value of "Security Access Bit".
    @{security_access_bit}=  Split String  ${security_access_bit}  ${SPACE}
    ${security_access_bit}=  Set Variable  @{security_access_bit}[-1]
    ${security_access_bit}=  Convert To Binary  ${security_access_bit}  base=16
    ${security_access_bit}=  Get Substring  ${security_access_bit}  0  2
    Should Be Equal  '${security_access_bit}'  '${11}'
    ...  msg=System is not booted in secure mode.


Verify TPM Policy With Power On Or Off
    [Documentation]  Verify TPM policy with power on or off.
    [Arguments]  ${tpm_policy}

    # Description of argument(s):
    # tpm_policy  Enable-0 or Disable-1.
 
    REST Power Off  stack_mode=skip
    Set And Verify TPM Policy  ${tpm_policy}

    REST Power On

    Get And Verify Security Access Bit  ${sol_log_file_path}

    Error Logs Should Not Exist
    REST Verify No Gard Records


Test Setup Execution
    [Documentation]  Test setup execution.

    ${timestamp}=  Get Current Date  result_format=%Y%m%d%H%M%S
    ${sol_log_file_path}=  Catenate  ${Secure}${timestamp}
    Start SOL Console Logging  ${sol_log_file_path}
    Set Suite Variable  ${sol_log_file_path}
    Delete Error Logs And Verify
    Clear BMC Gard record


Test Teardown Execution
    [Documentation]  Test teardown execution.

    ${sol_log}=  Stop SOL Console Logging
    Run  rm -rf ${EXECDIR}${/}${sol_log_file_path}
