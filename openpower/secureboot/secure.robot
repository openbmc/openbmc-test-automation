*** Settings ***
Documentation  Secure boot related test cases.

# Test Parameters:
# FFDC_TOOL_DIR_PATH  The path to the directory containing FFDC translation
#                     tools such as eSEL.pl.

Resource          ../../lib/utils.robot
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
# Description of BC8A1E07
#
# devdesc                  : ROM_verify() Call Failed
# moduleid                 : SECUREBOOT::MOD_SECURE_ROM_VERIFY
# reasoncode               : SECUREBOOT::RC_ROM_VERIFY
# userdata1                : l_rc
${pnor_corruption_rc}        SECUREBOOT::RC_ROM_VERIFY
${bmc_image_dir_path}        /usr/local/share/pnor
${bmc_guard_dir_path}        /var/lib/phosphor-software-manager/pnor/prsv

*** Test Cases ***

# All the test cases requires by default jumpers to be positioned
# between 1 & 2. If this is not met test cases would fail
# TODO: To validate jumper position and giving warning messages
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
    scp.Put File
    ...  ${EXEC_DIR}/data/pnor_test_data/${partition}  ${bmc_image_dir_path}

    ${err_log_path}=  Catenate  ${SB_LOG_DIR_PATH}sbe-corruption

    # Starting a power on.
    BMC Execute Command  /usr/sbin/obmcutil poweron
    Wait Until Keyword Succeeds  10 min  10 sec  Error Logs Should Exist

    Wait Until Keyword Succeeds  10 min  10 sec  Collect Error Logs and Verify SRC  ${error_rc} ${err_log_path}

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
    # log_prefix      Log path prefix.

    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}list
    Should Not Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

    Collect eSEL Log  ${log_prefix}
    ${error_log_file_path}=  Catenate  ${log_prefix}esel.txt
    ${rc}  ${output}=  Run and Return RC and Output
    ...  grep -i ${error_msg} ${error_log_file_path}
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
    # If fails, probable issue is Jumper possition

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


Suite Setup Execution
    [Documentation]  Suite Setup Execution

    ${bmc_image_dir_path}=  Add Trailing Slash  ${bmc_image_dir_path}
    ${bmc_guard_dir_path}=  Add Trailing Slash  ${bmc_guard_dir_path}

    ${SB_LOG_DIR_PATH}=  Catenate  ${EXECDIR}/SB_logs/
    Set Suite Variable  ${SB_LOG_DIR_PATH}

    Create Directory  ${SB_LOG_DIR_PATH}
    OperatingSystem.Directory Should Exist  ${SB_LOG_DIR_PATH}
    Empty Directory  ${SB_LOG_DIR_PATH}

    Set Global Variable  ${bmc_image_dir_path}
    Log  ${bmc_image_dir_path}
    BMC Execute Command  rm -rf ${bmc_image_dir_path}*

    Set Global Variable  ${bmc_guard_dir_path}
    Log  ${bmc_guard_dir_path}
    BMC Execute Command  rm -rf ${bmc_guard_dir_path}*


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
