*** Settings ***
Documentation          DHCP Network to test suite functionality.

Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/bmc_network_utils.robot
Library                ../lib/bmc_network_utils.py

Suite Setup            Suite Setup Execution
Suite Teardown         Run Keywords  Restore Configuration  AND Redfish.Logout

Test Tags              BMC_DHCP_Conf

*** Variables ***

&{DHCP_ENABLE_DICT}                DHCPEnabled=${True}
&{DHCP_DISABLE_DICT}               DHCPEnabled=${False}

&{DNS_ENABLE_DICT}                 UseDNSServers=${True}
&{DNS_DISABLE_DICT}                UseDNSServers=${False}

&{NTP_ENABLE_DICT}                 UseNTPServers=${True}
&{NTP_DISABLE_DICT}                UseNTPServers=${False}

&{DOMAIN_NAME_ENABLE_DICT}         UseDomainName=${True}
&{DOMAIN_NAME_DISABLE_DICT}        UseDomainName=${False}

&{ENABLE_MULTIPLE_PROPRETIES}      UseDomainName=${True}
...                                UseNTPServers=${True}
...                                UseDNSServers=${True}

&{DISABLE_MULTIPLE_PROPERTIES}     UseDomainName=${False}
...                                UseNTPServers=${False}
...                                UseDNSServers=${False}

*** Test Cases ***

Set Network Property via Redfish And Verify
   [Documentation]  Set network property via Redfish and verify.
   [Tags]  Set_Network_Property_via_Redfish_And_Verify
   [Template]  Apply Ethernet Config

   # property
   ${DHCP_ENABLE_DICT}
   ${DHCP_DISABLE_DICT}
   ${DNS_ENABLE_DICT}
   $NTP_ENABLE_DICT{DNS_DISABLE_DICT}
   ${DOMAIN_NAME_ENABLE_DICT}
   ${DOMAIN_NAME_DISABLE_DICT}
   ${NTP_ENABLE_DICT}
   ${NTP_DISABLE_DICT}
   ${ENABLE_MULTIPLE_PROPRETIES}
   ${DISABLE_MULTIPLE_PROPERTIES}

*** Keywords ***

Suite Setup Execution
    [Documentation]  Suite Setup Execution.

    Ping Host  ${OPENBMC_HOST}
    Ping Host  ${OPENBMC_HOST_ETH1}
    Redfish.Login

    ${network_configurations}=
    ...  Get Network Configuration Using Channel Number  ${2}
    FOR  ${network_configuration}  IN  @{network_configurations}
        IF  '${network_configuration['Address']}' == '${OPENBMC_HOST_ETH1}'
            Set Suite Variable   ${eth1_subnet_mask}  ${network_configuration['SubnetMask']}
            Set Suite Variable   ${eth1_gateway}  ${network_configuration['Gateway']}
            BREAK
        END
    END

    ${network_configurations}=
    ...  Get Network Configuration Using Channel Number  ${1}
    FOR  ${network_configuration}  IN  @{network_configurations}
      IF  '${network_configuration['Address']}' == '${OPENBMC_HOST}'
          Set Suite Variable  ${eth0_subnet_mask}  ${network_configuration['SubnetMask']}
          Set Suite Variable  ${eth0_gateway}  ${network_configuration['Gateway']}
          BREAK
      END
    END

Get Network Configuration Using Channel Number
    [Documentation]  Get ethernet interface.
    [Arguments]  ${channel_number}

    # Description of argument(s):
    # channel_number   Ethernet channel number, 1 is for eth0 and 2 is for
    #                  eth1 (e.g. "1").

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=
    ...  Set Variable  ${active_channel_config['${channel_number}']['name']}
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}

    @{network_configurations}=
    ...  Get From Dictionary  ${resp.dict}  IPv4StaticAddresses
    RETURN  @{network_configurations}

Apply Ethernet Config
    [Documentation]  Set the given Ethernet config property.
    [Arguments]  ${property}

    # Description of argument(s):
    # property   Ethernet property to be set..

    ${active_channel_config}=  Get Active Channel Config
    Redfish.Patch
    ...  /redfish/v1/Managers/${MANAGER_ID}/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}/
    ...  body={"DHCPv4":${property}}  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    ${resp}=  Redfish.Get
    ...  /redfish/v1/Managers/${MANAGER_ID}/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}
    Verify Ethernet Config Property  ${property}  ${resp.dict["DHCPv4"]}

Restore Configuration
    [Documentation]  Restore the configuration to Both Static Network

    IF  '${CHANNEL_NUMBER}' == '1'
        Add IP Address  ${OPENBMC_HOST}  ${eth0_subnet_mask}  ${eth0_gateway}
    ELSE IF  '${CHANNEL_NUMBER}' == '2'
        Add IP Address
        ...  ${OPENBMC_HOST_ETH1}  ${eth1_subnet_mask}  ${eth1_gateway}
    END

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

