*** Settings ***

Documentation    VMI static/dynamic IP config tests.

Resource         ../../lib/external_intf/vmi_utils.robot

Suite Setup       Suite Setup Execution
Test Teardown     FFDC On Test Case Fail
Suite Teardown    Suite Teardown Execution

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
    [Tags]  Verify_All_VMI_EthernetInterfaces

    Verify VMI EthernetInterfaces


Verify Existing VMI Network Interface Details
    [Documentation]  Verify existing VMI network interface details.
    [Tags]  Verify_Existing_VMI_Network_Interface_Details

    ${vmi_ip}=  Get VMI Network Interface Details
    ${origin}=  Set Variable If  ${vmi_ip["DHCPv4"]} == ${False}  Static  DHCP
    Should Not Be Equal  ${vmi_ip["DHCPv4"]}  ${vmi_ip["IPv4StaticAddresses"]}
    Should Be Equal As Strings  ${vmi_ip["Id"]}  ${ethernet_interface}
    Should Be Equal As Strings  ${vmi_ip["Description"]}
    ...  Hypervisor's Virtual Management Ethernet Interface
    Should Be Equal As Strings  ${vmi_ip["Name"]}  Hypervisor Ethernet Interface
    Should Be True  ${vmi_ip["InterfaceEnabled"]}
    Run Keyword If   ${vmi_ip["IPv4StaticAddresses"]} != @{empty}
    ...  Verify VMI Network Interface Details  ${vmi_ip["IPv4_Address"]}
    ...  ${origin}  ${vmi_ip["IPv4_Gateway"]}  ${vmi_ip["IPv4_SubnetMask"]}


Delete Existing Static VMI IP Address
    [Documentation]  Delete existing static VMI IP address.
    [Tags]  Delete_Existing_Static_VMI_IP_Address

    ${curr_origin}=  Get Immediate Child Parameter From VMI Network Interface  DHCPEnabled
    Run Keyword If  ${curr_origin} == ${True}  Set VMI IPv4 Origin  ${False}  ${HTTP_ACCEPTED}

    Delete VMI IPv4 Address


Verify User Cannot Delete ReadOnly Property IPv4Addresses
    [Documentation]  Verify user cannot delete readonly property IPv4Addresses.
    [Tags]  Verify_User_Cannot_Delete_ReadOnly_Property_IPv4Addresses

    ${curr_origin}=  Get Immediate Child Parameter From VMI Network Interface  DHCPEnabled
    Run Keyword If  ${curr_origin} == ${True}  Set VMI IPv4 Origin  ${False}  ${HTTP_ACCEPTED}
    Set Static IPv4 Address To VMI And Verify  ${test_ipv4}  ${test_gateway}  ${test_netmask}
    Delete VMI IPv4 Address  IPv4Addresses  valid_status_code=${HTTP_FORBIDDEN}


Assign Valid And Invalid Static IPv4 Address To VMI
    [Documentation]  Assign static IPv4 address to VMI.
    [Tags]  Assign_Valid_And_Invalid_Static_IPv4_Address_To_VMI
    [Template]  Set Static IPv4 Address To VMI And Verify
    [Teardown]   Run keywords  Delete VMI IPv4 Address  AND  Test Teardown Execution

    # ip          gateway     netmask           valid_status_code
    10.5.20.30    10.5.20.1     255.255.252.0    ${HTTP_ACCEPTED}
    a.3.118.94    10.5.20.1     255.255.252.0    ${HTTP_BAD_REQUEST}
    10.5.20       10.5.20.1     255.255.252.0    ${HTTP_BAD_REQUEST}
    10.5.20.-5    10.5.20.1     255.255.252.0    ${HTTP_BAD_REQUEST}


