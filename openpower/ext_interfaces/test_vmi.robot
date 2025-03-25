*** Settings ***

Documentation     VMI static/dynamic IP config tests.

Resource          ../../lib/external_intf/vmi_utils.robot

Suite Setup       Suite Setup Execution
Test Teardown     FFDC On Test Case Fail
Suite Teardown    Run Keyword And Ignore Error  Suite Teardown Execution

Test Tags         Vmi

*** Variables ***

# users           User Name               password
@{ADMIN}          admin_user              TestPwd123
@{OPERATOR}       operator_user           TestPwd123
@{ReadOnly}       readonly_user           TestPwd123
&{USERS}          Administrator=${ADMIN}  ReadOnly=${ReadOnly}

${test_ipv4}              10.6.6.6
${test_gateway}           10.6.6.1
${test_netmask}           255.255.252.0

&{DHCP_ENABLED}           DHCPEnabled=${${True}}
&{DHCP_DISABLED}          DHCPEnabled=${${False}}

&{ENABLE_DHCP}            DHCPv4=&{DHCP_ENABLED}
&{DISABLE_DHCP}           DHCPv4=&{DHCP_DISABLED}

${default}                0.0.0.0
${default_ipv6addr}       ::
${prefix_length}          ${64}
${test_vmi_ipv6addr}      2001:db8:1111:2222:10:5:5:6
${test_vmi_ipv6gateway}   2001:db8:1111:2222::1
${ipv4_hexword_addr}      10.5.5.6:1A:1B:1C:1D:1E:1F
${multicast_ipv6addr}     FF00
${loopback_ipv6addr}      ::1


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
        Verify VMI Network Interface Details  ${vmi_ip_config["IPv4_Address"]}
        ...  DHCP  ${vmi_ip_config["IPv4_Gateway"]}  ${vmi_ip_config["IPv4_SubnetMask"]}
    END


Enable DHCP When Static IP Configured And Verify Static IP
    [Documentation]  Enable DHCP when static ip configured and verify static ip
    [Tags]  Enable_DHCP_When_Static_IP_Configured_And_Verify_Static_IP
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
    Redfish OBMC Reboot (off)  stack_mode=skip
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
    Redfish OBMC Reboot (off)  stack_mode=skip
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
    Verify VMI Network Interface Details  ${vmi_ip_config["IPv4_Address"]}
    ...  DHCP  ${vmi_ip_config["IPv4_Gateway"]}  ${vmi_ip_config["IPv4_SubnetMask"]}


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
    Verify VMI Network Interface Details  ${default}  DHCP  ${default}  ${default}


Verify To Configure VMI Static IP Address With Different User Roles
    [Documentation]  Verify to configure vmi static ip address with different user roles.
    [Tags]  Verify_To_Configure_VMI_Static_IP_Address_With_Different_User_Roles
    [Setup]  Run Keywords  Delete BMC Users Using Redfish
    ...  AND  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Config VMI Static IP Address Using Different Users
    [Teardown]  Delete BMC Users Using Redfish

    # username     password    ip_address    gateway          nemask           valid_status_code
    admin_user     TestPwd123  ${test_ipv4}  ${test_gateway}  ${test_netmask}  ${HTTP_ACCEPTED}
    readonly_user  TestPwd123  ${test_ipv4}  ${test_gateway}  ${test_netmask}  ${HTTP_FORBIDDEN}


Verify To Configure VMI Static IP Address With Operator User Role
    [Documentation]  Verify to configure vmi static ip address with operator user role.
    [Tags]  Verify_To_Configure_VMI_Static_IP_Address_With_Operator_User_Role
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Config VMI Static IP Address Using Different Users
    [Teardown]  Delete BMC Users Using Redfish

    # username     password    ip_address    gateway          nemask           valid_status_code
    operator_user  TestPwd123  ${test_ipv4}  ${test_gateway}  ${test_netmask}  ${HTTP_FORBIDDEN}


