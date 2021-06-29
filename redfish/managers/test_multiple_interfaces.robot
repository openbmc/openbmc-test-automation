*** Settings ***
Documentation   Test BMC multiple network interface functionalities.

Library         ../../lib/bmc_redfish.py  https://${OPENBMC_HOST_1}:${HTTPS_PORT}
...             ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  WITH NAME  Redfish1

Resource        ../../lib/resource.robot
Resource        ../../lib/common_utils.robot
Resource        ../../lib/connection_client.robot
Resource        ../../lib/bmc_network_utils.robot
Resource        ../../lib/openbmc_ffdc.robot

Suite Setup     Suite Setup Execution
Test Teardown   FFDC On Test Case Fail
Suite Teardown  Redfish.Logout

*** Variables ***



*** Test Cases ***

Verify Both Interfaces BMC IP Addresses Are Pingable
    [Documentation]  Verify both interfaces BMC IP addresses able to ping.
    [Tags]  Verify_Both_Interfaces_BMC_IP_Addrresses_Are_Pingable

    Ping Host  ${OPENBMC_HOST}
    Ping Host  ${OPENBMC_HOST_1}


Verify Both Interfaces BMC IP Addreeses Accessible Via SSH
    [Documentation]  Verify able to SSH both interfaces.
    [Tags]  Verify_Both_Interfaces_BMC_IP_Addresses_Accessible_Via_SSH

    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  host=${OPENBMC_HOST}
    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  host=${OPENBMC_HOST_1}
    Close All Connections


*** Keywords ***

Get Network Configuration Using Channel Number
    [Documentation]  Get ethernet intreface.
    [Arguments]  ${channel_number}

    # Description of argument(s):
    # channel_number  The user's channel number (e.g. "1").

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${channel_number}']['name']}
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}

    @{network_configurations}=  Get From Dictionary  ${resp.dict}  IPv4StaticAddresses
    [Return]  @{network_configurations}


Suite Setup Execution
    [Documentation]  Do suite setup task.

    Valid Value  OPENBMC_HOST_1

    Redfish.Login

    ${status}=  Run Keyword And Return Status  Redfish.Get  ${REDFISH_NW_ETH_IFACE}eth0
    Should Be Equal  ${status}  ${True}  msg=BMC not configured with eth0 interface.

    ${status}=  Run Keyword And Return Status  Redfish.Get  ${REDFISH_NW_ETH_IFACE}eth1
    Should Be Equal  ${status}  ${True}  msg=BMC not configured with eth1 interface.

    ${status}=  Run Keyword And Return Status  Ping Host  ${OPENBMC_HOST_1}
    Should Be Equal  ${status}  ${True}  msg=Unable to ping eth1 BMC IP address.

    @{network_configurations}=  Get Network Configuration Using Channel Number  1
    FOR  ${network_configuration}  IN  @{network_configurations}
      Run Keyword If  '${network_configuration['Address']}' =='${OPENBMC_HOST}'
      ...  Run Keywords  Set Suite Variable  ${eth0_ipaddress}  ${network_configuration['Address']}
      ...  AND  Set Suite Variable  ${eth0_subnet_mask}  ${network_configuration['SubnetMask']}
      ...  AND  Set Suite Variable  ${eth0_gateway}  ${network_configuration['Gateway']}
      ...  AND  Exit For Loop
    END

    @{network_configurations}=  Get Network Configuration Using Channel Number  2
    FOR  ${network_configuration}  IN  @{network_configurations}
      Run Keyword If  '${network_configuration['Address']}' =='${OPENBMC_HOST_1}'
      ...  Run Keywords  Set Suite Variable  ${eth1_ipaddress}  ${network_configuration['Address']}
      ...  AND  Set Suite Variable  ${eth1_subnet_mask}  ${network_configuration['SubnetMask']}
      ...  AND  Set Suite Variable  ${eth1_gateway}  ${network_configuration['Gateway']}
      ...  AND  Exit For Loop
    END
