*** Settings ***
Documentation       This module is for SSH connection override to QEMU
...                 based openbmc systems.

Library             SSHLibrary    timeout=30 seconds
Library             OperatingSystem
Library             Collections


*** Keywords ***
Open Connection And Log In
    [Documentation]    Opens a connection with the given arguments, and logs in.
    ...    Defaults to logging into the BMC.
    [Arguments]    ${username}=${OPENBMC_USERNAME}
    ...    ${password}=${OPENBMC_PASSWORD}    &{connection_args}

    # username    The username to log into the connection with.
    # password    The password to log into the connection with.
    # connection_args    A dictionary of acceptable inputs to the Open Connection
    #    keyword. This includes, but is not limited to, the
    #    following:
    #    host, alias, port, timeout, newline, prompt, term_type,
    #    width, height, path_separator, encoding
    #    (For more information, please visit the SSHLibrary doc)

    #    Of the above arguments to Open Connection, this keyword
    #    will provide the following default values:
    #    host    ${OPENBMC_HOST}

    # If no host was provided, add ${OPENBMC_HOST} to the dictionary
    ${has_host}=    Run Keyword and Return Status
    ...    Dictionary Should Contain Key    ${connection_args}    host
    IF    ${has_host} == ${FALSE}
        Set To Dictionary    ${connection_args}    host=${OPENBMC_HOST}
    END

    IF    '${SSH_PORT}' != '${EMPTY}' and '${HTTPS_PORT}' != '${EMPTY}'
        User input SSH and HTTPs Ports
    END

    # Check to see if a port to connect to was provided.
    ${has_port}=    Run Keyword and Return Status
    ...    Dictionary Should Contain Key    ${connection_args}    port

    # If the ${SSH_PORT} is set and no port was provided, add the defined port
    # to the dictionary and open the connection. Otherwise, open the connection
    # with the either the provided port or the default port.
    IF    '${SSH_PORT}' != '${EMPTY}' and ${has_port} == ${FALSE}
        Set To Dictionary    ${connection_args}    port=${SSH_PORT}
        SSHLibrary.Open connection    &{connection_args}
    ELSE
        Run Keyword    SSHLibrary.Open connection    &{connection_args}
    END

    SSHLibrary.Login    ${username}    ${password}

Open Connection for SCP
    [Documentation]    Open a connection for SCP.
    Import Library    SCPLibrary    WITH NAME    scp
    IF    '${SSH_PORT}' == '${EMPTY}'
        scp.Open connection    ${OPENBMC_HOST}    username=${OPENBMC_USERNAME}    password=${OPENBMC_PASSWORD}
    ELSE
        Run Keyword
        ...    scp.Open connection
        ...    ${OPENBMC_HOST}
        ...    port=${SSH_PORT}
        ...    username=${OPENBMC_USERNAME}
        ...    password=${OPENBMC_PASSWORD}
    END

User input SSH and HTTPs Ports
    [Documentation]    Update the global SSH and HTTPs port variable for QEMU
    ${port_num}=    Convert To Integer    ${SSH_PORT}
    ${SSH_PORT}=    Replace Variables    ${port_num}

    ${https_num}=    Convert To Integer    ${HTTPS_PORT}
    Set Global Variable    ${AUTH_URI}    https://${OPENBMC_HOST}:${https_num}

Validate Or Open Connection
    [Documentation]    Checks for an open connection to a host or alias.
    [Arguments]    ${alias}=None    ${host}=${EMPTY}    &{connection_args}

    # alias    The alias of the connection to validate.
    # host    The DNS name or IP of the host to validate.
    # connection_args    A dictionary of arguments to pass to Open Connection
    #    and Log In (see above) if the connection is not open. May
    #    contain, but does not need to contain, the host or alias.

    # Check to make sure we have an alias or host to search for.
    IF    '${host}' == '${EMPTY}'
        Should Not Be Equal    ${alias}    None    msg=Need to provide a host or an alias.    values=False
    END

    # Search the dictionary to see if it includes the host and alias.
    ${host_exists}=    Run Keyword and Return Status
    ...    Dictionary Should Contain Key    ${connection_args}    host
    ${alias_exists}=    Run Keyword and Return Status
    ...    Dictionary Should Contain Key    ${connection_args}    alias

    # Add the alias and host back into the dictionary of connection arguments,
    # if needed.
    IF    '${host}' != '${EMPTY}' and ${host_exists} == ${FALSE}
        Set to Dictionary    ${connection_args}    host    ${host}
    END
    IF    '${alias}' != 'None' and ${alias_exists} == ${FALSE}
        Set to Dictionary    ${connection_args}    alias    ${alias}
    END

    @{open_connections}=    Get Connections
    # If there are no open connections, open one and return.
    IF    '${open_connections}' == '[]'
        Open Connection and Log In    &{connection_args}
    END
    IF    '${open_connections}' == '[]'    RETURN

    # Connect to the alias or host that matches. If both are given, only connect
    # to a connection that has both.
    FOR    ${connection}    IN    @{open_connections}
        Log    ${connection}
        ${alias_match}=    Evaluate    '${alias}' == '${connection.alias}'
        ${host_match}=    Evaluate    '${host}' == '${connection.host}'
        ${given_alias}=    Evaluate    '${alias}' != 'None'
        ${no_alias}=    Evaluate    '${alias}' == 'None'
        ${given_host}=    Evaluate    '${host}' != '${EMPTY}'
        ${no_host}=    Evaluate    '${host}' == '${EMPTY}'
        IF    ${given_alias} and ${given_host} and ${alias_match} and ${host_match}
            Switch Connection    ${alias}
            Log to Console    Found connection. Switched to ${alias} ${host}
            IF    ${alias_match} and ${host_match}    RETURN
        ELSE
            Run Keyword If
            ...    ${given_alias} and ${no_host} and ${alias_match}
            ...    Run Keywords
            ...    Switch Connection
            ...    ${alias}
            ...    AND
            ...    Log to Console
            ...    Found connection. Switched to: ${alias}
            ...    AND
            ...    Return From Keyword If
            ...    ${alias_match}
        ELSE
            Run Keyword If
            ...    ${given_host} and ${no_alias} and ${host_match}
            ...    Run Keywords
            ...    Switch Connection
            ...    ${connection.index}
            ...    AND
            ...    Log to Console
            ...    Found Connection. Switched to: ${host}
            ...    AND
            ...    Return From Keyword If
            ...    ${host_match}
        END
    END
    # If no connections are found, open a connection with the provided args.
    Log    No connection with provided arguments.    Opening a connection.
    Open Connection and Log In    &{connection_args}

Clear System Entry From Knownhosts
    [Documentation]    Delete OPENBMC_HOST entry from known_hosts file.
    ${cmd}=    Set Variable    sed '/${OPENBMC_HOST}/d' -i ~/.ssh/known_hosts
    ${rc}    ${output}=    Run and Return RC and Output    ${cmd}
