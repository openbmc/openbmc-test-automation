*** Settings ***
Documentation    Module to test IPMI chipher functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Library          ../lib/ipmi_utils.py
Variables        ../data/ipmi_raw_cmd_table.py

Test Teardown    FFDC On Test Case Fail

*** Variables ***


*** Test Cases ***

Verify Supported Cipher List
    [Documentation]  Execute all supported cipher levels and verify.
    [Tags]  Verify_Supported_Cipher_List
    :FOR  ${cipher_level}  IN  @{valid_cipher_list}
    \  ${status}  ${output}=  Run Keyword And Ignore Error
    ...    Run External IPMI Standard Command  power status  C=${cipher_level}
    \  Should Be Equal  ${status}  PASS  msg=${output}  values=False


Verify Unsupported Cipher List
    [Documentation]  Execute all unsupported cipher levels and verify error.
    [Tags]  Verify_Unsupported_Cipher_List
    :FOR  ${cipher_level}  IN  @{unsupported_cipher_list}
    \  ${status}  ${output}=  Run Keyword And Ignore Error
    ...  Run External IPMI Standard Command  power status  C=${cipher_level}
    \  Should Be Equal  ${status}  FAIL  values=False
    ...  msg=ipmitool execution with cipher suite value of ${cipher_level} should have failed.


Verify Supported Cipher List Via Lan Print
    [Documentation]  Verify supported cipher list via IPMI lan print command.
    [Tags]  Verify_Supported_Cipher_List_Via_Lan_Print

    ${channel_ipmi_cipher}=  Get Channel Ciphers

    # Example cipher entry: 3 17
    Rprint Vars  channel_ipmi_cipher

    ${cipher_list}=  Evaluate  list(map(int, $channel_ipmi_cipher))
    Lists Should Be Equal  ${cipher_list}  ${valid_cipher_list}


Verify Supported Cipher Via Getciphers
    [Documentation]  Verify supported chiper list via IPMI getciphers command.
    [Tags]  Verify_Supported_Cipher_Via_Getciphers
    ${output}=  Run IPMI Standard Command  channel getciphers ipmi
    # Example of getciphers command output:
    # ID   IANA    Auth Alg        Integrity Alg   Confidentiality Alg
    # 3    N/A     hmac_sha1       hmac_sha1_96    aes_cbc_128
    # 17   N/A     hmac_sha256     sha256_128      aes_cbc_128

    ${report}=  Outbuf To Report  ${output}
    # Make list from the 'id' column in the report.
    ${cipher_list}=  Evaluate  [int(x['id']) for x in $report]
    Lists Should Be Equal  ${cipher_list}  ${valid_cipher_list}


*** Keywords ***

