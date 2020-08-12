*** Settings ***

Documentation    VMI static/dynamic IP config tests.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot
Library          ../../lib/bmc_network_utils.py

Suite Setup       Suite Setup Execution
Test Teardown     FFDC On Test Case Fail
Suite Teardown    Redfish.Logout

*** Variables ***

# users           User Name               password
@{ADMIN}          admin_user              TestPwd123
@{OPERATOR}       operator_user           TestPwd123
@{ReadOnly}       readonly_user           TestPwd123
@{NoAccess}       noaccess_user           TestPwd123
&{USERS}          Administrator=${ADMIN}  Operator=${OPERATOR}  ReadOnly=${ReadOnly}
...               NoAccess=${NoAccess}

${test_ipv4}              10.6.6.6
${test_gateway}           10.6.6.1
${test_netmask}           255.255.252.0

&{DHCP_ENABLED}           DHCPEnabled=${${True}}
&{DHCP_DISABLED}          DHCPEnabled=${${False}}

&{ENABLE_DHCP}            DHCPv4=&{DHCP_ENABLED}
&{DISABLE_DHCP}           DHCPv4=&{DHCP_DISABLED}
${wait_time}              10s


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
    Should Be Equal As Strings  ${vmi_ip["Description"]}
    ...  Ethernet Interface for Virtual Management Interface
    Should Be Equal As Strings  ${vmi_ip["Name"]}  Virtual Management Interface
    Should Be True  ${vmi_ip["InterfaceEnabled"]}


Delete Existing Static VMI IP Address
    [Documentation]  Delete existing static VMI IP address.
    [Tags]  Delete_Existing_Static_VMI_IP_Address

    ${curr_origin}=  Get Immediate Child Parameter From VMI Network Interface  DHCPEnabled
    Run Keyword If  ${curr_origin} == ${True}  Set VMI IPv4 Origin  ${False}  ${HTTP_ACCEPTED}

    Delete VMI IPv4 Address  IPv4StaticAddresses  valid_status_code=${HTTP_ACCEPTED}
    ${default}=  Set Variable  0.0.0.0
    Verify VMI Network Interface Details  ${default}  Static  ${default}  ${default}


Verify User Cannot Delete ReadOnly Property IPv4Addresses
    [Documentation]  Verify user cannot delete readonly property IPv4Addresses.
    [Tags]  Verify_User_Cannot_Delete_ReadOnly_Property_IPv4Addresses

    ${curr_origin}=  Get Immediate Child Parameter From VMI Network Interface  DHCPEnabled
    Run Keyword If  ${curr_origin} == ${False}  Set VMI IPv4 Origin  ${True}  ${HTTP_ACCEPTED}
    Delete VMI IPv4 Address  IPv4Addresses  valid_status_code=${HTTP_BAD_REQUEST}


Assign Valid And Invalid Static IPv4 Address To VMI
    [Documentation]  Assign static IPv4 address to VMI.
    [Tags]  Assign_Valid_And_Invalid_Static_IPv4_Address_To_VMI
    [Template]  Set Static IPv4 Address To VMI And Verify
    [Teardown]   Run keywords  Delete VMI IPv4 Address  AND  Test Teardown Execution

    # ip          gateway     netmask           valid_status_code
    10.5.20.30    0.0.0.0     255.255.252.0    ${HTTP_ACCEPTED}
    a.3.118.94    0.0.0.0     255.255.252.0    ${HTTP_BAD_REQUEST}


Add Multiple IP Addreses On VMI Interface And Verify
    [Documentation]  Add multiple IP addreses on VMI interface and verify.
    [Tags]  Add_Multiple_IP_Addreses_On_VMI_Interface_And_Verify
    [Teardown]   Run keywords  Delete VMI IPv4 Address  AND  Test Teardown Execution

    ${ip1}=  Create dictionary  Address=10.5.5.10  SubnetMask=255.255.252.0  Gateway=0.0.0.0
    ${ip2}=  Create dictionary  Address=10.5.5.11  SubnetMask=255.255.252.0  Gateway=0.0.0.0
    ${ip3}=  Create dictionary  Address=10.5.5.12  SubnetMask=255.255.252.0  Gateway=0.0.0.0
    ${ips}=  Create List  ${ip1}  ${ip2}  ${ip3}

    Redfish.Patch  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}
    ...  body={'IPv4StaticAddresses':${ips}}  valid_status_codes=[${HTTP_ACCEPTED}]
    Verify VMI Network Interface Details   ${ip1["Address"]}  Static  ${ip1["Gateway"]}  ${ip1["SubnetMask"]}