Verify To Delete VMI Static IP Address With Different User Roles
    [Documentation]  Verify to delete vmi static IP address with different user roles.
    [Tags]  Verify_To_Delete_VMI_Static_IP_Address_With_Different_User_Roles
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Delete VMI Static IP Address Using Different Users
    [Teardown]  Delete BMC Users Using Redfish

    # username     password     valid_status_code
    admin_user     TestPwd123   ${HTTP_ACCEPTED}
    readonly_user  TestPwd123   ${HTTP_FORBIDDEN}


Verify To Delete VMI Static IP Address With Operator User Role
    [Documentation]  Verify to delete vmi static IP address with operator user role.
    [Tags]  Verify_To_Delete_VMI_Static_IP_Address_With_Operator_User_Role
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Delete VMI Static IP Address Using Different Users
    [Teardown]  Delete BMC Users Using Redfish

    # username     password     valid_status_code
    operator_user     TestPwd123   ${HTTP_FORBIDDEN}


Verify To Update VMI Static IP Address With Different User Roles
    [Documentation]  Verify to update vmi static IP address with different user roles.
    [Tags]  Verify_To_Update_VMI_Static_IP_Address_With_Different_User_Roles
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Config VMI Static IP Address Using Different Users
    [Teardown]  Delete BMC Users Using Redfish

    # username     password     ip_address  gateway    netmask       valid_status_code
    admin_user     TestPwd123   10.5.10.20  10.5.10.1  255.255.0.0  ${HTTP_ACCEPTED}
    readonly_user  TestPwd123   10.5.20.40  10.5.20.1  255.255.0.0  ${HTTP_FORBIDDEN}


Verify To Update VMI Static IP Address With Operator User Role
    [Documentation]  Verify to update vmi static IP address with operator user role.
    [Tags]  Verify_To_Update_VMI_Static_IP_Address_With_Operator_User_Role
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Config VMI Static IP Address Using Different Users
    [Teardown]  Delete BMC Users Using Redfish

    # username     password     ip_address  gateway    netmask       valid_status_code
    operator_user  TestPwd123   10.5.10.30  10.5.10.1  255.255.0.0  ${HTTP_FORBIDDEN}


Verify To Read VMI Network Configuration With Different User Roles
    [Documentation]  Verify to read vmi network configuration with different user roles.
    [Tags]  Verify_To_Read_VMI_Network_Configuration_With_Different_User_Roles
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Read VMI Static IP Address Using Different Users
    [Teardown]  Delete BMC Users Using Redfish

    # username     password     valid_status_code
    admin_user     TestPwd123   ${HTTP_OK}
    readonly_user  TestPwd123   ${HTTP_OK}


Verify To Read VMI Network Configuration With Operator User Role
    [Documentation]  Verify to read vmi network configuration with operator user role.
    [Tags]  Verify_To_Read_VMI_Network_Configuration_With_Operator_User_Role
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Read VMI Static IP Address Using Different Users
    [Teardown]  Delete BMC Users Using Redfish

    # username     password     valid_status_code
    operator_user  TestPwd123   ${HTTP_FORBIDDEN}


Enable DHCP On VMI Network Via Different Users Roles And Verify
    [Documentation]  Enable DHCP On VMI Network Via Different Users Roles And Verify.
    [Tags]  Enable_DHCP_On_VMI_Network_Via_Different_Users_Roles_And_Verify
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Update User Role And Set VMI IPv4 Origin
    [Teardown]  Delete BMC Users Using Redfish

    # username     password     dhcp_enabled   valid_status_code
    admin_user     TestPwd123   ${True}        ${HTTP_ACCEPTED}
    readonly_user  TestPwd123   ${True}        ${HTTP_FORBIDDEN}


Enable DHCP On VMI Network Via Operator User Role And Verify
    [Documentation]  Enable DHCP On VMI Network Via Operator User Role And Verify.
    [Tags]  Enable_DHCP_On_VMI_Network_Via_Operator_User_Role_And_Verify
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Update User Role And Set VMI IPv4 Origin
    [Teardown]  Delete BMC Users Using Redfish

    # username     password     dhcp_enabled   valid_status_code
    operator_user  TestPwd123   ${True}        ${HTTP_FORBIDDEN}


