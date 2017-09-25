*** Settings ***
Documentation  Test BMC network interface functionalities.

Resource  ../lib/rest_client.robot
Resource  ../lib/utils.robot
Resource  ../lib/bmc_network_utils.robot
Resource  ../lib/boot_utils.robot

Library  String
Library  SSHLibrary

Suite Setup  Suite Setup Execution

*** Variables ***

# AA:AA:AA:AA:AA:AA series is a valid MAC and does not exist in
# our network, so this is chosen to avoid MAC conflict.

${valid_mac}         AA:E2:84:14:28:79
${broadcast_mac}     FF:FF:FF:FF:FF:FF
${zero_mac}          00:00:00:00:00:00
${out_of_range_mac}  AA:FF:FF:FF:FF:100
${special_char_mac}  &$:AA:AA:AA:AA:^^

# There will be 6 bytes in MAC address (e.g. xx.xx.xx.xx.xx.xx)
# but trying to configure xx.xx.xx.xx.xx

${less_byte_mac}     AA:AA:AA:AA:BB

# There will be 6 bytes in MAC address (e.g. xx.xx.xx.xx.xx.xx)
# but trying to configure xx.xx.xx.xx.xx.xx.xx

${more_byte_mac}     AA:AA:AA:AA:AA:AA:BB

*** Test Cases ***

Configure Valid MAC And Verify
    [Documentation]  Configure valid MAC and verify.
    [Tags]  Configure_Valid_MAC_And_Verify

    Configure MAC Settings  ${valid_mac}  valid

    # Verify whether new MAC is configured on BMC.
    Validate MAC On BMC  ${valid_mac}

Configure Invalid MAC And Verify
    [Documentation]  Configure invalid MAC address which is a string.
    [Tags]  Configure_Invalid_MAC_And_Verify

    [Template]  Configure MAC Settings
    # MAC Address        Expected_Result
    ${special_char_mac}  error


Configure Out Of Range MAC And Verify
    [Documentation]  Configure out-of-range MAC address.
    [Tags]  Configure_Out_Of_Range_MAC_And_Verify

    [Template]  Configure MAC Settings
    # MAC Address        Expected_Result
    ${out_of_range_mac}  error

Configure Broadcast MAC And Verify
    [Documentation]  Configure broadcast MAC address.
    [Tags]  Configure_Broadcast_MAC_And_Verify

    [Template]  Configure MAC Settings
    # MAC Address     Expected_Result
    ${broadcast_mac}  error

Configure Zero MAC And Verify
    [Documentation]  Configure zero MAC address.
    [Tags]  Configure_Zero_MAC_And_Verify

    [Template]  Configure MAC Settings
    # MAC Address     Expected_Result
    ${zero_mac}  error

Configure More Byte MAC And Verify
    [Documentation]  Configure more byte MAC address.
    [Tags]  Configure_More_Byte_MAC_And_Verify

    [Template]  Configure MAC Settings
    # MAC Address     Expected_Result
    ${more_byte_mac}  error

Configure Less Byte MAC And Verify
    [Documentation]  Configure less byte MAC address.
    [Tags]  Configure_Less_Byte_MAC_And_Verify

    [Template]  Configure MAC Settings
    # MAC Address     Expected_Result
    ${less_byte_mac}  error

Configure Valid MAC And Check Persistency
    [Documentation]  Configure valid MAC and check persistency.
    [Tags]  Configure_Valid_MAC_And_Check_Persistency

    Configure MAC Settings  ${valid_mac}  valid

    # Verify whether new MAC is configured on BMC.
    Validate MAC On BMC  ${valid_mac}

    # Reboot BMC and check whether MAC is persistent.
    OBMC Reboot (off)
    Validate MAC On BMC  ${valid_mac}

Revert To Initial MAC And Verify
    [Documentation]  Revert to initial MAC address.
    [Tags]  Revert_To_Initial_MAC_And_Verify

    Configure MAC Settings  ${macaddr}  valid

    # Verify whether new MAC is configured on BMC.
    Validate MAC On BMC  ${macaddr}

*** Keywords ***

Suite Setup Execution
    [Documentation]  Network setup.
    Open Connection And Login

    # Get BMC MAC address.
    ${macaddr}=  Read Attribute  ${XYZ_NETWORK_MANAGER}/eth0  MACAddress
    Validate MAC On BMC  ${macaddr}
    Set Suite Variable  ${macaddr}

Validate MAC on BMC
    [Documentation]  Validate MAC on BMC.
    [Arguments]  ${mac_addr}

    # Description of argument(s):
    # mac_addr  MAC address of the BMC.

    ${system_mac}=  Get BMC MAC Address

    Should Contain  ${system_mac}  ${mac_addr}
    ...  ignore_case=True  msg=MAC address does not exist.

Configure MAC Settings
    [Documentation]  Configure MAC settings.
    [Arguments]  ${mac_addr}  ${expected_result}

    # Description of argument(s):
    # mac_addr         MAC address of BMC.
    # expected_result  Expected status of MAC configuration.

    ${data}=  Create Dictionary  data=${mac_addr}

    Run Keyword And Ignore Error  OpenBMC Put Request
    ...  ${XYZ_NETWORK_MANAGER}/eth0/attr/MACAddress  data=${data}

    # After any modification on network interface, BMC restarts network
    # module, wait until it is reachable.

    Wait For Host To Ping  ${OPENBMC_HOST}  0.3  10

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

