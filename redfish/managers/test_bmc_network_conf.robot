*** Settings ***
Documentation  Network interface configuration and verification
               ...  tests.

Resource       ../../lib/bmc_redfish_resource.robot
Resource       ../../lib/bmc_network_utils.robot
Resource       ../../lib/openbmc_ffdc.robot
Library        ../../lib/bmc_network_utils.py
Library        Collections

Test Setup     Test Setup Execution
Test Teardown  Test Teardown Execution

*** Variables ***
${test_hostname}           openbmc
${test_ipv4_addr}          10.7.7.7
${test_ipv4_invalid_addr}  0.0.1.a
${test_subnet_mask}        255.255.0.0
${test_gateway}            10.7.7.1
${broadcast_ip}            10.7.7.255
${loopback_ip}             127.0.0.2
${multicast_ip}            224.6.6.6
${out_of_range_ip}         10.7.7.256

*** Test Cases ***

Get IP Address And Verify
    [Documentation]  Get IP Address And Verify.
    [Tags]  Get_IP_Address_And_Verify

    : FOR  ${network_configuration}  IN  @{network_configurations}
    \  Verify IP On BMC  ${network_configuration['Address']}

Get Netmask And Verify
    [Documentation]  Get Netmask And Verify.
    [Tags]  Get_Netmask_And_Verify

    : FOR  ${network_configuration}  IN  @{network_configurations}
    \  Verify Netmask On BMC  ${network_configuration['SubnetMask']}

Get Gateway And Verify
    [Documentation]  Get gateway and verify it's existence on the BMC.
    [Tags]  Get_Gateway_And_Verify

    : FOR  ${network_configuration}  IN  @{network_configurations}
    \  Verify Gateway On BMC  ${network_configuration['Gateway']}

Get MAC Address And Verify
    [Documentation]  Get MAC address and verify it's existence on the BMC.
    [Tags]  Get_MAC_Address_And_Verify

    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH0_URI}
    ${macaddr}=  Get From Dictionary  ${resp.dict}  MACAddress
    Validate MAC On BMC  ${macaddr}

Verify All Configured IP And Netmask
    [Documentation]  Verify all configured IP and netmask on BMC.
    [Tags]  Verify_All_Configured_IP_And_Netmask

    : FOR  ${network_configuration}  IN  @{network_configurations}
    \  Verify IP And Netmask On BMC  ${network_configuration['Address']}
    ...  ${network_configuration['SubnetMask']}

Get Hostname And Verify
    [Documentation]  Get hostname via Redfish and verify.
    [Tags]  Get_Hostname_And_Verify

    ${hostname}=  Redfish_Utils.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  HostName

    Validate Hostname On BMC  ${hostname}

Configure Hostname And Verify
    [Documentation]  Configure hostname via Redfish and verify.
    [Tags]  Configure_Hostname_And_Verify

    Configure Hostname  ${test_hostname}

    Validate Hostname On BMC  ${test_hostname}

Add Valid IPv4 Address And Verify
    [Documentation]  Add IPv4 Address via Redfish and verify.
    [Tags]  Add_Valid_IPv4_Addres_And_Verify

     Add IP Address  ${test_ipv4_addr}  ${test_subnet_mask}  ${test_gateway}
     Delete IP Address  ${test_ipv4_addr}

Add Invalid IPv4 Address And Verify
    [Documentation]  Add Invalid IPv4 Address via Redfish and verify.
    [Tags]  Add_Invalid_IPv4_Addres_And_Verify

    Add IP Address  ${test_ipv4_invalid_addr}  ${test_subnet_mask}
    ...  ${test_gateway}  valid_status_codes=${HTTP_BAD_REQUEST}