Disable DHCP On VMI Network Via Different Users Roles And Verify
    [Documentation]  Disable DHCP On VMI Network Via Different Users Roles And Verify.
    [Tags]  Disable_DHCP_On_VMI_Network_Via_Different_Users_Roles_And_Verify
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Update User Role And Set VMI IPv4 Origin
    [Teardown]  Delete BMC Users Using Redfish

    # username     password     dhcp_enabled    valid_status_code
    admin_user     TestPwd123   ${False}        ${HTTP_ACCEPTED}
    readonly_user  TestPwd123   ${False}        ${HTTP_FORBIDDEN}


Disable DHCP On VMI Network Via Operator User Role And Verify
    [Documentation]  Disable DHCP On VMI Network Via Operator User Role And Verify.
    [Tags]  Disable_DHCP_On_VMI_Network_Via_Operator_User_Role_And_Verify
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Template]  Update User Role And Set VMI IPv4 Origin
    [Teardown]  Delete BMC Users Using Redfish

    # username     password     dhcp_enabled    valid_status_code
    operator_user  TestPwd123   ${False}        ${HTTP_FORBIDDEN}


Enable And Disable DHCP And Verify
    [Documentation]  verify enable DHCP and disable DHCP.
    [Tags]  Enable_And_Disable_DHCP_And_Verify

    Set VMI IPv4 Origin  ${True}
    Verify VMI Network Interface Details  ${default}  DHCP  ${default}  ${default}
    Set VMI IPv4 Origin  ${False}
    Verify VMI Network Interface Details  ${default}  Static  ${default}  ${default}


Multiple Times Enable And Disable DHCP And Verify
    [Documentation]  Enable and Disable DHCP in a loop and verify VMI gets an IP address from DHCP
    ...  each time when DHCP is enabled
    [Tags]  Multiple_Times_Enable_And_Disable_DHCP_And_Verify

    FOR  ${i}  IN RANGE  ${2}
      Set VMI IPv4 Origin  ${True}
      Verify VMI Network Interface Details  ${default}  DHCP  ${default}  ${default}
      Set VMI IPv4 Origin  ${False}
      Verify VMI Network Interface Details  ${default}  Static  ${default}  ${default}
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


Enable DHCP When Host Is Off And Verify After Poweron
    [Documentation]  Enable DHCP when host is off and
    ...  check whether it is enabled after poweron.
    [Tags]  Enable_DHCP_When_Host_Is_Off_And_Verify_After_Poweron
    [Setup]  Redfish Power Off  stack_mode=skip

    Set VMI IPv4 Origin  ${True}
    Redfish Power On  stack_mode=skip
    Verify VMI Network Interface Details  ${default}  DHCP  ${default}  ${default}


Disable DHCP When Host Is Off And Verify New State Reflects After Power On
    [Documentation]  Disable DHCP when host is off and
    ...  get network info and verify that VMI origin is static.
    [Tags]  Disable_DHCP_When_Host_Is_Off_And_Verify_New_State_Reflects_After_Power_On
    [Setup]  Redfish Power Off  stack_mode=skip

    Set VMI IPv4 Origin  ${False}
    Redfish Power On  stack_mode=skip
    Verify VMI Network Interface Details  ${default}  Static  ${default}  ${default}


Enable VMI Stateless Address AutoConfig And Verify
    [Documentation]  Enable VMI SLAACv6 and verify an origin.
    [Tags]  Enable_VMI_Stateless_Address_AutoConfig_And_Verify

    Set VMI SLAACv6 Origin    ${True}

    # Check origin is set to slaac and address are getting displayed.
    Verify VMI IPv6 Address  SLAAC


