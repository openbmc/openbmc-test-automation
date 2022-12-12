*** Settings ***
Documentation   Factory reset BMC and set the network config back.

# robot -v OPENBMC_HOST:xx.xx.xx.233 -v SUBNET_MASK:22 -v BMC_GW:xx.xx.xx.1
# -v OPENBMC_SERIAL_HOST:xx.xx.xx.152 -v OPENBMC_SERIAL_PORT:2002
# -v OPENBMC_MODEL:witherspoon factory_reset.robot

Resource     ../lib/resource.robot
Resource     ../lib/serial_connection/serial_console_client.robot
Library      ../lib/bmc_ssh_utils.py

Test Setup   Test Setup Execution

*** Variables ***

${CMD_STATIC_IPV4_PREFIX}    busctl call  xyz.openbmc_project.Network
...  /xyz/openbmc_project/network/eth0 xyz.openbmc_project.Network.IP.Create IP
...  ssys "xyz.openbmc_project.Network.IP.Protocol.IPv4"

${CMD_STATIS_GW_PREFIX}      busctl set-property xyz.openbmc_project.Network
...  /xyz/openbmc_project/network/config
...  xyz.openbmc_project.Network.SystemConfiguration DefaultGateway s


*** Test Cases ***

Factory Reset BMC
    [Documentation]  Factory reset BMC and verify BMC comes back online.

    BMC Execute Command  /usr/bin/hostnamectl set-hostname ${OPENBMC_MODEL}
    BMC Execute Command  /sbin/fw_setenv rwreset true
    Execute Command On Serial Console  reboot -f

    Sleep  4min

    ${cmd_ip}=  Catenate  ${CMD_STATIC_IPV4_PREFIX} ${OPENBMC_HOST}
    ...  ${SUBNET_MASK} ${BMC_GW}
    Execute Command On Serial Console  ${cmd_ip}

    ${cmd_gw}=  Catenate  ${CMD_STATIS_GW_PREFIX}  ${BMC_GW}
    Execute Command On Serial Console  ${cmd_gw}


*** Keywords ***

Test Setup Execution
    [Documentation]  Check if parameters are provided.
    Should Not Be Empty   ${OPENBMC_SERIAL_HOST}
    Should Not Be Empty   ${OPENBMC_SERIAL_PORT}
    Should Not Be Empty   ${OPENBMC_MODEL}
    Should Not Be Empty   ${SUBNET_MASK}
    Should Not Be Empty   ${BMC_GW}
