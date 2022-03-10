*** Settings ***
Documentation    Test Redfish AD user configuration.

Library          ../../lib/gen_robot_valid.py
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Library          ../../lib/gen_robot_valid.py
Resource         ../../lib/bmc_network_utils.robot
Resource         ../../lib/bmc_ad_utils.robot

Suite Setup      Suite Setup Execution
Suite Teardown   Run Keywords  Restore AD Privilege  AND  Redfish.Logout
Test Teardown    FFDC On Test Case Fail

Force Tags       AD_Test

*** Variables ***
${old_ad_privilege}     Administrator
&{old_account_service}  &{EMPTY}
&{old_ad_config}        &{EMPTY}
${hostname}             ${EMPTY}
${test_ip}              10.6.6.6
${test_mask}            255.255.255.0
${bmc_console_ad_adding_group_cmd}  groupadd -g 513 osp


*** Test Case ***

Verify AD Configuration Created
    [Documentation]  Verify that AD configuration created.
    [Tags]  Verify_AD_Configuration_Created

    Create AD Configuration
    # Call 'Get AD Configuration' to verify that AD configuration exists.
    Get AD Configuration  ${AD_TYPE}
    Sleep  10s
    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}
    Redfish.Logout
    Redfish.Login


Verify AD Service Disable
    [Documentation]  Verify that AD is disabled and that AD user cannot
    ...  login.
    [Tags]  Verify_AD_Service_Disable

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${AD_TYPE}': {'ServiceEnabled': ${False}}}
    Sleep  15s
    ${resp}=  Run Keyword And Return Status  Redfish.Login  ${AD_USER}
    ...  ${AD_USER_PASSWORD}
    Should Be Equal  ${resp}  ${False}
    ...  msg=AD user was able to login even though the AD service was disabled.
    Redfish.Logout
    Redfish.Login
    # Enabling AD so that AD user works.
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${AD_TYPE}': {'ServiceEnabled': ${True}}}
    Redfish.Logout
    Redfish.Login


Verify AD Login With ServiceEnabled
    [Documentation]  Verify that AD Login with ServiceEnabled.
    [Tags]  Verify_AD_Login_With_ServiceEnabled

    Disable Other AD
    # Actual service enablement.
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${AD_TYPE}': {'ServiceEnabled': ${True}}}
    Sleep  15s
    # After update, AD login.
    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}
    Redfish.Logout
    Redfish.Login


Verify AD Login With Correct AuthenticationType
    [Documentation]  Verify that AD Login with right AuthenticationType.
    [Tags]  Verify_AD_Login_With_Correct_AuthenticationType

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${ad_type}': {'Authentication': {'AuthenticationType':'UsernameAndPassword'}}}
    Sleep  15s
    # After update, AD login.
    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}
    Redfish.Logout
    Redfish.Login


Verify AD Config Update With Incorrect AuthenticationType
    [Documentation]  Verify that invalid AuthenticationType is not updated.
    [Tags]  Verify_AD_Update_With_Incorrect_AuthenticationType

    ${body}=  Catenate  {'${ad_type}': {'Authentication': {'AuthenticationType':'KerberosKeytab'}}}

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body=${body}  valid_status_codes=[400]


Verify AD Login With Correct AD URL
    [Documentation]  Verify AD Login with right AD URL.
    [Tags]  Verify_AD_Login_With_Correct_AD_URL

    Config AD URL  ${AD_SERVER_URI}


Verify AD Config Update With Incorrect AD URL
    [Documentation]  Verify that AD Login fails with invalid AD URL.
    [Tags]  Verify_AD_Config_Update_With_Incorrect_AD_URL
    [Teardown]  Run Keywords  Restore AD URL  AND
    ...  FFDC On Test Case Fail

    Config AD URL  ldap://1.2.3.4/  ${FALSE}

Verify AD Configuration Exist
    [Documentation]  Verify that AD configuration is available.
    [Tags]  Verify_AD_Configuration_Exist

    ${resp}=  Redfish.Get Attribute  ${REDFISH_BASE_URI}AccountService
    ...  ${AD_TYPE}  default=${EMPTY}
    Should Not Be Empty  ${resp}  msg=AD configuration is not defined.


Verify AD User Login
    [Documentation]  Verify that AD user able to login into BMC.
    [Tags]  Verify_AD_User_Login

    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}
    Redfish.Logout
    Redfish.Login


Verify AD Service Available
    [Documentation]  Verify that AD service is available.
    [Tags]  Verify_AD_Service_Available

    @{ad_configuration}=  Get AD Configuration  ${AD_TYPE}
    Should Contain  ${ad_configuration}  LDAPService
    ...  msg=LDAPService is not available.


