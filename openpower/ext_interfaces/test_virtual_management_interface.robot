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

    Redfish Network Interface Check

*** Keywords ***

Redfish Network Interface Check
    [Documentation]  Verify the network interface list.

    ${resp}=  Redfish.Get  /redfish/v1/Systems/hypervisor/EthernetInterfaces
