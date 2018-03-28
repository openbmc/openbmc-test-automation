*** Settings ***
Documentation  Secure boot related test cases

Library           SSHLibrary   timeout=30 seconds
Library           OperatingSystem
Library           Collections
Library           Telnet
Library           String

*** Keywords ***


Enable TPMEnable Policy
    [Documentation]  Enable or Disable TPM Policy.
    [Arguments]  ${TPM_Policy}

    # Description of argument(s):
    # TPM_Policy  0 or 1

    ${valueDict}=  Create Dictionary  data=${TPM_policy}
    Write Attribute  ${CONTROL_HOST_URI}/TPMEnable  TPMEnable
    ...  data=${valueDict}


Enable And Verify TPM Policy
    [Documentation]  Enable And Verify TPM Policy
    [Arguments]  ${TPM_Policy}

    # Description of argument(s):
    # TPMEnable  0 or 1

    Enable TPMEnable Policy  ${TPM_Policy}
    ${resp}=  Verify The Attribute
    ...  ${CONTROL_URI}/host0/TPMEnable  TPMEnable  ${TPM_Policy}


No Gard Records Present
    [Documentation]  No Gard Records Present

    ${resp}=  Read Properties  ${OPENPOWER_CONTROL}gard/enumerate
    Log Dictionary  ${resp}
    Should Be Empty  ${resp}
    ...  msg=Found gard records.

Verify The Attribute
    [Arguments]  ${uri}  ${parm}  ${value}

    # Description of arguments:
    # uri     URI path.
    # parm    Attribute.
    # value   Output to be compared.

    ${output}=  Read Attribute  ${uri}  ${parm}
    Should Be Equal  ${value}  ${output}
