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
# PORT_NUMBER         The switch port where the server is connected (e.g.
#                     "1", "2", etc).
# NET_INTERFACE       The network interface name that will be tested (e.g.
#                     "enP5s1f0", "eth0").

Library         SSHLibrary
Library         String
Library         ../lib/bmc_ssh_utils.py
Resource        ../lib/resource.txt
Resource        ../syslib/utils_os.robot

Suite Setup     Test Setup Execution

*** Variables ***

${PORT_NUMBER}  ${EMPTY}

*** Test Cases ***

Verify Network Interface Recovery
    [Documentation]  Test the recovery of the network interface that has been
    ...  shutdown from the switch port.
    [Tags]  Network_Interface_recover

    Rprintn
    ${state}=  Set Variable  DOWN
    Set Switch Port State  ${state}
    ${state}=  Set Variable  UP
    Set Switch Port State  ${state}=UP

*** Keywords ***

Set Switch Port State
    [Documentation]  Disable the port connected to the server.
    [Arguments]  ${state}=${EMPTY}
    # Description of argument(s):
    # state           The state to be set in the network interface (e.g. "UP").

    Device Write  enable
    Device Write  configure terminal
    Device Write  interface port ${PORT_NUMBER}
    Run Keyword If  '${state}' == 'DOWN'  Run Keywords
    ...  Device Write  shutdown
    ...  AND
    ...  Wait Until Keyword Succeeds  30 sec  5 sec
    ...  Check Network Interface State  ${state}
    ...    ELSE IF  '${state}' == 'UP'  Run Keywords
    ...  Device Write  no shutdown
    ...  AND
    ...  Wait Until Keyword Succeeds  30 sec  5 sec
    ...  Check Network Interface State  ${state}

Check Network Interface State
    [Documentation]  Check the status of the network interface.
    [Arguments]  ${NET_INTERFACE}=${NET_INTERFACE}  ${state}=${EMPTY}
    # Description of argument(s):
    # NET_INTERFACE   The network interface name that will be tested (e.g.
    #                 "enP5s1f0", "eth0").
    # state           The network interface expected state (e.g. "UP").

    ${stdout}  ${stderr}  ${rc}=  OS Execute Command
    ...  ip link | grep "${NET_INTERFACE}" | cut -d " " -f9
    Should Contain  ${stdout}  ${state}

Test Setup Execution
    [Documentation]  Do suite setup tasks.

    Should Not Be Empty  ${PORT_NUMBER}
    Should Not Be Empty  ${NET_INTERFACE}