Disable VMI Stateless Address AutoConfig And Verify
    [Documentation]  Disable VMI SLAACv6 and verify an origin.
    [Tags]  Disable_VMI_Stateless_Address_AutoConfig_And_Verify
    [Setup]  Set VMI SLAACv6 Origin    ${True}

    Set VMI SLAACv6 Origin    ${False}

    # Check origin is set to static and slaacv6 address are getting erased.
    Verify VMI IPv6 Address  Static


Enable VMI SLAAC And Check Persistency On BMC Reboot
    [Documentation]  Enable VMI SLAACv6 and verify its persistency
    ...  on BMC reboot and this works on the setup where router
    ...  advertises network prefix.
    [Tags]  Enable_VMI_SLAAC_And_Check_Persistency_On_BMC_Reboot

    Set VMI SLAACv6 Origin    ${True}

    # Reboot BMC and verify persistency.
    OBMC Reboot (off)
    Redfish Power On
    Wait For Host Boot Progress To Reach Required State
    Sleep  5s

    # Check origin is set to slaac and address are getting displayed.
    ${vmi_ipv6addr}=  Verify VMI IPv6 Address  SLAAC
    Should Not Be Equal  ${vmi_ipv6addr["Address"]}  ${default_ipv6addr}


Disable VMI SLAAC And Check Persistency On BMC Reboot
    [Documentation]  Disable VMI SLAACv6 and verify its persistency
    ...  on BMC reboot.
    [Tags]  Disable_VMI_SLAAC_And_Check_Persistency_On_BMC_Reboot

    Set VMI SLAACv6 Origin    ${False}

    # Reboot BMC and verify persistency.
    OBMC Reboot (off)
    Redfish Power On
    Wait For Host Boot Progress To Reach Required State

    # Check if origin is set to static and SLAAC address are getting erased.
    ${vmi_ipv6addr}=  Verify VMI IPv6 Address  Static
    Should Be Equal  ${vmi_ipv6addr["Address"]}  ${default_ipv6addr}


Disable VMI DHCPv4 When SLAAC Is Enabled And Verify
    [Documentation]  Disable VMI DHCPv4 parameter when SLAACv6 is enabled
    ...  and check whether the IPv4 address origin is set to static and
    ...  DHCPv4 address is getting erased.
    [Tags]  Disable_VMI_DHCPv4_When_SLAAC_Is_Enabled_And_Verify
    [Setup]  Set VMI IPv4 Origin  ${True}

    # Set IPv6 origin to SLAAC.
    Set VMI SLAACv6 Origin    ${True}
    Verify VMI IPv6 Address  SLAAC

    # Disable VMI DHCPv4 and check IPv4 address origin is set to static.
    Set VMI IPv4 Origin  ${False}
    Verify VMI Network Interface Details  ${default}  Static  ${default}  ${default}


Enable VMI SLAAC When DHCPv6 Is Enabled And Verify
    [Documentation]  Enable VMI SLAACv6 when VMI DHCPv6 is enabled and
    ...  check IPv6 gets Slaac address and this works on the setup
    ...  where router advertise network prefix.
    [Tags]  Enable_VMI_SLAAC_When_DHCPv6_Is_Enabled_And_Verify

    Set VMI DHCPv6 Property  Enabled

    # Enable SLAAC and check whether IPv6 origin is set to SLAAC.
    Set VMI SLAACv6 Origin    ${True}

    # Check if origin is set to slaac and address are getting displayed.
    ${vmi_ipv6addr}=  Verify VMI IPv6 Address  SLAAC
    Should Not Be Equal  ${vmi_ipv6addr["Address"]}  ${default_ipv6addr}
    Should Be Equal  ${vmi_ipv6addr["PrefixLength"]}  ${prefix_length}


Disable VMI DHCPv6 Property And Verify
    [Documentation]  Disable VMI DHCPv6 property and verify IPv6 address
    ...              origin is set to static and DHCPv6 address is erased.
    [Tags]  Disable_VMI_DHCPv6_Property_And_Verify
    [Setup]  Set VMI DHCPv6 Property  Enabled

    Set VMI DHCPv6 Property  Disabled

    # Verify IPv6 address origin is set to static and DHCPv6 address is erased.
    ${vmi_ipv6addr}=  Verify VMI IPv6 Address  Static
    Should Be Equal  ${vmi_ipv6addr["Address"]}  ${default_ipv6addr}


