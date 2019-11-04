*** Settings ***
Documentation           Test setting VLAN and its configuration.


Resource                	../lib/rest_client.robot
Resource                	../lib/ipmi_client.robot
Resource                	../lib/utils.robot
Resource                	../lib/openbmc_ffdc.robot
Resource                	../lib/ipmi_client.robot
Resource                	../lib/bmc_network_utils.robot
Resource                	../lib/state_manager.robot
Library                 	../lib/utilities.py
Library                 	../lib/ipmi_utils.py
Library                 	../lib/var_funcs.py
Library                 	Collections

Suite Teardown                  Suite Teardown Execution


*** Variables ***
${vlan_id}              	${53}
${invalid_vlan_id}      	abc
${vlan_resource}        	${NETWORK_MANAGER}action/VLAN
${network_resource}     	xyz.openbmc_project.Network.IP.Protocol.IPv4
${static_network_resource}      xyz.openbmc_project.Network.IP.AddressOrigin.Static
${ip}                   	10.6.6.10
${netmask}              	${24}
${gateway}              	0.0.0.0
${initial_vlan_config}  	@{EMPTY}


*** Test Cases ***


Add VLAN Via REST And Verify
    [Documentation]  Add VLAN via REST and verify it via CMD and IPMI.
    [Tags]  Add_VLAN_Via_REST_And_Verify
    [Setup]  Test Setup Execution
    [Teardown]  Delete VLAN  ${vlan_id}

    Create VLAN  ${vlan_id}
    Verify Existence Of VLAN  ${vlan_id}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ["${vlan_id}"]


Add Invalid VLAN Via REST And Verify
    [Documentation]  Add Invalid VLAN via REST and verify.
    [Tags]  Add_Invalid_VLAN_Via_REST_And_Verify

    ${status}=  Create VLAN  ${invalid_vlan_id}
    Should Be Equal  ${status}  ${False}


Delete VLAN Via REST
    [Documentation]  Delete VLAN via REST and verify it via CMD and IPMI.
    [Tags]  Delete_VLAN_Via_REST
    [Setup]  Run Keywords  Test Setup Execution  AND  Create VLAN  ${vlan_id}
    [Teardown]  Delete VLAN  ${vlan_id}

    Verify Existence Of VLAN  ${vlan_id}
    Delete VLAN  ${vlan_id}

    ${status}=  Run Keyword And Return Status
    ...  Verify Existence Of VLAN  ${vlan_id}
    Should Be Equal  ${status}  ${False}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ["Disabled"]


Configure IP On VLAN Via REST
    [Documentation]  Configure IP on VLAN and verify it via REST and IPMI.
    [Tags]  Configure_IP_On_VLAN_Via_REST
    [Setup]  Run Keywords  Test Setup Execution  AND  Create VLAN  ${vlan_id}
    [Teardown]  Delete VLAN  ${vlan_id}

    Configure IP On VLAN  ${vlan_id}  ${ip}  ${netmask}
    Get VLAN URI  ${vlan_id}  ${ip}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]


Delete IP On VLAN Via REST
    [Documentation]  Delete IP on VLAN and verify it via REST and IPMI.
    [Tags]  Delete_IP_On_VLAN_Via_REST
    [Setup]  Run Keywords  Test Setup Execution  AND  Create VLAN  ${vlan_id}
    [Teardown]  Delete VLAN  ${vlan_id}

    Configure IP On VLAN  ${vlan_id}  ${ip}  ${netmask}
    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]

    ${vlan_ip_uri}=  Get VLAN URI  ${vlan_id}  ${ip}
    Delete IP And Object  ${ip}  ${vlan_ip_uri}

    ${status}=  Run Keyword And Return Status
    ...  Get VLAN URI  ${vlan_id}  ${ip}
    Should Be Equal  ${status}  ${False}

    ${lan_config}=  Get LAN Print Dict
    Should Not Match  ${lan_config['IP Address']}  ${ip}


Delete VLAN When IP Is Configured Via REST
    [Documentation]  Delete IP on VLAN and verify using IPMI.
    [Tags]  Delete_VLAN_When_IP_Is_Configured_Via_REST
    [Setup]  Run Keywords  Test Setup Execution  AND  Create VLAN  ${vlan_id}
    [Teardown]  Delete VLAN  ${vlan_id}

    Configure IP On VLAN  ${vlan_id}  ${ip}  ${netmask}
    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]
    Delete VLAN  ${vlan_id}

    ${status}=  Run Keyword And Return Status
    ...  Verify Existence Of VLAN  ${vlan_id}
    Should Be Equal  ${status}  ${False}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ["Disabled"]


Configure VLAN And Check Persistency On Reboot
    [Documentation]  Create VLAN ID & IP , reboot and verify.
    [Tags]  Configure_VLAN_And_Check_Persistency_On_Reboot
    [Setup]  Test Setup Execution
    [Teardown]  Delete VLAN  ${vlan_id}

    Create VLAN  ${vlan_id}
    Configure IP On VLAN  ${vlan_id}  ${ip}  ${netmask}
    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]
    Valid Value  lan_config['802.1q VLAN ID']  ["${vlan_id}"]

    Initiate BMC Reboot

    Verify Existence Of VLAN  ${vlan_id}
    Get VLAN URI  ${vlan_id}  ${ip}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]
    Valid Value  lan_config['802.1q VLAN ID']  ["${vlan_id}"]


