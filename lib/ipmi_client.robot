*** Settings ***
Documentation   This module is for IPMI client for copying ipmitool to
...             openbmc box and execute ipmitool IPMI standard
...             command. IPMI raw command will use dbus-send command
Resource        ../lib/resource.robot
Resource        ../lib/connection_client.robot
Resource        ../lib/utils.robot
Resource        ../lib/state_manager.robot

Library         String
Library         var_funcs.py
Library         ipmi_client.py
Library         ../lib/bmc_ssh_utils.py

*** Variables ***
${dbusHostIpmicmd1}=   dbus-send --system  ${OPENBMC_BASE_URI}HostIpmi/1
${dbusHostIpmiCmdReceivedMsg}=   ${OPENBMC_BASE_DBUS}.HostIpmi.ReceivedMessage
${netfnByte}=          ${EMPTY}
${cmdByte}=            ${EMPTY}
${arrayByte}=          array:byte:
${IPMI_USER_OPTIONS}   ${EMPTY}
${IPMI_INBAND_CMD}=    ipmitool -C ${IPMI_CIPHER_LEVEL} -N ${IPMI_TIMEOUT} -p ${IPMI_PORT}
${HOST}=               -H
${RAW}=                raw
${IPMITOOL_PATH}       /tmp/ipmitool
${expected_max_ids}    15
${empty_name_pattern}  ^User Name\\s.*\\s:\\s$

*** Keywords ***

Run IPMI Command
    [Documentation]  Run the raw IPMI command.
    [Arguments]  ${command}  ${fail_on_err}=${1}  &{options}

    # Description of argument(s):
    # command                       The IPMI command string to be executed
    #                               (e.g. "power status").
    # fail_on_err                   Fail if the IPMI command execution fails.
    # options                       Additional ipmitool command options (e.g.
    #                               -C=3, -I=lanplus, etc.).  Currently, only
    #                               used for external IPMI commands.

    ${resp}=  Run Keyword If  '${IPMI_COMMAND}' == 'External'
    ...    Run External IPMI Raw Command  ${command}  ${fail_on_err}  &{options}
    ...  ELSE IF  '${IPMI_COMMAND}' == 'Inband'
    ...    Run Inband IPMI Raw Command  ${command}
    ...  ELSE IF  '${IPMI_COMMAND}' == 'Dbus'
    ...    Run Dbus IPMI RAW Command  ${command}
    ...  ELSE  Fail  msg=Invalid IPMI Command type provided: ${IPMI_COMMAND}
    RETURN  ${resp}


Run IPMI Standard Command
    [Documentation]  Run the standard IPMI command.
    [Arguments]  ${command}  ${fail_on_err}=${1}  ${expected_rc}=${0}  &{options}

    # Description of argument(s):
    # command                       The IPMI command string to be executed
    #                               (e.g. "0x06 0x36").
    # fail_on_err                   Fail if the IPMI command execution fails.
    # expected_rc                   The expected return code from the ipmi
    #                               command (e.g. ${0}, ${1}, etc.).
    # options                       Additional ipmitool command options (e.g.
    #                               -C=3, -I=lanplus, etc.).  Currently, only
    #                               used for external IPMI commands.

    ${resp}=  Run Keyword If  '${IPMI_COMMAND}' == 'External'
    ...    Run External IPMI Standard Command  ${command}  ${fail_on_err}  ${expected_rc}  &{options}
    ...  ELSE IF  '${IPMI_COMMAND}' == 'Inband'
    ...    Run Inband IPMI Standard Command  ${command}  ${fail_on_err}
    ...  ELSE IF  '${IPMI_COMMAND}' == 'Dbus'
    ...    Run Dbus IPMI Standard Command  ${command}
    ...  ELSE  Fail  msg=Invalid IPMI Command type provided : ${IPMI_COMMAND}
    RETURN  ${resp}


