*** Settings ***
Documentation  Network interface IPv6 configuration and verification
               ...  tests.

Resource       ../../lib/bmc_redfish_resource.robot
Resource       ../../lib/openbmc_ffdc.robot
Resource       ../../lib/bmc_ipv6_utils.robot
Resource       ../../lib/external_intf/vmi_utils.robot
Resource       ../../lib/bmc_network_utils.robot
Library        ../../lib/bmc_network_utils.py
Library        Collections
Library        Process

Test Setup      Test Setup Execution
Test Teardown   Test Teardown Execution
Suite Setup     Suite Setup Execution
Suite Teardown  Redfish.Logout

Test Tags     BMC_IPv6

*** Variables ***
${test_ipv6_invalid_addr}    2001:db8:3333:4444:5555:6666:7777:JJKK
${test_ipv6_addr1}           2001:db8:3333:4444:5555:6666:7777:9999
${invalid_hexadec_ipv6}      x:x:x:x:x:x:10.5.5.6
${ipv6_multi_short}          2001::33::111
# Valid prefix length is a integer ranges from 1 to 128.
${ipv6_gw_addr}              2002:903:15F:32:9:3:32:1
${prefix_length_def}         None
${invalid_staticv6_gateway}  9.41.164.1
${new_mac_addr}              AA:E2:84:14:28:79
${linklocal_addr_format}     fe80::[0-9a-f:]+$
${link_local_addr}           fe80::
${link_local_prefix_len}     10
${ipv6_leading_zero}         2001:0022:0033::0111
${ipv6_firsthextet_zero}    2001:0022:1133::1111
${ipv6_eliminate_zero}       2001:22:33::111
${ipv6_eliminate_zero1}      2001:22:1133::1111
${ipv6_contigeous_zero}      2001:0022:0000:0000:1:2:3:8
${ipv6_zero_compression}     2001:22::1:2:3:8

*** Test Cases ***

Get IPv6 Address And Verify
    [Documentation]  Get IPv6 Address And Verify.
    [Tags]  Get_IPv6_Address_And_Verify

    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
      Verify IPv6 On BMC  ${ipv6_network_configuration['Address']}
    END


Get PrefixLength And Verify
    [Documentation]  Get IPv6 prefix length and verify.
    [Tags]  Get_PrefixLength_And_Verify

    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
      Verify IPv6 On BMC  ${ipv6_network_configuration['PrefixLength']}
    END


Get IPv6 Default Gateway And Verify
    [Documentation]  Get IPv6 default gateway and verify.
    [Tags]  Get_IPv6_Default_Gateway_And_Verify

    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ${ipv6_gateway}=  Get From Dictionary  ${resp.dict}  IPv6DefaultGateway
    Verify IPv6 Default Gateway On BMC  ${ipv6_gateway}


Verify All Configured IPv6 And PrefixLength On BMC
    [Documentation]  Verify IPv6 address and its prefix length on BMC.
    [Tags]  Verify_All_Configured_IPv6_And_PrefixLength_On_BMC

    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
      Verify IPv6 And PrefixLength  ${ipv6_network_configuration['Address']}
      ...  ${ipv6_network_configuration['PrefixLength']}
    END


Configure IPv6 Address And Verify
    [Documentation]  Configure IPv6 address and verify.
    [Tags]  Configure_IPv6_Address_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IPv6 Address  ${test_ipv6_addr}  AND  Test Teardown Execution
    [Template]  Configure IPv6 Address On BMC


    # IPv6 address     Prefix length
    ${test_ipv6_addr}  ${test_prefix_length}


Configure IPv6 Address On BMC And Verify On Both Interfaces
    [Documentation]  Configure IPv6 address on both interfaces and verify.
    [Tags]  Configure_IPv6_Address_On_BMC_And_Verify_On_Both_Interfaces
    [Teardown]  Run Keywords
    ...  Delete IPv6 Address  ${test_ipv6_addr}  ${1}
    ...  AND  Delete IPv6 Address  ${test_ipv6_addr1}  ${2}
    ...  AND  Test Teardown Execution

    Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}  ${None}  ${1}
    Configure IPv6 Address On BMC  ${test_ipv6_addr1}  ${test_prefix_length}  ${None}  ${2}

    Verify All The Addresses Are Intact  ${1}
    Verify All The Addresses Are Intact  ${2}
    ...    ${eth1_initial_ipv4_addressorigin_list}  ${eth1_initial_ipv4_addr_list}

    # Verify Static IPv6 on eth0
    @{ipv6_addressorigin_list}  ${ipv6_static_addr}=
    ...  Get Address Origin List And Address For Type  Static  ${1}
    Should Contain  ${ipv6_addressorigin_list}  Static
    Should Not Be Empty  ${ipv6_static_addr}  msg=${ipv6_static_addr} address is not present

    # Verify Static IPv6 on eth1
    @{ipv6_addressorigin_list}  ${ipv6_static_addr}=
    ...  Get Address Origin List And Address For Type  Static  ${2}
    Should Contain  ${ipv6_addressorigin_list}  Static
    Should Not Be Empty  ${ipv6_static_addr}  msg=${ipv6_static_addr} address is not present


Delete IPv6 Address And Verify
    [Documentation]  Delete IPv6 address and verify.
    [Tags]  Delete_IPv6_Address_And_Verify

    Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}

    Delete IPv6 Address  ${test_ipv6_addr}


Modify IPv6 Address And Verify
    [Documentation]  Modify IPv6 address and verify.
    [Tags]  Modify_IPv6_Address_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IPv6 Address  ${test_ipv6_addr1}  AND  Test Teardown Execution

    Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}

    Modify IPv6 Address  ${test_ipv6_addr}  ${test_ipv6_addr1}  ${test_prefix_length}


Verify Persistency Of IPv6 After BMC Reboot
    [Documentation]  Verify persistency of IPv6 after BMC reboot.
    [Tags]  Verify_Persistency_Of_IPv6_After_BMC_Reboot
    [Teardown]  Run Keywords
    ...  Delete IPv6 Address  ${test_ipv6_addr}  AND  Test Teardown Execution

    Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}

    Redfish OBMC Reboot (off)  stack_mode=skip

    # Verifying persistency of IPv6.
    Verify IPv6 On BMC  ${test_ipv6_addr}


Enable SLAAC On BMC And Verify
    [Documentation]  Enable SLAAC on BMC and verify.
    [Tags]  Enable_SLAAC_On_BMC_And_Verify

    Set SLAAC Configuration State And Verify  ${True}


Enable DHCPv6 Property On BMC And Verify
    [Documentation]  Enable DHCPv6 property on BMC and verify.
    [Tags]  Enable_DHCPv6_Property_On_BMC_And_Verify

    Set And Verify DHCPv6 Property  Enabled


Disable DHCPv6 Property On BMC And Verify
    [Documentation]  Disable DHCPv6 property on BMC and verify.
    [Tags]  Disable_DHCPv6_Property_On_BMC_And_Verify

    Set And Verify DHCPv6 Property  Disabled


Verify Persistency Of DHCPv6 On Reboot
    [Documentation]  Verify persistency of DHCPv6 property on reboot.
    [Tags]  Verify_Persistency_Of_DHCPv6_On_Reboot

    Set And Verify DHCPv6 Property  Enabled
    Redfish OBMC Reboot (off)       stack_mode=skip
    Verify DHCPv6 Property          Enabled


