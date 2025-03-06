*** Settings ***
Documentation    Vmi network utilities keywords.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot
Resource         ../../lib/state_manager.robot
Resource         ../../lib/bmc_network_utils.robot
Library          ../../lib/bmc_network_utils.py

*** Variables ***

&{DHCP_ENABLED}           DHCPEnabled=${True}
&{DHCP_DISABLED}          DHCPEnabled=${False}

&{ENABLE_DHCP}            DHCPv4=&{DHCP_ENABLED}
&{DISABLE_DHCP}           DHCPv4=&{DHCP_DISABLED}

&{SLAAC_ENABLED}          IPv6AutoConfigEnabled=${True}
&{SLAAC_DISABLED}         IPv6AutoConfigEnabled=${False}

&{ENABLE_SLAAC}           StatelessAddressAutoConfig=&{SLAAC_ENABLED}
&{DISABLE_SLAAC}          StatelessAddressAutoConfig=&{SLAAC_DISABLED}

&{DHCPv6_ENABLED}         OperatingMode=Enabled
&{DHCPv6_DISABLED}        OperatingMode=Disabled

&{ENABLE_DHCPv6}          DHCPv6=&{DHCPv6_ENABLED}
&{DISABLE_DHCPv6}         DHCPv6=&{DHCPv6_DISABLED}

${wait_time}              40s
${ethernet_interface}     eth0

*** Keywords ***

Set Static IPv4 Address To VMI And Verify
    [Documentation]  Set static IPv4 address to VMI.
    [Arguments]  ${ip}  ${gateway}  ${netmask}  ${valid_status_code}=${HTTP_ACCEPTED}
    ...  ${interface}=${ethernet_interface}

    # Description of argument(s):
    # ip                 VMI IPv4 address.
    # gateway            Gateway for VMI IP.
    # netmask            Subnetmask for VMI IP.
    # valid_status_code  Expected valid status code from GET request. Default is HTTP_ACCEPTED.
    # interface          VMI interface (eg. eth0 or eth1).

    ${ip_details}=  Create dictionary  Address=${ip}  SubnetMask=${netmask}  Gateway=${gateway}
    ${ip_data}=  Create List  ${ip_details}
    ${resp}=  Redfish.Patch  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}
    ...  body={'IPv4StaticAddresses':${ip_data}}  valid_status_codes=[${valid_status_code}]

    # Wait few seconds for new configuration to get populated on runtime.
    Sleep  ${wait_time}

    Return From Keyword If  ${valid_status_code} != ${HTTP_ACCEPTED}
    ${host_power_state}  ${host_state}=   Redfish Get Host State
    Run Keyword If  '${host_power_state}' == 'On' and '${host_state}' == 'Enabled'
    ...  Verify VMI Network Interface Details  ${ip}  Static  ${gateway}  ${netmask}  ${interface}

Verify VMI Network Interface Details
    [Documentation]  Verify VMI network interface details.
    [Arguments]  ${ip}  ${origin}  ${gateway}  ${netmask}
    ...  ${interface}=${ethernet_interface}  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # ip                 VMI IPv4 address.
    # origin             Origin of IPv4 address eg. Static or DHCP.
    # gateway            Gateway for VMI IP.
    # netmask            Subnetmask for VMI IP.
    # interface          VMI interface (eg. eth0 or eth1).
    # valid_status_code  Expected valid status code from GET request. Default is HTTP_OK.

    ${vmi_ip}=  Get VMI Network Interface Details  ${interface}  ${valid_status_code}
    Should Be Equal As Strings  ${origin}  ${vmi_ip["IPv4_AddressOrigin"]}
    Should Be Equal As Strings  ${gateway}  ${vmi_ip["IPv4_Gateway"]}
    Should Be Equal As Strings  ${netmask}  ${vmi_ip["IPv4_SubnetMask"]}
    Should Be Equal As Strings  ${ip}  ${vmi_ip["IPv4_Address"]}