Run Dbus IPMI RAW Command
    [Documentation]  Run the raw IPMI command through dbus.
    [Arguments]    ${command}
    ${valueinBytes}=   Byte Conversion  ${command}
    ${cmd}=   Catenate   ${dbushostipmicmd1} ${dbusHostIpmiCmdReceivedMsg}
    ${cmd}=   Catenate   ${cmd} ${valueinBytes}
    ${output}   ${stderr}=  Execute Command  ${cmd}  return_stderr=True
    Should Be Empty      ${stderr}
    set test variable    ${OUTPUT}     "${output}"


Run Dbus IPMI Standard Command
    [Documentation]  Run the standard IPMI command through dbus.
    [Arguments]    ${command}
    Copy ipmitool
    ${stdout}    ${stderr}    ${output}=  Execute Command
    ...    ${IPMITOOL_PATH} -I dbus ${command}    return_stdout=True
    ...    return_stderr= True    return_rc=True
    Should Be Equal    ${output}    ${0}    msg=${stderr}
    RETURN    ${stdout}


Run Inband IPMI Raw Command
    [Documentation]  Run the raw IPMI command in-band.
    [Arguments]  ${command}  ${fail_on_err}=${1}  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}

    # Description of argument(s):
    # command                       The IPMI command string to be executed
    #                               (e.g. "0x06 0x36").
    # os_host                       The host name or IP address of the OS Host.
    # os_username                   The OS host user name.
    # os_password                   The OS host passwrd.

    Login To OS Host  ${os_host}  ${os_username}  ${os_password}
    Check If IPMI Tool Exist

    ${ipmi_cmd}=  Catenate  ${IPMI_INBAND_CMD}  ${RAW}  ${command}
    Qprint Issuing  ${ipmi_cmd}
    ${stdout}  ${stderr}=  Execute Command  ${ipmi_cmd}  return_stderr=True
    Return From Keyword If  ${fail_on_err} == ${0}  ${stderr}
    Should Be Empty  ${stderr}  msg=${stdout}
    RETURN  ${stdout}


Run Inband IPMI Standard Command
    [Documentation]  Run the standard IPMI command in-band.
    [Arguments]  ${command}  ${fail_on_err}=${1}  ${os_host}=${OS_HOST}
    ...          ${os_username}=${OS_USERNAME}  ${os_password}=${OS_PASSWORD}
    ...          ${login_host}=${1}

    # Description of argument(s):
    # command                       The IPMI command string to be executed
    #                               (e.g. "power status").
    # os_host                       The host name or IP address of the OS Host.
    # os_username                   The OS host user name.
    # os_password                   The OS host passwrd.
    # login_host                    Indicates that this keyword should login to host OS.

    Run Keyword If  ${login_host} == ${1}
    ...  Login To OS Host  ${os_host}  ${os_username}  ${os_password}
    Check If IPMI Tool Exist

    ${ipmi_cmd}=  Catenate  ${IPMI_INBAND_CMD}  ${command}
    Qprint Issuing  ${ipmi_cmd}
    ${stdout}  ${stderr}=  Execute Command  ${ipmi_cmd}  return_stderr=True
    Return From Keyword If  ${fail_on_err} == ${0}  ${stderr}
    Should Be Empty  ${stderr}  msg=${stdout}
    RETURN  ${stdout}


