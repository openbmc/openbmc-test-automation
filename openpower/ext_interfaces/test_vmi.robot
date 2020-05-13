*** Settings ***

Documentation    VMI static/dynamic IP config and certificate exchange tests.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Suite Setup       Redfish.Login
Test Teardown     FFDC On Test Case Fail
Suite Teardown    Redfish.Logout

*** Variables ***

&{DHCP_ENABLED}           DHCPEnabled=${${True}}
&{DHCP_DISABLED}          DHCPEnabled=${${False}}

&{ENABLE_DHCP}            DHCPv4=&{DHCP_ENABLED}
&{DISABLE_DHCP}           DHCPv4=&{DHCP_DISABLED}


*** Test Cases ***

Verify All VMI EthernetInterfaces
    [Documentation]  Verify all VMI ethernet interfaces.
    [Tags]  Verify_All_VMI_EthernetINterfaces

    Verify VMI EthernetInterfaces


Verify Existing VMI Network Interface Details
    [Documentation]  Verify existing VMI network interface details.
    [Tags]  Verify_VMI_Network_Interface_Details

    ${vmi_ip}=  Get VMI Network Interface Details
    ${origin}=  Set Variable If  ${vmi_ip["DHCPv4"]} == ${False}  Static  DHCP

    Should Not Be Equal  ${vmi_ip["DHCPv4"]}  ${vmi_ip["IPv4StaticAddresses"]}
    Should Be Equal As Strings  ${origin}  ${vmi_ip["IPv4_AddressOrigin"]}
    Should Be Equal As Strings  ${vmi_ip["Id"]}  intf0
    Should Be Equal As Strings  ${vmi_ip["Description"]}  Virtual Interface Management Network Interface
    Should Be Equal As Strings  ${vmi_ip["Name"]}  Virtual Management Ethernet Interface
    Should Be True  ${vmi_ip["InterfaceEnabled"]}


Delete Existing Static VMI IP Address
    [Documentation]  Delete existing static VMI IP address.
    [Tags]  Delete_Existing_Static_VMI_IP_Address

    ${curr_origin}=  Get Immediate Child Parameter From VMI Network Interface  DHCPEnabled
    Run Keyword If  ${curr_origin} == ${True}  Set VMI IPv4 Origin  ${False}  ${HTTP_ACCEPTED}

    Delete VMI IPv4 Address  IPv4StaticAddresses  valid_status_code=${HTTP_ACCEPTED}
    ${default}=  Set Variable  0.0.0.0
    Verify VMI Network Interface Details  ${default}  Static  ${default}  ${default}  ${True}


Verify User Cannot Delete ReadOnly Property IPv4Addresses
    [Documentation]  Verify user cannot delete readonly property IPv4Addresses.
    [Tags]  Verify_User_Cannot_Delete_ReadOnly_Property_IPv4Addresses

    ${curr_origin}=  Get Immediate Child Parameter From VMI Network Interface  DHCPEnabled
    Run Keyword If  ${curr_origin} == ${False}  Set VMI IPv4 Origin  ${True}  ${HTTP_ACCEPTED}
    Delete VMI IPv4 Address  IPv4Addresses  valid_status_code=${HTTP_BAD_REQUEST}


Assign Static IPv4 Address To VMI
    [Documentation]  Assign static IPv4 address to VMI.
    [Tags]  Assign_Static_IPv4_Address_To_VMI
    [Template]  Verify Assigning Static IPv4 Address To VMI

    # ip          gateway         netmask         del_curr_ip  host_reboot  valid_status_code
    ${VMI_IP}     ${VMI_GATEWAY}  ${VMI_NETMASK}  ${False}     ${True}      ${HTTP_ACCEPTED}
    a.3.118.94    ${VMI_GATEWAY}  ${VMI_NETMASK}  ${False}     ${False}     ${HTTP_BAD_REQUEST}
    10.118.94     10.118.3.Z      ${VMI_NETMASK}  ${False}     ${False}     ${HTTP_BAD_REQUEST}


Switch Between IP Origins On VMI And Verify Details
    [Documentation]  Switch between IP origins on VMI and verify details.
    [Tags]  Switch_Between_IP_Origins_On_VMI_And_Verify_Details

    Switch VMI IPv4 Origin And Verify Details
    Switch VMI IPv4 Origin And Verify Details


Verify Persistency Of VMI IPv4 Details After Host Reboot
    [Documentation]  Verify persistency of VMI IPv4 details after host reboot.
    [Tags]  Verify_Persistency_Of_VMI_IPv4_Details_After_Host_Reboot

    # Verifying persistency of dynamic address.
    Set VMI IPv4 Origin  ${True}  ${HTTP_ACCEPTED}
    ${default}=  Set Variable  0.0.0.0
    Verify VMI Network Interface Details  ${default}  DHCP  ${default}  ${default}  ${True}
    Verify VMI Network Interface Details  ${default}  DHCP  ${default}  ${default}  ${True}

    # Verifying persistency of static address.
    Switch VMI IPv4 Origin And Verify Details  ${True}
    Verify Assigning Static IPv4 Address To VMI  ${VMI_IP}  ${VMI_GATEWAY}  ${VMI_NETMASK}  ${False}
    Verify VMI Network Interface Details  ${VMI_IP}  Static  ${VMI_GATEWAY}  ${VMI_NETMASK}  ${True}


