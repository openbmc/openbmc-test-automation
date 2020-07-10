** Settings ***
Documentation          DHCP Network to test suite functionality.

Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/bmc_network_utils.robot
Library                ../lib/ipmi_utils.py
Library                ../lib/bmc_network_utils.py

Suite Setup            Suite Setup Execution
Suite Teardown         Redfish.Logout

*** Variables ***

&{dhcp_enable_dict}                DHCPEnabled=${True}
&{dhcp_disable_dict}               DHCPEnabled=${False}

&{dns_enable_dict}                 UseDNSServers=${True}
&{dns_disable_dict}                UseDNSServers=${False}

&{ntp_enable_dict}                 UseNTPServers=${True}
&{ntp_disable_dict}                UseNTPServers=${False}

&{domain_name_enable_dict}         UseDomainName=${True}
&{domain_name_disable_dict}        UseDomainName=${False}

&{enable_multiple_properties}      UseDomainName=${True}
...                                UseNTPServers=${True}
...                                UseDNSServers=${True}

&{disable_multiple_properties}     UseDomainName=${False}
...                                UseNTPServers=${False}
...                                UseDNSServers=${False}

*** Test Cases ***

Enable DHCP Via Redfish And Verify
    [Documentation]  Enable DHCP via Redfish and verify.
    [Tags]  Enable_DHCP_Via_Redfish_And_Verify
    [Teardown]  Run Keywords  Restore Configuration
    ...  AND  FFDC On Test Case Fail
    [Template]  Apply Ethernet Config

    # property
    ${dhcp_enable_dict}


Disable DHCP Via Redfish And Verify
    [Documentation]  Disable DHCP via Redfish and verify.
    [Tags]  Disable_DHCP_Via_Redfish_And_Verify
    [Teardown]  Run Keywords  Restore Configuration
    ...  AND  FFDC On Test Case Fail
    [Template]  Apply Ethernet Config

    # property
    ${dhcp_disable_dict}


Enable UseDNSServers Via Redfish And Verify
    [Documentation]  Enable UseDNSServers via Redfish and verify.
    [Tags]  Enable_UseDNSServers_Via_Redfish_And_Verify
    [Teardown]  Run Keywords  Restore Configuration
    ...  AND  FFDC On Test Case Fail
    [Template]  Apply Ethernet Config

    # property
    ${dns_enable_dict}


Disable UseDNSServers Via Redfish And Verify
    [Documentation]  Disable UseDNSServers via Redfish and verify.
    [Tags]  Disable_UseDNSServers_Via_Redfish_And_Verify
    [Teardown]  Run Keywords  Restore Configuration
    ...  AND  FFDC On Test Case Fail
    [Template]  Apply Ethernet Config

    # property
    ${dns_disable_dict}

Enable UseDomainName Via Redfish And Verify
    [Documentation]  Enable UseDomainName via Redfish and verify.
    [Tags]  Enable_UseDomainName_Via_Redfish_And_Verify
    [Teardown]  Run Keywords  Restore Configuration
    ...  AND  FFDC On Test Case Fail
    [Template]  Apply Ethernet Config

    # property
    ${domain_name_enable_dict}


Disable UseDomainName Via Redfish And Verify
    [Documentation]  Disable UseDomainName via Redfish and verify.
    [Tags]  Disable_UseDomainName_Via_Redfish_And_Verify
    [Teardown]  Run Keywords  Restore Configuration
    ...  AND  FFDC On Test Case Fail
    [Template]  Apply Ethernet Config

    # property
    ${domain_name_disable_dict}


Enable UseNTPServers Via Redfish And Verify
    [Documentation]  Enable UseNTPServers via Redfish and verify.
    [Tags]  Enable_UseNTPServers_Via_Redfish_And_Verify
    [Teardown]  Run Keywords  Restore Configuration
    ...  AND  FFDC On Test Case Fail
    [Template]  Apply Ethernet Config

    # property
    ${ntp_enable_dict}


