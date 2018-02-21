*** Settings ***
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/boot_utils.robot
Library                 ../lib/gen_misc.py
Library                 ../lib/utils.py

*** Variables ***
# MAC input from user.
${MAC_ADDRESS}          ${EMPTY}


*** Keywords ***

Check And Reset MAC
    [Documentation]  Update BMC with user input MAC address.
    [Arguments]  ${mac_address}=${MAC_ADDRESS}

    # Description of argument(s):
    # mac_address  The mac address (e.g. 00:01:6c:80:02:28).

    Should Not Be Empty  ${mac_address}
    Open Connection And Log In
    ${bmc_mac_addr}=  Execute Command On BMC  cat /sys/class/net/eth0/address
    Run Keyword If  '${mac_address.lower()}' != '${bmc_mac_addr.lower()}'
    ...  Set MAC Address


Set MAC Address
    [Documentation]  Update eth0 with input MAC address.
    [Arguments]  ${mac_address}=${MAC_ADDRESS}

    # Description of argument(s):
    # mac_address  The mac address (e.g. 00:01:6c:80:02:28).

    Write  fw_setenv ethaddr ${mac_address}
    OBMC Reboot (off)

    # Take SSH session post BMC reboot.
    Open Connection And Log In
    ${bmc_mac_addr}=  Execute Command On BMC  cat /sys/class/net/eth0/address
    Should Be Equal  ${bmc_mac_addr}  ${mac_address}  ignore_case=True


Get BMC IP Info
    [Documentation]  Get system IP address and prefix length.

    Open Connection And Login

    # Get system IP address and prefix length details using "ip addr"
    # Sample Output of "ip addr":
    # 1: eth0: <BROADCAST,MULTIAST> mtu 1500 qdisc mq state UP qlen 1000
    #     link/ether xx:xx:xx:xx:xx:xx brd ff:ff:ff:ff:ff:ff
    #     inet xx.xx.xx.xx/24 brd xx.xx.xx.xx scope global eth0

    ${cmd_output}=  Execute Command On BMC  /sbin/ip addr | grep eth0

    # Get line having IP address details.
    ${lines}=  Get Lines Containing String  ${cmd_output}  inet

    # List IP address details.
    @{ip_components}=  Split To Lines  ${lines}

    @{ip_data}=  Create List

    # Get all IP addresses and prefix lengths on system.
    :FOR  ${ip_component}  IN  @{ip_components}
    \  @{if_info}=  Split String  ${ip_component}
    \  ${ip_n_prefix}=  Get From List  ${if_info}  1
    \  Append To List  ${ip_data}  ${ip_n_prefix}

    [Return]  ${ip_data}

Get BMC Route Info
    [Documentation]  Get system route info.

    Open Connection And Login

    # Sample output of "ip route":
    # default via xx.xx.xx.x dev eth0
    # xx.xx.xx.0/23 dev eth0  src xx.xx.xx.xx
    # xx.xx.xx.0/24 dev eth0  src xx.xx.xx.xx

    ${cmd_output}=  Execute Command On BMC  /sbin/ip route

    [Return]  ${cmd_output}

Get BMC MAC Address
    [Documentation]  Get system MAC address.

    Open Connection And Login

    # Sample output of "ip addr | grep ether":
    # link/ether xx.xx.xx.xx.xx.xx brd ff:ff:ff:ff:ff:ff

    ${cmd_output}=  Execute Command On BMC  /sbin/ip addr | grep ether

    # Split the line and return MAC address.
    # Split list data:
    # link/ether | xx:xx:xx:xx:xx:xx | brd | ff:ff:ff:ff:ff:ff

    @{words}=  Split String  ${cmd_output}

    [Return]  ${words[1]}