Verify AD Login Works After BMC Reboot
    [Documentation]  Verify that AD login works after BMC reboot.
    [Tags]  Verify_AD_Login_Works_After_BMC_Reboot

    Redfish OBMC Reboot (off)  
    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}
    Redfish.Logout
    Redfish.Login


Verify AD User With Admin Privilege Able To Do BMC Reboot
    [Documentation]  Verify that AD user with administrator privilege able to do BMC reboot.
    [Tags]  Verify_AD_User_With_Admin_Privilege_Able_To_Do_BMC_Reboot


    Update AD Configuration with AD User Role And Group  ${AD_TYPE}
    ...  ${AD_GROUP_PRIVILEGE}  ${AD_GROUP_NAME}
    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}
    # With AD user and with right privilege trying to do BMC reboot.
    Redfish OBMC Reboot (off)  
    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}
    Redfish.Logout
    Redfish.Login


Verify AD User With Operator Privilege Able To Do Host Poweroff
    [Documentation]  Verify that AD user with operator privilege can do host
    ...  power off.
    [Tags]  Verify_AD_User_With_Operator_Privilege_Able_To_Do_Host_Poweroff
    [Teardown]  Restore AD Privilege

    Update AD Configuration with AD User Role And Group  ${AD_TYPE}
    ...  Operator  ${AD_GROUP_NAME}

    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}
    # Verify that the AD user with operator privilege is able to power the system off.
    Redfish.Post  ${REDFISH_POWER_URI}
    ...  body={'ResetType': 'ForceOff'}   valid_status_codes=[200]
    Redfish.Logout
    Redfish.Login


Verify AccountLockout Attributes Set To Zero
    [Documentation]  Verify that attribute AccountLockoutDuration and
    ...  AccountLockoutThreshold are set to 0.
    [Teardown]  Run Keywords  Restore AccountLockout Attributes  AND
    ...  FFDC On Test Case Fail
    [Tags]  Verify_AccountLockout_Attributes_Set_To_Zero

    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}
    ${old_account_service}=  Redfish.Get Properties
    ...  ${REDFISH_BASE_URI}AccountService
    Rprint Vars  old_account_service
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body=[('AccountLockoutDuration', 0)]
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body=[('AccountLockoutThreshold', 0)]
    Redfish.Logout
    Redfish.Login


Verify AD User With Read Privilege Able To Check Inventory
    [Documentation]  Verify that AD user with read privilege able to
    ...  read firmware inventory.
    [Tags]  Verify_AD_User_With_Read_Privilege_Able_To_Check_Inventory
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND  Restore AD Privilege
    [Template]  Set Read Privilege And Check Firmware Inventory

    ReadOnly


Verify AD User With Read Privilege Should Not Do Host Poweron
    [Documentation]  Verify that AD user with read privilege should not be
    ...  allowed to power on the host.
    [Tags]  Verify_AD_User_With_Read_Privilege_Should_Not_Do_Host_Poweron
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND  Restore AD Privilege
    [Template]  Set Read Privilege And Check Poweron

    ReadOnly


Update AD Group Name And Verify Operations
    [Documentation]  Verify that AD group name update and able to do right
    ...  operations.
    [Tags]  Update_AD_Group_Name_And_Verify_Operations
    [Template]  Update AD Config And Verify Set Host Name
    [Teardown]  Restore AD Privilege

    # ad_group_name             ad_group_privilege  valid_status_codes
    ${AD_GROUP_NAME}            Administrator    [${HTTP_OK}, ${HTTP_NO_CONTENT}]
    ${AD_GROUP_NAME}            Operator         [${HTTP_OK}, ${HTTP_NO_CONTENT}]
    ${AD_GROUP_NAME}            ReadOnly         [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]
    ${AD_GROUP_NAME}            NoAccess         [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]
    Invalid_AD_Group_Name       Administrator    [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]
    Invalid_AD_Group_Name       Operator         [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]
    Invalid_AD_Group_Name       ReadOnly         [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]
    Invalid_AD_Group_Name       NoAccess         [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]


Verify AD BaseDN Update And AD Login
    [Documentation]  Update AD BaseDN of AD configuration and verify
    ...  that AD login works.
    [Tags]  Verify_AD_BaseDN_Update_And_AD_Login


    ${body}=  Catenate  {'${AD_TYPE}': { 'LDAPService': {'SearchSettings':
    ...   {'BaseDistinguishedNames': ['${AD_BASE_DN}']}}}}
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService  body=${body}
    Sleep  15s
    Redfish Verify AD Login


Verify AD BindDN Update And AD Login
    [Documentation]  Update AD BindDN of AD configuration and verify
    ...  that AD login works.
    [Tags]  Verify_AD_BindDN_Update_And_AD_Login

    ${body}=  Catenate  {'${AD_TYPE}': { 'Authentication':
    ...   {'AuthenticationType':'UsernameAndPassword', 'Username':
    ...  '${AD_BIND_DN}'}}}
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService  body=${body}
    Sleep  15s
    Redfish Verify AD Login


