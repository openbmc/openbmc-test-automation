*** Settings ***
Documentation  Ethtool provides NIC card info viz Interface name,
...            MAC address, DHCP enabled or not, speed etc.

Library  SSHLibrary
Resource       ../lib/rest_client.robot
Resource       ../lib/connection_client.robot
Resource       ../lib/utils.robot
Resource       ../data/variables.py

*** Variables ***

*** Test Cases ***

Read Ethtool Data And Validate
    [Documentation]  Read Ethtool data and validate.
    [Tags]  Read_Ethtool_Data_And_Validate

    # Get Ethtool data.

    ${dhcp_state}=  Read Attribute  ${XYZ_NETWORK_MANAGER}/eth0  DHCPEnabled
    ${interface_name}=  Read Attribute  ${XYZ_NETWORK_MANAGER}/eth0  InterfaceName
    ${macaddr}=  Read Attribute  ${XYZ_NETWORK_MANAGER}/eth0  MACAddress

    Validate Ethtool Results  ${dhcp_state}  ${interface_name}  ${macaddr}

*** Keywords ***

Validate Ethtool Results
    [Documentation]  Validate Ethtool Results.
    [Arguments]  ${dhcp}  ${interface}  ${macaddr}

    # Description of argument(s):
    # dhcp       Indicates dhcp enabled or not.
    # interface  Interface name (e.g "eth0").
    # macaddr    MAC address  (e.g "XX:XX:XX:XX:XX:XX").

    Open Connection And Login

    # Collect MAC address and interface name on BMC system.

    # Sample Output of "ip addr":
    # 1: eth0: <BROADCAST,MULTIAST> mtu 1500 qdisc mq state UP qlen 1000
    #     link/ether xx:xx:xx:xx:xx:xx brd ff:ff:ff:ff:ff:ff
    #     inet xx.xx.xx.xx/24 brd xx.xx.xx.xx scope global eth0
    # 2: eth1: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN qlen 1000
    #     link/ether xx:xx:xx:xx:xx:xx brd ff:ff:ff:ff:ff:ff
    #     inet xx.xx.xx.xx/24 brd xx.xx.xx.xx scope global eth1

    ${cmd_output}=  Execute Command  /sbin/ip addr
    Should Contain  ${cmd_output}  ${interface}  msg=interface not found.
    Should COntain  ${cmd_output}  ${macaddr}  msg=MAC address not matching.

    # Find whether DHCP enabled on BMC. The file
    # /etc/systemd/network/00-bmc-eth0.network will have line containing 'dhcp'
    # if DHCP is enabled, otherwise it'll not have that line.

    ${cmd_output}= Execute Command  cat /etc/systemd/network/00-bmc-eth0.network
    Run Keyword If  '${dhcp}' == '1'  Should Contain  ${cmd_output}  dhcp
    ...  ELSE  Should Not Contain  ${cmd_output}  dhcp
