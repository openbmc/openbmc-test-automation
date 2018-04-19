*** Settings ***
Documentation  Secure boot related test cases.

Resource          ../lib/utils.robot
Resource          ../lib/boot_utils.robot
Resource          ../lib/secure_utils.robot
Resource          ../lib/open_power_utils.robot
Resource          ../lib/logging_utils.robot

Test Setup        Test Setup Execution
Test Teardown     Test Teardown Execution

*** Variables ***

${security_access_bit_mask}  ${0xC000000000000000}

*** Test Cases ***

Validate Secure Boot With TPM Policy Disabled
    [Documentation]  Validate secure boot with TPM policy disabled.
    [Tags]  Validate_Secure_Boot_With_TPM_Policy_Disabled

    Validate Secure Boot With TPM Policy Enabled Or Disabled  ${0}


Validate Secure Boot With TPM Policy Enabled
    [Documentation]  Validate secure boot with TPM policy enabled.
    [Tags]  Validate_Secure_Boot_With_TPM_Policy_Enabled

    Validate Secure Boot With TPM Policy Enabled Or Disabled  ${1}


Verify Secure Boot Violation SRC After SBE Partition Corruption
    [Documentation]  Verify SRC after SBE partition corruption.
    [Tags]  Verify_Secure_Boot_Violation_SRC_After_SBE_Partition_Corruption

    Verify Secure Boot Violation SRC After Partition Corruption  SBE


*** Keywords ***

Verify Secure Boot Violation SRC After Partition Corruption
    [Documentation]  Verify secure boot violation SRC after partition corruption.
    [Arguments]  ${partition}

    # Decription of argument(s):
    # ${partition}  Corrupted partition.

    ${file_path1}=  Set Variable  /esw/san2/devindia/errorlog_decode/skiboot/
    ${file_path2}=  Set Variable  /external/pflash/corrupted_imprint_pnor/
    ${file_path}=  Catenate  ${file_path1}${filepath2}

    REST Power Off  stack_mode=skip
    Set And Verify TPM Policy  ${1}

    # Load corrupted image to /usr/local/share/pnor.
    Open Connection For SCP
    scp.Put File  ${file_path}/SBE  /usr/local/share/pnor/

    BMC Execute Command  /usr/sbin/obmcutil poweron
    Wait Until Keyword Succeeds  10 min  10 sec  Verify Test Error Log

    Decode Error Log And Verify  BC8A1E07

    # Remove the file from /usr/local/share/pnor/.
    BMC Execute Command  rm -rf /usr/local/share/pnor/${partition}

    Run Keywords
    ...  Wait Until Keyword Succeeds  3 min  5 sec  Is Host Quiesced  AND
    ...  Recover Quiesced Host


Verify Test Error Log
    [Documentation]  Verify test error log entries.

    ${elog_entry}=  Get URL List  ${BMC_LOGGING_ENTRY}
    Should Contain  ${elog_entry}[0]  OPENBMC_BASE/logging/entry/
    ...  msg=Error log not generated.


Decode Error Log And Verify
    [Documentation]  Decode error log and verify.
    [Arguments]  ${error_log_code}

    ${decode_path}=  Set Variable  /esw/san2/devindia/errorlog_decode/x86/bin/

    ${resp}=  OpenBMC Get Request  OPENBMC_BASE/logging/enumerate
    Create File  ${EXEC_DIR}/esel_error.out  ${resp.content}

    ${cmd}=  Catenate  ${decode_path}/eSEL.pl -p decode_obmc_data -l
    ...   ${EXEC_DIR}/esel_error.out

    ${rc}  ${output}=  Run And Return RC And Output  ${cmd}
    Should Be Equal  ${rc}  ${0}
    ...  msg=Unable to decode the error log.

    ${cmd}=  Catenate
    ...  cat ${EXEC_DIR}/esel_error.out.txt | grep -i ${error_log_code}
    ${rc}  ${output}=  Run and Return RC and Output  ${cmd}
    Should Be Equal  ${rc}  ${0}
    ...  msg=Code not found in the decoded error log.


Get And Verify Security Access Bit
    [Documentation]  Get and verify security access bit.
    [Arguments]  ${sol_log_file_path}

    # Description of argument(s):
    # sol_log_file_path  The path to the file containing SOL data
    #                    which was collected during a REST Power On.

    # Sample output:
    #  19.68481|SECURE|Security Access Bit> 0xC000000000000000

    ${cmd}=  Catenate
    ...  grep "Security Access Bit"  ${sol_log_file_path} | awk '{ print $4 }'
    ${rc}  ${security_access_bit_str}=  Run and Return RC and Output  ${cmd}
    Should Be Equal  ${rc}  ${0}
    ...  msg=Return code from ${cmd} not zero.

    # Verify the value of "Security Access Bit".

    ${security_access_bit}=  Convert to Integer  ${security_access_bit_str}
    ${result}=  Evaluate  ${security_access_bit_mask} & ${security_access_bit}
    Should Be Equal  ${result}  ${security_access_bit_mask}
    ...  msg=System is not booted in secure mode.  values=False


Validate Secure Boot With TPM Policy Enabled Or Disabled
    [Documentation]  Validate secure boot with TPM policy enabled or disabled.
    [Arguments]  ${tpm_policy}

    # Description of argument(s):
    # tpm_policy  Enable-0 or Disable-1.

    Set And Verify TPM Policy  ${tpm_policy}
    REST Power On  quiet=1
    Validate Secure Boot  ${sol_log_file_path}


Validate Secure Boot
    [Documentation]  Validate secure boot.
    [Arguments]  ${sol_log_file_path}

    # Description of argument(s):
    # sol_log_file_path  The path to the file containing SOL data
    #                    which was collected during a REST Power On.

    Get And Verify Security Access Bit  ${sol_log_file_path}
    Error Logs Should Not Exist
    REST Verify No Gard Records


Test Setup Execution
    [Documentation]  Test setup execution.

    ${timestamp}=  Get Current Date  result_format=%Y%m%d%H%M%S
    ${sol_log_file_path}=  Catenate  ${EXECDIR}/Secure_SOL${timestamp}
    Start SOL Console Logging  ${sol_log_file_path}
    Set Suite Variable  ${sol_log_file_path}

    REST Power Off  stack_mode=skip  quiet=1
    Delete Error Logs And Verify
    Clear BMC Gard record


Test Teardown Execution
    [Documentation]  Test teardown execution.

    Stop SOL Console Logging
    Run  rm -rf ${sol_log_file_path}
