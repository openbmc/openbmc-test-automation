*** Settings ***
Documentation           Test setting VLAN and its configuration.


Resource                        ../lib/rest_client.robot
Resource                        ../lib/ipmi_client.robot
Resource                        ../lib/utils.robot
Resource                        ../lib/common_utils.robot
Resource                        ../lib/openbmc_ffdc.robot
Resource                        ../lib/ipmi_client.robot
Resource                        ../lib/bmc_network_utils.robot
Resource                        ../lib/state_manager.robot
Library                         ../lib/utilities.py
Library                         ../lib/ipmi_utils.py
Library                         ../lib/func_args.py

Suite Teardown                  Suite Teardown Execution


*** Variables ***
${vlan_id}                      ${53}
@{vlan_ids}                     ${35}  ${55}
${invalid_vlan_id}              abc
${ip}                           10.6.6.10
@{ip_addresses}                 10.5.5.10  10.4.5.7


*** Test Cases ***

Add VLAN Via REST And Verify
    [Documentation]  Add VLAN via REST and verify it via REST and IPMI.
    [Tags]  Add_VLAN_Via_REST_And_Verify
    [Setup]  Test Setup Execution
    [Teardown]  Delete VLANs  [${vlan_id}]

    Create VLAN  ${vlan_id}
    Verify Existence Of VLAN  ${vlan_id}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ["${vlan_id}"]


Add Invalid VLAN Via REST And Verify
    [Documentation]  Add Invalid VLAN via REST and verify.
    [Tags]  Add_Invalid_VLAN_Via_REST_And_Verify

    Create VLAN  ${invalid_vlan_id}  expected_result=error


Delete VLAN Via REST
    [Documentation]  Delete VLAN via REST and verify it via REST and IPMI.
    [Tags]  Delete_VLAN_Via_REST
    [Setup]  Run Keywords  Test Setup Execution  AND  Create VLAN  ${vlan_id}

    Verify Existence Of VLAN  ${vlan_id}
    Delete VLANs  [${vlan_id}]
    Verify Existence Of VLAN  ${vlan_id}  expected_result=error

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ["Disabled"]


Configure Network Settings On VLAN Via REST
    [Documentation]  Configure IP on VLAN and verify it via REST and IPMI.
    [Tags]  Configure_Network_Settings_On_VLAN_Via_REST
    [Setup]  Run Keywords  Test Setup Execution  AND  Create VLAN  ${vlan_id}
    [Teardown]  Delete VLANs  [${vlan_id}]

    Configure Network Settings On VLAN  ${vlan_id}  ${ip}  ${netmask}
    Get VLAN URI For IP  ${vlan_id}  ${ip}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]


Delete IP On VLAN Via REST
    [Documentation]  Delete IP on VLAN and verify it via REST and IPMI.
    [Tags]  Delete_IP_On_VLAN_Via_REST
    [Setup]  Run Keywords  Test Setup Execution  AND  Create VLAN  ${vlan_id}
    [Teardown]  Delete VLANs  [${vlan_id}]

    Configure Network Settings On VLAN  ${vlan_id}  ${ip}  ${netmask}
    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]

    ${vlan_ip_uri}=  Get VLAN URI For IP  ${vlan_id}  ${ip}
    Delete IP And Object  ${ip}  ${vlan_ip_uri}

    Get VLAN URI For IP  ${vlan_id}  ${ip}  expected_result=error

    ${lan_config}=  Get LAN Print Dict
    Should Not Match  ${lan_config['IP Address']}  ${ip}


Delete VLAN When IP Is Configured Via REST
    [Documentation]  Delete IP on VLAN and verify using IPMI.
    [Tags]  Delete_VLAN_When_IP_Is_Configured_Via_REST
    [Setup]  Run Keywords  Test Setup Execution  AND  Create VLAN  ${vlan_id}
    [Teardown]  Delete VLANs  [${vlan_id}]

    Configure Network Settings On VLAN  ${vlan_id}  ${ip}  ${netmask}
    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]
    Delete VLANs  [${vlan_id}]

    Verify Existence Of VLAN  ${vlan_id}  expected_result=error

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ["Disabled"]


Configure VLAN And Check Persistency On Reboot
    [Documentation]  Create VLAN ID & IP , reboot and verify.
    [Tags]  Configure_VLAN_And_Check_Persistency_On_Reboot
    [Setup]  Test Setup Execution
    [Teardown]  Delete VLANs  [${vlan_id}]

    Create VLAN  ${vlan_id}
    Configure Network Settings On VLAN  ${vlan_id}  ${ip}  ${netmask}
    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]
    Valid Value  lan_config['802.1q VLAN ID']  ["${vlan_id}"]

 #   Initiate BMC Reboot

    Verify Existence Of VLAN  ${vlan_id}
    Get VLAN URI For IP  ${vlan_id}  ${ip}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]
    Valid Value  lan_config['802.1q VLAN ID']  ["${vlan_id}"]


Add Multiple VLANs Via REST And Verify
    [Documentation]  Add multiple VLANs via REST and verify them via CLI.
    [Tags]  Add_Multiple_VLANs_Via_REST_And_Verify
    [Setup]  Test Setup Execution
    [Teardown]  Delete VLANs  ${vlan_ids}

    FOR  ${vlan_id}  IN   @{vlan_ids}
        Create VLAN  ${vlan_id}
        Verify Existence Of VLAN  ${vlan_id}
    END

    ${lan_config}=  Get LAN Print Dict
    ${vlan_id_ipmi}=  Convert To Integer  ${lan_config["802.1q VLAN ID"]}
    Valid List  vlan_ids  required_values=[${vlan_id_ipmi}]

Delete Multiple IPs On VLAN And Verify
    [Documentation]  Delete multiple IPs on VLAN and verify each via REST and IPMI.
    [Tags]  Delete_Multiple_IP_On_VLAN_Via_REST
    [Setup]  Run Keywords  Test Setup Execution  AND  Create VLAN  ${vlan_id}
    [Teardown]  Delete VLANs  [${vlan_id}]

    FOR  ${ip}  IN  @{ip_addresses}
        Configure Network Settings On VLAN  ${vlan_id}  ${ip}  ${netmask}
        ${vlan_ip_uri}=  Get VLAN URI For IP  ${vlan_id}  ${ip}
        Delete IP And Object  ${ip}  ${vlan_ip_uri}

        Get VLAN URI For IP  ${vlan_id}  ${ip}  expected_result=error

        ${lan_config}=  Get LAN Print Dict
        Should Not Match  ${lan_config['IP Address']}  ${ip}
    END

Delete Multiple VLANs Via REST
    [Documentation]  Delete multiple VLANs via REST and verify each via REST and IPMI.
    [Tags]  Delete_Multiple_VLANs_Via_REST
    [Setup]  Test Setup Execution

    FOR  ${vlan_id}  IN   @{vlan_ids}
        Create VLAN  ${vlan_id}
    END

    Delete VLANs  ${vlan_ids}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ["Disabled"]

Configure Multiple IPs On VLAN Via REST
    [Documentation]  Configure Multiple IPs on VLAN and verify each via REST.
    [Tags]  Configure_Multiple_IPs_On_VLAN_Via_REST
    [Setup]  Run Keywords  Test Setup Execution  AND  Create VLAN  ${vlan_id}
    [Teardown]  Delete VLANs  [${vlan_id}]

    FOR  ${ip}  IN  @{ip_addresses}
        Configure Network Settings On VLAN  ${vlan_id}  ${ip}  ${netmask}
    END

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip_addresses[0]}"]