Add Multiple IP Addresses On VMI Interface And Verify
    [Documentation]  Add multiple IP addresses on VMI interface and verify.
    [Tags]  Add_Multiple_IP_Addresses_On_VMI_Interface_And_Verify
    [Teardown]   Run keywords  Delete VMI IPv4 Address  AND  Test Teardown Execution

    ${ip1}=  Create dictionary  Address=10.5.5.10  SubnetMask=255.255.252.0  Gateway=10.5.5.1
    ${ip2}=  Create dictionary  Address=10.5.5.11  SubnetMask=255.255.252.0  Gateway=10.5.5.1
    ${ip3}=  Create dictionary  Address=10.5.5.12  SubnetMask=255.255.252.0  Gateway=10.5.5.1
    ${ips}=  Create List  ${ip1}  ${ip2}  ${ip3}

    Redfish.Patch  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    ...  body={'IPv4StaticAddresses':${ips}}  valid_status_codes=[${HTTP_BAD_REQUEST}]


Modify IP Addresses On VMI Interface And Verify
    [Documentation]  Modify IP addresses on VMI interface and verify.
    [Tags]  Modify_IP_Addresses_On_VMI_Interface_And_Verify
    [Template]  Set Static IPv4 Address To VMI And Verify
    [Teardown]   Run keywords  Delete VMI IPv4 Address  AND  Test Teardown Execution

    # ip        gateway       netmask        valid_status_code
    10.5.5.10   10.5.5.1     255.255.252.0    ${HTTP_ACCEPTED}
    10.5.5.11   10.5.5.1     255.255.252.0    ${HTTP_ACCEPTED}

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
    Redfish Power Off  stack_mode=skip
    Redfish Power On
    ${default}=  Set Variable  0.0.0.0
    Verify VMI Network Interface Details  ${default}  DHCP  ${default}  ${default}

    # Verifying persistency of static address.
    Switch VMI IPv4 Origin And Verify Details
    Redfish Power Off  stack_mode=skip
    Redfish Power On
    Set Static IPv4 Address To VMI And Verify  ${test_ipv4}  ${test_gateway}  ${test_netmask}


Delete VMI Static IP Address And Verify
    [Documentation]  Delete VMI static IP address and verify.
    [Tags]  Delete_VMI_Static_IP_Address_And_Verify
    [Teardown]  Test Teardown Execution

    Set Static IPv4 Address To VMI And Verify  ${test_ipv4}  ${test_gateway}  ${test_netmask}
    Delete VMI IPv4 Address
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    Should Be Empty  ${resp.dict["IPv4Addresses"]}


Verify Successful VMI IP Static Configuration On HOST Boot After Session Delete
    [Documentation]  Verify VMI IP static Configuration On HOST Boot After session deleted.
    [Tags]  Verify_Successful_VMI_IP_Static_Configuration_On_HOST_Boot_After_Session_Delete
    [Teardown]  Run keywords  Delete VMI IPv4 Address  AND  Test Teardown Execution

    Set Static IPv4 Address To VMI And Verify  ${test_ipv4}  ${test_gateway}  ${test_netmask}

    ${session_info}=  Get Redfish Session Info
    Redfish.Delete  ${session_info["location"]}

    # Create a new Redfish session
    Redfish.Login
    Redfish Power Off
    Redfish Power On

    Verify VMI Network Interface Details  ${test_ipv4}  Static  ${test_gateway}  ${test_netmask}


Verify Persistency Of VMI DHCP IP Configuration After Multiple HOST Reboots
    [Documentation]  Verify Persistency Of VMI DHCP IP configuration After Multiple HOST Reboots
    [Tags]  Verify_Persistency_Of_VMI_DHCP_IP_Configuration_After_Multiple_HOST_Reboots
    [Teardown]  Test Teardown Execution

    Set VMI IPv4 Origin  ${True}  ${HTTP_ACCEPTED}
    ${vmi_ip_config}=  Get VMI Network Interface Details
    # Verifying persistency of dynamic address after multiple reboots.
    FOR  ${i}  IN RANGE  ${2}
        Redfish Power Off
        Redfish Power On
        Verify VMI Network Interface Details  ${vmi_ip_config["IPv4_Address"]}  DHCP  ${vmi_ip_config["IPv4_Gateway"]}
    ...  ${vmi_ip_config["IPv4_SubnetMask"]}
    END