Modify IP Addresses On VMI Interface And Verify
    [Documentation]  Modify IP addresses on VMI interface and verify.
    [Tags]  Modify_IP_Addresses_On_VMI_Interface_And_Verify
    [Template]  Set Static IPv4 Address To VMI And Verify
    [Teardown]   Run keywords  Delete VMI IPv4 Address  AND  Test Teardown Execution

    # ip        gateway       netmask        valid_status_code
    10.5.5.10   0.0.0.0     255.255.252.0    ${HTTP_ACCEPTED}
    10.5.5.11   0.0.0.0     255.255.252.0    ${HTTP_ACCEPTED}

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
    Verify VMI Network Interface Details  ${default}  DHCP  ${default}  ${default}

    # Verifying persistency of static address.
    Switch VMI IPv4 Origin And Verify Details
    Set Static IPv4 Address To VMI And Verify  ${test_ipv4}  ${test_gateway}  ${test_netmask}


Delete VMI Static IP Address And Verify
    [Documentation]  Delete VMI static IP address and verify.
    [Tags]  Delete_VMI_Static_IP_Address_And_Verify
    [Teardown]  Test Teardown Execution

    Set Static IPv4 Address To VMI And Verify  ${test_ipv4}  ${test_gateway}  ${test_netmask}
    Delete VMI IPv4 Address
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}
    Should Be Empty  ${resp.dict["IPv4Addresses"]}


Verify Successful VMI IP Static Configuration On HOST Boot After Session Delete
    [Documentation]  Verify VMI IP static Configuration On HOST Boot After session deleted.
    [Tags]  Verify_Successful_VMI_IP_Static_Configuration_On_HOST_Boot_After_Session_Delete
    [Teardown]  Run keywords  Delete VMI IPv4 Address  IPv4Addresses  AND  Test Teardown Execution

    Set Static IPv4 Address To VMI  ${test_ipv4}  ${test_gateway}  ${test_netmask}

    ${session_info}=  Get Redfish Session Info
    Redfish.Delete  ${session_info["location"]}

    # Create a new Redfish session
    Redfish Power Off
    Redfish Power On

    Verify VMI Network Interface Details  ${test_ipv4}  Static  ${test_gateway}  ${test_netmask}


Verify Persistency Of VMI DHCP IP Configuration After Multiple HOST Reboots
    [Documentation]  Verify Persistency Of VMI DHCP IP configuration After Multiple HOST Reboots
    [Tags]  Verify_Persistency_Of_VMI_DHCP_IP_Configuration_After_Multiple_HOST_Reboots
    [Teardown]  Test Teardown Execution

    ${LOOP_COUNT}=  Set Variable  ${3}
    Set VMI IPv4 Origin  ${True}  ${HTTP_ACCEPTED}
    Run Keywords  Redfish Power Off  AND  Redfish Power On
    ${vmi_ip_config}=  Get VMI Network Interface Details
    # Verifying persistency of dynamic address after multiple reboots.
    Repeat Keyword  ${LOOP_COUNT} times
    ...  Verify VMI Network Interface Details  ${vmi_ip_config["IPv4_Address"]}  DHCP  ${vmi_ip_config["IPv4_Gateway"]}
    ...  ${vmi_ip_config["IPv4_SubnetMask"]}


Enable DHCP When Static IP Configured And Verify Static IP
    [Documentation]  Enable DHCP when static ip configured and verify static ip
    [Tags]  Enable_DHCP_when_Static_IP_Configured_And_Verify_Static_IP
    [Teardown]  Test Teardown Execution

    Verify Assigning Static IPv4 Address To VMI  ${test_ipv4}  ${test_gateway}  ${test_netmask}
    Set VMI IPv4 Origin  ${True}
    ${vmi_network_conf}=  Get VMI Network Interface Details
    Should Not Be Equal As Strings  ${test_ipv4}  ${vmi_network_conf["IPv4_Address"]}


