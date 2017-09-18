*** Settings ***
Documentation     Module for capturing BMC serial output

Library           Telnet  newline=LF
Library           OperatingSystem
Library           Collections

*** Variables ***

*** Keywords ***

Open Telnet Connection to BMC Serial Console
    [Documentation]   Open telnet connection session to BMC serial console
    ...               The login prompt expected, for example, for barreleye
    ...               is "barreleye login:"
    [Arguments]   ${i_host}=${OPENBMC_SERIAL_HOST}
    ...           ${i_port}=${OPENBMC_SERIAL_PORT}
    ...           ${i_model}=${OPENBMC_MODEL}

    Log To Console    SMS001 *******************************************************

    Run Keyword If
    ...  '${i_host}' != '${EMPTY}' and '${i_port}' != '${EMPTY}' and '${i_model}' != '${EMPTY}'
    ...  Establish Telnet Session on BMC Serial Console
    ...  ELSE   Fail   msg=One of the paramaters is EMPTY


Establish Telnet Session on BMC Serial Console
    [Documentation]   Establish telnet session and set timeout to 30 mins
    ...               30 secs.

    ${prompt_string}   Set Variable   ${OPENBMC_MODEL} login:
    Log To Console  SMS003 **HOST=${OPENBMC_SERIAL_HOST} port=${OPENBMC_SERIAL_PORT} ***************************************************
    Telnet.Open Connection
    ...   ${OPENBMC_SERIAL_HOST}  port=${OPENBMC_SERIAL_PORT}  prompt=#
    Set Newline    \n
    Set Newline    CRLF
    Telnet.Write   \n
    Log To Console  SMS004 *****************************************************

    Log TO Console   SMS005 ********** PS=${prompt_string} PW=${OPENBMC_PASSWORD} **************************
    Telnet.Login   ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ...    login_prompt=${prompt_string}   password_prompt=Password:
    Telnet.Set Timeout   30 minute 30 seconds


Read and Log BMC Serial Console Output
    [Documentation]    Reads everything that is currently available
    ...                in the output.
    ${bmc_serial_log}=   Telnet.Read
    Log   ${bmc_serial_log}