Delete VMI IPv4 Address
    [Documentation]  Delete VMI IPv4 address.
    [Arguments]  ${delete_param}=IPv4StaticAddresses  ${valid_status_code}=${HTTP_ACCEPTED}
    ...  ${interface}=${ethernet_interface}

    # Description of argument(s):
    # delete_param       Parameter to be deleted eg. IPv4StaticAddresses or IPv4Addresses.
    #                    Default is IPv4StaticAddresses.
    # valid_status_code  Expected valid status code from PATCH request. Default is HTTP_OK.
    # interface          VMI interface (eg. eth0 or eth1).

    ${data}=  Set Variable  {"${delete_param}": [${Null}]}
    ${resp}=  Redfish.Patch
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}
    ...  body=${data}  valid_status_codes=[${valid_status_code}]

    Return From Keyword If  ${valid_status_code} != ${HTTP_ACCEPTED}

    # Wait few seconds for configuration to get effective.
    Sleep  ${wait_time}
    ${vmi_ip}=  Get VMI Network Interface Details  ${interface}
    ${default}=  Set Variable  0.0.0.0
    Verify VMI Network Interface Details  ${default}  Static  ${default}  ${default}

Set VMI IPv4 Origin
    [Documentation]  Set VMI IPv4 origin.
    [Arguments]  ${dhcp_enabled}=${False}  ${valid_status_code}=${HTTP_ACCEPTED}
    ...  ${interface}=${ethernet_interface}

    # Description of argument(s):
    # dhcp_enabled       True if user wants to enable DHCP. Default is Static, hence value is set to False.
    # valid_status_code  Expected valid status code from PATCH request. Default is HTTP_OK.
    # interface          VMI interface (eg. eth0 or eth1).

    ${data}=  Set Variable If  ${dhcp_enabled} == ${False}  ${DISABLE_DHCP}  ${ENABLE_DHCP}
    ${resp}=  Redfish.Patch
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}
    ...  body=${data}  valid_status_codes=[${valid_status_code}]

    Sleep  ${wait_time}
    Return From Keyword If  ${valid_status_code} != ${HTTP_ACCEPTED}
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}
    Should Be Equal  ${resp.dict["DHCPv4"]["DHCPEnabled"]}  ${dhcp_enabled}


Get VMI Network Interface Details
    [Documentation]  Get VMI network interface details.
    [Arguments]  ${interface}=${ethernet_interface}  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # interface          VMI interface (eg. eth0 or eth1).
    # valid_status_code  Expected valid status code from GET request.

    # Note: It returns a dictionary of VMI ethernet interface parameters.

    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}
    ...  valid_status_codes=[${valid_status_code}]

    ${ip_resp}=  Evaluate  json.loads(r'''${resp.text}''')  json

    ${ip_exists}=  Set Variable If  ${ip_resp["IPv4Addresses"]} == @{empty}  ${False}  ${True}
    ${static_exists}=  Set Variable If  ${ip_resp["IPv4StaticAddresses"]} == @{empty}  ${False}  ${True}

    ${vmi_ip}=  Run Keyword If   ${ip_exists} == ${True}
    ...  Create Dictionary  DHCPv4=${${ip_resp["DHCPv4"]["DHCPEnabled"]}}  Id=${ip_resp["Id"]}
    ...  Description=${ip_resp["Description"]}  IPv4_Address=${ip_resp["IPv4Addresses"][0]["Address"]}
    ...  IPv4_AddressOrigin=${ip_resp["IPv4Addresses"][0]["AddressOrigin"]}  Name=${ip_resp["Name"]}
    ...  IPv4_Gateway=${ip_resp["IPv4Addresses"][0]["Gateway"]}
    ...  InterfaceEnabled=${${ip_resp["InterfaceEnabled"]}}
    ...  IPv4_SubnetMask=${ip_resp["IPv4Addresses"][0]["SubnetMask"]}
    ...  IPv4StaticAddresses=${${static_exists}}
    ...  ELSE
    ...  Create Dictionary  DHCPv4=${${ip_resp["DHCPv4"]["DHCPEnabled"]}}  Id=${ip_resp["Id"]}
    ...  Description=${ip_resp["Description"]}  IPv4StaticAddresses=${ip_resp["IPv4StaticAddresses"]}
    ...  IPv4_Address=${ip_resp["IPv4Addresses"]}  Name=${ip_resp["Name"]}
    ...  InterfaceEnabled=${${ip_resp["InterfaceEnabled"]}}

    RETURN  &{vmi_ip}


