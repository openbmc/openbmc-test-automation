*** Settings ***
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/boot_utils.robot
Library                 ../lib/gen_misc.py
Library                 ../lib/utils.py
Library                        ../lib/func_args.py
*** Variables ***
# MAC input from user.
${MAC_ADDRESS}                  ${EMPTY}
${vlan_resource}                ${NETWORK_MANAGER}action/VLAN
${network_resource}             xyz.openbmc_project.Network.IP.Protocol.IPv4
${static_network_resource}      xyz.openbmc_project.Network.IP.AddressOrigin.Static
${initial_vlan_config}          @{EMPTY}
${gateway}                      0.0.0.0
${netmask}                      ${24}
*** Keywords ***

Check And Reset MAC
    [Documentation]  Update BMC with user input MAC address.
    [Arguments]  ${mac_address}=${MAC_ADDRESS}

    # Description of argument(s):
    # mac_address  The mac address (e.g. 00:01:6c:80:02:28).

    Should Not Be Empty  ${mac_address}
    Open Connection And Log In
    ${bmc_mac_addr}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /sys/class/net/eth0/address
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
    ${bmc_mac_addr}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /sys/class/net/eth0/address
    Should Be Equal  ${bmc_mac_addr}  ${mac_address}  ignore_case=True


Get BMC IP Info
    [Documentation]  Get system IP address and prefix length.


    # Get system IP address and prefix length details using "ip addr"
    # Sample Output of "ip addr":
    # 1: eth0: <BROADCAST,MULTIAST> mtu 1500 qdisc mq state UP qlen 1000
    #     link/ether xx:xx:xx:xx:xx:xx brd ff:ff:ff:ff:ff:ff
    #     inet xx.xx.xx.xx/24 brd xx.xx.xx.xx scope global eth0

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip addr | grep eth0

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

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip addr | grep ether

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
    :FOR  ${line}  IN  @{lines}
    \  @{words}=  Split String  ${line}
    \   Append To List  ${mac_list}  ${words[1]}

    [Return]  ${mac_list}

Get BMC Hostname
    [Documentation]  Get BMC hostname.

    # Sample output of  "hostname":
    # test_hostname

    ${output}  ${stderr}  ${rc}=  BMC Execute Command  hostname

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

    ${status}=  Compare MAC Address  ${system_mac}  ${mac_addr}
    Should Be True  ${status}
    ...  msg=MAC address ${system_mac} does not match ${mac_addr}.


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

    ${data}=  Create Dictionary  HostName=${hostname}
    Redfish.patch  ${REDFISH_NW_PROTOCOL_URI}  body=&{data}
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


Test Setup Execution
    [Documentation]  Check and delete all previously created VLAN if any.

    Printn
    ${lan_config}=  Get LAN Print Dict
    Return From Keyword If  '${lan_config['802.1q VLAN ID']}' == 'Disabled'

    # Get all VLAN ID on interface eth0.
    ${vlan_ids}=  Get VLAN IDs

    ${initial_vlan_config}=  Create List
    Set Suite Variable  ${initial_vlan_config}

    FOR  ${vlan_id}  IN  @{vlan_ids}
        ${vlan_records}=  Read Properties
        ...  ${NETWORK_MANAGER}eth0_${vlan_id}${/}enumerate  quiet=1
        ${vlan_record}=  Filter Struct
        ...  ${vlan_records}  [('Origin', '${static_network_resource}')]

        ${id}=  Convert To Integer  ${vlan_id}
        Set Initial VLAN Config  ${vlan_record}  ${id}
    END
    Rprint Vars  initial_vlan_config

    Delete VLANs  ${vlan_ids}


Set Initial VLAN Config
    [Documentation]  Set suite level list of Initial VLAN Config.
    [Arguments]  ${vlan_record}  ${id}

    # Description of argument(s):
    # vlan_record  Dictionary of IP configuration information of a VLAN.
    # Example:
    #  /xyz/openbmc_project/network/eth0_55/ipv4/5fb2cfe6": {
    #  "Address": "x.x.x.x",
    #  "Gateway": "",
    #  "Origin": "xyz.openbmc_project.Network.IP.AddressOrigin.Static",
    #  "PrefixLength": 16,
    #  "Type": "xyz.openbmc_project.Network.IP.Protocol.IPv4"}
    #
    # id  The VLAN ID corresponding to the IP Configuration records contained
    #     in the variable "vlan_record".

    ${uris}=  Get Dictionary Keys  ${vlan_record}

    FOR  ${uri}  IN  @{uris}
        Append To List  ${initial_vlan_config}  ${id}  ${vlan_record['${uri}']['Address']}
        ...  ${vlan_record['${uri}']['PrefixLength']}
    END

    Run Keyword If  @{uris} == @{EMPTY}
    ...  Append To List  ${initial_vlan_config}  ${id}  ${EMPTY}  ${EMPTY}


