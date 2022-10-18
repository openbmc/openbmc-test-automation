*** Settings ***
Documentation    Test BMC Manager functionality.
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/common_utils.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/boot_utils.robot
Resource         ../../lib/open_power_utils.robot
Resource         ../../lib/bmc_network_utils.robot
Library          ../../lib/gen_robot_valid.py

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


*** Variables ***

${SYSTEM_SHUTDOWN_TIME}    ${5}
${OPENBMC_DEFAULT_PASSWORD}    0penBmc

# Strings to check from journald.
${REBOOT_REGEX}    ^\-- Boot | Startup finished

*** Test Cases ***

Verify Redfish BMC Firmware Version
    [Documentation]  Get firmware version from BMC manager.
    [Tags]  Verify_Redfish_BMC_Firmware_Version

    Redfish.Login
    ${resp}=  Redfish.Get  /redfish/v1/Managers/bmc
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
    ${bmc_version}=  Get BMC Version
    Should Be Equal As Strings
    ...  ${resp.dict["FirmwareVersion"]}  ${bmc_version.strip('"')}


Verify Redfish BMC Manager Properties
    [Documentation]  Verify BMC managers resource properties.
    [Tags]  Verify_Redfish_BMC_Manager_Properties

    Redfish.Login
    ${resp}=  Redfish.Get  /redfish/v1/Managers/bmc
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
    # Example:
    #  "Description": "Baseboard Management Controller"
    #  "Id": "bmc"
    #  "Model": "OpenBmc",
    #  "Name": "OpenBmc Manager",
    #  "UUID": "xxxxxxxx-xxx-xxx-xxx-xxxxxxxxxxxx"
    #  "PowerState": "On"

    Should Be Equal As Strings
    ...  ${resp.dict["Description"]}  Baseboard Management Controller
    Should Be Equal As Strings  ${resp.dict["Id"]}  bmc
    Should Be Equal As Strings  ${resp.dict["Name"]}  OpenBmc Manager
    Should Not Be Empty  ${resp.dict["UUID"]}
    Should Be Equal As Strings  ${resp.dict["PowerState"]}  On


Verify MAC Address Property Is Populated
    [Documentation]  Verify BMC managers resource properties.
    [Tags]  Verify_MAC_Address_Property_Is_Populated

    # Get OrderedDict from the BMC which contains active ethernet channel.
    # Example: ([('1', {'name': 'eth0',
    #                   'is_valid': True,
    #                   'active_sessions': 0,
    #                   'channel_info': {'medium_type': 'lan-802.3',
    #                                    'protocol_type': 'ipmb-1.0',
    #                                    'session_supported': 'multi-session',
    #                                    'is_ipmi': True
    #                                   }
    #                  }
    #          )])

    ${active_channel_config}=  Get Active Channel Config

    FOR  ${channel_number}  IN  @{active_channel_config.keys()}
        Log Dictionary  ${active_channel_config["${channel_number}"]}

        # Skip channel if is_valid is false for the channel number
        Continue For Loop If
        ...  ${active_channel_config["${channel_number}"]["is_valid"]}==${FALSE}

        # Get ethernet valid paths in redfish.
        # Example: ['/redfish/v1/Managers/bmc/EthernetInterfaces']
        ${eth_interface}=  redfish_utils.Get Endpoint Path List
        ...  /redfish/v1/Managers/  EthernetInterfaces

        # Get the MACAddress attrivute value with the 'name': 'eth0'.
        # Example: /redfish/v1/Managers/bmc/EthernetInterfaces/eth0
        ${redfish_mac_addr}=  Redfish.Get Attribute
        ...  ${eth_interface[0]}/${active_channel_config["${channel_number}"]["name"]}
        ...  MACAddress
    END

    Rprint Vars  redfish_mac_addr  fmt=terse
    Valid Value  redfish_mac_addr

    ${ipaddr_mac_addr}=  Get BMC MAC Address List
    Rprint Vars  ipaddr_mac_addr  fmt=terse

    List Should Contain Value  ${ipaddr_mac_addr}  ${redfish_mac_addr}


