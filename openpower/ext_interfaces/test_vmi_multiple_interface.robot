*** Settings ***

Documentation    VMI multiple network interface tests.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot
Resource         ../../lib/state_manager.robot
Library          ../../lib/bmc_network_utils.py

Suite Setup       Suite Setup Execution
Test Teardown     FFDC On Test Case Fail
Suite Teardown    Suite Teardown Execution

*** Variables ***

${test_ipv4_1}              10.6.6.6
${test_gateway_1}           10.6.6.1
${test_netmask_1}           255.255.252.0

${test_ipv4_2}              10.5.20.5
${test_gateway_2}           10.5.20.1
${test_netmask_2}           255.255.255.0

${wait_time}                10s

*** Test Cases ***

Configure VMI Both Interfaces In Same Subnet And Verify
    [Documentation]  Configure vmi both interfaces in same subnet and verify.
    [Tags]  Configure_VMI_Both_Interfaces_In_Same_Subnet_And_Verify
    [Teardown]   Test Teardown Execution

    Set Static IPv4 Address To VMI And Verify  ${test_ipv4_1}  ${test_gateway_1}
    ...  ${test_netmask_1}  ${interface_list}[0]
    Set Static IPv4 Address To VMI And Verify  ${test_ipv4_2}  ${test_gateway_2}
    ...  ${test_netmask_1}  ${interface_list}[1]


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test setup execution task.

    Redfish.Login
    Redfish Power On  stack_mode=skip  quiet=1
    Get VMI Interfaces

    FOR  ${interface}  IN   @{interface_list}
        ${resp}=  Redfish.Get
        ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}
        ${ip_resp}=  Evaluate  json.loads(r'''${resp.text}''')  json
        ${length}=  Get Length  ${ip_resp["IPv4StaticAddresses"]}
        ${vmi_network_conf}=  Catenate  SEPARATOR=_   vmi_network_conf  ${interface}
        ${vmi_network_conf_value}=  Run Keyword If  ${length} != ${0}
        ...  Get VMI Network Interface Details  ${interface}
       Set Suite Variable  ${${vmi_network_conf}}  ${vmi_network_conf_value}
    END

Get VMI Interfaces
    [Documentation]  Get VMI network interface.
    [Arguments]  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # valid_status_code  Expected valid status code from GET request.

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
    Set Suite Variable  @{interface_list}
    [Return]  @{interface_list}

Get VMI Network Interface Details
    [Documentation]  Get VMI network interface details.
    [Arguments]  ${ethernet_interface}  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # ethernet_interface  VMI ethernet interface.
    # valid_status_code   Expected valid status code from GET request.

    # Note: It returns a dictionary of VMI ethernet interface parameters.

    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
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

    [Return]  &{vmi_ip}

Verify VMI Network Interface Details
    [Documentation]  Verify VMI network interface details.
    [Arguments]  ${ip}  ${origin}  ${gateway}  ${netmask}  ${ethernet_interface}
    ...  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # ip                  VMI IPv4 address.
    # origin              Origin of IPv4 address eg. Static or DHCP.
    # gateway             Gateway for VMI IP.
    # netmask             Subnetmask for VMI IP.
    # ethernet_interface  VMI ethernet interface.
    # valid_status_code   Expected valid status code from GET request. Default is HTTP_OK.

    ${vmi_ip}=  Get VMI Network Interface Details  ${ethernet_interface}  ${valid_status_code}
    Should Be Equal As Strings  ${origin}  ${vmi_ip["IPv4_AddressOrigin"]}
    Should Be Equal As Strings  ${gateway}  ${vmi_ip["IPv4_Gateway"]}
    Should Be Equal As Strings  ${netmask}  ${vmi_ip["IPv4_SubnetMask"]}
    Should Be Equal As Strings  ${ip}  ${vmi_ip["IPv4_Address"]}


Set Static IPv4 Address To VMI And Verify
    [Documentation]  Set static IPv4 address to VMI.
    [Arguments]  ${ip}  ${gateway}  ${netmask}  ${ethernet_interface}
    ...  ${valid_status_code}=${HTTP_ACCEPTED}

    # Description of argument(s):
    # ip                  VMI IPv4 address.
    # gateway             Gateway for VMI IP.
    # netmask             Subnetmask for VMI IP.
    # ethernet_interface  VMI ethernet interface.
    # valid_status_code   Expected valid status code from GET request. Default is HTTP_ACCEPTED.

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
    ...  Verify VMI Network Interface Details  ${ip}  Static  ${gateway}  ${netmask}  ${ethernet_interface}

Delete VMI IPv4 Address
    [Documentation]  Delete VMI IPv4 address.
    [Arguments]  ${ethernet_interface}  ${delete_param}=IPv4StaticAddresses
    ...  ${valid_status_code}=${HTTP_ACCEPTED}

    # Description of argument(s):
    # delete_param        Parameter to be deleted eg. IPv4StaticAddresses or IPv4Addresses.
    #                     Default is IPv4StaticAddresses.
    # ethernet_interface  VMI ethernet interface.
    # valid_status_code   Expected valid status code from PATCH request. Default is HTTP_OK.

    ${data}=  Set Variable  {"${delete_param}": [${Null}]}
    ${active_channel_config}=  Get Active Channel Config
    ${resp}=  Redfish.Patch
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    ...  body=${data}  valid_status_codes=[${valid_status_code}]

    Return From Keyword If  ${valid_status_code} != ${HTTP_ACCEPTED}
    ${vmi_ip}=  Get VMI Network Interface Details  ${ethernet_interface}
    Should Be Empty  ${vmi_ip["IPv4_Address"]}

Test Teardown Execution
    [Documentation]  Do test teardown execution task.

    FOR  ${interface}  IN   @{interface_list}
        Delete VMI IPv4 Address  ${interface}
    END
    FFDC On Test Case Fail


Suite Teardown Execution
    [Documentation]  Do suit teardown execution task.

    FOR  ${interface}  IN   @{interface_list}
        Run Keyword If  ${vmi_network_conf_${interface}} != ${None}
        ...  Set Static IPv4 Address To VMI And Verify
        ...  ${vmi_network_conf_${interface}}[IPv4_Address]
        ...  ${vmi_network_conf_${interface}}[IPv4_Gateway]
        ...  ${vmi_network_conf_${interface}}[IPv4_SubnetMask]
        ...  ${interface}
    END
    Redfish.Logout
