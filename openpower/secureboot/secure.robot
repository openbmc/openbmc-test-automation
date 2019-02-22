*** Settings ***
Documentation  Secure boot related test cases.

# Test Parameters:
# SEL to PEL conversion:
# https://github.com/openbmc/openbmc-test-automation/blob/master/docs/
# openbmc_test_tools.md#converting-sels-to-readable-format

Resource          ../../lib/utils.robot
Resource          ../../lib/state_manager.robot
Resource          ../../lib/boot_utils.robot
Resource          ../../lib/secure_utils.robot
Resource          ../../lib/open_power_utils.robot
Resource          ../../lib/logging_utils.robot
Resource          ../../lib/openbmc_ffdc_methods.robot

Library           ../../lib/gen_misc.py

Suite Setup       Suite Setup Execution
Test Setup        Test Setup Execution
Test Teardown     Test Teardown Execution

*** Variables ***

${security_access_bit_mask}  ${0xC000000000000000}
# TODO: will enable this in next commit
#${pnor_corruption_rc}        SECUREBOOT::RC_ROM_VERIFY
${pnor_corruption_rc}        0x1E07
${bmc_image_dir_path}        /usr/local/share/pnor
${bmc_guard_part_path}       /var/lib/phosphor-software-manager/pnor/prsv/GUARD

*** Test Cases ***

# All the test cases requires by default jumpers to be positioned
# between 1 & 2. If this is not met test cases would fail
# TODO:https://github.com/openbmc/openbmc-test-automation/issues/1644
Validate Secure Cold Boot With TPM Policy Disabled
    [Documentation]  Validate secure cold boot with TPM policy disabled.
    [Tags]  Validate_Secure_Cold_Boot_With_TPM_Policy_Disabled

    Validate Secure Boot With TPM Policy Enabled Or Disabled  ${0}


Validate Secure Cold Boot With TPM Policy Enabled
    [Documentation]  Validate secure cold boot with TPM policy enabled.
    [Tags]  Validate_Secure_Cold_Boot_With_TPM_Policy_Enabled

    Validate Secure Boot With TPM Policy Enabled Or Disabled  ${1}


Secure Boot Violation Using Corrupt SBE Image On Cold Boot
    [Documentation]  Secure boot violation using corrupt SBE image on cold boot.
    [Tags]  Secure_Boot_Violation_Using_Corrupt_SBE_Image_On_Cold_Boot

    Violate Secure Boot Using Corrupt Image
    ...  SBE  ${pnor_corruption_rc}  ${bmc_image_dir_path}


*** Keywords ***

Violate Secure Boot Using Corrupt Image
    [Documentation]  Cause secure boot violation during cold boot
    ...  with corrupted image.
    [Arguments]  ${partition}  ${error_rc}  ${bmc_image_dir_path}

    # Description of argument(s):
    # partition            The partition which is to be corrupted
    #                      (e.g. "SBE", "HBI", "HBB", "HBRT", "HBBL", "OCC").
    # error_rc             The RC that is expected as a
    #                      result of the secure boot violation
    #                      (e.g. "SECUREBOOT::RC_ROM_VERIFY").
    # bmc_image_dir_path   BMC image path.

    Set And Verify TPM Policy  ${1}

    # Descipiton:
    # Cause a secure boot violation by copying an BMC image file to the
    # target BMC and then starting a power on.
    # This action should result in:
    # 1) an error log entry
    # 2) the system going to "Quiesced" state.

    # Load corrupted image to /usr/local/share/pnor.
    Open Connection For SCP
    Log  ${bmc_image_dir_path}
    Log  ${error_rc}

    scp.Put File
    ...  ${EXEC_DIR}/data/pnor_test_data/${partition}  ${bmc_image_dir_path}

    ${error_log_path}=  Catenate  ${SB_LOG_DIR_PATH}/partition-corruption
    Create Directory  ${error_log_path}

    Set Global Variable  ${error_log_path}
    Log  ${error_log_path}

    # Starting a power on.
    # TODO: Need to move to REST Power On. Needs more testing.
    BMC Execute Command  /usr/sbin/obmcutil poweron
    Wait Until Keyword Succeeds  15 min  15 sec  Error Logs Should Exist

    #TODO: This will be enabled little later as more tesing required
    #Wait Until Keyword Succeeds  5 min  5 sec  Collect Error Logs and Verify SRC  ${error_rc}  ${error_log_path}

    # Verify the RC 0x1E07 in the SOL logs.
    Get And Verify Partition Corruption  ${sol_log_file_path}

    # Remove the file from /usr/local/share/pnor/.
    BMC Execute Command  rm -rf ${bmc_image_dir_path}*

    # Check if system reaches quiesce state.
    Run Keywords
    ...  Wait Until Keyword Succeeds  3 min  5 sec  Is Host Quiesced  AND
    ...  Recover Quiesced Host