Verify AD BindDN Password Update And AD Login
    [Documentation]  Update AD BindDN password of AD configuration and
    ...  verify that AD login works.
    [Tags]  Verify_AD_BindDN_Passsword_Update_And_AD_Login


    ${body}=  Catenate  {'${AD_TYPE}': { 'Authentication':
    ...   {'AuthenticationType':'UsernameAndPassword', 'Password':
    ...  '${AD_BIND_DN_PASSWORD}'}}}
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService  body=${body}
    Sleep  15s
    Redfish Verify AD Login


Verify AD Type Update And AD Login
    [Documentation]  Update AD type of AD configuration and verify
    ...  that AD login works.
    [Tags]  Verify_AD_Type_Update_And_AD_Login

    Disable Other AD
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${AD_TYPE}': {'ServiceEnabled': ${True}}}
    Sleep  15s
    Redfish Verify AD Login


Verify Authorization With Null Privilege
    [Documentation]  Verify the failure of AD authorization with empty
    ...  privilege.
    [Tags]  Verify_AD_Authorization_With_Null_Privilege
    [Teardown]  Restore AD Privilege

    Update AD Config And Verify Set Host Name  ${AD_GROUP_NAME}  ${EMPTY}
    ...  [${HTTP_FORBIDDEN}]


Verify Authorization With Invalid Privilege
    [Documentation]  Verify that AD user authorization with wrong privilege
    ...  fails.
    [Tags]  Verify_AD_Authorization_With_Invalid_Privilege
    [Teardown]  Restore AD Privilege

    Update AD Config And Verify Set Host Name  ${AD_GROUP_NAME}
    ...  Invalid_Privilege  [${HTTP_FORBIDDEN}]


Verify AD Login With Invalid Data
    [Documentation]  Verify that AD login with Invalid AD data and
    ...  right AD user fails.
    [Tags]  Verify_AD_Login_With_Invalid_Data
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Create AD Configuration

    Create AD Configuration  ${AD_TYPE}  Invalid_AD_Server_URI
    ...  Invalid_AD_BIND_DN  AD_BIND_DN_PASSWORD
    ...  Invalid_AD_BASE_DN
    Sleep  15s
    Redfish Verify AD Login  ${False}


Verify AD Config Creation Without BASE_DN
    [Documentation]  Verify that AD login with AD configuration
    ...  created without BASE_DN fails.
    [Tags]  Verify_AD_Config_Creation_Without_BASE_DN
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Create AD Configuration

    Create AD Configuration  ${AD_TYPE}  ${AD_SERVER_URI}
    ...  ${AD_BIND_DN}  ${AD_BIND_DN_PASSWORD}  ${EMPTY}
    Sleep  15s
    Redfish Verify AD Login  ${False}


Verify AD Authentication Without Password
    [Documentation]  Verify that AD user authentication without AD
    ...  user password fails.
    [Tags]  Verify_AD_Authentication_Without_Password
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login

    ${status}=  Run Keyword And Return Status  Redfish.Login  ${AD_USER}
    Valid Value  status  [${False}]


Verify AD Login With Invalid BASE_DN
    [Documentation]  Verify that AD login with invalid BASE_DN and
    ...  valid AD user fails.
    [Tags]  Verify_AD_Login_With_Invalid_BASE_DN
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Create AD Configuration

    Create AD Configuration  ${AD_TYPE}  ${AD_SERVER_URI}
    ...  ${AD_BIND_DN}  ${AD_BIND_DN_PASSWORD}  Invalid_AD_BASE_DN
    Sleep  15s
    Redfish Verify AD Login  ${False}


Verify AD Login With Invalid BIND_DN_PASSWORD
    [Documentation]  Verify that AD login with invalid BIND_DN_PASSWORD and
    ...  valid AD user fails.
    [Tags]  Verify_AD_Login_With_Invalid_BIND_DN_PASSWORD
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Create AD Configuration

    Create AD Configuration  ${AD_TYPE}  ${AD_SERVER_URI}
    ...  ${AD_BIND_DN}  INVALID_AD_BIND_DN_PASSWORD  ${AD_BASE_DN}
    Sleep  15s
    Redfish Verify AD Login  ${False}


Verify AD Login With Invalid BASE_DN And Invalid BIND_DN
    [Documentation]  Verify that AD login with invalid BASE_DN and invalid
    ...  BIND_DN and valid AD user fails.
    [Tags]  Verify_AD_Login_With_Invalid_BASE_DN_And_Invalid_BIND_DN
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Create AD Configuration

    Create AD Configuration  ${AD_TYPE}  ${AD_SERVER_URI}
    ...  INVALID_AD_BIND_DN  ${AD_BIND_DN_PASSWORD}  INVALID_AD_BASE_DN
    Sleep  15s
    Redfish Verify AD Login  ${False}


