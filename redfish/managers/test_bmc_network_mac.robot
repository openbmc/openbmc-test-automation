*** Settings ***
Documentation  Test BMC network interface functionalities.

Resource       ../../lib/bmc_redfish_resource.robot
Resource       ../../lib/bmc_network_utils.robot
Resource       ../../lib/openbmc_ffdc.robot
Library        ../../lib/bmc_network_utils.py

Suite Setup    Suite Setup Execution
Test Teardown  Redfish.Logout

*** Variables ***

# AA:AA:AA:AA:AA:AA series is a valid MAC and does not exist in
# our network, so this is chosen to avoid MAC conflict.
${valid_mac}         AA:E2:84:14:28:79
${zero_mac}          00:00:00:00:00:00
${broadcast_mac}     FF:FF:FF:FF:FF:FF

*** Test Cases ***

Configure Valid MAC And Verify
    [Documentation]  Configure valid MAC via Redfish and verify.
    [Tags]  Configure_Valid_MAC_And_Verify

    Configure MAC Settings  ${valid_mac}  valid

    # Verify whether new MAC is configured on BMC.
    Validate MAC On BMC  ${valid_mac}

Configure Zero MAC And Verify
    [Documentation]  Configure zero MAC via Redfish and verify
    [Tags]  Configure_Zero_MAC_And_Verify

    [Template]  Configure MAC Settings
    # MAC address  scenario
    ${zero_mac}    error

Configure Broadcast MAC And Verify
    [Documentation]  Configure broadcast MAC via Redfish and verify
    [Tags]  Configure_Broadcast_MAC_And_Verify

    [Template]  Configure MAC Settings
    # MAC address    scenario
    ${broadcast_mac}  error


*** Keywords ***

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Redfish.Logout


Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Redfish.Login

    # Get BMC MAC address.
    ${resp}=  redfish.Get  ${REDFISH_NW_ETH0_URI}
    Set Suite Variable  ${initial_mac_address}  ${resp.dict['MACAddress']}

    Validate MAC On BMC  ${initial_mac_address}

    Redfish.Logout

Configure MAC Settings
    [Documentation]  Configure MAC settings via Redfish.
    [Arguments]  ${mac_address}  ${expected_result}

    # Description of argument(s):
    # mac_address      MAC address of BMC.
    # expected_result  Expected status of MAC configuration.

    Redfish.Login
    ${payload}=  Create Dictionary  MACAddress=${mac_address}

    Run Keyword And Ignore Error
    ...  Redfish.Patch  ${REDFISH_NW_ETH0_URI}  body=&{payload}

    # After any modification on network interface, BMC restarts network
    # module, wait until it is reachable.

    Wait For Host To Ping  ${OPENBMC_HOST}
    ...  ${NETWORK_TIMEOUT}  ${NETWORK_RETRY_TIME}

    # Verify whether new MAC address is populated on BMC system.
    # It should not allow to configure invalid settings.

    ${status}=  Run Keyword And Return Status
    ...  Validate MAC On BMC  ${mac_address}

    Run Keyword If  '${expected_result}' == 'error'
    ...      Should Be Equal  ${status}  ${False}
    ...      msg=Allowing the configuration of an invalid MAC.
    ...  ELSE
    ...      Should Be Equal  ${status}  ${True}
    ...      msg=Not allowing the configuration of a valid MAC.