Verify Persistency Of DHCPv6 On BMC Reboot On Eth1
    [Documentation]  Verify persistency of DHCPv6 property and
    ...    all existing n/w configurations on BMC reboot on eth1.
    [Tags]  Verify_Persistency_Of_DHCPv6_On_BMC_Reboot_On_Eth1
    [Setup]  Set And Verify DHCPv6 Property  Enabled  ${2}

    Redfish OBMC Reboot (off)  stack_mode=skip

    Verify DHCPv6 Property  Enabled  ${2}

    Verify All The Addresses Are Intact  ${1}
    Verify All The Addresses Are Intact  ${2}
    ...    ${eth1_initial_ipv4_addressorigin_list}  ${eth1_initial_ipv4_addr_list}


Verify Persistency Of SLAAC On BMC Reboot On Eth0
    [Documentation]  Verify persistency of SLAAC property on reboot on eth0.
    [Tags]  Verify_Persistency_Of_SLAAC_On_BMC_Reboot_On_Eth0

    Set SLAAC Configuration State And Verify  ${True}  [${HTTP_OK}]  ${1}  ${False}
    Redfish OBMC Reboot (off)      stack_mode=skip
    Verify SLAAC Property          ${True}


Verify Persistency Of SLAAC On BMC Reboot On Eth1
    [Documentation]  Verify persistency of SLAAC property on reboot on eth1.
    [Tags]  Verify_Persistency_Of_SLAAC_On_BMC_Reboot_On_Eth1

    Set SLAAC Configuration State And Verify  ${True}  [${HTTP_OK}]  ${2}  ${False}
    Redfish OBMC Reboot (off)      stack_mode=skip
    Verify SLAAC Property          ${True}  ${2}


Configure Invalid Static IPv6 And Verify
    [Documentation]  Configure invalid static IPv6 and verify.
    [Tags]  Configure_Invalid_Static_IPv6_And_Verify
    [Template]  Configure IPv6 Address On BMC

    #invalid_ipv6            prefix length           valid_status_codes
    ${ipv4_hexword_addr}     ${test_prefix_length}   valid_status_codes=${HTTP_BAD_REQUEST}
    ${invalid_hexadec_ipv6}  ${test_prefix_length}   valid_status_codes=${HTTP_BAD_REQUEST}
    ${ipv6_multi_short}      ${test_prefix_length}   valid_status_codes=${HTTP_BAD_REQUEST}


Configure IPv6 Static Default Gateway And Verify
    [Documentation]  Configure IPv6 static default gateway and verify.
    [Tags]  Configure_IPv6_Static_Default_Gateway_And_Verify
    [Template]  Configure IPv6 Static Default Gateway On BMC

    # static_def_gw              prefix length           valid_status_code
    ${ipv6_gw_addr}              ${prefix_length_def}    ${HTTP_OK}
    ${invalid_staticv6_gateway}  ${test_prefix_length}   ${HTTP_BAD_REQUEST}


Modify Static Default Gateway And Verify
    [Documentation]  Modify static default gateway and verify.
    [Tags]  Modify_Static_Default_Gateway_And_Verify
    [Setup]  Configure IPv6 Static Default Gateway On BMC  ${ipv6_gw_addr}  ${prefix_length_def}

    Modify IPv6 Static Default Gateway On BMC  ${test_ipv6_addr1}  ${prefix_length_def}  ${HTTP_OK}  ${ipv6_gw_addr}


Delete IPv6 Static Default Gateway And Verify
    [Documentation]  Delete IPv6 static default gateway and verify.
    [Tags]  Delete_IPv6_Static_Default_Gateway_And_Verify
    [Setup]  Configure IPv6 Static Default Gateway On BMC  ${ipv6_gw_addr}  ${prefix_length_def}

    Delete IPv6 Static Default Gateway  ${ipv6_gw_addr}


Verify Coexistence Of Linklocalv6 And Static IPv6 On BMC
    [Documentation]  Verify linklocalv6 And static IPv6 both exist.
    [Tags]  Verify_Coexistence_Of_Linklocalv6_And_Static_IPv6_On_BMC
    [Setup]  Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}
    [Teardown]  Delete IPv6 Address  ${test_ipv6_addr}

    Check Coexistence Of Linklocalv6 And Static IPv6


Verify IPv6 Linklocal Address Is In Correct Format
    [Documentation]  Verify linklocal address has network part as fe80 and
    ...  host part as EUI64.
    [Tags]  Verify_IPv6_Linklocal_Address_Is_In_Correct_Format

    Check If Linklocal Address Is In Correct Format


Verify BMC Gets SLAAC Address On Enabling SLAAC
    [Documentation]  On enabling SLAAC verify SLAAC address comes up.
    [Tags]  Verify_BMC_Gets_SLAAC_Address_On_Enabling_SLAAC
    [Setup]  Set SLAAC Configuration State And Verify  ${False}

    Set SLAAC Configuration State And Verify  ${True}
    Sleep  ${NETWORK_TIMEOUT}
    Check BMC Gets SLAAC Address


Verify Enable And Disable SLAAC On Both Interfaces
    [Documentation]  Verify enable and disable SLAAC on both the interfaces.
    [Tags]  Verify_Enable_And_Disable_SLAAC_On_Both_Interfaces
    [Setup]  Get The Initial SLAAC Settings
    [Template]  Set And Verify SLAAC Property On Both Interfaces
    [Teardown]  Run Keywords  Set SLAAC Configuration State And Verify  ${slaac_channel_1}  [${HTTP_OK}]  ${1}
    ...  AND  Set SLAAC Configuration State And Verify  ${slaac_channel_2}  [${HTTP_OK}]  ${2}

    # slaac_eth0       slaac_eth1
    ${True}            ${True}
    ${True}            ${False}
    ${False}           ${True}
    ${False}           ${False}


Configure And Validate DHCPv6 Settings On Both Network Interfaces
    [Documentation]  Configure and validate the DHCPv6 enable/disable settings
    ...  on both network interfaces.
    [Tags]  Configure_And_Validate_DHCPv6_Settings_On_Both_Network_Interfaces
    [Setup]  Get The Initial DHCPv6 Settings
    [Template]  Set And Verify DHCPv6 Property On Both Interfaces
    [Teardown]  Run Keywords  Set And Verify DHCPv6 Property  ${dhcpv6_channel_1}  ${1}  AND
    ...  Set And Verify DHCPv6 Property  ${dhcpv6_channel_2}  ${2}

    # DHCPv6_eth0      DHCPv6_eth1
    Enabled            Enabled
    Enabled            Disabled
    Disabled           Enabled
    Disabled           Disabled


Verify Autoconfig Is Present On Ethernet Interface
    [Documentation]  Verify autoconfig is present on ethernet interface.
    [Tags]  Verify_Autoconfig_Is_Present_On_Ethernet_Interface

    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    Should Contain  ${resp.dict}  StatelessAddressAutoConfig


