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
Library                         ../lib/var_funcs.py
Library                         ../lib/func_args.py
Library                         Collections

Suite Teardown                  Suite Teardown Execution


*** Variables ***
${vlan_id}                      ${53}
@{vlan_ids}                     ${35}  ${55}
${invalid_vlan_id}              abc
${vlan_resource}                ${NETWORK_MANAGER}action/VLAN
${network_resource}             xyz.openbmc_project.Network.IP.Protocol.IPv4
${static_network_resource}      xyz.openbmc_project.Network.IP.AddressOrigin.Static
${ip}                           10.6.6.10
@{ip_addresses}                 10.5.5.10  10.4.5.7
${netmask}                      ${24}
${gateway}                      0.0.0.0
${initial_vlan_config}          @{EMPTY}


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

    Initiate BMC Reboot

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

*** Keywords ***


Test Setup Execution
    [Documentation]  Check and delete all previously created VLAN if any.

    Printn
    ${lan_config}=  Get LAN Print Dict
    Return From Keyword If  '${lan_config['802.1q VLAN ID']}' == 'Disabled'

    # Get all VLAN ID on interface eth0.
    ${vlan_ids}=  Get VLAN IDs

    ${initial_vlan_config}=  Create List
    Set Suite Variable  ${initial_vlan_config}

    FOR  ${vlan_id}  IN  @{vlan_ids}
        ${vlan_records}=  Read Properties
        ...  ${NETWORK_MANAGER}eth0_${vlan_id}${/}enumerate  quiet=1
        ${vlan_record}=  Filter Struct
        ...  ${vlan_records}  [('Origin', '${static_network_resource}')]

        ${id}=  Convert To Integer  ${vlan_id}
        Set Initial VLAN Config  ${vlan_record}  ${id}
    END
    Rprint Vars  initial_vlan_config

    Delete VLANs  ${vlan_ids}


Set Initial VLAN Config
    [Documentation]  Set suite level list of Initial VLAN Config.
    [Arguments]  ${vlan_record}  ${id}

    # Description of argument(s):
    # vlan_record  Dictionary of IP configuration information of a VLAN.
    # Example:
    #  /xyz/openbmc_project/network/eth0_55/ipv4/5fb2cfe6": {
    #  "Address": "x.x.x.x",
    #  "Gateway": "",
    #  "Origin": "xyz.openbmc_project.Network.IP.AddressOrigin.Static",
    #  "PrefixLength": 16,
    #  "Type": "xyz.openbmc_project.Network.IP.Protocol.IPv4"}
    #
    # id  The VLAN ID corresponding to the IP Configuration records contained
    #     in the variable "vlan_record".

    ${uris}=  Get Dictionary Keys  ${vlan_record}

    FOR  ${uri}  IN  @{uris}
        Append To List  ${initial_vlan_config}  ${id}  ${vlan_record['${uri}']['Address']}
        ...  ${vlan_record['${uri}']['PrefixLength']}
    END

    Run Keyword If  @{uris} == @{EMPTY}
    ...  Append To List  ${initial_vlan_config}  ${id}  ${EMPTY}  ${EMPTY}


Suite Teardown Execution
    [Documentation]  Restore VLAN configuration.

    ${length}=  Get Length  ${initial_vlan_config}
    Return From Keyword If  ${length} == ${0}

    ${previous_id}=  Set Variable  ${EMPTY}
    FOR  ${index}  IN RANGE  0  ${length}  3

        Run Keyword If  '${initial_vlan_config[${index+1}]}' == '${EMPTY}'
        ...  Create VLAN  ${initial_vlan_config[${index}]}
        ...  ELSE IF  '${previous_id}' == '${initial_vlan_config[${index}]}'
        ...  Configure Network Settings On VLAN  ${initial_vlan_config[${index}]}
        ...  ${initial_vlan_config[${index+1}]}  ${initial_vlan_config[${index+2}]}
        ...  ELSE  Run Keywords  Create VLAN  ${initial_vlan_config[${index}]}  AND
        ...  Configure Network Settings On VLAN  ${initial_vlan_config[${index}]}
        ...  ${initial_vlan_config[${index+1}]}  ${initial_vlan_config[${index+2}]}

        ${previous_id}=  Set Variable  ${initial_vlan_config[${index}]}
    END


Delete VLANs
    [Documentation]  Delete one or more VLANs.
    [Arguments]  ${ids}  ${interface}=eth0

    # Description of argument(s):
    # ids                           A list of VLAN IDs (e.g. ['53'] or ['53', '35', '12']). Note that the
    #                               caller may simply pass a list variable or he/she may specify a
    #                               python-like list specification (see examples below).
    # interface                     The physical interface for the VLAN (e.g. 'eth0').

    # Example calls:
    # Delete VLANs  ${vlan_ids}
    # Delete Vlans  [53, 35]

    # Allow for python-like list specifications (e.g. ids=['53']).
    ${vlan_ids}=  Source To Object  ${ids}

    FOR  ${id}  IN  @{vlan_ids}
        OpenBMC Delete Request  ${NETWORK_MANAGER}${interface}_${id}
    END
    Run Key U  Sleep \ ${NETWORK_TIMEOUT}s


