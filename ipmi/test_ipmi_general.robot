*** Settings ***

Documentation    Module to test IPMI asset tag functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Variables        ../data/ipmi_raw_cmd_table.py
Variables        ../data/channel_variable.py
Library          ../lib/bmc_network_utils.py
Library          ../lib/ipmi_utils.py

Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify Get DCMI Capabilities
    [Documentation]  Verify get DCMI capabilities command output.
    [Tags]  Verify_Get_DCMI_Capabilities
    ${cmd_output}=  Run IPMI Standard Command  dcmi discover

    @{supported_capabilities}=  Create List
    # Supported DCMI capabilities:
    ...  Mandatory platform capabilties
    ...  Optional platform capabilties
    ...  Power management available
    ...  Managebility access capabilties
    ...  In-band KCS channel available
    # Mandatory platform attributes:
    ...  200 SEL entries
    ...  SEL automatic rollover is enabled
    # Optional Platform Attributes:
    ...  Slave address of device: 0h (8bits)(Satellite/External controller)
    ...  Channel number is 0h (Primary BMC)
    ...  Device revision is 0
    # Manageability Access Attributes:
    ...  Primary LAN channel number: 1 is available
    ...  Secondary LAN channel is not available for OOB
    ...  No serial channel is available

    FOR  ${capability}  IN  @{supported_capabilities}
      Should Contain  ${cmd_output}  ${capability}  ignore_case=True
      ...  msg=Supported DCMI capabilities not present.
    END


Test Get Self Test Results via IPMI Raw Command
    [Documentation]  Get self test results via IPMI raw command and verify the output.
    [Tags]  Test_Get_Self_Test_Results_via_IPMI

    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Self_Test_Results']['Get'][0]}

    # 55h = No error. All Self Tests Passed.
    # 56h = Self Test function not implemented in this controller.
    Should Contain Any  ${resp}  55 00  56 00


Test Get Device GUID Via IPMI Raw Command
    [Documentation]  Get device GUID via IPMI raw command and verify it using Redfish.
    [Tags]  Test_Get_Device_GUID_via_IPMI_and_Verify_via_Redfish
    [Teardown]  Run Keywords  Redfish.Logout  AND  FFDC On Test Case Fail
    # Get GUIDS via IPMI.
    # This should match the /redfish/v1/Managers/bmc's UUID data.
    ${guids}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Device GUID']['Get'][0]}
    # Reverse the order and remove space delims.
    ${guids}=  Split String  ${guids}
    Reverse List  ${guids}
    ${guids}=  Evaluate  "".join(${guids})

    Redfish.Login
    ${uuid}=  Redfish.Get Attribute  /redfish/v1/Managers/bmc  UUID
    ${uuid}=  Remove String  ${uuid}  -

    Rprint Vars  guids  uuid
    Valid Value  uuid  ['${guids}']


Verify Get Channel Info via IPMI
    [Documentation]  Verify get channel info via IPMI
    [Tags]  Verify_Get_Channel_Info_via_IPMI

    # Get channel info via ipmi command "ipmitool channel info [channel number]."
    # Verify channel info with files "channel_access.json" and "channel_config.json" in BMC.

    # Example output from 'Get Channel Info':
    # channel_info:
    #   [channel_0x2_info]:
    #     [channel_medium_type]:                        802.3 LAN
    #     [channel_protocol_type]:                      IPMB-1.0
    #     [session_support]:                            multi-session
    #     [active_session_count]:                       0
    #     [protocol_vendor_id]:                         7154
    #     [volatile(active)_settings]:
    #     [alerting]:                                   enabled
    #     [per-message_auth]:                           enabled
    #     [user_level_auth]:                            enabled
    #     [access_mode]:                                always available

    ${channel_info_ipmi}=  Get Channel Info  ${CHANNEL_NUMBER}
    ${active_channel_config}=  Get Active Channel Config
    ${channel_access_config}=  Get Channel Access Config
    Rprint Vars  channel_info_ipmi  active_channel_config  channel_access_config

    ${channel_medium_type_ipmi}=  Set Variable
    ...  ${medium_type_ipmi_conf_map['${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['channel_medium_type']}']}
    Valid Value  channel_medium_type_ipmi
    ...  ['${active_channel_config['${CHANNEL_NUMBER}']['channel_info']['medium_type']}']

    Valid Value  channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['session_support']
    ...  ['${active_channel_config['${CHANNEL_NUMBER}']['channel_info']['session_supported']}']

    ${channel_protocol_type_ipmi}=  Set Variable
    ...  ${protocol_type_ipmi_conf_map['${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['channel_protocol_type']}']}
    Valid Value  channel_protocol_type_ipmi
    ...  ['${active_channel_config['${CHANNEL_NUMBER}']['channel_info']['protocol_type']}']

    ${alerting_ipmi}=  Set Variable
    ...  ${disabled_ipmi_conf_map['${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['alerting']}']}
    Valid Value  alerting_ipmi
    ...  ['${channel_access_config['${CHANNEL_NUMBER}']['alerting_disabled']}']

    ${per-message_auth_ipmi}=  Set Variable
    ...  ${disabled_ipmi_conf_map['${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['per-message_auth']}']}
    Valid Value  per-message_auth_ipmi
    ...  ['${channel_access_config['${CHANNEL_NUMBER}']['per_msg_auth_disabled']}']

    ${user_level_auth_ipmi}=  Set Variable
    ...  ${disabled_ipmi_conf_map['${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['user_level_auth']}']}
    Valid Value  user_level_auth_ipmi
    ...  ['${channel_access_config['${CHANNEL_NUMBER}']['user_auth_disabled']}']

    ${access_mode_ipmi}=  Set Variable
    ...  ${access_mode_ipmi_conf_map['${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['access_mode']}']}
    Valid Value  access_mode_ipmi
    ...  ['${channel_access_config['${CHANNEL_NUMBER}']['access_mode']}']