Verify Interface ID Of SLAAC And LinkLocal Addresses Are Same
    [Documentation]  Validate interface id of SLAAC and link-local addresses are same.
    [Tags]  Verify_Interface_ID_Of_SLAAC_And_LinkLocal_Addresses_Are_Same

    @{ipv6_addressorigin_list}  ${ipv6_linklocal_addr}=  Get Address Origin List And Address For Type  LinkLocal
    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=  Get Address Origin List And Address For Type  SLAAC

    ${linklocal_interface_id}=  Get Interface ID Of IPv6  ${ipv6_linklocal_addr}
    ${slaac_interface_id}=  Get Interface ID Of IPv6  ${ipv6_slaac_addr}

    Should Be Equal    ${linklocal_interface_id}    ${slaac_interface_id}


Verify Persistency Of Link Local IPv6 On BMC Reboot
    [Documentation]  Verify persistency of link local on BMC reboot.
    [Tags]  Verify_Persistency_Of_Link_Local_IPv6_On_BMC_Reboot

    # Capturing the linklocal before reboot.
    @{ipv6_address_origin_list}  ${linklocal_addr_before_reboot}=
    ...  Get Address Origin List And Address For Type  LinkLocal

    # Rebooting BMC.
    Redfish OBMC Reboot (off)  stack_mode=skip

    @{ipv6_address_origin_list}  ${linklocal_addr_after_reboot}=
    ...  Get Address Origin List And Address For Type  LinkLocal

    # Verifying the linklocal must be the same before and after reboot.
    Should Be Equal    ${linklocal_addr_before_reboot}    ${linklocal_addr_after_reboot}
    ...    msg=IPv6 Linklocal address has changed after reboot.


Modify MAC and Verify BMC Reinitializing Linklocal
    [Documentation]  Modify MAC and verify BMC reinitializing linklocal.
    [Tags]  Modify_MAC_and_Verify_BMC_Reinitializing_Linklocal
    [Teardown]  Configure MAC Settings  ${original_address}

    ${original_address}=  Get BMC MAC Address
    @{ipv6_addressorigin_list}  ${ipv6_before_linklocal_addr}=  Get Address Origin List And Address For Type  LinkLocal

    # Modify MAC Address Of Ethernet Interface.
    Configure MAC Settings  ${new_mac_addr}
    Sleep  30s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}
    @{ipv6_addressorigin_list}  ${ipv6_linklocal_after_addr}=  Get Address Origin List And Address For Type  LinkLocal

    # Verify whether the linklocal has changed and is in the the correct format.
    Check If Linklocal Address Is In Correct Format
    Should Not Be Equal    ${ipv6_before_linklocal_addr}    ${ipv6_linklocal_after_addr}


Add Multiple IPv6 Address And Verify
    [Documentation]  Add multiple IPv6 address and verify.
    [Tags]  Add_Multiple_IPv6_Address_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IPv6 Address  ${test_ipv6_addr}  AND  Delete IPv6 Address  ${test_ipv6_addr1}
    ...  AND  Test Teardown Execution

    Configure Multiple IPv6 Address on BMC  ${test_prefix_length}


Verify Coexistence Of Static IPv6 And SLAAC On BMC
    [Documentation]  Verify static IPv6 And SLAAC both coexist.
    [Tags]  Verify_Coexistence_Of_Static_IPv6_And_SLAAC_On_BMC
    [Setup]  Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}
             Set SLAAC Configuration State And Verify  ${True}
    [Teardown]  Delete IPv6 Address  ${test_ipv6_addr}

    Sleep  ${NETWORK_TIMEOUT}s

    Check Coexistence Of Static IPv6 And SLAAC


Verify Coexistence Of Link Local And DHCPv6 On BMC
    [Documentation]  Verify link local And dhcpv6 both coexist.
    [Tags]  Verify_Coexistence_Of_Link_Local_And_DHCPv6_On_BMC
    [Setup]  Set DHCPv6 Property  Enabled  ${2}

    Sleep  ${NETWORK_TIMEOUT}s

    Check Coexistence Of Link Local And DHCPv6


Verify Coexistence Of Link Local And SLAAC On BMC
    [Documentation]  Verify link local And SLAAC both coexist.
    [Tags]  Verify_Coexistence_Of_Link_Local_And_SLAAC_On_BMC
    [Setup]  Set SLAAC Configuration State And Verify  ${True}

    Sleep  ${NETWORK_TIMEOUT}s

    Check Coexistence Of Link Local And SLAAC


Verify Coexistence Of All IPv6 Type Addresses On BMC
    [Documentation]  Verify coexistence of link local, static, DHCPv6 and SLAAC ipv6 addresses.
    [Tags]  Verify_Coexistence_Of_All_IPv6_Type_Addresses_On_BMC
    [Setup]  Run Keywords  Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}
    ...      AND  Get The Initial DHCPv6 Setting On Each Interface  ${1}
    ...      AND  Set And Verify DHCPv6 Property  Enabled
    ...      AND  Get The Initial SLAAC Setting On Each Interface  ${1}
    ...      AND  Set SLAAC Configuration State And Verify  ${True}
    [Teardown]  Run Keywords  Delete IPv6 Address  ${test_ipv6_addr}
    ...         AND  Set And Verify DHCPv6 Property  ${dhcpv6_channel_1}  ${1}
    ...         AND  Set SLAAC Configuration State And Verify  ${slaac_channel_1}  [${HTTP_OK}]  ${1}

    Sleep  ${NETWORK_TIMEOUT}s

    # Verify link local, static, DHCPv6 and SLAAC ipv6 addresses coexist.
    Verify The Coexistence Of The Address Type  LinkLocal  Static  DHCPv6  SLAAC


Configure Link Local IPv6 Address And Verify
    [Documentation]  Configure link local IPv6 address and verify.
    [Tags]  Configure_Link_Local_IPv6_Address_And_Verify

    Configure IPv6 Address On BMC  ${link_local_addr}  ${link_local_prefix_len}

    # Verify the address origin contains link local.
    @{ipv6_address_origin_list}  ${ipv6_link_local_addr}=
    ...    Get Address Origin List And Address For Type  LinkLocal

    ${count}=  Evaluate  ${ipv6_address_origin_list}.count("LinkLocal")

    Should Be Equal As Integers  ${count}  2


Configure Valid IPv6 Address And Verify
    [Documentation]  Configure valid IPv6 address and verify it is getting added as expected format.
    [Tags]  Configure_Valid_IPv6_Address_And_Verify
    [Teardown]  Run Keywords
    ...  Delete IPv6 Address  ${ipv6_zero_compression}
    ...    AND  Delete IPv6 Address  ${ipv6_eliminate_zero}
    ...    AND  Delete IPv6 Address  ${ipv6_eliminate_zero1}
    ...    AND  Test Teardown Execution
    [Template]  Configure IPv6 Address On BMC

    # IPv6 address            prefix length          IPv6 address verified.
    ${ipv6_contigeous_zero}   ${test_prefix_length}  ${ipv6_zero_compression}
    ${ipv6_firsthextet_zero}  ${test_prefix_length}  ${ipv6_eliminate_zero1}
    ${ipv6_leading_zero}      ${test_prefix_length}  ${ipv6_eliminate_zero}


Verify Coexistence Of IPv6 Addresses Type Combination On BMC
    [Documentation]  Verify coexistence of IPv6 addresses type combination on BMC.
    [Tags]  Verify_Coexistence_Of_IPv6_Addresses_Type_Combination_On_BMC
    [Setup]  Run Keywords
    ...    Get The Initial DHCPv6 Setting On Each Interface  ${1}
    ...    AND  Get The Initial SLAAC Setting On Each Interface  ${1}
    [Teardown]  Run Keywords
    ...    Set And Verify DHCPv6 Property  ${dhcpv6_channel_1}  ${1}
    ...    AND  Set SLAAC Configuration State And Verify  ${slaac_channel_1}  [${HTTP_OK}]  ${1}
    [Template]  Verify IPv6 Addresses Coexist

   # type1  type2.
    Static  DHCPv6
    DHCPv6  SLAAC
    SLAAC   Static
    Static  Static