Get VMI Interfaces
    [Documentation]  Get VMI network interface.
    [Arguments]  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # valid_status_code  Expected valid status code from GET request.
    #                    By default set to ${HTTP_OK}.

    ${resp}=  Redfish.Get  /redfish/v1/Systems/hypervisor/EthernetInterfaces
    ...  valid_status_codes=[${valid_status_code}]

    ${resp}=  Evaluate  json.loads(r'''${resp.text}''')  json
    ${interfaces_uri}=  Set Variable  ${resp["Members"]}
    ${interface_list}=  Create List
    ${number_of_interfaces}=  Get Length  ${interfaces_uri}
    FOR  ${interface}  IN RANGE  ${number_of_interfaces}
        ${_}  ${interface_value}=  Split String From Right  ${interfaces_uri[${interface}]}[@odata.id]  /  1
        Append To List  ${interface_list}  ${interface_value}
    END

   RETURN  @{interface_list}


Verify VMI EthernetInterfaces
    [Documentation]  Verify VMI ethernet interfaces.
    [Arguments]  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # valid_status_code  Expected valid status code from GET request.

    ${resp}=  Redfish.Get  /redfish/v1/Systems/hypervisor/EthernetInterfaces
    ...  valid_status_codes=[${valid_status_code}]

    ${resp}=  Evaluate  json.loads(r'''${resp.text}''')  json
    ${interfaces}=  Set Variable  ${resp["Members"]}

    ${number_of_interfaces}=  Get Length  ${interfaces}
    FOR  ${i}  IN RANGE  ${number_of_interfaces}
        Should Be Equal As Strings  ${interfaces[${i}]}[@odata.id]
        ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/eth${i}
    END
    Should Be Equal  ${resp["Members@odata.count"]}  ${number_of_interfaces}

Get And Set Static VMI IP
    [Documentation]  Get a suitable VMI IP and set it.
    [Arguments]   ${host}=${OPENBMC_HOST}  ${network_active_channel}=${CHANNEL_NUMBER}
    ...  ${interface}=eth0  ${valid_status_code}=${HTTP_ACCEPTED}

    # Description of argument(s):
    # host                    BMC host name or IP address.
    # network_active_channel  Ethernet channel number (e.g.1 or 2).
    # interface               VMI interface (eg. eth0 or eth1).
    # valid_status_code       Expected valid status code from PATCH request. Default is HTTP_ACCEPTED.

    ${vmi_ip}=  Get First Non Pingable IP From Subnet  ${host}
    ${bmc_ip_data}=  Get Network Configuration  ${network_active_channel}

    Set Static IPv4 Address To VMI And Verify  ${vmi_ip}  ${bmc_ip_data[0]['Gateway']}
    ...  ${bmc_ip_data[0]['SubnetMask']}  ${valid_status_code}  ${interface}

    RETURN   ${vmi_ip}  ${bmc_ip_data}


Set VMI SLAACv6 Origin
    [Documentation]  Set VMI SLAACv6 origin.
    [Arguments]  ${slaac_enabled}=${False}  ${valid_status_code}=${HTTP_ACCEPTED}
    ...  ${interface}=${ethernet_interface}

    # Description of argument(s):
    # slaacv6_enabled    True if user wants to enable SLAACv6. Default is Static, hence value is set to False.
    # valid_status_code  Expected valid status code from PATCH request. Default is HTTP_OK.
    # interface          VMI interface (eg. eth0 or eth1).

    ${data}=  Set Variable If  ${slaac_enabled} == ${False}  ${DISABLE_SLAAC}  ${ENABLE_SLAAC}
    ${resp}=  Redfish.Patch
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}
    ...  body=${data}  valid_status_codes=[${valid_status_code}]

    Sleep  ${wait_time}
    Return From Keyword If  ${valid_status_code} != ${HTTP_ACCEPTED}
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}
    Should Be Equal  ${resp.dict["StatelessAddressAutoConfig"]["IPv6AutoConfigEnabled"]}  ${slaac_enabled}


