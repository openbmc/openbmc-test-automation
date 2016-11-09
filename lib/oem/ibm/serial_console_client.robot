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
    ...           ${i_port}=OPENBMC_SERIAL_PORT
    ...           ${i_model}=${OPENBMC_MODEL}

    Run Keyword If
    ...  '${i_host}' != '${EMPTY}' and '${i_port}' != '${EMPTY}' and '${i_model}' != '${EMPTY}'
    ...  Establish Telnet Session
    ...  ELSE   Fail   msg=One of the paramaters is EMPTY


Establish Telnet Session on BMC Serial Console
    [Documentation]   Establish telnet session and set timeout approx
    ...               30 mins 30 seconds as a round figure MAX timeout for
    ...               operation like code update, manufacturing test and reboot
    ...               use case else telnet .

    ${prompt_string}   Set Variable   ${OPENBMC_MODEL} login:
    Telnet.Open Connection    ${TELNET_HOST}  port=${TELNET_PORT}  prompt=#
    Set Newline    \n
    Set Newline    CRLF
    Telnet.Write   \n
    Telnet.Login   ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ...    login_prompt=${prompt_string}   password_prompt=Password:
    Telnet.Set Timeout   30 minute 30 seconds