Verify Group Name And Group Privilege Able To Modify
    [Documentation]  Verify that AD group name and group privilege able to
    ...  modify.
    [Tags]  Verify_Group_Name_And_Group_Privilege_Able_To_Modify
    [Setup]  Update AD Configuration with AD User Role And Group
    ...  ${AD_TYPE}  Operator  ${AD_GROUP_NAME}

    Update AD Configuration with AD User Role And Group  ${AD_TYPE}
    ...  Administrator  ${AD_GROUP_NAME}


Verify AD Login With Invalid BIND_DN
    [Documentation]  Verify that AD login with invalid BIND_DN and
    ...  valid AD user fails.
    [Tags]  Verify_AD_Login_With_Invalid_BIND_DN
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Create AD Configuration

    Create AD Configuration  ${AD_TYPE}  ${AD_SERVER_URI}
    ...  Invalid_AD_BIND_DN  ${AD_BIND_DN_PASSWORD}  ${AD_BASE_DN}
    Sleep  15s
    Redfish Verify AD Login  ${False}


Verify AD Authentication With Invalid AD User
    [Documentation]  Verify that AD user authentication for user not exist
    ...  in AD server and fails.
    [Tags]  Verify_AD_Authentication_With_Invalid_AD_User
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login

    ${status}=  Run Keyword And Return Status  Redfish.Login  INVALID_AD_USER
    ...  ${AD_USER_PASSWORD}
    Valid Value  status  [${False}]


Update AD User Roles And Verify Host Poweroff Operation
    [Documentation]  Update AD user roles and verify host poweroff operation.
    [Tags]  Update_AD_User_Roles_And_Verify_Host_Poweroff_Operation
    [Teardown]  Restore AD Privilege

    [Template]  Update AD User Role And Host Poweroff
    # ad_type   ad_group_privilege  ad_group_name     valid_status_codes

    # Verify AD user with NoAccess privilege not able to do host poweroff.
    ${AD_TYPE}  NoAccess         ${AD_GROUP_NAME}  ${HTTP_FORBIDDEN}

    # Verify AD user with ReadOnly privilege not able to do host poweroff.
    ${AD_TYPE}  ReadOnly         ${AD_GROUP_NAME}  ${HTTP_FORBIDDEN}

    # Verify AD user with Operator privilege able to do host poweroff.
    ${AD_TYPE}  Operator         ${AD_GROUP_NAME}  ${HTTP_OK}

    # Verify AD user with Administrator privilege able to do host poweroff.
    ${AD_TYPE}  Administrator    ${AD_GROUP_NAME}  ${HTTP_OK}


Update AD User Roles And Verify Host Poweron Operation
    [Documentation]  Update AD user roles and verify host poweron operation.
    [Tags]  Update_AD_User_Roles_And_Verify_Host_Poweron_Operation
    [Teardown]  Restore AD Privilege

    [Template]  Update AD User Role And Host Poweron
    # ad_type   ad_group_privilege  ad_group_name     valid_status_codes

    # Verify AD user with NoAccess privilege not able to do host poweron.
    ${AD_TYPE}  NoAccess         ${AD_GROUP_NAME}  ${HTTP_FORBIDDEN}

    # Verify AD user with ReadOnly privilege not able to do host poweron.
    ${AD_TYPE}  ReadOnly         ${AD_GROUP_NAME}  ${HTTP_FORBIDDEN}

    # Verify AD user with Operator privilege able to do host poweron.
    ${AD_TYPE}  Operator         ${AD_GROUP_NAME}  ${HTTP_OK}

    # Verify AD user with Administrator privilege able to do host poweron.
    ${AD_TYPE}  Administrator    ${AD_GROUP_NAME}  ${HTTP_OK}


Configure IP Address Via Different User Roles And Verify
    [Documentation]  Configure IP address via different user roles and verify.
    [Tags]  Configure_IP_Address_Via_Different_User_Roles_And_Verify
    [Teardown]  Restore AD Privilege

    [Template]  Update AD User Role And Configure IP Address
    # Verify AD user with Administrator privilege is able to configure IP address.
    ${AD_TYPE}  Administrator    ${AD_GROUP_NAME}  ${HTTP_OK}

    # Verify AD user with ReadOnly privilege is forbidden to configure IP address.
    ${AD_TYPE}  ReadOnly         ${AD_GROUP_NAME}  ${HTTP_FORBIDDEN}

    # Verify AD user with NoAccess privilege is forbidden to configure IP address.
    ${AD_TYPE}  NoAccess         ${AD_GROUP_NAME}  ${HTTP_FORBIDDEN}

    # Verify AD user with Operator privilege is able to configure IP address.
    ${AD_TYPE}  Operator         ${AD_GROUP_NAME}  ${HTTP_OK}


