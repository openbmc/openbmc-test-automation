*** Settings ***
Documentation     Module for capturing BMC serial output

Library           Telnet  newline=LF
Library           OperatingSystem
Library           Collections


*** Keywords ***

Open Serial Console Connection
    [Documentation]   Open telnet connection session to BMC serial console
    ...               The login prompt expected, for example, for barreleye
    ...               is "barreleye login:".
    [Arguments]   ${i_host}=${OPENBMC_SERIAL_HOST}
    ...           ${i_port}=${OPENBMC_SERIAL_PORT}
    ...           ${i_model}=${OPENBMC_MODEL}

    # Description of argument(s):
    # i_host    The host or IP of the serial console to connect to.
    # i_port    The port of the serial console to connect to.
    # i_model   The model of the current machine, i.e. "witherspoon".

    ${prompt_string}   Set Variable   ${i_model} login:
    Telnet.Open Connection
    ...   ${i_host}  port=${i_port}  prompt=#
    Telnet.Set Newline    \n
    Telnet.Set Newline    CRLF
    Telnet.Write   \n
    Telnet.Login   ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ...    login_prompt=${prompt_string}   password_prompt=Password:
    Telnet.Set Timeout   30 minute 30 seconds


Read and Log BMC Serial Console Output
    [Documentation]    Reads everything that is currently available
    ...                in the output.

    ${bmc_serial_log}=   Telnet.Read
    Log   ${bmc_serial_log}


Execute Command On Serial Console
    [Documentation]  Execute a command on the BMC serial console.
    [Arguments]  ${command}

    # Description of argument(s):
    # command   The command to execute on the BMC.

    Telnet.Write  \n
    Telnet.Execute Command  ${command}


Close Serial Console Connection
    [Documentation]  Log out of root on the BMC and close telnet.

    Execute Command On Serial Console  exit
    Telnet.Close Connection