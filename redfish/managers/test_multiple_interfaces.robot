*** Settings ***
Documentation   Test BMC multiple network interface functionalities.
...             Run on setup with both eth0 and eth1 in static mode.

Library         OperatingSystem
Resource        ../../lib/resource.robot
Resource        ../../lib/common_utils.robot
Resource        ../../lib/connection_client.robot
Resource        ../../lib/bmc_network_utils.robot
Resource        ../../lib/openbmc_ffdc.robot
Resource        ../../lib/bmc_ldap_utils.robot
Resource        ../../lib/snmp/resource.robot
Resource        ../../lib/snmp/redfish_snmp_utils.robot
Resource        ../../lib/certificate_utils.robot
Resource         ../../lib/protocol_setting_utils.robot
Library         ../../lib/jobs_processing.py

# User input BMC IP for the eth1.
# Use can input as  -v OPENBMC_HOST_ETH1:xx.xxx.xx from command line.
Library         ../../lib/bmc_redfish.py  https://${OPENBMC_HOST_ETH1}:${HTTPS_PORT}
...             ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  AS  Redfish1

Suite Setup     Suite Setup Execution
Test Setup      Run Keywords  Redfish.Login  AND  Redfish1.Login
Test Teardown   Run Keywords  FFDC On Test Case Fail  AND  Redfish.Logout  AND  Redfish1.Logout
Suite Teardown  Run Keywords  Redfish1.Logout  AND  Redfish.Logout

Test Tags       Multiple_Interfaces

*** Variables ***

${cmd_prefix}  ipmitool -I lanplus -C 17 -p 623 -U ${IPMI_USERNAME} -P ${IPMI_PASSWORD}
${test_ipv4_addr}     10.7.7.7
${test_ipv4_addr2}    10.7.7.8
${test_subnet_mask}   255.255.255.0

# Time for the DHCP client to give up on the unreachable server and fall back to link-local.
${link_local_timeout}   3 min
${link_local_interval}  10 sec

*** Test Cases ***

Verify Both Interfaces BMC IP Addresses Accessible Via SSH
    [Documentation]  Verify both interfaces (eth0, eth1) BMC IP addresses accessible via SSH.
    [Tags]  Verify_Both_Interfaces_BMC_IP_Addresses_Accessible_Via_SSH

    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  host=${OPENBMC_HOST}
    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  host=${OPENBMC_HOST_ETH1}
    Close All Connections


Verify Redfish Works On Both Interfaces
    [Documentation]  Verify access BMC with both interfaces (eth0, eth1) IP addresses via Redfish.
    [Tags]  Verify_Redfish_Works_On_Both_Interfaces
    [Teardown]  Run Keywords
    ...  Configure Hostname  ${hostname}  AND  Validate Hostname On BMC  ${hostname}

    ${hostname}=  Redfish.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  HostName
    ${data}=  Create Dictionary  HostName=openbmc
    Redfish1.Patch  ${REDFISH_NW_ETH_IFACE}eth1  body=&{data}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    Validate Hostname On BMC  openbmc

    ${resp1}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}eth0
    ${resp2}=  Redfish1.Get  ${REDFISH_NW_ETH_IFACE}eth1
    Should Be Equal  ${resp1.dict['HostName']}  ${resp2.dict['HostName']}


Verify LDAP Login Works When Eth1 IP Is Not Configured
    [Documentation]  Verify LDAP login works when eth1 IP is erased.
    [Tags]  Verify_LDAP_Login_Works_When_Eth1_IP_Is_Not_Configured
    [Setup]  Run Keywords  Set Test Variable  ${CHANNEL_NUMBER}  ${SECONDARY_CHANNEL_NUMBER}
    ...  AND  Redfish.Login  AND  Delete IP Address  ${OPENBMC_HOST_ETH1}
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login  AND
    ...  Add IP Address  ${OPENBMC_HOST_ETH1}  ${eth1_subnet_mask}  ${eth1_gateway}

    Create LDAP Configuration
    Redfish.Logout
    Sleep   30
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}


