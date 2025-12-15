*** Settings ***

Documentation    Module to test IPMI asset tag functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/bmc_network_utils.robot
Resource         ../lib/energy_scale_utils.robot
Variables        ../data/ipmi_raw_cmd_table.py
Variables        ../data/ipmi_variable.py
Library          ../lib/bmc_network_utils.py
Library          ../lib/ipmi_utils.py

Suite Setup      IPMI General Test Suite Setup
Test Teardown    FFDC On Test Case Fail

Test Tags       IPMI_General

*** Test Cases ***

Test Get Self Test Results via IPMI Raw Command
    [Documentation]  Get self test results via IPMI raw command and verify the output.
    [Tags]  Test_Get_Self_Test_Results_via_IPMI_Raw_Command

    ${resp}=  Run IPMI Command  ${IPMI_RAW_CMD['Self_Test_Results']['Get'][0]}

    # 55h = No error. All Self Tests Passed.
    # 56h = Self Test function not implemented in this controller.
    Should Contain Any  ${resp}  55 00  56 00


Test Get Device GUID Via IPMI Raw Command
    [Documentation]  Get device GUID via IPMI raw command and verify it using Redfish.
    [Tags]  Test_Get_Device_GUID_Via_IPMI_Raw_Command
    [Teardown]  Run Keywords  Redfish.Logout  AND  FFDC On Test Case Fail
    # Get GUIDS via IPMI.
    # This should match the /redfish/v1/Managers/${MANAGER_ID}'s UUID data.
    ${guids}=  Run IPMI Command  ${IPMI_RAW_CMD['Device GUID']['Get'][0]}
    # Reverse the order and remove space delims.
    ${guids}=  Split String  ${guids}
    Reverse List  ${guids}
    ${guids}=  Evaluate  "".join(${guids})

    Redfish.Login
    ${uuid}=  Redfish.Get Attribute  /redfish/v1/Managers/${MANAGER_ID}  UUID
    ${uuid}=  Remove String  ${uuid}  -

    Rprint Vars  guids  uuid
    Valid Value  uuid  ['${guids}']