Verify VMI IPv6 Address
    [Documentation]  Verify VMI IPv6 address configurations.
    [Arguments]  ${ipv6_origin}  ${interface}=${ethernet_interface}

    # Description of argument(s):
    # ipv6_origin     Origin of IPv6 address eg. Static or DHCPv6 or SLAAC.
    # interface       VMI interface (eg. eth0 or eth1).

    ${resp}=  Redfish.Get  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}

    @{vmi_ipv6_configurations}=  Get From Dictionary  ${resp.dict}  IPv6Addresses
    ${vmi_ipv6_config}=  Get From List  ${vmi_ipv6_configurations}  0
    Should Not Be Empty  ${vmi_ipv6_config["Address"]}
    Should Be Equal As Strings   ${vmi_ipv6_config["AddressOrigin"]}  ${ipv6_origin}
    RETURN  &{vmi_ipv6_config}


Set VMI DHCPv6 Property
    [Documentation]  Set VMI DHCPv6 attribute.
    [Arguments]  ${dhcpv6_operatingmode}=${Disabled}  ${valid_status_code}=${HTTP_ACCEPTED}
    ...  ${interface}=${ethernet_interface}

    # Description of argument(s):
    # dhcpv6_operatingmode    Enabled if user wants to enable DHCPv6.
    # ...                     Default is Static, hence value is set to Disabled.
    # valid_status_code       Expected valid status code from PATCH request. Default is HTTP_OK.
    # interface               VMI interface (eg. eth0 or eth1).

    ${data}=  Set Variable If  '${dhcpv6_operatingmode}' == 'Disabled'  ${DISABLE_DHCPv6}  ${ENABLE_DHCPv6}
    ${resp}=  Redfish.Patch
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}
    ...  body=${data}  valid_status_codes=[${valid_status_code}]

    Sleep  ${wait_time}
    Return From Keyword If  ${valid_status_code} != ${HTTP_ACCEPTED}
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}
    Should Be Equal  ${resp.dict["DHCPv6"]["OperatingMode"]}  ${dhcpv6_operatingmode}


Set Static VMI IPv6 Address
    [Documentation]  Add static VMI IPv6 address.
    [Arguments]  ${vmi_ipv6_addr}  ${prefix_len}  ${valid_status_codes}=${HTTP_ACCEPTED}
    ...  ${interface}=${ethernet_interface}

    # Description of argument(s):
    # vmi_ipv6_addr       VMI IPv6 address to be added.
    # prefix_len          Prefix length for the VMI IPv6 to be added.
    # valid_status_codes  Expected valid status code from PATCH request.
    # interface           VMI interface (eg. eth0 or eth1).

    ${prefix_length}=  Convert To Integer  ${prefix_len}
    ${empty_dict}=  Create Dictionary
    ${vmi_ipv6_data}=  Create Dictionary  Address=${vmi_ipv6_addr}
    ...  PrefixLength=${prefix_length}

    ${patch_list}=  Create List

    Append To List  ${patch_list}  ${vmi_ipv6_data}
    ${data}=  Create Dictionary  IPv6StaticAddresses=${patch_list}

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Redfish.patch  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}
    ...  body=&{data}  valid_status_codes=[${valid_status_codes}]


Set VMI IPv6 Static Default Gateway
    [Documentation]  Set VMI IPv6 static default gateway address.
    [Arguments]  ${vmi_staticipv6_gateway}  ${valid_status_codes}=${HTTP_ACCEPTED}
    ...  ${interface}=${ethernet_interface}

    # Description of argument(s):
    # vmi_staticipv6_gateway   VMI static IPv6 default gateway address.
    # valid_status_codes       Expected valid status code from PATCH request.
    # interface                VMI interface (eg. eth0 or eth1).

    ${patch_list}=  Create List  ${vmi_staticipv6_gateway}
    ${data}=  Create Dictionary  IPv6StaticDefaultGateways=${patch_list}

    Redfish.patch  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}
    ...  body=&{data}  valid_status_codes=[${valid_status_codes}]


Delete VMI IPv6 Static Address
    [Documentation]  Delete VMI IPv6 static address.
    [Arguments]  ${valid_status_codes}=${HTTP_ACCEPTED}
    ...  ${interface}=${ethernet_interface}

    # Description of argument(s):
    # valid_status_codes       Expected valid status code from PATCH request.
    # interface                VMI interface (eg. eth0 or eth1).

    ${data}=  Set Variable  {"IPv6StaticAddresses": [${Null}]}
    Redfish.Patch  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}
    ...  body=${data}  valid_status_codes=[${valid_status_codes}]

    Sleep  5s
