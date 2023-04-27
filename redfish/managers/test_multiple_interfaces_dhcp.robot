*** Settings ***
Documentation   Test BMC DHCP multiple network interface functionalities.

Resource        ../../lib/resource.robot
Resource        ../../lib/common_utils.robot
Resource        ../../lib/connection_client.robot
Resource        ../../lib/bmc_network_utils.robot
Resource        ../../lib/openbmc_ffdc.robot

Suite Setup     Suite Setup Execution
Test Teardown   FFDC On Test Case Fail
Suite Teardown  Redfish.Logout

*** Variables ***

&{DHCP_ENABLED}           DHCPEnabled=${True}
&{DHCP_DISABLED}          DHCPEnabled=${False}
&{ENABLE_DHCP}            DHCPv4=${DHCP_ENABLED}
&{DISABLE_DHCP}           DHCPv4=${DHCP_DISABLED}
${ethernet_interface}     eth1

*** Test Cases ***

Disable DHCP On Eth1 And Verify System Is Accessible By Eth0
    [Documentation]  Disable DHCP on eth1 using Redfish and verify
    ...              if system is accessible by eth0.
    [Tags]  Disable_DHCP_On_Eth1_And_Verify_System_Is_Accessible_By_Eth0
    [Teardown]  Set DHCPEnabled To Enable Or Disable  True  eth1

    Set DHCPEnabled To Enable Or Disable  False  eth1
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

Enable DHCP On Eth1 And Verify System Is Accessible By Eth0
    [Documentation]  Enable DHCP on eth1 using Redfish and verify if system
    ...              is accessible by eth0.
    [Tags]  Enable_DHCP_On_Eth1_And_Verify_System_Is_Accessible_By_Eth0
    [Setup]  Set DHCPEnabled To Enable Or Disable  False  eth1

    Set DHCPEnabled To Enable Or Disable  True  eth1
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}

*** Keywords ***

Set DHCPEnabled To Enable Or Disable
    [Documentation]  Enable or Disable DHCP on the interface.
    [Arguments]  ${dhcp_enabled}=${False}  ${interface}=${ethernet_interface}
    ...          ${valid_status_code}=[${HTTP_OK},${HTTP_ACCEPTED}]

    # Description of argument(s):
    # dhcp_enabled        False for disabling DHCP and True for Enabling DHCP.
    # interface           eth0 or eth1. Default is eth1.
    # valid_status_code   Expected valid status code from Patch request.
    #                     Default is HTTP_OK.

    ${data}=  Set Variable If  ${dhcp_enabled} == ${False}  ${DISABLE_DHCP}  ${ENABLE_DHCP}
    ${resp}=  Redfish.Patch
    ...  /redfish/v1/Managers/${MANAGER_ID}/EthernetInterfaces/${interface}
    ...  body=${data}  valid_status_codes=${valid_status_code}

Suite Setup Execution
    [Documentation]  Do suite setup task.

    Ping Host  ${OPENBMC_HOST}
    Redfish.Login
