*** Settings ***

Documentation    Module to test IPMI messaging support functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Library          ../lib/ipmi_utils.py
Library          ../lib/bmc_network_utils.py

Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify Get Channel Info via IPMI
    [Documentation]  Verify get channel info via IPMI
    [Tags]  Verify_Get_Channel_Info_via_IPMI

    # Get channel info via ipmi command "ipmitool channel info [channel number]."
    # Verify channel info with files "channel_access.json" and "channel_config.json" in BMC.
    ${channel_info_ipmi}=  Get Channel Info  ${CHANNEL_NUMBER}
    ${active_channel_config}=  Get Active Channel Config
    ${channel_access_config}=  Get channel Access Config
    Rprint Vars  channel_info_ipmi  active_channel_config  channel_access_config

    ${channel_medium_type}=  Get Channel Medium Type Mapping Table
    ...  ${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['channel_medium_type']}
    ${channel_protocol_type}=  Get Channel Protocol Type Mapping Table
    ...  ${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['channel_protocol_type']}

    ${alerting}=  Get Disabled Mapping Table
    ...  ${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['alerting']}
    ${per-message_auth}=  Get Disabled Mapping Table
    ...  ${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['per-message_auth']}
    ${user_level_auth}=  Get Disabled Mapping Table
    ...  ${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['user_level_auth']}
    ${access_mode}=  Get Channel Access Mode Mapping Table
    ...  ${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['access_mode']}

    Valid Value  channel_medium_type
    ...  ['${active_channel_config['${CHANNEL_NUMBER}']['channel_info']['medium_type']}']
    Valid Value  channel_protocol_type
    ...  ['${active_channel_config['${CHANNEL_NUMBER}']['channel_info']['protocol_type']}']
    Valid Value  channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['session_support']
    ...  ['${active_channel_config['${CHANNEL_NUMBER}']['channel_info']['session_supported']}']

    Valid Value  alerting  ['${channel_access_config['${CHANNEL_NUMBER}']['alerting_disabled']}']
    Valid Value  per-message_auth  ['${channel_access_config['${CHANNEL_NUMBER}']['per_msg_auth_disabled']}']
    Valid Value  user_level_auth  ['${channel_access_config['${CHANNEL_NUMBER}']['user_auth_disabled']}']
    Valid Value  access_mode  ['${channel_access_config['${CHANNEL_NUMBER}']['access_mode']}']