Verify LDAP Login Works When Both Interfaces Are Configured
    [Documentation]  Verify LDAP login works when both interfaces are configured.
    [Tags]  Verify_LDAP_Login_Works_When_Both_Interfaces_Are_Configured

    Create LDAP Configuration
    Redfish.Logout
    Sleep   30
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}


Verify Secure LDAP Login Works When Both Interfaces Are Configured
    [Documentation]  Verify Secure LDAP login works when both the interfaces are configured.
    [Tags]  Verify_Secure_LDAP_Login_Works_When_Both_Interfaces_Are_Configured

    Create LDAP Configuration  ${LDAP_TYPE}  ${LDAP_SERVER_URI_1}  ${LDAP_BIND_DN}
    ...  ${LDAP_BIND_DN_PASSWORD}  ${LDAP_BASE_DN}
    Redfish.Logout
    Sleep   30
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}


Verify SNMP Works When Eth1 IP Is Not Configured
    [Documentation]  Verify SNMP works when eth1 IP is not configured.
    [Tags]  Verify_SNMP_Works_When_Eth1_IP_Is_Not_Configured
    [Setup]  Run Keywords  Redfish.Login  AND
    ...  Set Test Variable  ${CHANNEL_NUMBER}  ${SECONDARY_CHANNEL_NUMBER}
    ...  AND  Delete IP Address  ${OPENBMC_HOST_ETH1}
    [Teardown]  Add IP Address  ${OPENBMC_HOST_ETH1}  ${eth1_subnet_mask}  ${eth1_gateway}

    Create Error On BMC And Verify Trap


Disable And Enable Eth0 Interface
    [Documentation]  Disable and Enable eth0 ethernet interface via redfish.
    [Tags]  Disable_And_Enable_Eth0_Interface
    [Template]  Set BMC Ethernet Interfaces State

    # interface_ip   interface  enabled
    ${OPENBMC_HOST}   eth0      ${False}
    ${OPENBMC_HOST}   eth0      ${True}


Verify Both Interfaces Access Concurrently Via Redfish
    [Documentation]  Verify both interfaces access conurrently via redfish.
    [Tags]  Verify_Both_Interfaces_Access_Concurrently_Via_Redfish

    ${dict}=  Execute Process Multi Keyword  ${2}
    ...  Redfish.Patch ${REDFISH_NW_ETH_IFACE}eth0 body={'DHCPv4':{'UseDNSServers':${True}}}
    ...  Redfish1.Patch ${REDFISH_NW_ETH_IFACE}eth1 body={'DHCPv4':{'UseDNSServers':${True}}}

    Dictionary Should Not Contain Value  ${dict}  False
    ...  msg=One or more operations has failed.

    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}eth0
    ${resp1}=  Redfish1.Get  ${REDFISH_NW_ETH_IFACE}eth1

    Should Be Equal  ${resp.dict["DHCPv4"]['UseDNSServers']}  ${True}
    Should Be Equal  ${resp1.dict["DHCPv4"]['UseDNSServers']}  ${True}

Able To Access Serial Console Via Both Network Interfaces
    [Documentation]  Able to access serial console via both network interfaces.
    [Tags]  Able_To_Access_Serial_Console_Via_Both_Network_Interfaces

    Open Connection And Log In  host=${OPENBMC_HOST}  port=2200
    Open Connection And Log In  host=${OPENBMC_HOST_ETH1}  port=2200
    Close All Connections

Verify IPMI Works On Both Network Interfaces
    [Documentation]  Verify IPMI works on both network interfaces.
    [Tags]  Verify_IPMI_Works_On_Both_Network_Interfaces

    Run IPMI  ${OPENBMC_HOST_ETH1}  power on
    ${status1}=  Run IPMI  ${OPENBMC_HOST}  power status
    ${status2}=  Run IPMI  ${OPENBMC_HOST_ETH1}  power status
    Should Be Equal  ${status1}  ${status2}

