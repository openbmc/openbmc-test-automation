*** Settings ***
Documentation           This suite will verifiy the Network Configuration, Factory Reset
...                     and Zero config Address
Resource                ../lib/ipmi_client.robot
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/oem/ibm/serial_console_client.robot
Resource                ../lib/resource.txt
Library                 OperatingSystem

Suite Setup         Open Connection And Log In
Suite Teardown      Close All Connections

*** Test Cases ***

Reset to Factory
    [Documentation]   ***DISRUPTIVE PATH***
    ...               This test case tries to factory reset system and checks
    Factory Reset

Zeroconf
    [Documentation]   ***DISRUPTIVE PATH***
    ...               This test case tries to factory reset system and checks
    ...               whether system comes up with Zero Config IP
    Factory Reset
    Validate Zero Config IP   ${OPENBMC_HOST}
    Revert to Initial Setup   ${OPENBMC_HOST}
    Ping Host                 ${OPENBMC_HOST}

***keywords***

Factory Reset
    [Documentation]  This keyword do the factory reset on system
    ${set_factory_reset}=   Run Dbus IPMI Raw Command   0x32 0xBA 00 00
    ${do_factory_reset}=   Run Dbus IPMI Raw Command   0x32 0x66
    Check Host Connection    ${OPENBMC_HOST}

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
    Open Telnet Connection to BMC Serial Console
    Telnet.write            ifconfig eth0 ${ip} netmask ${NMASK}
    Telnet.write            route add default gw ${GW_IP}