Delete IP Address Via Different User Roles And Verify
    [Documentation]  Delete IP address via different user roles and verify.
    [Tags]  Delete_IP_Address_Via_Different_User_Roles_And_Verify
    [Teardown]  Run Keywords  Restore AD Privilege  AND  FFDC On Test Case Fail

    [Template]  Update AD User Role And Delete IP Address
    # Verify AD user with Administrator privilege is able to delete IP address.
    ${AD_TYPE}  Administrator    ${AD_GROUP_NAME}  ${HTTP_OK}

    # Verify AD user with ReadOnly privilege is forbidden to delete IP address.
    ${AD_TYPE}  ReadOnly         ${AD_GROUP_NAME}  ${HTTP_FORBIDDEN}

    # Verify AD user with NoAccess privilege is forbidden to delete IP address.
    ${AD_TYPE}  NoAccess         ${AD_GROUP_NAME}  ${HTTP_FORBIDDEN}

    # Verify AD user with Operator privilege is able to delete IP address.
    ${AD_TYPE}  Operator         ${AD_GROUP_NAME}  ${HTTP_OK}


Read Network Configuration Via Different User Roles And Verify
    [Documentation]  Read network configuration via different user roles and verify.
    [Tags]  Read_Network_configuration_Via_Different_User_Roles_And_Verify
    [Teardown]  Restore AD Privilege

    [Template]  Update AD User Role And Read Network Configuration
    ${AD_TYPE}  Administrator  ${AD_GROUP_NAME}  ${HTTP_OK}

    ${AD_TYPE}  ReadOnly       ${AD_GROUP_NAME}  ${HTTP_OK}

    ${AD_TYPE}  NoAccess       ${AD_GROUP_NAME}  ${HTTP_FORBIDDEN}

    ${AD_TYPE}  Operator       ${AD_GROUP_NAME}  ${HTTP_OK}


*** Keywords ***

Redfish Verify AD Login
    [Documentation]  AD user log into BMC.
    [Arguments]  ${valid_status}=${True}

    # Description of argument(s):
    # valid_status  Expected status of AD login ("True" or "False").

    # According to our repo coding rules, Redfish.Login is to be done in Suite
    # Setup and Redfish.Logout is to be done in Suite Teardown.  For any
    # deviation from this rule (such as in this keyword), the deviant code
    # must take steps to restore us to our original logged-in state.

    ${status}=  Run Keyword And Return Status  Redfish.Login  ${AD_USER}
    ...  ${AD_USER_PASSWORD}
    Valid Value  status  [${valid_status}]
    Redfish.Logout
    Redfish.Login


Update AD Config And Verify Set Host Name
    [Documentation]  Update AD config and verify by attempting to set host name.
    [Arguments]  ${ad_group_name}  ${ad_group_privilege}=Administrator
    ...  ${valid_status_codes}=[${HTTP_OK}]
    [Teardown]  Run Keyword If  '${group_privilege}'=='NoAccess'  Redfish.Login
                ...  ELSE  Run Keywords  Redfish.Logout  AND  Redfish.Login


    # Description of argument(s):
    # ad_group_name                    The group name of user.
    # ad_group_privilege               The group privilege ("Administrator",
    #                               "Operator", "User" or "Callback").
    # valid_status_codes            Expected return code(s) from patch
    #                               operation (e.g. "200") used to update
    #                               HostName.  See prolog of rest_request
    #                               method in redfish_plut.py for details.
    Update AD Configuration with AD User Role And Group  ${AD_TYPE}
    ...  ${ad_group_privilege}  ${ad_group_name}

    Run Keyword If  '${group_privilege}'=='NoAccess'  Verify redfish Login for AD userRole NoAccess
    ...  ELSE  Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}

    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}
    # Verify that the AD user in ${ad_group_name} with the given privilege is
    # allowed to change the hostname.
    Redfish.Patch  ${REDFISH_NW_ETH0_URI}  body={'HostName': '${hostname}'}
    ...  valid_status_codes=${valid_status_codes}


Verify redfish Login for AD userRole NoAccess
    [Documentation]  Verifying redfish Login should not login for LDAP userRole NoAccess.

    ${status}=  Run Keyword And Return Status  Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}
    Valid Value  status  [${False}


Disable Other AD
    [Documentation]  Disable other AD configuration.

    # First disable other LDAP.
    ${inverse_ldap_type}=  Set Variable If  '${AD_TYPE}' == 'ActiveDirectory'  ActiveDirectory  LDAP
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${inverse_ldap_type}': {'ServiceEnabled': ${False}}}
    Sleep  15s


Config AD URL
    [Documentation]  Config AD URL.
    [Arguments]  ${ad_server_uri}=${AD_SERVER_URI}  ${expected_status}=${TRUE}

    # Description of argument(s):
    # ad_server_uri AD server uri (e.g. "ad://XX.XX.XX.XX/").

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${ad_type}': {'ServiceAddresses': ['${ad_server_uri}']}}
    Sleep  15s
    # After update, AD login.
    ${status}=  Run Keyword And Return Status  Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}
    Valid Value  status  [${expected_status}]

    Redfish.Logout
    Redfish.Login


