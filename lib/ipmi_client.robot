*** Settings ***
Documentation   This module is for IPMI client for copying ipmitool to
...             openbmc box and execute ipmitool IPMI standard
...             command. IPMI raw command will use dbus-send command
Resource        ../lib/resource.robot
Resource        ../lib/connection_client.robot
Resource        ../lib/utils.robot
Resource        ../lib/state_manager.robot

Library         String
Library         ipmi_client.py

*** Variables ***
${dbusHostIpmicmd1}=   dbus-send --system  ${OPENBMC_BASE_URI}HostIpmi/1
${dbusHostIpmiCmdReceivedMsg}=   ${OPENBMC_BASE_DBUS}.HostIpmi.ReceivedMessage
${netfnByte}=          ${EMPTY}
${cmdByte}=            ${EMPTY}
${arrayByte}=          array:byte:
${IPMI_USER_OPTIONS}   ${EMPTY}
${IPMI_INBAND_CMD}=    ipmitool -C ${IPMI_CIPHER_LEVEL}
${HOST}=               -H
${RAW}=                raw

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
    [Return]  ${resp}


Run IPMI Standard Command
    [Documentation]  Run the standard IPMI command.
    [Arguments]  ${command}  ${fail_on_err}=${1}  &{options}

    # Description of argument(s):
    # command                       The IPMI command string to be executed
    #                               (e.g. "0x06 0x36").
    # fail_on_err                   Fail if the IPMI command execution fails.
    # options                       Additional ipmitool command options (e.g.
    #                               -C=3, -I=lanplus, etc.).  Currently, only
    #                               used for external IPMI commands.

    ${resp}=  Run Keyword If  '${IPMI_COMMAND}' == 'External'
    ...    Run External IPMI Standard Command  ${command}  ${fail_on_err}  &{options}
    ...  ELSE IF  '${IPMI_COMMAND}' == 'Inband'
    ...    Run Inband IPMI Standard Command  ${command}  ${fail_on_err}
    ...  ELSE IF  '${IPMI_COMMAND}' == 'Dbus'
    ...    Run Dbus IPMI Standard Command  ${command}
    ...  ELSE  Fail  msg=Invalid IPMI Command type provided : ${IPMI_COMMAND}

    [Return]  ${resp}


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
    ...    /tmp/ipmitool -I dbus ${command}    return_stdout=True
    ...    return_stderr= True    return_rc=True
    Should Be Equal    ${output}    ${0}    msg=${stderr}
    [Return]    ${stdout}


Run Inband IPMI Raw Command
    [Documentation]  Run the raw IPMI command in-band.
    [Arguments]  ${command}  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
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
    Should Be Empty  ${stderr}  msg=${stdout}
    [Return]  ${stdout}


Run Inband IPMI Standard Command
    [Documentation]  Run the standard IPMI command in-band.
    [Arguments]  ${command}  ${fail_on_err}=${1}  ${os_host}=${OS_HOST}
    ...          ${os_username}=${OS_USERNAME}  ${os_password}=${OS_PASSWORD}

    # Description of argument(s):
    # command                       The IPMI command string to be executed
    #                               (e.g. "power status").
    # os_host                       The host name or IP address of the OS Host.
    # os_username                   The OS host user name.
    # os_password                   The OS host passwrd.

    Login To OS Host  ${os_host}  ${os_username}  ${os_password}
    Check If IPMI Tool Exist

    ${ipmi_cmd}=  Catenate  ${IPMI_INBAND_CMD}  ${command}
    Qprint Issuing  ${ipmi_cmd}
    ${stdout}  ${stderr}=  Execute Command  ${ipmi_cmd}  return_stderr=True
    Return From Keyword If  ${fail_on_err} == ${0}  ${stderr}
    Should Be Empty  ${stderr}  msg=${stdout}
    [Return]  ${stdout}


Run External IPMI Standard Command
    [Documentation]  Run the external IPMI standard command.
    [Arguments]  ${command}  ${fail_on_err}=${1}  &{options}

    # Description of argument(s):
    # command                       The IPMI command string to be executed
    #                               (e.g. "power status").  Note that if
    #                               ${IPMI_USER_OPTIONS} has a value (e.g.
    #                               "-vvv"), it will be pre-pended to this
    #                               command string.
    # fail_on_err                   Fail if the IPMI command execution fails.
    # options                       Additional ipmitool command options (e.g.
    #                               -C=3, -I=lanplus, etc.).

    ${command_string}=  Process IPMI User Options  ${command}
    ${ipmi_cmd}=  Create IPMI Ext Command String  ${command_string}  &{options}
    Qprint Issuing  ${ipmi_cmd}
    ${rc}  ${output}=  Run And Return RC and Output  ${ipmi_cmd}
    Return From Keyword If  ${fail_on_err} == ${0}  ${output}
    Should Be Equal  ${rc}  ${0}  msg=${output}
    [Return]  ${output}