Get BMC Hostname
    [Documentation]  Get BMC hostname.

    # Sample output of  "hostnamectl":
    #   Static hostname: xxyyxxyyxx
    #         Icon name: computer
    #        Machine ID: 6939927dc0db409ea09289d5b56eef08
    #           Boot ID: bb806955fd904d47b6aa4bc7c34df482
    #  Operating System: Phosphor OpenBMC (xxx xx xx) v1.xx.x-xx
    #            Kernel: Linux 4.10.17-d6ae40dc4c4dff3265cc254d404ed6b03fcc2206
    #      Architecture: arm

    ${output}=  Execute Command on BMC  hostnamectl | grep hostname

    [Return]  ${output}

Get List Of IP Address Via REST
    [Documentation]  Get list of IP address via REST.
    [Arguments]  @{ip_uri_list}

    # Description of argument(s):
    # ip_uri_list  List of IP objects.
    # Example:
    #   "data": [
    #     "/xyz/openbmc_project/network/eth0/ipv4/e9767624",
    #     "/xyz/openbmc_project/network/eth0/ipv4/31f4ce8b"
    #   ],

    ${ip_list}=  Create List

    : FOR  ${ip_uri}  IN  @{ip_uri_list}
    \  ${ip_addr}=  Read Attribute  ${ip_uri}  Address
    \  Append To List  ${ip_list}  ${ip_addr}

    [Return]  @{ip_list}

Delete IP And Object
    [Documentation]  Delete IP and object.
    [Arguments]  ${ip_addr}  @{ip_uri_list}

    # Description of argument(s):
    # ip_addr      IP address to be deleted.
    # ip_uri_list  List of IP object URIs.

    # Find IP object having this IP address.

    : FOR  ${ip_uri}  IN  @{ip_uri_list}
    \  ${ip_addr1}=  Read Attribute  ${ip_uri}  Address
    \  Run Keyword If  '${ip_addr}' == '${ip_addr1}'  Exit For Loop

    # If the given IP address is not configured, return.
    # Otherwise, delete the IP and object.

    Run Keyword And Return If  '${ip_addr}' != '${ip_addr1}'
    ...  Pass Execution  IP address to be deleted is not configured.

    Run Keyword And Ignore Error  OpenBMC Delete Request  ${ip_uri}

    # After any modification on network interface, BMC restarts network
    # module, wait until it is reachable.

    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_RETRY_TIME}
    ...  ${NETWORK_TIMEOUT}

    # Verify whether deleted IP address is removed from BMC system.

    ${ip_data}=  Get BMC IP Info
    Should Not Contain Match  ${ip_data}  ${ip_addr}*
    ...  msg=IP address not deleted.

Get First Non Pingable IP From Subnet
    [Documentation]  Find first non-pingable IP from the subnet and return it.
    [Arguments]  ${host}=${OPENBMC_HOST}

    # Description of argument(s):
    # host  Any valid host name or IP address
    #       (e.g. "machine1" or "9.xx.xx.31").

    # Non-pingable IP is unused IP address in the subnet.
    ${host_name}  ${ip_addr}=  Get Host Name IP

    # Split IP address into network part and host part.
    # IP address will have 4 octets xx.xx.xx.xx.
    # Sample output after split:
    # split_ip  [xx.xx.xx, xx]

    ${split_ip}=  Split String From Right  ${ip_addr}  .  1
    # First element in list is Network part.
    ${network_part}=  Get From List  ${split_ip}  0

    : FOR  ${octet4}  IN RANGE  1  255
    \  ${new_ip}=  Catenate  ${network_part}.${octet4}
    \  ${status}=  Run Keyword And Return Status  Ping Host  ${new_ip}
    # If IP is non-pingable, return it.
    \  Return From Keyword If  '${status}' == 'False'  ${new_ip}

    Fail  msg=No non-pingable IP could be found in subnet ${network_part}.


Validate MAC On BMC
    [Documentation]  Validate MAC on BMC.
    [Arguments]  ${mac_addr}

    # Description of argument(s):
    # mac_addr  MAC address of the BMC.

    ${system_mac}=  Get BMC MAC Address

    ${status}=  Compare Mac_Address  ${system_mac}  ${mac_addr}
    Should Be True  ${status}
    ...  msg=MAC address does not exist.