Verify Eth0 Static IPv4 Functions Properly In The Presence Of DHCPv6
    [Documentation]  Verify eth0 static IPv4 functions properly in the presence of DHCPv6.
    [Tags]  Verify_Eth0_Static_IPv4_Functions_Properly_In_The_Presence_Of_DHCPv6
    [Setup]  Set And Verify DHCPv6 Property  Enabled

    # Verify that on enabling DHCPv6 other configurations are not impacted.
    Sleep  ${NETWORK_TIMEOUT}
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

    Verify All The Addresses Are Intact  ${1}
    Verify All The Addresses Are Intact  ${2}
    ...    ${eth1_initial_ipv4_addressorigin_list}  ${eth1_initial_ipv4_addr_list}


Disable And Verify AutoConfig On Both Interfaces When AutoConfig Enabled
    [Documentation]  Enable and then disable both eth0 & eth1 with auto-config and
    ...    check both interfaces gets disabled with SLAAC.
    [Tags]  Disable_And_Verify_AutoConfig_On_Both_Interfaces_When_AutoConfig_Enabled
    [Setup]  Set And Verify SLAAC Property On Both Interfaces  ${True}  ${True}
    [Template]  Set And Verify SLAAC Property On Both Interfaces

    # slaac_eth0       slaac_eth1.
    ${False}           ${False}


Verify Eth1 DHCPv4 Functionality In The Presence Of Static IPv6
    [Documentation]  Verify eth1 dhcpv4 functionality in the presence of Static IPv6
    ...    and verify link local IPv6 and SLAAC.
    ...    Run on setup with DHCPv4 available on eth1.
    [Tags]  Verify_Eth1_DHCPv4_Functionality_In_The_Presence_Of_Static_IPv6
    [Setup]  Run Keywords
    ...  Set DHCPEnabled To Enable Or Disable  True  eth1
    ...  AND  Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}  ${None}  ${2}
    ...  AND  Set SLAAC Configuration State And Verify  ${True}  [${HTTP_OK}]  ${2}

    # Verify presence of static IPv6 address and origin.
    @{ipv6_address_origin_list}  ${static_ipv6_addr}=
    ...  Get Address Origin List And Address For Type  Static  ${2}
    Should Contain  ${ipv6_address_origin_list}  Static
    Should Not Be Empty  ${static_ipv6_addr}  msg=${test_ipv6_addr} address is not present

    # Verify presence of link local IPv6 address and origin.
    @{ipv6_address_origin_list}  ${link_local_ipv6_addr}=
    ...  Get Address Origin List And Address For Type  LinkLocal  ${2}
    Should Contain  ${ipv6_address_origin_list}  LinkLocal
    Should Match Regexp  ${link_local_ipv6_addr}  ${linklocal_addr_format}
    Should Not Be Empty  ${link_local_ipv6_addr}  msg=link local IPv6 address is not present

    # Verify presence of SLAAC address and origin.
    Sleep  ${NETWORK_TIMEOUT}s
    @{ipv6_address_origin_list}  ${slaac_addr}=
    ...  Get Address Origin List And Address For Type  SLAAC  ${2}
    Should Contain  ${ipv6_address_origin_list}  SLAAC
    Should Not Be Empty  ${slaac_addr}  msg=SLAAC address is not present

    Verify DHCPv4 Functionality On Eth1


Verify Eth1 DHCPv4 Functionality In The Presence Of DHCPv6
    [Documentation]  Verify eth1 dhcpv4 functionality in the presence of dhcpv6.
    ...    Run on setup with DHCPv4 available on eth1.
    [Tags]  Verify_Eth1_DHCPv4_Functionality_In_The_Presence_Of_DHCPv6
    [Setup]  Run Keywords
    ...  Set DHCPEnabled To Enable Or Disable  True  eth1
    ...  AND  Set And Verify DHCPv6 Property  Enabled  ${2}

    # Verify presence of DHCPv6 address and origin.
    @{ipv6_address_origin_list}  ${dhcpv6_addr}=
    ...  Get Address Origin List And Address For Type  DHCPv6  ${2}
    Should Contain  ${ipv6_address_origin_list}  DHCPv6
    Should Not Be Empty  ${dhcpv6_addr}  msg=dhcpv6 address is not present

    Verify DHCPv4 Functionality On Eth1


Verify Static IPv4 Functionality In Presence Of Static IPv6
    [Documentation]  Verify static IPv4 functionality in presence of static IPv6.
    [Tags]  Verify_Static_IPv4_Functionality_In_Presence_Of_Static_IPv6
    [Setup]  Run Keywords
    ...  Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}  ${None}  ${1}
    ...  AND  Configure IPv6 Address On BMC  ${test_ipv6_addr1}  ${test_prefix_length}  ${None}  ${2}
    [Template]  Verify Static IPv4 Functionality

    # Channel_number
    ${1}
    ${2}


Verify Enable SLAAC On Eth0 While Eth0 In Static And Eth1 In DHCPv4
    [Documentation]  Set eth0 to static & eth1 to DHCPv4, enable slaac and verify.
    [Tags]  Verify_Enable_SLAAC_On_Eth0_While_Eth0_In_Static_And_Eth1_In_DHCPv4
    [Setup]  Run Keywords
    ...  Add IP Address  ${test_ipv4_addr}  ${test_subnet_mask}  ${test_gateway}
    ...  AND  Set DHCPEnabled To Enable Or Disable  True  eth1

    Set SLAAC Configuration State And Verify  ${True}
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}


Configure Static IPv4 On Eth0 and Eth1 And Configure Static IPv6 And Verify
    [Documentation]  Configure static IPv4 address on both eth0 and eth1 and then configure
    ...    static IPv6 address on eth0/eth1 and verify all addresses are reachable.
    [Tags]  Configure_Static_IPv4_On_Eth0_and_Eth1_And_Configure_Static_IPv6_And_Verify
    [Setup]  Add Static IPv4 Address On Both Eth0 And Eth1
    [Template]  Configure Static IPv6 And Verify IP Reachability

    # channel_number
    ${1}
    ${2}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup execution.

    Redfish.Login
    ${active_channel_config}=  Get Active Channel Config
    Set Suite Variable  ${active_channel_config}

    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Set Suite variable  ${ethernet_interface}

    # Get initial IPv4 and IPv6 addresses and address origins for eth0.
    ${initial_ipv4_addressorigin_list}  ${initial_ipv4_addr_list}=  Get Address Origin List And IPv4 or IPv6 Address  IPv4Addresses
    ${initial_ipv6_addressorigin_list}  ${initial_ipv6_addr_list}=  Get Address Origin List And IPv4 or IPv6 Address  IPv6Addresses

    Set Suite Variable   ${initial_ipv4_addressorigin_list}
    Set Suite Variable   ${initial_ipv4_addr_list}
    Set Suite Variable   ${initial_ipv6_addressorigin_list}
    Set Suite Variable   ${initial_ipv6_addr_list}

    # Get initial IPv4 and IPv6 addresses and address origins for eth1.
    ${eth1_initial_ipv4_addressorigin_list}  ${eth1_initial_ipv4_addr_list}=
    ...  Get Address Origin List And IPv4 or IPv6 Address  IPv4Addresses  ${2}
    ${eth1_initial_ipv6_addressorigin_list}  ${eth1_initial_ipv6_addr_list}=
    ...  Get Address Origin List And IPv4 or IPv6 Address  IPv6Addresses  ${2}
    Set Suite Variable   ${eth1_initial_ipv4_addressorigin_list}
    Set Suite Variable   ${eth1_initial_ipv4_addr_list}
    Set Suite Variable   ${eth1_initial_ipv6_addressorigin_list}
    Set Suite Variable   ${eth1_initial_ipv6_addr_list}
    ${test_gateway}=     Get BMC Default Gateway
    Set Suite variable   ${test_gateway}


