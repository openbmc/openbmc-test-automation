*** Settings ***
Documentation   Test BMC DHCP multiple network interface functionalities.
                ...  Run on setup eth0 in static and eth1 in DHCP.

Resource        ../../lib/resource.robot
Resource        ../../lib/common_utils.robot
Resource        ../../lib/connection_client.robot
Resource        ../../lib/bmc_network_utils.robot
Resource        ../../lib/openbmc_ffdc.robot

Suite Setup     Suite Setup Execution
Test Teardown   FFDC On Test Case Fail
Suite Teardown  Redfish.Logout

Test Tags       Multiple_Interfaces_DHCP

*** Variables ***

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

*** Test Cases ***

Disable DHCP On Eth1 And Verify System Is Accessible By Eth0
    [Documentation]  Disable DHCP on eth1 using Redfish and verify
    ...              if system is accessible by eth0.
    [Tags]  Disable_DHCP_On_Eth1_And_Verify_System_Is_Accessible_By_Eth0
    [Teardown]  Set DHCPEnabled To Enable Or Disable  True  eth1

    Set DHCPEnabled To Enable Or Disable  False  eth1
    ${DHCPEnabled}=  Get IPv4 DHCP Enabled Status  ${2}
    Should Be Equal  ${DHCPEnabled}  ${False}
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

Enable DHCP On Eth1 And Verify System Is Accessible By Eth0
    [Documentation]  Enable DHCP on eth1 using Redfish and verify if system
    ...              is accessible by eth0.
    [Tags]  Enable_DHCP_On_Eth1_And_Verify_System_Is_Accessible_By_Eth0
    [Setup]  Set DHCPEnabled To Enable Or Disable  False  eth1

    Set DHCPEnabled To Enable Or Disable  True  eth1
    ${DHCPEnabled}=  Get IPv4 DHCP Enabled Status  ${2}
    Should Be Equal  ${DHCPEnabled}  ${True}
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

Set Network Property via Redfish And Verify
   [Documentation]  Set network property via Redfish and verify.
   [Tags]  Set_Network_Property_via_Redfish_And_Verify
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

Set Network Property For DHCPv6 via Redfish And Verify
   [Documentation]  Set network property for DHCPv6 via Redfish and verify.
   [Tags]  Set_Network_Property_For_DHCPv6_via_Redfish_And_Verify
   [Template]  Apply DHCPv6 Config And Verify

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

    # Enable DHCP on eth1.
    Set DHCPEnabled To Enable Or Disable  True  eth1

    # Check the value of DHCPEnabled on eth0 is not impacted.
    ${DHCPEnabled}=  Get IPv4 DHCP Enabled Status  ${1}
    Should Be Equal  ${DHCPEnabled}  ${False}

    # Getting eth0 details after enabling DHCP.
    ${ip_data_after}=  Get BMC IP Info

    # Before and after IP details must match.
    Should Be Equal  ${ip_data_before}  ${ip_data_after}

Enable DHCP On Eth1 And Check Persistency On Reboot
    [Documentation]  Enable DHCP on Eth1 and check persistency
    ...  on reboot and should not switch to static.
    [Tags]  Enable_DHCP_On_Eth1_And_Check_Persistency_On_Reboot
    [Setup]  Set DHCPEnabled To Enable Or Disable  False  eth1

    Set DHCPEnabled To Enable Or Disable  True  eth1
    Redfish OBMC Reboot (off)  stack_mode=skip
    ${DHCPEnabled}=  Get IPv4 DHCP Enabled Status  ${2}
    Should Be Equal  ${DHCPEnabled}  ${True}

Switch Between DHCP And Static
    [Documentation]  Switch between DHCP and static.
    [Tags]  Switch_Between_DHCP_And_Static
    [Teardown]  Set DHCPEnabled To Enable Or Disable  True  eth1

    # Fetch the IP details before.
    ${ip_addr_before}  ${gateway_before}  ${subnetmask_before}  Get DHCP IP Info

    # Switch Between Static and DHCP.
    FOR  ${i}  IN RANGE  ${10}
      Set DHCPEnabled To Enable Or Disable  False  eth1
      Set DHCPEnabled To Enable Or Disable  True  eth1
    END
    Sleep  5s

    # Fetch the IP details after.
    ${ip_addr_after}  ${gateway_after}  ${subnetmask_after}  Get DHCP IP Info

    # DHCP Details must be the same before and after.
    Should Be Equal  ${ip_addr_before}  ${ip_addr_after}
    Should Be Equal  ${gateway_before}  ${gateway_after}
    Should Be Equal  ${subnetmask_before}  ${subnetmask_after}

