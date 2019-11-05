*** Settings ***
Documentation  Secure boot related test cases.

# Test Parameters:
# SEL to PEL conversion:
# https://github.com/openbmc/openbmc-test-automation/blob/master/docs/
# openbmc_test_tools.md#converting-sels-to-readable-format
#
# Definition of each partition acronyms
# HBB:  Hostboot Base
# HBI:  Hostboot Extended Image
# HBRT: Hostboot Runtime
# HBD:  Hostboot Data
# HBBL: Bostboot Base loader
# SBE:  Self Boot Engine
# OCC:  On Chip Controller
# PAYLOAD : OPAL Partition
# HCODE : Hardware Code
# BOOTKERNEL : OPAL Boot Kernel
# WOFDATA : Workload Optimized Frequency Data
# MEMD  : Memory VPD

Resource          ../../lib/resource.robot
Resource          ../../lib/utils.robot
Resource          ../../lib/state_manager.robot
Resource          ../../lib/boot_utils.robot
Resource          ../../lib/secureboot/secureboot.robot
Resource          ../../lib/open_power_utils.robot
Resource          ../../lib/logging_utils.robot
Resource          ../../lib/openbmc_ffdc_methods.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/openbmc_ffdc_utils.robot

Library           ../../lib/gen_misc.py
Library           ../../lib/secureboot/secureboot.py

Suite Setup       Suite Setup Execution
Test Setup        Test Setup Execution
Test Teardown     Test Teardown Execution

*** Variables ***

${security_access_bit_mask}  ${0xC000000000000000}
# TODO: will enable this in next commit
#${pnor_corruption_rc}        SECUREBOOT::RC_ROM_VERIFY
${pnor_corruption_rc}        1E07
${bootkernel_corruption_rc}  log=0xffffffffffff8160
${bmc_image_dir_path}        /usr/local/share/pnor
${bmc_guard_part_path}       /var/lib/phosphor-software-manager/pnor/prsv/GUARD
${HB_PART_LIST}              [HBB, HBD, HBI, HBRT, HBBL]
${NON_HB_PART_LIST}          [SBE, OCC, HCODE, WOFDATA, MEMD, PAYLOAD]
${MIXED_PART_LIST}           [SBE, HBD, OCC, HBRT, HBBL, HCODE, WOFDATA, MEMD, PAYLOAD]

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


Secure Boot Violation Using Corrupt HBD Image On Cold Boot
    [Documentation]  Secure boot violation using corrupt HBD image on cold boot.
    [Tags]  Secure_Boot_Violation_Using_Corrupt_HBD_Image_On_Cold_Boot

    Violate Secure Boot Using Corrupt Image
    ...  HBD  ${pnor_corruption_rc}  ${bmc_image_dir_path}

Secure Boot Violation Using Corrupt HBB Image On Cold Boot
    [Documentation]  Secure boot violation using corrupt HBB image on cold boot.
    [Tags]  Secure_Boot_Violation_Using_Corrupt_HBB_Image_On_Cold_Boot

    Violate Secure Boot Using Corrupt Image
    ...  HBB  ${pnor_corruption_rc}  ${bmc_image_dir_path}


Secure Boot Violation Using Corrupt HBBL Image On Cold Boot
    [Documentation]  Secure boot violation using corrupt HBBL image on cold boot.
    [Tags]  Secure_Boot_Violation_Using_Corrupt_HBBL_Image_On_Cold_Boot

    Violate Secure Boot Using Corrupt Image
    ...  HBBL  ${pnor_corruption_rc}  ${bmc_image_dir_path}


Secure Boot Violation Using Corrupt HBI Image On Cold Boot
    [Documentation]  Secure boot violation using corrupt HBI image on cold boot.
    [Tags]  Secure_Boot_Violation_Using_Corrupt_HBI_Image_On_Cold_Boot

    Violate Secure Boot Using Corrupt Image
    ...  HBI  ${pnor_corruption_rc}  ${bmc_image_dir_path}


Secure Boot Violation Using Corrupt HBRT Image On Cold Boot
    [Documentation]  Secure boot violation using corrupt HBRT image on cold boot.
    [Tags]  Secure_Boot_Violation_Using_Corrupt_HBRT_Image_On_Cold_Boot

    Violate Secure Boot Using Corrupt Image
    ...  HBRT  ${pnor_corruption_rc}  ${bmc_image_dir_path}


Secure Boot Violation Using Corrupt OCC Image On Cold Boot
    [Documentation]  Secure boot violation using corrupt OCC image on cold boot.
    [Tags]  Secure_Boot_Violation_Using_Corrupt_OCC_Image_On_Cold_Boot

    Violate Secure Boot Using Corrupt Image
    ...  OCC  ${pnor_corruption_rc}  ${bmc_image_dir_path}