Test Setup Execution
    [Documentation]  Test setup execution.

    @{ipv6_network_configurations}=  Get IPv6 Network Configuration
    Set Test Variable  @{ipv6_network_configurations}

    # Get BMC IPv6 address and prefix length.
    ${ipv6_data}=  Get BMC IPv6 Info
    Set Test Variable  ${ipv6_data}


Test Teardown Execution
    [Documentation]  Test teardown execution.

    FFDC On Test Case Fail


Configure Multiple IPv6 Address on BMC
    [Documentation]  Add multiple IPv6 address on BMC.
    [Arguments]  ${prefix_len}
    ...          ${valid_status_codes}=[${HTTP_OK},${HTTP_NO_CONTENT}]

    # Description of argument(s):
    # prefix_len          Prefix length for the IPv6 to be added
    #                     (e.g. "64").
    # valid_status_codes  Expected return code from patch operation
    #                     (e.g. "200").

    ${ipv6_list}=  Create List  ${test_ipv6_addr}  ${test_ipv6_addr1}
    ${prefix_length}=  Convert To Integer  ${prefix_len}
    ${empty_dict}=  Create Dictionary
    ${patch_list}=  Create List

    # Get existing static IPv6 configurations on BMC.
    ${ipv6_network_configurations}=  Get IPv6 Network Configuration
    ${num_entries}=  Get Length  ${ipv6_network_configurations}

    FOR  ${INDEX}  IN RANGE  0  ${num_entries}
      Append To List  ${patch_list}  ${empty_dict}
    END

    # We need not check for existence of IPv6 on BMC while adding.
    FOR  ${ipv6_addr}  IN  @{ipv6_list}
      ${ipv6_data}=  Create Dictionary  Address=${ipv6_addr}  PrefixLength=${prefix_length}
      Append To List  ${patch_list}  ${ipv6_data}
    END
    ${data}=  Create Dictionary  IPv6StaticAddresses=${patch_list}

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Redfish.patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body=&{data}
    ...  valid_status_codes=${valid_status_codes}

    IF  ${valid_status_codes} != [${HTTP_OK}, ${HTTP_NO_CONTENT}]
        Fail  msg=Static address not added correctly
    END

    # Note: Network restart takes around 15-18s after patch request processing.
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

    # Verify newly added ip address on CLI.
    FOR  ${ipv6_addr}  IN  @{ipv6_list}
      Verify IPv6 And PrefixLength  ${ipv6_addr}  ${prefix_len}
    END

    # Verify if existing static IPv6 addresses still exist.
    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
      Verify IPv6 On BMC  ${ipv6_network_configuration['Address']}
    END

    # Get the latest ipv6 network configurations.
    @{ipv6_network_configurations}=  Get IPv6 Network Configuration

    # Verify newly added ip address on BMC.
    FOR  ${ipv6_network_configuration}  IN  @{ipv6_network_configurations}
      Should Contain Match  ${ipv6_list}  ${ipv6_network_configuration['Address']}
    END

    Validate IPv6 Network Config On BMC


Set And Verify DHCPv6 Property
    [Documentation]  Set DHCPv6 property and verify.
    [Arguments]  ${dhcpv6_operating_mode}=${Disabled}  ${channel_number}=${CHANNEL_NUMBER}

    # Description of argument(s):
    # dhcpv6_operating_mode    Enabled if user wants to enable DHCPv6('Enabled' or 'Disabled').
    # channel_number           Channel number 1 or 2.

    Set DHCPv6 Property  ${dhcpv6_operating_mode}  ${channel_number}
    Verify DHCPv6 Property  ${dhcpv6_operating_mode}  ${channel_number}


Set DHCPv6 Property
    [Documentation]  Set DHCPv6 attribute is enables or disabled.
    [Arguments]  ${dhcpv6_operating_mode}=${Disabled}  ${channel_number}=${CHANNEL_NUMBER}

    # Description of argument(s):
    # dhcpv6_operating_mode    Enabled if user wants to enable DHCPv6('Enabled' or 'Disabled').
    # channel_number           Channel number 1 or 2.

    ${data}=  Set Variable If  '${dhcpv6_operating_mode}' == 'Disabled'  ${DISABLE_DHCPv6}  ${ENABLE_DHCPv6}
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ...  body=${data}  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]


Verify DHCPv6 Property
    [Documentation]  Verify DHCPv6 settings is enabled or disabled.
    [Arguments]  ${dhcpv6_operating_mode}  ${channel_number}=${CHANNEL_NUMBER}

    # Description of Argument(s):
    # dhcpv6_operating_mode  Enable/ Disable DHCPv6.
    # channel_number         Channel number 1 or 2.

    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}

    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ${dhcpv6_verify}=  Get From Dictionary  ${resp.dict}  DHCPv6

    Should Be Equal  '${dhcpv6_verify['OperatingMode']}'  '${dhcpv6_operating_mode}'

    Sleep  30s

    @{ipv6_addressorigin_list}  ${ipv6_dhcpv6_addr}=
    ...  Get Address Origin List And IPv4 or IPv6 Address  IPv6Addresses  ${channel_number}

    IF  "${dhcpv6_operating_mode}" == "Enabled"
        @{ipv6_addressorigin_list}  ${ipv6_dhcpv6_addr}=
        ...  Get Address Origin List And Address For Type  DHCPv6  ${channel_number}
        Should Not Be Empty  ${ipv6_dhcpv6_addr}  msg=DHCPv6 must be present.
    ELSE
        Should Not Contain  ${ipv6_addressorigin_list}  DHCPv6
    END



Get IPv6 Static Default Gateway
    [Documentation]  Get IPv6 static default gateway.

    ${active_channel_config}=  Get Active Channel Config
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${active_channel_config['${CHANNEL_NUMBER}']['name']}

    @{ipv6_static_defgw_configurations}=  Get From Dictionary  ${resp.dict}  IPv6StaticDefaultGateways
    RETURN  @{ipv6_static_defgw_configurations}