Enable VMI SLAAC When DHCPv4 Is Enabled And Verify
    [Documentation]  On VMI enable SLAAC when DHCPv4 is enabled and verify DHCPv4 settings are intact
    ...  and IPv6 origin is set to SLAAC & it gets assigned with SLAAC IPv6 address and this
    ...  works on the setup where router advertise network prefix.
    [Tags]  Enable_VMI_SLAAC_When_DHCPv4_Is_Enabled_And_Verify
    [Setup]  Set VMI IPv4 Origin  ${True}

    # Enable Autoconfig address and check whether IPv6 address origin is set to SLAAC.
    Set VMI SLAACv6 Origin  ${True}
    Verify VMI IPv6 Address  SLAAC

    # Check there is no impact on IPv4 settings, IPv4 address origin should be DHCP.
    Verify VMI Network Interface Details  ${default}  DHCP  ${default}  ${default}


Disable VMI DHCPv6 Property And Check Persistency On BMC Reboot
    [Documentation]  Disable VMI DHCPv6 property and verify its persistency on
    ...  BMC reboot.
    [Tags]  Disable_VMI_DHCPv6_Property_And_Check_Persistency_On_BMC_Reboot
    [Setup]  Set VMI DHCPv6 Property  Enabled

    Set VMI DHCPv6 Property  Disabled

    # Reboot BMC and verify persistency.
    OBMC Reboot (off)

    # Verify IPv6 address origin is set to Static and DHCPv6 address is erased.
    ${vmi_ipv6addr}=  Verify VMI IPv6 Address  Static
    Should Be Equal  ${vmi_ipv6addr["Address"]}  ${default_ipv6addr}


Enable VMI SLAAC When IPv4 Origin Is Static And Verify
    [Documentation]  On VMI enable SLAAC when IPv4 origin is static and verify IPv4 settings are intact
    ...  and IPv6 origin is set to SLAAC & it gets assigned with SLAAC IPv6 address and this works
    ...  on the setup where router advertise network prefix.
    [Tags]  Enable_VMI_SLAAC_When_IPv4_Origin_Is_Static_And_Verify
    [Setup]  Set Static IPv4 Address To VMI And Verify  ${test_ipv4}  ${test_gateway}  ${test_netmask}
    [Teardown]  Run keywords  Delete VMI IPv4 Address  AND  Test Teardown Execution

    # Enable Autoconfig address and check whether IPv6 address origin is set to SLAAC.
    Set VMI SLAACv6 Origin  ${True}
    Verify VMI IPv6 Address  SLAAC

    # Check there is no impact on IPv4 settings, IPv4 address origin should be Static.
    Verify VMI Network Interface Details  ${test_ipv4}  Static  ${test_gateway}  ${test_netmask}


Configure Static VMI IPv6 Address And Verify
    [Documentation]  Add static VMI IPv6 address and check whether IPv6 origin is set to static
    ...  and Static IPv6 address is assigned.
    [Tags]  Configure_Static_VMI_IPv6_Address_And_Verify

    Set Static VMI IPv6 Address  ${test_vmi_ipv6addr}  ${prefix_length}

    # Verify IPv6 address origin is set to static and static IPv6 address is assigned.
    ${vmi_ipv6addr}=  Verify VMI IPv6 Address  Static
    Should Not Be Equal  ${vmi_ipv6addr["Address"]}  ${default_ipv6addr}
    Should Be Equal  ${vmi_ipv6addr["PrefixLength"]}  ${prefix_length}


