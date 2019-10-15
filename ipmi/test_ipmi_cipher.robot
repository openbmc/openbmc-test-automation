*** Settings ***
Documentation    Module to test IPMI chipher functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Library          ../lib/ipmi_utils.py
Library          ../lib/var_funcs.py
Variables        ../data/ipmi_raw_cmd_table.py
Library          String

Test Setup       Printn
Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify Supported Ciphers
    [Documentation]  Execute all supported ciphers and verify.
    [Tags]  Verify_Supported_Ciphers
    FOR  ${cipher}  IN  @{valid_ciphers}
      Run External IPMI Standard Command  power status  C=${cipher}
    END


Verify Unsupported Ciphers
    [Documentation]  Execute all unsupported ciphers and verify error.
    [Tags]  Verify_Unsupported_Ciphers
    FOR  ${cipher}  IN  @{unsupported_ciphers}
      Run Keyword And Expect Error  *invalid * algorithm*
      ...  Run External IPMI Standard Command  power status  C=${cipher}
    END


Verify Supported Ciphers Via Lan Print
    [Documentation]  Verify supported ciphers via IPMI lan print command.
    [Tags]  Verify_Supported_Ciphers_Via_Lan_Print

    ${lan_print}=  Get Lan Print Dict
    # Example 'RMCP+ Cipher Suites' entry: 3,17
    ${ciphers}=  Split String  ${lan_print['RMCP+ Cipher Suites']}  ,
    Rprint Vars  ciphers
    Valid List  ciphers  valid_values=${valid_ciphers}


Verify Supported Cipher Via Getciphers
    [Documentation]  Verify supported chipers via IPMI getciphers command.
    [Tags]  Verify_Supported_Cipher_Via_Getciphers

    # Example output from 'Channel Getciphers IPMI':
    # ipmi_channel_ciphers:
    #   [0]:
    #     [id]:                                         3
    #     [iana]:                                       N/A
    #     [auth_alg]:                                   hmac_sha1
    #     [integrity_alg]:                              hmac_sha1_96
    #     [confidentiality_alg]:                        aes_cbc_128
    #   [1]:
    #     [id]:                                         17
    #     [iana]:                                       N/A
    #     [auth_alg]:                                   hmac_sha256
    #     [integrity_alg]:                              sha256_128
    #     [confidentiality_alg]:                        aes_cbc_128

    ${ipmi_channel_ciphers}=  Channel Getciphers IPMI
    # Example cipher entry: 3 17
    Rprint Vars  ipmi_channel_ciphers
    ${ipmi_channel_cipher_ids}=  Nested Get  id  ${ipmi_channel_ciphers}
    Rpvars  ipmi_channel_cipher_ids
    Valid List  ipmi_channel_cipher_ids  valid_values=${valid_ciphers}