Run External IPMI Standard Command
    [Documentation]  Run the external IPMI standard command.
    [Arguments]  ${command}  ${fail_on_err}=${1}  ${expected_rc}=${0}  &{options}

    # Description of argument(s):
    # command                       The IPMI command string to be executed
    #                               (e.g. "power status").  Note that if
    #                               ${IPMI_USER_OPTIONS} has a value (e.g.
    #                               "-vvv"), it will be pre-pended to this
    #                               command string.
    # fail_on_err                   Fail if the IPMI command execution fails.
    # expected_rc                   The expected return code from the ipmi
    #                               command (e.g. ${0}, ${1}, etc.).
    # options                       Additional ipmitool command options (e.g.
    #                               -C=3, -I=lanplus, etc.).

    ${command_string}=  Process IPMI User Options  ${command}
    ${ipmi_cmd}=  Create IPMI Ext Command String  ${command_string}  &{options}
    Qprint Issuing  ${ipmi_cmd}
    ${rc}  ${output}=  Run And Return RC and Output  ${ipmi_cmd}
    Return From Keyword If  ${fail_on_err} == ${0}  ${output}
    Should Be Equal  ${rc}  ${expected_rc}  msg=${output}
    RETURN  ${output}


Run External IPMI Raw Command
    [Documentation]  Run the external IPMI raw command.
    [Arguments]  ${command}  ${fail_on_err}=${1}  &{options}

    # This keyword is a wrapper for 'Run External IPMI Standard Command'. See
    # that keyword's prolog for argument details.  This keyword will pre-pend
    # the word "raw" plus a space to command prior to calling 'Run External
    # IPMI Standard Command'.

    ${output}=  Run External IPMI Standard Command
    ...  raw ${command}  ${fail_on_err}  &{options}
    RETURN  ${output}


Check If IPMI Tool Exist
    [Documentation]  Check if IPMI Tool installed or not.
    ${output}=  Execute Command  which ipmitool
    Should Not Be Empty  ${output}  msg=ipmitool not installed.


Activate SOL Via IPMI
    [Documentation]  Start SOL using IPMI and route output to a file.
    [Arguments]  ${file_path}=${IPMI_SOL_LOG_FILE}

    # Description of argument(s):
    # file_path                     The file path on the local machine (vs.
    #                               OBMC) to collect SOL output. By default
    #                               SOL output is collected at
    #                               logs/sol_<BMC_IP> else user input location.

    ${ipmi_cmd}=  Create IPMI Ext Command String  sol activate usesolkeepalive
    Qprint Issuing  ${ipmi_cmd}
    Start Process  ${ipmi_cmd}  shell=True  stdout=${file_path}
    ...  alias=sol_proc


Deactivate SOL Via IPMI
    [Documentation]  Stop SOL using IPMI and return SOL output.
    [Arguments]  ${file_path}=${IPMI_SOL_LOG_FILE}

    # Description of argument(s):
    # file_path                     The file path on the local machine to copy
    #                               SOL output collected by above "Activate
    #                               SOL Via IPMI" keyword.  By default it
    #                               copies log from logs/sol_<BMC_IP>.

    ${ipmi_cmd}=  Create IPMI Ext Command String  sol deactivate
    Qprint Issuing  ${ipmi_cmd}
    ${rc}  ${output}=  Run and Return RC and Output  ${ipmi_cmd}
    Run Keyword If  ${rc} > 0  Run Keywords
    ...  Run Keyword And Ignore Error  Terminate Process  sol_proc
    ...  AND  Return From Keyword  ${output}

    ${output}=  OperatingSystem.Get File  ${file_path}  encoding_errors=ignore

    # Logging SOL output for debug purpose.
    Log  ${output}

    RETURN  ${output}


