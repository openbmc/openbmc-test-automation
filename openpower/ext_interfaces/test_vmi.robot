*** Settings ***
Documentation       VMI static/dynamic IP config tests.

Resource            ../../lib/external_intf/vmi_utils.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Run Keyword And Ignore Error    Suite Teardown Execution
Test Teardown       FFDC On Test Case Fail

Test Tags           vmi


*** Variables ***
# users    User Name    password
@{ADMIN}            admin_user    TestPwd123
@{OPERATOR}         operator_user    TestPwd123
@{ReadOnly}         readonly_user    TestPwd123
&{USERS}            Administrator=${ADMIN}    ReadOnly=${ReadOnly}

${test_ipv4}        10.6.6.6
${test_gateway}     10.6.6.1
${test_netmask}     255.255.252.0

&{DHCP_ENABLED}     DHCPEnabled=${${True}}
&{DHCP_DISABLED}    DHCPEnabled=${${False}}

&{ENABLE_DHCP}      DHCPv4=&{DHCP_ENABLED}
&{DISABLE_DHCP}     DHCPv4=&{DHCP_DISABLED}

${default}          0.0.0.0


*** Test Cases ***
Verify All VMI EthernetInterfaces
    [Documentation]    Verify all VMI ethernet interfaces.
    [Tags]    verify_all_vmi_ethernetinterfaces

    Verify VMI EthernetInterfaces

Verify Existing VMI Network Interface Details
    [Documentation]    Verify existing VMI network interface details.
    [Tags]    verify_existing_vmi_network_interface_details

    ${vmi_ip}=    Get VMI Network Interface Details
    ${origin}=    Set Variable If    ${vmi_ip["DHCPv4"]} == ${False}    Static    DHCP
    Should Not Be Equal    ${vmi_ip["DHCPv4"]}    ${vmi_ip["IPv4StaticAddresses"]}
    Should Be Equal As Strings    ${vmi_ip["Id"]}    ${ethernet_interface}
    Should Be Equal As Strings    ${vmi_ip["Description"]}
    ...    Hypervisor's Virtual Management Ethernet Interface
    Should Be Equal As Strings    ${vmi_ip["Name"]}    Hypervisor Ethernet Interface
    IF    ${vmi_ip["IPv4StaticAddresses"]} != @{empty}
        Verify VMI Network Interface Details
        ...    ${vmi_ip["IPv4_Address"]}
        ...    ${origin}
        ...    ${vmi_ip["IPv4_Gateway"]}
        ...    ${vmi_ip["IPv4_SubnetMask"]}
    END

Delete Existing Static VMI IP Address
    [Documentation]    Delete existing static VMI IP address.
    [Tags]    delete_existing_static_vmi_ip_address

    ${curr_origin}=    Get Immediate Child Parameter From VMI Network Interface    DHCPEnabled
    IF    ${curr_origin} == ${True}
        Set VMI IPv4 Origin    ${False}    ${HTTP_ACCEPTED}
    END

    Delete VMI IPv4 Address

Verify User Cannot Delete ReadOnly Property IPv4Addresses
    [Documentation]    Verify user cannot delete readonly property IPv4Addresses.
    [Tags]    verify_user_cannot_delete_readonly_property_ipv4addresses

    ${curr_origin}=    Get Immediate Child Parameter From VMI Network Interface    DHCPEnabled
    IF    ${curr_origin} == ${True}
        Set VMI IPv4 Origin    ${False}    ${HTTP_ACCEPTED}
    END
    Set Static IPv4 Address To VMI And Verify    ${test_ipv4}    ${test_gateway}    ${test_netmask}
    Delete VMI IPv4 Address    IPv4Addresses    valid_status_code=${HTTP_FORBIDDEN}

