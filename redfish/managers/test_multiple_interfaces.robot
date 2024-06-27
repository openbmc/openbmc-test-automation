*** Settings ***
Documentation       Test BMC multiple network interface functionalities.

# User input BMC IP for the eth1.
# Use can input as    -v OPENBMC_HOST_1:xx.xxx.xx from command line.
Library             ../../lib/bmc_redfish.py    https://${OPENBMC_HOST_1}:${HTTPS_PORT}
...                 ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}    WITH NAME    Redfish1
Resource            ../../lib/resource.robot
Resource            ../../lib/common_utils.robot
Resource            ../../lib/connection_client.robot
Resource            ../../lib/bmc_network_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/bmc_ldap_utils.robot
Resource            ../../lib/snmp/resource.robot
Resource            ../../lib/snmp/redfish_snmp_utils.robot
Resource            ../../lib/certificate_utils.robot
Library             ../../lib/jobs_processing.py
Library             OperatingSystem

Suite Setup         Suite Setup Execution
Suite Teardown      Run Keywords    Redfish1.Logout    AND    Redfish.Logout
Test Teardown       FFDC On Test Case Fail


*** Variables ***
${cmd_prefix}           ipmitool -I lanplus -C 17 -p 623 -U ${OPENBMC_USERNAME} -P ${OPENBMC_PASSWORD}
${test_ipv4_addr}       10.7.7.7
${test_ipv4_addr2}      10.7.7.8
${test_subnet_mask}     255.255.255.0


*** Test Cases ***
Verify Both Interfaces BMC IP Addresses Accessible Via SSH
    [Documentation]    Verify both interfaces (eth0, eth1) BMC IP addresses accessible via SSH.
    [Tags]    verify_both_interfaces_bmc_ip_addresses_accessible_via_ssh

    Open Connection And Log In    ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}    host=${OPENBMC_HOST}
    Open Connection And Log In    ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}    host=${OPENBMC_HOST_1}
    Close All Connections

Verify Redfish Works On Both Interfaces
    [Documentation]    Verify access BMC with both interfaces (eth0, eth1) IP addresses via Redfish.
    [Tags]    verify_redfish_works_on_both_interfaces

    Redfish1.Login
    Redfish.Login

    ${hostname}=    Redfish.Get Attribute    ${REDFISH_NW_PROTOCOL_URI}    HostName
    ${data}=    Create Dictionary    HostName=openbmc
    Redfish1.patch    ${REDFISH_NW_ETH_IFACE}eth1    body=&{data}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    Validate Hostname On BMC    openbmc

    ${resp1}=    Redfish.Get    ${REDFISH_NW_ETH_IFACE}eth0
    ${resp2}=    Redfish1.Get    ${REDFISH_NW_ETH_IFACE}eth1
    Should Be Equal    ${resp1.dict['HostName']}    ${resp2.dict['HostName']}
    [Teardown]    Run Keywords
    ...    Configure Hostname    ${hostname}    AND    Validate Hostname On BMC    ${hostname}

Verify LDAP Login Works When Eth1 IP Is Not Configured
    [Documentation]    Verify LDAP login works when eth1 IP is erased.
    [Tags]    verify_ldap_login_works_when_eth1_ip_is_not_configured
    [Setup]    Run Keywords    Set Test Variable    ${CHANNEL_NUMBER}    ${SECONDARY_CHANNEL_NUMBER}
    ...    AND    Delete IP Address    ${OPENBMC_HOST_1}
    ...    AND    Redfish.Login

    Create LDAP Configuration
    Redfish.Logout
    Redfish.Login    ${LDAP_USER}    ${LDAP_USER_PASSWORD}
    [Teardown]    Run Keywords    Redfish.Logout    AND
    ...    Add IP Address    ${OPENBMC_HOST_1}    ${eth1_subnet_mask}    ${eth1_gateway}

Verify LDAP Login Works When Both Interfaces Are Configured
    [Documentation]    Verify LDAP login works when both interfaces are configured.
    [Tags]    verify_ldap_login_works_when_both_interfaces_are_configured
    [Setup]    Redfish.Login

    Create LDAP Configuration
    Redfish.Logout
    Redfish.Login    ${LDAP_USER}    ${LDAP_USER_PASSWORD}
    [Teardown]    Redfish.Logout

Verify Secure LDAP Login Works When Both Interfaces Are Configured
    [Documentation]    Verify Secure LDAP login works when both the interfaces are configured.
    [Tags]    verify_secure_ldap_login_works_when_both_interfaces_are_configured
    [Setup]    Redfish.Login

    Create LDAP Configuration    ${LDAP_TYPE}    ${LDAP_SERVER_URI_1}    ${LDAP_BIND_DN}
    ...    ${LDAP_BIND_DN_PASSWORD}    ${LDAP_BASE_DN}
    Redfish.Logout
    Redfish.Login    ${LDAP_USER}    ${LDAP_USER_PASSWORD}
    [Teardown]    Redfish.Logout