Byte Conversion
    [Documentation]   Byte Conversion method receives IPMI RAW commands as
    ...               argument in string format.
    ...               Sample argument is as follows
    ...               "0x04 0x30 9 0x01 0x00 0x35 0x00 0x00 0x00 0x00 0x00
    ...               0x00"
    ...               IPMI RAW command format is as follows
    ...               <netfn Byte> <cmd Byte> <Data Bytes..>
    ...               This method converts IPMI command format into
    ...               dbus command format  as follows
    ...               <byte:seq-id> <byte:netfn> <byte:lun> <byte:cmd>
    ...               <array:byte:data>
    ...               Sample dbus  Host IPMI Received Message argument
    ...               byte:0x00 byte:0x04 byte:0x00 byte:0x30
    ...               array:byte:9,0x01,0x00,0x35,0x00,0x00,0x00,0x00,0x00,0x00
    [Arguments]     ${args}
    ${argLength}=   Get Length  ${args}
    Set Global Variable  ${arrayByte}   array:byte:
    @{listargs}=   Split String  ${args}
    ${index}=   Set Variable   ${0}
    FOR  ${word}  IN  @{listargs}
         Run Keyword if   ${index} == 0   Set NetFn Byte  ${word}
         Run Keyword if   ${index} == 1   Set Cmd Byte    ${word}
         Run Keyword if   ${index} > 1    Set Array Byte  ${word}
         ${index}=    Set Variable    ${index + 1}
    END
    ${length}=   Get Length  ${arrayByte}
    ${length}=   Evaluate  ${length} - 1
    ${arrayByteLocal}=  Get Substring  ${arrayByte}  0   ${length}
    Set Global Variable  ${arrayByte}   ${arrayByteLocal}
    ${valueinBytesWithArray}=   Catenate  byte:0x00   ${netfnByte}  byte:0x00
    ${valueinBytesWithArray}=   Catenate  ${valueinBytesWithArray}  ${cmdByte}
    ${valueinBytesWithArray}=   Catenate  ${valueinBytesWithArray} ${arrayByte}
    ${valueinBytesWithoutArray}=   Catenate  byte:0x00 ${netfnByte}  byte:0x00
    ${valueinBytesWithoutArray}=   Catenate  ${valueinBytesWithoutArray} ${cmdByte}
    #   To Check scenario for smaller IPMI raw commands with only 2 arguments
    #   instead of usual 12 arguments.
    #   Sample small IPMI raw command: Run IPMI command 0x06 0x36
    #   If IPMI raw argument length is only 9 then return value in bytes without
    #   array population.
    #   Equivalent dbus-send argument for smaller IPMI raw command:
    #   byte:0x00 byte:0x06 byte:0x00 byte:0x36
    Run Keyword if   ${argLength} == 9     Return from Keyword    ${valueinBytesWithoutArray}
    RETURN    ${valueinBytesWithArray}


Set NetFn Byte
    [Documentation]  Set the network function byte.
    [Arguments]    ${word}
    ${netfnByteLocal}=  Catenate   byte:${word}
    Set Global Variable  ${netfnByte}  ${netfnByteLocal}


Set Cmd Byte
    [Documentation]  Set the command byte.
    [Arguments]    ${word}
    ${cmdByteLocal}=  Catenate   byte:${word}
    Set Global Variable  ${cmdByte}  ${cmdByteLocal}


Set Array Byte
    [Documentation]  Set the array byte.
    [Arguments]    ${word}
    ${arrayByteLocal}=   Catenate   SEPARATOR=  ${arrayByte}  ${word}
    ${arrayByteLocal}=   Catenate   SEPARATOR=  ${arrayByteLocal}   ,
    Set Global Variable  ${arrayByte}   ${arrayByteLocal}


Copy ipmitool
    [Documentation]  Copy the ipmitool to the BMC.
    ${ipmitool_error}=  Catenate  The ipmitool program could not be found in the tools directory.
    ...  It is not part of the automation code by default. You must manually copy or link the correct openbmc
    ...  version of the tool in to the tools directory in order to run this test suite.

    ${response}  ${stderr}  ${rc}=  BMC Execute Command
    ...  which ipmitool  ignore_err=${1}
    ${installed}=  Get Regexp Matches  ${response}  ipmitool
    Run Keyword If  ${installed} == ['ipmitool']
    ...  Run Keywords  Set Suite Variable  ${IPMITOOL_PATH}  ${response}
    ...  AND  SSHLibrary.Open Connection     ${OPENBMC_HOST}
    ...  AND  SSHLibrary.Login   ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}
    ...  AND  Return From Keyword

    OperatingSystem.File Should Exist  tools/ipmitool  msg=${ipmitool_error}
    Import Library      SCPLibrary      AS       scp
    scp.Open connection     ${OPENBMC_HOST}     username=${OPENBMC_USERNAME}      password=${OPENBMC_PASSWORD}
    scp.Put File    tools/ipmitool   /tmp
    SSHLibrary.Open Connection     ${OPENBMC_HOST}
    SSHLibrary.Login   ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}
    Execute Command     chmod +x ${IPMITOOL_PATH}


