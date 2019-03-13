*** Settings ***
Documentation  Network interface configuration and verification
               ...  tests.

Resource       ../../lib/bmc_redfish_resource.robot
Resource       ../../lib/bmc_network_utils.robot
Resource       ../../lib/openbmc_ffdc.robot
Library        ../../lib/bmc_network_utils.py

Test Setup     Test Setup Execution
Test Teardown  Test Teardown Execution

*** Variables ***
${test_hostname}  bmcbmc

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

    Should Contain  ${sys_hostname}  ${hostname}
    ...  ignore_case=True  msg=Hostname does not exist.

Test Teardown Execution
    [Documentation]  Test teardown execution.

    FFDC On Test Case Fail
    Redfish.Logout