Enable DHCP When Static IP Configured And Verify Static IP
    [Documentation]  Enable DHCP when static ip configured and verify static ip
    [Tags]  Enable_DHCP_when_Static_IP_Configured_And_Verify_Static_IP
    [Setup]  Redfish Power On
    [Teardown]  Test Teardown Execution

    Set Static IPv4 Address To VMI And Verify  ${test_ipv4}  ${test_gateway}  ${test_netmask}
    Set VMI IPv4 Origin  ${True}
    ${vmi_network_conf}=  Get VMI Network Interface Details
    Should Not Be Equal As Strings  ${test_ipv4}  ${vmi_network_conf["IPv4_Address"]}


Verify VMI Static IP Configuration Persist On BMC Reset Before Host Boot
    [Documentation]  Verify VMI static IP configuration persist on BMC reset.
    [Tags]   Verify_VMI_Static_IP_Configuration_Persist_On_BMC_Reset_Before_Host_Boot
    [Teardown]  Run keywords  Delete VMI IPv4 Address  AND  FFDC On Test Case Fail

    Set Static IPv4 Address To VMI And Verify  ${test_ipv4}  ${test_gateway}  ${test_netmask}
    OBMC Reboot (off)
    Redfish Power On
    # Verifying the VMI static configuration
    Verify VMI Network Interface Details  ${test_ipv4}  Static   ${test_gateway}  ${test_netmask}

Add Static IP When Host Poweroff And Verify On Poweron
    [Documentation]  Add Static IP When Host Poweroff And Verify on power on
    [Tags]   Add_Static_IP_When_Host_Poweroff_And_Verify_On_Poweron
    [Setup]  Redfish Power Off
    [Teardown]  Run keywords  Delete VMI IPv4 Address  AND  FFDC On Test Case Fail

    Set Static IPv4 Address To VMI And Verify  ${test_ipv4}  ${test_gateway}  ${test_netmask}
    Redfish Power On
    Verify VMI Network Interface Details  ${test_ipv4}  Static  ${test_gateway}  ${test_netmask}

Add VMI Static IP When Host Poweroff And Verify Static IP On BMC Reset
    [Documentation]  Add Static IP When Host Poweroff And Verify Static IP On BMC Reset.
    [Tags]  Add_VMI_Static_IP_When_Host_Poweroff_And_Verify_Static_IP_On_BMC_Reset
    [Setup]  Redfish Power Off
    [Teardown]  Run keywords  Delete VMI IPv4 Address  AND  FFDC On Test Case Fail

    Set Static IPv4 Address To VMI And Verify  ${test_ipv4}  ${test_gateway}  ${test_netmask}
    OBMC Reboot (off)
    Redfish Power On
    Verify VMI Network Interface Details  ${test_ipv4}  Static  ${test_gateway}  ${test_netmask}

Enable DHCP When No Static IP Configured And Verify DHCP IP
    [Documentation]  Enable DHCP when no static ip configured and verify dhcp ip
    [Tags]  Enable_DHCP_When_No_Static_IP_Configured_And_Verify_DHCP_IP
    [Setup]  Run Keyword And Ignore Error  Delete VMI IPv4 Address
    [Teardown]  Test Teardown Execution

    ${curr_origin}=  Get Immediate Child Parameter From VMI Network Interface  DHCPEnabled
    Run Keyword If  ${curr_origin} == ${False}  Set VMI IPv4 Origin  ${True}  ${HTTP_ACCEPTED}
    ${vmi_ip_config}=  Get VMI Network Interface Details
    Verify VMI Network Interface Details  ${vmi_ip_config["IPv4_Address"]}  DHCP  ${vmi_ip_config["IPv4_Gateway"]}
    ...  ${vmi_ip_config["IPv4_SubnetMask"]}