Verify Get Channel Info via IPMI
    [Documentation]  Verify get channel info via IPMI.
    [Tags]  Verify_Get_Channel_Info_via_IPMI

    # Get channel info via ipmi command "ipmitool channel info [channel number]".
    # Verify channel info with files "channel_access_volatile.json", "channel_access_nv.json"
    # and "channel_config.json" in BMC.

    # Example output from 'Get Channel Info':
    # channel_info:
    #   [channel_0x2_info]:
    #     [channel_medium_type]:                        802.3 LAN
    #     [channel_protocol_type]:                      IPMB-1.0
    #     [session_support]:                            multi-session
    #     [active_session_count]:                       0
    #     [protocol_vendor_id]:                         7154
    #   [volatile(active)_settings]:
    #       [alerting]:                                 enabled
    #       [per-message_auth]:                         enabled
    #       [user_level_auth]:                          enabled
    #       [access_mode]:                              always available
    #   [Non-Volatile Settings]:
    #       [alerting]:                                 enabled
    #       [per-message_auth]:                         enabled
    #       [user_level_auth]:                          enabled
    #       [access_mode]:                              always available

    ${channel_info_ipmi}=  Get Channel Info  ${CHANNEL_NUMBER}
    ${active_channel_config}=  Get Active Channel Config
    ${channel_volatile_data_config}=  Get Channel Access Config  /run/ipmi/channel_access_volatile.json
    ${channel_nv_data_config}=  Get Channel Access Config  /var/lib/ipmi/channel_access_nv.json

    Rprint Vars  channel_info_ipmi
    Rprint Vars  active_channel_config
    Rprint Vars  channel_volatile_data_config
    Rprint Vars  channel_nv_data_config

    Valid Value  medium_type_ipmi_conf_map['${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['channel_medium_type']}']
    ...  ['${active_channel_config['${CHANNEL_NUMBER}']['channel_info']['medium_type']}']

    Valid Value  protocol_type_ipmi_conf_map['${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['channel_protocol_type']}']
    ...  ['${active_channel_config['${CHANNEL_NUMBER}']['channel_info']['protocol_type']}']

    Valid Value  channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['session_support']
    ...  ['${active_channel_config['${CHANNEL_NUMBER}']['channel_info']['session_supported']}']

    Valid Value  channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['active_session_count']
    ...  ['${active_channel_config['${CHANNEL_NUMBER}']['active_sessions']}']
    # IPMI Spec: The IPMI Enterprise Number is: 7154 (decimal)
    Valid Value  channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['protocol_vendor_id']  ['7154']

    # Verify volatile(active)_settings
    Valid Value  disabled_ipmi_conf_map['${channel_info_ipmi['volatile(active)_settings']['alerting']}']
    ...  ['${channel_volatile_data_config['${CHANNEL_NUMBER}']['alerting_disabled']}']

    Valid Value  disabled_ipmi_conf_map['${channel_info_ipmi['volatile(active)_settings']['per-message_auth']}']
    ...  ['${channel_volatile_data_config['${CHANNEL_NUMBER}']['per_msg_auth_disabled']}']

    Valid Value  disabled_ipmi_conf_map['${channel_info_ipmi['volatile(active)_settings']['user_level_auth']}']
    ...  ['${channel_volatile_data_config['${CHANNEL_NUMBER}']['user_auth_disabled']}']

    Valid Value  access_mode_ipmi_conf_map['${channel_info_ipmi['volatile(active)_settings']['access_mode']}']
    ...  ['${channel_volatile_data_config['${CHANNEL_NUMBER}']['access_mode']}']

    # Verify Non-Volatile Settings
    Valid Value  disabled_ipmi_conf_map['${channel_info_ipmi['non-volatile_settings']['alerting']}']
    ...  ['${channel_nv_data_config['${CHANNEL_NUMBER}']['alerting_disabled']}']

    Valid Value  disabled_ipmi_conf_map['${channel_info_ipmi['non-volatile_settings']['per-message_auth']}']
    ...  ['${channel_nv_data_config['${CHANNEL_NUMBER}']['per_msg_auth_disabled']}']

    Valid Value  disabled_ipmi_conf_map['${channel_info_ipmi['non-volatile_settings']['user_level_auth']}']
    ...  ['${channel_nv_data_config['${CHANNEL_NUMBER}']['user_auth_disabled']}']

    Valid Value  access_mode_ipmi_conf_map['${channel_info_ipmi['non-volatile_settings']['access_mode']}']
    ...  ['${channel_nv_data_config['${CHANNEL_NUMBER}']['access_mode']}']


Test Get Channel Authentication Capabilities via IPMI
    [Documentation]  Verify channel authentication capabilities via IPMI.
    [Tags]  Test_Get_Channel_Authentication_Capabilities_via_IPMI
    [Template]  Verify Channel Auth Capabilities

    FOR  ${channel}  IN   @{active_channel_list}
        FOR  ${privilege}  IN   4  3  2
            # Input Channel     Privilege Level
            ${channel}          ${privilege}
        END
    END


Test Get Channel Authentication Capabilities IPMI Command For Invalid Channel
    [Documentation]  Verify get channel authentication capabilities for invalid channel.
    [Tags]  Test_Get_Channel_Authentication_Capabilities_IPMI_Command_For_Invalid_Channel
    [Template]  Verify Channel Auth Capabilities For Invalid Channel

    FOR  ${channel}  IN  @{inactive_channel_list}
        # Input Channel
        ${channel}
    END


Verify Get Channel Authentication Capabilities IPMI Raw Command With Invalid Data Length
    [Documentation]  Verify get channel authentication capabilities IPMI raw command with invalid data length.
    [Tags]  Verify_Get_Channel_Authentication_Capabilities_IPMI_Raw_Command_With_Invalid_Data_Length
    [Template]  Verify Channel Auth Command For Invalid Data Length

    # Bytes
    low
    high


