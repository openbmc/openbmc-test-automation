*** Settings ***
Documentation  Ethtool provides NIC card info viz Interface name,
...            MAC address, DHCP enabled or not, speed etc.

Resource      ../lib/rest_client.robot
Resource      ../lib/connection_client.robot
Resource      ../lib/utils.robot
Resource      ../data/variables.py

*** Variables ***

*** Test Cases ***

Read Ethtool Data And Validate
    [Documentation]  Read Ethtool data and validate.
    [Tags]  Read_Ethtool_Data_And_Validate

    # Get Ethtool data.

    ${dhcp_state}=  Read Attribute  ${XYZ_NETWORK_MANAGER}/eth0  DHCPEnabled
    ${iface_name}=  Read Attribute  ${XYZ_NETWORK_MANAGER}/eth0  InterfaceName
    ${macaddr}=  Read Attribute  ${XYZ_NETWORK_MANAGER}/eth0  MACAddress

    Validate Ethtool  ${dhcp_state}  ${iface_name}  ${macaddr}

*** Keywords ***

Validate Ethtool
    [Documentation]  Validate Ethtool.
    [Arguments]  ${dhcp}  ${iface}  ${macaddr}

    Open Connection And Login

    # Collect MAC address and interface name on BMC system.

    # Sample Output of "ip addr":
    # 1: eth0: <BROADCAST,MULTIAST> mtu 1500 qdisc mq state UP qlen 1000
    # link/ether 00:0a:f7:66:5f:a0 brd ff:ff:ff:ff:ff:ff
    # inet 9.3.62.216/24 brd 9.3.62.255 scope global eth0
    # 2: eth1: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN qlen 1000
    # link/ether 00:0a:f7:66:5f:a2 brd ff:ff:ff:ff:ff:ff

    ${cmd_output}=  Exceute Command  ip addr
    Should Contain  ${cmd_output}  ${iface}  msg=interface not found.
    Should COntain  ${cmd_output}  ${macaddr}  msg=mac address not matching.

    # Find whether DHCP enabled on BMC, the file 
    # /etc/systemd/network/00-bmc-eth0.network will have line containing 'dhcp' 
    # if DHCP is enabled else it'll not have that line.

    ${cmd_output}= Execute Command  cat /etc/systemd/network/00-bmc-eth0.network
    Run Keyword If  '${dhcp}' == '1'  Should Contain  ${cmd_output}  dhcp
    ...  ELSE  Should Not Contain  ${cmd_output}  dhcp
