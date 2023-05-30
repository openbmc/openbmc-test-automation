*** Settings ***
Documentation    Module to test dcmi management controller functionality.
Resource         ../../lib/ipmi_client.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_network_utils.robot
Resource         ../../lib/boot_utils.robot
Resource         ../../lib/bmc_redfish_utils.robot
Variables        ../../data/ipmi_raw_cmd_table.py
Variables        ../../data/dcmi_raw_cmd_table.py
Variables        ../../data/ipmi_variable.py
Library          ../../lib/ipmi_utils.py
Library          ../../lib/utilities.py
Library          ../../lib/utils.py
Library          JSONLibrary

*** Variables ***
${hostname_file_path}  /etc/hostname

*** Test Cases ***
Validate IPMI Response Length
    [Documentation]  Check ipmi response length.
    [Tags]  Validate_IPMI_Response_Length

    ${rsp}=  Get DCMI Management Controller Identifier String
    @{ipmi_cmd_rsp_list}=  Split String  ${rsp}
    # ipmi_cmd_rsp_list = ["00", "0a", "00", "01", "02", "03",
    #                      "04", "05", "06", "07", "08", "09"]
    # rsp_length = 10
    # string_length = 0a
    ${rsp_length}=  Get Length  ${ipmi_cmd_rsp_list[2:]}
    ${string_length}=  Get Response Length In Hex  ${rsp_length}

    # ipmi_cmd_rsp_list[1] = 0a
    # string_length = 0a
    # the above condition is equal.
    # suppose if string_length and ipmi_cmd_rsp_list[1] not matches
    #  then it will fails.
    Should Be Equal As Strings  ${ipmi_cmd_rsp_list[1]}  ${string_length}
    ...  msg=Id string length in ipmi response is showing wrongly

Test Hostname Is Same With Management Controller Identifier String
    [Documentation]  Check hostname was verified with get management
    ...              controller identifier string.
    [Tags]  Test_Hostname_Is_Same_With_Management_Controller_Identifier_String

    ${rsp}=  Get DCMI Management Controller Identifier String
    @{ipmi_cmd_rsp_list}=  Split String  ${rsp}
    ${bmc_console_hostname_bytes_list}=  Get Hostname From BMC Console

    Lists Should Be Equal  ${ipmi_cmd_rsp_list[2:]}  ${bmc_console_hostname_bytes_list}
    ...  msg=response get from dcmi get mcid cmd and hostname from "cat /etc/os-release" cmd is not same.

Test Get Management Controller Identifier String
    [Documentation]  Validate set and get mcid string.
    [Tags]  Test_Get_Management_Controller_Identifier_String
    [Setup]  Get Default MCID
    [Teardown]  Set Default MCID

    # Set Hostname via DCMI Management Controller Identifier String Command.
    ${cmd_rsp}=  Set DCMI Management Controller Identifier String
    @{cmd_rsp_list}=  Split String  ${cmd_rsp}
    Run Keyword And Continue On Failure
    ...  Valid Value  cmd_rsp_list[1]  valid_values=['${number_of_bytes_to_write}']

    ${rsp}=  Get DCMI Management Controller Identifier String
    @{ipmi_cmd_rsp_list}=  Split String  ${rsp}

    # Verify number of bytes that was set and id string length are same.
    ${string_length}=  Get Response Length In Hex  ${random_int}
    Run Keyword And Continue On Failure
    ...  Should Be Equal As Strings  ${ipmi_cmd_rsp_list[1]}  ${string_length}
    ...  msg=Number of bytes that was set and id string length are not same.

    # Verify ID String Length and data.
    # ipmi_cmd_rsp_list = ["00", "0a", "00", "01", "02", "03", "04",
    #                      "05", "06", "07", "08", "09"]
    # rsp_length = 10
    # string_length = 0a
    # ipmi_cmd_rsp_list[1] = 0a
    # ipmi_cmd_rsp_list[1] is equal to string_length
    # the above condition is equal.
    # suppose if string_length and ipmi_cmd_rsp_list[1] not matches then
    # it will fails.
    ${rsp_length}=  Get Length  ${ipmi_cmd_rsp_list[2:]}
    ${string_length}=  Get Response Length In Hex  ${rsp_length}
    Run Keyword And Continue On Failure
    ...  Should Be Equal As Strings  ${ipmi_cmd_rsp_list[1]}  ${string_length}
    ...  msg=Id string length in ipmi response is showing wrongly

    # Verify get dcmi management controller identifier string command response
    # and the bytes used for Set DCMI MCID string.
    ${set_dcmi_mcid_cmd}=
    ...  convert_prefix_hex_list_to_non_prefix_hex_list  ${string_hex_list}
    Run Keyword And Continue On Failure
    ...  Lists Should Be Equal  ${ipmi_cmd_rsp_list[2:]}  ${set_dcmi_mcid_cmd}
    ...  msg=Bytes given in dcmi set mcid command and string bytes got from dcmi get mcid command are not same

    # Verify Hostname of cat /etc/hostname and get dcmi management controller identifier string command.
    ${bytes_list}=  Get Hostname From BMC Console
    Run Keyword And Continue On Failure
    ...  Lists Should Be Equal  ${ipmi_cmd_rsp_list[2:]}  ${bytes_list}
    ...  msg=Bytes got from dcmi get mcid command and hostname from "cat /etc/os-release" command is not same.

