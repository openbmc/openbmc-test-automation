*** Settings ***
Documentation           Verifiy the Network Configuration, Factory Reset and Zero config
...                      Address
Resource                ../lib/ipmi_client.robot
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/oem/ibm/serial_console_client.robot
Resource                ../lib/resource.txt
Library                 OperatingSystem

Suite Setup         Open Connection And Log In
Suite Teardown      Close All Connections

*** Test Cases ***

Zero Config
    [Documentation]   Validate Zero Config IP.
    ...               Factory-reset system and verify system comes up with Zero Config IP.
    [Tags]             Zero_Config
    Factory Reset
    Validate Zero Config IP   ${OPENBMC_HOST}
    Revert to Initial Setup   ${OPENBMC_HOST}
    Ping Host                 ${OPENBMC_HOST}

*** Keywords ***

Factory Reset
    [Documentation]     Factory-reset the system.
    Run Dbus IPMI Raw Command   0x32 0xBA 00 00
    Run Dbus IPMI Raw Command   0x32 0x66
    Check Host Connection    ${OPENBMC_HOST}

Validate Zero Config IP
    [Documentation]   Validate zero config IP.
    [Arguments]       ${ip}
    Check Host Connection   ${ip}

Check Host Connection
    [Documentation]  Verify that host can be pinged.
    [Arguments]     ${host}
    ${RC}  ${output}=  Run and return RC and Output  ping -c 4 ${host}
    Log     RC: ${RC}\nOutput:\n${output}
    Should Not be equal     ${RC}   ${0}

Revert to Initial Setup
    [Documentation]  Erase zero config IP and restore old IP and route.
    [Arguments]      ${ip}
    Open Telnet Connection to BMC Serial Console
    Telnet.write     ifconfig eth0 ${ip} netmask ${NMASK}
    Telnet.write     route add default gw ${GW_IP}
