*** Settings ***
Documentation   This program performs Factory data reset.

Resource        ../lib/ipmi_client.robot
Resource        ../lib/utils.robot
Resource        ../lib/connection_client.robot
Resource        ../lib/oem/ibm/serial_console_client.robot
Library         OperatingSystem

Suite Setup      Validate Setup
Suite Teardown   Close All Connections

*** Test Cases ***

Verify Factory Reset
    [Documentation]  Factory reset the system.
    [Tags]  Verify_Factory_Reset
    Erase All Settings
    ${status}=  Run Keyword And Return Status  Ping Host  ${OPENBMC_HOST}
    Should Be Equal  ${status}  False  msg=Factory reset failed.

Revert to Initial Setup And Verify
    [Documentation]  Revert to old setup.
    [Tags]  Revert_to_Initial_Setup_And_Verify
    Configure Initial Settings
    Ping Host  ${OPENBMC_HOST}

*** Keywords ***

Validate Setup
    [Documentation]  Validate setup.

    Open Connection And Log In

    # Check whether gateway IP is reachable.
    Ping Host  ${GW_IP}
    Should Not Be Empty  ${NET_MASK}  msg=Netmask not provided.

    # Check whether serial console IP is reachable and responding
    # to telnet command.
    Open Telnet Connection to BMC Serial Console

Erase All Settings
    [Documentation]  Factory reset the system.

    Run Dbus IPMI Raw Command  0x32 0xBA 00 00
    Run Dbus IPMI Raw Command  0x32 0x66
