*** Settings ***
Documentation  Verify the EEH recovery on the controllers connected to the
...  PCI. This injects an EEH error to every controller installed on the
...  server.

# Test Parameters:

# TYPE                EEH error function to use.
# OS_HOST             The OS host name or IP Address.
# OS_USERNAME         The OS login userid (usually root).
# OS_PASSWORD         The password for the OS login.
# DEVICE_HOST         The network device IP where the ports will be shutdown.
# DEVICE_USERNAME     The network device username.
# DEVICE_PASSWORD     The network device password.
# PORT_NUMBER         The switch port where the server is connected.
# NET_INTERFACE       The network interface name that will be tested.

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
    Sleep  30 sec
    Login To OS
    ${stdout}  ${stderr}  ${rc}=  OS Execute Command
    ...  ip link | grep "${NET_INTERFACE}" | cut -d " " -f9
    Should Contain  ${stdout}  DOWN
    Enable Switch Port
    Sleep  30 sec
    ${stdout}  ${stderr}  ${rc}=  OS Execute Command
    ...  ip link | grep "${NET_INTERFACE}" | cut -d " " -f9
    Should Contain  ${stdout}  UP

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

Test Setup Execution
    [Documentation]  Do suite setup tasks.

    Should Not Be Empty  ${PORT_NUMBER}
    Should Not Be Empty  ${NET_INTERFACE}