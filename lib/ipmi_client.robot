*** Settings ***
Documentation   This module is for IPMI client for copying ipmitool to
...             openbmc box and execute ipmitool IPMI standard
...             command. IPMI raw command will use dbus-send command
Resource        ../lib/resource.txt
Resource        ../lib/connection_client.robot
Library         String

*** Variables ***
${dbusHostIpmicmd1} =   dbus-send --system  /org/openbmc/HostIpmi/1
${dbusHostIpmiCmdReceivedMsg} =   org.openbmc.HostIpmi.ReceivedMessage
${netfnByte} =          ${EMPTY}
${cmdByte}   =          ${EMPTY}
${arrayByte} =          array:byte:
${IPMI_EXT_CMD} =       ipmitool -I lanplus -C 1 -P
${HOST} =               -H
${RAW} =                raw

*** Keywords ***

Run IPMI Command
    [arguments]    ${args}
    ${resp}=     Run Keyword If   '${IPMI_COMMAND}'=='External'
    ...    Run External IPMI RAW Command   ${args}
    ...          ELSE IF          '${IPMI_COMMAND}'=='Dbus'
    ...    Run Dbus IPMI RAW Command   ${args}
    ...          ELSE             Fail
    ...    msg=Invalid IPMI Command type provided : ${IPMI_COMMAND}
    [return]    ${resp}

Run IPMI Standard Command
    [arguments]    ${args}
    ${resp}=     Run Keyword If   '${IPMI_COMMAND}'=='External'
    ...    Run External IPMI Standard Command   ${args}
    ...          ELSE IF          '${IPMI_COMMAND}'=='Dbus'
    ...    Run Dbus IPMI Standard Command   ${args}
    ...          ELSE             Fail
    ...    msg=Invalid IPMI Command type provided : ${IPMI_COMMAND}

    [return]    ${resp}

Run Dbus IPMI RAW Command
    [arguments]    ${args}
    ${valueinBytes} =   Byte Conversion  ${args}
    ${cmd} =   Catenate   ${dbushostipmicmd1} ${dbusHostIpmiCmdReceivedMsg}
    ${cmd} =   Catenate   ${cmd} ${valueinBytes}
    ${output}   ${stderr}=  Execute Command  ${cmd}  return_stderr=True
    Should Be Empty      ${stderr}
    set test variable    ${OUTPUT}     "${output}"

Run Dbus IPMI Standard Command
    [arguments]    ${args}
    ${stdout}    ${stderr}    ${output}=  Execute Command
    ...    /tmp/ipmitool -I dbus ${args}    return_stdout=True
    ...    return_stderr= True    return_rc=True
    Should Be Equal    ${output}    ${0}    msg=${stderr}
    [return]    ${stdout}

Run External IPMI RAW Command
    [arguments]    ${args}
    ${ipmi_raw_cmd}=   Catenate  SEPARATOR=
    ...    ${IPMI_EXT_CMD}${SPACE}${IPMI_PASSWORD}${SPACE}
    ...    ${HOST}${SPACE}${OPENBMC_HOST}${SPACE}${RAW}${SPACE}${args}
    ${rc}    ${output}=    Run and Return RC and Output    ${ipmi_raw_cmd}
    Should Be Equal    ${rc}    ${0}    msg=${output}
    [return]    ${output}

Run External IPMI Standard Command
    [arguments]    ${args}
    ${ipmi_cmd}=   Catenate  SEPARATOR=
    ...    ${IPMI_EXT_CMD}${SPACE}${IPMI_PASSWORD}${SPACE}
    ...    ${HOST}${SPACE}${OPENBMC_HOST}${SPACE}${args}
    ${rc}    ${output}=    Run and Return RC and Output    ${ipmi_cmd}
    Should Be Equal    ${rc}    ${0}    msg=${output}
    [return]   ${output}


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
    [arguments]     ${args}
    ${argLength} =   Get Length  ${args}
    Set Global Variable  ${arrayByte}   array:byte:
    @{listargs} =   Split String  ${args}
    ${index} =   Set Variable   ${0}
    :FOR   ${word}   in   @{listargs}
    \    Run Keyword if   ${index} == 0   Set NetFn Byte  ${word}
    \    Run Keyword if   ${index} == 1   Set Cmd Byte    ${word}
    \    Run Keyword if   ${index} > 1    Set Array Byte  ${word}
    \    ${index} =    Set Variable    ${index + 1}
    ${length} =   Get Length  ${arrayByte}
    ${length} =   Evaluate  ${length} - 1
    ${arrayByteLocal} =  Get Substring  ${arrayByte}  0   ${length}
    Set Global Variable  ${arrayByte}   ${arrayByteLocal}
    ${valueinBytesWithArray} =   Catenate  byte:0x00   ${netfnByte}  byte:0x00
    ${valueinBytesWithArray} =   Catenate  ${valueinBytesWithArray}  ${cmdByte}
    ${valueinBytesWithArray} =   Catenate  ${valueinBytesWithArray} ${arrayByte}
    ${valueinBytesWithoutArray} =   Catenate  byte:0x00 ${netfnByte}  byte:0x00
    ${valueinBytesWithoutArray} =   Catenate  ${valueinBytesWithoutArray} ${cmdByte}
#   To Check scenario for smaller IPMI raw commands with only 2 arguments
#   instead of usual 12 arguments.
#   Sample small IPMI raw command: Run IPMI command 0x06 0x36
#   If IPMI raw argument length is only 9 then return value in bytes without
#   array population.
#   Equivalent dbus-send argument for smaller IPMI raw command:
#   byte:0x00 byte:0x06 byte:0x00 byte:0x36
    Run Keyword if   ${argLength} == 9     Return from Keyword    ${valueinBytesWithoutArray}
    [return]    ${valueinBytesWithArray}


Set NetFn Byte
   [arguments]    ${word}
   ${netfnByteLocal} =  Catenate   byte:${word}
   Set Global Variable  ${netfnByte}  ${netfnByteLocal}

Set Cmd Byte
   [arguments]    ${word}
   ${cmdByteLocal} =  Catenate   byte:${word}
   Set Global Variable  ${cmdByte}  ${cmdByteLocal}

Set Array Byte
   [arguments]    ${word}
   ${arrayByteLocal} =   Catenate   SEPARATOR=  ${arrayByte}  ${word}
   ${arrayByteLocal} =   Catenate   SEPARATOR=  ${arrayByteLocal}   ,
   Set Global Variable  ${arrayByte}   ${arrayByteLocal}