Redfish BMC Manager GracefulRestart When Host Off
    [Documentation]  BMC graceful restart when host is powered off.
    [Tags]  Redfish_BMC_Manager_GracefulRestart_When_Host_Off

    # "Actions": {
    # "#Manager.Reset": {
    #  "ResetType@Redfish.AllowableValues": [
    #    "GracefulRestart",
    #    "ForceRestart"
    #  ],
    #  "target": "/redfish/v1/Managers/bmc/Actions/Manager.Reset"
    # }

    ${test_file_path}=  Set Variable  /tmp/before_bmcreboot
    BMC Execute Command  touch ${test_file_path}

    Redfish Power Off  stack_mode=skip

    Redfish BMC Reset Operation  reset_type=GracefulRestart

    Is BMC Standby

    ${stdout}  ${stderr}  ${rc}=  BMC Execute Command  test ! -f ${test_file_path}  print_out=1
    Verify BMC RTC And UTC Time Drift

    # Check for journald persistency post reboot.
    Wait Until Keyword Succeeds  3 min  10 sec
    ...  Check For Regex In Journald  ${REBOOT_REGEX}  error_check=${1}


Redfish BMC Manager ForceRestart When Host Off
    [Documentation]  BMC force restart when host is powered off.
    [Tags]  Redfish_BMC_Manager_ForceRestart_When_Host_Off

    # "Actions": {
    # "#Manager.Reset": {
    #  "ResetType@Redfish.AllowableValues": [
    #    "GracefulRestart",
    #    "ForceRestart"
    #  ],
    #  "target": "/redfish/v1/Managers/bmc/Actions/Manager.Reset"
    # }

    ${test_file_path}=  Set Variable  /tmp/before_bmcreboot
    BMC Execute Command  touch ${test_file_path}

    Redfish Power Off  stack_mode=skip

    Redfish BMC Reset Operation  reset_type=ForceRestart

    Is BMC Standby

    ${stdout}  ${stderr}  ${rc}=  BMC Execute Command  test ! -f ${test_file_path}  print_out=1
    Verify BMC RTC And UTC Time Drift

    # Check for journald persistency post reboot.
    Wait Until Keyword Succeeds  3 min  10 sec
    ...  Check For Regex In Journald  ${REBOOT_REGEX}  error_check=${1}


Verify Boot Count After BMC Reboot
    [Documentation]  Verify boot count increments on BMC reboot.
    [Tags]  Verify_Boot_Count_After_BMC_Reboot
    [Setup]  Run Keywords  Update NTP Test Initial Status  AND
    ...  Set NTP state  ${TRUE}
    [Teardown]  Restore NTP Status

    Set BMC Boot Count  ${0}
    Redfish OBMC Reboot (off)
    ${boot_count}=  Get BMC Boot Count
    Should Be Equal  ${boot_count}  ${1}  msg=Boot count is not incremented.


Redfish BMC Manager GracefulRestart When Host Booted
    [Documentation]  BMC graceful restart when host is running.
    [Tags]  Redfish_BMC_Manager_GracefulRestart_When_Host_Booted

    Redfish OBMC Reboot (run)

    # TODO: Replace OCC state check with redfish property when available.
    Wait Until Keyword Succeeds  10 min  30 sec  Verify OCC State