Initiate Host Boot Via External IPMI
    [Documentation]  Initiate host power on using external IPMI.
    [Arguments]  ${wait}=${1}

    # Description of argument(s):
    # wait                          Indicates that this keyword should wait
    #                               for host running state.

    ${output}=  Run External IPMI Standard Command  chassis power on
    Should Not Contain  ${output}  Error

    Run Keyword If  '${wait}' == '${0}'  Return From Keyword
    Wait Until Keyword Succeeds  10 min  10 sec  Is Host Running


Initiate Host PowerOff Via External IPMI
    [Documentation]  Initiate host power off using external IPMI.
    [Arguments]  ${wait}=${1}

    # Description of argument(s):
    # wait                          Indicates that this keyword should wait
    #                               for host off state.

    ${output}=  Run External IPMI Standard Command  chassis power off
    Should Not Contain  ${output}  Error

    Run Keyword If  '${wait}' == '${0}'  Return From Keyword
    Wait Until Keyword Succeeds  3 min  10 sec  Is Host Off


Is Host Off Via IPMI
    [Documentation]  Verify if the Host is off using IPMI command.

    ${status}=  Run External IPMI Standard Command  chassis power status
    Should Contain  ${status}  off


Get Host State Via External IPMI
    [Documentation]  Returns host state using external IPMI.

    ${output}=  Run External IPMI Standard Command  chassis power status
    Should Not Contain  ${output}  Error
    ${output}=  Fetch From Right  ${output}  ${SPACE}

    RETURN  ${output}


Set BMC Network From Host
    [Documentation]  Set BMC network from host.
    [Arguments]  ${nw_info}

    # Description of argument(s):
    # nw_info                       A dictionary containing the network
    #                               information to apply.

    Run Inband IPMI Standard Command
    ...  lan set 1 ipaddr ${nw_info['IP Address']}

    Run Inband IPMI Standard Command
    ...  lan set 1 netmask ${nw_info['Subnet Mask']}

    Run Inband IPMI Standard Command
    ...  lan set 1 defgw ipaddr ${nw_info['Default Gateway IP']}


Verify IPMI Username And Password
    [Documentation]  Verify that user is able to run IPMI command
    ...  with given username and password.
    [Arguments]  ${username}  ${password}

    # Description of argument(s):
    # username    The user name (e.g. "root", "robert", etc.).
    # password    The user password.

    ${output}=  Wait Until Keyword Succeeds  15 sec  5 sec  Run External IPMI Standard Command
    ...  sel info  U=${username}  P=${password}
    Should Contain  ${output}  SEL Information  msg=SEL information not present


IPMI Create User
    [Documentation]  Create IPMI user with given userid and username.
    [Arguments]  ${userid}  ${username}

    # Description of argument(s):
    # userid      The user ID (e.g. "1", "2", etc.).
    # username    The user name (e.g. "root", "robert", etc.).

    ${ipmi_cmd}=  Catenate  user set name ${userid} ${username}
    ${resp}=  Run IPMI Standard Command  ${ipmi_cmd}
    ${user_info}=  Get User Info  ${userid}  ${CHANNEL_NUMBER}
    Should Be Equal  ${user_info['user_name']}  ${username}