Verify VMI Static IP Configuration Persist On BMC Reset Before Host Boot
    [Documentation]  Verify VMI static IP configuration persist on BMC reset.
    [Tags]   Verify_VMI_Static_IP_Configuration_Persist_On_BMC_Reset_Before_Host_Boot
    [Teardown]  Run keywords  Delete VMI IPv4 Address  AND  FFDC On Test Case Fail

    Set Static IPv4 Address To VMI  ${test_ipv4}  ${test_gateway}  ${test_netmask}
    OBMC Reboot (off)
    Redfish Power On
    # Verifying the VMI static configuration
    Verify VMI Network Interface Details  ${test_ipv4}  Static   ${test_gateway}  ${test_netmask}


Verify To Configure VMI Static IP Address With Different User Roles
    [Documentation]  Verify to configure vmi static ip address with different user roles.
    [Tags]  Verify_To_Configure_VMI_Static_IP_Address_With_Different_User_Roles
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Config VMI Static IP Address Using Different Users
    [Teardown]  Delete BMC Users Using Redfish

    # username     password    ip_address    gateway          nemask           valid_status_code
    admin_user     TestPwd123  ${test_ipv4}  ${test_gateway}  ${test_netmask}  ${HTTP_ACCEPTED}
    operator_user  TestPwd123  ${test_ipv4}  ${test_gateway}  ${test_netmask}  ${HTTP_FORBIDDEN}
    readonly_user  TestPwd123  ${test_ipv4}  ${test_gateway}  ${test_netmask}  ${HTTP_FORBIDDEN}
    noaccess_user  TestPwd123  ${test_ipv4}  ${test_gateway}  ${test_netmask}  ${HTTP_FORBIDDEN}


Verify To Delete VMI Static IP Address With Different User Roles
    [Documentation]  Verify to delete vmi static IP address with different user roles.
    [Tags]  Verify_To_Delete_VMI_Static_IP_Address_With_Different_User_Roles
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Delete VMI Static IP Address Using Different Users
    [Teardown]  Delete BMC Users Using Redfish

    # username     password     valid_status_code
    admin_user     TestPwd123   ${HTTP_ACCEPTED}
    operator_user  TestPwd123   ${HTTP_FORBIDDEN}
    readonly_user  TestPwd123   ${HTTP_FORBIDDEN}
    noaccess_user  TestPwd123   ${HTTP_FORBIDDEN}


Verify To Update VMI Static IP Address With Different User Roles
    [Documentation]  Verify to update vmi static IP address with different user roles.
    [Tags]  Verify_To_Update_VMI_Static_IP_Address_With_Different_User_Roles_And_Verify
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Config VMI Static IP Address Using Different Users
    [Teardown]  Delete BMC Users Using Redfish

    # username     password     ip_address  gateway  nemask       valid_status_code
    admin_user     TestPwd123   10.5.10.20  0.0.0.0  255.255.0.0  ${HTTP_ACCEPTED}
    operator_user  TestPwd123   10.5.10.30  0.0.0.0  255.255.0.0  ${HTTP_FORBIDDEN}
    readonly_user  TestPwd123   10.5.20.40  0.0.0.0  255.255.0.0  ${HTTP_FORBIDDEN}
    noaccess_user  TestPwd123   10.5.30.50  0.0.0.0  255.255.0.0  ${HTTP_FORBIDDEN}


Verify To Read VMI Network Configuration With Different User Roles
    [Documentation]  Verify to read vmi network configuration with different user roles.
    [Tags]  Verify_To_Read_VMI_Network_Configuration_Via_Different_User_Roles
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Read VMI Static IP Address Using Different Users
    [Teardown]  Delete BMC Users Using Redfish

    # username     password     valid_status_code
    admin_user     TestPwd123   ${HTTP_OK}
    operator_user  TestPwd123   ${HTTP_OK}
    readonly_user  TestPwd123   ${HTTP_OK}
    noaccess_user  TestPwd123   ${HTTP_FORBIDDEN}


