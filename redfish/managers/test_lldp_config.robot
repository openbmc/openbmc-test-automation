*** Settings ***
Documentation  LLDP(Link Layer Discovery Protocol) Test Suite for configuration
               ... and verification tests.

Resource        ../../lib/bmc_redfish_resource.robot
Resource        ../../lib/bmc_network_utils.robot
Resource        ../../lib/openbmc_ffdc.robot

Suite Setup               Suite Setup Execution
Suite Teardown Execution  Redfish.Logout
Test Teardown             FFDC On Test Case Fail

Test Tags     LLDP_config

*** Test Cases ***

Enable LLDP And Verify
    [Documentation]  Enable LLDP and verify.
    [Tags]  Enable_LLDP_And_Verify

    # Set the LLDP enabled property as True.
    Set LLDP Configuration State  ${True}

    # Verify the LLDP state is set true
    Verify LLDP Configuration State  ${True}

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup execution.

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}
    Set Suite variable  ${ethernet_interface}

    Redfish.Login
    ${initial_lldp_config}=  Get Initial LLDP Configuration
    Set Suite Variable  ${initial_lldp_config}

Set LLDP Configuration State
    [Documentation]  Set LLDP configuration state.
    [Arguments]  ${lldp_state}

    # Description of argument(s):
    # lldp_state          LLDP state('True' or 'False').

    Redfish.Patch  ${REDFISH_LLDP_ETH_IFACE}${ethernet_interface}  body={'Ethernet':{'LLDPEnabled': ${lldp_state}}}
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
    # lldp_state          LLDP state set('True' or 'False').

    ${resp}=  Redfish.Get  ${REDFISH_LLDP_ETH_IFACE}${ethernet_interface}
    ${lldp_state_expected}=  Get From Dictionary  ${resp.dict}  Ethernet

    Run Keyword If  '${lldp_state}' != '${lldp_state_expected['LLDPEnabled']}'
    ...  Fail  msg=LLDP value is not set correctly.