Restore AD URL
    [Documentation]  Restore AD URL.

    # Restoring the working AD server uri.
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${ad_type}': {'ServiceAddresses': ['${AD_SERVER_URI}']}}
    Sleep  15s


Restore AccountLockout Attributes
    [Documentation]  Restore AccountLockout Attributes.

    Return From Keyword If  &{old_account_service} == &{EMPTY}
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body=[('AccountLockoutDuration', ${old_account_service['AccountLockoutDuration']})]
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body=[('AccountLockoutDuration', ${old_account_service['AccountLockoutThreshold']})]


Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Valid Value  AD_TYPE  valid_values=["ActiveDirectory", "AD"]
    Valid Value  AD_USER
    Valid Value  AD_USER_PASSWORD
    Valid Value  AD_GROUP_PRIVILEGE
    Valid Value  AD_GROUP_NAME
    Valid Value  AD_SERVER_URI
    Valid Value  AD_BIND_DN_PASSWORD
    Valid Value  AD_BIND_DN
    Valid Value  AD_BASE_DN

    Redfish.Login
    # Call 'Get AD Configuration' to verify that AD configuration exists.
    Get AD Configuration  ${AD_TYPE}
    Set Suite Variable  ${old_ad_privilege}
    Disable Other AD
    Create AD Configuration
    ${hostname}=  Redfish.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  HostName


Set Read Privilege And Check Firmware Inventory
    [Documentation]  Set read privilege and check firmware inventory.
    [Arguments]  ${read_privilege}

    # Description of argument(s):
    # read_privilege  The read privilege role (e.g. "User" / "Callback").

    Update AD Configuration with AD User Role And Group  ${AD_TYPE}
    ...  ${read_privilege}  ${AD_GROUP_NAME}

    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}
    # Verify that the AD user with read privilege is able to read inventory.
    ${resp}=  Redfish.Get  /redfish/v1/UpdateService/FirmwareInventory
    Should Be True  ${resp.dict["Members@odata.count"]} >= ${1}
    Length Should Be  ${resp.dict["Members"]}  ${resp.dict["Members@odata.count"]}
    Redfish.Logout
    Redfish.Login


Set Read Privilege And Check Poweron
    [Documentation]  Set read privilege and power on should not be possible.
    [Arguments]  ${read_privilege}

    # Description of argument(s):
    # read_privilege  The read privilege role (e.g. "User" / "Callback").

    Update AD Configuration with AD User Role And Group  ${AD_TYPE}
    ...  ${read_privilege}  ${AD_GROUP_NAME}
    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}
    Redfish.Post  ${REDFISH_POWER_URI}
    ...  body={'ResetType': 'On'}   valid_status_codes=[401, 403]
    Redfish.Logout
    Redfish.Login


Get AD Configuration
    [Documentation]  Retrieve AD Configuration.
    [Arguments]   ${ad_type}

    # Description of argument(s):
    # ad_type  The AD type ("ActiveDirectory" or "AD").

    ${ad_config}=  Redfish.Get Properties  ${REDFISH_BASE_URI}AccountService
    [Return]  ${ad_config["${ad_type}"]}


Update AD Configuration with AD User Role And Group
    [Documentation]  Update AD configuration update with AD user Role and group.
    [Arguments]   ${ad_type}  ${ad_group_privilege}  ${ad_group_name}

    # Description of argument(s):
    # ad_type        The AD type ("ActiveDirectory" or "AD").
    # ad_group_privilege  The group privilege ("Administrator", "Operator", "User" or "Callback").
    # ad_group_name       The group name of user.

    ${local_role_remote_group}=  Create Dictionary  LocalRole=${ad_group_privilege}  RemoteGroup=${ad_group_name}
    ${remote_role_mapping}=  Create List  ${local_role_remote_group}
    ${ad_data}=  Create Dictionary  RemoteRoleMapping=${remote_role_mapping}
    ${payload}=  Create Dictionary  ${ad_type}=${ad_data}
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService  body=&{payload}
    # Provide adequate time for AD daemon to restart after the update.
    Sleep  15s


Get AD Privilege
    [Documentation]  Get AD privilege and return it.

    ${ad_config}=  Get AD Configuration  ${AD_TYPE}
    ${num_list_entries}=  Get Length  ${ad_config["RemoteRoleMapping"]}
    Return From Keyword If  ${num_list_entries} == ${0}  @{EMPTY}

    [Return]  ${ad_config["RemoteRoleMapping"][0]["LocalRole"]}


