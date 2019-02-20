*** Settings ***
Documentation  Test BMC network interface functionalities.

Resource       ../../lib/bmc_redfish_resource.robot
Resource       ../../lib/bmc_network_utils.robot
Resource       ../../lib/openbmc_ffdc.robot
Library        ../../lib/bmc_network_utils.py

Suite Setup    Suite Setup Execution
Test Teardown  redfish.Logout

*** Variables ***

# AA:AA:AA:AA:AA:AA series is a valid MAC and does not exist in
# our network, so this is chosen to avoid MAC conflict.
${valid_mac}         AA:E2:84:14:28:79

*** Test Cases ***

Configure Valid MAC And Verify
    [Documentation]  Configure valid MAC and verify.
    [Tags]  Configure_Valid_MAC_And_Verify

    Configure MAC Settings  ${valid_mac}  valid

    # Verify whether new MAC is configured on BMC.
    Validate MAC On BMC  ${valid_mac}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Network setup.
    redfish.Login

    # Get BMC MAC address.
    ${resp}=  redfish.Get  ${REDFISH_NW_ETH0_URI}
    ${macaddr}=  Get From Dictionary  ${resp.dict}  MACAddress

    Validate MAC On BMC  ${macaddr}
    Set Suite Variable  ${macaddr}

Configure MAC Settings
    [Documentation]  Configure MAC settings.
    [Arguments]  ${mac_addr}  ${expected_result}

    # Description of argument(s):
    # mac_addr         MAC address of BMC.
    # expected_result  Expected status of MAC configuration.

    redfish.Login
    ${payload}=  Create Dictionary  MACAddress=${mac_addr}

    # MAC address configuration is failing at present.
    # Issue: https://github.com/openbmc/bmcweb/issues/43
    # Ignore error is used only for understandng the rest of the code flow.

    ${resp}=  Run Keyword And Ignore Error
    ...  redfish.Patch  ${REDFISH_NW_ETH0_URI}  &{payload}

    # After any modification on network interface, BMC restarts network
    # module, wait until it is reachable.

    Wait For Host To Ping  ${OPENBMC_HOST}
    ...  ${NETWORK_TIMEOUT}  ${NETWORK_RETRY_TIME}

    # Verify whether new MAC address is populated on BMC system.
    # It should not allow to configure invalid settings.

    ${status}=  Run Keyword And Return Status
    ...  Validate MAC On BMC  ${mac_addr}

    Run Keyword If  '${expected_result}' == 'error'
    ...      Should Be Equal  ${status}  ${False}
    ...      msg=Allowing the configuration of an invalid MAC.
    ...  ELSE
    ...      Should Be Equal  ${status}  ${True}
    ...      msg=Not allowing the configuration of a valid MAC.