Assign Valid And Invalid Static IPv4 Address To VMI
    [Documentation]    Assign static IPv4 address to VMI.
    [Tags]    assign_valid_and_invalid_static_ipv4_address_to_vmi
    [Template]    Set Static IPv4 Address To VMI And Verify

    # ip    gateway    netmask    valid_status_code
    10.5.20.30    10.5.20.1    255.255.252.0    ${HTTP_ACCEPTED}
    a.3.118.94    10.5.20.1    255.255.252.0    ${HTTP_BAD_REQUEST}
    10.5.20    10.5.20.1    255.255.252.0    ${HTTP_BAD_REQUEST}
    10.5.20.-5    10.5.20.1    255.255.252.0    ${HTTP_BAD_REQUEST}
    [Teardown]    Run keywords    Delete VMI IPv4 Address    AND    Test Teardown Execution

Add Multiple IP Addresses On VMI Interface And Verify
    [Documentation]    Add multiple IP addresses on VMI interface and verify.
    [Tags]    add_multiple_ip_addresses_on_vmi_interface_and_verify

    ${ip1}=    Create dictionary    Address=10.5.5.10    SubnetMask=255.255.252.0    Gateway=10.5.5.1
    ${ip2}=    Create dictionary    Address=10.5.5.11    SubnetMask=255.255.252.0    Gateway=10.5.5.1
    ${ip3}=    Create dictionary    Address=10.5.5.12    SubnetMask=255.255.252.0    Gateway=10.5.5.1
    ${ips}=    Create List    ${ip1}    ${ip2}    ${ip3}

    Redfish.Patch    /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    ...    body={'IPv4StaticAddresses':${ips}}    valid_status_codes=[${HTTP_BAD_REQUEST}]
    [Teardown]    Run keywords    Delete VMI IPv4 Address    AND    Test Teardown Execution

Modify IP Addresses On VMI Interface And Verify
    [Documentation]    Modify IP addresses on VMI interface and verify.
    [Tags]    modify_ip_addresses_on_vmi_interface_and_verify
    [Template]    Set Static IPv4 Address To VMI And Verify

    # ip    gateway    netmask    valid_status_code
    10.5.5.10    10.5.5.1    255.255.252.0    ${HTTP_ACCEPTED}
    10.5.5.11    10.5.5.1    255.255.252.0    ${HTTP_ACCEPTED}
    [Teardown]    Run keywords    Delete VMI IPv4 Address    AND    Test Teardown Execution

Switch Between IP Origins On VMI And Verify Details
    [Documentation]    Switch between IP origins on VMI and verify details.
    [Tags]    switch_between_ip_origins_on_vmi_and_verify_details

    Switch VMI IPv4 Origin And Verify Details
    Switch VMI IPv4 Origin And Verify Details

Verify Persistency Of VMI IPv4 Details After Host Reboot
    [Documentation]    Verify persistency of VMI IPv4 details after host reboot.
    [Tags]    verify_persistency_of_vmi_ipv4_details_after_host_reboot

    # Verifying persistency of dynamic address.
    Set VMI IPv4 Origin    ${True}    ${HTTP_ACCEPTED}
    Redfish Power Off    stack_mode=skip
    Redfish Power On
    Verify VMI Network Interface Details    ${default}    DHCP    ${default}    ${default}

    # Verifying persistency of static address.
    Switch VMI IPv4 Origin And Verify Details
    Redfish Power Off    stack_mode=skip
    Redfish Power On
    Set Static IPv4 Address To VMI And Verify    ${test_ipv4}    ${test_gateway}    ${test_netmask}

Delete VMI Static IP Address And Verify
    [Documentation]    Delete VMI static IP address and verify.
    [Tags]    delete_vmi_static_ip_address_and_verify

    Set Static IPv4 Address To VMI And Verify    ${test_ipv4}    ${test_gateway}    ${test_netmask}
    Delete VMI IPv4 Address
    [Teardown]    Test Teardown Execution

Verify Successful VMI IP Static Configuration On HOST Boot After Session Delete
    [Documentation]    Verify VMI IP static Configuration On HOST Boot After session deleted.
    [Tags]    verify_successful_vmi_ip_static_configuration_on_host_boot_after_session_delete

    Set Static IPv4 Address To VMI And Verify    ${test_ipv4}    ${test_gateway}    ${test_netmask}

    ${session_info}=    Get Redfish Session Info
    Redfish.Delete    ${session_info["location"]}

    # Create a new Redfish session
    Redfish.Login
    Redfish Power Off
    Redfish Power On

    Verify VMI Network Interface Details    ${test_ipv4}    Static    ${test_gateway}    ${test_netmask}
    [Teardown]    Run keywords    Delete VMI IPv4 Address    AND    Test Teardown Execution