Verify Modifying IP Address Multiple Times On Interface
    [Documentation]  Verify modifying IP address multiple times on interface.
    [Tags]  Verify_Modifying_IP_Address_Multiple_Times_On_Interface
    [Teardown]  Run Keywords
    ...  Delete IP Address  ${test_ipv4_addr}  AND  Redfish.Logout

    ${test_gateway}=  Get BMC Default Gateway
    Add IP Address  ${test_ipv4_addr}  ${test_subnet_mask}  ${test_gateway}
    Update IP Address  ${test_ipv4_addr}  ${test_ipv4_addr2}  ${test_subnet_mask}  ${test_gateway}
    Update IP Address  ${test_ipv4_addr2}  ${test_ipv4_addr}  ${test_subnet_mask}  ${test_gateway}
    Run Keyword  Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}
    Run Keyword  Wait For Host To Ping  ${OPENBMC_HOST_ETH1}  ${NETWORK_TIMEOUT}

Verify Able To Load Certificates Via Eth1 IP Address
    [Documentation]  Verify able to load certificates via eth1 IP address.
    [Tags]  Verify_Able_To_Load_Certificates_Via_Eth1_IP_Address
    [Template]  Install Certificate Via Redfish And Verify

    # cert_type  cert_format                         expected_status
    CA           Valid Certificate                   ok
    Client       Valid Certificate Valid Privatekey  ok

Enable SSH Protocol Via Eth1 And Verify On Both Interfaces
    [Documentation]  Enable SSH protocol via eth1 and verify on both interfaces.
    [Tags]  Enable_SSH_Protocol_Via_Eth1_And_Verify_On_Both_Interfaces

    Set SSH Value Via Eth1  ${True}
    # Check if SSH is really enabled via Redfish via eth1.
    Verify SSH Protocol State Via Eth1  ${True}
    # Check if SSH login and commands on SSH session work on both interfaces.
    Verify SSH Login And Commands Work
    Verify SSH Login And Commands Work  ${OPENBMC_HOST_ETH1}

Disable SSH Protocol Via Eth1 And Verify On Both Interfaces
    [Documentation]  Disable SSH protocol via eth1 and verify on both interfaces.
    [Tags]  Disable_SSH_Protocol_Via_Eth1_And_Verify_On_Both_Interfaces
    [Teardown]  Set SSH Value Via Eth1  ${True}

    Set SSH Value Via Eth1  ${False}
    # Check if SSH is really disabled via Redfish via eth1.
    Verify SSH Protocol State Via Eth1  ${False}
    # Check if SSH login and commands fail on eth1.
    ${status}=  Run Keyword And Return Status
    ...  Verify SSH Login And Commands Work  ${OPENBMC_HOST_ETH1}

    Should Be Equal As Strings  ${status}  False
    ...  msg=SSH Login and commands are working after disabling SSH via eth1.

    # Check if SSH login and commands fail.
    ${status}=  Run Keyword And Return Status
    ...  Verify SSH Login And Commands Work

    Should Be Equal As Strings  ${status}  False
    ...  msg=SSH Login and commands are working after disabling SSH.

Verify Eth0 Static To DHCP Switch Assigns Link Local When DHCP Server Is Down
    [Documentation]  Switch eth0 from static to DHCP mode while no DHCP server is reachable on
    ...              the eth0 network and verify that eth0 gets an IPv4 link-local address.
    ...              Precondition: DHCP server must not be reachable from eth0.
    [Tags]  Verify_Eth0_Static_To_DHCP_Switch_Assigns_Link_Local_When_DHCP_Server_Is_Down
    [Setup]  Setup Eth0 And Eth1 Static And Reachable
    [Teardown]  Restore Eth0 Static Via Eth1

    # Switch eth0 to DHCP via eth1 since eth0 static IP is going to be removed.
    Redfish1.Patch  ${REDFISH_NW_ETH_IFACE}eth0  body=${ENABLE_DHCP}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_ACCEPTED}, ${HTTP_NO_CONTENT}]

    # Verify eth0 is in DHCP mode and has link-local address (no DHCP lease as server is down).
    Wait Until Keyword Succeeds  1 min  5 sec  Verify Eth0 DHCP Enabled Via Eth1
    Wait Until Keyword Succeeds  ${link_local_timeout}  ${link_local_interval}
    ...  Verify Eth0 Link Local And No DHCP Lease Via Eth1

    # Verify BMC is still reachable and working through eth1.
    Wait For Host To Ping  ${OPENBMC_HOST_ETH1}  ${NETWORK_TIMEOUT}
    ${resp}=  Redfish1.Get  ${REDFISH_NW_ETH_IFACE}eth1
    Should Be Equal  ${resp.dict['DHCPv4']['DHCPEnabled']}  ${False}
    ...  msg=eth1 DHCP state changed after switching eth0 to DHCP.