Configure IPv6 Static Default Gateway On VMI And Verify
    [Documentation]  Configure IPv6 static default gateway on VMI and verify.
    [Tags]  Configure_IPv6_Static_Default_Gateway_On_VMI_And_Verify
    [Setup]  Set Static VMI IPv6 Address  ${test_vmi_ipv6addr}  ${prefix_length}

    Set VMI IPv6 Static Default Gateway  ${test_vmi_ipv6gateway}

    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    ${vmi_ipv6_gateways}=  Get From Dictionary  ${resp.dict}  IPv6StaticDefaultGateways
    ${vmi_ipv6_gateway} =  Get From List  ${vmi_ipv6_gateways}  0
    Should Be Equal  ${vmi_ipv6_gateway["Address"]}  ${test_vmi_ipv6gateway}


Delete VMI Static IPv6 Address And Verify
    [Documentation]  Delete VMI static IPv6 address and verify address is erased.
    [Tags]  Delete_VMI_Static_IPv6_Address_And_Verify
    [Setup]  Set Static VMI IPv6 Address  ${test_vmi_ipv6addr}  ${prefix_length}

    # Delete VMI static IPv6 address.
    Delete VMI IPv6 Static Address

    # Verify VMI static IPv6 address is erased.
    ${vmi_ipv6addr}=  Verify VMI IPv6 Address  Static
    Should Not Be Equal  ${vmi_ipv6addr["Address"]}  ${test_vmi_ipv6addr}
    Should Be Equal  ${vmi_ipv6addr["Address"]}  ${default_ipv6addr}


Enable VMI DHCPv6 When IPv6 Origin Is Static And Verify
    [Documentation]  Enable VMI DHCPv6 when IPv6 origin is in static and verify
    ...  origin is set to DHCP and check if static IPv6 address is erased.
    [Tags]  Enable_VMI_DHCPv6_When_IPv6_Origin_Is_Static_And_Verify

    Set Static VMI IPv6 Address  ${test_vmi_ipv6addr}  ${prefix_length}
    ${vmi_ipv6addr_static}=  Verify VMI IPv6 Address  Static

    Sleep  5s

    # Enable DHCPv6 property.
    Set VMI DHCPv6 Property  Enabled

    # Check origin is set to DHCP and static IPv6 address is erased.
    ${vmi_dhcpv6addr}=  Verify VMI IPv6 Address  DHCPv6
    Should Not Be Equal  ${vmi_dhcpv6addr["Address"]}  ${vmi_ipv6addr_static["Address"]}


Configure Invalid Static IPv6 To VMI And Verify
    [Documentation]  Configure invalid static IPv6 address to VMI and verify that address
    ...  does not get assigned and it throws an error.
    [Tags]  Configure_Invalid_Static_IPv6_To_VMI_And_Verify
    [Setup]  Set Static VMI IPv6 Address  ${test_vmi_ipv6addr}  ${prefix_length}
    [Template]  Set VMI Invalid Static IPv6 Address And Verify

    # invalid_vmi_ipv6addr     invalid_prefix_length     valid_status_codes
    ${default_ipv6addr}        128                       ${HTTP_BAD_REQUEST}
    ${multicast_ipv6addr}      8                         ${HTTP_BAD_REQUEST}
    ${loopback_ipv6addr}       64                        ${HTTP_BAD_REQUEST}
    ${ipv4_hexword_addr}       64                        ${HTTP_BAD_REQUEST}


Delete IPv6 Static Default Gateway On VMI And Verify
    [Documentation]  Delete IPv6 static default gateway and verify address is erased.
    [Tags]  Delete_IPv6_Static_Default_Gateway_On_VMI_And_Verify
    [Setup]  Run Keywords  Set Static VMI IPv6 Address  ${test_vmi_ipv6addr}  ${prefix_length}
    ...  AND  Set VMI IPv6 Static Default Gateway  ${test_vmi_ipv6gateway}

    # Delete IPv6 static default gateway address.
    Delete VMI IPv6 Static Default Gateway Address

    # Verify static IPv6 default gateway address is deleted.
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    Should Be Empty  ${resp.dict["IPv6StaticDefaultGateways"]}
    Should Not Be Equal  ${resp.dict["IPv6StaticDefaultGateways"]}  ${test_vmi_ipv6gateway}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test setup execution task.

    Redfish.Login

    Redfish Power Off
    Set BIOS Attribute  pvm_hmc_managed  Enabled
    Set BIOS Attribute  pvm_stop_at_standby  Disabled

    Redfish Power On
    Wait For Host Boot Progress To Reach Required State

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
    Run Keyword If  '${vmi_network_conf["IPv4_Address"]}' != '${default}'
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

    RETURN  ${value}