Verify Persistency Of VMI DHCP IP Configuration After Multiple HOST Reboots
    [Documentation]    Verify Persistency Of VMI DHCP IP configuration After Multiple HOST Reboots
    [Tags]    verify_persistency_of_vmi_dhcp_ip_configuration_after_multiple_host_reboots

    Set VMI IPv4 Origin    ${True}    ${HTTP_ACCEPTED}
    ${vmi_ip_config}=    Get VMI Network Interface Details
    # Verifying persistency of dynamic address after multiple reboots.
    FOR    ${i}    IN RANGE    ${2}
        Redfish Power Off
        Redfish Power On
        Verify VMI Network Interface Details    ${vmi_ip_config["IPv4_Address"]}
        ...    DHCP    ${vmi_ip_config["IPv4_Gateway"]}    ${vmi_ip_config["IPv4_SubnetMask"]}
    END
    [Teardown]    Test Teardown Execution

Enable DHCP When Static IP Configured And Verify Static IP
    [Documentation]    Enable DHCP when static ip configured and verify static ip
    [Tags]    enable_dhcp_when_static_ip_configured_and_verify_static_ip
    [Setup]    Redfish Power On

    Set Static IPv4 Address To VMI And Verify    ${test_ipv4}    ${test_gateway}    ${test_netmask}
    Set VMI IPv4 Origin    ${True}
    ${vmi_network_conf}=    Get VMI Network Interface Details
    Should Not Be Equal As Strings    ${test_ipv4}    ${vmi_network_conf["IPv4_Address"]}
    [Teardown]    Test Teardown Execution

Verify VMI Static IP Configuration Persist On BMC Reset Before Host Boot
    [Documentation]    Verify VMI static IP configuration persist on BMC reset.
    [Tags]    verify_vmi_static_ip_configuration_persist_on_bmc_reset_before_host_boot

    Set Static IPv4 Address To VMI And Verify    ${test_ipv4}    ${test_gateway}    ${test_netmask}
    Redfish OBMC Reboot (off)    stack_mode=skip
    Redfish Power On
    # Verifying the VMI static configuration
    Verify VMI Network Interface Details    ${test_ipv4}    Static    ${test_gateway}    ${test_netmask}
    [Teardown]    Run keywords    Delete VMI IPv4 Address    AND    FFDC On Test Case Fail

Add Static IP When Host Poweroff And Verify On Poweron
    [Documentation]    Add Static IP When Host Poweroff And Verify on power on
    [Tags]    add_static_ip_when_host_poweroff_and_verify_on_poweron
    [Setup]    Redfish Power Off

    Set Static IPv4 Address To VMI And Verify    ${test_ipv4}    ${test_gateway}    ${test_netmask}
    Redfish Power On
    Verify VMI Network Interface Details    ${test_ipv4}    Static    ${test_gateway}    ${test_netmask}
    [Teardown]    Run keywords    Delete VMI IPv4 Address    AND    FFDC On Test Case Fail

Add VMI Static IP When Host Poweroff And Verify Static IP On BMC Reset
    [Documentation]    Add Static IP When Host Poweroff And Verify Static IP On BMC Reset.
    [Tags]    add_vmi_static_ip_when_host_poweroff_and_verify_static_ip_on_bmc_reset
    [Setup]    Redfish Power Off

    Set Static IPv4 Address To VMI And Verify    ${test_ipv4}    ${test_gateway}    ${test_netmask}
    Redfish OBMC Reboot (off)    stack_mode=skip
    Redfish Power On
    Verify VMI Network Interface Details    ${test_ipv4}    Static    ${test_gateway}    ${test_netmask}
    [Teardown]    Run keywords    Delete VMI IPv4 Address    AND    FFDC On Test Case Fail

