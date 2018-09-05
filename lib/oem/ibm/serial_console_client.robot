*** Settings ***
Documentation     Module for capturing BMC serial output

Library           Telnet  newline=LF
Library           OperatingSystem
Library           Collections
Library           String


*** Keywords ***

Open Telnet Connection To BMC Serial Console
    [Documentation]   Open telnet connection session to BMC serial console
    ...               The login prompt expected, for example, for Witherspoon
    ...               is "Witherspoon login:".
    [Arguments]   ${i_host}=${OPENBMC_SERIAL_HOST}
    ...           ${i_port}=${OPENBMC_SERIAL_PORT}
    ...           ${i_model}=${OPENBMC_MODEL}

    # Description of argument(s):
    # i_host    The host name or IP of the serial console.
    # i_port    The port of the serial console.
    # i_model   The path to the system data, i.e. "./data/Witherspoon.py".

    ${prompt_string}=  Convert To Lowercase  ${OPENBMC_MODEL} login:
    Telnet.Open Connection
    ...  ${i_host}  port=${i_port}  prompt=#
    Telnet.Set Timeout  30 seconds
    Telnet.Set Newline  \n
    Telnet.Set Newline  CRLF
    Telnet.Write  \n
    Telnet.Write  exit
    Telnet.Write  \n
    Telnet.Read Until Regexp  (Password:|logout)
    Telnet.Write  \n
    Telnet.Read Until  ${prompt_string}
    Telnet.Write  ${OPENBMC_USERNAME}
    Telnet.Write  \n
    Telnet.Read Until  Password:
    Telnet.Write  ${OPENBMC_PASSWORD}
    Telnet.Write  \n
    Telnet.Read Until Prompt
    Telnet.Set Timeout  30 minute 30 seconds


Read And Log BMC Serial Console Output
    [Documentation]    Reads everything that is currently available
    ...                in the output.

    ${bmc_serial_log}=   Telnet.Read
    Log   ${bmc_serial_log}


Execute Command On Serial Console
    [Documentation]  Execute a command on the BMC serial console.
    [Arguments]  ${command_string}

    # Description of argument(s):
    # command   The command to execute on the BMC.

    Open Telnet Connection To BMC Serial Console
    Telnet.Write  \n
    Telnet.Write  \n
    Telnet.Execute Command  ${command_string}
    Read And Log BMC Serial Console Output
    Close Serial Console Connection


Close Serial Console Connection
    [Documentation]  Log out of the BMC and close telnet.

    Telnet.Write  \n
    Telnet.Write  exit
    Telnet.Close Connection
