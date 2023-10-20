*** Settings ***
Documentation       This suite tests IPMI Payload in OpenBMC.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/bmc_network_utils.robot
Variables           ../data/ipmi_raw_cmd_table.py
Library             ../lib/ipmi_utils.py
Test Tags           IPMI

Suite Setup         IPMI Payload Setup Execution
Test Teardown       FFDC On Test Case Fail


*** Variables ***
${user_priv}                     2
${operator_priv}                 3
${admin_level_priv}              4
${no_access_priv}                15
${new_user_passwd}               0penBmc1
${standard_payload_type_resp}    03 00
${session_setup_payload_resp}    3f 00
&{standard_payload_types}        ipmi_message=0  sol=1
&{session_setup_payload_types}  RMCP+open_session_request=0x10
                           ...  RMCP+open_session_response=0x11
                           ...  RAKP_msg_1=0x12
                           ...  RAKP_msg_2=0x13
                           ...  RAKP_msg_3=0x14
                           ...  RAKP_msg_4=0x15


*** Test Cases ***

Test Get Payload Activation Status
    [Documentation]  Test get payload activation status.
    [Tags]  Test_Get_Payload_Activation_Status

    # SOL is the payload currently supported for payload status.
    # Currently supports only one SOL session.
    # Response Data
    # 01   instance 1 is activated.
    # 00   instance 1 is deactivated.
    ${payload_status}=  Get Payload Activation Status
    Should Contain Any  ${payload_status}  01  00


Test Activate Payload
    [Documentation]  Test activate payload via IPMI raw command.
    [Tags]  Test_Activate_Payload

    ${payload_status}=  Get Payload Activation Status
    Run Keyword If  '${payload_status}' == '01'  Deactivate Payload

    Activate Payload

    ${payload_status}=  Get Payload Activation Status
    Should Contain  ${payload_status}  01


Test Deactivate Payload
    [Documentation]  Test deactivate payload via IPMI raw command.
    [Tags]  Test_Deactivate_Payload

    ${payload_status}=  Get Payload Activation Status
    Run Keyword If  '${payload_status}' == '00'  Activate Payload

    Deactivate Payload

    ${payload_status}=  Get Payload Activation Status
    Should Contain  ${payload_status}  00


Test Get Payload Instance Info
    [Documentation]  Test Get Payload Instance via IPMI raw command.
    [Tags]  Test_Get_Payload_Instance_Info

    ${payload_status}=  Get Payload Activation Status
    Run keyword If  '${payload_status}' == '01'
    ...  Deactivate Payload

    # First four bytes should be 00 if given instance is not activated.
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Payload']['Get_Payload_Instance_Info'][0]}
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Payload']['Get_Payload_Instance_Info'][1]}
    Activate Payload

    # First four bytes should be session ID when payload is activated.
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Payload']['Get_Payload_Instance_Info'][0]}
    Should Not Contain  ${resp}  ${IPMI_RAW_CMD['Payload']['Get_Payload_Instance_Info'][1]}


Verify Set User Access Payload For Standard Payload SOL
    [Documentation]  Disable standard payload for SOL and verify IPMI sol activate command does not work.
    [Tags]  Verify_Set_User_Access_Payload_For_Standard_Payload_SOL
    [Teardown]  Run Keywords  Set User Access Payload For Given User  ${user_id_in_hex}
    ...  AND  Delete Created User  ${userid}
    ...  AND  FFDC On Test Case Fail

    ${userid}  ${username}=  Create And Verify IPMI User
    ${user_id_in_hex}=  Convert To Hex  ${userid}
    ${userid_in_hex_format}=  Convert To Hex  ${userid}  prefix=0x  length=2

    # Get default user access payload values.
    ${default_user_access_payload}=  Get User Access Payload For Given Channel  ${userid_in_hex_format}

    # Disable Standard payload 1 via set user access payload command.
    Set User Access Payload For Given User  ${user_id_in_hex}  Disable

    Verify Standard Payload  ${userid_in_hex_format}  ${username}  Disabled


Verify Set User Access Payload For Operator Privileged User
    [Documentation]  Try to set user access payload using operator privileged user and expect error.
    [Tags]  Verify_Set_User_Access_Payload_For_Operator_Privileged_User
    [Teardown]  Run Keywords  Delete Created User  ${userid}  AND  FFDC On Test Case Fail

    ${userid}  ${username}=  Create And Verify IPMI User  ${operator_priv}  Operator

    ${payload_raw_cmd}=  Catenate  ${IPMI_RAW_CMD['Payload']['Set_User_Access_Payload'][0]}
    ...  ${CHANNEL_NUMBER} 0x${user_id} 0x02 0x00 0x00 0x00

    Run Keyword and Expect Error  *Unable to establish IPMI*
    ...  Run External IPMI Raw Command  ${payload_raw_cmd}  U=${userid}  P=${new_user_passwd}  L=Operator