Enable DHCP When No Static IP Configured And Verify DHCP IP
    [Documentation]    Enable DHCP when no static ip configured and verify dhcp ip
    [Tags]    enable_dhcp_when_no_static_ip_configured_and_verify_dhcp_ip
    [Setup]    Run Keyword And Ignore Error    Delete VMI IPv4 Address

    ${curr_origin}=    Get Immediate Child Parameter From VMI Network Interface    DHCPEnabled
    IF    ${curr_origin} == ${False}
        Set VMI IPv4 Origin    ${True}    ${HTTP_ACCEPTED}
    END
    ${vmi_ip_config}=    Get VMI Network Interface Details
    Verify VMI Network Interface Details    ${vmi_ip_config["IPv4_Address"]}
    ...    DHCP    ${vmi_ip_config["IPv4_Gateway"]}    ${vmi_ip_config["IPv4_SubnetMask"]}
    [Teardown]    Test Teardown Execution

Verify User Cannot Delete VMI DHCP IP Address
    [Documentation]    Verify user cannot delete VMI DHCP IP Address
    [Tags]    verify_user_cannot_delete_vmi_dhcp_ip_address
    [Setup]    Set VMI IPv4 Origin    ${True}

    Delete VMI IPv4 Address    IPv4Addresses    valid_status_code=${HTTP_FORBIDDEN}
    ${resp}=    Redfish.Get
    ...    /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    Should Not Be Empty    ${resp.dict["IPv4Addresses"]}
    [Teardown]    Test Teardown Execution

Enable DHCP When Static IP Configured DHCP Server Unavailable And Verify IP
    [Documentation]    Enable DHCP When Static IP Configured And DHCP Server Unavailable And Verify No IP.
    [Tags]    enable_dhcp_when_static_ip_configured_dhcp_server_unavailable_and_verify_ip

    Set Static IPv4 Address To VMI And Verify    ${test_ipv4}    ${test_gateway}    ${test_netmask}
    Set VMI IPv4 Origin    ${True}
    Verify VMI Network Interface Details    ${default}    DHCP    ${default}    ${default}
    [Teardown]    Test Teardown Execution

Verify To Configure VMI Static IP Address With Different User Roles
    [Documentation]    Verify to configure vmi static ip address with different user roles.
    [Tags]    verify_to_configure_vmi_static_ip_address_with_different_user_roles
    [Template]    Config VMI Static IP Address Using Different Users
    [Setup]    Run Keywords    Delete BMC Users Using Redfish
    ...    AND    Create Users With Different Roles    users=${USERS}    force=${True}

    # username    password    ip_address    gateway    nemask    valid_status_code
    admin_user    TestPwd123    ${test_ipv4}    ${test_gateway}    ${test_netmask}    ${HTTP_ACCEPTED}
    readonly_user    TestPwd123    ${test_ipv4}    ${test_gateway}    ${test_netmask}    ${HTTP_FORBIDDEN}
    [Teardown]    Delete BMC Users Using Redfish

Verify To Configure VMI Static IP Address With Operator User Role
    [Documentation]    Verify to configure vmi static ip address with operator user role.
    [Tags]    verify_to_configure_vmi_static_ip_address_with_operator_user_role
    [Template]    Config VMI Static IP Address Using Different Users
    [Setup]    Create Users With Different Roles    users=${USERS}    force=${True}

    # username    password    ip_address    gateway    nemask    valid_status_code
    operator_user    TestPwd123    ${test_ipv4}    ${test_gateway}    ${test_netmask}    ${HTTP_FORBIDDEN}
    [Teardown]    Delete BMC Users Using Redfish

Verify To Delete VMI Static IP Address With Different User Roles
    [Documentation]    Verify to delete vmi static IP address with different user roles.
    [Tags]    verify_to_delete_vmi_static_ip_address_with_different_user_roles
    [Template]    Delete VMI Static IP Address Using Different Users
    [Setup]    Create Users With Different Roles    users=${USERS}    force=${True}

    # username    password    valid_status_code
    admin_user    TestPwd123    ${HTTP_ACCEPTED}
    readonly_user    TestPwd123    ${HTTP_FORBIDDEN}
    [Teardown]    Delete BMC Users Using Redfish

