*** Settings ***

Documentation     VMI (Virtual Management Interface) network and certificate test case.

Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_resource.robot
Resource          ../../lib/openbmc_ffdc.robot
Variables         ../../data/variables.py

Suite Setup       Redfish.Login
Test Teardown     FFDC On Test Case Fail
Suite Teardown    Redfish.Logout

*** Test Cases ***

Redfish VMI Network Interface Exists
    [Documentation]  Verify VMI network interface exists.
    [Tags]  Redfish_VMI_Network_Interface_Exists
    [Template]  Redfish Network Interface Verification

    # Network interface
    Hypervisor
    Ethernet

*** Keywords ***

Redfish Network Interface Verification
    [Documentation]  Verify the network interfaces.
    [Arguments]  ${network_interface}

    Run Keyword If  'Hypervisor' == '${network_interface}'
    ...    Redfish.Get  /redfish/v1/Systems/hypervisor/EthernetInterfaces
    ...  ELSE IF  'Ethernet' == '${network_interface}'
    ...    Run Keywords  Redfish.Get  /redfish/v1/Systems/hypervisor/EthernetInterfaces/intf0  AND
    ...    Redfish.Get  /redfish/v1/Systems/hypervisor/EthernetInterfaces/intf1