Switch VMI IPv4 Origin And Verify Details
    [Documentation]  Switch VMI IPv4 origin and verify details.

    ${dhcp_mode_before}=  Get Immediate Child Parameter From VMI Network Interface  DHCPEnabled
    ${dhcp_enabled}=  Set Variable If  ${dhcp_mode_before} == ${False}  ${True}  ${False}

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

    # TODO: operator_user role is not yet supported.
    Skip If  '${username}' == 'operator_user'
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

    # TODO: operator_user role is not yet supported.
    Skip If  '${username}' == 'operator_user'
    Redfish.Login  ${username}  ${password}
    Set Static IPv4 Address To VMI And Verify  ${ip}  ${gateway}  ${netmask}  ${valid_status_code}


Read VMI Static IP Address Using Different Users
   [Documentation]  Update user role and read vmi static ip address.
   [Arguments]  ${username}  ${password}  ${valid_status_code}

    # Description of argument(s):
    # username            The host username.
    # password            The host password.
    # valid_status_code   The expected valid status code.

    # TODO: operator_user role is not yet supported.
    Skip If  '${username}' == 'operator_user'
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

    # TODO: operator_user role is not yet supported.
    Skip If  '${username}' == 'operator_user'
    Redfish.Login  ${username}  ${password}
    Set VMI IPv4 Origin  ${dhcp_enabled}  ${valid_status_code}


Suite Teardown Execution
    [Documentation]  Do suite teardown execution task.

    Run Keyword If  ${vmi_network_conf} != ${None}
    ...  Set Static IPv4 Address To VMI And Verify  ${vmi_network_conf["IPv4_Address"]}
    ...  ${vmi_network_conf["IPv4_Gateway"]}  ${vmi_network_conf["IPv4_SubnetMask"]}
    Delete All Redfish Sessions
    Redfish.Logout


Set VMI Invalid Static IPv6 Address And Verify
    [Documentation]  Set VMI invalid static IPv6 address and verify it throws an error.
    [Arguments]  ${invalid_vmi_ipv6addr}  ${invalid_prefix_length}  ${valid_status_codes}
    ...  ${interface}=${ethernet_interface}

    # Description of argument(s):
    # invalid_vmi_ipv6addr           VMI IPv6 address to be added.
    # invalid_prefix_length          Prefix length for the VMI IPv6 to be added.
    # valid_status_codes             Expected status code for PATCH request.
    # interface                      VMI interface (eg. eth0 or eth1).

    Set Static VMI IPv6 Address  ${invalid_vmi_ipv6addr}  ${invalid_prefix_length}
    ...  ${valid_status_codes}

    ${resp}=  Redfish.Get  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}

    @{vmi_ipv6_address}=  Get From Dictionary  ${resp.dict}  IPv6Addresses
    ${vmi_ipv6_addr}=  Get From List  ${vmi_ipv6_address}  0
    Should Not Be Equal  ${vmi_ipv6_addr["Address"]}  ${invalid_vmi_ipv6addr}


Delete VMI IPv6 Static Default Gateway Address
    [Documentation]  Delete VMI IPv6 static default gateway address.
    [Arguments]  ${valid_status_codes}=${HTTP_ACCEPTED}
    ...  ${interface}=${ethernet_interface}

    # Description of argument(s):
    # valid_status_codes       Expected valid status code from PATCH request.
    # interface                VMI interface (eg. eth0 or eth1).

    ${data}=  Set Variable  {"IPv6StaticDefaultGateways": [${Null}]}
    Redfish.Patch  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}
    ...  body=${data}  valid_status_codes=[${valid_status_codes}]

    Sleep  5s
