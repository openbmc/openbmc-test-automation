*** Settings ***
Documentation   This module is for IPMI client for copying ipmitool to
...             openbmc box and execute ipmitool commands for IPMI
...             standarad command. IPMI raw command will use dbus 
Resource        ../lib/resource.txt
Resource        ../lib/connection_client.robot
Library         String

*** Variables ***
${dbushostipmicmd1} =   dbus-send --system  /org/openbmc/HostIpmi/1
${dbushostipmicmdreceivedmsg} =   org.openbmc.HostIpmi.ReceivedMessage
${netfnByte}
${cmdByte}
${arraybyte} =       array:byte:

*** Keywords ***
Run IPMI Command
    [arguments]    ${args}
    Log to Console  \n ${args}
    ${valueinbytes} =   Byte Conversion  ${args}
    Log to Console  \n ${dbushostipmicmd1}
    Log to Console  \n ${dbushostipmicmdreceivedmsg}
    Log to Console  \n ${valueinbytes}
    ${output}   ${stderr}=  Execute Command  ${dbushostipmicmd1} ${dbushostipmicmdreceivedmsg} ${valueinbytes}  return_stderr=True
    Should Be Empty 	${stderr}
    set test variable    ${OUTPUT}     "${output}"

Run IPMI Standard Command
    [arguments]    ${args}
    Copy ipmitool
    ${stdout}    ${stderr}    ${output}=  Execute Command    /tmp/ipmitool -I dbus ${args}    return_stdout=True    return_stderr= True    return_rc=True
    Should Be Equal    ${output}    ${0}    msg=${stderr}
    [return]    ${stdout}

Byte Conversion
    # This method converts IPMI command format into dbus command format
    [arguments]     ${args}
    ${arglength} =   Get Length  ${args}
    ${arraybyte1}    Set Variable   array:byte:
    Set Global Variable  ${arraybyte}   ${arraybyte1}
    @{listargs} =   Split String  ${args}  ${SPACE}  12
    ${index} =   Set Variable   ${0}
    :FOR   ${word}   in   @{listargs}
    \    Run Keyword if   ${index} == 0   Set NetFn Byte  ${word}
    \    Run Keyword if   ${index} == 1   Set Cmd Byte   ${word}
    \    Run Keyword if   ${index} > 1     Set Array Byte   ${word}
    \    ${index} =    Set Variable    ${index + 1}
    ${length} =   Get Length  ${arraybyte}
    ${length} =   Evaluate  ${length} - 1
    ${arraybyte1} =  Get Substring  ${arraybyte}  0   ${length}
    Set Global Variable  ${arraybyte}   ${arraybyte1}
    ${valueinbyteswarray} =   Catenate  byte:0x00   ${netfnByte}  byte:0x00  ${cmdByte}  ${arraybyte}
    ${valueinbyteswoarray} =   Catenate  byte:0x00   ${netfnByte}  byte:0x00  ${cmdByte} 
    Run Keyword if   ${arglength} == 9     Return from Keyword    ${valueinbyteswoarray} 
    [return]    ${valueinbyteswarray}


Set NetFn Byte
   [arguments]    ${word}
   ${netfnByte1} =  Catenate   byte:${word}
   Set Global Variable  ${netfnByte}  ${netfnByte1}

Set Cmd Byte
   [arguments]    ${word}
   ${cmdByte1} =  Catenate   byte:${word}
   Set Global Variable  ${cmdByte}  ${cmdByte1}

Set Array Byte
   [arguments]    ${word}
   ${arraybyte1} =   Catenate   SEPARATOR=  ${arraybyte}  ${word}
   ${arraybyte1} =   Catenate   SEPARATOR=  ${arraybyte1}   ,
   Set Global Variable  ${arraybyte}   ${arraybyte1}

Copy ipmitool
    OperatingSystem.File Should Exist   tools/ipmitool      msg=The ipmitool program could not be found in the tools directory. It is not part of the automation code by default. You must manually copy or link the correct openbmc version of the tool in to the tools directory in order to run this test suite.

    Import Library      SCPLibrary      WITH NAME       scp
    scp.Open connection     ${OPENBMC_HOST}     username=${OPENBMC_USERNAME}      password=${OPENBMC_PASSWORD}
    scp.Put File    tools/ipmitool   /tmp
    SSHLibrary.Open Connection     ${OPENBMC_HOST}
    Login   ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}
    Execute Command     chmod +x /tmp/ipmitool