Enable And Disable DHCP And Verify
    [Documentation]  verify enable DHCP and disable DHCP.
    [Tags]  Enabled_And_Disabled_DHCP_Verify

    Set VMI IPv4 Origin  ${True}
    ${default}=  Set Variable  0.0.0.0
    Verify VMI Network Interface Details  ${default}  DHCP  ${default}  ${default}
    Set VMI IPv4 Origin  ${False}
    Verify VMI Network Interface Details  ${default}  Static  ${default}  ${default}


Multiple Times Enable And Disable DHCP And Verify
    [Documentation]  Enable and Disable DHCP in a loop and verify VMI gets an IP address from DHCP
    ...  each time when DHCP is enabled
    [Tags]  Multiple_Times_Enable_And_Disable_DHCP_And_Verify

    ${default}=  Set Variable  0.0.0.0
    FOR  ${i}  IN RANGE  ${2}
      Set VMI IPv4 Origin  ${True}
      Verify VMI Network Interface Details  ${default}  DHCP  ${default}  ${default}
      Set VMI IPv4 Origin  ${False}
      Verify VMI Network Interface Details  ${default}  Static  ${default}  ${default}
    END


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test setup execution task.

    Redfish.Login
    Redfish Power On
    ${active_channel_config}=  Get Active Channel Config
    Set Suite Variable   ${active_channel_config}
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}
    ${ip_resp}=  Evaluate  json.loads('''${resp.text}''')  json
    ${length}=  Get Length  ${ip_resp["IPv4StaticAddresses"]}
    ${vmi_network_conf}=  Run Keyword If  ${length} != ${0}  Get VMI Network Interface Details
    Set Suite Variable  ${vmi_network_conf}


Test Teardown Execution
    [Documentation]  Do test teardown execution task.

    FFDC On Test Case Fail
    ${curr_mode}=  Get Immediate Child Parameter From VMI Network Interface  DHCPEnabled
    Run Keyword If  ${curr_mode} == ${True}  Set VMI IPv4 Origin  ${False}
    Run Keyword If  ${vmi_network_conf} != ${None}
    ...  Verify Assigning Static IPv4 Address To VMI  ${vmi_network_conf["IPv4_Address"]}
    ...  ${vmi_network_conf["IPv4_Gateway"]}  ${vmi_network_conf["IPv4_SubnetMask"]}


Get VMI Network Interface Details
    [Documentation]  Get VMI network interface details.
    [Arguments]  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # valid_status_code  Expected valid status code from GET request.

    # Note: It returns a dictionary of VMI eth0 parameters.

    ${active_channel_config}=  Get Active Channel Config
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}
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
    ...  IPv4_SubnetMask=${ip_resp["IPv4Addresses"][0]["SubnetMask"]}
    ...  IPv4StaticAddresses=${${static_exists}}

    [Return]  &{vmi_ip}


Get Immediate Child Parameter From VMI Network Interface
    [Documentation]  Get immediate child parameter from VMI network interface.
    [Arguments]  ${parameter}  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # parameter          parameter for which value is required. Ex: DHCPEnabled, MACAddress etc.
    # valid_status_code  Expected valid status code from GET request.

    ${active_channel_config}=  Get Active Channel Config
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}
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
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/eth0
    Should Be Equal As Strings  ${interfaces[1]}[@odata.id]
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/eth1

    Should Be Equal  ${resp["Members@odata.count"]}  ${2}


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

    ${active_channel_config}=  Get Active Channel Config
    ${resp}=  Redfish.Patch
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}
    ...  body=${data}  valid_status_codes=[${valid_status_code}]

    # Wait few seconds for new configuration to get populated on runtime.
    Sleep  ${wait_time}

    Return From Keyword If  ${valid_status_code} != ${HTTP_ACCEPTED}
    Verify VMI Network Interface Details  ${ip}  Static  ${gateway}  ${netmask}


Delete VMI IPv4 Address
    [Documentation]  Delete VMI IPv4 address.
    [Arguments]  ${delete_param}=IPv4StaticAddresses  ${valid_status_code}=${HTTP_ACCEPTED}

    # Description of argument(s):
    # delete_param       Parameter to be deleted eg. IPv4StaticAddresses or IPv4Addresses.
    #                    Default is IPv4StaticAddresses.
    # valid_status_code  Expected valid status code from PATCH request. Default is HTTP_OK.

    ${data}=  Set Variable  {"${delete_param}": [${Null}]}
    ${active_channel_config}=  Get Active Channel Config
    ${resp}=  Redfish.Patch
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}
    ...  body=${data}  valid_status_codes=[${valid_status_code}]

    Return From Keyword If  ${valid_status_code} != ${HTTP_ACCEPTED}
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}
    Should Be Empty  ${resp.dict["IPv4StaticAddresses"]}