Configure IPv6 Static Default Gateway On BMC
    [Documentation]  Configure IPv6 static default gateway on BMC.
    [Arguments]  ${ipv6_gw_addr}  ${prefix_length_def}
    ...  ${valid_status_codes}=${HTTP_OK}

    # Description of argument(s):
    # ipv6_gw_addr          IPv6 Static Default Gateway address to be configured.
    # prefix_len_def        Prefix length value (Range 1 to 128).
    # valid_status_codes    Expected return code from patch operation
    #                       (e.g. "200", "204".)

    # Prefix Length is passed as None.
    IF   '${prefix_length_def}' == '${None}'
        ${ipv6_gw}=  Create Dictionary  Address=${ipv6_gw_addr}
    ELSE
        ${ipv6_gw}=  Create Dictionary  Address=${ipv6_gw_addr}  Prefix Length=${prefix_length_def}
    END

    ${ipv6_static_def_gw}=  Get IPv6 Static Default Gateway

    ${num_entries}=  Get Length  ${ipv6_static_def_gw}

    ${patch_list}=  Create List
    ${empty_dict}=  Create Dictionary

    FOR  ${INDEX}  IN RANGE  0  ${num_entries}
      Append To List  ${patch_list}  ${empty_dict}
    END

    ${valid_status_codes}=  Set Variable If  '${valid_status_codes}' == '${HTTP_OK}'
    ...  ${HTTP_OK},${HTTP_NO_CONTENT}
    ...  ${valid_status_codes}

    Append To List  ${patch_list}  ${ipv6_gw}
    ${data}=  Create Dictionary  IPv6StaticDefaultGateways=${patch_list}

    Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ...  body=${data}  valid_status_codes=[${valid_status_codes}]

    # Verify the added static default gateway is present in Redfish Get Output.
    ${ipv6_staticdef_gateway}=  Get IPv6 Static Default Gateway

    ${ipv6_static_def_gw_list}=  Create List
    FOR  ${ipv6_staticdef_gateway}  IN  @{ipv6_staticdef_gateway}
        ${value}=    Get From Dictionary    ${ipv6_staticdef_gateway}    Address
        Append To List  ${ipv6_static_def_gw_list}  ${value}
    END

    IF  '${valid_status_codes}' != '${HTTP_OK},${HTTP_NO_CONTENT}'
        Should Not Contain  ${ipv6_static_def_gw_list}  ${ipv6_gw_addr}
    ELSE
        Should Contain  ${ipv6_static_def_gw_list}  ${ipv6_gw_addr}
    END


Modify IPv6 Static Default Gateway On BMC
    [Documentation]  Modify and verify IPv6 address of BMC.
    [Arguments]  ${ipv6_gw_addr}  ${new_static_def_gw}  ${prefix_length}
    ...  ${valid_status_codes}=[${HTTP_OK},${HTTP_ACCEPTED}]

    # Description of argument(s):
    # ipv6_gw_addr          IPv6 static default gateway address to be replaced (e.g. "2001:AABB:CCDD::AAFF").
    # new_static_def_gw     New static default gateway address to be configured.
    # prefix_length         Prefix length value (Range 1 to 128).
    # valid_status_codes    Expected return code from patch operation
    #                       (e.g. "200", "204").

    ${empty_dict}=  Create Dictionary
    ${patch_list}=  Create List
    # Prefix Length is passed as None.
    IF   '${prefix_length_def}' == '${None}'
        ${modified_ipv6_gw_addripv6_data}=  Create Dictionary  Address=${new_static_def_gw}
    ELSE
        ${modified_ipv6_gw_addripv6_data}=  Create Dictionary  Address=${new_static_def_gw}  Prefix Length=${prefix_length_def}
    END

    @{ipv6_static_def_gw_list}=  Get IPv6 Static Default Gateway

    FOR  ${ipv6_static_def_gw}  IN  @{ipv6_static_def_gw_list}
      IF  '${ipv6_static_def_gw['Address']}' == '${ipv6_gw_addr}'
          Append To List  ${patch_list}  ${modified_ipv6_gw_addripv6_data}
      ELSE
          Append To List  ${patch_list}  ${empty_dict}
      END
    END

    # Modify the IPv6 address only if given IPv6 static default gateway is found.
    ${ip_static_def_gw_found}=  Run Keyword And Return Status  List Should Contain Value
    ...  ${patch_list}  ${modified_ipv6_gw_addripv6_data}  msg=${ipv6_gw_addr} does not exist on BMC
    Pass Execution If  ${ip_static_def_gw_found} == ${False}  ${ipv6_gw_addr} does not exist on BMC

    ${data}=  Create Dictionary  IPv6StaticDefaultGateways=${patch_list}

    Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ...  body=&{data}  valid_status_codes=${valid_status_codes}

    ${ipv6_staticdef_gateway}=  Get IPv6 Static Default Gateway

    ${ipv6_static_def_gw_list}=  Create List
    FOR  ${ipv6_staticdef_gateway}  IN  @{ipv6_staticdef_gateway}
        ${value}=  Get From Dictionary  ${ipv6_staticdef_gateway}  Address
        Append To List  ${ipv6_static_def_gw_list}  ${value}
    END

    Should Contain  ${ipv6_static_def_gw_list}  ${new_static_def_gw}
    # Verify if old static default gateway address is erased.
    Should Not Contain  ${ipv6_static_def_gw_list}  ${ipv6_gw_addr}


Delete IPv6 Static Default Gateway
    [Documentation]  Delete IPv6 static default gateway on BMC.
    [Arguments]  ${ipv6_gw_addr}
    ...          ${valid_status_codes}=[${HTTP_OK},${HTTP_ACCEPTED},${HTTP_NO_CONTENT}]

    # Description of argument(s):
    # ipv6_gw_addr          IPv6 Static Default Gateway address to be deleted.
    # valid_status_codes    Expected return code from patch operation
    #                       (e.g. "200").

    ${patch_list}=  Create List
    ${empty_dict}=  Create Dictionary

    ${ipv6_static_def_gw_list}=  Create List
    @{ipv6_static_defgw_configurations}=  Get IPv6 Static Default Gateway

    FOR  ${ipv6_staticdef_gateway}  IN  @{ipv6_static_defgw_configurations}
        ${value}=  Get From Dictionary  ${ipv6_staticdef_gateway}  Address
        Append To List  ${ipv6_static_def_gw_list}  ${value}
    END

    ${defgw_found}=  Run Keyword And Return Status  List Should Contain Value
    ...  ${ipv6_static_def_gw_list}  ${ipv6_gw_addr}  msg=${ipv6_gw_addr} does not exist on BMC
    Skip If  ${defgw_found} == ${False}  ${ipv6_gw_addr} does not exist on BMC

    FOR  ${ipv6_static_def_gw}  IN  @{ipv6_static_defgw_configurations}
        IF  '${ipv6_static_def_gw['Address']}' == '${ipv6_gw_addr}'
            Append To List  ${patch_list}  ${null}
        ELSE
            Append To List  ${patch_list}  ${empty_dict}
      END
    END

    # Run patch command only if given IP is found on BMC.
    ${data}=  Create Dictionary  IPv6StaticDefaultGateways=${patch_list}

    Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body=&{data}
    ...  valid_status_codes=${valid_status_codes}

    ${data}=  Create Dictionary  IPv6StaticDefaultGateways=${patch_list}

    @{ipv6_static_defgw_configurations}=  Get IPv6 Static Default Gateway
    Should Not Contain Match  ${ipv6_static_defgw_configurations}  ${ipv6_gw_addr}
    ...  msg=IPv6 Static default gateway does not exist.


