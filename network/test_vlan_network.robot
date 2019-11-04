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


Suite Setup             Suite Setup Execution

*** Variables ***
${vlan_id}              ${53}
${vlan_resource}        ${NETWORK_MANAGER}action/VLAN
${nw_resource}          xyz.openbmc_project.Network.IP.Protocol.IPv4
${ip}                   10.6.6.10
${netmask}              ${24}
${gateway}              0.0.0.0


*** Test Cases ***

Create VLAN Via REST
    [Documentation]  Create new VLAN ID via REST and verify using IPMI
    [Tags]  Create_VLAN_Via_REST
    [Teardown]  Delete VLAN ID  ${vlan_id}

    Create VLAN ID  ${vlan_id}
    Wait Until Keyword Succeeds  20x  5s
    ...  Check If Exists  eth0.${vlan_id}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ["${vlan_id}"]


Delete VLAN Via REST
    [Documentation]  Delete VLAN ID via REST and verify using IPMI
    [Tags]  Delete_VLAN_Via_REST
    [Setup]  Create VLAN ID  ${vlan_id}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ["${vlan_id}"]
    Delete VLAN ID  ${vlan_id}

    Wait Until Keyword Succeeds  30x  5s
    ...  Check If Does Not Exist  eth0.${vlan_id}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ["Disabled"]


Configiure IP On VLAN Via REST
    [Documentation]  Configure IP on VLAN and verify using IPMI
    [Tags]  Configiure_IP_On_VLAN_Via_REST
    [Setup]  Create VLAN ID  ${vlan_id}
    [Teardown]  Delete VLAN ID  ${vlan_id}

    Create VLAN IP  ${vlan_id}  ${ip}
    Wait Until Keyword Succeeds  30x  5s
    ...  Verify IP On BMC  ${ip}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]


Delete IP On VLAN via REST
    [Documentation]  Delete IP on VLAN and verify using IPMI
    [Tags]  Delete_IP_On_VLAN_Via_REST
    [Setup]  Create VLAN ID  ${vlan_id}
    [Teardown]  Delete VLAN ID  ${vlan_id}

    Create VLAN IP  ${vlan_id}  ${ip}
    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]

    ${vlan_ip_uri}=  Wait Until Keyword Succeeds  20x  5s
    ...  Get VLAN URI  ${vlan_id}  ${ip}
    Delete VLAN IP  ${vlan_ip_uri}

    Wait Until Keyword Succeeds  30x  5s
    ...  Check If Does Not Exist  ${ip}

    ${lan_config}=  Get LAN Print Dict
    Should Not Match  ${lan_config['IP Address']}  ${ip}


Delete VLAN When IP Is Configured Via REST
    [Documentation]  Delete IP on VLAN and verify using IPMI
    [Tags]  Delete_VLAN_When_IP_Is_Configured_Via_REST
    [Setup]  Create VLAN ID  ${vlan_id}

    Create VLAN IP  ${vlan_id}  ${ip}
    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]
    Delete VLAN ID  ${vlan_id}

    Wait Until Keyword Succeeds  30x  5s
    ...  Check If Does Not Exist  eth0.${vlan_id}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['802.1q VLAN ID']  ["Disabled"]


Create VLAN Parameters And Check Persistency On Reboot
    [Documentation]  Create VLAN ID & IP , reboot and verify
    [Tags]  Create_VLAN_Parameters_And_Check_Persistency_On_Reboot
    [Teardown]  Delete VLAN ID  ${vlan_id}

    Create VLAN ID  ${vlan_id}
    Create VLAN IP  ${vlan_id}  ${ip}
    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]
    Valid Value  lan_config['802.1q VLAN ID']  ["${vlan_id}"]

    Initiate BMC Reboot

    Wait Until Keyword Succeeds  30x  5s
    ...  Check If Exists  eth0.${vlan_id}
    Wait Until Keyword Succeeds  30x  5s
    ...  Verify IP On BMC  ${ip}

    ${lan_config}=  Get LAN Print Dict
    Valid Value  lan_config['IP Address']  ["${ip}"]
    Valid Value  lan_config['802.1q VLAN ID']  ["${vlan_id}"]


*** Keywords ***

Suite Setup Execution
    [Documentation]  Check and delete all previously created VLAN if any.

    ${lan_config}=  Get LAN Print Dict
    Run Keyword if  '${lan_config['802.1q VLAN ID']}' == 'Disabled'
    ...  Return From Keyword  True

    # Get all VLAN ID on interface eth0.
    ${vlan_id}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip addr|grep @eth0|awk -F@ '{print$1}'|awk -F. '{print$2}'
    ${vlan_id_list}=  Split String  ${vlan_id}

    :FOR  ${id}  IN  @{vlan_id_list}
    \  Delete VLAN ID  ${id}


Delete VLAN ID
    [Documentation]  Deletes a specified VLAN ID.
    [Arguments]  ${id}

    OpenBMC Delete Request  ${NETWORK_MANAGER}eth0_${id}
    Sleep  5s


Create VLAN ID
    [Documentation]  Creates a specified VLAN ID.
    [Arguments]  ${id}

    @{data_vlan_id}=  Create List  eth0  ${id}
    ${data}=  create dictionary   data=@{data_vlan_id}
    OpenBMC Post Request  ${vlan_resource}  data=${data}
    Sleep  5s


Delete VLAN IP
    [Documentation]  Deletes a specified VLAN IP.
    [Arguments]  ${ip_uri}

    OpenBMC Delete Request  ${ip_uri}
    Sleep  5s


Create VLAN IP
    [Documentation]  Create a specified VLAN IP.
    [Arguments]  ${id}  ${ip}

    @{data_vlan_ip}=  Create List
    ...  ${nw_resource}  ${ip}  ${netmask}  ${gateway}
    ${data}=  create dictionary   data=@{data_vlan_ip}
    OpenBMC Post Request
    ...  ${NETWORK_MANAGER}eth0_${id}/action/IP  data=${data}
    Sleep  5s


Get VLAN URI
    [Documentation]  Get equivalent URI for a given VLAN IP.
    [Arguments]  ${vlan_id}  ${vlan_ip}

    ${resp}=  OpenBMC Get Request
    ...  ${NETWORK_MANAGER}eth0_${vlan_id}${/}enumerate
    ${eth0_vlan}=  To Json  ${resp.content}
    ${eth0_vlan_keys}=  Get Dictionary Keys  ${eth0_vlan['data']}

    :FOR  ${id}  IN  @{eth0_vlan_keys}
    \  ${value}=  Evaluate
    ...  $eth0_vlan['data']['${id}'].get("Address", "None")
    \  Run Keyword if  '${value}' == '${vlan_ip}'
    ...  Return From Keyword  ${id}

    FAIL  IP Not Found


Check If Exists
    [Documentation]  Check if the given N/W parameter exists on the BMC.
    [Arguments]  ${param}

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip addr
    Should Contain  ${cmd_output}  ${param}
    ...  msg=${param} not found.


Check If Does Not Exist
    [Documentation]  Check if the given N/W parameter dosen't exist on the BMC.
    [Arguments]  ${param}

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip addr
    Should Not Contain  ${cmd_output}  ${param}
    ...  msg=${param} found.
