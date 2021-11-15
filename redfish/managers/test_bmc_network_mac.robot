*** Settings ***
Documentation  Test BMC network interface functionalities.

Resource       ../../lib/bmc_redfish_resource.robot
Resource       ../../lib/bmc_network_utils.robot
Resource       ../../lib/openbmc_ffdc.robot
Library        ../../lib/bmc_network_utils.py

Suite Setup    Suite Setup Execution
Test Teardown  Test Teardown Execution

Force Tags     MAC_Test

*** Variables ***

# AA:AA:AA:AA:AA:AA series is a valid MAC and does not exist in
# our network, so this is chosen to avoid MAC conflict.
${valid_mac}         AA:E2:84:14:28:79
${zero_mac}          00:00:00:00:00:00
${broadcast_mac}     FF:FF:FF:FF:FF:FF
${out_of_range_mac}  AA:FF:FF:FF:FF:100

# There will be 6 bytes in MAC address (e.g. xx.xx.xx.xx.xx.xx).
# Here trying to configure xx.xx.xx.xx.xx
${less_byte_mac}     AA:AA:AA:AA:BB
# Here trying to configure xx.xx.xx.xx.xx.xx.xx
${more_byte_mac}     AA:AA:AA:AA:AA:AA:BB

# MAC address with special characters.
${special_char_mac}  &A:$A:AA:AA:AA:^^

*** Test Cases ***

Configure Valid MAC And Verify
    [Documentation]  Configure valid MAC via Redfish and verify.
    [Tags]  Configure_Valid_MAC_And_Verify

    Configure MAC Settings  ${valid_mac}  valid

    # Verify whether new MAC is configured on BMC and FW_Env.
    Validate MAC On BMC  ${valid_mac}
    Verify MAC Address Via FW_Env  ${valid_mac}  valid

Configure Zero MAC And Verify
    [Documentation]  Configure zero MAC via Redfish and verify.
    [Tags]  Configure_Zero_MAC_And_Verify

    [Template]  Configure MAC Settings
    # MAC address  scenario
    ${zero_mac}    error

Configure Broadcast MAC And Verify
    [Documentation]  Configure broadcast MAC via Redfish and verify.
    [Tags]  Configure_Broadcast_MAC_And_Verify

    [Template]  Configure MAC Settings
    # MAC address    scenario
    ${broadcast_mac}  error

Configure Invalid MAC And Verify
    [Documentation]  Configure invalid MAC address which is a string.
    [Tags]  Configure_Invalid_MAC_And_Verify

    [Template]  Configure MAC Settings
    # MAC Address        Expected_Result
    ${special_char_mac}  error

Configure Valid MAC And Check Persistency
    [Documentation]  Configure valid MAC and check persistency.
    [Tags]  Configure_Valid_MAC_And_Check_Persistency

    Configure MAC Settings  ${valid_mac}  valid

    # Verify whether new MAC is configured on BMC.
    Validate MAC On BMC  ${valid_mac}

    # Reboot BMC and check whether MAC is persistent on BMC and FW_Env.
    OBMC Reboot (off)
    Validate MAC On BMC  ${valid_mac}
    Verify MAC Address Via FW_Env  ${valid_mac}  valid

Configure Invalid MAC And Verify On FW_Env
    [Documentation]  Configure Invalid  MAC via Redfish and verify on FW_Env.
    [Tags]  Configure_Invalid_MAC_And_Verify_On_FW_Env

    [Template]  Configure MAC Settings

    # invalid_MAC        scenario
    ${zero_mac}          error
    ${broadcast_mac}     error
    ${special_char_mac}  error
    ${less_byte_mac}     error

Configure Invalid MAC And Verify Persistency On FW_Env
    [Documentation]  Configure invalid MAC and verify persistency on FW_Env.
    [Tags]  Configure_Invalid_MAC_And_Verify_Persistency_On_FW_Env

    Configure MAC Settings  ${special_char_mac}  error

    # Reboot BMC and check whether MAC is persistent on FW_Env.
    OBMC Reboot (off)
    Verify MAC Address Via FW_Env  ${special_char_mac}  error

Configure Out Of Range MAC And Verify
    [Documentation]  Configure out of range MAC via Redfish and verify.
    [Tags]  Configure_Out_Of_Range_MAC_And_Verify

    Configure MAC Settings  ${out_of_range_mac}  error

    # Verify whether new MAC is configured on FW_Env.
    Verify MAC Address Via FW_Env  ${out_of_range_mac}  error

Configure Less Byte MAC And Verify
    [Documentation]  Configure less byte MAC via Redfish and verify.
    [Tags]  Configure_Less_Byte_MAC_And_Verify

    [Template]  Configure MAC Settings
    # MAC address     scenario
    ${less_byte_mac}  error

Configure More Byte MAC And Verify
    [Documentation]  Configure more byte MAC via Redfish and verify.
    [Tags]  Configure_More_Byte_MAC_And_Verify

    Configure MAC Settings  ${more_byte_mac}  error
    # Verify whether new MAC is configured on FW_Env.
    Verify MAC Address Via FW_Env  ${more_byte_mac}  error

*** Keywords ***

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    # Revert to initial MAC address.
    Configure MAC Settings  ${initial_mac_address}  valid

    # Verify whether new MAC is configured on BMC and FW_Env.
    Validate MAC On BMC  ${initial_mac_address}
    Validate MAC On Fw_Env  ${initial_mac_address}

    FFDC On Test Case Fail
    Redfish.Logout


Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Redfish.Login
    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    # Get BMC MAC address.
    ${resp}=  redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
    Set Suite Variable  ${initial_mac_address}  ${resp.dict['MACAddress']}

    Validate MAC On BMC  ${initial_mac_address}

    Redfish.Logout


Configure MAC Settings
    [Documentation]  Configure MAC settings via Redfish.
    [Arguments]  ${mac_address}  ${expected_result}

    # Description of argument(s):
    # mac_address      MAC address of BMC.
    # expected_result  Expected status of MAC configuration.

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Redfish.Login
    ${payload}=  Create Dictionary  MACAddress=${mac_address}

    Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body=&{payload}
    ...  valid_status_codes=[200, 400, 500]

    # After any modification on network interface, BMC restarts network
    # Note: Network restart takes around 15-18s after patch request processing.
    Sleep  ${NETWORK_TIMEOUT}s

    Redfish.Get  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}

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

    Verify MAC Address Via FW_Env  ${mac_address}  ${expected_result}

Verify MAC Address Via FW_Env
    [Documentation]  Verify MAC address on FW_Env.
    [Arguments]  ${mac_address}  ${expected_result}

    # Description of argument(s):
    # mac_address      MAC address of BMC.
    # expected_result  Expected status of MAC configuration.

    ${status}=  Run Keyword And Return Status
    ...  Validate MAC On FW_Env  ${mac_address}

    Run Keyword If  '${expected_result}' == 'error'
    ...      Should Be Equal  ${status}  ${False}
    ...      msg=Allowing the configuration of an invalid MAC.
    ...  ELSE
    ...      Should Be Equal  ${status}  ${True}
    ...      msg=Not allowing the configuration of a valid MAC.