Verify User Cannot Delete VMI DHCP IP Address
    [Documentation]  Verify user cannot delete VMI DHCP IP Address
    [Tags]  Verify_User_Cannot_Delete_VMI_DHCP_IP_Address
    [Setup]  Set VMI IPv4 Origin  ${True}
    [Teardown]  Test Teardown Execution

    Delete VMI IPv4 Address  IPv4Addresses  valid_status_code=${HTTP_FORBIDDEN}
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    Should Not Be Empty  ${resp.dict["IPv4Addresses"]}

Enable DHCP When Static IP Configured DHCP Server Unavailable And Verify IP
    [Documentation]  Enable DHCP When Static IP Configured And DHCP Server Unavailable And Verify No IP.
    [Tags]  Enable_DHCP_When_Static_IP_Configured_DHCP_Server_Unavailable_And_Verify_IP
    [Teardown]  Test Teardown Execution

    Set Static IPv4 Address To VMI And Verify  ${test_ipv4}  ${test_gateway}  ${test_netmask}
    Set VMI IPv4 Origin  ${True}
    ${default}=  Set Variable  0.0.0.0
    Verify VMI Network Interface Details  ${default}  DHCP  ${default}  ${default}


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

    # username     password     ip_address  gateway    netmask       valid_status_code
    admin_user     TestPwd123   10.5.10.20  10.5.10.1  255.255.0.0  ${HTTP_ACCEPTED}
    operator_user  TestPwd123   10.5.10.30  10.5.10.1  255.255.0.0  ${HTTP_FORBIDDEN}
    readonly_user  TestPwd123   10.5.20.40  10.5.20.1  255.255.0.0  ${HTTP_FORBIDDEN}
    noaccess_user  TestPwd123   10.5.30.50  10.5.30.1  255.255.0.0  ${HTTP_FORBIDDEN}


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

Enable DHCP On VMI Network Via Different Users Roles And Verify
    [Documentation]  Enable DHCP On VMI Network Via Different Users Roles And Verify.
    [Tags]  Enable_DHCP_On_VMI_Network_Via_Different_Users_Roles_And_Verify
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Update User Role And Set VMI IPv4 Origin
    [Teardown]  Delete BMC Users Using Redfish

    # username     password     dhcp_enabled   valid_status_code
    admin_user     TestPwd123   ${True}        ${HTTP_ACCEPTED}
    operator_user  TestPwd123   ${True}        ${HTTP_FORBIDDEN}
    readonly_user  TestPwd123   ${True}        ${HTTP_FORBIDDEN}
    noaccess_user  TestPwd123   ${True}        ${HTTP_FORBIDDEN}

Disable DHCP On VMI Network Via Different Users Roles And Verify
    [Documentation]  Disable DHCP On VMI Network Via Different Users Roles And Verify.
    [Tags]  Disable_DHCP_On_VMI_Network_Via_Different_Users_Roles_And_Verify
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Update User Role And Set VMI IPv4 Origin
    [Teardown]  Delete BMC Users Using Redfish

    # username     password     dhcp_enabled    valid_status_code
    admin_user     TestPwd123   ${False}        ${HTTP_ACCEPTED}
    operator_user  TestPwd123   ${False}        ${HTTP_FORBIDDEN}
    readonly_user  TestPwd123   ${False}        ${HTTP_FORBIDDEN}
    noaccess_user  TestPwd123   ${False}        ${HTTP_FORBIDDEN}


Enable And Disable DHCP And Verify
    [Documentation]  verify enable DHCP and disable DHCP.
    [Tags]  Enabled_And_Disabled_DHCP_Verify

    Set VMI IPv4 Origin  ${True}
    ${default}=  Set Variable  0.0.0.0
    Verify VMI Network Interface Details  ${default}  DHCP  ${default}  ${default}
    Set VMI IPv4 Origin  ${False}
    ${vmi_ip}=  Get VMI Network Interface Details
    Should Be Empty  ${vmi_ip["IPv4_Address"]}


