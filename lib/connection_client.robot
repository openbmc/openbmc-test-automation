*** Settings ***
Documentation     This module is for SSH connection override to QEMU
...               based openbmc systems.

Library           SSHLibrary
Library           OperatingSystem

*** Variables ***

*** Keywords ***
Open Connection And Log In
    [Documentation]  Opens a connection with the given arguments, and logs in.
    ...  Defaults to logging into the BMC.
    [Arguments]  ${username}=${OPENBMC_USERNAME}
    ...          ${password}=${OPENBMC_PASSWORD}  &{connection_args}

    # username          The username to log into the connection with.
    # password          The password to log into the connection with.
    # connection_args   A dictionary of acceptable inputs to the Open Connection
    #                   keyword. If not provided, will establish a connection to
    #                   the ${OPENBMC_HOST} under default settings. If a host is
    #                   not provided while other args are, a connection to the
    #                   ${OPENBMC_HOST} will be established with provided
    #                   settings. Otherwise, a connection with all the args
    #                   provided will be established.

    # If no host was provided, add ${OPENBMC_HOST} to the dictionary
    ${has_host}=  Run Keyword and Return Status
    ...           Dictionary Should Contain Key  ${connection_args}  host
    Run Keyword If  ${has_host} == ${FALSE}
    ...             Set To Dictionary  ${connection_args}  host=${OPENBMC_HOST}

    Run Keyword If
    ...   '${SSH_PORT}' != '${EMPTY}' and '${HTTPS_PORT}' != '${EMPTY}'
    ...   User input SSH and HTTPs Ports

    # Check to see if a port to connect to was provided.
    ${has_port}=  Run Keyword and Return Status
    ...           Dictionary Should Contain Key  ${connection_args}  port

    # If the ${SSH_PORT} is set and no port was provided, add the defined port
    # to the dictionary and open the connection. Otherwise, open the connection
    # with the either the provided port or the default port.
    Run Keyword If  '${SSH_PORT}' != '${EMPTY}' and ${has_port} == ${FALSE}
    ...            Run Keywords
    ...            Set To Dictionary  ${connection_args}  port=${SSH_PORT}  AND
    ...            Open connection  &{connection_args}
    ...   ELSE  Run Keyword  Open connection  &{connection_args}

    Login  ${username}  ${password}

User input SSH and HTTPs Ports
    [Documentation]   Update the global SSH and HTTPs port variable for QEMU
    ${port_num}=    Convert To Integer    ${SSH_PORT}
    ${SSH_PORT}=    Replace Variables     ${port_num}

    ${https_num}=   Convert To Integer    ${HTTPS_PORT}
    Set Global Variable     ${AUTH_URI}    https://${OPENBMC_HOST}:${https_num}
