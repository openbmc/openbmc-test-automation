*** Settings ***

Documentation    Module to test dcmi asset tag functionality.
Resource         ../../lib/ipmi_client.robot
Resource         ../../lib/openbmc_ffdc.robot
Library          ../../lib/gen_robot_valid.py
Library          ../../lib/utils.py
Variables        ../../data/dcmi_raw_cmd_table.py

Suite Setup      Redfish.Login
Suite Teardown   Redfish.Logout
Test Teardown    FFDC On Test Case Fail


*** Test Cases ***

Set Asset Tag With Valid String Length
    [Documentation]  Set asset tag with valid string length and verify.
    [Tags]  Set_Asset_Tag_With_Valid_String_Length
    # Allowed MAX characters length for asset tag name is 63.
    ${random_string}=  Generate Random String  63
    Run Keyword  Run IPMI Standard Command  dcmi set_asset_tag ${random_string}

    ${asset_tag}=  Run Keyword  Run IPMI Standard Command  dcmi asset_tag
    Should Contain  ${asset_tag}  ${random_string}


Set Asset Tag With Invalid String Length
    [Documentation]  Verify error while setting invalid asset tag via IPMI.
    [Tags]  Set_Asset_Tag_With_Invalid_String_Length
    # Any string more than 63 character is invalid for asset tag.
    ${random_string}=  Generate Random String  64

    ${resp}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  dcmi set_asset_tag ${random_string}
    Should Contain  ${resp}  Parameter out of range  ignore_case=True


Set Asset Tag With IPMI And Verify With Redfish
    [Documentation]  Set valid asset tag via IPMI and verify using Redfish.
    [Tags]  Set_Asset_Tag_With_IPMI_And_Verify_With_Redfish

    ${random_string}=  Generate Random String  63
    Run Keyword  Run IPMI Standard Command  dcmi set_asset_tag ${random_string}

    ${asset_tag}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  AssetTag
    Valid Value  asset_tag  ['${random_string}']


Set Asset Tag With Valid String Length Via DCMI Command
    [Documentation]  Set asset tag with valid string length and verify.
    [Tags]  Set_Asset_Tag_With_Valid_String_Length_Via_DCMI_Command

    ${cmd_resp}=  Set Valid Asset Tag
    @{cmd_resp_list}=  Split String  ${cmd_resp}
    Run Keyword And Continue On Failure
    ...  Valid Value  cmd_resp_list[1]  valid_values=['${number_of_bytes_to_write}']
    Validate Asset Tag Via Raw Command


Set Asset Tag With Invalid String Length Via DCMI Command
    [Documentation]  Set asset tag with invalid string length and verify.
    [Tags]  Set_Asset_Tag_With_Invalid_String_Length_Via_DCMI_Command

    ${random_string}=  Generate Random String  ${16}
    ${string_hex_list}=  convert_name_into_bytes_with_prefix  ${random_string}
    ${random_hex}=  Catenate  @{string_hex_list}
    ${number_of_random_string}=  Evaluate  ${16} + 1
    ${number_of_bytes_to_write}=  Get Response Length In Hex  ${number_of_random_string}

    ${cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['Asset_Tag'][1]} 0x${number_of_bytes_to_write} ${random_hex}
    ${resp}=  Run Keyword And Expect Error  *
    ...  Run External IPMI Raw Command  ${cmd}
    Should Contain  ${resp}  resp=0xc9): Parameter out of range:  ignore_case=True


Set Valid Asset Tag With DCMI And Verify With Redfish
    [Documentation]  Set valid asset tag via IPMI and verify using Redfish.
    [Tags]  Set_Asset_Tag_With_DCMI_And_Verify_With_Redfish

    ${cmd_resp}=  Set Valid Asset Tag
    @{cmd_resp_list}=  Split String  ${cmd_resp}
    Run Keyword And Continue On Failure
    ...  Valid Value  cmd_resp_list[1]  valid_values=['${number_of_bytes_to_write}']

    ${asset_tag}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  AssetTag
    Valid Value  asset_tag  ['${random_string}']

*** Keywords ***
Set Valid Asset Tag
    [Documentation]  Set valid length asset tag.

    # 16 bytes maximum as per dcmi spec
    ${random_int}=  Evaluate  random.randint(1, 15)  modules=random
    ${random_string}=  Generate Random String  ${random_int}
    ${string_hex_list}=  convert_name_into_bytes_with_prefix  ${random_string}
    ${random_hex}=  Catenate  @{string_hex_list}
    ${number_of_random_string}=  Evaluate  ${random_int} + 1
    ${number_of_bytes_to_write}=  Get Response Length In Hex  ${number_of_random_string}

    ${cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['Asset_Tag'][1]} 0x${number_of_bytes_to_write} ${random_hex}
    ${ret}=  Run External IPMI Raw Command  ${cmd}

    Set Test Variable  ${string_hex_list}
    Set Test Variable  ${random_string}
    Set Test Variable  ${number_of_bytes_to_write}

    [Return]  ${ret}

Get Raw Asset Tag
    [Documentation]  Get asset tag command in raw command.

    ${cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['Asset_Tag'][0]} 0x${number_of_bytes_to_write}
    ${ret}=  Run External IPMI Raw Command  ${cmd}

    [Return]  ${ret}

Validate Asset Tag Via Raw Command
    [Documentation]  Validate asset tag via raw cmd.

    ${cmd_resp}=  Get Raw Asset Tag
    @{resp_list}=  Split String  ${cmd_resp}
    Run Keyword And Continue On Failure
    ...  Valid Value  resp_list[1]  valid_values=['${number_of_bytes_to_write}']
    ${data_list}=  convert_prefix_hex_list_to_non_prefix_hex_list  ${string_hex_list}
    Lists Should Be Equal  ${data_list}  ${resp_list[2:]}
    ...  msg=Get asset tag command response is showing wrong response ${data_list}.

Get Response Length In Hex
    [Documentation]  Get response length in hex.
    [Arguments]  ${resp_length}

    ${length}=  Convert To Hex  ${resp_length}
    ${length_1}=  Get Length  ${length}
    ${length_2}=  Set Variable IF
    ...  '${length_1}' == '1'  0${length}
    ...  '${length_1}' != '1'  ${length}
    ${ret}=  Convert To Lower Case  ${length_2}

    [Return]  ${ret}