Enable IPMI User And Verify
    [Documentation]  Enable the userid and verify that it has been enabled.
    [Arguments]  ${userid}

    # Description of argument(s):
    # userid   A numeric userid (e.g. "4").

    Run IPMI Standard Command  user enable ${userid}
    ${user_info}=  Get User Info  ${userid}  ${CHANNEL_NUMBER}
    Valid Value  user_info['enable_status']  ['enabled']


Create Random IPMI User
    [Documentation]  Create IPMI user with random username and userid and return those fields.

    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Find Free User Id
    IPMI Create User  ${random_userid}  ${random_username}
    Wait And Confirm New User Entry  ${random_username}
    RETURN  ${random_userid}  ${random_username}


Find Free User Id
    [Documentation]  Find a userid that is not being used.

    Check Enabled User Count
    FOR    ${num}    IN RANGE    300
        ${random_userid}=  Evaluate  random.randint(1, ${expected_max_ids})  modules=random
        ${access}=  Run IPMI Standard Command  channel getaccess ${CHANNEL_NUMBER} ${random_userid}

        ${name_line}=  Get Lines Containing String  ${access}  User Name
        Log To Console  For ID ${random_userid}: ${name_line}
        ${is_empty}=  Run Keyword And Return Status
        ...  Should Match Regexp  ${name_line}  ${empty_name_pattern}

        Exit For Loop If  ${is_empty} == ${True}
    END
    RETURN  ${random_userid}


Check Enabled User Count
    [Documentation]  Ensure that there are available user IDs.

    # Check for the enabled user count
    ${resp}=  Run IPMI Standard Command  user summary ${CHANNEL_NUMBER}
    ${enabled_user_count}=
    ...  Get Lines Containing String  ${resp}  Enabled User Count

    Should not contain  ${enabled_user_count}  ${expected_max_ids}
    ...  msg=IPMI has reached maximum user count


Wait And Confirm New User Entry
    [Documentation]  Wait in loop until new user appears with given username.
    [Arguments]  ${username}

    # Description of argument(s):
    # username         The user name (e.g. "root", "robert", etc.).

    Wait Until Keyword Succeeds  45 sec  1 sec  Verify IPMI Username Visible
    ...  ${username}


Verify IPMI Username Visible
    [Documentation]  Confirm that username is present in user list.
    [Arguments]  ${username}

    # Description of argument(s):
    # username         The user name (e.g. "root", "robert", etc.).

    ${resp}=  Run IPMI Standard Command  user list
    Should Contain  ${resp}  ${username}


Delete Created User
    [Documentation]  Delete created IPMI user.
    [Arguments]  ${userid}
    # Description of argument(s):
    # userid  The user ID (e.g. "1", "2", etc.).

    Run IPMI Standard Command  user set name ${userid} ""
    Sleep  5s


Set Channel Access
    [Documentation]  Verify that user is able to run IPMI command
    ...  with given username and password.
    [Arguments]  ${userid}  ${options}  ${channel_number}=${CHANNEL_NUMBER}

    # Description of argument(s):
    # userid          The user ID (e.g. "1", "2", etc.).
    # options         Set channel command options (e.g.
    #                 "link=on", "ipmi=on", etc.).
    # channel_number  The user's channel number (e.g. "1").

    ${ipmi_cmd}=  Catenate  SEPARATOR=
    ...  channel setaccess${SPACE}${channel_number}${SPACE}${userid}
    ...  ${SPACE}${options}
    Run IPMI Standard Command  ${ipmi_cmd}


Delete All Non Root IPMI User
    [Documentation]  Delete all non-root IPMI user.

    # Get complete list of user info records.
    ${user_info}=  Get User Info  ${EMPTY}  ${CHANNEL_NUMBER}
    # Remove header record.
    ${user_info}=  Filter Struct  ${user_info}  [('user_name', None)]  invert=1
    ${non_empty_user_info}=  Filter Struct  ${user_info}  [('user_name', '')]  invert=1
    ${non_root_user_info}=  Filter Struct  ${non_empty_user_info}  [('user_name', 'root')]  invert=1

    FOR  ${user_record}  IN  @{non_root_user_info}
        Run IPMI Standard Command   user set name ${user_record['user_id']} ""
        Sleep  5s
    END