Verify Set User Access Payload For Invalid User
    [Documentation]  Verify set user access payload IPMI command for invalid user.
    [Tags]  Verify_Set_User_Access_Payload_For_Invalid_User

    # Get Random invalid user ID.
    ${invalid_userid}=  Get Invalid User ID

    ${raw_cmd}=  Catenate   ${IPMI_RAW_CMD['Payload']['Set_User_Access_Payload'][0]}
    ...  ${CHANNEL_NUMBER} ${invalid_userid} 0x02 0x00 0x00 0x00

    Verify Invalid IPMI Command  ${raw_cmd}  0xcc


Verify Set User Access Payload For Invalid Channel Number
    [Documentation]  Verify set user access payload IPMI command for invalid channel number.
    [Tags]  Verify_Set_User_Access_Payload_For_Invalid_Channel_Number
    [Teardown]  Delete Created User  ${userid}

    ${userid}  ${username}=  Create And Verify IPMI User

    FOR  ${channel}  IN  @{inactive_channel_list}

        Verify Set User Access Payload For Invalid Channel  ${userid}  ${channel}
    END


Verify Get User Access Payload For User Access privilege
    [Documentation]   Verify get user access payload for user access(Read-only) privileged user.
    [Tags]  Verify_Get_User_Access_Payload_For_User_Access_privilege
    [Teardown]  Delete Created User  ${userid}

    ${userid}  ${username}=  Create And Verify IPMI User  ${user_priv}  User

    ${raw_command}=  Catenate  ${IPMI_RAW_CMD['Payload']['Get_User_Access_Payload'][0]}
    ...  ${CHANNEL_NUMBER} ${user_id}

    Run Keyword and Expect Error  *Unable to establish IPMI*
    ...  Run External IPMI Raw Command  ${raw_command}  U=${userid}  P=${new_user_passwd}  L=User


Verify Get User Access Payload For Invalid User
    [Documentation]  Verify get user access payload IPMI command for invalid user.
    [Tags]  Verify_Get_User_Access_Payload_For_Invalid_User

    ${invalid_userid}=  Get Invalid User ID

    Verify Get User Access Payload For Invalid User Or Channel  ${invalid_userid}  ${CHANNEL_NUMBER}


Verify Get User Access Payload For Invalid Channel Number
    [Documentation]  Verify get user access payload IPMI command for invalid channel number.
    [Tags]  Verify_Get_User_Access_Payload_For_Invalid_Channel_Number
    [Teardown]  Delete Created User  ${userid}

    ${userid}  ${username}=  Create And Verify IPMI User
    #${invalid_channels}=  Get Invalid Channel Number

    FOR  ${channel}  IN  @{inactive_channel_list}
        Verify Get User Access Payload For Invalid User Or Channel  ${userid}  ${channel}
    END


Verify Get Channel Payload Version
    [Documentation]  Verify payload version for all supported payload type in
                ...  all active channels.
    [Tags]  Verify_Get_Channel_Payload_Version
    [Template]  Verify Payload Version

    FOR  ${channel}  IN  @{active_channel_list}
        # Input Channel.
        ${channel}
    END

Verify Get Channel Payload Version For Invalid Channel
    [Documentation]  Verify get channel payload version IPMI command for invalid channel.
    [Tags]  Verify_Get_Channel_Payload_Version_For_Invalid_Channel
    [Template]  Verify Payload Version For Invalid Channel

    FOR  ${invalid_channel_number}  IN  @{inactive_channel_list}
        # channel number           payload types.
        ${invalid_channel_number}   &{standard_payload_types}
        ${invalid_channel_number}   &{session_setup_payload_types}
    END


Verify Get Channel Payload Support
    [Documentation]  Verify get channel payload support IPMI command for active channels.
    [Tags]  Verify_Get_Channel_Payload_Support
    [Template]  Verify Payload Support

    FOR  ${channel}  IN  @{active_channel_list}
        # Input channel.
        ${channel}
    END