Verify Set Session Privilege Level via IPMI Raw Command
    [Documentation]  Set session privilege with given privilege level and verify the response with
    ...              expected level.
    [Tags]  Verify_Set_Session_Privilege_Level_via_IPMI_Raw_Command
    [Template]  Set Session Privilege Level And Verify

    # privilege_level   expected_level
    0x00                04
    0x02                02
    0x03                03
    0x04                04


Verify Set Invalid Session Privilege Level Via IPMI Raw Command
    [Documentation]  Verify set invalid session privilege level via IPMI raw command.
    [Tags]  Verify_Set_Invalid_Session_Privilege_Level_Via_IPMI_Raw_Command
    [Template]  Set Invalid Session Privilege Level And Verify

    # invalid_privilege_level
    0x01
    0x05
    0x06
    0x07
    0x0F


Verify Close Session Via IPMI
    [Documentation]  Verify close session via IPMI.
    [Tags]  Verify_Close_Session_Via_IPMI

    # The "close session command" can be tested with any out-of-band IPMI command.
    # When the session is about to close, it will execute the close session command at the end.

    ${cmd}=  Catenate  mc info -vvv 2>&1 | grep "Closed Session"
    ${cmd_output}=  Run External IPMI Standard Command  ${cmd}

    Should Contain  ${cmd_output}  Closed Session


Verify Chassis Identify via IPMI
    [Documentation]  Set chassis identify using IPMI and verify.
    [Tags]  Verify_Chassis_Identify_via_IPMI
    [Setup]  Redfish.Login
    [Teardown]  Redfish.logout

    # Set to default "chassis identify" and verify that LED blinks for 15s.
    Run IPMI Standard Command  chassis identify
    Verify Identify LED State Via Redfish  True

    Sleep  18s
    Verify Identify LED State Via Redfish  False

    # Set "chassis identify" to 10s and verify that the LED blinks for 10s.
    Run IPMI Standard Command  chassis identify 10
    Verify Identify LED State Via Redfish  True

    Sleep  12s
    Verify Identify LED State Via Redfish  False


Verify Chassis Identify Off And Force Identify On via IPMI
    [Documentation]  Set chassis identify to "off" and "force" using IPMI and verify.
    [Tags]  Verify_Chassis_Identify_Off_And_Force_Identify_On_via_IPMI
    [Setup]  Redfish.Login
    [Teardown]  Redfish.logout

    # Set the LED to "Force Identify On".
    Run IPMI Standard Command  chassis identify force
    Verify Identify LED State Via Redfish  True

    # Set "chassis identify" to 0 and verify that the LED turns off.
    Run IPMI Standard Command  chassis identify 0
    Verify Identify LED State Via Redfish  False


Set Power Cap Value Via IPMI And Verify Using Redfish
    [Documentation]  Set power cap value via IPMI and verify using Redfish.
    [Setup]  Redfish.Login
    [Teardown]  Run Keywords  Set Power Cap Value Via Redfish  ${initial_power_value}  AND  Redfish.Logout
    [Tags]  Set_Power_Cap_Value_Via_IPMI_And_Verify_Using_Redfish

    # Get initial power cap value via Redfish.
    ${power_limit_watts}=  Get System Power Cap Limit
    ${initial_power_value}=  Set Variable  ${power_limit_watts['SetPoint']}

    # Get the allowable min and max power cap value via Redfish.
    ${min_power_value}=  Set Variable  ${power_limit_watts['AllowableMin']}
    ${max_power_value}=  Set Variable  ${power_limit_watts['AllowableMax']}

    # Generate a random power cap value within the allowable range.
    ${random_power_cap}=  Evaluate  random.randint(${min_power_value}, ${max_power_value})  modules=random

    # Set power cap value via IPMI.
    Run Keyword  Run IPMI Standard Command  dcmi power set_limit limit ${random_power_cap}

    # Verify the power cap value with the Redfish value.
    ${updated_power_limits}=  Get System Power Cap Limit
    Should Be Equal  ${updated_power_limits['SetPoint']}  ${random_power_cap}


