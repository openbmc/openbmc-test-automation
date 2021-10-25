*** Settings ***
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/boot_utils.robot
Library                 ../lib/gen_misc.py
Library                 ../lib/utils.py
Library                 ../lib/bmc_network_utils.py

*** Variables ***
# MAC input from user.
${MAC_ADDRESS}          ${EMPTY}


*** Keywords ***

Check And Reset MAC
    [Documentation]  Update BMC with user input MAC address.
    [Arguments]  ${mac_address}=${MAC_ADDRESS}

    # Description of argument(s):
    # mac_address  The mac address (e.g. 00:01:6c:80:02:28).

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Should Not Be Empty  ${mac_address}
    Open Connection And Log In
    ${bmc_mac_addr}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /sys/class/net/${ethernet_interface}/address
    Run Keyword If  '${mac_address.lower()}' != '${bmc_mac_addr.lower()}'
    ...  Set MAC Address


Set MAC Address
    [Documentation]  Update eth0 with input MAC address.
    [Arguments]  ${mac_address}=${MAC_ADDRESS}

    # Description of argument(s):
    # mac_address  The mac address (e.g. 00:01:6c:80:02:28).

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Write  fw_setenv ethaddr ${mac_address}
    OBMC Reboot (off)

    # Take SSH session post BMC reboot.
    Open Connection And Log In
    ${bmc_mac_addr}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /sys/class/net/${ethernet_interface}/address
    Should Be Equal  ${bmc_mac_addr}  ${mac_address}  ignore_case=True


Get BMC IP Info
    [Documentation]  Get system IP address and prefix length.


    # Get system IP address and prefix length details using "ip addr"
    # Sample Output of "ip addr":
    # 1: eth0: <BROADCAST,MULTIAST> mtu 1500 qdisc mq state UP qlen 1000
    #     link/ether xx:xx:xx:xx:xx:xx brd ff:ff:ff:ff:ff:ff
    #     inet xx.xx.xx.xx/24 brd xx.xx.xx.xx scope global eth0

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}
    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip addr | grep ${ethernet_interface}

    # Get line having IP address details.
    ${lines}=  Get Lines Containing String  ${cmd_output}  inet

    # List IP address details.
    @{ip_components}=  Split To Lines  ${lines}

    @{ip_data}=  Create List

    # Get all IP addresses and prefix lengths on system.
    FOR  ${ip_component}  IN  @{ip_components}
      @{if_info}=  Split String  ${ip_component}
      ${ip_n_prefix}=  Get From List  ${if_info}  1
      Append To List  ${ip_data}  ${ip_n_prefix}
    END

    [Return]  ${ip_data}

Get BMC Route Info
    [Documentation]  Get system route info.


    # Sample output of "ip route":
    # default via xx.xx.xx.x dev eth0
    # xx.xx.xx.0/23 dev eth0  src xx.xx.xx.xx
    # xx.xx.xx.0/24 dev eth0  src xx.xx.xx.xx

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip route

    [Return]  ${cmd_output}

# TODO: openbmc/openbmc-test-automation#1331
Get BMC MAC Address
    [Documentation]  Get system MAC address.


    # Sample output of "ip addr | grep ether":
    # link/ether xx.xx.xx.xx.xx.xx brd ff:ff:ff:ff:ff:ff

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip addr | grep ${ethernet_interface} -A 1 | grep ether

    # Split the line and return MAC address.
    # Split list data:
    # link/ether | xx:xx:xx:xx:xx:xx | brd | ff:ff:ff:ff:ff:ff

    @{words}=  Split String  ${cmd_output}

    [Return]  ${words[1]}


Get BMC MAC Address List
    [Documentation]  Get system MAC address

    # Sample output of "ip addr | grep ether":
    # link/ether xx.xx.xx.xx.xx.xx brd ff:ff:ff:ff:ff:ff

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip addr | grep ether

    # Split the line and return MAC address.
    # Split list data:
    # link/ether | xx:xx:xx:xx:xx:xx | brd | ff:ff:ff:ff:ff:ff
    # link/ether | xx:xx:xx:xx:xx:xx | brd | ff:ff:ff:ff:ff:ff

    ${mac_list}=  Create List
    @{lines}=  Split To Lines  ${cmd_output}
    FOR  ${line}  IN  @{lines}
      @{words}=  Split String  ${line}
      Append To List  ${mac_list}  ${words[1]}
    END

    [Return]  ${mac_list}

Get BMC Hostname
    [Documentation]  Get BMC hostname.

    # Sample output of  "hostname":
    # test_hostname

    ${output}  ${stderr}  ${rc}=  BMC Execute Command  hostname

    [Return]  ${output}

