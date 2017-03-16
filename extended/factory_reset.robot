*** Settings ***
Documentation  Verifiy the Network Configuration, Factory Reset and Zero config
...            Address
Resource       ../lib/ipmi_client.robot
Resource       ../lib/utils.robot
Resource       ../lib/connection_client.robot
Resource       ../lib/oem/ibm/serial_console_client.robot
Resource       ../lib/resource.txt
Library        OperatingSystem

Suite Setup     Open Connection And Log In
Suite Teardown  Close All Connections

*** Test Cases ***

Factory Reset
    [Documentation]  Factory-reset the system.
    [Tags]  Factory_Reset
    Erase All

Revert to Initial Setup
    [Documentation]  Revert to old setup.
    [Tags]  Revert_to_Initial_Setup
    Configure Initial Settings  ${OPENBMC_HOST}
    Ping Host  ${OPENBMC_HOST}

*** Keywords ***

Erase All
    [Documentation]   Factory-reset the system.
    Run Dbus IPMI Raw Command  0x32 0xBA 00 00
    Run Dbus IPMI Raw Command  0x32 0x66
    Check Host Connection  ${OPENBMC_HOST}

Check Host Connection
    [Arguments]  ${host}
    # Description of Arguments:
    # ${host}  Target System's IP addes.

    ${RC}  ${output}=  Run and return RC and Output  ping -c 4 ${host}
    Log  RC: ${RC}\nOutput:\n${output}
    Should Not be equal  ${RC}  ${0}  msg=Factory-reset failed.

Configure Initial Settings
    [Documentation]  Erase zero config IP and restore old IP and route.
    [Arguments]  ${ip}
    # Description of Arguments:
    # ${ip}  Initial IP address of the system.
    Open Telnet Connection to BMC Serial Console
    Telnet.write  ifconfig eth0 ${ip} netmask ${NMASK}
    Telnet.write  route add default gw ${GW_IP}
