*** Settings ***
Documentation  Update BMC MAC address with input MAC.

Library   ../lib/gen_robot_keyword.py
Resource  ../lib/utils.robot
Resource  ../extended/obmc_boot_test_resource.robot

*** Variables ***

# MAC input from Jenkins job.
${mac_address}

*** Test Cases ***

Check And Reset MAC
    [Documentation]  Update BMC with user input MAC address.

    Should Not Be Empty  ${mac_address}
    Open Connection And Log In
    ${output}=  Execute Command  cat /sys/class/net/eth0/address
    Run Keyword If  '${mac_address}' != '${output}'
    ...  Set MAC Address

*** Keywords ***

Set MAC Address
    [Documentation]  Update eth0 with input MAC address.

    Write  fw_setenv ethaddr ${mac_address}
    Run Key U  OBMC Boot Test \ OBMC Reboot (off)
    ${output}=  Execute Command  cat /sys/class/net/eth0/address
    Should Be Equal  ${output}  ${mac_address}