Disable DHCP On Eth1 And Verify DHCP IP Erased
    [Documentation]  Disable DHCP on Eth1 and verify DHCP IP erased.
    [Tags]  Disable_DHCP_On_Eth1_And_Verify_DHCP_IP_Erased
    [Teardown]  Set DHCPEnabled To Enable Or Disable  True  eth1

    Set DHCPEnabled To Enable Or Disable  False  eth1
    ${DHCPEnabled}=  Get IPv4 DHCP Enabled Status  ${2}
    Should Be Equal  ${DHCPEnabled}  ${False}

    ${dhcp_ip_list}=  Get Network Configuration Using Channel Number  ${2}

    Should Be Empty  ${dhcp_ip_list}
    ...  msg=From switching from DHCP to Static DHCP IP is not erased.

*** Keywords ***

Apply DHCP Config
    [Documentation]  Apply DHCP Config
    [Arguments]  ${property}

    # Description of Argument(s):
    # property  DHCP property values.

    Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ...  body={"DHCPv4":${property}}  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    Verify Ethernet Config Property  ${property}  ${resp.dict["DHCPv4"]}

Apply DHCPv6 Config And Verify
    [Documentation]  Apply DHCPv6 config and verify.
    [Arguments]  ${property}

    # Description of Argument(s):
    # property  DHCPv6 property values.

    Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ...  body={"DHCPv6":${property}}  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}

    Verify Ethernet Config Property  ${property}  ${resp.dict["DHCPv6"]}

Verify Ethernet Config Property
    [Documentation]  verify ethernet config properties.
    [Arguments]  ${property}  ${response_data}

    # Description of argument(s):
    # property         DHCP Properties in dictionary.
    #   Example:
    #   property         value
    #   DHCPEnabled      :False
    #   UseDomainName    :True
    #   UseNTPServers    :True
    #   UseDNSServers    :True
    # response_data    DHCP Response data in dictionary.
    #   Example:
    #   property         value
    #   DHCPEnabled      :False
    #   UseDomainName    :True
    #   UseNTPServers    :True
    #   UseDNSServers    :True

   ${key_map}=  Get Dictionary Items  ${property}
   FOR  ${key}  ${value}  IN  @{key_map}
      Should Be Equal As Strings  ${response_data['${key}']}  ${value}
   END

Restore Configuration
    [Documentation]  Restore the configuration to Both Static Network

    IF  '${CHANNEL_NUMBER}' == '${1}'
        Add IP Address  ${OPENBMC_HOST}  ${eth0_subnet_mask}  ${eth0_gateway}
    ELSE IF  '${CHANNEL_NUMBER}' == '{2}'
        Add IP Address  ${OPENBMC_HOST_ETH1}  ${eth1_subnet_mask}  ${eth1_gateway}
    END

Get Network Configuration Using Channel Number
    [Documentation]  Get ethernet interface.
    [Arguments]  ${channel_number}

    # Description of argument(s):
    # channel_number   Ethernet channel number, 1 is for eth0 and 2 is for eth1 (e.g. "1").

    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}

    @{network_configurations}=  Get From Dictionary  ${resp.dict}  IPv4StaticAddresses
    RETURN  @{network_configurations}

Suite Setup Execution
    [Documentation]  Do suite setup task.

    Ping Host  ${OPENBMC_HOST}
    Redfish.Login

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    # Get the configuration of eth1
    ${network_configurations}=  Get Network Configuration Using Channel Number  ${2}
    FOR  ${network_configuration}  IN  @{network_configurations}
        IF  '${network_configuration['Address']}' == '${OPENBMC_HOST_ETH1}'
            Set Suite Variable  ${eth1_subnet_mask}  ${network_configuration['SubnetMask']}
            Set Suite Variable  ${eth1_gateway}  ${network_configuration['Gateway']}
            BREAK
        END
    END

    # Get the configuration of eth0
    ${network_configurations}=  Get Network Configuration Using Channel Number  ${1}
    FOR  ${network_configuration}  IN  @{network_configurations}
        IF  '${network_configuration['Address']}' == '${OPENBMC_HOST}'
            Set Suite Variable  ${eth0_subnet_mask}  ${network_configuration['SubnetMask']}
            Set Suite Variable  ${eth0_gateway}  ${network_configuration['Gateway']}
            BREAK
        END
    END