Set VMI IPv4 Origin
    [Documentation]  Set VMI IPv4 origin.
    [Arguments]  ${dhcp_enabled}=${False}  ${valid_status_code}=${HTTP_ACCEPTED}

    # Description of argument(s):
    # dhcp_enabled       True if user wants to enable DHCP. Default is Static, hence value is set to False.
    # valid_status_code  Expected valid status code from PATCH request. Default is HTTP_OK.

    ${data}=  Set Variable If  ${dhcp_enabled} == ${False}  ${DISABLE_DHCP}  ${ENABLE_DHCP}
    ${resp}=  Redfish.Patch  /redfish/v1/Systems/hypervisor/EthernetInterfaces/eth0  body=${data}
    ...  valid_status_codes=[${valid_status_code}]

    Return From Keyword If  ${valid_status_code} != ${HTTP_ACCEPTED}
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}
    Should Be Equal  ${resp.dict["DHCPv4"]["DHCPEnabled"]}  ${dhcp_enabled}


Switch VMI IPv4 Origin And Verify Details
    [Documentation]  Switch VMI IPv4 origin and verify details.

    ${curr_mode}=  Get Immediate Child Parameter From VMI Network Interface  DHCPEnabled
    ${dhcp_enabled}=  Set Variable If  ${curr_mode} == ${False}  ${True}  ${False}

    ${default}=  Set Variable  0.0.0.0
    ${origin}=  Set Variable If  ${curr_mode} == ${False}  DHCP  Static
    Set VMI IPv4 Origin  ${dhcp_enabled}  ${HTTP_ACCEPTED}
    Verify VMI Network Interface Details  ${default}  ${origin}  ${default}  ${default}


Delete VMI Static IP Address Using Different Users
    [Documentation]  Update user role and delete vmi static IP address.
    [Arguments]  ${username}  ${password}  ${valid_status_code}
    [Teardown]  Run Keywords  Redfish.Login  AND
    ...  Verify Assigning Static IPv4 Address To VMI  ${test_ipv4}  ${test_gateway}
    ...  ${test_netmask}  ${HTTP_ACCEPTED}  AND  Redfish.Logout

    # Description of argument(s):
    # username            The host username.
    # password            The host password.
    # valid_status_code   The expected valid status code.

    Redfish.Login  ${username}  ${password}
    Delete VMI IPv4 Address  delete_param=IPv4StaticAddresses  valid_status_code=${valid_status_code}
    Redfish.Logout


Config VMI Static IP Address Using Different Users
   [Documentation]  Update user role and update vmi static ip address.
   [Arguments]  ${username}  ${password}  ${ip}  ${gateway}  ${netmask}
   ...  ${valid_status_code}

    # Description of argument(s):
    # username            The host username.
    # password            The host password.
    # ip                  IP address to be added (e.g. "10.7.7.7").
    # subnet_mask         Subnet mask for the IP to be added
    #                     (e.g. "255.255.0.0").
    # gateway             Gateway for the IP to be added (e.g. "10.7.7.1").
    # valid_status_code   The expected valid status code.

    Redfish.Login  ${username}  ${password}
    Set Static IPv4 Address To VMI And Verify  ${ip}  ${gateway}  ${netmask}  ${valid_status_code}
    Redfish.Logout


Read VMI Static IP Address Using Different Users
   [Documentation]  Update user role and read vmi static ip address.
   [Arguments]  ${username}  ${password}  ${valid_status_code}

    # Description of argument(s):
    # username            The host username.
    # password            The host password.
    # valid_status_code   The expected valid status code.

    Redfish.Login  ${username}  ${password}
    Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}
    ...  valid_status_codes=[${valid_status_code}]
    Redfish.Logout


Delete BMC Users Using Redfish
   [Documentation]  Delete BMC users via redfish.

   Redfish.Login
   Delete BMC Users Via Redfish  users=${USERS}