Restore AD Privilege
    [Documentation]  Restore the AD privilege to its original value.

    Redfish.Login
    Return From Keyword If  '${old_ad_privilege}' == '${EMPTY}' or '${old_ad_privilege}' == '[]'
    # Log back in to restore the original privilege.
    Update AD Configuration with AD User Role And Group  ${AD_TYPE}
    ...  ${old_ad_privilege}  ${AD_GROUP_NAME}

    Sleep  18s

Verify Host Power Status
    [Documentation]  Verify the Host power status and do host power on/off respectively.
    [Arguments]  ${expected_power_status}

    ${power_status}=  Redfish.Get Attribute  /redfish/v1/Chassis/${CHASSIS_ID}  PowerState
    Return From Keyword If  '${power_status}' == '${expected_power_status}'

    Run Keyword If  '${power_status}' == 'Off'  Redfish Power On
    ...  ELSE  Redfish Power Off

Update AD User Role And Host Poweroff
    [Documentation]  Update AD user role and do host poweroff.
    [Arguments]  ${ad_type}  ${ad_group_privilege}  ${ad_group_name}  ${valid_status_code}
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login

    # Description of argument(s):
    # ad_type          The AD type ("ActiveDirectory" or "AD").
    # ad_group_privilege    The group privilege ("Administrator", "Operator", "ReadOnly" or "NoAccess").
    # ad_group_name         The group name of user.
    # valid_status_code  The expected valid status code.

    Verify Host Power Status  On

    Update AD Configuration with AD User Role And Group  ${ad_type}
    ...  ${ad_group_privilege}  ${ad_group_name}

    ${status}=  Run Keyword And Return Status  Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}

    Redfish.Post  ${REDFISH_POWER_URI}
    ...  body={'ResetType': 'ForceOff'}   valid_status_codes=[${valid_status_code}]


Update AD User Role And Host Poweron
    [Documentation]  Update AD user role and do host poweron.
    [Arguments]  ${ad_type}  ${ad_group_privilege}  ${ad_group_name}  ${valid_status_code}
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login

    # Description of argument(s):
    # ad_type          The AD type ("ActiveDirectory" or "AD").
    # ad_group_privilege    The group privilege ("Administrator", "Operator", "ReadOnly" or "NoAccess").
    # ad_group_name         The group name of user.
    # valid_status_code  The expected valid status code.

    Verify Host Power Status  Off

    Update AD Configuration with AD User Role And Group  ${ad_type}
    ...  ${ad_group_privilege}  ${ad_group_name}

    ${status}=  Run Keyword And Return Status  Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}

    Redfish.Post  ${REDFISH_POWER_URI}
    ...  body={'ResetType': 'On'}   valid_status_codes=[${valid_status_code}]


Update AD User Role And Configure IP Address
    [Documentation]  Update AD user role and configure IP address.
    [Arguments]  ${ad_type}  ${ad_group_privilege}  ${ad_group_name}  ${valid_status_code}=${HTTP_OK}
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login  AND  Delete IP Address  ${test_ip}

    # Description of argument(s):
    # ad_type          The AD type ("ActiveDirectory" or "AD").
    # ad_group_privilege    The group privilege ("Administrator", "Operator", "ReadOnly" or "NoAccess").
    # ad_group_name         The group name of user.
    # valid_status_code  The expected valid status code.

    Update AD Configuration with AD User Role And Group  ${ad_type}
    ...  ${ad_group_privilege}  ${ad_group_name}

    Redfish.Logout

    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}

    ${test_gateway}=  Get BMC Default Gateway

    Run Keyword If  '${ad_group_privilege}' == 'NoAccess'
    ...  Add IP Address With NoAccess User  ${test_ip}  ${test_mask}  ${test_gateway}  ${valid_status_code}
    ...  ELSE
    ...  Add IP Address  ${test_ip}  ${test_mask}  ${test_gateway}  ${valid_status_code}


Update AD User Role And Delete IP Address
    [Documentation]  Update AD user role and delete IP address.
    [Arguments]  ${ad_type}  ${ad_group_privilege}  ${ad_group_name}  ${valid_status_code}=${HTTP_OK}
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login  AND  Delete IP Address  ${test_ip}

    # Description of argument(s):
    # ad_type          The AD type ("ActiveDirectory" or "AD").
    # ad_group_privilege    The group privilege ("Administrator", "Operator", "ReadOnly" or "NoAccess").
    # ad_group_name         The group name of user.
    # valid_status_code  The expected valid status code.

    ${test_gateway}=  Get BMC Default Gateway

    # Configure IP address before deleting via AD user roles.
    Add IP Address  ${test_ip}  ${test_mask}  ${test_gateway}

    Update AD Configuration with AD User Role And Group  ${ad_type}
    ...  ${ad_group_privilege}  ${ad_group_name}

    Redfish.Logout

    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}

    Run Keyword If  '${ad_group_privilege}' == 'NoAccess'
    ...  Delete IP Address With NoAccess User  ${test_ip}  ${valid_status_code}
    ...  ELSE
    ...  Delete IP Address  ${test_ip}  ${valid_status_code}