Verify To Delete VMI Static IP Address With Operator User Role
    [Documentation]    Verify to delete vmi static IP address with operator user role.
    [Tags]    verify_to_delete_vmi_static_ip_address_with_operator_user_role
    [Template]    Delete VMI Static IP Address Using Different Users
    [Setup]    Create Users With Different Roles    users=${USERS}    force=${True}

    # username    password    valid_status_code
    operator_user    TestPwd123    ${HTTP_FORBIDDEN}
    [Teardown]    Delete BMC Users Using Redfish

Verify To Update VMI Static IP Address With Different User Roles
    [Documentation]    Verify to update vmi static IP address with different user roles.
    [Tags]    verify_to_update_vmi_static_ip_address_with_different_user_roles
    [Template]    Config VMI Static IP Address Using Different Users
    [Setup]    Create Users With Different Roles    users=${USERS}    force=${True}

    # username    password    ip_address    gateway    netmask    valid_status_code
    admin_user    TestPwd123    10.5.10.20    10.5.10.1    255.255.0.0    ${HTTP_ACCEPTED}
    readonly_user    TestPwd123    10.5.20.40    10.5.20.1    255.255.0.0    ${HTTP_FORBIDDEN}
    [Teardown]    Delete BMC Users Using Redfish

Verify To Update VMI Static IP Address With Operator User Role
    [Documentation]    Verify to update vmi static IP address with operator user role.
    [Tags]    verify_to_update_vmi_static_ip_address_with_operator_user_role
    [Template]    Config VMI Static IP Address Using Different Users
    [Setup]    Create Users With Different Roles    users=${USERS}    force=${True}

    # username    password    ip_address    gateway    netmask    valid_status_code
    operator_user    TestPwd123    10.5.10.30    10.5.10.1    255.255.0.0    ${HTTP_FORBIDDEN}
    [Teardown]    Delete BMC Users Using Redfish

Verify To Read VMI Network Configuration With Different User Roles
    [Documentation]    Verify to read vmi network configuration with different user roles.
    [Tags]    verify_to_read_vmi_network_configuration_with_different_user_roles
    [Template]    Read VMI Static IP Address Using Different Users
    [Setup]    Create Users With Different Roles    users=${USERS}    force=${True}

    # username    password    valid_status_code
    admin_user    TestPwd123    ${HTTP_OK}
    readonly_user    TestPwd123    ${HTTP_OK}
    [Teardown]    Delete BMC Users Using Redfish

Verify To Read VMI Network Configuration With Operator User Role
    [Documentation]    Verify to read vmi network configuration with operator user role.
    [Tags]    verify_to_read_vmi_network_configuration_with_operator_user_role
    [Template]    Read VMI Static IP Address Using Different Users
    [Setup]    Create Users With Different Roles    users=${USERS}    force=${True}

    # username    password    valid_status_code
    operator_user    TestPwd123    ${HTTP_FORBIDDEN}
    [Teardown]    Delete BMC Users Using Redfish

Enable DHCP On VMI Network Via Different Users Roles And Verify
    [Documentation]    Enable DHCP On VMI Network Via Different Users Roles And Verify.
    [Tags]    enable_dhcp_on_vmi_network_via_different_users_roles_and_verify
    [Template]    Update User Role And Set VMI IPv4 Origin
    [Setup]    Create Users With Different Roles    users=${USERS}    force=${True}

    # username    password    dhcp_enabled    valid_status_code
    admin_user    TestPwd123    ${True}    ${HTTP_ACCEPTED}
    readonly_user    TestPwd123    ${True}    ${HTTP_FORBIDDEN}
    [Teardown]    Delete BMC Users Using Redfish

Enable DHCP On VMI Network Via Operator User Role And Verify
    [Documentation]    Enable DHCP On VMI Network Via Operator User Role And Verify.
    [Tags]    enable_dhcp_on_vmi_network_via_operator_user_role_and_verify
    [Template]    Update User Role And Set VMI IPv4 Origin
    [Setup]    Create Users With Different Roles    users=${USERS}    force=${True}

    # username    password    dhcp_enabled    valid_status_code
    operator_user    TestPwd123    ${True}    ${HTTP_FORBIDDEN}
    [Teardown]    Delete BMC Users Using Redfish

