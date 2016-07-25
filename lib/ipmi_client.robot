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
${netfnByte} =    ${EMPTY}
${cmdByte}   =    ${EMPTY}
${arrayByte} =       array:byte:

*** Keywords ***
Run IPMI Command
    [arguments]    ${args}
    Log to Console  \n ${args}
    ${valueinBytes} =   Byte Conversion  ${args}
    ${output}   ${stderr}=  Execute Command  ${dbushostipmicmd1} ${dbusHostIpmiCmdReceivedMsg} ${valueinBytes}  return_stderr=True
    Should Be Empty 	${stderr}
    set test variable    ${OUTPUT}     "${output}"

Run IPMI Standard Command
    [arguments]    ${args}
    Copy ipmitool
    ${stdout}    ${stderr}    ${output}=  Execute Command    /tmp/ipmitool -I dbus ${args}    return_stdout=True    return_stderr= True    return_rc=True
    Should Be Equal    ${output}    ${0}    msg=${stderr}
    [return]    ${stdout}

Byte Conversion
    [Documentation]   Byte Conversion method receives IPMI RAW commands as argument in string format
    ...               Sample argument is "0x04 0x30 9 0x01 0x00 0x35 0x00 0x00 0x00 0x00 0x00 0x00"
    ...               IPMI RAW command format is  <netfn Byte> <cmd Byte> <Data Bytes..>
    ...               This method converts IPMI command format into dbus command format
    ...               dbu HostIpmi format is <byte:seq-id> <byte:netfn> <byte:lun> <byte:cmd> <array:byte:data>
    ...               byte:0x00 byte:0x04 byte:0x00 byte:0x30 array:byte:9,0x01,0x00,0x35,0x00,0x00,0x00,0x00,0x00,0x00
    [arguments]     ${args}
    ${argLength} =   Get Length  ${args}
#   Initializing Global Variable  and split the IPMI raw arguments which is usually 12 arguments
    Set Global Variable  ${arrayByte}   array:byte:
    @{listargs} =   Split String  ${args}  ${SPACE}  12
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
    ${valueinBytesWithArray} =   Catenate  byte:0x00   ${netfnByte}  byte:0x00  ${cmdByte}  ${arrayByte}
    ${valueinBytesWithoutArray} =   Catenate  byte:0x00   ${netfnByte}  byte:0x00  ${cmdByte}
#   To Check scenario for smaller IPMI raw commands with only 2 arguments instead of usual 12 arguments
#   Sample small IPMI raw command: Run IPMI command 0x06 0x36
#   If IPMI raw argument length is only 9 then return value in bytes without array population
#   Equivalent dbus-send argument for smaller IPMI raw command:  byte:0x00 byte:0x06 byte:0x00 byte:0x36
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

Copy ipmitool
    OperatingSystem.File Should Exist   tools/ipmitool      msg=The ipmitool program could not be found in the tools directory. It is not part of the automation code by default. You must manually copy or link the correct openbmc version of the tool in to the tools directory in order to run this test suite.

    Import Library      SCPLibrary      WITH NAME       scp
    scp.Open connection     ${OPENBMC_HOST}     username=${OPENBMC_USERNAME}      password=${OPENBMC_PASSWORD}
    scp.Put File    tools/ipmitool   /tmp
    SSHLibrary.Open Connection     ${OPENBMC_HOST}
    Login   ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}
    Execute Command     chmod +x /tmp/ipmitool