Get FW_Env MAC Address
    [Documentation]  Get FW_Env MAC address.

    # Sample output of "fw_printenv | grep ethaddr"
    # ethaddr=xx:xx:xx:xx:xx:xx:xx

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    ${ethernet_interface}=  Set Variable If
    ...  "${ethernet_interface}"=="eth0"  ethaddr  eth1addr

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command  /sbin/fw_printenv | grep ${ethernet_interface}

    # Split the line and return MAC address.
    # Split list data:
    # ethaddr | xx:xx:xx:xx:xx:xx:xx

    @{words}=  Split String  ${cmd_output}  =

    [Return]  ${words[1]}


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

    FOR  ${ip_uri}  IN  @{ip_uri_list}
      ${ip_addr}=  Read Attribute  ${ip_uri}  Address
      Append To List  ${ip_list}  ${ip_addr}
    END

    [Return]  @{ip_list}

Delete IP And Object
    [Documentation]  Delete IP and object.
    [Arguments]  ${ip_addr}  @{ip_uri_list}

    # Description of argument(s):
    # ip_addr      IP address to be deleted.
    # ip_uri_list  List of IP object URIs.

    # Find IP object having this IP address.

     FOR  ${ip_uri}  IN  @{ip_uri_list}
       ${ip_addr1}=  Read Attribute  ${ip_uri}  Address
       Run Keyword If  '${ip_addr}' == '${ip_addr1}'  Exit For Loop
     END

    # If the given IP address is not configured, return.
    # Otherwise, delete the IP and object.

    Run Keyword And Return If  '${ip_addr}' != '${ip_addr1}'
    ...  Pass Execution  IP address to be deleted is not configured.

    Run Keyword And Ignore Error  OpenBMC Delete Request  ${ip_uri}

    # After any modification on network interface, BMC restarts network
    # module, wait until it is reachable. Then wait 15 seconds for new
    # configuration to be updated on BMC.

    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}
    ...  ${NETWORK_RETRY_TIME}
    Sleep  15s

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
    ${host_name}  ${ip_addr}=  Get Host Name IP  ${host}

    # Split IP address into network part and host part.
    # IP address will have 4 octets xx.xx.xx.xx.
    # Sample output after split:
    # split_ip  [xx.xx.xx, xx]

    ${split_ip}=  Split String From Right  ${ip_addr}  .  1
    # First element in list is Network part.
    ${network_part}=  Get From List  ${split_ip}  0

    FOR  ${octet4}  IN RANGE  1  255
      ${new_ip}=  Catenate  ${network_part}.${octet4}
      ${status}=  Run Keyword And Return Status  Ping Host  ${new_ip}
      # If IP is non-pingable, return it.
      Return From Keyword If  '${status}' == 'False'  ${new_ip}
    END

    Fail  msg=No non-pingable IP could be found in subnet ${network_part}.


Validate MAC On BMC
    [Documentation]  Validate MAC on BMC.
    [Arguments]  ${mac_addr}

    # Description of argument(s):
    # mac_addr  MAC address of the BMC.

    ${system_mac}=  Get BMC MAC Address
    ${mac_new_addr}=  Truncate MAC Address  ${system_mac}  ${mac_addr}

    ${status}=  Compare MAC Address  ${system_mac}  ${mac_new_addr}
    Should Be True  ${status}
    ...  msg=MAC address ${system_mac} does not match ${mac_new_addr}.

Validate MAC On FW_Env
    [Documentation]  Validate MAC on FW_Env.
    [Arguments]  ${mac_addr}

    # Description of argument(s):
    # mac_addr  MAC address of the BMC.

    ${fw_env_addr}=  Get FW_Env MAC Address
    ${mac_new_addr}=  Truncate MAC Address  ${fw_env_addr}  ${mac_addr}

    ${status}=  Compare MAC Address  ${fw_env_addr}  ${mac_new_addr}
    Should Be True  ${status}
    ...  msg=MAC address ${fw_env_addr} does not match ${mac_new_addr}.

