*** Settings ***
Documentation  Network interface configuration and verification
               ...  tests.

Resource  ../../lib/bmc_redfish_resource.robot
Resource  ../../lib/bmc_network_utils.robot

Library  String
Library  SSHLibrary

Test Setup  Test Setup Execution

*** Test Cases ***

Get IP Address And Verify
    [Documentation]  Get IP Address And Verify.
    [Tags]           Get_IP_Address_And_Verify 

    : FOR  ${network_configuration}  IN  @{network_configurations}
    \  Validate IP On BMC  ${network_configuration['Address']}
    
Get Netmask And Verify
    [Documentation]  Get Netmask And Verify.
    [Tags]           Get_Netmask_And_Verify

    : FOR  ${network_configuration}  IN  @{network_configurations}
    \  Validate Netmask On BMC  ${network_configuration['SubnetMask']}

*** Keywords ***

Test Setup Execution
    [Documentation]  Test setup execution.

    redfish.Login

    @{network_configurations}=  Get Network Configuration Via Redfish
    Set Test Variable  @{network_configurations}

    # Get BMC IP address and prefix length.
    ${ip_data}=  Get BMC IP Info
    Set Test Variable  ${ip_data}

Get Network Configuration Via Redfish
    [Documentation]  Get network configuration via Redfish.

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

    ${resp}=  redfish.Get  ${REDFISH_ETH_URI}
    @{network_configurations}=  Get From Dictionary  ${resp.dict}  IPv4Addresses
    [Return]  @{network_configurations}

Validate IP On BMC
    [Arguments]  ${ip}

    # Description of the argument(s):
    # ip  IP address to be verified.

    # Get IP address details on BMC using IP command.
    @{ip_data}=  Get BMC IP Info
    Should Contain Match  ${ip_data}  ${ip}/*
    ...  msg=IP address does not exist.

Validate Netmask On BMC
    [Arguments]  ${netmask}

    # Description of the argument(s):
    # netmask  netmask value to be verified.

    # TBD

