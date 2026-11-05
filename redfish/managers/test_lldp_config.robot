*** Settings ***
Documentation       LLDP(Link Layer Discovery Protocol) test suite for
...                 configuration and verification tests.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_network_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/connection_client.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Redfish.Logout
Test Teardown       FFDC On Test Case Fail

Test Tags           LLDP_config

*** Variables ***

${LLDP_SHOW_INTERFACES}        sudo lldpcli show interfaces
${LLDP_TLV_CHASSIS_ID}         ChassisID
${LLDP_TLV_PORT_ID}            PortID

*** Test Cases ***

Enable LLDP And Verify
    [Documentation]  Enable LLDP and verify.
    [Tags]  Enable_LLDP_And_Verify

    # Set the LLDP enabled property as True.
    Set LLDP Configuration State  ${True}

    # Verify the LLDP state is set true.
    Verify LLDP Configuration State  ${True}

Disable LLDP And Verify
    [Documentation]  Disable LLDP and verify.
    [Tags]  Disable_LLDP_And_Verify

    # Set the LLDP enabled property as False.
    Set LLDP Configuration State  ${False}

    # Verify the LLDP state is set False.
    Verify LLDP Configuration State  ${False}

Verify LLDP ChassisID Matches Eth0 MAC Address Via SSH And Redfish
    [Documentation]  SSH into BMC via OPENBMC_HOST, run lldpcli show
    ...  interfaces. Verify eth0 and eth1 ChassisID match each other
    ...  and eth0 ChassisID matches Redfish MACAddress.
    [Tags]  Verify_LLDP_ChassisID_Matches_Eth0_MAC_Address_Via_SSH_And_Redfish
    [Teardown]  Restore LLDP State And Collect FFDC

    # Enable LLDP explicitly so this test is independent of execution order.
    Set LLDP Configuration State  ${True}
    Verify LLDP Configuration State  ${True}

    # Open SSH connection to the BMC using OPENBMC_HOST.
    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

    # Run lldpcli and capture the full interfaces output; retry until non-empty.
    ${lldpcli_output}=  Wait Until Keyword Succeeds  30s  5s
    ...  Get Non Empty LLDP Interfaces Output

    # Parse the ChassisID TLV value for eth0 and eth1 from lldpcli output.
    ${eth0_chassis_id_mac}=  Get Interface TLV Value From LLDP Output
    ...  ${lldpcli_output}  eth0  ${LLDP_TLV_CHASSIS_ID}
    ${eth1_chassis_id_mac}=  Get Interface TLV Value From LLDP Output
    ...  ${lldpcli_output}  eth1  ${LLDP_TLV_CHASSIS_ID}

    # Verify eth0 and eth1 ChassisID are identical (same BMC chassis).
    VAR  ${msg_chassis}
    ...  ChassisID eth0 '${eth0_chassis_id_mac}'
    ...  != eth1 '${eth1_chassis_id_mac}'.
    Should Be Equal
    ...  ${eth0_chassis_id_mac.lower()}  ${eth1_chassis_id_mac.lower()}
    ...  msg=${msg_chassis}

    # Fetch the eth0 MAC address via Redfish for cross-verification.
    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}eth0
    ${redfish_eth0_mac}=  Get From Dictionary  ${resp.dict}  MACAddress

    # Verify the lldpcli ChassisID MAC matches the Redfish MACAddress for eth0.
    VAR  ${msg}
    ...  eth0 ChassisID '${eth0_chassis_id_mac}'
    ...  != Redfish MAC '${redfish_eth0_mac}'.
    Should Be Equal
    ...  ${eth0_chassis_id_mac.lower()}  ${redfish_eth0_mac.lower()}
    ...  msg=${msg}

Verify LLDP PortID Matches MAC Address For Eth0 And Eth1
    [Documentation]  Enable LLDP, run lldpcli show interfaces, extract
    ...  the PortID TLV for eth0 and eth1, fetch both MAC addresses from
    ...  Redfish, and verify:
    ...  1) eth0 PortID (from lldpcli) matches eth0 MACAddress (Redfish).
    ...  2) eth1 PortID (from lldpcli) matches eth1 MACAddress (Redfish).
    [Tags]  Verify_LLDP_PortID_Matches_MAC_Address_For_Eth0_And_Eth1
    [Teardown]  Restore LLDP State And Collect FFDC

    # Enable LLDP explicitly so this test is independent of execution order.
    Set LLDP Configuration State  ${True}
    Verify LLDP Configuration State  ${True}

    # Open SSH connection to the BMC using OPENBMC_HOST.
    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

    # Run lldpcli and capture the full interfaces output; retry until non-empty.
    ${lldpcli_output}=  Wait Until Keyword Succeeds  30s  5s
    ...  Get Non Empty LLDP Interfaces Output

    # Parse the PortID TLV value for eth0 and eth1 from lldpcli output.
    ${eth0_port_id}=  Get Interface TLV Value From LLDP Output
    ...  ${lldpcli_output}  eth0  ${LLDP_TLV_PORT_ID}
    ${eth1_port_id}=  Get Interface TLV Value From LLDP Output
    ...  ${lldpcli_output}  eth1  ${LLDP_TLV_PORT_ID}

    # Fetch the eth0 MAC address via Redfish.
    ${resp_eth0}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}eth0
    ${redfish_eth0_mac}=  Get From Dictionary  ${resp_eth0.dict}  MACAddress

    # Fetch the eth1 MAC address via Redfish.
    ${resp_eth1}=  Redfish.Get  ${REDFISH_NW_ETH_IFACE}eth1
    ${redfish_eth1_mac}=  Get From Dictionary  ${resp_eth1.dict}  MACAddress

    # Verify eth0 PortID from lldpcli matches eth0 MACAddress from Redfish.
    VAR  ${msg_eth0}
    ...  eth0 PortID '${eth0_port_id}' != Redfish MAC '${redfish_eth0_mac}'.
    Should Be Equal
    ...  ${eth0_port_id.lower()}  ${redfish_eth0_mac.lower()}
    ...  msg=${msg_eth0}

    # Verify eth1 PortID from lldpcli matches eth1 MACAddress from Redfish.
    VAR  ${msg_eth1}
    ...  eth1 PortID '${eth1_port_id}' != Redfish MAC '${redfish_eth1_mac}'.
    Should Be Equal
    ...  ${eth1_port_id.lower()}  ${redfish_eth1_mac.lower()}
    ...  msg=${msg_eth1}

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup execution.

    ${active_channel_config}=  Get Active Channel Config
    VAR  ${ethernet_interface}
    ...  ${active_channel_config['${CHANNEL_NUMBER}']['name']}
    VAR  ${ethernet_interface}  ${ethernet_interface}  scope=SUITE

    Redfish.Login
    ${initial_lldp_config}=  Get Initial LLDP Configuration
    VAR  ${initial_lldp_config}  ${initial_lldp_config}  scope=SUITE