Run External IPMI Raw Command
    [Documentation]  Run the external IPMI raw command.
    [Arguments]  ${command}  ${fail_on_err}=${1}  &{options}

    # This keyword is a wrapper for 'Run External IPMI Standard Command'. See
    # that keyword's prolog for argument details.  This keyword will pre-pend
    # the word "raw" plus a space to command prior to calling 'Run External
    # IPMI Standard Command'.

    ${output}=  Run External IPMI Standard Command
    ...  raw ${command}  ${fail_on_err}  &{options}
    [Return]  ${output}


Check If IPMI Tool Exist
    [Documentation]  Check if IPMI Tool installed or not.
    ${output}=  Execute Command  which ipmitool
    Should Not Be Empty  ${output}  msg=ipmitool not installed.


Activate SOL Via IPMI
    [Documentation]  Start SOL using IPMI and route output to a file.
    [Arguments]  ${file_path}=/tmp/sol_${OPENBMC_HOST}

    # Description of argument(s):
    # file_path                     The file path on the local machine (vs.
    #                               OBMC) to collect SOL output. By default
    #                               SOL output is collected at
    #                               /tmp/sol_<BMC_IP> else user input location.

    ${ipmi_cmd}=  Create IPMI Ext Command String  sol activate usesolkeepalive
    Qprint Issuing  ${ipmi_cmd}
    Start Process  ${ipmi_cmd}  shell=True  stdout=${file_path}
    ...  alias=sol_proc


Deactivate SOL Via IPMI
    [Documentation]  Stop SOL using IPMI and return SOL output.
    [Arguments]  ${file_path}=/tmp/sol_${OPENBMC_HOST}

    # Description of argument(s):
    # file_path                     The file path on the local machine to copy
    #                               SOL output collected by above "Activate
    #                               SOL Via IPMI" keyword.  By default it
    #                               copies log from /tmp/sol_<BMC_IP>.

    ${ipmi_cmd}=  Create IPMI Ext Command String  sol deactivate
    Qprint Issuing  ${ipmi_cmd}
    ${rc}  ${output}=  Run and Return RC and Output  ${ipmi_cmd}
    Run Keyword If  ${rc} > 0  Run Keywords
    ...  Run Keyword And Ignore Error  Terminate Process  sol_proc
    ...  AND  Return From Keyword  ${output}

    ${rc}  ${output}=  Run and Return RC and Output  cat ${file_path}
    Should Be Equal  ${rc}  ${0}  msg=${output}

    # Logging SOL output for debug purpose.
    Log  ${output}

    [Return]  ${output}


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
    :FOR  ${word}  IN  @{listargs}
    \    Run Keyword if   ${index} == 0   Set NetFn Byte  ${word}
    \    Run Keyword if   ${index} == 1   Set Cmd Byte    ${word}
    \    Run Keyword if   ${index} > 1    Set Array Byte  ${word}
    \    ${index}=    Set Variable    ${index + 1}
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
    [Return]    ${valueinBytesWithArray}


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

    OperatingSystem.File Should Exist  tools/ipmitool  msg=${ipmitool_error}

    Import Library      SCPLibrary      WITH NAME       scp
    scp.Open connection     ${OPENBMC_HOST}     username=${OPENBMC_USERNAME}      password=${OPENBMC_PASSWORD}
    scp.Put File    tools/ipmitool   /tmp
    SSHLibrary.Open Connection     ${OPENBMC_HOST}
    Login   ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}
    Execute Command     chmod +x /tmp/ipmitool


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


Get Host State Via External IPMI
    [Documentation]  Returns host state using external IPMI.

    ${output}=  Run External IPMI Standard Command  chassis power status
    Should Not Contain  ${output}  Error
    ${output}=  Fetch From Right  ${output}  ${SPACE}

    [Return]  ${output}


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

    ${output}=  Run External IPMI Standard Command
    ...  sel info  U=${username}  P=${password}
    Should Contain  ${output}  SEL Information