Truncate MAC Address
    [Documentation]  Truncates and returns user provided MAC address.
    [Arguments]    ${sys_mac_addr}  ${user_mac_addr}

    # Description of argument(s):
    # sys_mac_addr  MAC address of the BMC.
    # user_mac_addr user provided MAC address.

    ${mac_byte}=  Set Variable  ${0}
    @{user_mac_list}=  Split String  ${user_mac_addr}  :
    @{sys_mac_list}=  Split String  ${sys_mac_addr}  :
    ${user_new_mac_list}  Create List

    # Truncate extra bytes and bits from MAC address
    FOR  ${mac_item}  IN  @{sys_mac_list}
        ${invalid_mac_byte} =  Get Regexp Matches  ${user_mac_list}[${mac_byte}]  [^A-Za-z0-9]+
        Return From Keyword If  ${invalid_mac_byte}  ${user_mac_addr}
        ${mac_int} =    Convert To Integer      ${user_mac_list}[${mac_byte}]   16
        ${user_mac_len} =  Get Length  ${user_mac_list}
        ${user_mac_byte}=  Run Keyword IF
        ...  ${mac_int} >= ${256}  Truncate MAC Bits  ${user_mac_list}[${mac_byte}]
        ...  ELSE  Set Variable  ${user_mac_list}[${mac_byte}]

        Append To List  ${user_new_mac_list}  ${user_mac_byte}
        ${mac_byte} =    Set Variable    ${mac_byte + 1}
        Exit For Loop If  '${mac_byte}' == '${user_mac_len}'

    END
    ${user_new_mac_string}=   Evaluate  ":".join(${user_new_mac_list})
    [Return]  ${user_new_mac_string}

Truncate MAC Bits
    [Documentation]  Truncates user provided MAC address byte to bits.
    [Arguments]    ${user_mac_addr_byte}

    # Description of argument(s):
    # user_mac_addr_byte user provided MAC address byte to truncate bits

    ${user_mac_addr_int}=   Convert To List  ${user_mac_addr_byte}
    ${user_mac_addr_byte}=  Get Slice From List  ${user_mac_addr_int}  0  2
    ${user_mac_addr_byte_string}=  Evaluate  "".join(${user_mac_addr_byte})
    [Return]  ${user_mac_addr_byte_string}


Run Build Net
    [Documentation]  Run build_net to preconfigure the ethernet interfaces.

    OS Execute Command  build_net help y y
    # Run pingum to check if the "build_net" was run correctly done.
    ${output}  ${stderr}  ${rc}=  OS Execute Command  pingum
    Should Contain  ${output}  All networks ping Ok


Configure Hostname
    [Documentation]  Configure hostname on BMC via Redfish.
    [Arguments]  ${hostname}

    # Description of argument(s):
    # hostname  A hostname value which is to be configured on BMC.

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    ${data}=  Create Dictionary  HostName=${hostname}
    Redfish.patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body=&{data}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]