Verify Managers Reset To Defaults action
    [Documentation]  Perform reset to defaults action and verify whether BMC
    ...  is restored to default configuration.
    [Tags]  Verify_Managers_Reset_To_Defaults_action
    [Setup]  Ensure Host Power On And Get Bmc Address

    # Set IP address source to static if IP source is not static
    ${initial_ip_address_source}=  Get BMC IP Address Source Via KCS
    Run Keyword If  '${initial_ip_address_source}' != 'Static'  Set Static IP

    # Post some test user data & modify NTP enabled to false
    Redfish Create User  operator_user  TestPwd123  Operator  ${True}
    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}
    ...  body={'NTP':{'ProtocolEnabled': ${False}}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    # Call manager reset to defaults action
    Redfish Reset To Defaults

    # Wait for the reset to default action to initiate
    Wait Until Keyword Succeeds  2 minutes  5 seconds  Is BMC Unpingable

    # Wait for BMC to become accessible
    ${BMC_State}=  Wait Until Keyword Succeeds  10 minutes   30 seconds
    ...  OS Execute Command  ipmitool lan print

    # Verify BMC network status
    Verify BMC LAN Status  Static  ${current_ip_address}

    # Restore to static IP if the initial IP source is static
    Run Keyword If  '${initial_ip_address_source}' == 'Static'
    ...  Set Static IP

    # Ensure Redfish login is not allowed with ${OPENBMC_PASSWORD} since defaults restored
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login

    # Make one-time password change for root account
    Perform First Time Password Change For Root User

    # Verify test user data & NTP state modified are restored to default
    Redfish.Login
    Redfish.Get  /redfish/v1/AccountService/Accounts/operator_user1
    ...  valid_status_codes=[${HTTP_NOT_FOUND}]
    ${NTP}=  Redfish.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  NTP
    Should Be Equal As Strings  ${NTP['ProtocolEnabled']}  True
    ...  NTP.ProtocolEnabled value is not restored to default


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Run Keyword And Ignore Error  redfish.Logout


Update NTP Test Initial Status
    [Documentation]  Update the initial status of NTP.

    Redfish.Login
    ${original_ntp}=  Redfish.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  NTP
    Set Suite Variable  ${original_ntp}


Set NTP state
    [Documentation]  Set NTP service inactive.
    [Arguments]  ${state}

    Redfish.Login
    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body={'NTP':{'ProtocolEnabled': ${state}}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]


Restore NTP Status
    [Documentation]  Restore NTP Status.

    Run Keyword If  '${original_ntp["ProtocolEnabled"]}' == 'True'
    ...    Set NTP state  ${TRUE}
    ...  ELSE  Set NTP state  ${FALSE}


Redfish Create User
    [Documentation]  Redfish create user.
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}  ${login_check}=${True}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role ID of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).
    # login_check         Checks user login for created user.
    #                     (e.g. ${True}, ${False}).

    # Make sure the user account in question does not already exist.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${userName}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    # Create specified user.
    ${payload}=  Create Dictionary
    ...  UserName=${username}  Password=${password}  RoleId=${role_id}  Enabled=${enabled}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    # Resetting faillock count as a workaround for issue
    # openbmc/phosphor-user-manager#4
    ${cmd}=  Catenate  test -f /usr/sbin/faillock && /usr/sbin/faillock --user USER --reset
    ...  || /usr/sbin/pam_tally2 -u ${username} --reset
    Bmc Execute Command  ${cmd}

    # Verify login with created user.
    ${status}=  Run Keyword If  '${login_check}' == '${True}'
    ...  Verify Redfish User Login  ${username}  ${password}
    Run Keyword If  '${login_check}' == '${True}'  Should Be Equal  ${status}  ${enabled}

    # Validate Role ID of created user.
    ${role_config}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/${username}  RoleId
    Should Be Equal  ${role_id}  ${role_config}


Verify Redfish User Login
    [Documentation]  Verify Redfish login with given user id.
    [Teardown]  Run Keywords  Run Keyword And Ignore Error  Redfish.Logout  AND  Redfish.Login
    [Arguments]   ${username}  ${password}

    # Description of argument(s):
    # username            Login username.
    # password            Login password.

    # Logout from current Redfish session.
    # We don't really care if the current session is flushed out since we are going to login
    # with new credential in next.
    Run Keyword And Ignore Error  Redfish.Logout

    ${status}=  Run Keyword And Return Status  Redfish.Login  ${username}  ${password}
    [Return]  ${status}


Redfish Reset To Defaults
    [Documentation]  Post Redfish reset to defaults action for manager.
    [Arguments]   ${ResetToDefaultsType}=ResetAll

    # Description of argument(s):
    # ResetToDefaultsType       Default is ResetAll. When ResetToDefaultsType
    #                           is ResetAll, all settings including network
    #                           and local user names/passwords will be restored
    #                           to factory defaults

    ${payload}=  Create Dictionary  ResetToDefaultsType=${ResetToDefaultsType}
    Redfish.Post  ${REDFISH_BASE_URI}Managers/bmc/Actions/Manager.ResetToDefaults
    ...  body=&{payload}  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]


Ensure Host Power On And Get Bmc Address
    [Documentation]  Ensure the host system is powered on and
    ...  the IP address is accesible.

    Redfish Power On    stack_mode=skip
    ${current_ip_address}=  Get BMC IP Address Via KCS
    Set Suite Variable  ${current_ip_address}