*** Keywords ***

Get Network Configuration Using Channel Number
    [Documentation]  Get ethernet interface.
    [Arguments]  ${channel_number}

    # Description of argument(s):
    # channel_number   Ethernet channel number, 1 is for eth0 and 2 is for eth1 (e.g. "1").

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}

    @{network_configurations}=  Get From Dictionary  ${resp.dict}  IPv4StaticAddresses
    RETURN  @{network_configurations}


Suite Setup Execution
    [Documentation]  Do suite setup task.

    Valid Value  OPENBMC_HOST_ETH1

    # Check both interfaces are configured and reachable.
    Ping Host  ${OPENBMC_HOST}
    Ping Host  ${OPENBMC_HOST_ETH1}

    ${network_configurations}=  Get Network Configuration Using Channel Number  ${SECONDARY_CHANNEL_NUMBER}
    FOR  ${network_configuration}  IN  @{network_configurations}

      IF  '${network_configuration['Address']}' == '${OPENBMC_HOST_ETH1}'
          Set Suite Variable  ${eth1_subnet_mask}  ${network_configuration['SubnetMask']}
          Set Suite Variable  ${eth1_gateway}  ${network_configuration['Gateway']}
          BREAK
      END

    END


Set BMC Ethernet Interfaces State
    [Documentation]  Set BMC ethernet interface state.
    [Arguments]  ${interface_ip}  ${interface}  ${enabled}
    [Teardown]  Redfish1.Logout

    # Description of argument(s):
    # interface_ip    IP address of ethernet interface.
    # interface       The ethernet interface name (eg. eth0 or eth1).
    # enabled         Indicates interface should be enabled (eg. True or False).

    Redfish1.Login

    ${data}=  Create Dictionary  InterfaceEnabled=${enabled}

    Redfish1.Patch  ${REDFISH_NW_ETH_IFACE}${interface}  body=&{data}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    Sleep  ${NETWORK_TIMEOUT}s
    ${interface_status}=   Redfish1.Get Attribute  ${REDFISH_NW_ETH_IFACE}${interface}  InterfaceEnabled
    Should Be Equal  ${interface_status}  ${enabled}

    ${status}=  Run Keyword And Return Status  Ping Host  ${interface_ip}

    IF  ${enabled} == ${True}
        Should Be Equal  ${status}  ${True}
    ELSE
        Should Be Equal  ${status}  ${False}
    END


Run IPMI
    [Documentation]  Run IPMI command.
    [Arguments]  ${host}  ${sub_cmd}

    # Description of argument(s):
    # host         BMC host name or IP address.
    # sub_cmd      The IPMI command string to be executed.

    ${rc}  ${output}=  Run And Return Rc And Output  ${cmd_prefix} -H ${host} ${sub_cmd}
    Should Be Equal As Strings  ${rc}  0
    RETURN  ${output}