*** Keywords ***
Get Default MCID
    [Documentation]  Get default mcid.

    ${default_mcid}=  Get DCMI Management Controller Identifier String
    Set Test Variable  ${default_mcid}

Set Default MCID
    [Documentation]  Set default mcid.

    @{ipmi_cmd_rsp_list}=  Split String  ${default_mcid}
    ${number_of_bytes_to_write}=  Set Variable  ${ipmi_cmd_rsp_list[1]}
    ${bytes_in_int}=  Convert To Integer  ${number_of_bytes_to_write}  16
    ${bytes_to_write}=  Evaluate  ${bytes_in_int} + 1
    ${no_of_bytes_to_write}=  Get Response Length In Hex  ${bytes_to_write}
    @{tmp_lst}=  Create List
    FOR  ${bytes}  IN  @{ipmi_cmd_rsp_list[2:]}
      Append To List  ${tmp_lst}  0x${bytes}
    END
    ${default_hex}=  Catenate  @{tmp_lst}

    ${cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['MANAGEMENT_CONTROLLER_IDENTIFIER_STRING']['SET']}
    ...  0x${no_of_bytes_to_write} ${default_hex}
    Run External IPMI Raw Command  ${cmd}

Get DCMI Management Controller Identifier String
    [Documentation]  Get DCMI MCID String.

    ${mcid_get_cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['MANAGEMENT_CONTROLLER_IDENTIFIER_STRING']['GET']}
    ${resp}=  Run External IPMI Raw Command  ${mcid_get_cmd}

    [Return]  ${resp}

Set DCMI Management Controller Identifier String
    [Documentation]  Set DCMI MCID String.

    # 16 bytes maximum as per dcmi spec
    ${random_int}=  Evaluate  random.randint(1, 15)  modules=random
    ${random_string}=  Generate Random String  ${random_int}
    ${string_hex_list}=  convert_name_into_bytes_with_prefix  ${random_string}
    ${random_hex}=  Catenate  @{string_hex_list}
    ${number_of_random_string}=  Evaluate  ${random_int} + 1
    ${number_of_bytes_to_write}=  Get Response Length In Hex  ${number_of_random_string}

    ${mcid_set_cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['MANAGEMENT_CONTROLLER_IDENTIFIER_STRING']['SET']}
    ...  0x${number_of_bytes_to_write} ${random_hex} 0x00
    ${resp}=  Run External IPMI Raw Command  ${mcid_set_cmd}

    Set Test Variable  ${string_hex_list}
    Set Test Variable  ${random_int}
    Set Test Variable  ${number_of_bytes_to_write}

    [Return]  ${resp}

Get Hostname From BMC Console
    [Documentation]  Get hostname.

    ${cmd}=  Catenate  cat ${hostname_file_path}
    ${bmc_hostname}=  BMC Execute Command  ${cmd}
    ${name}=  Convert To List  ${bmc_hostname}
    ${hostname_bytes}=  convert_name_into_bytes_without_prefix  ${name[0]}

    [Return]  ${hostname_bytes}

Get Response Length In Hex
    [Documentation]  Get response length in hex.
    [Arguments]  ${resp_length}

    ${length}=  Convert To Hex  ${resp_length}
    ${length_1}=  Get Length  ${length}
    ${length_2}=  Set Variable IF
    ...  '${length_1}' == '1'  0${length}
    ...  '${length_1}' != '1'  ${length}
    ${resp_length_3}=  Convert To Lower Case  ${length_2}

    [Return]  ${resp_length_3}