Configure Out Of Range IP
    [Documentation]  Configure out-of-range IP address.
    [Tags]  Configure_Out_Of_Range_IP
    [Template]  Add IP Address

    # ip                subnet_mask          gateway          valid_status_codes
    ${out_of_range_ip}  ${test_subnet_mask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Broadcast IP
    [Documentation]  Configure broadcast IP address.
    [Tags]  Configure_Broadcast_IP
    [Template]  Add IP Address

    # ip             subnet_mask          gateway          valid_status_codes
    ${broadcast_ip}  ${test_subnet_mask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Multicast IP
    [Documentation]  Configure multicast IP address.
    [Tags]  Configure_Multicast_IP
    [Template]  Add IP Address

    # ip             subnet_mask          gateway          valid_status_codes
    ${multicast_ip}  ${test_subnet_mask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Configure Loopback IP
    [Documentation]  Configure loopback IP address.
    [Tags]  Configure_Loopback_IP
    [Template]  Add IP Address

    # ip            subnet_mask          gateway          valid_status_codes
    ${loopback_ip}  ${test_subnet_mask}  ${test_gateway}  ${HTTP_BAD_REQUEST}

Add Valid IPv4 Address And Check Persistency
    [Documentation]  Add IPv4 address and check peristency.
    [Tags]  Add_Valid_IPv4_Addres_And_Check_Persistency

    Add IP Address  ${test_ipv4_addr}  ${test_subnet_mask}  ${test_gateway}

    # Reboot BMC and verify persistency.
    OBMC Reboot (off)
    Verify IP On BMC  ${test_ipv4_addr}
    Delete IP Address  ${test_ipv4_addr}

Add Fourth Octet Threshold IP And Verify
    [Documentation]  Add fourth octet threshold IP and verify.
    [Tags]  Add_Fourth_Octet_Threshold_IP_And_Verify

     Add IP Address  10.7.7.254  ${test_subnet_mask}  ${test_gateway}
     Delete IP Address  10.7.7.254

Add Fourth Octet Lowest IP And Verify
    [Documentation]  Add fourth octet lowest IP and verify.
    [Tags]  Add_Fourth_Octet_Lowest_IP_And_Verify

     Add IP Address  10.7.7.1  ${test_subnet_mask}  ${test_gateway}
     Delete IP Address  10.7.7.1

Add Third Octet Threshold IP And Verify
    [Documentation]  Add third octet threshold IP and verify.
    [Tags]  Add_Third_Octet_Threshold_IP_And_Verify

     Add IP Address  10.7.255.7  ${test_subnet_mask}  ${test_gateway}
     Delete IP Address  10.7.255.7

Add Third Octet Lowest IP And Verify
    [Documentation]  Add third octet lowest IP and verify.
    [Tags]  Add_Third_Octet_Lowest_IP_And_Verify

     Add IP Address  10.7.0.7  ${test_subnet_mask}  ${test_gateway}
     Delete IP Address  10.7.0.7

Add Second Octet Threshold IP And Verify
    [Documentation]  Add second octet threshold IP and verify.
    [Tags]  Add_Second_Octet_Threshold_IP_And_Verify

     Add IP Address  10.255.7.7  ${test_subnet_mask}  ${test_gateway}
     Delete IP Address  10.255.7.7

Add Second Octet Lowest IP And Verify
    [Documentation]  Add second octet lowest IP and verify.
    [Tags]  Add_Second_Octet_Lowest_IP_And_Verify

     Add IP Address  10.0.7.7  ${test_subnet_mask}  ${test_gateway}
     Delete IP Address  10.0.7.7

Add First Octet Threshold IP And Verify
    [Documentation]  Add first octet threshold IP and verify.
    [Tags]  Add_First_Octet_Threshold_IP_And_Verify

     Add IP Address  223.7.7.7  ${test_subnet_mask}  ${test_gateway}
     Delete IP Address  223.7.7.7

Add First Octet Lowest IP And Verify
    [Documentation]  Add first octet lowest IP and verify.
    [Tags]  Add_First_Octet_Lowest_IP_And_Verify

     Add IP Address  1.7.7.7  ${test_subnet_mask}  ${test_gateway}
     Delete IP Address  1.7.7.7

*** Keywords ***

Test Setup Execution
    [Documentation]  Test setup execution.

    Redfish.Login

    @{network_configurations}=  Get Network Configuration
    Set Test Variable  @{network_configurations}

    # Get BMC IP address and prefix length.
    ${ip_data}=  Get BMC IP Info
    Set Test Variable  ${ip_data}


Get Network Configuration
    [Documentation]  Get network configuration.

    # Sample output:
    #{
    #  "@odata.context": "/redfish/v1/$metadata#EthernetInterface.EthernetInterface",
    #  "@odata.id": "/redfish/v1/Managers/bmc/EthernetInterfaces/eth0",
    #  "@odata.type": "#EthernetInterface.v1_2_0.EthernetInterface",
    #  "Description": "Management Network Interface",
    #  "IPv4Addresses": [
    #    {
    #      "Address": "169.254.xx.xx",
    #      "AddressOrigin": "IPv4LinkLocal",
    #      "Gateway": "0.0.0.0",
    #      "SubnetMask": "255.255.0.0"
    #    },
    #    {
    #      "Address": "xx.xx.xx.xx",
    #      "AddressOrigin": "Static",
    #      "Gateway": "xx.xx.xx.1",
    #      "SubnetMask": "xx.xx.xx.xx"
    #    }
    #  ],
    #  "Id": "eth0",
    #  "MACAddress": "xx:xx:xx:xx:xx:xx",
    #  "Name": "Manager Ethernet Interface",
    #  "SpeedMbps": 0,
    #  "VLAN": {
    #    "VLANEnable": false,
    #    "VLANId": 0
    #  }

    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH0_URI}
    @{network_configurations}=  Get From Dictionary  ${resp.dict}  IPv4Addresses
    [Return]  @{network_configurations}


Verify IP On BMC
    [Documentation]  Verify IP on BMC.
    [Arguments]  ${ip}

    # Description of argument(s):
    # ip  IP address to be verified (e.g. "10.7.7.7").

    # Get IP address details on BMC using IP command.
    @{ip_data}=  Get BMC IP Info
    Should Contain Match  ${ip_data}  ${ip}/*
    ...  msg=IP address does not exist.

Add IP Address
    [Documentation]  Add IP Address To BMC.
    [Arguments]  ${ip}  ${subnet_mask}  ${gateway}
    ...  ${valid_status_codes}=${HTTP_OK}

    # Description of argument(s):
    # ip                  IP address to be added (e.g. "10.7.7.7").
    # subnet_mask         Subnet mask for the IP to be added
    #                     (e.g. "255.255.0.0").
    # gateway             Gateway for the IP to be added (e.g. "10.7.7.1").
    # valid_status_codes  Expected return code from patch operation
    #                     (e.g. "200").  See prolog of rest_request
    #                     method in redfish_plut.py for details.

    ${empty_dict}=  Create Dictionary
    ${ip_data}=  Create Dictionary  Address=${ip}
    ...  AddressOrigin=Static  SubnetMask=${subnet_mask}
    ...  Gateway=${gateway}

    ${patch_list}=  Create List
    ${network_configurations}=  Get Network Configuration
    ${num_entries}=  Get Length  ${network_configurations}

    : FOR  ${INDEX}  IN RANGE  0  ${num_entries}
    \  Append To List  ${patch_list}  ${empty_dict}

    # We need not check for existence of IP on BMC while adding.
    Append To List  ${patch_list}  ${ip_data}
    ${data}=  Create Dictionary  IPv4Addresses=${patch_list}

    Redfish.patch  ${REDFISH_NW_ETH0_URI}  body=&{data}
    ...  valid_status_codes=[${valid_status_codes}]

    Return From Keyword If  '${valid_status_codes}' != '${HTTP_OK}'

    # Note: Network restart takes around 15-18s after patch request processing.
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

    Verify IP On BMC  ${ip}
    Validate Network Config On BMC


Delete IP Address
    [Documentation]  Delete IP Address Of BMC.
    [Arguments]  ${ip}  ${valid_status_codes}=${HTTP_OK}

    # Description of argument(s):
    # ip                  IP address to be deleted (e.g. "10.7.7.7").
    # valid_status_codes  Expected return code from patch operation
    #                     (e.g. "200").  See prolog of rest_request
    #                     method in redfish_plut.py for details.

    ${empty_dict}=  Create Dictionary
    ${patch_list}=  Create List

    @{network_configurations}=  Get Network Configuration
    : FOR  ${network_configuration}  IN  @{network_configurations}
    \  Run Keyword If  '${network_configuration['Address']}' == '${ip}'
       ...  Append To List  ${patch_list}  ${null}
       ...  ELSE  Append To List  ${patch_list}  ${empty_dict}

    ${ip_found}=  Run Keyword And Return Status  List Should Contain Value
    ...  ${patch_list}  ${null}  msg=${ip} does not exist on BMC
    Pass Execution If  ${ip_found} == ${False}  ${ip} does not exist on BMC

    # Run patch command only if given IP is found on BMC
    ${data}=  Create Dictionary  IPv4Addresses=${patch_list}

    Redfish.patch  ${REDFISH_NW_ETH0_URI}  body=&{data}
    ...  valid_status_codes=[${valid_status_codes}]

    # Note: Network restart takes around 15-18s after patch request processing
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

    ${delete_status}=  Run Keyword And Return Status  Verify IP On BMC  ${ip}
    Run Keyword If  '${valid_status_codes}' == '${HTTP_OK}'
    ...  Should Be True  ${delete_status} == ${False}
    ...  ELSE  Should Be True  ${delete_status} == ${True}

    Validate Network Config On BMC


Validate Network Config On BMC
    [Documentation]  Check that network info obtained via redfish matches info
    ...              obtained via CLI.

    @{network_configurations}=  Get Network Configuration
    ${ip_data}=  Get BMC IP Info
    : FOR  ${network_configuration}  IN  @{network_configurations}
    \  Should Contain Match  ${ip_data}  ${network_configuration['Address']}/*
    ...  msg=IP address does not exist.


Verify Netmask On BMC
    [Documentation]  Verify netmask on BMC.
    [Arguments]  ${netmask}

    # Description of the argument(s):
    # netmask  netmask value to be verified.

    ${prefix_length}=  Netmask Prefix Length  ${netmask}

    Should Contain Match  ${ip_data}  */${prefix_length}
    ...  msg=Prefix length does not exist.

Verify Gateway On BMC
    [Documentation]  Verify gateway on BMC.
    [Arguments]  ${gateway_ip}=0.0.0.0

    # Description of argument(s):
    # gateway_ip  Gateway IP address.

    ${route_info}=  Get BMC Route Info

    # If gateway IP is empty or 0.0.0.0 it will not have route entry.

    Run Keyword If  '${gateway_ip}' == '0.0.0.0'
    ...      Pass Execution  Gateway IP is "0.0.0.0".
    ...  ELSE
    ...      Should Contain  ${route_info}  ${gateway_ip}
    ...      msg=Gateway IP address not matching.

Verify IP And Netmask On BMC
    [Documentation]  Verify IP and netmask on BMC.
    [Arguments]  ${ip}  ${netmask}

    # Description of the argument(s):
    # ip       IP address to be verified.
    # netmask  netmask value to be verified.

    ${prefix_length}=  Netmask Prefix Length  ${netmask}
    @{ip_data}=  Get BMC IP Info

    ${ip_with_netmask}=  Catenate  ${ip}/${prefix_length}
    Should Contain  ${ip_data}  ${ip_with_netmask}
    ...  msg=IP and netmask pair does not exist.

Configure Hostname
    [Documentation]  Configure hostname on BMC via Redfish.
    [Arguments]  ${hostname}

    # Description of argument(s):
    # hostname  A hostname value which is to be configured on BMC.

    ${data}=  Create Dictionary  HostName=${hostname}
    Redfish.patch  ${REDFISH_NW_PROTOCOL_URI}  body=&{data}

Validate Hostname On BMC
    [Documentation]  Verify that the hostname read via Redfish is the same as the
    ...  hostname configured on system.
    [Arguments]  ${hostname}

    # Description of argument(s):
    # hostname  A hostname value which is to be compared to the hostname
    #           configured on system.

    ${sys_hostname}=  Get BMC Hostname
    Should Be Equal  ${sys_hostname}  ${hostname}
    ...  ignore_case=True  msg=Hostname does not exist.

Test Teardown Execution
    [Documentation]  Test teardown execution.

    FFDC On Test Case Fail
    Redfish.Logout