Collect Error Logs and Verify SRC
    [Documentation]  Verify error log entry & signature description.
    [Arguments]  ${error_rc}  ${log_prefix}

    # Description of argument(s):
    # error_rc  Error log signature description.
    # log_prefix Log path prefix.

    Error Logs Should Not Exist

    Collect eSEL Log  ${log_prefix}
    ${error_log_file_path}=  Catenate  ${log_prefix}esel.txt
    ${rc}  ${output}=  Run and Return RC and Output
    ...  grep -i ${error_rc} ${error_log_file_path}
    Should Be Equal  ${rc}  ${0}
    Should Not Be Empty  ${output}

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
    # If fails, probable issue is Jumper position.

    ${security_access_bit}=  Convert to Integer  ${security_access_bit_str}
    ${result}=  Evaluate  ${security_access_bit_mask} & ${security_access_bit}
    Should Be Equal  ${result}  ${security_access_bit_mask}
    ...  msg=System is not booted in secure mode.  values=False

Get And Verify Partition Corruption
    [Documentation]  Get and verify partition corruption.
    [Arguments]  ${sol_log_file_path}

    # Description of argument(s):
    # sol_log_file_path  The path to the file containing SOL data
    #                    which was collected during a REST Power On.

    # Sample output:
    #  44.47498|secure|Secureboot Failure plid = 0x90000007, rc = 0x1E07

    ${cmd}=  Catenate
    ...  grep -i "Secureboot Failure"  ${sol_log_file_path} | awk '{ print $8 }'
    ${rc}  ${corruption_rc_str}=  Run and Return RC and Output  ${cmd}
    Should Be Equal  ${rc}  ${0}
    ...  msg=Return code from ${cmd} not zero.

    # Verify the RC 0x1E07 from sol output".
    Should Be Equal As Strings  ${corruption_rc_str}  ${pnor_corruption_rc}
    ...  msg=SB violation due to PNOR partition corruption not reported. values=False


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


Suite Setup Execution
    [Documentation]  Suite Setup Execution.

    ${bmc_image_dir_path}=  Add Trailing Slash  ${bmc_image_dir_path}

    ${SB_LOG_DIR_PATH}=  Catenate  ${EXECDIR}/SB_logs/
    Set Suite Variable  ${SB_LOG_DIR_PATH}

    Create Directory  ${SB_LOG_DIR_PATH}
    Empty Directory  ${SB_LOG_DIR_PATH}

    Set Global Variable  ${bmc_image_dir_path}
    Log  ${bmc_image_dir_path}
    BMC Execute Command  rm -rf ${bmc_image_dir_path}*

    Set Global Variable  ${bmc_guard_part_path}
    Log  ${bmc_guard_part_path}
    BMC Execute Command  rm -rf ${bmc_guard_part_path}


Test Setup Execution
    [Documentation]  Test setup execution.

    ${timestamp}=  Get Current Date  result_format=%Y%m%d%H%M%S
    ${sol_log_file_path}=  Catenate  ${EXECDIR}/Secure_SOL${timestamp}
    Start SOL Console Logging  ${sol_log_file_path}
    Set Suite Variable  ${sol_log_file_path}

    REST Power Off  stack_mode=skip  quiet=1
    Delete Error Logs And Verify


Test Teardown Execution
    [Documentation]  Test teardown execution.

    Stop SOL Console Logging
    Run  rm -rf ${sol_log_file_path}

    # Removing the corrupted file from BMC.
    BMC Execute Command  rm -rf ${bmc_image_dir_path}*