Set LLDP Configuration State
    [Documentation]  Set LLDP configuration state.
    [Arguments]  ${lldp_state}

    # Description of argument(s):
    # lldp_state    LLDP state ('True' or 'False').

    VAR  &{lldp_body}  LLDPEnabled=${lldp_state}
    VAR  &{eth_body}  Ethernet=${lldp_body}
    Redfish.Patch  ${REDFISH_LLDP_ETH_IFACE}${ethernet_interface}
    ...  body=${eth_body}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

Get Initial LLDP Configuration
    [Documentation]  Get initial LLDP configuration.

    ${resp}=  Redfish.Get  ${REDFISH_LLDP_ETH_IFACE}${ethernet_interface}

    ${lldp_state}=  Get From Dictionary  ${resp.dict}  Ethernet
    RETURN  ${lldp_state}

Verify LLDP Configuration State
    [Documentation]  Verify LLDP configuration state.
    [Arguments]  ${lldp_state}

    # Description of argument(s):
    # lldp_state    LLDP state set ('True' or 'False').

    ${resp}=  Redfish.Get  ${REDFISH_LLDP_ETH_IFACE}${ethernet_interface}
    ${lldp_state_expected}=  Get From Dictionary  ${resp.dict}  Ethernet

    IF  '${lldp_state}' != '${lldp_state_expected['LLDPEnabled']}'
        Fail  msg=LLDP value is not set correctly.
    END

Get Interface TLV Value From LLDP Output
    [Documentation]  Parse "lldpcli show interfaces" output for the given
    ...  interface section and return the value of the given TLV
    ...  (e.g. ChassisID, PortID, SysName, MgmtIP, TTL).
    [Arguments]  ${lldpcli_output}  ${interface}  ${tlv_value}

    # Description of argument(s):
    # lldpcli_output    Full text output of "lldpcli show interfaces".
    # interface         Interface name to extract TLV from (e.g. eth0).
    # tlv_value         TLV field name to extract (e.g. ChassisID, PortID).

    ${lldpcli_lines}=  Split To Lines  ${lldpcli_output}
    VAR  ${tlv_result}  ${EMPTY}
    VAR  ${in_iface_section}  ${False}

    FOR  ${lldpcli_line}  IN  @{lldpcli_lines}
        # Detect entry into the target interface section.
        ${is_target_interface_line}=  Run Keyword And Return Status
        ...  Should Match Regexp  ${lldpcli_line}
        ...  Interface:\\s+${interface}\\s*$

        # Detect any interface header to exit the target section.
        ${is_other_interface_line}=  Run Keyword And Return Status
        ...  Should Match Regexp  ${lldpcli_line}
        ...  Interface:\\s+\\w+\\s*$

        IF  ${is_target_interface_line}
            VAR  ${in_iface_section}  ${True}
        ELSE IF  ${is_other_interface_line}
            VAR  ${in_iface_section}  ${False}
        END

        # Within the target interface section, extract the TLV value.
        IF  ${in_iface_section}
            ${is_tlv_line}=  Run Keyword And Return Status
            ...  Should Match Regexp  ${lldpcli_line}  ${tlv_value}:\\s+\\S+

            IF  ${is_tlv_line}
                # Split on whitespace; last token is the TLV value.
                # mac:   "ChassisID: mac xx:xx:xx:xx:xx:xx" -> xx:xx:xx:xx:xx:xx
                # plain: "SysName:   p10bmc"                -> p10bmc
                # num:   "TTL:       120"                   -> 120
                ${lldpcli_line_tokens}=  Split String  ${lldpcli_line}
                ${tlv_result}=  Get From List  ${lldpcli_line_tokens}  -1
                BREAK
            END
        END
    END

    Should Not Be Empty  ${tlv_result}
    ...  msg=TLV "${tlv_value}" not found for ${interface} in lldpcli output.
    RETURN  ${tlv_result}


Get Non Empty LLDP Interfaces Output
    [Documentation]  Run lldpcli show interfaces and fail if output is empty.

    ${lldpcli_output}  ${stderr}  ${rc}=
    ...  BMC Execute Command  ${LLDP_SHOW_INTERFACES}
    Should Not Be Empty  ${lldpcli_output}
    ...  msg=lldpcli show interfaces returned no output; ensure LLDP is enabled.
    RETURN  ${lldpcli_output}


Restore LLDP State And Collect FFDC
    [Documentation]  Restore initial LLDP state and collect FFDC on failure.

    Run Keyword And Continue On Failure
    ...  Set LLDP Configuration State  ${initial_lldp_config['LLDPEnabled']}
    FFDC On Test Case Fail