Check Coexistence Of Linklocalv6 And Static IPv6
    [Documentation]  Verify both linklocalv6 and static IPv6 exist.

    # Verify the address origin contains static and linklocal.
    @{ipv6_addressorigin_list}  ${ipv6_linklocal_addr}=  Get Address Origin List And Address For Type  LinkLocal

    Should Match Regexp  ${ipv6_linklocal_addr}        ${linklocal_addr_format}
    Should Contain       ${ipv6_addressorigin_list}    Static


Check Coexistence Of Static IPv6 And SLAAC
    [Documentation]  Verify both static IPv6 and SLAAC coexist.

    # Verify the address origin contains static and slaac.
    @{ipv6_addressorigin_list}  ${ipv6_static_addr}=
    ...    Get Address Origin List And Address For Type  Static

    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=
    ...    Get Address Origin List And Address For Type  SLAAC


Check Coexistence Of Link Local And SLAAC
    [Documentation]  Verify both link local and SLAAC coexist.

    # Verify the address origin contains SLAAC and link local.
    @{ipv6_addressorigin_list}  ${ipv6_link_local_addr}=
    ...    Get Address Origin List And Address For Type  LinkLocal

    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=
    ...    Get Address Origin List And Address For Type  SLAAC

    Should Match Regexp    ${ipv6_link_local_addr}    ${linklocal_addr_format}


Check Coexistence Of Link Local And DHCPv6
    [Documentation]  Verify both link local and dhcpv6 coexist.

    # Verify the address origin contains dhcpv6 and link local.
    @{ipv6_address_origin_list}  ${ipv6_link_local_addr}=
    ...    Get Address Origin List And Address For Type  LinkLocal

    @{ipv6_address_origin_list}  ${ipv6_dhcpv6_addr}=
    ...    Get Address Origin List And Address For Type  DHCPv6

    Should Match Regexp    ${ipv6_link_local_addr}    ${linklocal_addr_format}


Check If Linklocal Address Is In Correct Format
    [Documentation]  Linklocal address has network part fe80 and host part EUI64.

    # Fetch the linklocal address.
    @{ipv6_addressorigin_list}  ${ipv6_linklocal_addr}=  Get Address Origin List And Address For Type  LinkLocal

    # Follow EUI64 from MAC.
    ${system_mac}=  Get BMC MAC Address
    ${split_octets}=  Split String  ${system_mac}  :
    ${first_octet}=  Evaluate  int('${split_octets[0]}', 16)
    ${flipped_hex}=  Evaluate  format(${first_octet} ^ 2, '02x')
    ${grp1}=  Evaluate  re.sub(r'^0+', '', '${flipped_hex}${split_octets[1]}')  modules=re
    ${grp2}=  Evaluate  re.sub(r'^0+', '', '${split_octets[2]}ff')  modules=re
    ${grp3}=  Evaluate  re.sub(r'^0+', '', '${split_octets[4]}${split_octets[5]}')  modules=re
    ${linklocal}=  Set Variable  fe80::${grp1}:${grp2}:fe${split_octets[3]}:${grp3}

    # Verify the linklocal obtained is the same as on the machine.
    Should Be Equal  ${linklocal}  ${ipv6_linklocal_addr}


Check BMC Gets SLAAC Address
    [Documentation]  Check BMC gets slaac address.

    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=  Get Address Origin List And Address For Type  SLAAC


Get The Initial DHCPv6 Setting On Each Interface
    [Documentation]  Get the initial DHCPv6 setting of each interface.
    [Arguments]  ${channel_number}

    # Description of the argument(s):
    # channel_number    Channel number 1 or 2.

    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ${initial_dhcpv6_iface}=  Get From Dictionary  ${resp.dict}  DHCPv6
    IF  ${channel_number}==${1}
        Set Test Variable  ${dhcpv6_channel_1}  ${initial_dhcpv6_iface['OperatingMode']}
    ELSE
        Set Test Variable  ${dhcpv6_channel_2}  ${initial_dhcpv6_iface['OperatingMode']}
    END


Get The Initial DHCPv6 Settings
    [Documentation]  Get the initial DHCPv6 settings of both the interfaces.

    Get The Initial DHCPv6 Setting On Each Interface  ${1}
    Get The Initial DHCPv6 Setting On Each Interface  ${2}


Get The Initial SLAAC Settings
    [Documentation]  Get the initial SLAAC settings of both the interfaces.

    Get The Initial SLAAC Setting On Each Interface   ${1}
    Get The Initial SLAAC Setting On Each Interface   ${2}


Get The Initial SLAAC Setting On Each Interface
    [Documentation]  Get the initial SLAAC setting of the interface.
    [Arguments]  ${channel_number}

    # Description of the argument(s):
    # channel_number     Channel number 1 or 2.

    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    ${initial_slaac_iface}=  Get From Dictionary  ${resp.dict}  StatelessAddressAutoConfig
    IF  ${channel_number}==${1}
        Set Test Variable  ${slaac_channel_1}  ${initial_slaac_iface['IPv6AutoConfigEnabled']}
    ELSE
        Set Test Variable  ${slaac_channel_2}  ${initial_slaac_iface['IPv6AutoConfigEnabled']}
    END


Verify All The Addresses Are Intact
    [Documentation]  Verify all the addresses and address origins remain intact.
    [Arguments]    ${channel_number}=${CHANNEL_NUMBER}
    ...  ${initial_ipv4_addressorigin_list}=${initial_ipv4_addressorigin_list}
    ...  ${initial_ipv4_addr_list}=${initial_ipv4_addr_list}

    # Description of argument(s):
    # channel_number                   Channel number 1(eth0) or 2(eth1).
    # initial_ipv4_addressorigin_list  Initial IPv4 address origin list.
    # initial_ipv4_addr_list           Initial IPv4 address list.

    # Verify that it will not impact the IPv4 configuration.
    Sleep  ${NETWORK_TIMEOUT}
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

    # IPv6 Linklocal address must be present.
    @{ipv6_addressorigin_list}  ${ipv6_linklocal_addr}=
    ...  Get Address Origin List And Address For Type  LinkLocal  ${channel_number}

    # IPv4 addresses must remain intact.
    ${ipv4_addressorigin_list}  ${ipv4_addr_list}=
    ...  Get Address Origin List And IPv4 or IPv6 Address  IPv4Addresses  ${channel_number}

    Should be Equal  ${initial_ipv4_addressorigin_list}  ${ipv4_addressorigin_list}
    Should be Equal  ${initial_ipv4_addr_list}  ${ipv4_addr_list}


Get Interface ID Of IPv6
    [Documentation]  Get interface id of IPv6 address.
    [Arguments]    ${ipv6_address}

    # Description of the argument(s):
    # ${ipv6_address}  IPv6 Address to extract the last 4 hextets.

    # Last 64 bits of SLAAC and Linklocal must be the same.
    # Sample IPv6 network configurations.
    #"IPv6AddressPolicyTable": [],
    #  "IPv6Addresses": [
    #    {
    #      "Address": "fe80::xxxx:xxxx:xxxx:xxxx",
    #      "AddressOrigin": "LinkLocal",
    #      "AddressState": null,
    #      "PrefixLength": xx
    #    }
    #  ],
    #    {
    #      "Address": "2002:xxxx:xxxx:xxxx:xxxx",
    #      "AddressOrigin": "SLAAC",
    #      "PrefixLength": 64
    #    }
    #  ],

    ${split_ip_address}=  Split String  ${ipv6_address}  :
    ${missing_ip}=  Evaluate  8 - len(${split_ip_address}) + 1
    ${expanded_ip}=  Create List

    FOR  ${hextet}  IN  @{split_ip_address}
       IF  '${hextet}' == ''
           FOR  ${i}  IN RANGE  ${missing_ip}
               Append To List  ${expanded_ip}  0000
           END
       ELSE
           Append To List  ${expanded_ip}  ${hextet}
       END
    END
    ${interface_id}=  Evaluate  ':'.join(${expanded_ip}[-4:])
    RETURN  ${interface_id}