Verify SNMP Works When Eth1 IP Is Not Configured
    [Documentation]    Verify SNMP works when eth1 IP is not configured.
    [Tags]    verify_snmp_works_when_eth1_ip_is_not_configured
    [Setup]    Run Keywords    Set Test Variable    ${CHANNEL_NUMBER}    ${SECONDARY_CHANNEL_NUMBER}
    ...    AND    Delete IP Address    ${OPENBMC_HOST_1}

    Create Error On BMC And Verify Trap
    [Teardown]    Run Keywords    Redfish.Login    AND
    ...    Add IP Address    ${OPENBMC_HOST_1}    ${eth1_subnet_mask}    ${eth1_gateway}

Disable And Enable Eth0 Interface
    [Documentation]    Disable and Enable eth0 ethernet interface via redfish.
    [Tags]    disable_and_enable_eth0_interface
    [Template]    Set BMC Ethernet Interfaces State

    # interface_ip    interface    enabled
    ${OPENBMC_HOST}    eth0    ${False}
    ${OPENBMC_HOST}    eth0    ${True}

Verify Both Interfaces Access Concurrently Via Redfish
    [Documentation]    Verify both interfaces access conurrently via redfish.
    [Tags]    verify_both_interfaces_access_concurrently_via_redfish

    Redfish.Login
    Redfish1.Login

    ${dict}=    Execute Process Multi Keyword    ${2}
    ...    Redfish.Patch ${REDFISH_NW_ETH_IFACE}eth0 body={'DHCPv4':{'UseDNSServers':${True}}}
    ...    Redfish1.Patch ${REDFISH_NW_ETH_IFACE}eth1 body={'DHCPv4':{'UseDNSServers':${True}}}

    Dictionary Should Not Contain Value    ${dict}    False
    ...    msg=One or more operations has failed.

    ${resp}=    Redfish.Get    ${REDFISH_NW_ETH_IFACE}eth0
    ${resp1}=    Redfish1.Get    ${REDFISH_NW_ETH_IFACE}eth1

    Should Be Equal    ${resp.dict["DHCPv4"]['UseDNSServers']}    ${True}
    Should Be Equal    ${resp1.dict["DHCPv4"]['UseDNSServers']}    ${True}

Able To Access Serial Console Via Both Network Interfaces
    [Documentation]    Able to access serial console via both network interfaces.
    [Tags]    able_to_access_serial_console_via_both_network_interfaces

    Open Connection And Log In    host=${OPENBMC_HOST}    port=2200
    Open Connection And Log In    host=${OPENBMC_HOST_1}    port=2200
    Close All Connections

Verify IPMI Works On Both Network Interfaces
    [Documentation]    Verify IPMI works on both network interfaces.
    [Tags]    verify_ipmi_works_on_both_network_interfaces

    Run IPMI    ${OPENBMC_HOST_1}    power on
    ${status1}=    Run IPMI    ${OPENBMC_HOST}    power status
    ${status2}=    Run IPMI    ${OPENBMC_HOST_1}    power status
    Should Be Equal    ${status1}    ${status2}

Verify Modifying IP Address Multiple Times On Interface
    [Documentation]    Verify modifying IP address multiple times on interface.
    [Tags]    verify_modifying_ip_address_multiple_times_on_interface

    ${test_gateway}=    Get BMC Default Gateway
    Add IP Address    ${test_ipv4_addr}    ${test_subnet_mask}    ${test_gateway}
    Update IP Address    ${test_ipv4_addr}    ${test_ipv4_addr2}    ${test_subnet_mask}    ${test_gateway}
    Update IP Address    ${test_ipv4_addr2}    ${test_ipv4_addr}    ${test_subnet_mask}    ${test_gateway}
    Run Keyword    Wait For Host To Ping    ${OPENBMC_HOST}    ${NETWORK_TIMEOUT}
    Run Keyword    Wait For Host To Ping    ${OPENBMC_HOST_1}    ${NETWORK_TIMEOUT}
    [Teardown]    Run Keywords
    ...    Delete IP Address    ${test_ipv4_addr}    AND    Test Teardown

Verify Able To Load Certificates Via Eth1 IP Address
    [Documentation]    Verify able to load certificates via eth1 IP address.
    [Tags]    verify_able_to_load_certificates_via_eth1_ip_address
    [Template]    Install Certificate Via Redfish And Verify
    [Setup]    Create Directory    certificate_dir

    # cert_type    cert_format    expected_status
    CA    Valid Certificate    ok
    Client    Valid Certificate Valid Privatekey    ok
    [Teardown]    Run Keywords    Remove Directory    certificate_dir    recursive=True
    ...    AND    FFDC On Test Case Fail