Disable DHCP On VMI Network Via Different Users Roles And Verify
    [Documentation]    Disable DHCP On VMI Network Via Different Users Roles And Verify.
    [Tags]    disable_dhcp_on_vmi_network_via_different_users_roles_and_verify
    [Template]    Update User Role And Set VMI IPv4 Origin
    [Setup]    Create Users With Different Roles    users=${USERS}    force=${True}

    # username    password    dhcp_enabled    valid_status_code
    admin_user    TestPwd123    ${False}    ${HTTP_ACCEPTED}
    readonly_user    TestPwd123    ${False}    ${HTTP_FORBIDDEN}
    [Teardown]    Delete BMC Users Using Redfish

Disable DHCP On VMI Network Via Operator User Role And Verify
    [Documentation]    Disable DHCP On VMI Network Via Operator User Role And Verify.
    [Tags]    disable_dhcp_on_vmi_network_via_operator_user_role_and_verify
    [Template]    Update User Role And Set VMI IPv4 Origin
    [Setup]    Create Users With Different Roles    users=${USERS}    force=${True}

    # username    password    dhcp_enabled    valid_status_code
    operator_user    TestPwd123    ${False}    ${HTTP_FORBIDDEN}
    [Teardown]    Delete BMC Users Using Redfish

Enable And Disable DHCP And Verify
    [Documentation]    verify enable DHCP and disable DHCP.
    [Tags]    enable_and_disable_dhcp_and_verify

    Set VMI IPv4 Origin    ${True}
    Verify VMI Network Interface Details    ${default}    DHCP    ${default}    ${default}
    Set VMI IPv4 Origin    ${False}
    Verify VMI Network Interface Details    ${default}    Static    ${default}    ${default}

Multiple Times Enable And Disable DHCP And Verify
    [Documentation]    Enable and Disable DHCP in a loop and verify VMI gets an IP address from DHCP
    ...    each time when DHCP is enabled
    [Tags]    multiple_times_enable_and_disable_dhcp_and_verify

    FOR    ${i}    IN RANGE    ${2}
        Set VMI IPv4 Origin    ${True}
        Verify VMI Network Interface Details    ${default}    DHCP    ${default}    ${default}
        Set VMI IPv4 Origin    ${False}
        Verify VMI Network Interface Details    ${default}    Static    ${default}    ${default}
    END

Assign Static IPv4 Address With Invalid Netmask To VMI
    [Documentation]    Assign static IPv4 address with invalid netmask and expect error.
    [Tags]    assign_static_ipv4_address_with_invalid_netmask_to_vmi
    [Template]    Set Static IPv4 Address To VMI And Verify

    # ip    gateway    netmask    valid_status_code
    ${test_ipv4}    ${test_gateway}    255.256.255.0    ${HTTP_BAD_REQUEST}
    ${test_ipv4}    ${test_gateway}    ff.ff.ff.ff    ${HTTP_BAD_REQUEST}
    ${test_ipv4}    ${test_gateway}    255.255.253.0    ${HTTP_BAD_REQUEST}

Assign Static IPv4 Address With Invalid Gateway To VMI
    [Documentation]    Add static IPv4 address with invalid gateway and expect error.
    [Tags]    assign_static_ipv4_address_with_invalid_gateway_to_vmi
    [Template]    Set Static IPv4 Address To VMI And Verify

    # ip    gateway    netmask    valid_status_code
    ${test_ipv4}    @@@.%%.44.11    ${test_netmask}    ${HTTP_BAD_REQUEST}
    ${test_ipv4}    0xa.0xb.0xc.0xd    ${test_netmask}    ${HTTP_BAD_REQUEST}
    ${test_ipv4}    10.3.36    ${test_netmask}    ${HTTP_BAD_REQUEST}
    ${test_ipv4}    10.3.36.-10    ${test_netmask}    ${HTTP_BAD_REQUEST}

