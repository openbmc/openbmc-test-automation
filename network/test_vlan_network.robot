*** Settings ***
Documentation           Test setting VLAN and its configuration.


Resource                ../lib/rest_client.robot
Resource                ../lib/ipmi_client.robot
Resource                ../lib/utils.robot
Resource                ../lib/openbmc_ffdc.robot
Resource                ../lib/ipmi_client.robot
Resource                ../lib/bmc_network_utils.robot
Resource                ../lib/state_manager.robot
Library                 ../lib/utilities.py
Library                 ../lib/ipmi_utils.py
Library                 ../lib/var_funcs.py
Library                 Collections

Suite Setup             Suite Setup Execution

*** Variables ***
${vlan_id}              ${53}
${vlan_resource}        ${NETWORK_MANAGER}action/VLAN
${network_resource}          xyz.openbmc_project.Network.IP.Protocol.IPv4
${ip}                   10.6.6.10
${netmask}              ${24}
${gateway}              0.0.0.0


*** Test Cases ***

Create VLAN Via REST
    [Documentation]  Create new VLAN ID via REST and verify using IPMI
    [Tags]  Create_VLAN_Via_REST
    [Teardown]  Delete VLAN  ${vlan_id}

    Create VLAN  ${vlan_id}
    Wait Until Keyword Succeeds  20x  5s
    ...  Verify VLAN Parameter Exists  eth0.${vlan_id}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ["${vlan_id}"]


Delete VLAN Via REST
    [Documentation]  Delete VLAN via REST and verify using IPMI
    [Tags]  Delete_VLAN_Via_REST
    [Setup]  Create VLAN  ${vlan_id}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ["${vlan_id}"]
    Delete VLAN  ${vlan_id}

    Wait Until Keyword Succeeds  30x  5s
    ...  Verify VLAN Parameter Does Not Exist  eth0.${vlan_id}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ["Disabled"]


Configure IP On VLAN Via REST
    [Documentation]  Configure IP on VLAN and verify using IPMI
    [Tags]  Configure_IP_On_VLAN_Via_REST
    [Setup]  Create VLAN  ${vlan_id}
    [Teardown]  Delete VLAN  ${vlan_id}

    Create VLAN IP  ${vlan_id}  ${ip}
    Wait Until Keyword Succeeds  30x  5s
    ...  Verify IP On BMC  ${ip}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]


Delete IP On VLAN Via REST
    [Documentation]  Delete IP on VLAN and verify using IPMI
    [Tags]  Delete_IP_On_VLAN_Via_REST
    [Setup]  Create VLAN  ${vlan_id}
    [Teardown]  Delete VLAN  ${vlan_id}

    Create VLAN IP  ${vlan_id}  ${ip}
    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]

    ${vlan_ip_uri}=  Wait Until Keyword Succeeds  20x  5s
    ...  Get VLAN URI  ${vlan_id}  ${ip}
    Delete VLAN IP  ${vlan_ip_uri}

    Wait Until Keyword Succeeds  30x  5s
    ...  Verify VLAN Parameter Does Not Exist  ${ip}

    ${lan_config}=  Get LAN Print Dict
    Should Not Match  ${lan_config['IP Address']}  ${ip}


Delete VLAN When IP Is Configured Via REST
    [Documentation]  Delete IP on VLAN and verify using IPMI
    [Tags]  Delete_VLAN_When_IP_Is_Configured_Via_REST
    [Setup]  Create VLAN  ${vlan_id}

    Create VLAN IP  ${vlan_id}  ${ip}
    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]
    Delete VLAN  ${vlan_id}

    Wait Until Keyword Succeeds  30x  5s
    ...  Verify VLAN Parameter Does Not Exist  eth0.${vlan_id}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ["Disabled"]


Create VLAN Parameters And Check Persistency On Reboot
    [Documentation]  Create VLAN ID & IP , reboot and verify
    [Tags]  Create_VLAN_Parameters_And_Check_Persistency_On_Reboot
    [Teardown]  Delete VLAN  ${vlan_id}

    Create VLAN  ${vlan_id}
    Create VLAN IP  ${vlan_id}  ${ip}
    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]
    Valid Value  lan_config['802.1q VLAN ID']  ["${vlan_id}"]

    Initiate BMC Reboot

    Wait Until Keyword Succeeds  30x  5s
    ...  Verify VLAN Parameter Exists  eth0.${vlan_id}
    Wait Until Keyword Succeeds  30x  5s
    ...  Verify IP On BMC  ${ip}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]
    Valid Value  lan_config['802.1q VLAN ID']  ["${vlan_id}"]