Secure Boot Violation Using Corrupt HCODE Image On Cold Boot
    [Documentation]  Secure boot violation using corrupt HCODE image on cold boot.
    [Tags]  Secure_Boot_Violation_Using_Corrupt_HCODE_Image_On_Cold_Boot

    Violate Secure Boot Using Corrupt Image
    ...  HCODE  ${pnor_corruption_rc}  ${bmc_image_dir_path}


Secure Boot Violation Using Corrupt WOFDATA Image On Cold Boot
    [Documentation]  Secure boot violation using corrupt HCODE image on cold boot.
    [Tags]  Secure_Boot_Violation_Using_Corrupt_WOFDATA_Image_On_Cold_Boot

    Violate Secure Boot Using Corrupt Image
    ...  WOFDATA  ${pnor_corruption_rc}  ${bmc_image_dir_path}


Secure Boot Violation Using Corrupt BOOTKERNEL Image On Cold Boot
    [Documentation]  Secure boot violation using corrupt BOOTKERNEL image on cold boot.
    [Tags]  Secure_Boot_Violation_Using_Corrupt_BOOTKERNEL_Image_On_Cold_Boot

    Violate Secure Boot Using Corrupt Image
    ...  BOOTKERNEL  ${bootkernel_corruption_rc}  ${bmc_image_dir_path}


Secure Boot Violation Using Corrupt MEMD Image On Cold Boot
    [Documentation]  Secure boot violation using corrupt MEMD image on cold boot.
    [Tags]  Secure_Boot_Violation_Using_Corrupt_MEMD_Image_On_Cold_Boot

    Violate Secure Boot Using Corrupt Image
    ...  MEMD  ${pnor_corruption_rc}  ${bmc_image_dir_path}


Secure Boot Violation Using Corrupt PAYLOAD Image On Cold Boot
    [Documentation]  Secure boot violation using corrupt PAYLOAD image on cold boot.
    [Tags]  Secure_Boot_Violation_Using_Corrupt_PAYLOAD_Image_On_Cold_Boot

    Violate Secure Boot Using Corrupt Image
    ...  PAYLOAD  ${pnor_corruption_rc}  ${bmc_image_dir_path}


*** Keywords ***

Validate Secure Boot Setup
    [Documentation]  Validates setup to make sure it's secureboot run capable.

    # Check the jumper position and Security settings before moving ahead.
    ${num_procs}  ${secureboot_state}  ${jumper_state}=  Get Secure Boot Info

    Rprint Vars  secureboot_state  jumper_state

    Should Be True  ${secureboot_state} == True and ${jumper_state} == False
    ...  msg=Jumper is on while secureboot is disabled. Put the jumpers between pins 2 and 3.

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

    # Some times it is observed that bigger size files doesn't get copied.
    # Our intention here is to test bad image. Even if it is truncated/partial,
    # that should be fine
    Run Keyword And Ignore Error  scp.Put File
    ...  ${ENV_SB_CORRUPTED_BIN_PATH}/${partition}  ${bmc_image_dir_path}

    ${error_log_path}=  Catenate  ${SB_LOG_DIR_PATH}
    Create Directory  ${error_log_path}

    Set Global Variable  ${error_log_path}
    Log  ${error_log_path}

    # Starting a power on.
    BMC Execute Command  /usr/bin/obmcutil poweron
    Wait Until Keyword Succeeds  15 min  15 sec  Error Logs Should Exist

    # Check for eSEL.
    # Expected behavior is that the error occurs early in the boot process,
    # therefore, no entry in the error log and nothing to decode.
    # The 1E07 error is written to PNOR & then goes into Quiesced state.
    # On the next valid boot, the error log will be sent to BMC &
    # seen on SOL console.
    # We won't see any ESEL's for HBB, HBD, HBI or BOOTKERNEL because
    # Hostboot has no mechanism to send an eSEL when it is dying.
    Run Keyword If  '${partition}' not in ['HBB', 'HBD', 'HBI', 'BOOTKERNEL']
    ...  Wait Until Keyword Succeeds  5 min  5 sec
    ...  Collect Error Logs and Verify SRC  ${error_rc}  ${error_log_path}

    # Remove the file from /usr/local/share/pnor/.
    BMC Execute Command  rm -rf ${bmc_image_dir_path}*

    # Check if system reaches quiesce state.
    # Default system state will be power off at the end of the verification.
    Run Keywords
    ...  Wait Until Keyword Succeeds  3 min  5 sec  Is Host Quiesced  AND
    ...  Recover Quiesced Host

    # We will retry boot with corrupted partition removed
    # SOL console should show previous boot fail message (1E07) on current boot
    # HBB, HBD or HBI corruption will never get far enough to log into PNOR.
    # so, it should be removed from consideration for this check
    Run Keyword If  '${partition}' in ['HBB', 'HBD', 'HBI']
    ...  Log To Console  No more action on ${partition} corruption required.
    ...  ELSE IF  '${partition}' in ['HBRT']
    ...  Run Keywords
    ...    REST Power On  stack_mode=skip  quiet=1  AND
    ...    Wait Until Keyword Succeeds  5 min  5 sec  Error Logs Should Exist  AND
    ...    Get And Verify Partition Corruption  ${partition}  ${sol_log_file_path}  AND
    ...    REST Power Off  stack_mode=skip  quiet=1

