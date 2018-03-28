*** Settings ***
Documentation  Secure boot keywords.

*** Keywords ***

Set TPMEnable Policy
    [Documentation]  Enable or disable TPM Policy.
    [Arguments]  ${tpm_policy}

    # Description of argument(s):
    # tpm_policy  Enable-1 or Disable-0.

    ${value_Dict}=  Create Dictionary  data=${tpm_policy}
    Write Attribute  ${CONTROL_HOST_URI}/TPMEnable  TPMEnable
    ...  data=${value_Dict}


Set And Verify TPM Policy
    [Documentation]  Enable or disable and verify TPM Policy.
    [Arguments]  ${tpm_policy}

    # Description of argument(s):
    # tpm_policy  Enable-1 or Disable-0.

    Set TPMEnable Policy  ${tpm_policy}
    ${resp}=  Verify The Attribute
    ...  ${CONTROL_URI}/host0/TPMEnable  TPMEnable  ${tpm_policy}


REST Verify No Gard Records
    [Documentation]  Verify no gard records are present.

    ${resp}=  Read Properties  ${OPENPOWER_CONTROL}gard/enumerate
    Log Dictionary  ${resp}
    Should Be Empty  ${resp}  msg=Found gard records.
