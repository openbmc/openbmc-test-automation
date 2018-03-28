*** Settings ***
Documentation  Secure boot keywords.

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
