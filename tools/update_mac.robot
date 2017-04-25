*** Settings ***
Documentation  Comapare and update BMC MAC address with input MAC if
...            they are different.

Resource   ../lib/oem/ibm/serial_console_client.robot

*** Variables ***

#MAC input from Jenkins job passed over from AES
${MAC_AES_INPUT}

*** Test Cases ***

Check And Reset MAC
    [Documentation]   Get BMC System MAC address and update with input.

    Open Telnet Connection to BMC Serial Console
    ${output}=  Telnet.Execute Command  cat /sys/class/net/eth0/address
    ...         strip_prompt=True
    Run Keyword If  '${MAC_AES_INPUT}' not in '''${output}'''
    ...  Set AES MAC Address

*** Keywords ***

Set AES MAC Address
    [Documentation]  Update eth0 with AES MAC address

    Telnet.Write  export PATH=$PATH:/usr/sbin
    Telnet.Write  ifconfig eth0 down
    Telnet.Write  ifconfig eth0 hw ether ${MAC_AES_INPUT}
    Telnet.Write  ifconfig eth0 up