Suite Teardown Execution
    [Documentation]  Restore VLAN configuration.

    ${length}=  Get Length  ${initial_vlan_config}
    Return From Keyword If  ${length} == ${0}

    ${previous_id}=  Set Variable  ${EMPTY}
    FOR  ${index}  IN RANGE  0  ${length}  3

        Run Keyword If  '${initial_vlan_config[${index+1}]}' == '${EMPTY}'
        ...  Create VLAN  ${initial_vlan_config[${index}]}
        ...  ELSE IF  '${previous_id}' == '${initial_vlan_config[${index}]}'
        ...  Configure Network Settings On VLAN  ${initial_vlan_config[${index}]}
        ...  ${initial_vlan_config[${index+1}]}  ${initial_vlan_config[${index+2}]}
        ...  ELSE  Run Keywords  Create VLAN  ${initial_vlan_config[${index}]}  AND
        ...  Configure Network Settings On VLAN  ${initial_vlan_config[${index}]}
        ...  ${initial_vlan_config[${index+1}]}  ${initial_vlan_config[${index+2}]}

        ${previous_id}=  Set Variable  ${initial_vlan_config[${index}]}
    END


Delete VLANs
    [Documentation]  Delete one or more VLANs.
    [Arguments]  ${ids}  ${interface}=eth0

    # Description of argument(s):
    # ids                           A list of VLAN IDs (e.g. ['53'] or ['53', '35', '12']). Note that the
    #                               caller may simply pass a list variable or he/she may specify a
    #                               python-like list specification (see examples below).
    # interface                     The physical interface for the VLAN (e.g. 'eth0').

    # Example calls:
    # Delete VLANs  ${vlan_ids}
    # Delete Vlans  [53, 35]

    # Allow for python-like list specifications (e.g. ids=['53']).
    ${vlan_ids}=  Source To Object  ${ids}

    FOR  ${id}  IN  @{vlan_ids}
        OpenBMC Delete Request  ${NETWORK_MANAGER}${interface}_${id}
    END
    Run Key U  Sleep \ ${NETWORK_TIMEOUT}s


Create VLAN
    [Documentation]  Create a VLAN.
    [Arguments]  ${id}  ${interface}=eth0  ${expected_result}=valid

    # Description of argument(s):
    # id  The VLAN ID (e.g. '53').
    # interface  The physical interface for the VLAN(e.g. 'eth0').

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


Get VLAN IDs
    [Documentation]  Return all VLAN IDs.

    ${vlan_ids}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip addr | grep @eth0 | cut -f1 -d@ | cut -f2 -d.
    ${vlan_ids}=  Split String  ${vlan_ids}

    [Return]  @{vlan_ids}


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


Get VLAN URI For IP
    [Documentation]  Get and return the URI for a VLAN IP.
    [Arguments]  ${vlan_id}  ${vlan_ip}  ${expected_result}=valid

    # Description of argument(s):
    # vlan_id  The VLAN ID (e.g. '53').
    # vlan_ip  The VLAN IP (e.g. 'x.x.x.x').

    ${vlan_records}=  Read Properties
    ...  ${NETWORK_MANAGER}eth0_${vlan_id}${/}enumerate  quiet=1
    ${vlan_record}=  Filter Struct  ${vlan_records}  [('Address', '${vlan_ip}')]
    ${num_vlan_records}=  Get Length  ${vlan_record}
    ${status}=  Run Keyword And Return Status  Should Be True  ${num_vlan_records} > 0
    ...  msg=Could not find a uri for vlan "${vlan_id}" with IP "${vlan_ip}".

    Run Keyword If  '${expected_result}' == 'valid'
    ...      Should Be Equal  ${status}  ${True}
    ...      msg=VLAN IP URI doesn't exist!.
    ...  ELSE
    ...      Should Be Equal  ${status}  ${False}
    ...      msg=VLAN IP URI exists!.
    ${uris}=  Get Dictionary Keys  ${vlan_record}
    Return From Keyword If  @{uris} == @{EMPTY}

    [Return]  ${uris[${0}]}


Verify Existence Of VLAN
    [Documentation]  Verify VLAN ID exists.
    [Arguments]  ${id}  ${interface}=eth0  ${expected_result}=valid

    # Description of argument(s):
    # id  The VLAN ID (e.g. id:'53').
    # interface        Physical Interface on which the VLAN is defined.
    # expected_result  Expected status to check existence or non-existence of VLAN.

    ${vlan_ids}=  Get VLAN IDs
    ${cli_status}=  Run Keyword And Return Status
    ...  Valid List  vlan_ids  required_values=['${id}']

    ${network_records}=  Read Properties  ${NETWORK_MANAGER}
    ${rest_status}=  Run Keyword And Return Status  Valid List  network_records
    ...  required_values=['${NETWORK_MANAGER}${interface}_${id}']

    Should Be Equal  ${rest_status}  ${cli_status}
    ...  msg=REST and CLI Output are not the same.
    Run Keyword If  '${expected_result}' == 'valid'
    ...      Should Be Equal  ${rest_status}  ${True}
    ...      msg=VLAN ID doesn't exist!.
    ...  ELSE
    ...      Should Be Equal  ${rest_status}  ${False}
    ...      msg=VLAN ID exists!.

