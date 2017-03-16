*** Settings ***
Documentation   This program performs Factory data reset.

Resource        ../lib/ipmi_client.robot
Resource        ../lib/utils.robot
Resource        ../lib/connection_client.robot
Resource        ../lib/oem/ibm/serial_console_client.robot
Library         OperatingSystem

Test Setup      Open Connection And Log In
Test Teardown   Close All Connections

*** Test Cases ***

Factory Reset The System
    [Documentation]  Factory reset the system.
    [Tags]  Factory_Reset_The_System
    Erase All Settings

Revert to Initial Setup
    [Documentation]  Revert to old setup.
    [Tags]  Revert_to_Initial_Setup
    Configure Initial Settings
    Ping Host  ${OPENBMC_HOST}

*** Keywords ***

Erase All Settings
    [Documentation]  Factory reset the system.
    Run Dbus IPMI Raw Command  0x32 0xBA 00 00
    Run Dbus IPMI Raw Command  0x32 0x66
    Check Host Connection  ${OPENBMC_HOST}

Check Host Connection
    [Arguments]  ${host}
    [Documentation]  Check host connectivity.
    # Description of Arguments:
    # host  Target System's IP addes.

    ${RC}  ${output}=  Run and return RC and Output  ping -c 4 ${host}
    Log  RC: ${RC}\nOutput:\n${output}
    Should Not be equal  ${RC}  ${0}  msg=Factory reset failed.

Configure Initial Settings
    [Documentation]  Restore old IP and route.
    ...  This keyword requires initial settings viz IP address,
    ...  Network Mask, default gatway and serial console IP and port
    ...  information which should be provided in command line.

    Open Telnet Connection to BMC Serial Console
    Telnet.write  ifconfig eth0 ${OPENBMC_HOST} netmask ${NET_MASK}
    Telnet.write  route add default gw ${GW_IP}
