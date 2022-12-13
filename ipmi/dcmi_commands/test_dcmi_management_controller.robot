*** Settings ***
Documentation    Module to test IPMI DCMI functionality.
Resource         ../../lib/ipmi_client.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_network_utils.robot
Resource         ../../lib/boot_utils.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/bmc_redfish_utils.robot
Variables        ../../data/ipmi_raw_cmd_table.py
Variables        ../../data/dcmi_raw_cmd_table.py
Variables        ../../data/ipmi_variable.py
Library          ../../lib/bmc_network_utils.py
Library          ../../lib/ipmi_utils.py
Library          ../../lib/utilities.py
Library          ../../lib/utils.py
Library          JSONLibrary

*** Variables ***
${hostname_cmd}  /etc/hostname

*** Test Cases ***
Validate String Length
    [Documentation]  Check string length.
    [Tags]  Validate_String_Length

    ${rsp}=  Get DCMI Management Controller Identifier String
    @{ipmi_cmd_rsp_list}=  Split String  ${rsp}
    ${rsp_length}=  Get Length  ${ipmi_cmd_rsp_list[2:]}
    ${string_length}=  Get Response Length In Hex  ${rsp_length}

    Should Be Equal As Strings  ${ipmi_cmd_rsp_list[1]}  ${string_length}
    ...  msg=Id string length in ipmi response is showing wrongly

Check Hostname Was Verified With Get Management Controller Identifier String
    [Documentation]  Check hostname was verified with get management controller identfier string.
    [Tags]  Validate_Hostname_With_Get_DCMI_MCID_String

    ${rsp}=  Get DCMI Management Controller Identifier String
    @{ipmi_cmd_rsp_list}=  Split String  ${rsp}
    ${bmc_console_hostname_bytes_list}=  Get Hostname From BMC Console

    Lists Should Be Equal  ${ipmi_cmd_rsp_list[2:]}  ${bmc_console_hostname_bytes_list}
    ...  msg=String bytes got from dcmi get mcid command and hostname bytes from "cat /etc/os-release" command are not same.

Set And Get Management Controller Identifier String
    [Documentation]  Validate set and get mcid string.
    [Tags]  Set_And_Get_Management_Controller_Identifier_String
    [Setup]  Get Default MCID
    [Teardown]  Set Default MCID

    # Set Hostname via DCMI Management Controller Identifier String Command.
    ${cmd_rsp}=  Set DCMI Management Controller Identifier String
    @{cmd_rsp_list}=  Split String  ${cmd_rsp}
    Run Keyword And Continue On Failure  Valid Value  cmd_rsp_list[1]  valid_values=['${number_of_bytes_to_write}']

    ${rsp}=  Get DCMI Management Controller Identifier String
    @{ipmi_cmd_rsp_list}=  Split String  ${rsp}

    # Verify number of bytes that was set and id string length are same.
    ${string_length}=  Get Response Length In Hex  ${random_int}
    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${ipmi_cmd_rsp_list[1]}  ${string_length}
    ...  msg=Number of bytes that was set and id string length are not same.

    # Verify ID String Length and data.
    ${rsp_length}=  Get Length  ${ipmi_cmd_rsp_list[2:]}
    ${string_length}=  Get Response Length In Hex  ${rsp_length}
    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${ipmi_cmd_rsp_list[1]}  ${string_length}
    ...  msg=Id string length in ipmi response is showing wrongly

    # Verify get dcmi management controller identifier string command response and the bytes used for Set DCMI MCID string.
    ${list_of_bytes_used_in_set_dcmi_mcid_command}=  convert_prefix_hex_list_to_non_prefix_hex_list  ${string_hex_list}
    Run Keyword And Continue On Failure  Lists Should Be Equal  ${ipmi_cmd_rsp_list[2:]}  ${list_of_bytes_used_in_set_dcmi_mcid_command}
    ...  msg=String bytes given in dcmi set mcid command and string bytes got from dcmi get mcid command are not same.

    # Verify Hostname of cat /etc/hostname and get dcmi management controller identifier string command.
    ${bmc_console_hostname_bytes_list}=  Get Hostname From BMC Console
    Run Keyword And Continue On Failure  Lists Should Be Equal  ${ipmi_cmd_rsp_list[2:]}  ${bmc_console_hostname_bytes_list}
    ...  msg=String bytes got from dcmi get mcid command and hostname bytes from "cat /etc/os-release" command are not same.

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
      ${byte}=  Set Variable  0x${bytes}
      Append To List  ${tmp_lst}  ${byte}
    END
    ${default_hex}=  Catenate  @{tmp_lst}

    ${cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['MANAGEMENT_CONTROLLER_IDENTIFIER_STRING']['SET']} 0x${no_of_bytes_to_write} ${default_hex}
    Run External IPMI Raw Command  ${cmd}

Get DCMI Management Controller Identifier String
    [Documentation]  Get DCMI MCID String.

    ${cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['MANAGEMENT_CONTROLLER_IDENTIFIER_STRING']['GET']}
    ${rsp}=  Run External IPMI Raw Command  ${cmd}

    [Return]  ${rsp}

Set DCMI Management Controller Identifier String
    [Documentation]  Set DCMI MCID String.

    # 16 bytes maximum as per dcmi spec
    ${random_int}=  Evaluate  random.randint(1, 15)  modules=random
    ${random_string}=  Generate Random String  ${random_int}
    ${string_hex_list}=  convert_name_into_bytes_with_prefix  ${random_string}
    ${random_hex}=  Catenate  @{string_hex_list}
    ${number_of_random_string}=  Evaluate  ${random_int} + 1
    ${number_of_bytes_to_write}=  Get Response Length In Hex  ${number_of_random_string}

    ${cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['MANAGEMENT_CONTROLLER_IDENTIFIER_STRING']['SET']} 0x${number_of_bytes_to_write} ${random_hex} 0x00
    ${rsp}=  Run External IPMI Raw Command  ${cmd}

    Set Test Variable  ${string_hex_list}
    Set Test Variable  ${random_int}
    Set Test Variable  ${number_of_bytes_to_write}

    [Return]  ${rsp}

Get Hostname From BMC Console
    [Documentation]  Get hostname.

    ${cmd}=  Catenate  cat ${hostname_cmd}
    ${hostname_bmc}=  BMC Execute Command  ${cmd}
    ${name}=  Convert To List  ${hostname_bmc}
    ${hostname}=  Set Variable   ${name[0]}
    ${hostname_bytes}=  convert_name_into_bytes_without_prefix  ${hostname}

    [Return]  ${hostname_bytes}

Get Response Length In Hex
    [Documentation]  Get response length in hex.
    [Arguments]  ${rsp_length}

    ${length}=  Convert To Hex  ${rsp_length}
    ${length_1}=  Get Length  ${length}
    ${length_2}=  Set Variable IF
    ...  '${length_1}' == '1'  0${length}
    ...  '${length_1}' != '1'  ${length}
    ${length_3}=  Convert To Lower Case  ${length_2}

    [Return]  ${length_3}