Enable DHCP When Host Is Off And Verify After Poweron
    [Documentation]    Enable DHCP when host is off and
    ...    check whether it is enabled after poweron.
    [Tags]    enable_dhcp_when_host_is_off_and_verify_after_poweron
    [Setup]    Redfish Power Off    stack_mode=skip

    Set VMI IPv4 Origin    ${True}
    Redfish Power On    stack_mode=skip
    Verify VMI Network Interface Details    ${default}    DHCP    ${default}    ${default}

Disable DHCP When Host Is Off And Verify New State Reflects After Power On
    [Documentation]    Disable DHCP when host is off and
    ...    get network info and verify that VMI origin is static.
    [Tags]    disable_dhcp_when_host_is_off_and_verify_new_state_reflects_after_power_on
    [Setup]    Redfish Power Off    stack_mode=skip

    Set VMI IPv4 Origin    ${False}
    Redfish Power On    stack_mode=skip
    Verify VMI Network Interface Details    ${default}    Static    ${default}    ${default}


*** Keywords ***
Suite Setup Execution
    [Documentation]    Do test setup execution task.

    Redfish.Login

    Redfish Power Off
    Set BIOS Attribute    pvm_hmc_managed    Enabled
    Set BIOS Attribute    pvm_stop_at_standby    Disabled

    Redfish Power On
    Wait For Host Boot Progress To Reach Required State

    ${active_channel_config}=    Get Active Channel Config
    Set Suite Variable    ${active_channel_config}
    Set Suite Variable    ${ethernet_interface}    ${active_channel_config['${CHANNEL_NUMBER}']['name']}
    ${resp}=    Redfish.Get
    ...    /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    ${ip_resp}=    Evaluate    json.loads(r'''${resp.text}''')    json
    ${length}=    Get Length    ${ip_resp["IPv4StaticAddresses"]}
    IF    ${length} != ${0}
        ${vmi_network_conf}=    Get VMI Network Interface Details
    ELSE
        ${vmi_network_conf}=    Set Variable    ${None}
    END
    Set Suite Variable    ${vmi_network_conf}

Test Teardown Execution
    [Documentation]    Do test teardown execution task.

    FFDC On Test Case Fail
    ${curr_mode}=    Get Immediate Child Parameter From VMI Network Interface    DHCPEnabled
    IF    ${curr_mode} == ${True}    Set VMI IPv4 Origin    ${False}
    IF    '${vmi_network_conf["IPv4_Address"]}' != '${default}'
        Set Static IPv4 Address To VMI And Verify
        ...    ${vmi_network_conf["IPv4_Address"]}
        ...    ${vmi_network_conf["IPv4_Gateway"]}
        ...    ${vmi_network_conf["IPv4_SubnetMask"]}
    END

Get Immediate Child Parameter From VMI Network Interface
    [Documentation]    Get immediate child parameter from VMI network interface.
    [Arguments]    ${parameter}    ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # parameter    parameter for which value is required. Ex: DHCPEnabled, MACAddress etc.
    # valid_status_code    Expected valid status code from GET request.

    ${resp}=    Redfish.Get
    ...    /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    ...    valid_status_codes=[${valid_status_code}]

    ${ip_resp}=    Evaluate    json.loads(r'''${resp.text}''')    json
    ${value}=    Set Variable If    '${parameter}' != 'DHCPEnabled'    ${ip_resp["${parameter}"]}
    ...    ${ip_resp["DHCPv4"]["${parameter}"]}

    RETURN    ${value}

Switch VMI IPv4 Origin And Verify Details
    [Documentation]    Switch VMI IPv4 origin and verify details.

    ${dhcp_mode_before}=    Get Immediate Child Parameter From VMI Network Interface    DHCPEnabled
    ${dhcp_enabled}=    Set Variable If    ${dhcp_mode_before} == ${False}    ${True}    ${False}

    ${origin}=    Set Variable If    ${dhcp_mode_before} == ${False}    DHCP    Static
    Set VMI IPv4 Origin    ${dhcp_enabled}    ${HTTP_ACCEPTED}

    ${dhcp_mode_after}=    Get Immediate Child Parameter From VMI Network Interface    DHCPEnabled
    Should Not Be Equal    ${dhcp_mode_before}    ${dhcp_mode_after}

    IF    ${dhcp_mode_after} == ${True}
        Verify VMI Network Interface Details    ${default}    ${origin}    ${default}    ${default}
    END