*** Keywords ***

Get VMI Network Interface Details
    [Documentation]  Get VMI network interface details.
    [Arguments]  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # valid_status_code  Expected valid status code from GET request.

    # Note: It returns a dictionary of VMI intf0 parameters.

    ${resp}=  Redfish.Get  /redfish/v1/Systems/hypervisor/EthernetInterfaces/intf0
    ...  valid_status_codes=[${valid_status_code}]

    ${ip_resp}=  Evaluate  json.loads('''${resp.text}''')  json

    ${static_exists}=  Run Keyword And Ignore Error
    ...  Set Variable  ${ip_resp["IPv4StaticAddresses"][0]["Address"]}
    ${static_exists}=  Set Variable If  '${static_exists[0]}' == 'PASS'  ${True}  ${False}

    ${vmi_ip}=  Create Dictionary  DHCPv4=${${ip_resp["DHCPv4"]["DHCPEnabled"]}}  Id=${ip_resp["Id"]}
    ...  Description=${ip_resp["Description"]}  IPv4_Address=${ip_resp["IPv4Addresses"][0]["Address"]}
    ...  IPv4_AddressOrigin=${ip_resp["IPv4Addresses"][0]["AddressOrigin"]}  Name=${ip_resp["Name"]}
    ...  IPv4_Gateway=${ip_resp["IPv4Addresses"][0]["Gateway"]}
    ...  InterfaceEnabled=${${ip_resp["InterfaceEnabled"]}}
    ...  IPv4_SubnetMask=${ip_resp["IPv4Addresses"][0]["SubnetMask"]}  MACAddress=${ip_resp["MACAddress"]}
    ...  IPv4StaticAddresses=${${static_exists}}

    [Return]  &{vmi_ip}


Get Immediate Child Parameter From VMI Network Interface
    [Documentation]  Get immediate child parameter from VMI network interface.
    [Arguments]  ${parameter}  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # parameter          parameter for which value is required. Ex: DHCPEnabled, MACAddress etc.
    # valid_status_code  Expected valid status code from GET request.

    ${resp}=  Redfish.Get  /redfish/v1/Systems/hypervisor/EthernetInterfaces/intf0
    ...  valid_status_codes=[${valid_status_code}]

    ${ip_resp}=  Evaluate  json.loads('''${resp.text}''')  json
    ${value}=  Set Variable If  '${parameter}' != 'DHCPEnabled'   ${ip_resp["${parameter}"]}
    ...  ${ip_resp["DHCPv4"]["${parameter}"]}

    [Return]  ${value}


Verify VMI EthernetInterfaces
    [Documentation]  Verify VMI ethernet interfaces.
    [Arguments]  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # valid_status_code  Expected valid status code from GET request.

    ${resp}=  Redfish.Get  /redfish/v1/Systems/hypervisor/EthernetInterfaces
    ...  valid_status_codes=[${valid_status_code}]

    ${resp}=  Evaluate  json.loads('''${resp.text}''')  json
    ${interfaces}=  Set Variable  ${resp["Members"]}

    Should Be Equal As Strings  ${interfaces[0]}[@odata.id]
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/intf0
    Should Be Equal As Strings  ${interfaces[1]}[@odata.id]
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/intf1

    Should Be Equal  ${resp["Members@odata.count"]}  ${2}


Verify VMI Network Interface Details
    [Documentation]  Verify VMI network interface details.
    [Arguments]  ${ip}  ${origin}  ${gateway}  ${netmask}
    ...  ${host_reboot}=${False}  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # ip                 VMI IPv4 address.
    # origin             Origin of IPv4 address eg. Static or DHCP.
    # gateway            Gateway for VMI IP.
    # netmask            Subnetmask for VMI IP.
    # valid_status_code  Expected valid status code from GET request. Default is HTTP_OK.
    # host_reboot        Reboot HOST if True.

    Run Keyword If  ${host_reboot} == ${True}  Run Keywords
    ...  Redfish Power Off  AND  Redfish Power On  AND  Redfish.Login

    ${vmi_ip}=  Get VMI Network Interface Details  ${valid_status_code}
    Should Be Equal As Strings  ${origin}  ${vmi_ip["IPv4_AddressOrigin"]}
    Should Be Equal As Strings  ${gateway}  ${vmi_ip["IPv4_Gateway"]}
    Should Be Equal As Strings  ${netmask}  ${vmi_ip["IPv4_SubnetMask"]}

    Return From Keyword If  '${origin}' == 'DHCP'
    Should Be Equal As Strings  ${ip}  ${vmi_ip["IPv4_Address"]}