Install Certificate Via Redfish And Verify
    [Documentation]  Install and verify certificate using Redfish.
    [Arguments]  ${cert_type}  ${cert_format}  ${expected_status}  ${delete_cert}=${True}
    [Teardown]  Remove Directory  certificate_dir  recursive=True

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Client" or "CA").
    # cert_format         Certificate file format
    #                     (e.g. "Valid_Certificate_Valid_Privatekey").
    # expected_status     Expected status of certificate replace Redfish
    #                     request (i.e. "ok" or "error").
    # delete_cert         Certificate will be deleted before installing if this True.

    Create Directory  certificate_dir
    # AUTH_URI is a global variable defined in lib/resource.robot
    Set Test Variable  ${AUTH_URI}  https://${OPENBMC_HOST_ETH1}
    IF  '${cert_type}' == 'CA' and '${delete_cert}' == '${True}'
        Delete All CA Certificate Via Redfish
    ELSE IF  '${cert_type}' == 'Client' and '${delete_cert}' == '${True}'
        Delete Certificate Via BMC CLI  ${cert_type}
    END

    ${cert_file_path}=  Generate Certificate File Via Openssl  ${cert_format}
    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

    ${certificate_uri}=  Set Variable If
    ...  '${cert_type}' == 'Client'  ${REDFISH_LDAP_CERTIFICATE_URI}
    ...  '${cert_type}' == 'CA'  ${REDFISH_CA_CERTIFICATE_URI}

    ${cert_id}=  Install Certificate File On BMC  ${certificate_uri}  ${expected_status}  data=${file_data}
    Logging  Installed certificate id: ${cert_id}

    Sleep  30s

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}

    ${content}=   redfish_utils.Get Attribute
    ...  ${certificate_uri}/${cert_id}  CertificateString

    ${bmc_cert_content}=  Set Variable If  '${expected_status}' == 'ok'
    ...  ${content}

    IF  '${expected_status}' == 'ok'
        Should Contain  ${cert_file_content}  ${bmc_cert_content}
    END
    RETURN  ${cert_id}

Set SSH Value Via Eth1
    [Documentation]  Enable or disable SSH protocol via Eth1.
    [Arguments]  ${enable_value}=${True}

    # Description of argument(s}:
    # enable_value  Enable or disable SSH, e.g. (true, false).

    ${ssh_state}=  Create Dictionary  ProtocolEnabled=${enable_value}
    ${data}=  Create Dictionary  SSH=${ssh_state}

    Redfish1.Login
    Redfish1.Patch  ${REDFISH_NW_PROTOCOL_URI}  body=&{data}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]

    # Wait for timeout for new values to take effect.
    Sleep  ${NETWORK_TIMEOUT}s

Verify SSH Protocol State Via Eth1
    [Documentation]  Verify SSH protocol state via eth1.
    [Arguments]  ${state}=${True}

    # Description of argument(s}:
    # state  Enable or disable SSH, e.g. (true, false)

    ${resp}=  Redfish1.Get  ${REDFISH_NW_PROTOCOL_URI}
    Should Be Equal As Strings  ${resp.dict['SSH']['ProtocolEnabled']}  ${state}
    ...  msg=Protocol states are not matching.


Setup Eth0 And Eth1 Static And Reachable
    [Documentation]  Skip the test unless eth0 and eth1 are static and pingable.

    # Ping both interfaces before any login so an unreachable one skips the test.
    FOR  ${name}  ${host}  IN  eth0  ${OPENBMC_HOST}  eth1  ${OPENBMC_HOST_ETH1}
        TRY
            Ping Host  ${host}
        EXCEPT  AS  ${error}
            Skip  ${name} (${host}) is not pingable, skipping test. ${error}
        END
    END

    Redfish1.Login

    FOR  ${interface}  IN  eth0  eth1
        ${dhcp}=  Redfish1.Get Attribute  ${REDFISH_NW_ETH_IFACE}${interface}  DHCPv4
        IF  ${dhcp['DHCPEnabled']}
            Skip  ${interface} is in DHCP mode instead of static, skipping test.
        END
    END

    # Save the eth0 static IPv4 entries so teardown can restore them.
    ${eth0_static}=  Redfish1.Get Attribute  ${REDFISH_NW_ETH_IFACE}eth0  IPv4StaticAddresses
    VAR  @{static_addresses}
    FOR  ${entry}  IN  @{eth0_static}
        VAR  &{ip_data}
        ...  Address=${entry['Address']}
        ...  SubnetMask=${entry['SubnetMask']}
        ...  Gateway=${entry['Gateway']}
        Append To List  ${static_addresses}  ${ip_data}
    END
    IF  not ${static_addresses}
        Skip  No static IPv4 address found on eth0, skipping test.
    END

    # Set only after all checks pass so teardown restores nothing for a skipped test.
    VAR  @{eth0_static_original}  @{static_addresses}  scope=TEST