Collect Error Logs and Verify SRC
    [Documentation]  Verify error log entry & signature description.
    [Arguments]  ${error_rc}  ${log_prefix}

    # Description of argument(s):
    # error_rc  Error log signature description.
    # log_prefix Log path prefix.

    Error Logs Should Exist

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
    [Arguments]  ${partition}  ${sol_log_file_path}

    # Description of argument(s):
    # partition          The partition which is to be corrupted
    #                    (e.g. "SBE", "HBI", "HBB", "HBRT", "HBBL", "OCC").
    # sol_log_file_path  The path to the file containing SOL data
    #                    which was collected during a REST Power On.

    # Sample output:
    #  44.47498|secure|Secureboot Failure plid = 0x90000007, rc = 0x1E07
    #                               OR
    #  14.94315|Error reported by secure (0x1E00) PLID 0x90000002
    #  14.99659|  ROM_verify() Call Failed
    #  14.99659|  ModuleId   0x03 SECUREBOOT::MOD_SECURE_ROM_VERIFY
    #  14.99660|  ReasonCode 0x1e07 SECUREBOOT::RC_ROM_VERIFY
    #                               OR
    #  113.150162849,0] STB: BOOTKERNEL verification FAILED. log=0xffffffffffff8160
    #

    ${cmd}=   Run Keyword If  '${partition}' in '${MIXED_PART_LIST}'
    ...  Catenate
    ...  grep -i "Secureboot Failure"  ${sol_log_file_path} | awk '{ print $8 }'
    ...  ELSE IF  '${partition}' == 'HBI'
    ...  Catenate
    ...  grep -i "ReasonCode"  ${sol_log_file_path} | awk '{ print $3 }'
    ...  ELSE IF  '{$partition}' == 'BOOTKERNEL'
    ...  Catenate
    ...  grep -i "STB: BOOTKERNEL verification FAILED"  ${sol_log_file_path} | awk '{ print $7}'

    ${rc}  ${corruption_rc_str}=  Run and Return RC and Output  ${cmd}
    Should Be Equal  ${rc}  ${0}
    ...  msg=Return code from ${cmd} not zero.

    # Verify the RC 0x1E07 from sol output".
    Should Be Equal As Strings
    ...  ${corruption_rc_str}  0x${pnor_corruption_rc}  ignore_case=True
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

    # All the corrupted binaries will go in here
    # Run this as input param
    Valid Path  ENV_SB_CORRUPTED_BIN_PATH
    Valid Path  ESEL_BIN_PATH
    Set Environment Variable  PATH  %{PATH}:${ENV_SB_CORRUPTED_BIN_PATH}:${ESEL_BIN_PATH}


Test Setup Execution
    [Documentation]  Test setup execution.

    ${timestamp}=  Get Current Date  result_format=%Y%m%d%H%M%S
    ${sol_log_file_path}=  Catenate  ${EXECDIR}/Secure_SOL${timestamp}
    Start SOL Console Logging  ${sol_log_file_path}
    Set Suite Variable  ${sol_log_file_path}

    REST Power On  stack_mode=skip  quiet=1

    # Validate the secureboot setup. If not met with required state then, fail.
    Validate Secure Boot Setup

    REST Power Off  stack_mode=skip  quiet=1
    Delete Error Logs And Verify


Test Teardown Execution
    [Documentation]  Test teardown execution.

    Stop SOL Console Logging
    Run  rm -rf ${sol_log_file_path}

    # Collect FFDC on failure
    FFDC On Test Case Fail

    # Removing the corrupted file from BMC.
    BMC Execute Command  rm -rf ${bmc_image_dir_path}*
