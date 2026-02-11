*** Settings ***
Documentation    Module to test IPMI chipher functionality.

Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/bmc_network_utils.robot
Library          ../lib/ipmi_utils.py
Library          ../lib/var_funcs.py
Variables        ../data/ipmi_raw_cmd_table.py
Library          String


Suite Setup      IPMI Cipher Suite Setup
Test Setup       Printn
Test Teardown    FFDC On Test Case Fail

Test Tags        IPMI_Cipher

*** Variables ***
${cipher_suite}      standard
&{payload_type}      ipmi=0  sol=1
@{list_index_value}  0x80  0x00


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
    [Documentation]  Verify supported cihpers via IPMI getciphers command.
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


Verify Cipher Suite And Supported Algorithms Via IPMI Raw Command
    [Documentation]  Verify cipher ID and Supported Algorithms for all Available
    ...  Channels.
    [Tags]  Verify_Cipher_Suite_And_Supported_Algorithms_Via_IPMI_Raw_Command
    [Template]  Verify Cipher ID And Supported Algorithm For Channel

    FOR  ${channel}  IN  @{active_channel_list}
        FOR  ${name}  ${type}  IN  &{payload_type}
            FOR  ${index_value}  IN  @{list_index_value}
                # Input Channel   Payload type    Index value 0x80 or 0x00
                ${channel}        ${type}         ${index_value}
            END
        END
    END


Verify Get Cipher Suite Command For Invalid Channels
    [Documentation]  Verify Get Cipher Suite Command For all Invalid Channels.
    [Tags]  Verify_Get_Cipher_Suite_Command_For_Invalid_Channels
    [Template]  Verify Cipher Suite For Invalid Channel

    FOR  ${channel}  IN  @{inactive_channel_list}
        # Input Channel
        ${channel}
    END


Verify Get Cipher Suite Raw Command With Invalid Data Length
    [Documentation]  Verify Get Cipher Suite Raw Command With One Extra and Less Byte.
    [Tags]  Verify_Get_Cipher_Suite_Raw_Command_With_Invalid_Data_Length
    [Template]  Verify Cipher Suite Command For Invalid Request Data

    # Byte
    less
    extra


*** Keywords ***

IPMI Cipher Suite Setup
    [Documentation]  Get active and inactive/invalid channels from channel_config.json file
    ...              in list type and set it as suite variable.

    # Get active channel list and set as a suite variable.
    @{active_channel_list}=  Get Active Ethernet Channel List  current_channel=1
    Set Suite Variable  @{active_channel_list}

    # Get Inactive/Invalid channel list and set as a suite variable.
    @{inactive_channel_list}=  Get Invalid Channel Number List
    Set Suite Variable  @{inactive_channel_list}

Verify Standard Cipher Suite For Channel
    [Documentation]  Get the supported algorithms from data/ipmi_raw_cmd_table.py and
    ...              split into list and compare it with the given data list.
    [Arguments]  ${data_list}  ${channel_number}

    # Description of argument(s):
    # data_list       cipher suite records in list
    #                 e.g  [01, c0, 11, 03, 44, 81]
    # channel_number  Interface channel number

    ${supported_algorithms}=  Split String  ${IPMI_RAW_CMD['Cipher Suite']['get'][1]}
    ${cipher_suite_id}=  Convert To Integer  ${data_list}[2]  base=16

    Should Be Equal  ${data_list}[0]  ${channel_number}
    Should Be Equal  ${data_list}[1]  c0
    Should Be Equal As Integers  ${cipher_suite_id}  ${valid_ciphers}[0]
    List Should Contain Value  ${supported_algorithms}  ${data_list}[3]
    List Should Contain Value  ${supported_algorithms}  ${data_list}[4]
    List Should Contain Value  ${supported_algorithms}  ${data_list}[5]

Verify Algorithm By Cipher Suite For Channel
    [Documentation]  Spilt the given response data, store it in a list.
    [Arguments]  ${response_data}  ${channel_number}

    # Description of argument(s):
    # response_data   Response data of get channel cipher suite IPMI raw command
    #   e.g  01 c0 11 03 44 81   ---> list of algorithms by cipher suite (0x80 in request data 3rd byte)
    # channel_number  Interface channel number

    @{expected_data_list}=  Split String  ${response_data}

    IF  '${cipher_suite}' == 'standard'
        Verify Standard Cipher Suite For Channel  ${expected_data_list}  ${channel_number}
    END

Verify Supported Algorithm For Channel
    [Documentation]  Compare the supported algorithms got from ipmi_raw_cmd_table with
    ...              given response.
    [Arguments]  ${response_data}  ${channel_number}

    # Description of argument(s):
    # response_data    response data of get channel cipher suite IPMI raw command.
    # channel_number   Interface Channel Number.

    # expected data will be like " 01 03 44 81 ".
    ${expected_data}=  Catenate  ${channel_number}  ${IPMI_RAW_CMD['Cipher Suite']['get'][1]}

    Should Be Equal  ${expected_data}  ${response_data}

Verify Cipher ID And Supported Algorithm For Channel
    [Documentation]  Verify Cipher ID and Supported Algorithm on given channel.
    [Arguments]  ${channel_num}  ${payload_type}  ${index_value}

    # Description of argument(s):
    # channel_num    Interface channel number.
    # payload_type   IPMI(0x00) or SOL(0x01).
    # index_value    0x80 for list algorithm by cipher suite.
    #                0x00 for supported algorithms.

    ${cmd}=  Catenate  ${IPMI_RAW_CMD['Cipher Suite']['get'][0]}
    ...  ${channel_num} ${payload_type} ${index_value}

    ${resp}=  Run IPMI Command  ${cmd}
    ${resp}=  Strip String  ${resp}

    # channel 14 represents current channel in which we send request.
    ${channel_num}=  Set Variable If  '${channel_num}' == '14'
    ...  Convert To Hex  ${CHANNEL_NUMBER}  length=2
    ...  ELSE
    ...  Convert To Hex  ${channel_num}  length=2

    IF  '${index_value}' == '0x80'
        Verify Algorithm By Cipher Suite For Channel  ${resp}  ${channel_num}
    ELSE
        Verify Supported Algorithm For Channel  ${resp}  ${channel_num}
    END

Verify Cipher Suite For Invalid Channel
   [Documentation]  Execute cipher suite ipmi cmd for invalid channel and verify Error code.
   [Arguments]  ${channel_number}

   # Description of argument(s):
   # channel_number   Interface channel number.

   ${cmd}=  Catenate  ${IPMI_RAW_CMD['Cipher Suite']['get'][0]} ${channel_number} 00 00

   Verify Invalid IPMI Command  ${cmd}  0xcc

Verify Cipher Suite Command For Invalid Request Data
   [Documentation]  Verify Cipher Suite Command with Invalid data Length.
   [Arguments]  ${byte_length}

   # Description of argument(s):
   # byte_length   extra or less.

   ${req_cmd}=  Set Variable If  '${byte_length}' == 'less'
   ...  Catenate  ${IPMI_RAW_CMD['Cipher Suite']['get'][0]} ${CHANNEL_NUMBER} 00
   ...  ELSE
   ...  Catenate  ${IPMI_RAW_CMD['Cipher Suite']['get'][0]} ${CHANNEL_NUMBER} 00 00 01

   Verify Invalid IPMI Command  ${req_cmd}  0xc7