Set Static IP
    [Documentation]  Set current IP as static IP address to BMC active channel.

    # Validating pre-requisite before setting static address
    ${VAR_LIST}=    Create List  OPENBMC_HOST  NETMASK  GATEWAY
    FOR  ${VAR}  IN  @{VAR_LIST}
        Should Not Be Empty  ${${VAR}}  msg=Unable to find variable ${VAR}
    END

    # Set static BMC address from host
    Os Execute Command  ipmitool lan set ${CHANNEL_NUMBER} ipsrc static
    Os Execute Command  ipmitool lan set ${CHANNEL_NUMBER} ipaddr ${OPENBMC_HOST}
    Os Execute Command  ipmitool lan set ${CHANNEL_NUMBER} defgw ipaddr ${GATEWAY}
    Os Execute Command  ipmitool lan set ${CHANNEL_NUMBER} netmask ${NETMASK}

Get BMC IP Address Via KCS
    [Documentation]  Get BMC IP address via KCS interface and return IP address.

    # Sample output of ipmitool lan print
    # Set in Progress         : Set Complete
    # Auth Type Support       :
    # Auth Type Enable        : Callback :
    #                         : User     :
    #                         : Operator :
    #                         : Admin    :
    #                         : OEM      :
    # IP Address Source       : Static Address
    # IP Address              : 10.19.102.19
    # Subnet Mask             : 255.255.255.192
    # MAC Address             : 00:cc:b3:d1:ad:cc
    # Default Gateway IP      : 10.19.102.1
    # Default Gateway MAC     : 00:00:00:00:00:00
    # 802.1q VLAN ID          : Disabled
    # RMCP+ Cipher Suites     : 17
    # Cipher Suite Priv Max   : aaaaaaaaaaaaaaa
    #                         :     X=Cipher Suite Unused
    #                         :     c=CALLBACK
    #                         :     u=USER
    #                         :     o=OPERATOR
    #                         :     a=ADMIN
    #                         :     O=OEM
    # Bad Password Threshold  : Not Available

    ${resp}=  Os Execute Command  ipmitool lan print
    ${ip_address}=  Get Lines Matching Regexp  ${resp[0]}
    ...  IP\\s+Address\\s+:  partial_match=${TRUE}
    @{stripped_ip_address}=  Split String  ${ip_address}  ${SPACE}
    ${current_ip_address}=  Set Variable  ${stripped_ip_address[-1]}
    Return From Keyword  ${current_ip_address}


Get BMC IP Address Source Via KCS
    [Documentation]  Get BMC IP address source via KCS interface and return value.

    ${resp}=  Os Execute Command  ipmitool lan print
    ${ip_address_source}=  Get Lines Matching Regexp  ${resp[0]}
    ...  IP\\s+Address\\s+Source\\s+:  partial_match=${TRUE}
    @{stripped_ip_source}=  Split String  ${ip_address_source}  ${SPACE}
    Return from Keyword  ${stripped_ip_source[-2]}

Verify BMC LAN Status
    [Documentation]  Check the BMC LAN parameters with the expected paramters.
    [Arguments]  ${expected_ip_address_source}  ${expected_ip_address}

    # Description of argument(s):
    # expected_ip_address_source    expected IP address source
    # expected_ip_address           expected IP address

    # Verify whether the specified arguments 'expected_ip_address_source'
    # and 'expected_ip_address' matches the current IP address & source.

    ${ip_address_source}=  Get BMC IP Address Source Via KCS
    ${new_ip_addr}=   Get BMC IP Address Via KCS

    Should Not Contain  ${ip_address_source}  ${expected_ip_address_source}
    Should Not Be Equal As Strings  ${new_ip_addr}  ${expected_ip_address}

Perform First Time Password Change For Root User
    [Documentation]  Get the user id of 'root' user and
    ...  change the default password to ${OPENBMC_PASSWORD}.

    Redfish.Login  root  ${OPENBMC_DEFAULT_PASSWORD}
    ${payload}=  Create Dictionary  Password=${OPENBMC_PASSWORD}
    Redfish.Patch  /redfish/v1/AccountService/Accounts/root
    ...  body=${payload}
    Run Keyword And Ignore Error  Redfish.Logout

Wait For BMC Unreachable
    [Documentation]  Check whether the BMC reset to default is initiated.

    Run Keyword And Expect Error    *  OS Execute Command  ipmitool lan print