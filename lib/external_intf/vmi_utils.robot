*** Settings ***

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot
Resource         ../../lib/state_manager.robot
Library          ../../lib/bmc_network_utils.py

*** Variables ***

*** Keywords ***
Set Static IPv4 Address To VMI And Verify
    [Documentation]  Set static IPv4 address to VMI.
    [Arguments]  ${ip}  ${gateway}  ${netmask}  ${valid_status_code}=${HTTP_ACCEPTED}

    # Description of argument(s):
    # ip                 VMI IPv4 address.
    # gateway            Gateway for VMI IP.
    # netmask            Subnetmask for VMI IP.
    # valid_status_code  Expected valid status code from GET request. Default is HTTP_ACCEPTED.

    ${data}=  Set Variable
    ...  {"IPv4StaticAddresses": [{"Address": "${ip}","SubnetMask": "${netmask}","Gateway": "${gateway}"}]}

    ${resp}=  Redfish.Patch
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    ...  body=${data}  valid_status_codes=[${valid_status_code}]

    # Wait few seconds for new configuration to get populated on runtime.
    Sleep  ${wait_time}

    Return From Keyword If  ${valid_status_code} != ${HTTP_ACCEPTED}
    ${host_power_state}  ${host_state}=   Redfish Get Host State
    Run Keyword If  '${host_power_state}' == 'On' and '${host_state}' == 'Enabled'
    ...  Verify VMI Network Interface Details  ${ip}  Static  ${gateway}  ${netmask}

Verify VMI Network Interface Details
    [Documentation]  Verify VMI network interface details.
    [Arguments]  ${ip}  ${origin}  ${gateway}  ${netmask}
    ...  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # ip                 VMI IPv4 address.
    # origin             Origin of IPv4 address eg. Static or DHCP.
    # gateway            Gateway for VMI IP.
    # netmask            Subnetmask for VMI IP.
    # valid_status_code  Expected valid status code from GET request. Default is HTTP_OK.

    ${vmi_ip}=  Get VMI Network Interface Details  ${valid_status_code}
    Should Be Equal As Strings  ${origin}  ${vmi_ip["IPv4_AddressOrigin"]}
    Should Be Equal As Strings  ${gateway}  ${vmi_ip["IPv4_Gateway"]}
    Should Be Equal As Strings  ${netmask}  ${vmi_ip["IPv4_SubnetMask"]}
    Should Be Equal As Strings  ${ip}  ${vmi_ip["IPv4_Address"]}

Delete VMI IPv4 Address
    [Documentation]  Delete VMI IPv4 address.
    [Arguments]  ${delete_param}=IPv4StaticAddresses  ${valid_status_code}=${HTTP_ACCEPTED}

    # Description of argument(s):
    # delete_param       Parameter to be deleted eg. IPv4StaticAddresses or IPv4Addresses.
    #                    Default is IPv4StaticAddresses.
    # valid_status_code  Expected valid status code from PATCH request. Default is HTTP_OK.

    ${data}=  Set Variable  {"${delete_param}": [${Null}]}
    ${resp}=  Redfish.Patch
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    ...  body=${data}  valid_status_codes=[${valid_status_code}]

    Return From Keyword If  ${valid_status_code} != ${HTTP_ACCEPTED}
    ${vmi_ip}=  Get VMI Network Interface Details
    Should Be Empty  ${vmi_ip["IPv4_Address"]}


Set VMI IPv4 Origin
    [Documentation]  Set VMI IPv4 origin.
    [Arguments]  ${dhcp_enabled}=${False}  ${valid_status_code}=${HTTP_ACCEPTED}

    # Description of argument(s):
    # dhcp_enabled       True if user wants to enable DHCP. Default is Static, hence value is set to False.
    # valid_status_code  Expected valid status code from PATCH request. Default is HTTP_OK.

    ${data}=  Set Variable If  ${dhcp_enabled} == ${False}  ${DISABLE_DHCP}  ${ENABLE_DHCP}
    ${resp}=  Redfish.Patch  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}  body=${data}
    ...  valid_status_codes=[${valid_status_code}]

    Sleep  ${wait_time}
    Return From Keyword If  ${valid_status_code} != ${HTTP_ACCEPTED}
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    Should Be Equal  ${resp.dict["DHCPv4"]["DHCPEnabled"]}  ${dhcp_enabled}