Disable UseNTPServers Via Redfish And Verify
    [Documentation]  Disable UseNTPServers via Redfish and verify.
    [Tags]  Disable_UseNTPServers_Via_Redfish_And_Verify
    [Teardown]  Run Keywords  Restore Configuration
    ...  AND  FFDC On Test Case Fail
    [Template]  Apply Ethernet Config

    # property
    ${ntp_disable_dict}


Enable Multiple Properties via Redfish And Verify
   [Documentation]  Enable multiple properties via Redfish and verify.
   [Tags]  Enable_Multiple_Properties_Via_Redfish_And_Verify
   [Teardown]  Run Keywords  Restore Configuration
   ...  AND  FFDC On Test Case Fail
   [Template]  Apply Ethernet Config

    # property
    ${enable_multiple_properties}


Disable Multiple Properties via Redfish And Verify
   [Documentation]  Disable multiple properties via Redfish and verify.
   [Tags]  Disable_Multiple_Properties_Via_Redfish_And_Verify
   [Teardown]  Run Keywords  Restore Configuration
   ...  AND  FFDC On Test Case Fail
   [Template]  Apply Ethernet Config

    # property
    ${disable_multiple_properties}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Suite Setup Execution.

    Redfish.Login

    # This keyword should login to host OS.
    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} ipsrc static  login_host=${1}

    ${host_name}  ${ip_address}=  Get Host Name IP  host=${OPENBMC_HOST}

    Set Suite Variable  ${ip_address}

    @{network_configurations}=  Get Network Configuration
    FOR  ${network_configuration}  IN  @{network_configurations}
      Run Keyword If  '${network_configuration['Address']}' == '${ip_address}'
      ...  Set Suite Variable  ${subnet_mask}  ${network_configuration['SubnetMask']}
    END

    ${initial_lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Set Suite Variable  ${initial_lan_config}

Set IPMI Inband Network Configuration
    [Documentation]  Run sequence of standard in-band IPMI command and set
    ...              the IP configuration.
    [Arguments]  ${ip}  ${netmask}  ${gateway}

    # Description of argument(s):
    # ip       The IP address to be set using ipmitool-inband.
    # netmask  The Netmask to be set using ipmitool-inband.
    # gateway  The Gateway address to be set using ipmitool-inband.
    # login    Indicates that this keyword should login to host OS.

    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} ipaddr ${ip}  login_host=${0}
    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} netmask ${netmask}  login_host=${0}
    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} defgw ipaddr ${gateway}  login_host=${0}


Restore Configuration
    [Documentation]  Restore the configuration to its pre-test state.

    ${length}=  Get Length  ${initial_lan_config}
    Return From Keyword If  ${length} == ${0}

    Set IPMI Inband Network Configuration  ${ip_address}  ${subnet_mask}
    ...  ${initial_lan_config['Default Gateway IP']}


Apply Ethernet Config
   [Documentation]  Set the given Ethernet config property.
   [Arguments]  ${property}

   # Description of argument(s):
   # property   Ethernet property to be set..

   ${active_channel_config}=  Get Active Channel Config
   Redfish.Patch
   ...  /redfish/v1/Managers/bmc/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}/
   ...  body={"DHCPv4":${property}}  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

   ${resp}=  Redfish.Get
   ...  /redfish/v1/Managers/bmc/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}
   Verify Ethernet Config Property  ${property}  ${resp.dict["DHCPv4"]}

Verify Ethernet Config Property
    [Documentation]  verify ethernet config properties.
    [Arguments]  ${property}  ${response_data}

    # Description of argument(s):
    # ${property}       DHCP Properties in dictionary.
    # Example:
    # property         value
    # DHCPEnabled      :False
    # UseDomainName    :True
    # UseNTPServers    :True
    # UseDNSServers    :True
    # ${response_data}  DHCP Response data in dictionary.
    # Example:
    # property         value
    # DHCPEnabled      :False
    # UseDomainName    :True
    # UseNTPServers    :True
    # UseDNSServers    :True

   ${key_map}=  Get Dictionary Items  ${property}
   FOR  ${key}  ${value}  IN  @{key_map}
      Should Be Equal As Strings  ${response_data['${key}']}  ${value}
   END