Verify Get Channel Payload Support For Invalid Channel
    [Documentation]  Verify get channel payload support IPMI command for invalid channels.
    [Tags]  Verify_Get_Channel_Payload_Support_For_Invalid_Channel
    [Template]  Verify Payload Support

    FOR  ${channel}  IN  @{inactive_channel_list}
       # Input channel.      Invalid channel intimation.
       ${channel}            ${1}
   END


*** Keywords ***

IPMI Payload Setup Execution
    [Documentation]  Get active and inactive/invalid channels from channel_config.json file
    ...              in list type and set it as suite variable.

    # Get active channel list and set as a suite variable.
    @{active_channel_list}=  Get Active Ethernet Channel List  current_channel=1
    Set Suite Variable  @{active_channel_list}

    # Get Inactive/Invalid channel list and set as a suite variable.
    @{inactive_channel_list}=  Get Invalid Channel Number List
    Set Suite Variable  @{inactive_channel_list}


Get Payload Activation Status
    [Documentation]  Get payload activation status.

    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Payload']['Get_Payload_Activation_Status'][0]}

    @{resp}=  Split String  ${resp}

    ${payload_status}=  Set Variable  ${resp[1]}

    [return]  ${payload_status}


Activate Payload
    [Documentation]  Activate Payload.

    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Payload']['Activate_Payload'][0]}
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Payload']['Activate_Payload'][1]}


Deactivate Payload
    [Documentation]  Deactivate Payload.

    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Payload']['Deactivate_Payload'][0]}
    Should Be Empty  ${resp}


Get User Access Payload For Given Channel
    [Documentation]  Execute get user access payload IPMI command for given channel
    ...              and return response.
    [Arguments]  ${user_id}  ${channel_number}=${CHANNEL_NUMBER}

    # Description of argument(s):
    # user_id         The user ID (e.g. "1", "2", etc.).
    # channel_number  Input channel number(e.g. "1", "2").

    ${raw_command}=  Catenate  ${IPMI_RAW_CMD['Payload']['Get_User_Access_Payload'][0]}
    ...  ${channel_number} ${user_id}
    ${resp}=  Run External IPMI Raw Command  ${raw_command}
    [Return]  ${resp}


Create And Verify IPMI User
    [Documentation]  Create IPMI User, set password, set privilege and enable the user.
    [Arguments]  ${user_privilege_level}=${admin_level_priv}   ${privilege}=Administrator

    # Description of argument(s):
    # user_privilege_level   User Privilege level in integer.
    #                        (e.g. 4-Administrator, 3-Operator, 2-Readonly).
    # privilege              User Privilege in Wordings.
    #                        (e.g. "Administrator", "Operator", "ReadOnly").

    ${random_user_id}  ${random_user_name}=  Create Random IPMI User
    Set User Password  ${random_user_id}  ${new_user_passwd}  16
    Set And Verify User Access Privilege  ${random_user_id}  ${user_privilege_level}
    Verify Username And Password  ${random_user_name}  ${new_user_passwd}  L=${privilege}

    [Return]  ${random_user_id}  ${random_user_name}


Set User Password
    [Documentation]  Set user password for given user ID.
    [Arguments]  ${user_id}  ${password}  ${password_option}

    # Description of argument(s):
    # user_id          The user ID (e.g. "1", "2", etc.).
    # password         The user password (e.g. "0penBmc", "0penBmc1", etc.).
    # password_option  Password length option to be given in IPMI command (e.g. "16", "20").

    Run IPMI Standard Command  user set password ${user_id} ${password} ${password_option}

Set And Verify User Access Privilege
    [Documentation]  Set User Access Privilege, enable and verify user for given user ID.
    [Arguments]  ${user_id}  ${privilege_level}

    # Description of argument(s):
    # user_id           The user ID (e.g. "1", "2", etc.).
    # privilege_level   User Privilege level in hex value.
    #                   (e.g. 0x04-Administrator, 0x03-Operator, 0x02-Readonly).

    Set Channel Access  ${_user_id}  ipmi=on privilege=${privilege_level}

    # Delay added for user privilege to get set.
    Sleep  5s

    Enable IPMI User And Verify  ${user_id}


Verify Username And Password
    [Documentation]  Verify that newly created user is able to run IPMI command
    ...  with given username and password.
    [Arguments]  ${username}  ${password}  &{options}

    # Description of argument(s):
    # username    The user name (e.g. "root", "robert", etc.).
    # password    The user password (e.g. "0penBmc", "0penBmc1", etc.).
    # options     Additional ipmitool command options  (e.g "-L=Operator","-C=3").

    Wait Until Keyword Succeeds  15 sec  5 sec  Run External IPMI Raw Command
    ...  ${IPMI_RAW_CMD['Device GUID']['Get'][0]}  U=${username}  P=${password}  &{options}