Verify Power Cap Value Via IPMI
    [Documentation]  Verify the power cap value via IPMI, set to non-zero using Redfish
    ...              if initial power cap value is zero.
    [Tags]  Verify_Power_Cap_Value_Via_IPMI
    [Setup]  Redfish.Login
    [Teardown]  Run Keywords  Set Power Cap Value Via Redfish  ${redfish_power_value}  AND  Redfish.Logout

    # Get power cap value via Redfish.
    ${power_cap_limit}=  Get System Power Cap Limit

    # Get initial power cap value.
    ${redfish_power_value}=  Set Variable  ${power_cap_limit['SetPoint']}

    # Update power cap value via Redfish if the initial power cap value is zero.
    IF  ${redfish_power_value} == 0
        # Get the allowable min and max power cap value via Redfish.
        ${min_power_value}=  Set Variable  ${power_cap_limit['AllowableMin']}
        ${max_power_value}=  Set Variable  ${power_cap_limit['AllowableMax']}

        # Generate a random power cap value within the allowable range.
        ${random_power_cap}=  Evaluate  random.randint(${min_power_value}, ${max_power_value})  modules=random

        # Set power value via Redfish.
        Set Power Cap Value Via Redfish  ${random_power_cap}
        ${redfish_power_value}=  Set Variable  ${random_power_cap}
    END

    # Get power cap value via IPMI.
    ${cmd}=  Catenate  dcmi power get_limit | grep "Power Limit:"
    ${resp}=  Run IPMI Standard Command  ${cmd}

    # The output will be as below.
    # Power Limit:         1472 Watts

    # Truncate power limit: and watts from output.
    ${output_limit}=  Strip String  ${resp}  mode=left  characters=Power Limit:
    ${ipmi_power_cap_value}=  Strip String  ${output_limit}  mode=both  characters= Watts

    # Perform a comparison of power cap values obtained from both IPMI and Redfish.
    ${redfish_power_cap_value}=  Convert To String  ${redfish_power_value}
    Should Be Equal  ${ipmi_power_cap_value}  ${redfish_power_cap_value}


*** Keywords ***

IPMI General Test Suite Setup
    [Documentation]  Get active and inactive/invalid channels from channel_config.json file
    ...              in list type and set it as suite variable.

    # Get active channel list and set as suite variable.
    @{active_channel_list}=  Get Active Ethernet Channel List
    Set Suite Variable  @{active_channel_list}

    # Get Inactive/Invalid channel list and set as suite variable.
    @{inactive_channel_list}=  Get Invalid Channel Number List
    Set Suite Variable  @{inactive_channel_list}


Set Session Privilege Level And Verify
    [Documentation]   Set session privilege with given privilege level and
    ...               verify the response with expected level.
    [Arguments]  ${privilege_level}  ${expected_level}

    # Description of argument(s):
    # privilege_level    Requested Privilege Level.
    # expected_level     New Privilege Level (or present level if
    #                    ‘return present privilege level’ was selected).

    ${resp}=  Run External IPMI Raw Command
    ...  0x06 0x3b ${privilege_level}
    Should Contain  ${resp}  ${expected_level}


Set Invalid Session Privilege Level And Verify
    [Documentation]   Set invalid session privilege level and verify the response.
    [Arguments]  ${privilege_level}

    # Description of argument(s):
    # privilege_level    Requested Privilege Level.

    # Verify requested level exceeds Channel and/or User Privilege Limit.
    ${msg}=  Run Keyword And Expect Error  *  Run External IPMI Raw Command
    ...  0x06 0x3b ${privilege_level}

    # 0x05 is OEM proprietary level.
    IF  ${privilege_level} == 0x05
        Should Contain  ${msg}  Unknown  rsp=0x81
    ELSE
        # According to IPMI spec privilege level except 0x00-0x05, others are
        # reserved. So if we try to set those privilege we will get rsp as
        # 0xcc(Invalid data filed in request)
        Should Contain  ${msg}  Invalid data field in request  rsp=0xcc
    END


