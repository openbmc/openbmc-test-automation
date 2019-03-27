*** Settings ***
Documentation       Utility for getting/reading Secure Boot related settings.
Resource            ../../lib/open_power_utils.robot
Resource            ../../lib/utils.robot
Resource            ../../lib/state_manager.robot
Resource            ../../lib/boot_utils.robot
Library             ../../lib/bmc_ssh_utils.py
Library             ../../lib/sb/sb_utils.py

*** Keywords ***

Set TPMEnable Policy
    [Documentation]  Enable or disable TPM Policy.
    [Arguments]  ${tpm_policy}

    # Description of argument(s):
    # tpm_policy  Enable-1 or Disable-0.

    ${value_dict}=  Create Dictionary  data=${tpm_policy}
    Write Attribute  ${CONTROL_HOST_URI}/TPMEnable  TPMEnable
    ...  data=${value_dict}


Set And Verify TPM Policy
    [Documentation]  Enable or disable and verify TPM Policy.
    [Arguments]  ${tpm_policy}

    # Description of argument(s):
    # tpm_policy  Enable-1 or Disable-0.

    Set TPMEnable Policy  ${tpm_policy}
    ${resp}=  Verify The Attribute
    ...  ${CONTROL_URI}/host0/TPMEnable  TPMEnable  ${tpm_policy}


Get SB Cfam
    [Documentation]  Get SB cfam value on a given Proc.
    [Arguments]      ${proc_num}

    # Description of argument(s):
    # proc_num            Processor Number (e.g '0', '1').

    ${cmd}=  Catenate  pdbg -d p9w -p${proc_num} getcfam 0x2801

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}

    @{words}=  Split String  ${cmd_output}

    [Return]  ${words[2]}


Get Jumper Bit Value
    [Documentation]  Get jumper bit position value.
    [Arguments]      ${input_val}

    ${jumper_pos}=  get_jumper_position  ${input_val}
    Log To Console  ${jumper_pos}
    [Return]  ${jumper_pos}


Get SB Bit Value
    [Documentation]  Get SB bit position value.
    [Arguments]      ${input_val}

    ${sb_policy}=   get_secureboot_policy  ${input_val}
    Log To Console  ${sb_policy}
    [Return]  ${sb_policy}


Get Jumper State
    [Documentation]  Get SB jumper state (ON/OFF) on all processor chips.

    REST Power On  stack_mode=skip  quiet=1

    # Witherspoon is limited two chips. So,keeping it simple.
    # TODO:
    # Additional logic needed to scan through no. of chips and fetch the value.
    ${cfam_val_p0}=  Get SB Cfam  ${0}
    ${cfam_val_p1}=  Get SB Cfam  ${1}

    ${p0_jumper_bit}=  Get Jumper Bit Value  ${cfam_val_p0}
    ${p1_jumper_bit}=  Get Jumper Bit Value  ${cfam_val_p1}

    # Get system level jumper state
    ${jumper_state}=  get_system_jumper_state
    ...               ${p0_jumper_bit}  ${p1_jumper_bit}

    [Return]  ${jumper_state}


Get SB State
    [Documentation]  Get SB state (ENABLED/DISABLED) on all processor chips.

    REST Power On  stack_mode=skip  quiet=1

    # Witherspoon is limited two chips. So,keeping it simple.
    # TODO:
    # Additional logic needed to scan through no. of chips and fetch the value.
    ${cfam_val_p0}=  Get SB Cfam  ${0}
    ${cfam_val_p1}=  Get SB Cfam  ${1}

    ${p0_sb_bit}=  Get SB Bit Value  ${cfam_val_p0}
    ${p1_sb_bit}=  Get SB Bit Value  ${cfam_val_p1}

    # Get system level SB state
    ${sb_state}=  get_system_sb_state
    ...           ${p0_sb_bit}  ${p1_sb_bit}

    [Return]  ${sb_state}

