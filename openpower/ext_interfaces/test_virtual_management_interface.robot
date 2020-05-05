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

Redfish VMI Network Interface
    [Documentation]  Verify VMI network interface exists.
    [Tags]  Redfish_VMI_Network_Interface

    Verify Network Interface

*** Keywords ***

Verify Network Interface
    [Documentation]  Verify the network interface list.

    ${network_interface}=  Redfish.Get Attribute  /redfish/v1/Systems/hypervisor  EthernetInterfaces
    Should Be Equal As Strings  ${REDFISH_EXTERNAL_ETHERNET_INTERFACE}  ${network_interface}[@odata.id]
    Print Timen  ${network_interface}[@odata.id]
