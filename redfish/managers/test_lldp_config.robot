*** Settings ***
Documentation  LLDP Test Suite for configuration and verification
               ...  tests.

Resource        ../../lib/bmc_redfish_resource.robot
Resource        ../../lib/bmc_network_utils.robot
Resource        ../../lib/openbmc_ffdc.robot

Suite Setup     Suite Setup Execution
Test Teardown   Test Teardown Execution

Test Tags     LLDP_config

*** Test Cases ***

Enable LLDP And Verify
    [Documentation]  Enable LLDP and verify.
    [Tags]  Enable_LLDP_And_Verify

    # Patch the property ['Ethernet']['LLDPEnabled'] to 'True'.
    Redfish.Patch  ${REDFISH_LLDP_ETH_IFACE}${ethernet_interface}  body={'Ethernet':{'LLDPEnabled': ${True}}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    Verify LLDP Configuration State  ${True}

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup execution.

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}
    Set Suite variable  ${ethernet_interface}

    Redfish.Login
    ${initial_lldp_config}=  Get Initial LLDP Configuration

Get Initial LLDP Configuration
    [Documentation]  Get initial LLDP configuration.

    ${active_channel_config}=  Get Active Channel Config
    ${resp}=  Redfish.Get  ${REDFISH_LLDP_ETH_IFACE}${active_channel_config['${CHANNEL_NUMBER}']['name']}

    ${LLDP_state}=  Get From Dictionary  ${resp.dict}  Ethernet
    Set Suite Variable  ${LLDP_state}

Verify LLDP Configuration State
    [Documentation]  Verify LLDP configuration state.
    [Arguments]  ${state}=${True}

    Run Keyword If  '${LLDP_state["LLDPEnabled"]}' != '${state}'
    ...  Fail  msg=LLDP value is not set correctly.

Test Teardown Execution
    [Documentation]  Test teardown execution.

    FFDC On Test Case Fail
    Redfish.Logout