Multiple Times Enable And Disable DHCP And Verify
    [Documentation]  Enable and Disable DHCP in a loop and verify VMI gets an IP address from DHCP
    ...  each time when DHCP is enabled
    [Tags]  Multiple_Times_Enable_And_Disable_DHCP_And_Verify

    ${default}=  Set Variable  0.0.0.0
    FOR  ${i}  IN RANGE  ${2}
      Set VMI IPv4 Origin  ${True}
      Verify VMI Network Interface Details  ${default}  DHCP  ${default}  ${default}
      Set VMI IPv4 Origin  ${False}
      ${vmi_ip}=  Get VMI Network Interface Details
      Should Be Empty  ${vmi_ip["IPv4_Address"]}
    END


Assign Static IPv4 Address With Invalid Netmask To VMI
    [Documentation]  Assign static IPv4 address with invalid netmask and expect error.
    [Tags]  Assign_Static_IPv4_Address_With_Invalid_Netmask_To_VMI
    [Template]  Set Static IPv4 Address To VMI And Verify

    # ip          gateway          netmask         valid_status_code
    ${test_ipv4}  ${test_gateway}  255.256.255.0   ${HTTP_BAD_REQUEST}
    ${test_ipv4}  ${test_gateway}  ff.ff.ff.ff     ${HTTP_BAD_REQUEST}
    ${test_ipv4}  ${test_gateway}  255.255.253.0   ${HTTP_BAD_REQUEST}


Assign Static IPv4 Address With Invalid Gateway To VMI
    [Documentation]  Add static IPv4 address with invalid gateway and expect error.
    [Tags]  Assign_Static_IPv4_Address_With_Invalid_Gateway_To_VMI
    [Template]  Set Static IPv4 Address To VMI And Verify

    # ip          gateway          netmask           valid_status_code
    ${test_ipv4}  @@@.%%.44.11     ${test_netmask}   ${HTTP_BAD_REQUEST}
    ${test_ipv4}  0xa.0xb.0xc.0xd  ${test_netmask}   ${HTTP_BAD_REQUEST}
    ${test_ipv4}  10.3.36          ${test_netmask}   ${HTTP_BAD_REQUEST}
    ${test_ipv4}  10.3.36.-10      ${test_netmask}   ${HTTP_BAD_REQUEST}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test setup execution task.

    Redfish.Login
    Redfish Power On
    ${active_channel_config}=  Get Active Channel Config
    Set Suite Variable   ${active_channel_config}
    Set Suite Variable  ${ethernet_interface}  ${active_channel_config['${CHANNEL_NUMBER}']['name']}
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    ${ip_resp}=  Evaluate  json.loads(r'''${resp.text}''')  json
    ${length}=  Get Length  ${ip_resp["IPv4StaticAddresses"]}
    ${vmi_network_conf}=  Run Keyword If  ${length} != ${0}  Get VMI Network Interface Details
    Set Suite Variable  ${vmi_network_conf}


Test Teardown Execution
    [Documentation]  Do test teardown execution task.

    FFDC On Test Case Fail
    ${curr_mode}=  Get Immediate Child Parameter From VMI Network Interface  DHCPEnabled
    Run Keyword If  ${curr_mode} == ${True}  Set VMI IPv4 Origin  ${False}
    Run Keyword If  ${vmi_network_conf} != ${None}
    ...  Set Static IPv4 Address To VMI And Verify  ${vmi_network_conf["IPv4_Address"]}
    ...  ${vmi_network_conf["IPv4_Gateway"]}  ${vmi_network_conf["IPv4_SubnetMask"]}


