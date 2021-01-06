*** Settings ***
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

Set Network Property via Redfish And Verify
   [Documentation]  Set network property via Redfish and verify.
   [Tags]  Set_Network_Property_via_Redfish_And_Verify
   [Template]  Apply Ethernet Config

    # property
    ${dhcp_enable_dict}
    ${dhcp_disable_dict}
    ${dns_enable_dict}
    ${dns_disable_dict}
    ${domain_name_enable_dict}
    ${domain_name_disable_dict}
    ${ntp_enable_dict}
    ${ntp_disable_dict}
    ${enable_multiple_properties}
    ${disable_multiple_properties}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Suite Setup Execution.

    Redfish.Login

    Redfish Power On
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
    [Teardown]  Run Keywords  Restore Configuration  AND
    ...  Set Global Variable  ${TEST_STATUS}  ${KEYWORD STATUS}  AND  FFDC On Test Case Fail

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