*** Keywords ***


Test Setup Execution
    [Documentation]  Check and delete all previously created VLAN if any.

    ${lan_config}=  Get LAN Print Dict
    Return From Keyword If  '${lan_config['802.1q VLAN ID']}' == 'Disabled'

    # Get all VLAN ID on interface eth0.
    ${vlan_id_lists}=  Get VLAN IDs

    ${initial_vlan_config}=  Create List
    Set Suite Variable  ${initial_vlan_config}

    FOR  ${vlan_id}  IN  @{vlan_id_lists}
    ${vlan_records}=  Read Properties
    ...  ${NETWORK_MANAGER}eth0_${vlan_id}${/}enumerate  quiet=1
    ${vlan_record}=  Filter Struct
    ...  ${vlan_records}  [('Origin', '${static_network_resource}')]

    ${id}=  Convert To Integer  ${vlan_id}
    Set Initial VLAN Config  ${vlan_record}  ${id}
    END
    Rprint Vars  initial_vlan_config

    FOR  ${vlan_id}  IN  @{vlan_id_lists}
    Delete VLAN  ${vlan_id}
    END


Set Initial VLAN Config
    [Documentation]  Set suite level list of Initial VLAN Config.
    [Arguments]  ${vlan_record}  ${id}

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
    ...  Configure IP On VLAN  ${initial_vlan_config[${index}]}
    ...  ${initial_vlan_config[${index+1}]}  ${initial_vlan_config[${index+2}]}
    ...  ELSE  Run Keywords  Create VLAN  ${initial_vlan_config[${index}]}  AND
    ...  Configure IP On VLAN  ${initial_vlan_config[${index}]}
    ...  ${initial_vlan_config[${index+1}]}  ${initial_vlan_config[${index+2}]}

    ${previous_id}=  Set Variable  ${initial_vlan_config[${index}]}
    END


Delete VLAN
    [Documentation]  Delete a VLAN.
    [Arguments]  ${id}  ${interface}=eth0

    # Description of argument(s):
    # id  The VLAN ID (e.g. '53').
    # interface  The physical interface for the VLAN(e.g. 'eth0').

    OpenBMC Delete Request  ${NETWORK_MANAGER}${interface}_${id}
    Sleep  ${NETWORK_TIMEOUT}s


Create VLAN
    [Documentation]  Create a VLAN.
    [Arguments]  ${id}  ${interface}=eth0

    # Description of argument(s):
    # id  The VLAN ID (e.g. '53').
    # interface  The physical interface for the VLAN(e.g. 'eth0').

    @{data_vlan_id}=  Create List  ${interface}  ${id}
    ${data}=  Create Dictionary   data=@{data_vlan_id}
    ${resp}=  OpenBMC Post Request  ${vlan_resource}  data=${data}
    ${resp.status_code}=  Convert To String  ${resp.status_code}
    ${status}=  Run Keyword And Return Status
    ...  Valid Value  resp.status_code  ["${HTTP_OK}"]
    Sleep  ${NETWORK_TIMEOUT}s

    [Return]  ${status}


Get VLAN IDs
    [Documentation]  Return all VLAN IDs.

    ${vlan_ids}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip addr | grep @eth0 | cut -f1 -d@ | cut -f2 -d.
    ${vlan_ids}=  Split String  ${vlan_ids}

    [Return]  @{vlan_ids}


Configure IP On VLAN
    [Documentation]  Create a VLAN IP.
    [Arguments]  ${id}  ${ip}  ${netmask}  ${gateway}=${gateway}

    # Description of argument(s):
    # id  The VLAN ID (e.g. '53').
    # ip  IP to be added for this VLAN Interface (e.g. 'x.x.x.x').
    # netmask  mask to be added for this VLAN Interface.
    # gateway  gateway to be added for this VLAN Interface.

    @{data_vlan_ip}=  Create List
    ...  ${network_resource}  ${ip}  ${netmask}  ${gateway}
    ${data}=  Create Dictionary   data=@{data_vlan_ip}
    OpenBMC Post Request
    ...  ${NETWORK_MANAGER}eth0_${id}/action/IP  data=${data}
    Sleep  ${NETWORK_TIMEOUT}s


Get VLAN URI
    [Documentation]  Get and return the URI for a VLAN IP.
    [Arguments]  ${vlan_id}  ${vlan_ip}

    # Description of argument(s):
    # vlan_id  The VLAN ID (e.g. '53').
    # vlan_ip  The VLAN IP (e.g. 'x.x.x.x').

    ${vlan_records}=  Read Properties
    ...  ${NETWORK_MANAGER}eth0_${vlan_id}${/}enumerate  quiet=1
    ${vlan_record}=  Filter Struct  ${vlan_records}  [('Address', '${vlan_ip}')]
    ${num_vlan_records}=  Get Length  ${vlan_record}
    Should Be True  ${num_vlan_records} > 0
    ...  msg=Could not find a uri for vlan "${53}" with IP "${vlan_ip}".
    ${uris}=  Get Dictionary Keys  ${vlan_record}

    [Return]  ${uris[${0}]}


Verify Existence Of VLAN
    [Documentation]  Verify VLAN ID exists.
    [Arguments]  ${id}

    # Description of argument(s):
    # id  The VLAN ID (e.g. id:'53').

    ${vlan_ids}=  Get VLAN IDs
    Valid List  vlan_ids  required_values=['${id}']
