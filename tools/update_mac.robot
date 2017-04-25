*** Settings ***
Documentation  Update BMC MAC address with input MAC.

Library   ../lib/gen_robot_keyword.py
Resource  ../lib/utils.robot
Resource  ../extended/obmc_boot_test_resource.robot

*** Variables ***

# MAC input from Jenkins job.
${MAC_ADDRESS}  ${EMPTY}

*** Test Cases ***

Check And Reset MAC
    [Documentation]  Update BMC with user input MAC address.

    Should Not Be Empty  ${MAC_ADDRESS}
    Open Connection And Log In
    ${bmc_mac_addr}=  Execute Command on BMC  cat /sys/class/net/eth0/address
    Run Keyword If  '${MAC_ADDRESS}' != '${bmc_mac_addr}'
    ...  Set MAC Address

*** Keywords ***

Set MAC Address
    [Documentation]  Update eth0 with input MAC address.

    Write  fw_setenv ethaddr ${MAC_ADDRESS}
    Run Key U  OBMC Boot Test \ OBMC Reboot (off)
    ${bmc_mac_addr}=  Execute Command on BMC  cat /sys/class/net/eth0/address
    Should Be Equal  ${bmc_mac_addr}  ${MAC_ADDRESS}