Verify Standard Payload
    [Documentation]  Verify standard payload is disabled or enabled.
    [Arguments]  ${user_id}  ${user_name}  ${standard_payload}=Enabled

    # Description of argument(s):
    # user_id            The user ID (e.g. "1", "2", etc.).
    # username           The user name (e.g. "root", "robert", etc.).
    # standard_payload   Enabled or Disabled.

    # Verify the standard payload 1 (sol) is disabled.
    ${get_user_access_payload}=  Get User Access Payload For Given Channel  ${user_id}
    @{get_user_access_cmd_resp_list}=  Split String  ${get_user_access_payload}

    Run Keyword If  '${standard_payload}' == 'Disabled'
    ...  Should Be Equal  ${get_user_access_cmd_resp_list}[0]  00
    ...  ELSE
    ...  Should Be Equal  ${get_user_access_cmd_resp_list}[0]  02

    Run Keyword If  '${standard_payload}' == 'Disabled'
    ...  Verify Sol Activate Disabled  ${user_name}


Verify Sol Activate Disabled
    [Documentation]  Verify SOL activate IPMI command is not working.
    [Arguments]  ${user_name}

    # Description of argument(s):
    # username    The user name (e.g. "root", "robert", etc.).

    ${resp}=  Run External IPMI Standard Command
    ...  sol activate  expected_rc=${1}  U=${username}  P=${new_user_passwd}

    Should Contain  ${resp}  SOL payload disabled


Set User Access Payload For Given User
    [Documentation]  Set the user access payload on given user, channel and return response.
    [Arguments]  ${user_id}  ${operation_mode}=Enable  ${oempayload_value}=0x00
    ...          ${standard_payload_value}=0x02

    # Description of argument(s):
    # user_id                  The user ID (e.g. "1", "2", etc.).
    # operation_mode          Enable or Disable payload type.
    # oempayload_value        Oempayload in hex (e.g. "0x00", "0x01", "0x02", "0x04" etc).
    # standard_payload_value  Standard payload type IPMI or SOL.
    #                         (e.g.  0x01 - IPMI, 0x02- SOL).

    # If operation mode is disable 2nd byte of raw command is 4${user_id}.
    # (e.g) 2n byte will be 0x4a (if user_id is a).
    # If operation mode is enable 2nd byte of raw command is 0${user_id}.
    # (e.g.) 3rd byte will be 0x0a (if user_id is a).
    # 0x02- standard payload for SOL, 0x01 standard payload for IPMI.
    # 3rd byte represent standard payload enables 1 (SOL).
    # 4th to 6th byte represent standard payload enables 2 and OEM payload 1 & 2 respectively.

    ${operation_mode_value}=  Set Variable If  '${operation_mode}' == 'Enable'
    ...  0  4
    ${set_cmd}=  Catenate  ${IPMI_RAW_CMD['Payload']['Set_User_Access_Payload'][0]}
    ...  ${CHANNEL_NUMBER} 0x${operation_mode_value}${user_id} ${standard_payload_value} 0x00 ${oempayload_value} 0x00

    ${resp}=  Run IPMI Command  ${set_cmd}

    [Return]  ${resp}


Get Invalid User ID
    [Documentation]  Get random invalid user ID using "channel getaccess" IPMI standard command.

    # Python module:  get_user_info(userid, channel_number=1)
    ${user_info}=  Get User Info  ${EMPTY}  ${CHANNEL_NUMBER}
    ${user_info}=  Filter Struct  ${user_info}  [('user_name', None)]  invert=1
    ${empty_user_info}=  Filter Struct  ${user_info}  [('user_name', '')]
    @{invalid_userid_list}=  Create List
    FOR  ${user_record}  IN  @{empty_user_info}
        Append To List  ${invalid_userid_list}  ${user_record['user_id']}
    END
    ${invalid_user_id}=  Evaluate  random.choice(${invalid_userid_list})  random

    [Return]  ${invalid_user_id}