Verify Eth0 DHCP Enabled Via Eth1
    [Documentation]  Verify DHCPv4 is enabled on eth0 via eth1.

    ${dhcp_enabled}=  Redfish1.Get Attribute  ${REDFISH_NW_ETH_IFACE}eth0  DHCPv4
    Should Be Equal  ${dhcp_enabled['DHCPEnabled']}  ${True}
    ...  msg=DHCP is not enabled on eth0.


Verify Eth0 Link Local And No DHCP Lease Via Eth1
    [Documentation]  Verify eth0 has IPv4 link-local and no DHCP address via eth1.

    ${resp}=  Redfish1.Get  ${REDFISH_NW_ETH_IFACE}eth0
    VAR  @{origins}
    FOR  ${ip_entry}  IN  @{resp.dict['IPv4Addresses']}
        Append To List  ${origins}  ${ip_entry['AddressOrigin']}
    END

    Should Contain  ${origins}  IPv4LinkLocal
    ...  msg=No IPv4LinkLocal address found on eth0 after enabling DHCP with DHCP server down.
    List Should Not Contain Value  ${origins}  DHCP
    ...  msg=eth0 got a DHCP address, DHCP server is expected to be down.


Restore Eth0 Static Via Eth1
    [Documentation]  Restore eth0 static IPv4 addresses via eth1 and log out.

    # Setup skipped or failed before saving the eth0 state, so there is nothing to restore.
    TRY
        Variable Should Exist  ${eth0_static_original}
    EXCEPT
        FFDC On Test Case Fail
        Run Keyword And Ignore Error  Redfish1.Logout
        RETURN
    END

    TRY
        # Turn DHCP off through eth1 since eth0 may be unreachable.
        Redfish1.Patch  ${REDFISH_NW_ETH_IFACE}eth0  body=${DISABLE_DHCP}
        ...  valid_status_codes=[${HTTP_OK}, ${HTTP_ACCEPTED}, ${HTTP_NO_CONTENT}]
        Sleep  ${NETWORK_TIMEOUT}s

        # An empty entry keeps the existing address unchanged, so pad the array with empty
        # entries for the current addresses and append only the saved ones that are missing.
        ${current}=  Redfish1.Get Attribute  ${REDFISH_NW_ETH_IFACE}eth0  IPv4StaticAddresses
        VAR  &{empty_entry}
        VAR  @{entries}
        VAR  @{current_addresses}
        FOR  ${entry}  IN  @{current}
            Append To List  ${entries}  ${empty_entry}
            Append To List  ${current_addresses}  ${entry['Address']}
        END
        FOR  ${original}  IN  @{eth0_static_original}
            IF  $original['Address'] not in $current_addresses
                Append To List  ${entries}  ${original}
            END
        END
        VAR  &{data}  IPv4StaticAddresses=${entries}
        Redfish1.Patch  ${REDFISH_NW_ETH_IFACE}eth0  body=&{data}
        ...  valid_status_codes=[${HTTP_OK}, ${HTTP_ACCEPTED}, ${HTTP_NO_CONTENT}]
        Sleep  ${NETWORK_TIMEOUT}s

        # Verify both interfaces answer again.
        Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}
        Wait For Host To Ping  ${OPENBMC_HOST_ETH1}  ${NETWORK_TIMEOUT}
    FINALLY
        # Collect FFDC after the restore attempt, while eth0 is reachable again.
        FFDC On Test Case Fail
        Run Keyword And Ignore Error  Redfish1.Logout
    END