Delete VMI Static IP Address Using Different Users
    [Documentation]    Update user role and delete vmi static IP address.
    [Arguments]    ${username}    ${password}    ${valid_status_code}

    # Description of argument(s):
    # username    The host username.
    # password    The host password.
    # valid_status_code    The expected valid status code.

    # TODO: operator_user role is not yet supported.
    Skip If    '${username}' == 'operator_user'
    Redfish.Login    ${username}    ${password}
    Delete VMI IPv4 Address    delete_param=IPv4StaticAddresses    valid_status_code=${valid_status_code}
    [Teardown]    Run Keywords    Redfish.Login    AND
    ...    Set Static IPv4 Address To VMI And Verify    ${test_ipv4}    ${test_gateway}
    ...    ${test_netmask}    ${HTTP_ACCEPTED}    AND    Redfish.Logout

Config VMI Static IP Address Using Different Users
    [Documentation]    Update user role and update vmi static ip address.
    [Arguments]    ${username}    ${password}    ${ip}    ${gateway}    ${netmask}
    ...    ${valid_status_code}

    # Description of argument(s):
    # username    The host username.
    # password    The host password.
    # ip    IP address to be added (e.g. "10.7.7.7").
    # subnet_mask    Subnet mask for the IP to be added
    #    (e.g. "255.255.0.0").
    # gateway    Gateway for the IP to be added (e.g. "10.7.7.1").
    # valid_status_code    The expected valid status code.

    # TODO: operator_user role is not yet supported.
    Skip If    '${username}' == 'operator_user'
    Redfish.Login    ${username}    ${password}
    Set Static IPv4 Address To VMI And Verify    ${ip}    ${gateway}    ${netmask}    ${valid_status_code}

Read VMI Static IP Address Using Different Users
    [Documentation]    Update user role and read vmi static ip address.
    [Arguments]    ${username}    ${password}    ${valid_status_code}

    # Description of argument(s):
    # username    The host username.
    # password    The host password.
    # valid_status_code    The expected valid status code.

    # TODO: operator_user role is not yet supported.
    Skip If    '${username}' == 'operator_user'
    Redfish.Login    ${username}    ${password}
    Redfish.Get
    ...    /redfish/v1/Systems/hypervisor/EthernetInterfaces/${ethernet_interface}
    ...    valid_status_codes=[${valid_status_code}]

Delete BMC Users Using Redfish
    [Documentation]    Delete BMC users via redfish.

    Redfish.Login
    Delete BMC Users Via Redfish    users=${USERS}

Update User Role And Set VMI IPv4 Origin
    [Documentation]    Update User Role And Set VMI IPv4 Origin.
    [Arguments]    ${username}    ${password}    ${dhcp_enabled}    ${valid_status_code}

    # Description of argument(s):
    # username    The host username.
    # password    The host password.
    # dhcp_enabled    Indicates whether dhcp should be enabled
    #    (${True}, ${False}).
    # valid_status_code    The expected valid status code.

    # TODO: operator_user role is not yet supported.
    Skip If    '${username}' == 'operator_user'
    Redfish.Login    ${username}    ${password}
    Set VMI IPv4 Origin    ${dhcp_enabled}    ${valid_status_code}

Suite Teardown Execution
    [Documentation]    Do suite teardown execution task.

    IF    ${vmi_network_conf} != ${None}
        Set Static IPv4 Address To VMI And Verify
        ...    ${vmi_network_conf["IPv4_Address"]}
        ...    ${vmi_network_conf["IPv4_Gateway"]}
        ...    ${vmi_network_conf["IPv4_SubnetMask"]}
    END
    Delete All Redfish Sessions
    Redfish.Logout
