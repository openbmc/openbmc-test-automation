*** Settings ***
Documentation     This module is for SSH,Telnet connection
...               client to openbmc box.

Library           SSHLibrary
Library           OperatingSystem

*** Variables ***

*** Keywords ***
Open Connection And Log In
    Run Keyword If   '${SSH_PORT}' != '${EMPTY}' and '${HTTPS_PORT}' != '${EMPTY}'   User input SSH and HTTPs Ports

    Run Keyword If  '${SSH_PORT}' == '${EMPTY}'    Open connection     ${OPENBMC_HOST}
    ...    ELSE  Run Keyword   Open connection     ${OPENBMC_HOST}    port=${SSH_PORT}

    Login   ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}

User input SSH and HTTPs Ports
    ${port_num}=    Convert To Integer    ${SSH_PORT}
    ${SSH_PORT}=    Replace Variables     ${port_num}

    ${https_num}=   Convert To Integer    ${HTTPS_PORT}
    ${AUTH_URI}=    Replace Variables     https://${OPENBMC_HOST}:${https_num}