Verify Set User Access Payload For Invalid Channel
    [Documentation]  Verify set user payload command for invalid channels.
    [Arguments]  ${user_id}  ${channel_number}

    # Description of argument(s):
    # user_id           The user ID (e.g. "1", "2", etc.).
    # channel_number    Input channel number.

    ${channel_number}=  Convert To Hex  ${channel_number}  prefix=0x
    ${user_id}=  Convert To Hex  ${user_id}  prefix=0x
    ${raw_cmd}=  Catenate   ${IPMI_RAW_CMD['Payload']['Set_User_Access_Payload'][0]}
    ...  ${channel_number} ${user_id} 0x02 0x00 0x00 0x00

    Verify Invalid IPMI Command  ${raw_cmd}  0xcc


Verify Get User Access Payload For Invalid User Or Channel
    [Documentation]  Verify get user payload command for invalid userid or invalid channels.
    [Arguments]  ${user_id}  ${channel_number}

    # Description of argument(s):
    # user_id           The user ID (e.g. "1", "2", etc.).
    # channel_number    Input channel number.

    ${channel_number}=  Convert To Hex  ${channel_number}  prefix=0x
    ${user_id}=  Convert To Hex  ${user_id}  prefix=0x
    ${raw_cmd}=  Catenate  ${IPMI_RAW_CMD['Payload']['Get_User_Access_Payload'][0]}
    ...  ${channel_number} ${user_id}

    Verify Invalid IPMI Command  ${raw_cmd}  0xcc


Verify Payload Type Version
    [Documentation]  Verify supported payload version.
    [Arguments]  ${channel_number}  &{payload_type_dict}

    # Description of argument(s):
    # channel_number     Input channel number.
    # payload_type_dict  Supported payload type in dictionary type.
    #                    standard_payload_types and session_setup_payload_types which we use
    #                    in this keyword are defined in variable section.

    FOR  ${payload_type_name}  ${payload_type_number}  IN  &{payload_type_dict}
        ${get_cmd}=  Catenate  ${IPMI_RAW_CMD['Payload']['Get_Channel_Payload_Version'][0]}
        ...  ${channel_number} ${payload_type_number}

        ${resp}=  Run External IPMI Raw Command  ${get_cmd}
        ${resp}=  Strip String  ${resp}
        Should Be Equal  ${resp}  10
    END


Verify Payload Version For Invalid Channel
    [Documentation]  Verify payload version for invalid channel.
    [Arguments]  ${channel_number}  &{payload_type_dict}

    # Description of argument(s):
    # channel_number     Input channel number.
    # payload_type_dict  Supported payload type in dictionary type.
    #                    standard_payload_types and session_setup_payload_types which we use
    #                    in this keyword are defined in variable section.

     ${channel_number}=  Convert To Hex  ${channel_number}  prefix=0x
     FOR  ${payload_type_name}  ${payload_type_number}  IN  &{payload_type_dict}
        ${get_cmd}=  Catenate  ${IPMI_RAW_CMD['Payload']['Get_Channel_Payload_Version'][0]}
        ...  ${channel_number} ${payload_type_number}

        Verify Invalid IPMI Command  ${get_cmd}  0xcc
     END


Verify Payload Version
    [Documentation]  Verify supported payload version on given channel number.
    [Arguments]  ${channel_number}

    # Description of argument(s):
    # channel_number     Input channel number.

    Verify Payload Type Version  ${channel_number}  &{standard_payload_types}
    Verify Payload Type Version  ${channel_number}  &{session_setup_payload_types}


Verify Payload Support
    [Documentation]  Verify payload support on given channel number.
    [Arguments]  ${channel_number}  ${invalid_channel}=${0}

    # Description of argument(s):
    # channel_number     Input channel number.
    # invalid_channel    This argument indicates whether we checking payload support command
    #                    for Invalid channel or not.
    #                    (e.g. 1 indicates checking for invalid channel, 0 indicates valid channel).

    ${channel_number}=  Convert To Hex  ${channel_number}  prefix=0x
    ${raw_cmd}=  Catenate  ${IPMI_RAW_CMD['Payload']['Get_Channel_Payload_Support'][0]}  ${channel_number}

    Run Keyword And Return If  '${invalid_channel}' == '${1}'
    ...  Verify Invalid IPMI Command  ${raw_cmd}  0xcc

    # will be executed only if invalid_channel == 0.
    ${resp}=  Run External IPMI Raw Command  ${raw_cmd}

    ${resp}=  Strip String  ${resp}
    ${expected_resp}=  Catenate  ${standard_payload_type_resp}  ${session_setup_payload_resp} 00 00 00 00
    Should Be Equal  ${expected_resp}  ${resp}