Create SEL
    [Documentation]  Create a SEL.
    [Arguments]  ${sensor_type}  ${sensor_number}

    # Create a SEL.
    # Example:
    # a | 02/14/2020 | 01:16:58 | Sensor_type #0x17 |  | Asserted
    # Description of argument(s):
    #    ${sensor_type}            Type of the sensor used in hexadecimal (can be fan, temp etc.,),
    #                              obtained from Sensor Type field in - ipmitool sdr get "sensor_name".
    #                              Example: Sensor Type (Threshold) : Fan (0x04), here 0xHH is sensor type.

    #    ${sensor_number}          Sensor number of the sensor in hexadecimal.
    #                              obtained from Sensor ID field in - ipmitool sdr get "sensor_name".
    #                              Example: Sensor ID : SENSOR_1 (0xHH), here 0xHH is sensor number.

    ${cmd}=  Catenate  ${IPMI_RAW_CMD['SEL_entry']['Create_SEL'][0]} 0x${GEN_ID_BYTE_1} 0x${GEN_ID_BYTE_2}
    ...  ${IPMI_RAW_CMD['SEL_entry']['Create_SEL'][1]} 0x${sensor_type} 0x${sensor_number}
    ...  ${IPMI_RAW_CMD['SEL_entry']['Create_SEL'][2]}

    ${resp}=  Run IPMI Command  ${cmd}

    Should Not Contain  ${resp}  00 00  msg=SEL not created.

    Sleep  5s

    RETURN  ${resp}


Fetch One Threshold Sensor From Sensor List
    [Documentation]  Fetch one threshold sensor randomly from Sensor list.

    @{sensor_name_list}=  Create List

    ${resp}=  Run IPMI Standard Command  sensor
    @{sensor_list}=  Split To Lines  ${resp}

    # Omit the discrete sensor and create an threshold sensor name list
    FOR  ${sensor}  IN  @{sensor_list}
      ${discrete_sensor_status}=  Run Keyword And Return Status  Should Contain  ${sensor}  discrete
      Continue For Loop If  '${discrete_sensor_status}' == 'True'
      ${sensor_details}=  Split String  ${sensor}  |
      ${get_sensor_name}=  Get From List  ${sensor_details}  0
      ${sensor_name}=  Set Variable  ${get_sensor_name.strip()}
      Append To List  ${sensor_name_list}  ${sensor_name}
    END

    ${random_sensor_name}=  Evaluate  random.choice(${sensor_name_list})  random

    RETURN  ${random_sensor_name}

Fetch Sensor Details From SDR
    [Documentation]  Identify the sensors from sdr get and fetch sensor details required.
    [Arguments]  ${sensor_name}  ${setting}

    # Description of argument(s):
    #    ${sensor_number}        Sensor number of the sensor in hexadecimal.
    #                            obtained sensor name from - 'ipmitool sensor' command.
    #                            Example: a | 02/14/2020 | 01:16:58 | Sensor_type #0x17 |  | Asserted
    #                            here, a is the sensor name.

    #    ${setting}              Field to fetch data. Example : Sensor ID, Sensor Type (Threshold), etc,.

    ${resp}=  Run IPMI Standard Command  sdr get "${sensor_name}"

    ${setting_line}=  Get Lines Containing String  ${resp}  ${setting}
    ...  case-insensitive
    ${setting_status}=  Fetch From Right  ${setting_line}  :${SPACE}

    RETURN  ${setting_status}