Set Static IPv4 Address To VMI
    [Documentation]  Set static IPv4 address to VMI.
    [Arguments]  ${ip}  ${gateway}  ${netmask}  ${valid_status_code}=${HTTP_ACCEPTED}

    # Description of argument(s):
    # ip                 VMI IPv4 address.
    # gateway            Gateway for VMI IP.
    # netmask            Subnetmask for VMI IP.
    # valid_status_code  Expected valid status code from GET request. Default is HTTP_ACCEPTED.

    ${data}=  Set Variable
    ...  {"IPv4StaticAddresses": [{"Address": "${ip}","SubnetMask": "${netmask}","Gateway": "${gateway}"}]}

    ${resp}=  Redfish.Patch  /redfish/v1/Systems/hypervisor/EthernetInterfaces/intf0  body=${data}
    ...  valid_status_codes=[${valid_status_code}]
    Redfish Power On  stack_mode=skip
    Log To Console  ${resp.text}


Verify Assigning Static IPv4 Address To VMI
    [Documentation]    Verify assigning static IPv4 address to VMI.
    [Arguments]  ${ip}  ${gateway}  ${netmask}  ${del_curr_ip}=${True}  ${host_reboot}=${True}
    ...  ${valid_status_code}=${HTTP_ACCEPTED}

    # Description of argument(s):
    # ip                 VMI IPv4 address.
    # gateway            Gateway for VMI IP.
    # netmask            Subnetmask for VMI IP.
    # del_curr_ip        Delete current VMI static IP if True.
    # host_reboot        True when HOST reboot is required.
    # valid_status_code  Expected valid status code from GET request. Default is HTTP_ACCEPTED.

    # Delete current static IP based on user input.
    ${curr_origin}=  Get Immediate Child Parameter From VMI Network Interface  DHCPEnabled
    Run Keyword If  ${curr_origin} == ${False} and ${del_curr_ip} == ${True}  Delete VMI IPv4 Address

    Set Static IPv4 Address To VMI  ${ip}  ${gateway}  ${netmask}  valid_status_code=${valid_status_code}
    Return From Keyword If  ${valid_status_code} != ${HTTP_ACCEPTED}

    Verify VMI Network Interface Details  ${ip}  Static  ${gateway}  ${netmask}  host_reboot=${host_reboot}


Delete VMI IPv4 Address
    [Documentation]  Delete VMI IPv4 address.
    [Arguments]  ${delete_param}=IPv4StaticAddresses  ${valid_status_code}=${HTTP_ACCEPTED}

    # Description of argument(s):
    # delete_param       Parameter to be deleted eg. IPv4StaticAddresses or IPv4Addresses.
    #                    Default is IPv4StaticAddresses.
    # valid_status_code  Expected valid status code from PATCH request. Default is HTTP_OK.

    ${data}=  Set Variable  {"${delete_param}": [${Null}]}
    ${resp}=  Redfish.Patch  /redfish/v1/Systems/hypervisor/EthernetInterfaces/intf0  body=${data}
    ...  valid_status_codes=[${valid_status_code}]


Set VMI IPv4 Origin
    [Documentation]  Set VMI IPv4 origin.
    [Arguments]  ${dhcp_enabled}=${False}  ${valid_status_code}=${HTTP_ACCEPTED}

    # Description of argument(s):
    # dhcp_enabled       True if user wants to enable DHCP. Default is Static, hence value is set to False.
    # valid_status_code  Expected valid status code from PATCH request. Default is HTTP_OK.

    ${data}=  Set Variable If  ${dhcp_enabled} == ${False}  ${DISABLE_DHCP}  ${ENABLE_DHCP}
    ${resp}=  Redfish.Patch  /redfish/v1/Systems/hypervisor/EthernetInterfaces/intf0  body=${data}
    ...  valid_status_codes=[${valid_status_code}]


Switch VMI IPv4 Origin And Verify Details
    [Documentation]  Switch VMI IPv4 origin and verify details.
    [Arguments]  ${host_reboot}=${False}

    # Description of argument(s):
    # host_reboot        Reboot HOST if True.

    ${curr_mode}=  Get Immediate Child Parameter From VMI Network Interface  DHCPEnabled
    ${dhcp_enabled}=  Set Variable If  ${curr_mode} == ${False}  ${True}  ${False}

    ${default}=  Set Variable  0.0.0.0
    ${origin}=  Set Variable If  ${curr_mode} == ${False}  DHCP  Static
    Set VMI IPv4 Origin  ${dhcp_enabled}  ${HTTP_ACCEPTED}
    Verify VMI Network Interface Details  ${default}  ${origin}  ${default}  ${default}  ${host_reboot}

    [Return]  ${origin}
