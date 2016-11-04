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
    [Documentation]   Factory data reset and check system status
    ...               This test case tries to factory-reset system and verifies IP address
    [Tag]             Reset_to_Facotory
    Factory Reset

Zero Config
    [Documentation]   Validate Zero Config IP
    ...               This test case tries to factory-reset system and checks
    ...               whether system comes up with Zero Config IP
    [Tag]             Zero_Config
    Factory Reset
    Validate Zero Config IP   ${OPENBMC_HOST}
    Revert to Initial Setup   ${OPENBMC_HOST}
    Ping Host                 ${OPENBMC_HOST}

*** Keywords ***

Factory Reset
    [Documentation]     Factory-reset the system
    ${set_factory_reset}=  Run Dbus IPMI Raw Command   0x32 0xBA 00 00
    ${do_factory_reset}=  Run Dbus IPMI Raw Command   0x32 0x66
    Check Host Connection    ${OPENBMC_HOST}

Validate Zero Config IP
    # NOTE: Currently there is no way to check zero config is
    # set or not, Instead  we test old IP is disconfigured or not
    [Documentation]   Validate zero config IP
    [Arguments]       ${ip}
    Log               ${ip}
    Check Host Connection   ${ip}

Check Host Connection
    [Arguments]     ${host}
    Log To Console   pinging ${host}
    ${RC}  ${output}=  Run and return RC and Output  ping -c 4 ${host}
    Log     RC: ${RC}\nOutput:\n${output}
    Should Not be equal     ${RC}   ${0}

Revert to Initial Setup
    [Documentation]  This keyword erases zero config IP and restores old IP and route
    [Arguments]      ${ip}
    Open Telnet Connection to BMC Serial Console
    Telnet.write            ifconfig eth0 ${ip} netmask ${NMASK}
    Telnet.write            route add default gw ${GW_IP}