Get Bytes From SDR Sensor
    [Documentation]  Fetch the Field Data and hexadecimal values from given details.
    [Arguments]  ${sensor_detail}

    # Description of argument(s):
    #    ${sensor_detail}      Requested field and the value from the sdr get ipmi command.
    #                          Example : if Sensor ID is the requesting setting, then,
    #                          ${sensor_detail} will be "Sensor ID : SENSOR_1 (0xHH)"

    ${sensor_detail}=  Split String  ${sensor_detail}  (0x
    ${sensor_hex}=  Replace String  ${sensor_detail[1]}  )  ${EMPTY}
    ${sensor_hex}=  Zfill Data  ${sensor_hex}  2

    RETURN  ${sensor_hex}


Get Current Date from BMC
    [Documentation]  Runs the date command from BMC and returns current date and time
    [Arguments]  ${date_format}=%m/%d/%Y %H:%M:%S

    # Description of argument(s):
    # date_format    Date format of the result. E.g. %Y-%m-%d %H:%M:%S etc.

    # Get Current Date from BMC
    ${date}  ${stderr}  ${rc}=  BMC Execute Command   date

    # Split the string and remove first and 2nd last value from the list and join to form %d %b %H:%M:%S %Y date format
    ${date}=  Split String  ${date}
    Remove From List  ${date}  0
    Remove From List  ${date}  -2
    ${date}=  Evaluate  " ".join(${date})

    # Convert the date to specified format, default:%m/%d/%Y %H:%M:%S
    ${date}=  Convert Date  ${date}  date_format=%b %d %H:%M:%S %Y  result_format=${date_format}  exclude_millis=True

    RETURN   ${date}


Get SEL Info Via IPMI
    [Documentation]  Get the SEL Info via IPMI raw command

    # Get SEL Info response consist of 14 bytes of hexadecimal data.

    # Byte 1 - SEL Version,
    # Byte 2 & 3 - Entry bytes - LSB MSB,
    # Byte 4 & 5 - Free Space in bytes, LS Byte first.
    # Byte 6 - 9 - Most recent addition timestamp,
    # Byte 10-13 - Most recent erase timestamp,
    # Byte 14 - Operation Support

    # Example: ${resp} will be "51 XX XX XX XX ff ff ff ff ff ff ff ff XX"

    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['SEL_entry']['SEL_info'][0]}
    ${resp}=  Split String  ${resp}

    RETURN  ${resp}


Verify Invalid IPMI Command
    [Documentation]  Execute invalid IPMI command and verify with given response code.
    [Arguments]  ${ipmi_cmd}  ${error_code}=0xc9

    #  Description Of Arguments.
    #  ${ipmi_cmd}   - IPMI raw cmd with invalid data length.
    #  ${error_code} - Expected error code e.g 0xc7, 0xcc.

    ${resp}=  Run IPMI Command  ${ipmi_cmd}  fail_on_err=0

    Should Contain  ${resp}  rsp=${error_code}


Identify Request Data
    [Documentation]  Convert text from variable declared to request data.
    [Arguments]  ${string}

    # Convert string to hexadecimal data for each character.
    # Return the hex data with prefix of 0x as string and list of hex data.
    # Description of argument(s):
    #    string             Any string to be converted to hex.

    # Given a string, convert to hexadecimal and prefix with 0x
    ${hex1}=  Create List
    ${hex2}=  Create List
    ${resp_data}=  Split String With Index  ${string}  1
    FOR  ${data}  IN  @{resp_data}
        # prefixes 0x by default
        ${hex_value}=  Evaluate  hex(ord("${data}"))
        # prefixes string with bytes prefixed 0x by default
        Append To List  ${hex1}  ${hex_value}
        # provides only hexadecimal bytes
        ${hex}=  Evaluate  hex(ord("${data}"))[2:]
        # provides string with only hexadecimal bytes
        Append To List  ${hex2}  ${hex}
    END
    ${hex1}=  Evaluate  " ".join(${hex1})

    # ${hex1} will contains the data to write for fru in list.
    # ${hex2} will contains the data to verify fru after write operation completed.

    RETURN  ${hex1}  ${hex2}
