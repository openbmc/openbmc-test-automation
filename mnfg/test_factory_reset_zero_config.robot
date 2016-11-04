*** Settings ***
Documentation		This suite will verifiy the Network Configuration, Factory Reset
...		        And Zero config Address...
...			https://github.com/openbmc/docs/blob/master/rest-api.md

Resource                ../lib/ipmi_client.robot
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Library                 Telnet  newline=LF
Library                 OperatingSystem

Suite Setup         Open Connection And Log In
Suite Teardown      Close All Connections
*** Variables ***
${SERIAL_IP}               portserv7.aus.stglabs.ibm.com
${SERIAL_IP_BMC}           9.3.40.75
${SERIAL_PORT}             2002
${LOGIN_PROMPT}            barreleye login:
${PASSWD_PROMPT}           Password:
${UNAME}                   root
${PASSWD}                  0penBmc
${NMASK}                   255.255.255.0
${GW_IP}                   9.3.23.1

*** Test Cases ***

Reset to Factory
    [Documentation]   ***DISRUPTIVE PATH***
    ...               This test case tries to factory reset system and checks
    ${current_ip}=    Get Current System IP   ${OPENBMC_HOST}
    Factory Reset


Zeroconf
    [Documentation]   ***DISRUPTIVE PATH***
    ...               This test case tries to factory reset system and checks
    ...               whether system comes up with Zero Config IP
    ${current_ip}=    Get Current System IP   ${OPENBMC_HOST}
    Factory Reset
    Validate Zero Config IP   ${OPENBMC_HOST}
    Revert to Initial Setup   ${OPENBMC_HOST}
    Sleep             1 minutes


***keywords***

Get Current System IP
    [Documentation]    This keyword returns current system IP address
    [Arguments]        ${ip}
    Log                Current IP address is ${ip}
    [return]           ${ip}

Factory Reset
    [Documentation]  This keyword do the factory reset on system
    ${set_factory_reset}=   Run Dbus IPMI Raw Command   0x32 0xBA 00 00
    ${do_factory_reset}=   Run Dbus IPMI Raw Command   0x32 0x66

Validate Zero Config IP
    [Documentation]   Currently there is no way to check zero config is set or not
    ...               instead we test old IP is disconfigured or not after factory reset
    [Arguments]       ${ip}
    Log               ${ip}
    Check Host Connection   ${ip}

Check Host Connection
    [Arguments]     ${host}
    Log To Console   pinging ${host}
    ${RC}   ${output} =     Run and return RC and Output    ping -c 4 ${host}
    Log     RC: ${RC}\nOutput:\n${output}
    Should Not be equal     ${RC}   ${0}

Revert to Initial Setup
    [Documentation]  This keyword erases zero config IP and restores old IP and route
    [Arguments]      ${ip} 
    Telnet.Open Connection   ${SERIAL_IP_BMC}    port=${SERIAL_PORT}   prompt=#
    Set Newline   \n
    Set Newline   CRLF
    Telnet.Write   \n
    Telnet.Login      ${UNAME}   ${PASSWD}   0penBmc  login_prompt=${LOGIN_PROMPT}   password_prompt={PASSWD_PROMPT}    login_timeout=10 second   login_incorrect=Login incorrect
    Telnet.write            ifconfig eth0 ${ip} netmask ${NMASK}
    Telnet.write            route add default gw ${GW_IP}