Create VLAN
    [Documentation]  Create a VLAN.
    [Arguments]  ${id}  ${interface}=eth0  ${expected_result}=valid

    # Description of argument(s):
    # id  The VLAN ID (e.g. '53').
    # interface  The physical interface for the VLAN(e.g. 'eth0').

    @{data_vlan_id}=  Create List  ${interface}  ${id}
    ${data}=  Create Dictionary   data=@{data_vlan_id}
    ${resp}=  OpenBMC Post Request  ${vlan_resource}  data=${data}
    ${resp.status_code}=  Convert To String  ${resp.status_code}
    ${status}=  Run Keyword And Return Status
    ...  Valid Value  resp.status_code  ["${HTTP_OK}"]

    Run Keyword If  '${expected_result}' == 'error'
    ...      Should Be Equal  ${status}  ${False}
    ...      msg=Configuration of an invalid VLAN ID Failed.
    ...  ELSE
    ...      Should Be Equal  ${status}  ${True}
    ...      msg=Configuration of a valid VLAN ID Failed.

    Sleep  ${NETWORK_TIMEOUT}s


Get VLAN IDs
    [Documentation]  Return all VLAN IDs.

    ${vlan_ids}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip addr | grep @eth0 | cut -f1 -d@ | cut -f2 -d.
    ${vlan_ids}=  Split String  ${vlan_ids}

    [Return]  @{vlan_ids}


Configure Network Settings On VLAN
    [Documentation]  Configure network settings.
    [Arguments]  ${id}  ${ip_addr}  ${prefix_len}  ${gateway_ip}=${gateway}
    ...  ${expected_result}=valid  ${interface}=eth0

    # Description of argument(s):
    # id               The VLAN ID (e.g. '53').
    # ip_addr          IP address of VLAN Interface.
    # prefix_len       Prefix length of VLAN Interface.
    # gateway_ip       Gateway IP address of VLAN Interface.
    # expected_result  Expected status of network setting configuration.
    # interface        Physical Interface on which the VLAN is defined.

    @{ip_parm_list}=  Create List  ${network_resource}
    ...  ${ip_addr}  ${prefix_len}  ${gateway_ip}

    ${data}=  Create Dictionary  data=@{ip_parm_list}

    Run Keyword And Ignore Error  OpenBMC Post Request
    ...  ${NETWORK_MANAGER}${interface}_${id}/action/IP  data=${data}

    # After any modification on network interface, BMC restarts network
    # module, wait until it is reachable. Then wait 15 seconds for new
    # configuration to be updated on BMC.

    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}
    ...  ${NETWORK_RETRY_TIME}
    Sleep  ${NETWORK_TIMEOUT}s

    # Verify whether new IP address is populated on BMC system.
    # It should not allow to configure invalid settings.
    ${status}=  Run Keyword And Return Status
    ...  Verify IP On BMC  ${ip_addr}

    Run Keyword If  '${expected_result}' == 'error'
    ...      Should Be Equal  ${status}  ${False}
    ...      msg=Configuration of invalid IP Failed.
    ...  ELSE
    ...      Should Be Equal  ${status}  ${True}
    ...      msg=Configuration of valid IP Failed.


Get VLAN URI For IP
    [Documentation]  Get and return the URI for a VLAN IP.
    [Arguments]  ${vlan_id}  ${vlan_ip}  ${expected_result}=valid

    # Description of argument(s):
    # vlan_id  The VLAN ID (e.g. '53').
    # vlan_ip  The VLAN IP (e.g. 'x.x.x.x').

    ${vlan_records}=  Read Properties
    ...  ${NETWORK_MANAGER}eth0_${vlan_id}${/}enumerate  quiet=1
    ${vlan_record}=  Filter Struct  ${vlan_records}  [('Address', '${vlan_ip}')]
    ${num_vlan_records}=  Get Length  ${vlan_record}
    ${status}=  Run Keyword And Return Status  Should Be True  ${num_vlan_records} > 0
    ...  msg=Could not find a uri for vlan "${vlan_id}" with IP "${vlan_ip}".

    Run Keyword If  '${expected_result}' == 'valid'
    ...      Should Be Equal  ${status}  ${True}
    ...      msg=VLAN IP URI doesn't exist!.
    ...  ELSE
    ...      Should Be Equal  ${status}  ${False}
    ...      msg=VLAN IP URI exists!.
    ${uris}=  Get Dictionary Keys  ${vlan_record}
    Return From Keyword If  @{uris} == @{EMPTY}

    [Return]  ${uris[${0}]}


Verify Existence Of VLAN
    [Documentation]  Verify VLAN ID exists.
    [Arguments]  ${id}  ${interface}=eth0  ${expected_result}=valid

    # Description of argument(s):
    # id  The VLAN ID (e.g. id:'53').
    # interface        Physical Interface on which the VLAN is defined.
    # expected_result  Expected status to check existence or non-existence of VLAN.

    ${vlan_ids}=  Get VLAN IDs
    ${cli_status}=  Run Keyword And Return Status
    ...  Valid List  vlan_ids  required_values=['${id}']

    ${network_records}=  Read Properties  ${NETWORK_MANAGER}
    ${rest_status}=  Run Keyword And Return Status  Valid List  network_records
    ...  required_values=['${NETWORK_MANAGER}${interface}_${id}']

    Should Be Equal  ${rest_status}  ${cli_status}
    ...  msg=REST and CLI Output are not the same.
    Run Keyword If  '${expected_result}' == 'valid'
    ...      Should Be Equal  ${rest_status}  ${True}
    ...      msg=VLAN ID doesn't exist!.
    ...  ELSE
    ...      Should Be Equal  ${rest_status}  ${False}
    ...      msg=VLAN ID exists!.
