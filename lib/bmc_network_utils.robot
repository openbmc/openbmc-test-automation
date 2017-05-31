*** Settings ***
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/boot_utils.robot

*** Variables ***
# MAC input from user.
${MAC_ADDRESS}          ${EMPTY}


*** Keywords ***

###############################################################################
Check And Reset MAC
    [Documentation]  Update BMC with user input MAC address.
    [Arguments]  ${mac_address}=${MAC_ADDRESS}

    # Description of argument(s):
    # mac_address  The mac address (e.g. 00:01:6c:80:02:28).

    Should Not Be Empty  ${mac_address}
    Open Connection And Log In
    ${bmc_mac_addr}=  Execute Command On BMC  cat /sys/class/net/eth0/address
    Run Keyword If  '${mac_address}' != '${bmc_mac_addr}'
    ...  Set MAC Address

###############################################################################


###############################################################################
Set MAC Address
    [Documentation]  Update eth0 with input MAC address.
    [Arguments]  ${mac_address}=${MAC_ADDRESS}

    # Description of argument(s):
    # mac_address  The mac address (e.g. 00:01:6c:80:02:28).

    Write  fw_setenv ethaddr ${mac_address}
    OBMC Reboot (off)
    ${bmc_mac_addr}=  Execute Command On BMC  cat /sys/class/net/eth0/address
    Should Be Equal  ${bmc_mac_addr}  ${mac_address}

###############################################################################