Update AD User Role And Read Network Configuration
    [Documentation]  Update AD user role and read network configuration.
    [Arguments]  ${ad_type}  ${ad_group_privilege}  ${ad_group_name}  ${valid_status_code}=${HTTP_OK}
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login

    # Description of argument(s):
    # ad_type          The AD type ("ActiveDirectory" or "AD").
    # ad_group_privilege    The group privilege ("Administrator", "Operator", "ReadOnly" or "NoAccess").
    # ad_group_name         The group name of user.
    # valid_status_code  The expected valid status code.

    Update AD Configuration with AD User Role And Group  ${ad_type}
    ...  ${ad_group_privilege}  ${ad_group_name}

    Redfish.Logout

    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}
    Redfish.Get  ${REDFISH_NW_ETH0_URI}  valid_status_codes=[${valid_status_code}]


Add IP Address With NoAccess User
    [Documentation]  Add IP Address To BMC.
    [Arguments]  ${ip}  ${subnet_mask}  ${gateway}
    ...  ${valid_status_codes}=${HTTP_OK}

    # Description of argument(s):
    # ip                  IP address to be added (e.g. "10.7.7.7").
    # subnet_mask         Subnet mask for the IP to be added
    #                     (e.g. "255.255.0.0").
    # gateway             Gateway for the IP to be added (e.g. "10.7.7.1").
    # valid_status_codes  Expected return code from patch operation
    #                     (e.g. "200").  See prolog of rest_request
    #                     method in redfish_plus.py for details.

    # Logout from AD user.
    Redfish.Logout

    # Login with local user.
    Redfish.Login

    ${empty_dict}=  Create Dictionary
    ${ip_data}=  Create Dictionary  Address=${ip}
    ...  SubnetMask=${subnet_mask}  Gateway=${gateway}

    ${patch_list}=  Create List
    ${network_configurations}=  Get Network Configuration
    ${num_entries}=  Get Length  ${network_configurations}

    FOR  ${INDEX}  IN RANGE  0  ${num_entries}
      Append To List  ${patch_list}  ${empty_dict}
    END

    ${valid_status_codes}=  Run Keyword If  '${valid_status_codes}' == '${HTTP_OK}'
    ...  Set Variable   ${HTTP_OK},${HTTP_NO_CONTENT}
    ...  ELSE  Set Variable  ${valid_status_codes}

    # We need not check for existence of IP on BMC while adding.
    Append To List  ${patch_list}  ${ip_data}
    ${data}=  Create Dictionary  IPv4StaticAddresses=${patch_list}

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    # Logout from local user.
    Redfish.Logout

    # Login from AD user and check if we can configure IP address.
    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}

    Redfish.patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body=&{data}
    ...  valid_status_codes=[${valid_status_codes}]


Delete IP Address With NoAccess User
    [Documentation]  Delete IP Address Of BMC.
    [Arguments]  ${ip}  ${valid_status_codes}=${HTTP_OK}

    # Description of argument(s):
    # ip                  IP address to be deleted (e.g. "10.7.7.7").
    # valid_status_codes  Expected return code from patch operation
    #                     (e.g. "200").  See prolog of rest_request
    #                     method in redfish_plus.py for details.

    # Logout from AD user.
    Redfish.Logout

    # Login with local user.
    Redfish.Login

    ${empty_dict}=  Create Dictionary
    ${patch_list}=  Create List

    @{network_configurations}=  Get Network Configuration
    FOR  ${network_configuration}  IN  @{network_configurations}
      Run Keyword If  '${network_configuration['Address']}' == '${ip}'
      ...  Append To List  ${patch_list}  ${null}
      ...  ELSE  Append To List  ${patch_list}  ${empty_dict}
    END

    ${ip_found}=  Run Keyword And Return Status  List Should Contain Value
    ...  ${patch_list}  ${null}  msg=${ip} does not exist on BMC
    Pass Execution If  ${ip_found} == ${False}  ${ip} does not exist on BMC

    # Run patch command only if given IP is found on BMC
    ${data}=  Create Dictionary  IPv4StaticAddresses=${patch_list}

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    # Logout from local user.
    Redfish.Logout

    # Login from AD user and check if we can delete IP address.
    Redfish.Login  ${AD_USER}  ${AD_USER_PASSWORD}

    Redfish.patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body=&{data}
    ...  valid_status_codes=[${valid_status_codes}]

    # Note: Network restart takes around 15-18s after patch request processing
    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}