*** Keywords ***
Get Network Configuration Using Channel Number
    [Documentation]    Get ethernet interface.
    [Arguments]    ${channel_number}

    # Description of argument(s):
    # channel_number    Ethernet channel number, 1 is for eth0 and 2 is for eth1 (e.g. "1").

    ${active_channel_config}=    Get Active Channel Config
    ${ethernet_interface}=    Set Variable    ${active_channel_config['${channel_number}']['name']}
    ${resp}=    Redfish.Get    ${REDFISH_NW_ETH_IFACE}${ethernet_interface}

    @{network_configurations}=    Get From Dictionary    ${resp.dict}    IPv4StaticAddresses
    RETURN    @{network_configurations}

Suite Setup Execution
    [Documentation]    Do suite setup task.

    Valid Value    OPENBMC_HOST_1

    # Check both interfaces are configured and reachable.
    Ping Host    ${OPENBMC_HOST}
    Ping Host    ${OPENBMC_HOST_1}

    ${network_configurations}=    Get Network Configuration Using Channel Number    ${SECONDARY_CHANNEL_NUMBER}
    FOR    ${network_configuration}    IN    @{network_configurations}
        IF    '${network_configuration['Address']}' == '${OPENBMC_HOST_1}'
            Set Suite Variable    ${eth1_subnet_mask}    ${network_configuration['SubnetMask']}
            Set Suite Variable    ${eth1_gateway}    ${network_configuration['Gateway']}
            BREAK
        END
    END

Set BMC Ethernet Interfaces State
    [Documentation]    Set BMC ethernet interface state.
    [Arguments]    ${interface_ip}    ${interface}    ${enabled}

    # Description of argument(s):
    # interface_ip    IP address of ethernet interface.
    # interface    The ethernet interface name (eg. eth0 or eth1).
    # enabled    Indicates interface should be enabled (eg. True or False).

    Redfish1.Login

    ${data}=    Create Dictionary    InterfaceEnabled=${enabled}

    Redfish1.patch    ${REDFISH_NW_ETH_IFACE}${interface}    body=&{data}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    Sleep    ${NETWORK_TIMEOUT}s
    ${interface_status}=    Redfish1.Get Attribute    ${REDFISH_NW_ETH_IFACE}${interface}    InterfaceEnabled
    Should Be Equal    ${interface_status}    ${enabled}

    ${status}=    Run Keyword And Return Status    Ping Host    ${interface_ip}

    IF    ${enabled} == ${True}
        Should Be Equal    ${status}    ${True}
    ELSE
        Should Be Equal    ${status}    ${False}
    END
    [Teardown]    Redfish1.Logout

Run IPMI
    [Documentation]    Run IPMI command.
    [Arguments]    ${host}    ${sub_cmd}

    # Description of argument(s):
    # host    BMC host name or IP address.
    # sub_cmd    The IPMI command string to be executed.

    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd_prefix} -H ${host} ${sub_cmd}
    Should Be Equal As Strings    ${rc}    0
    RETURN    ${output}

Install Certificate Via Redfish And Verify
    [Documentation]    Install and verify certificate using Redfish.
    [Arguments]    ${cert_type}    ${cert_format}    ${expected_status}    ${delete_cert}=${True}

    # Description of argument(s):
    # cert_type    Certificate type (e.g. "Client" or "CA").
    # cert_format    Certificate file format
    #    (e.g. "Valid_Certificate_Valid_Privatekey").
    # expected_status    Expected status of certificate replace Redfish
    #    request (i.e. "ok" or "error").
    # delete_cert    Certificate will be deleted before installing if this True.

    # AUTH_URI is a global variable defined in lib/resource.robot
    Set Test Variable    ${AUTH_URI}    https://${OPENBMC_HOST_1}
    IF    '${cert_type}' == 'CA' and '${delete_cert}' == '${True}'
        Delete All CA Certificate Via Redfish
    ELSE IF    '${cert_type}' == 'Client' and '${delete_cert}' == '${True}'
        Delete Certificate Via BMC CLI    ${cert_type}
    END

    ${cert_file_path}=    Generate Certificate File Via Openssl    ${cert_format}
    ${bytes}=    OperatingSystem.Get Binary File    ${cert_file_path}
    ${file_data}=    Decode Bytes To String    ${bytes}    UTF-8

    ${certificate_uri}=    Set Variable If
    ...    '${cert_type}' == 'Client'    ${REDFISH_LDAP_CERTIFICATE_URI}
    ...    '${cert_type}' == 'CA'    ${REDFISH_CA_CERTIFICATE_URI}

    ${cert_id}=    Install Certificate File On BMC    ${certificate_uri}    ${expected_status}    data=${file_data}
    Logging    Installed certificate id: ${cert_id}

    Sleep    30s
    ${cert_file_content}=    OperatingSystem.Get File    ${cert_file_path}
    IF    '${expected_status}' == 'ok'
        ${bmc_cert_content}=    redfish_utils.Get Attribute    ${certificate_uri}/${cert_id}    CertificateString
    ELSE
        ${bmc_cert_content}=    Set Variable    ${None}
    END
    IF    '${expected_status}' == 'ok'
        Should Contain    ${cert_file_content}    ${bmc_cert_content}
    END
    RETURN    ${cert_id}
