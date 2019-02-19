*** Settings ***
Documentation   This program performs Factory data reset.

Resource        ../lib/ipmi_client.robot
Resource        ../lib/utils.robot
Resource        ../lib/connection_client.robot
Resource        ../lib/serial_connection/serial_console_client.robot
Library         OperatingSystem

Suite Setup      Validate Setup
Suite Teardown   Close All Connections

Force Tags  Factory_Reset

*** Test Cases ***

Verify Factory Reset
    [Documentation]  Factory reset the system and verify if BMC is online.
    [Tags]  Verify_Factory_Reset

    # Factory reset erases user config settings which incldes IP, netmask
    # gateway and route. Before running this test we are checking all these
    # settings and checking whether ping works with BMC host.
    # If factory reset is successful, ping to BMC host should fail as
    # IP address is erased and comes up with zero_conf.

    Erase All Settings
    ${status}=  Run Keyword And Return Status  Ping Host  ${OPENBMC_HOST}
    Should Be Equal  ${status}  False  msg=Factory reset failed.

Revert to Initial Setup And Verify
    [Documentation]  Revert to old setup.
    [Tags]  Revert_to_Initial_Setup_And_Verify

    # This test case restores old settings Viz IP address, netmask, gateway
    # and route. Restoring is done through serial port console.
    # If reverting to initial setup is successful, ping to BMC
    # host should pass.

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