Verify Identify LED State Via Redfish
    [Documentation]  Verify that Redfish identify LED system with given state.
    [Arguments]  ${expected_state}

    # Description of argument(s):
    # expected_state  Expected state of Identify LED.

    # Get the following URI(s) and iterate to find the attribute IndicatorLED.
    # Example:
    # /redfish/v1/Systems/system
    # /redfish/v1/Systems/hypervisor

    # Python module:  get_member_list(resource_path)
    ${systems}=  Redfish_Utils.Get Member List  /redfish/v1/Systems
    FOR  ${system}  IN  @{systems}
        ${led_value}=  Redfish.Get Attribute  ${system}  LocationIndicatorActive
        # Get attribute return None if IndicatorLED does not exist in the URI.
        IF  '${led_value}' == 'None'  CONTINUE
        Should Be True  '${led_value}' == '${expected_state}'
    END


Verify Channel Auth Capabilities
    [Documentation]  Verify authentication capabilities for given channel and privilege.
    [Arguments]  ${channel}  ${privilege_level}

    # Description of argument(s):
    # channel           Interface channel number.
    # privilege_level   User Privilege level (e.g. 4-Administator, 3-Operator, 2-Readonly).

    # Python module:  get_channel_auth_capabilities(channel_number, privilege_level)
    ${channel_auth_cap}=  Get Channel Auth Capabilities  ${channel}  ${privilege_level}
    Rprint Vars  channel_auth_cap

    Valid Value  channel_auth_cap['channel_number']  ['${channel}']
    Valid Value  channel_auth_cap['kg_status']  ['default (all zeroes)']
    Valid Value  channel_auth_cap['per_message_authentication']  ['enabled']
    Valid Value  channel_auth_cap['user_level_authentication']  ['enabled']
    Valid Value  channel_auth_cap['non-null_user_names_exist']  ['yes']
    Valid Value  channel_auth_cap['null_user_names_exist']  ['no']
    Valid Value  channel_auth_cap['anonymous_login_enabled']  ['no']
    Valid Value  channel_auth_cap['channel_supports_ipmi_v1.5']  ['no']
    Valid Value  channel_auth_cap['channel_supports_ipmi_v2.0']  ['yes']


Verify Channel Auth Capabilities For Invalid Channel
    [Documentation]  Verify authentication capabilities of invalid channels.
    [Arguments]  ${channel}

    # Description of argument(s):
    # channel   Interface channel number.

    ${channel_in_hex}=  Convert To Hex  ${channel}  prefix=0x
    ${cmd}=  Catenate  ${IPMI_RAW_CMD['Get Channel Auth Cap']['get'][0]} ${channel_in_hex} 0x04

    Verify Invalid IPMI Command  ${cmd}  0xcc


Verify Channel Auth Command For Invalid Data Length
   [Documentation]  Verify channel authentication command for invalid data length.
   [Arguments]  ${byte_length}

   # Description of argument(s):
   # byte_length   high or low.
   #               e.g. high - add extra byte to request data like "0x06 0x38 0x01 0x04 0x01".
   #               low - reduce bytes in actual request data like "0x06 0x38".

   IF  '${byte_length}' == 'low'
        ${req_cmd}=  Catenate  ${IPMI_RAW_CMD['Get Channel Auth Cap']['get'][0]}  ${CHANNEL_NUMBER}
   ELSE
        ${req_cmd}=  Catenate  ${IPMI_RAW_CMD['Get Channel Auth Cap']['get'][0]}
        ...  ${CHANNEL_NUMBER} 0x04 0x01A
   END

   Verify Invalid IPMI Command  ${req_cmd}  0xc7


Set Power Cap Value Via Redfish
    [Documentation]  Set power cap value via Redfish.
    [Arguments]   ${power_cap_value}

    # Description of argument(s):
    # power_cap_value    Power cap value which need to be set.

    # Set power cap value based on argument.
    Redfish.Patch  /redfish/v1/Chassis/${CHASSIS_ID}/EnvironmentMetrics
    ...  body={"PowerLimitWatts":{"SetPoint": ${power_cap_value}}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
