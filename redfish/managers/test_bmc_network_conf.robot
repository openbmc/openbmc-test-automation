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
${test_hostname}  openbmc
${test_ipv4_addr}  10.7.7.7
${test_ipv4_invalid_addr}  0.0.1.a
${test_subnet_mask}  255.255.0.0
${test_gateway}  10.7.7.1

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

Add Valid IPv4Address And Verify
    [Documentation]  Add IPv4Address via Redfish and verify.
    [Tags]  Add_IPv4Addres_And_Verify

     Add IPv4Address  ${test_ipv4_addr}  ${test_subnet_mask}  ${test_gateway}
     Delete IPv4Address  ${test_ipv4_addr}

Add Invalid IPv4Address And Verify
    [Documentation]  Add IPv4Address via Redfish and verify.
    [Tags]  Add_IPv4Addres_And_Verify

    Add IPv4Address  ${test_ipv4_invalid_addr}  ${test_subnet_mask}
    ...  ${test_gateway}  expected_status=${HTTP_BAD_REQUEST}


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

    # Description of the argument(s):
    # ip  IP address to be verified.

    # Get IP address details on BMC using IP command.
    @{ip_data}=  Get BMC IP Info
    Should Contain Match  ${ip_data}  ${ip}/*
    ...  msg=IP address does not exist.

Add IPv4Address
    [Documentation]  Add IPv4Address To BMC.
    [Arguments]  ${ip}  ${subnet_mask}  ${gateway}
    ...  ${expected_status}=${HTTP_OK}

    # Description of the argument(s):
    # ip  IP address to be added.
    # subnet_mask  Subnet mask for the IP to be added
    # gateway  Gateway for the IP to be added
    # expected_status  Expected return code from patch operation

    Should Not Be Empty  ${ip}
    Should Not Be Empty  ${subnet_mask}

    ${empty_dict}=  Create Dictionary
    ${ip_data}=  Create Dictionary  Address=${ip}
    ...  AddressOrigin=Static  SubnetMask=${subnet_mask}
    ...  Gateway=${gateway}

    ${patch_list}=  Create List

    : FOR  ${network_configuration}  IN  @{network_configurations}
    \  Run Keyword If  '${network_configuration['Address']}' == '${ip}'
       ...  Append To List  ${patch_list}  ${ip_data}
       ...  ELSE  Append To List  ${patch_list}  ${empty_dict}

    ${check_ip}=  Run Keyword And Return Status
    ...  List Should Contain Value  ${patch_list}  ${ip_data}
    Run Keyword if  '${check_ip}' == 'False'
    ...  Append To List  ${patch_list}  ${ip_data}

    ${patch_status}=  Run Keyword And Return Status  Patch An Element  IPv4Addresses
    ...  ${patch_list}  ${REDFISH_NW_ETH0_URI}  ${expected_status}

    # Note: Network restart takes around 15-18s after patch request processing
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}
    ${status}=  Run Keyword And Return Status  Verify IP On BMC  ${ip}

    Run Keyword If  '${expected_status}' == '${HTTP_OK}'
    ...  Should Be True  '${status}' == 'True'
    ...  ELSE  Should Be True  '${status}' == 'False'

    Should Be True  '${patch_status}' == 'True'
    Validate Network Config On BMC

Delete IPv4Address
    [Documentation]  Delete IPv4Address Of BMC.
    [Arguments]  ${ip}  ${expected_status}=${HTTP_OK}

    # Description of the argument(s):
    # ip  IP address to be deleted.
    # expected_status  Expected return code from patch operation

    ${empty_dict}=  Create Dictionary
    ${patch_list}=  Create List

    @{network_configurations}=  Get Network Configuration
    : FOR  ${network_configuration}  IN  @{network_configurations}
    \  Run Keyword If  '${network_configuration['Address']}' == '${ip}'
       ...  Append To List  ${patch_list}  ${null}
       ...  ELSE  Append To List  ${patch_list}  ${empty_dict}

    ${ip_found}=  Run Keyword And Return Status  List Should Contain Value
    ...  ${patch_list}  ${null}
    Pass Execution If  '${ip_found}' == 'False'  Given IP not found on BMC

    # Run patch command only if given IP is found on BMC
    ${patch_status}=  Run Keyword And Return Status
    ...  Patch An Element  IPv4Addresses  ${patch_list}  ${REDFISH_NW_ETH0_URI}
    ...  ${expected_status}

    # Note: Network restart takes around 15-18s after patch request processing
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}
    ${status}=  Run Keyword And Return Status  Verify IP On BMC  ${ip}

    Run Keyword If  '${expected_status}' == '${HTTP_OK}'
    ...  Should Be True  '${status}' == 'False'
    ...  ELSE  Should Be True  '${status}' == 'True'

    Should Be True  '${patch_status}' == 'True'
    Validate Network Config On BMC

Patch An Element
    [Documentation]  Patch Operation on some element Of BMC.
    [Arguments]  ${patch_elem}  ${patch_list}  ${patch_uri}
    ...  ${expected_status}=${HTTP_OK}

    # Description of the argument(s):
    # patch_elem  Element name for which patch request has come
    # patch_list  List of items to be patched for patch_elem
    # patch_uri   URI for patch operation
    # expected_status  Expected return code from patch operation

    ${data}=  Create Dictionary  ${patch_elem}=${patch_list}
    Redfish.patch  ${patch_uri}  body=&{data}
    ...  valid_status_codes=[${expected_status}]

Validate Network Config On BMC
    [Documentation]  Network config from CLI and Redfish should match

    @{network_configurations}=  Get Network Configuration
    : FOR  ${network_configuration}  IN  @{network_configurations}
    \  Verify IP On BMC  ${network_configuration['Address']}

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