Verify IP On BMC
    [Documentation]  Verify IP on BMC.
    [Arguments]  ${ip}

    # Description of argument(s):
    # ip  IP address to be verified (e.g. "10.7.7.7").

    # Get IP address details on BMC using IP command.
    @{ip_data}=  Get BMC IP Info
    Should Contain Match  ${ip_data}  ${ip}/*
    ...  msg=IP address does not exist.


Verify Gateway On BMC
    [Documentation]  Verify gateway on BMC.
    [Arguments]  ${gateway_ip}=0.0.0.0

    # Description of argument(s):
    # gateway_ip  Gateway IP address.

    ${route_info}=  Get BMC Route Info

    # If gateway IP is empty or 0.0.0.0 it will not have route entry.

    Run Keyword If  '${gateway_ip}' == '0.0.0.0'
    ...      Pass Execution  Gateway IP is "0.0.0.0".
    ...  ELSE
    ...      Should Contain  ${route_info}  ${gateway_ip}
    ...      msg=Gateway IP address not matching.


Get BMC DNS Info
    [Documentation]  Get system DNS info.


    # Sample output of "resolv.conf":
    # ### Generated manually via dbus settings ###
    # nameserver 8.8.8.8

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /etc/resolv.conf

    [Return]  ${cmd_output}


CLI Get Nameservers
    [Documentation]  Get the nameserver IPs from /etc/resolv.conf and return as a list.

    # Example of /etc/resolv.conf data:
    # nameserver x.x.x.x
    # nameserver y.y.y.y

    ${stdout}  ${stderr}  ${rc}=  BMC Execute Command  egrep nameserver /etc/resolv.conf | cut -f2- -d ' '
    ${nameservers}=  Split String  ${stdout}

    [Return]  ${nameservers}


Get Network Configuration
    [Documentation]  Get network configuration.
    # Sample output:
    #{
    #  "@odata.context": "/redfish/v1/$metadata#EthernetInterface.EthernetInterface",
    #  "@odata.id": "/redfish/v1/Managers/bmc/EthernetInterfaces/eth0",
    #  "@odata.type": "#EthernetInterface.v1_2_0.EthernetInterface",
    #  "Description": "Management Network Interface",
    #  "IPv4Addresses": [
    #    {
    #      "Address": "169.254.xx.xx",
    #      "AddressOrigin": "IPv4LinkLocal",
    #      "Gateway": "0.0.0.0",
    #      "SubnetMask": "255.255.0.0"
    #    },
    #    {
    #      "Address": "xx.xx.xx.xx",
    #      "AddressOrigin": "Static",
    #      "Gateway": "xx.xx.xx.1",
    #      "SubnetMask": "xx.xx.xx.xx"
    #    }
    #  ],
    #  "Id": "eth0",
    #  "MACAddress": "xx:xx:xx:xx:xx:xx",
    #  "Name": "Manager Ethernet Interface",
    #  "SpeedMbps": 0,
    #  "VLAN": {
    #    "VLANEnable": false,
    #    "VLANId": 0
    #  }
    [Arguments]  ${network_active_channel}=${CHANNEL_NUMBER}

    # Description of argument(s):
    # network_active_channel   Ethernet channel number (eg. 1 or 2)
    
    ${active_channel_config}=  Get Active Channel Config
    ${resp}=  Redfish.Get
    ...  ${REDFISH_NW_ETH_IFACE}${active_channel_config['${network_active_channel}']['name']}

    @{network_configurations}=  Get From Dictionary  ${resp.dict}  IPv4StaticAddresses
    [Return]  @{network_configurations}


Add IP Address
    [Documentation]  Add IP Address To BMC.
    [Arguments]  ${ip}  ${subnet_mask}  ${gateway}
    ...  ${valid_status_codes}=${HTTP_OK}

    # Description of argument(s):
    # ip                  IP address to be added (e.g. "10.7.7.7").
    # subnet_mask         Subnet mask for the IP to be added
    #                     (e.g. "255.255.0.0").
    # gateway             Gateway for the IP to be added (e.g. "10.7.7.1").
    # valid_status_codes  Expected return code from patch operation
    #                     (e.g. "200").  See prolog of rest_request
    #                     method in redfish_plus.py for details.

    ${empty_dict}=  Create Dictionary
    ${ip_data}=  Create Dictionary  Address=${ip}
    ...  SubnetMask=${subnet_mask}  Gateway=${gateway}

    ${patch_list}=  Create List
    ${network_configurations}=  Get Network Configuration
    ${num_entries}=  Get Length  ${network_configurations}

    FOR  ${INDEX}  IN RANGE  0  ${num_entries}
      Append To List  ${patch_list}  ${empty_dict}
    END

    ${valid_status_codes}=  Run Keyword If  '${valid_status_codes}' == '${HTTP_OK}'
    ...  Set Variable   ${HTTP_OK},${HTTP_NO_CONTENT}
    ...  ELSE  Set Variable  ${valid_status_codes}

    # We need not check for existence of IP on BMC while adding.
    Append To List  ${patch_list}  ${ip_data}
    ${data}=  Create Dictionary  IPv4StaticAddresses=${patch_list}

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Redfish.patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body=&{data}
    ...  valid_status_codes=[${valid_status_codes}]

    Return From Keyword If  '${valid_status_codes}' != '${HTTP_OK},${HTTP_NO_CONTENT}'

    # Note: Network restart takes around 15-18s after patch request processing.
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

    Verify IP On BMC  ${ip}
    Validate Network Config On BMC


Delete IP Address
    [Documentation]  Delete IP Address Of BMC.
    [Arguments]  ${ip}  ${valid_status_codes}=${HTTP_OK}

    # Description of argument(s):
    # ip                  IP address to be deleted (e.g. "10.7.7.7").
    # valid_status_codes  Expected return code from patch operation
    #                     (e.g. "200").  See prolog of rest_request
    #                     method in redfish_plus.py for details.

    ${empty_dict}=  Create Dictionary
    ${patch_list}=  Create List

    @{network_configurations}=  Get Network Configuration
    FOR  ${network_configuration}  IN  @{network_configurations}
      Run Keyword If  '${network_configuration['Address']}' == '${ip}'
      ...  Append To List  ${patch_list}  ${null}
      ...  ELSE  Append To List  ${patch_list}  ${empty_dict}
    END

    ${ip_found}=  Run Keyword And Return Status  List Should Contain Value
    ...  ${patch_list}  ${null}  msg=${ip} does not exist on BMC
    Pass Execution If  ${ip_found} == ${False}  ${ip} does not exist on BMC

    # Run patch command only if given IP is found on BMC
    ${data}=  Create Dictionary  IPv4StaticAddresses=${patch_list}

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Redfish.patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body=&{data}
    ...  valid_status_codes=[${valid_status_codes}]

    # Note: Network restart takes around 15-18s after patch request processing
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

    ${delete_status}=  Run Keyword And Return Status  Verify IP On BMC  ${ip}
    Run Keyword If  '${valid_status_codes}' == '${HTTP_OK}'
    ...  Should Be True  '${delete_status}' == '${False}'
    ...  ELSE  Should Be True  '${delete_status}' == '${True}'

    Validate Network Config On BMC


Validate Network Config On BMC
    [Documentation]  Check that network info obtained via redfish matches info
    ...              obtained via CLI.

    @{network_configurations}=  Get Network Configuration
    ${ip_data}=  Get BMC IP Info
    FOR  ${network_configuration}  IN  @{network_configurations}
      Should Contain Match  ${ip_data}  ${network_configuration['Address']}/*
      ...  msg=IP address does not exist.
    END


Create VLAN
    [Documentation]  Create a VLAN.
    [Arguments]  ${id}  ${interface}=eth0  ${expected_result}=valid

    # Description of argument(s):
    # id  The VLAN ID (e.g. '53').
    # interface  The physical interface for the VLAN(e.g. 'eth0').
    # expected_result  Expected status of VLAN configuration.

    @{data_vlan_id}=  Create List  ${interface}  ${id}
    ${data}=  Create Dictionary   data=@{data_vlan_id}
    ${resp}=  OpenBMC Post Request  ${vlan_resource}  data=${data}
    ${resp.status_code}=  Convert To String  ${resp.status_code}
    ${status}=  Run Keyword And Return Status
    ...  Valid Value  resp.status_code  ["${HTTP_OK}"]

    Run Keyword If  '${expected_result}' == 'error'
    ...      Should Be Equal  ${status}  ${False}
    ...      msg=Configuration of an invalid VLAN ID Failed.
    ...  ELSE
    ...      Should Be Equal  ${status}  ${True}
    ...      msg=Configuration of a valid VLAN ID Failed.

    Sleep  ${NETWORK_TIMEOUT}s


Configure Network Settings On VLAN
    [Documentation]  Configure network settings.
    [Arguments]  ${id}  ${ip_addr}  ${prefix_len}  ${gateway_ip}=${gateway}
    ...  ${expected_result}=valid  ${interface}=eth0

    # Description of argument(s):
    # id               The VLAN ID (e.g. '53').
    # ip_addr          IP address of VLAN Interface.
    # prefix_len       Prefix length of VLAN Interface.
    # gateway_ip       Gateway IP address of VLAN Interface.
    # expected_result  Expected status of network setting configuration.
    # interface        Physical Interface on which the VLAN is defined.

    @{ip_parm_list}=  Create List  ${network_resource}
    ...  ${ip_addr}  ${prefix_len}  ${gateway_ip}

    ${data}=  Create Dictionary  data=@{ip_parm_list}

    Run Keyword And Ignore Error  OpenBMC Post Request
    ...  ${NETWORK_MANAGER}${interface}_${id}/action/IP  data=${data}

    # After any modification on network interface, BMC restarts network
    # module, wait until it is reachable. Then wait 15 seconds for new
    # configuration to be updated on BMC.

    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}
    ...  ${NETWORK_RETRY_TIME}
    Sleep  ${NETWORK_TIMEOUT}s

    # Verify whether new IP address is populated on BMC system.
    # It should not allow to configure invalid settings.
    ${status}=  Run Keyword And Return Status
    ...  Verify IP On BMC  ${ip_addr}

    Run Keyword If  '${expected_result}' == 'error'
    ...      Should Be Equal  ${status}  ${False}
    ...      msg=Configuration of invalid IP Failed.
    ...  ELSE
    ...      Should Be Equal  ${status}  ${True}
    ...      msg=Configuration of valid IP Failed.


Get BMC Default Gateway
    [Documentation]  Get system default gateway.

    ${route_info}=  Get BMC Route Info

    ${lines}=  Get Lines Containing String  ${route_info}  default via
    @{gateway_list}=  Split To Lines  ${lines}

    # Extract first default gateway and return.
    @{default_gw}=  Split String  ${gateway_list[0]}

    [Return]  ${default_gw[2]}


Validate Hostname On BMC
    [Documentation]  Verify that the hostname read via Redfish is the same as the
    ...  hostname configured on system.
    [Arguments]  ${hostname}

    # Description of argument(s):
    # hostname  A hostname value which is to be compared to the hostname
    #           configured on system.

    ${sys_hostname}=  Get BMC Hostname
    Should Be Equal  ${sys_hostname}  ${hostname}
    ...  ignore_case=True  msg=Hostname does not exist.