Get Immediate Child Parameter From VMI Network Interface
    [Documentation]  Get immediate child parameter from VMI network interface.
    [Arguments]  ${parameter}  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # parameter          parameter for which value is required. Ex: DHCPEnabled, MACAddress etc.
    # valid_status_code  Expected valid status code from GET request.

    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    ...  valid_status_codes=[${valid_status_code}]

    ${ip_resp}=  Evaluate  json.loads(r'''${resp.text}''')  json
    ${value}=  Set Variable If  '${parameter}' != 'DHCPEnabled'   ${ip_resp["${parameter}"]}
    ...  ${ip_resp["DHCPv4"]["${parameter}"]}

    [Return]  ${value}


Switch VMI IPv4 Origin And Verify Details
    [Documentation]  Switch VMI IPv4 origin and verify details.

    ${dhcp_mode_before}=  Get Immediate Child Parameter From VMI Network Interface  DHCPEnabled
    ${dhcp_enabled}=  Set Variable If  ${dhcp_mode_before} == ${False}  ${True}  ${False}

    ${default}=  Set Variable  0.0.0.0
    ${origin}=  Set Variable If  ${dhcp_mode_before} == ${False}  DHCP  Static
    Set VMI IPv4 Origin  ${dhcp_enabled}  ${HTTP_ACCEPTED}

    ${dhcp_mode_after}=  Get Immediate Child Parameter From VMI Network Interface  DHCPEnabled
    Should Not Be Equal  ${dhcp_mode_before}  ${dhcp_mode_after}

    Run Keyword If  ${dhcp_mode_after} == ${True}
    ...  Verify VMI Network Interface Details  ${default}  ${origin}  ${default}  ${default}


Delete VMI Static IP Address Using Different Users
    [Documentation]  Update user role and delete vmi static IP address.
    [Arguments]  ${username}  ${password}  ${valid_status_code}
    [Teardown]  Run Keywords  Redfish.Login  AND
    ...  Set Static IPv4 Address To VMI And Verify  ${test_ipv4}  ${test_gateway}
    ...  ${test_netmask}  ${HTTP_ACCEPTED}  AND  Redfish.Logout

    # Description of argument(s):
    # username            The host username.
    # password            The host password.
    # valid_status_code   The expected valid status code.

    Redfish.Login  ${username}  ${password}
    Delete VMI IPv4 Address  delete_param=IPv4StaticAddresses  valid_status_code=${valid_status_code}


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


Read VMI Static IP Address Using Different Users
   [Documentation]  Update user role and read vmi static ip address.
   [Arguments]  ${username}  ${password}  ${valid_status_code}

    # Description of argument(s):
    # username            The host username.
    # password            The host password.
    # valid_status_code   The expected valid status code.

    Redfish.Login  ${username}  ${password}
    Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    ...  valid_status_codes=[${valid_status_code}]


Delete BMC Users Using Redfish
   [Documentation]  Delete BMC users via redfish.

   Redfish.Login
   Delete BMC Users Via Redfish  users=${USERS}


Update User Role And Set VMI IPv4 Origin
    [Documentation]  Update User Role And Set VMI IPv4 Origin.
    [Arguments]  ${username}  ${password}  ${dhcp_enabled}  ${valid_status_code}

    # Description of argument(s):
    # username            The host username.
    # password            The host password.
    # dhcp_enabled        Indicates whether dhcp should be enabled
    #                     (${True}, ${False}).
    # valid_status_code   The expected valid status code.

    Redfish.Login  ${username}  ${password}
    Set VMI IPv4 Origin  ${dhcp_enabled}  ${valid_status_code}


Suite Teardown Execution
    [Documentation]  Do suite teardown execution task.

    Run Keyword If  ${vmi_network_conf} != ${None}
    ...  Set Static IPv4 Address To VMI And Verify  ${vmi_network_conf["IPv4_Address"]}
    ...  ${vmi_network_conf["IPv4_Gateway"]}  ${vmi_network_conf["IPv4_SubnetMask"]}
    Delete All Redfish Sessions
    Redfish.Logout
