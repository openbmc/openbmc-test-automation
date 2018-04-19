*** Settings ***
Documentation  Secure boot related test cases.

# Test Parameters:
# HB              Host boot.
# BC8A1E07        A problem occurred during the power on of the system.


Resource          ../lib/utils.robot
Resource          ../lib/boot_utils.robot
Resource          ../lib/secure_utils.robot
Resource          ../lib/open_power_utils.robot
Resource          ../lib/logging_utils.robot

Test Setup        Test Setup Execution
Test Teardown     Test Teardown Execution

*** Variables ***

${security_access_bit_mask}  ${0xC000000000000000}
${pnor_corruption}           BC8A1E07
${bmc_path_image}            /usr/local/share/pnor
${decode_path}               ${EMPTY}

*** Test Cases ***

Validate Secure Boot With TPM Policy Disabled
    [Documentation]  Validate secure boot with TPM policy disabled.
    [Tags]  Validate_Secure_Boot_With_TPM_Policy_Disabled

    Validate Secure Boot With TPM Policy Enabled Or Disabled  ${0}


Validate Secure Boot With TPM Policy Enabled
    [Documentation]  Validate secure boot with TPM policy enabled.
    [Tags]  Validate_Secure_Boot_With_TPM_Policy_Enabled

    Validate Secure Boot With TPM Policy Enabled Or Disabled  ${1}


Verify Secure Boot Violation During HB With Corrupted Key In SBE
    [Documentation]  Verify Secure Boot Violation Corrupted Key SBE Partition.
    [Tags]  Verify_Secure_Boot_Violation_During_HB_With_Corrupted_Key_In_SBE

    Verify Secure Boot Violation With Corrupted Key  SBE  ${pnor_corruption}


*** Keywords ***

Verify Secure Boot Violation With Corrupted Key
    [Documentation]  Verify secure boot violation during host boot
    ...  with corrupted key.
    [Arguments]  ${partition}  ${error_src}

    # Decription of argument(s):
    # ${partition}   Corrupted partition
    #                (e.g. "SBE", "HBI", "HBB", "HBRT", "HBBL", "OCC").
    # ${error_src}   System Resource Controller.

    Set And Verify TPM Policy  ${1}

    # Load corrupted image to /usr/local/share/pnor.
    Open Connection For SCP
    scp.Put File  ${EXEC_DIR}/data/pnor_test_data/SBE  ${bmc_path_image}

    BMC Execute Command  /usr/sbin/obmcutil poweron
    Wait Until Keyword Succeeds  10 min  10 sec  Error Logs Should Exist

    Generate Error Log And Verify SRC  ${error_src}

    # Remove the file from /usr/local/share/pnor/.
    BMC Execute Command  rm -rf ${bmc_path_image}/${partition}

    Run Keywords
    ...  Wait Until Keyword Succeeds  3 min  5 sec  Is Host Quiesced  AND
    ...  Recover Quiesced Host


Generate Error Log And Verify SRC
    [Documentation]  Decode error log and verify.
    [Arguments]  ${error_log_code}

    # Description of argument(s):
    # error_log_code  Src code.

    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_URI}/enumerate
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
