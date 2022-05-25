*** Settings ***
Documentation       This suite tests IPMI Payload in OpenBMC.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/bmc_network_utils.robot
Variables           ../data/ipmi_raw_cmd_table.py
Library             ../lib/ipmi_utils.py


*** Variables ***
${user_priv}                    2
${operator_priv}                3
${admin_level_priv}             4
${no_access_priv}               15
${newuser_Password}             0penBmc1


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
    [Documentation]  Disable Standard payload for SOL and Verify sol activate IPMI command is not working.
    [Tags]  Verify_Set_User_Access_Payload_For_Standard_Payload_SOL
    [Teardown]  Run Keywords  Set User Access Payload For Given User  ${user_id_in_hex}
    ...  AND  Delete Created User  ${userid}

    ${userid}  ${username}=  Create IPMI User
    ${user_id_in_hex}=  Convert To Hex  ${user_id}
    ${user_id_in_hex_with_prefix}=  Convert To Hex  ${user_id}  prefix=0x  length=2

    # Get default user access payload values.
    ${default_user_access_payload}=  Get User Access Payload For Given Channel  ${user_id_in_hex_with_prefix}

    # Disable Standard payload 1 via set user access payload command.
    Set User Access Payload For Given User  ${user_id_in_hex}  Disable

    Verify Standard Payload  ${user_id_in_hex_with_prefix}  ${username}  Disabled


Verify Set User Access Payload For Operator Privileged User
    [Documentation]  Try to set user access payload using operator privileged user and expect error.
    [Tags]  Verify_Set_User_Access_Payload_For_Operator_Privileged_User
    [Teardown]  Delete Created User  ${userid}

    ${userid}  ${username}=  Create IPMI User  ${operator_priv}  Operator

    ${payload_raw_cmd}=  Catenate  ${IPMI_RAW_CMD['Payload']['Set_User_Access_Payload'][0]}
    ...  ${CHANNEL_NUMBER} 0x${user_id} 0x02 0x00 0x00 0x00

    Run Keyword and Expect Error  *Unable to establish IPMI*
    ...  Run External IPMI Raw Command  ${payload_raw_cmd}  U=${userid}  P=${newuser_Password}  L=Operator


*** Keywords ***

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

    ${raw_command}=  Catenate  ${IPMI_RAW_CMD['Payload']['Get_User_Access_Payload'][0]} ${channel_number} ${user_id}
    ${resp}=  Run External IPMI Raw Command  ${raw_command}
    [Return]  ${resp}


Create IPMI User
    [Documentation]  Create IMPI User, set password, set  privilege and enable the user.
    [Arguments]  ${user_privilege_level}=${admin_level_priv}   ${privilege}=Administrator

    # Description of argument(s):
    # user_privilege_level   User Privelege level in integer.
    #                        (e.g. 4-Administator, 3-Operator, 2-Readonly).
    # privilege              User Privelege in Wordings.
    #                        (e.g. "Administrator", "Operator", "ReadOnly").

    ${random_user_id}  ${random_user_name}=  Create Random IPMI User
    Set User Password  ${random_user_id}  ${newuser_Password}  16
    Set User Access Privilege  ${random_user_id}  ${user_privilege_level}
    Verify Username And Password  ${random_user_name}  ${newuser_Password}  L=${privilege}

    [Return]  ${random_user_id}  ${random_user_name}


Set User Password
    [Documentation]  Set user password for given user ID.
    [Arguments]  ${user_id}  ${password}  ${password_option}

    # Description of argument(s):
    # user_id          The user ID (e.g. "1", "2", etc.).
    # password         The user password (e.g. "0penBmc", "0penBmc1", etc.).
    # password_option  Password length option to be given in IPMI command (e.g. "16", "20").

    Run IPMI Standard Command  user set password ${user_id} ${password} ${password_option}

Set User Access Privilege
    [Documentation]  Set user access privilege for given user ID.
    [Arguments]  ${user_id}  ${privilege_level}

    # Description of argument(s):
    # user_id           The user ID (e.g. "1", "2", etc.).
    # privelege_level   User Privelege level in hex value.
    #                   (e.g. 4-Administator, 3-Operator, 2-Readonly).

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

    ${output}=  Wait Until Keyword Succeeds  15 sec  5 sec  Run External IPMI Raw Command
    ...  ${IPMI_RAW_CMD['Device GUID']['Get'][0]}  U=${username}  P=${password}  &{options}


Verify Standard Payload
    [Documentation]  Verify standard payload disabled or enabled.
    [Arguments]  ${user_id}  ${user_name}  ${standard_payload}=Enabled

    # Description of argument(s):
    # userid      The user ID (e.g. "1", "2", etc.).
    # username    The user name (e.g. "root", "robert", etc.).

    # Verify the standard payload 1 (sol) is disabled.
    ${get_user_access_payload}=  Get User Access Payload For Given Channel  ${user_id}
    @{get_user_access_cmd_resp_list}=  Split String  ${get_user_access_payload}

    Run Keyword If  '${standard_payload}' == 'Disabled'
    ...  Should Be Equal  ${get_user_access_cmd_resp_list}[0]  00
    ...  ELSE
    ...  Should Be Equal  ${get_user_access_cmd_resp_list}[0]  02

    Run Keyword If  '${standard_payload}' == 'Disabled'
    ...  Verify sol activate not working  ${user_name}


Verify Sol Activate Not Working
    [Documentation]  Verify SOL activate IPMI command is not working.
    [Arguments]  ${user_name}

    # Description of argument(s):
    # username    The user name (e.g. "root", "robert", etc.).

    ${resp}=  Run External IPMI Standard Command
    ...  sol activate  expected_rc=${1}  U=${username}  P=${newuser_Password}

    Should Contain  ${resp}  SOL payload disabled


Set User Access Payload For Given User
    [Documentation]  Set the user access payload on given user and channel.
    [Arguments]  ${user_id}  ${operation_mode}=Enable  ${oempayload_value}=0x00  ${standard_payload_value}=0x02

    # Description of argument(s):
    # userid                  The user ID (e.g. "1", "2", etc.).
    # operation_mode          Enable or Disable payload type.
    # oempayload_value        Oempayload in hex (e.g. "0x00", "0x01", "0x02", "0x04" etc).
    # standard_payload_value  Standard paylaad type IPMI or SOL.
    #                         (e.g.  0x01 - IPMI, 0x02- SOL).

    ## If Operation is disable 2nd byte of raw command as 4${user_id}.
    ## If Operation mode is enable 2nd byte of raw command as 0${user_id}.
    ## 3rd byte represent standard payload enables 1 (SOL).
    ## 4th to 6th byte represent standard payload enables 2 and OEM payload 1 & 2 repectively.

    ${operation_mode_value}=  Set Variable If  '${operation_mode}' == 'Enable'
    ...  0  4
    ${set_cmd}=  Catenate  ${IPMI_RAW_CMD['Payload']['Set_User_Access_Payload'][0]}
    ...  ${CHANNEL_NUMBER} 0x${operation_mode_value}${user_id} ${standard_payload_value} 0x00 ${oempayload_value} 0x00

    ${resp}=  Run IPMI Command  ${set_cmd}

    [Return]  ${resp}