*** Keywords ***

Suite Setup Execution
    [Documentation]  Check and delete all previously created VLAN if any.

    ${lan_config}=  Get LAN Print Dict
    Return From Keyword If  '${lan_config['802.1q VLAN ID']}' == 'Disabled'

    # Get all VLAN ID on interface eth0.
    ${vlan_id_list}=  Get VLAN IDs

    :FOR  ${vlan_id}  IN  @{vlan_id_list}
    \  Delete VLAN  ${vlan_id}


Delete VLAN
    [Documentation]  Delete a VLAN.
    [Arguments]  ${id}

    # Description of argument(s):
    # id  The VLAN ID (e.g. '53').
    OpenBMC Delete Request  ${NETWORK_MANAGER}eth0_${id}
    Sleep  5s


Create VLAN
    [Documentation]  Create a VLAN.
    [Arguments]  ${id}

    # Description of argument(s):
    # id  The VLAN ID (e.g. '53').
    @{data_vlan_id}=  Create List  eth0  ${id}
    ${data}=  Create Dictionary   data=@{data_vlan_id}
    OpenBMC Post Request  ${vlan_resource}  data=${data}
    Sleep  5s


Get VLAN IDs
    [Documentation]  Returns all VLAN IDs.

    ${vlan_ids}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip addr | grep @eth0 | cut -f1 -d@ | cut -f2 -d.
    ${vlan_id_list}=  Split String  ${vlan_ids}

    [Return]  @{vlan_id_list}


Delete VLAN IP
    [Documentation]  Deletes a specified VLAN IP.
    [Arguments]  ${ip_uri}

    # Description of argument(s):
    # ip_uri  URI to delete via REST
    # Example:
    #   "data": [
    #     "/xyz/openbmc_project/network/eth0/ipv4/e9767624",
    #     "/xyz/openbmc_project/network/eth0/ipv4/31f4ce8b"
    #   ],

    OpenBMC Delete Request  ${ip_uri}
    Sleep  5s


Create VLAN IP
    [Documentation]  Create a specified VLAN IP.
    [Arguments]  ${id}  ${ip}

    # Description of argument(s):
    # id  The VLAN ID (e.g. '53').
    # ip  IP to be added for this VLAN Interface (e.g. '10.6.6.10')

    @{data_vlan_ip}=  Create List
    ...  ${network_resource}  ${ip}  ${netmask}  ${gateway}
    ${data}=  Create Dictionary   data=@{data_vlan_ip}
    OpenBMC Post Request
    ...  ${NETWORK_MANAGER}eth0_${id}/action/IP  data=${data}
    Sleep  5s


Get VLAN URI
    [Documentation]  Get and return the URI associated with a VLAN IP.
    [Arguments]  ${vlan_id}  ${vlan_ip}

    # Description of argument(s):
    # vlan_id  The VLAN ID (e.g. '53').
    # vlan_ip  The VLAN IP (e.g. '9.9.9.9').

    ${vlan_records}=  Read Properties
    ...  ${NETWORK_MANAGER}eth0_${vlan_id}${/}enumerate  quiet=1
    ${vlan_record}=  Filter Struct  ${vlan_records}  [('Address', '${vlan_ip}')]
    ${num_vlan_records}=  Get Length  ${vlan_record}
    Should Be True  ${num_vlan_records} > 0
    ...  msg=Could not find a uri for vlan "${53}" with IP "${vlan_ip}".
    ${uris}=  Get Dictionary Keys  ${vlan_record}

    [Return]  ${uris[${0}]}


Verify VLAN Parameter Exists
    [Documentation]  Verify that the given VLAN N/W parameter exists.
    [Arguments]  ${value}

    # Description of argument(s):
    # value  The VLAN ID/IP (e.g. id:'53'; ip:'9.9.9.9').

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip addr
    Should Contain  ${cmd_output}  ${value}
    ...  msg=${value} not found.


Verify VLAN Parameter Does Not Exist
    [Documentation]  Verify that the given VLAN N/W parameter does not exist.
    [Arguments]  ${value}

    # Description of argument(s):
    # value  The VLAN ID/IP (e.g. id:'53'; ip:'9.9.9.9').

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip addr
    Should Not Contain  ${cmd_output}  ${value}
    ...  msg=${value} found.
