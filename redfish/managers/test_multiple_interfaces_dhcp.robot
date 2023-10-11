*** Settings ***
Documentation   Test BMC DHCP multiple network interface functionalities.

Resource        ../../lib/resource.robot
Resource        ../../lib/common_utils.robot
Resource        ../../lib/connection_client.robot
Resource        ../../lib/bmc_network_utils.robot
Resource        ../../lib/openbmc_ffdc.robot

Suite Setup     Suite Setup Execution
Test Teardown   FFDC On Test Case Fail
Suite Teardown  Redfish.Logout

*** Variables ***

&{DHCP_ENABLED}           DHCPEnabled=${True}
&{DHCP_DISABLED}          DHCPEnabled=${False}
&{ENABLE_DHCP}            DHCPv4=${DHCP_ENABLED}
&{DISABLE_DHCP}           DHCPv4=${DHCP_DISABLED}
${ethernet_interface}     eth1

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

Force Tags                         Multiple_Interfaces_DHCP

*** Test Cases ***

Disable DHCP On Eth1 And Verify System Is Accessible By Eth0
    [Documentation]  Disable DHCP on eth1 using Redfish and verify
    ...              if system is accessible by eth0.
    [Tags]  Disable_DHCP_On_Eth1_And_Verify_System_Is_Accessible_By_Eth0
    [Teardown]  Set DHCPEnabled To Enable Or Disable  True  eth1

    Set DHCPEnabled To Enable Or Disable  False  eth1
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

Enable DHCP On Eth1 And Verify System Is Accessible By Eth0
    [Documentation]  Enable DHCP on eth1 using Redfish and verify if system
    ...              is accessible by eth0.
    [Tags]  Enable_DHCP_On_Eth1_And_Verify_System_Is_Accessible_By_Eth0
    [Setup]  Set DHCPEnabled To Enable Or Disable  False  eth1

    Set DHCPEnabled To Enable Or Disable  True  eth1
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

Set Network Property via Redfish And Verify
   [Documentation]  Set network property via Redfish and verify.
   [Tags]  Set_Network_Property_via_Redfish_And_Verify
   [Teardown]  Restore Configuration
   [Template]  Apply DHCP Config

    # property
    ${dns_enable_dict}
    ${dns_disable_dict}
    ${domain_name_enable_dict}
    ${domain_name_disable_dict}
    ${ntp_enable_dict}
    ${ntp_disable_dict}
    ${enable_multiple_properties}
    ${disable_multiple_properties}

Enable DHCP On Eth1 And Check No Impact On Eth0
    [Documentation]  Enable DHCP On Eth1 And Check No Impact On Eth0.
    [Tags]  Enable_DHCP_On_Eth1_And_Check_No_Impact_On_Eth0
    [Setup]  Set DHCPEnabled To Enable Or Disable  False  eth1

    # Getting the eth0 details before enabling DHCP.
    ${ip_data_before}=  Get BMC IP Info

    # Enable DHCP.
    Set DHCPEnabled To Enable Or Disable  True  eth1

    # Check the value of DHCPEnabled on eth0 is not impacted.
    ${DHCPEnabled}=  Get IPv4 DHCP Enabled Status
    Should Be Equal  ${DHCPEnabled}  ${False}

    # Getting eth0 details after enabling DHCP.
    ${ip_data_after}=  Get BMC IP Info

    # Before and after IP details must match.
    Should Be Equal  ${ip_data_before}  ${ip_data_after}

*** Keywords ***

Get IPv4 DHCP Enabled Status
    [Documentation]  Return IPv4 DHCP enabled status from redfish URI.

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}
    ${resp}=  Redfish.Get Attribute  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  DHCPv4
    Return From Keyword  ${resp['DHCPEnabled']}

Set DHCPEnabled To Enable Or Disable
    [Documentation]  Enable or Disable DHCP on the interface.
    [Arguments]  ${dhcp_enabled}=${False}  ${interface}=${ethernet_interface}
    ...          ${valid_status_code}=[${HTTP_OK},${HTTP_ACCEPTED}]

    # Description of argument(s):
    # dhcp_enabled        False for disabling DHCP and True for Enabling DHCP.
    # interface           eth0 or eth1. Default is eth1.
    # valid_status_code   Expected valid status code from Patch request.
    #                     Default is HTTP_OK.

    ${data}=  Set Variable If  ${dhcp_enabled} == ${False}  ${DISABLE_DHCP}  ${ENABLE_DHCP}
    ${resp}=  Redfish.Patch
    ...  /redfish/v1/Managers/${MANAGER_ID}/EthernetInterfaces/${interface}
    ...  body=${data}  valid_status_codes=${valid_status_code}

Apply DHCP Config
    [Documentation]  Apply DHCP Config
    [Arguments]  ${property}

    # Description of Argument(s):
    # property  DHCP property values.

    ${active_channel_config}=  Get Active Channel Config
    Redfish.Patch
    ...  /redfish/v1/Managers/${MANAGER_ID}/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}/
    ...  body={"DHCPv4":${property}}  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    ${resp}=  Redfish.Get
    ...  /redfish/v1/Managers/${MANAGER_ID}/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}
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

Restore Configuration
    [Documentation]  Restore the configuration to Both Static Network

    Run Keyword If  '${CHANNEL_NUMBER}' == '1'  Add IP Address  ${OPENBMC_HOST}  ${eth0_subnet_mask}  ${eth0_gateway}
    ...  ELSE IF  '${CHANNEL_NUMBER}' == '2'  Add IP Address  ${OPENBMC_HOST_1}  ${eth1_subnet_mask}  ${eth1_gateway}

Get Network Configuration Using Channel Number
    [Documentation]  Get ethernet interface.
    [Arguments]  ${channel_number}

    # Description of argument(s):
    # channel_number   Ethernet channel number, 1 is for eth0 and 2 is for eth1 (e.g. "1").

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}

    @{network_configurations}=  Get From Dictionary  ${resp.dict}  IPv4StaticAddresses
    [Return]  @{network_configurations}

Suite Setup Execution
    [Documentation]  Do suite setup task.

    Ping Host  ${OPENBMC_HOST}
    Ping Host  ${OPENBMC_HOST_1}
    Redfish.Login

    # Get the configuration of eth1
    ${network_configurations}=  Get Network Configuration Using Channel Number  ${2}
    FOR  ${network_configuration}  IN  @{network_configurations}
      Run Keyword If  '${network_configuration['Address']}' == '${OPENBMC_HOST_1}'
      ...  Run Keywords  Set Suite Variable  ${eth1_subnet_mask}  ${network_configuration['SubnetMask']}
      ...  AND  Set Suite Variable  ${eth1_gateway}  ${network_configuration['Gateway']}
      ...  AND  Exit For Loop
    END

    # Get the configuration of eth0
    ${network_configurations}=  Get Network Configuration Using Channel Number  ${1}
    FOR  ${network_configuration}  IN  @{network_configurations}
      Run Keyword If  '${network_configuration['Address']}' == '${OPENBMC_HOST}'
      ...  Run Keywords  Set Suite Variable  ${eth0_subnet_mask}  ${network_configuration['SubnetMask']}
      ...  AND  Set Suite Variable  ${eth0_gateway}  ${network_configuration['Gateway']}
      ...  AND  Exit For Loop
    END

