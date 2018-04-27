*** Settings ***
Documentation  Verify the port recovery by simulating its disconnection.

# Test Parameters:

# OS_HOST             The OS host name or IP Address.
# OS_USERNAME         The OS login userid (usually root).
# OS_PASSWORD         The OS login password.
# DEVICE_HOST         The network device hostname or IP where the ports will
#                     be shutdown.
# DEVICE_USERNAME     The network device username.
# DEVICE_PASSWORD     The network device password.
# PORT_NUMBER         The switch port where the server is connected.
# NET_INTERFACE       The network interface name that will be tested (e.g.
#                     "enP5s1f0","eth0").

Library         SSHLibrary
Library         String
Library         ../lib/gen_robot_ssh.py
Resource        ../lib/resource.txt
Resource        ../syslib/utils_os.robot

Suite Setup     Test Setup Execution

*** Variables ***
${PORT_NUMBER}

*** Test Cases ***
Recover Network Interface
    [Documentation]  Test the recovery of the network interface that has been
    ...  shutdown from the switch port.
    [Tags]  Network_Interface_recover

    Disable Switch Port
    Wait Until Keyword Succeeds  30 sec  5 sec  Check Network Interface Down
    Enable Switch Port
    Wait Until Keyword Succeeds  30 sec  5 sec  Check Network Interface Up

*** Keywords ***
Disable Switch Port
    [Documentation]  Disable the port connected to the server.

    SSHLibrary.Open Connection  ${DEVICE_HOST}  port=22
    SSHLibrary.Login  ${DEVICE_USERNAME}  ${DEVICE_PASSWORD}
    Write  enable
    Write  configure terminal
    Write  interface port ${PORT_NUMBER}
    Write  shutdown

Enable Switch Port
    [Documentation]  Enable the port connected to the server.

    SSHLibrary.Open Connection  ${DEVICE_HOST}  port=22
    SSHLibrary.Login  ${DEVICE_USERNAME}  ${DEVICE_PASSWORD}
    Write  enable
    Write  configure terminal
    Write  interface port ${PORT_NUMBER}
    Write  no shutdown

Check Network Interface Status
    [Documentation]  Check the status of the network interface.
    [Arguments]  ${NET_INTERFACE}=${NET_INTERFACE}
    # Description of argument(s):
    # NET_INTERFACE   The network interface name that will be tested (e.g.
    #                 "enP5s1f0","eth0").

    ${stdout}  ${stderr}  ${rc}=  OS Execute Command
    ...  ip link | grep "${NET_INTERFACE}" | cut -d " " -f9
    Should Be Empty  ${stderr}
    [Return]  ${stdout}

Check Network Interface Down
    [Documentation]  Check that the network interface has been shutdown.
    [Arguments]  ${NET_INTERFACE}=${NET_INTERFACE}
    # Description of argument(s):
    # NET_INTERFACE   The network interface name that will be tested (e.g.
    #                 "enP5s1f0","eth0").

    ${stdout}=  Check Network Interface Status
    Should Contain  ${stdout}  DOWN

Check Network Interface Up
    [Documentation]  Check that the network interface has been enabled.
    [Arguments]  ${NET_INTERFACE}=${NET_INTERFACE}
    # Description of argument(s):
    # NET_INTERFACE   The network interface name that will be tested (e.g.
    #                 "enP5s1f0","eth0").

    ${stdout}=  Check Network Interface Status
    Should Contain  ${stdout}  UP

Test Setup Execution
    [Documentation]  Do suite setup tasks.

    Should Not Be Empty  ${PORT_NUMBER}
    Should Not Be Empty  ${NET_INTERFACE}