Set And Verify SLAAC Property On Both Interfaces
    [Documentation]  Set and verify SLAAC property on both interfaces.
    [Arguments]  ${slaac_value_1}  ${slaac_value_2}

    # Description of the argument(s):
    # slaac_value_1  SLAAC value for channel 1.
    # slaac_value_2  SLAAC value for channel 2.

    Set SLAAC Configuration State And Verify  ${slaac_value_1}  [${HTTP_OK}]  ${1}
    Set SLAAC Configuration State And Verify  ${slaac_value_2}  [${HTTP_OK}]  ${2}

    Sleep  30s

    # Check SLAAC Settings for eth0.
    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=
    ...  Get Address Origin List And IPv4 or IPv6 Address  IPv6Addresses  ${1}
    IF  "${slaac_value_1}" == "${True}"
         Should Not Be Empty  ${ipv6_slaac_addr}  SLAAC
    ELSE
        Should Not Contain  ${ipv6_addressorigin_list}  SLAAC
    END

    # Check SLAAC Settings for eth1.
    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=
    ...  Get Address Origin List And IPv4 or IPv6 Address  IPv6Addresses  ${2}
    IF  "${slaac_value_2}" == "${True}"
         Should Not Be Empty  ${ipv6_slaac_addr}  SLAAC
    ELSE
        Should Not Contain  ${ipv6_addressorigin_list}  SLAAC
    END

    Verify All The Addresses Are Intact  ${1}
    Verify All The Addresses Are Intact  ${2}
    ...    ${eth1_initial_ipv4_addressorigin_list}  ${eth1_initial_ipv4_addr_list}


Set And Verify DHCPv6 Property On Both Interfaces
    [Documentation]  Set and verify DHCPv6 property on both interfaces.
    [Arguments]  ${dhcpv6_value_1}  ${dhcpv6_value_2}

    # Description of the argument(s):
    # dhcpv6_value_1  DHCPv6 value for channel 1.
    # dhcpv6_value_2  DHCPv6 value for channel 2.

    Set And Verify DHCPv6 Property  ${dhcpv6_value_1}  ${1}
    Set And Verify DHCPv6 Property  ${dhcpv6_value_2}  ${2}

    Verify All The Addresses Are Intact  ${1}
    Verify All The Addresses Are Intact  ${2}
    ...    ${eth1_initial_ipv4_addressorigin_list}  ${eth1_initial_ipv4_addr_list}


Verify IPv6 Addresses Coexist
    [Documentation]  Verify IPv6 address type coexist.
    [Arguments]   ${ipv6_address_type1}  ${ipv6_address_type2}

    # Description of the argument(s):
    # ipv6_address_type1  IPv6 address type.
    # ipv6_address_type2  IPv6 address type.
    # Valid IPv6 address type (Static, DHCPv6, SLAAC).

    IF  '${ipv6_address_type1}' == 'Static' and '${ipv6_address_type2}' == 'DHCPv6'
        Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}
        Set And Verify DHCPv6 Property  Enabled
    ELSE IF  '${ipv6_address_type1}' == 'DHCPv6' and '${ipv6_address_type2}' == 'SLAAC'
        Set And Verify DHCPv6 Property  Enabled
        Set SLAAC Configuration State And Verify  ${True}
    ELSE IF  '${ipv6_address_type1}' == 'SLAAC' and '${ipv6_address_type2}' == 'Static'
        Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}
        Set SLAAC Configuration State And Verify  ${True}
    ELSE IF  '${ipv6_address_type1}' == 'Static' and '${ipv6_address_type2}' == 'Static'
        Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}
        Configure IPv6 Address On BMC  ${test_ipv6_addr1}  ${test_prefix_length}
    END

    Sleep  ${NETWORK_TIMEOUT}s

    # Verify coexistence.
    Verify The Coexistence Of The Address Type  ${ipv6_address_type1}  ${ipv6_address_type2}

    IF  '${ipv6_address_type1}' == 'Static' or '${ipv6_address_type2}' == 'Static'
        Delete IPv6 Address  ${test_ipv6_addr}
    END
    IF  '${ipv6_address_type1}' == 'Static' and '${ipv6_address_type2}' == 'Static'
        Delete IPv6 Address  ${test_ipv6_addr1}
    END

    Set And Verify DHCPv6 Property  Disabled
    Set SLAAC Configuration State And Verify  ${False}


Verify DHCPv4 Functionality On Eth1
    [Documentation]  Verify DHCPv4 functions are present as expected on eth1.

    # Verify eth1 DHCPv4 is enabled.
    ${DHCPEnabled}=  Get IPv4 DHCP Enabled Status  ${2}
    Should Be Equal  ${DHCPEnabled}  ${True}

    # Verify presence of DHCPv4 address origin.
    @{ipv4_addressorigin_list}  ${ipv4_addr_list}=
    ...  Get Address Origin List And IPv4 or IPv6 Address  IPv4Addresses  ${2}
    ${ipv4_addressorigin_list}=  Combine Lists  @{ipv4_addressorigin_list}
    Should Contain  ${ipv4_addressorigin_list}  DHCP

    # Verify static is not present in address origin when DHPCv4 enabled.
    List Should Not Contain Value  ${ipv4_addressorigin_list}  Static


Add Static IPv4 Address On Both Eth0 And Eth1
    [Documentation]  Add static IPv4 address on both eth0 and eth1 interface.

    Add IP Address  ${test_ipv4_addr}  ${test_subnet_mask}  ${test_gateway}
    Set Test Variable  ${CHANNEL_NUMBER}  ${SECONDARY_CHANNEL_NUMBER}
    Add IP Address  ${test_ipv4_addr1}  ${test_subnet_mask}  ${test_gateway}


Configure Static IPv6 And Verify IP Reachability
    [Documentation]  Configure static IPv6 address on eth0/eth1 and verify IPs
    ...  are reachable.
    [Arguments]  ${channel_number}

    # Description of argument(s):
    # channel_number     Ethernet channel number, 1(eth0) or 2(eth1).

    IF  '${channel_number}' == '${1}'
        Configure IPv6 Address On BMC  ${test_ipv6_addr}  ${test_prefix_length}  ${None}  ${channel_number}
        @{ipv6_addressorigin_list}  ${ipv6_addr}=
        ...  Get Address Origin List And Address For Type  Static  ${channel_number}
        Wait For IPv6 Host To Ping  ${ipv6_addr}
    ELSE
        Configure IPv6 Address On BMC  ${test_ipv6_addr1}  ${test_prefix_length}  ${None}  ${channel_number}
        @{ipv6_addressorigin_list}  ${ipv6_addr}=
        ...  Get Address Origin List And Address For Type  Static  ${channel_number}
        Wait For IPv6 Host To Ping  ${ipv6_addr}
    END
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}