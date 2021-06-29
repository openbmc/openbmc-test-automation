*** Settings ***
Documentation    Test BMC multiple interface functionalities.

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

Verify Both Interfaces Able To Pingable
    [Documentation]  Verify both interfaces able to ping.
    [Tags]  Verify_Both_Interfaces_Able_To_Pingable

    Ping Host  ${OPENBMC_HOST}
    Ping Host  ${OPENBMC_HOST_1}


Verify Both Interfaces Able To Access Via SSH
    [Documentation]  Verify able to SSH both interfaces.
    [Tags]  Verify_Both_Interfaces_Able_To_Access_Via_SSH

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

    Redfish.Login
    ${status}=  Run Keyword And Return Status  Redfish.Get  ${REDFISH_NW_ETH_IFACE}eth1
    Should Be Equal  ${status}  ${True}  msg=BMC not configured with eth1 interface.

    ${eth1_host_name}  ${eth1_ip_address}=  Get Host Name IP  host=${OPENBMC_HOST_1}
    Set Suite Variable  ${eth1_ip_address}

    @{network_configurations}=  Get Network Configuration Using Channel Number  2
    FOR  ${network_configuration}  IN  @{network_configurations}
      Run Keyword If  '${network_configuration['Address']}' == '${eth1_ip_address}'
      ...  Run Keywords  Set Suite Variable  ${eth1_subnet_mask}  ${network_configuration['SubnetMask']}
      ...  AND  Set Suite Variable  ${eth1_gateway}  ${network_configuration['Gateway']}
      ...  AND  Exit For Loop
    END
