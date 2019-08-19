*** Settings ***
Documentation    Test Redfish LDAP user configuration.

Library          ../../lib/gen_robot_valid.py
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Library          ../../lib/gen_robot_valid.py

Suite Setup      Suite Setup Execution
Suite Teardown   Run Keywords  Restore LDAP Privilege  AND  Redfish.Logout
Test Teardown    FFDC On Test Case Fail

Force Tags       LDAP_Test

*** Variables ***
${old_ldap_privilege}  ${EMPTY}
&{old_account_service}  &{EMPTY}
&{old_ldap_config}  &{EMPTY}

** Test Cases **

Verify LDAP Configuration Created
    [Documentation]  Verify LDAP configuration created.
    [Tags]  Verify_LDAP_Configuration_Created

    Create LDAP Configuration
    # Call 'Get LDAP Configuration' to verify that LDAP configuration exists.
    Get LDAP Configuration  ${LDAP_TYPE}
    Sleep  10s
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Logout
    Redfish.Login


Verify LDAP Service Disable
    [Documentation]  Verify LDAP is disabled and that LDAP user cannot login.
    [Tags]  Verify_LDAP_Service_Disable

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${LDAP_TYPE}': {'ServiceEnabled': ${False}}}
    Sleep  15s
    ${resp}=  Run Keyword And Return Status  Redfish.Login  ${LDAP_USER}
    ...  ${LDAP_USER_PASSWORD}
    Should Be Equal  ${resp}  ${False}  msg=LDAP user was able to login even though the LDAP service was disabled.
    Redfish.Logout
    Redfish.Login
    # Enabling LDAP so that LDAP user works.
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${LDAP_TYPE}': {'ServiceEnabled': ${True}}}
    Redfish.Logout
    Redfish.Login


Verify LDAP Login With ServiceEnabled
    [Documentation]  Verify LDAP Login with ServiceEnabled.
    [Tags]  Verify_LDAP_Login_With_ServiceEnabled

    Disable Other LDAP
    # Actual service enablement.
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${LDAP_TYPE}': {'ServiceEnabled': ${True}}}
    Sleep  15s
    # After update, LDAP login.
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Logout
    Redfish.Login


Verify LDAP Login With Correct AuthenticationType
    [Documentation]  Verify LDAP Login with right AuthenticationType.
    [Tags]  Verify_LDAP_Login_With_Correct_AuthenticationType

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${ldap_type}': {'Authentication': {'AuthenticationType':'UsernameAndPassword'}}}
    Sleep  15s
    # After update, LDAP login.
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Logout
    Redfish.Login


Verify LDAP Config Update With Incorrect AuthenticationType
    [Documentation]  Verify invalid AuthenticationType is not updated.
    [Tags]  Verify_LDAP_Update_With_Incorrect_AuthenticationType

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${ldap_type}': {'Authentication': {'AuthenticationType':'KerberosKeytab'}}}  valid_status_codes=[400]


Verify LDAP Login With Correct LDAP URL
    [Documentation]  Verify LDAP Login with right LDAP URL.
    [Tags]  Verify_LDAP_Login_With_Correct_LDAP_URL

    Config LDAP URL  ${LDAP_SERVER_URI}


Verify LDAP Config Update With Incorrect LDAP URL
    [Documentation]  Verify LDAP Login fails with invalid LDAP URL.
    [Tags]  Verify_LDAP_Config_Update_With_Incorrect_LDAP_URL
    [Teardown]  Run Keywords  Restore LDAP URL  AND
    ...  FFDC On Test Case Fail

    Config LDAP URL  "ldap://1.2.3.4"


Verify LDAP Configuration Exist
    [Documentation]  Verify LDAP configuration is available.
    [Tags]  Verify_LDAP_Configuration_Exist

    ${resp}=  Redfish.Get Attribute  ${REDFISH_BASE_URI}AccountService
    ...  ${LDAP_TYPE}  default=${EMPTY}
    Should Not Be Empty  ${resp}  msg=LDAP configuration is not defined.


Verify LDAP User Login
    [Documentation]  Verify LDAP user able to login into BMC.
    [Tags]  Verify_LDAP_User_Login

    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Logout
    Redfish.Login


Verify LDAP Service Available
    [Documentation]  Verify LDAP service is available.
    [Tags]  Verify_LDAP_Service_Available

    @{ldap_configuration}=  Get LDAP Configuration  ${LDAP_TYPE}
    Should Contain  ${ldap_configuration}  LDAPService
    ...  msg=LDAPService is not available.


Verify LDAP Login Works After BMC Reboot
    [Documentation]  Verify LDAP login works after BMC reboot.
    [Tags]  Verify_LDAP_Login_Works_After_BMC_Reboot

    Redfish OBMC Reboot (off)
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Logout
    Redfish.Login


Verify LDAP User With Admin Privilege Able To Do BMC Reboot
    [Documentation]  Verify LDAP user with administrator privilege able to do BMC reboot.
    [Tags]  Verify_LDAP_User_With_Admin_Privilege_Able_To_Do_BMC_Reboot


    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  ${GROUP_PRIVILEGE}  ${GROUP_NAME}
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    # With LDAP user and with right privilege trying to do BMC reboot.
    Redfish OBMC Reboot (off)
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Logout
    Redfish.Login


Verify LDAP User With Operator Privilege Able To Do Host Poweroff
    [Documentation]  Verify LDAP user with operator privilege can do host power off.
    [Tags]  Verify_LDAP_User_With_Operator_Privilege_Able_To_Do_Host_Poweroff
    [Teardown]  Restore LDAP Privilege

    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  Operator  ${GROUP_NAME}

    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    # Verify that the LDAP user with operator privilege is able to power the system off.
    Redfish.Post  ${REDFISH_POWER_URI}
    ...  body={'ResetType': 'ForceOff'}   valid_status_codes=[200]
    Redfish.Logout
    Redfish.Login


Verify AccountLockout Attributes Set To Zero
    [Documentation]  Verify attribute AccountLockoutDuration and
    ...  AccountLockoutThreshold are set to 0.
    [Teardown]  Run Keywords  Restore AccountLockout Attributes  AND
    ...  FFDC On Test Case Fail
    [Tags]  Verify_AccountLockout_Attributes_Set_To_Zero

    ${old_account_service}=  Redfish.Get Properties
    ...  ${REDFISH_BASE_URI}AccountService
    Rprint Vars  old_account_service
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body=[('AccountLockoutDuration', 0)]
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body=[('AccountLockoutThreshold', 0)]


Verify LDAP User With Read Privilege Able To Check Inventory
    [Documentation]  Verify LDAP user with read privilege able to
    ...  read firmware inventory.
    [Tags]  Verify_LDAP_User_With_Read_Privilege_Able_To_Check_Inventory
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND  Restore LDAP Privilege
    [Template]  Set Read Privilege And Check Firmware Inventory

    User
    Callback


Verify LDAP User With Read Privilege Should Not Do Host Poweron
    [Documentation]  Verify LDAP user with read privilege should not be
    ...  allowed to power on the host.
    [Tags]  Verify_LDAP_User_With_Read_Privilege_Should_Not_Do_Host_Poweron
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND  Restore LDAP Privilege
    [Template]  Set Read Privilege And Check Poweron

    User
    Callback


Update LDAP Group Name And Verify Operations
    [Documentation]  Verify LDAP group name update and able to do right operations.
    [Tags]  Update_LDAP_Group_Name_And_Verify_Operations
    [Template]  Update LDAP Config And Verify Set Host Name
    [Teardown]  Restore LDAP Privilege

    # group_name             group_privilege  valid_status_codes
    ${GROUP_NAME}            Administrator    [${HTTP_OK}]
    ${GROUP_NAME}            Operator         [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]
    ${GROUP_NAME}            User             [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]
    ${GROUP_NAME}            Callback         [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]
    Invalid_LDAP_Group_Name  Administrator    [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]
    Invalid_LDAP_Group_Name  Operator         [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]
    Invalid_LDAP_Group_Name  User             [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]
    Invalid_LDAP_Group_Name  Callback         [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]


*** Keywords ***

Update LDAP Config And Verify Set Host Name
    [Documentation]  Update LDAP config and verify by attempting to set host name.
    [Arguments]  ${group_name}  ${group_privilege}=Administrator
    ...  ${valid_status_codes}=[${HTTP_OK}]

    # Description of argument(s):
    # group_name                    The group name of user.
    # group_privilege               The group privilege ("Administrator",
    #                               "Operator", "User" or "Callback").
    # valid_status_codes            Expected return code(s) from patch
    #                               operation (e.g. "200") used to update
    #                               HostName.  See prolog of rest_request
    #                               method in redfish_plut.py for details.
    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  ${group_privilege}  ${group_name}
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    # Verify that the LDAP user in ${group_name} with the given privilege is
    # allowed to change the hostname.
    ${hostname}=  Redfish_Utils.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  HostName
    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body={'HostName': '${hostname}'}
    ...  valid_status_codes=${valid_status_codes}
    Redfish.Logout
    Redfish.Login


Disable Other LDAP
    [Documentation]  Disable other LDAP configuration.

    # First disable other LDAP.
    ${inverse_ldap_type}=  Set Variable If  '${LDAP_TYPE}' == 'LDAP'  ActiveDirectory  LDAP
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${inverse_ldap_type}': {'ServiceEnabled': ${False}}}
    Sleep  15s


Create LDAP Configuration
    [Documentation]  Create LDAP configuration.
    [Arguments]  ${ldap_type}=${LDAP_TYPE}  ${ldap_server_uri}=${LDAP_SERVER_URI}
    ...  ${ldap_bind_dn}=${LDAP_BIND_DN}  ${ldap_bind_dn_password}=${LDAP_BIND_DN_PASSWORD}
    ...  ${ldap_base_dn}=${LDAP_BASE_DN}

    # Description of argument(s):
    # ldap_type              The LDAP type ("ActiveDirectory" or "LDAP").
    # ldap_server_uri        LDAP server uri (e.g. ldap://XX.XX.XX.XX).
    # ldap_bind_dn           The LDAP bind distinguished name.
    # ldap_bind_dn_password  The LDAP bind distinguished name password.
    # ldap_base_dn           The LDAP base distinguished name.

    Disable Other LDAP
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${ldap_type}': {'ServiceEnabled': ${True}, 'ServiceAddresses': ['${ldap_server_uri}'], 'Authentication': {'AuthenticationType':'UsernameAndPassword', 'Username':'${ldap_bind_dn}', 'Password':'${ldap_bind_dn_password}'}, 'LDAPService': {'SearchSettings': {'BaseDistinguishedNames': ['${ldap_base_dn}']}}}}
    Sleep  15s


Config LDAP URL
    [Documentation]  Config LDAP URL.
    [Arguments]  ${ldap_server_uri}=${LDAP_SERVER_URI}

    # Description of argument(s):
    # ldap_server_uri LDAP server uri (e.g. "ldap://XX.XX.XX.XX/").

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${ldap_type}': {'ServiceAddresses': ['${ldap_server_uri}']}}
    Sleep  15s
    # After update, LDAP login.
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Logout
    Redfish.Login


Restore LDAP URL
    [Documentation]  Restore LDAP URL.

    # Restoring the working LDAP server uri.
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${ldap_type}': {'ServiceAddresses': ['${LDAP_SERVER_URI}']}}
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

    Valid Value  LDAP_TYPE  valid_values=["ActiveDirectory", "LDAP"]
    Valid Value  LDAP_USER
    Valid Value  LDAP_USER_PASSWORD
    Valid Value  GROUP_PRIVILEGE
    Valid Value  GROUP_NAME
    Valid Value  LDAP_SERVER_URI
    Valid Value  LDAP_BIND_DN_PASSWORD
    Valid Value  LDAP_BIND_DN
    Valid Value  LDAP_BASE_DN

    Redfish.Login
    # Call 'Get LDAP Configuration' to verify that LDAP configuration exists.
    Get LDAP Configuration  ${LDAP_TYPE}
    ${old_ldap_privilege}=  Get LDAP Privilege


Set Read Privilege And Check Firmware Inventory
    [Documentation]  Set read privilege and check firmware inventory.
    [Arguments]  ${read_privilege}

    # Description of argument(s):
    # read_privilege  The read privilege role (e.g. "User" / "Callback").

    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  ${read_privilege}  ${GROUP_NAME}

    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    # Verify that the LDAP user with read privilege is able to read inventory.
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

    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  ${read_privilege}  ${GROUP_NAME}
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Post  ${REDFISH_POWER_URI}
    ...  body={'ResetType': 'On'}   valid_status_codes=[401, 403]
    Redfish.Logout
    Redfish.Login


Get LDAP Configuration
    [Documentation]  Retrieve LDAP Configuration.
    [Arguments]   ${ldap_type}

    # Description of argument(s):
    # ldap_type  The LDAP type ("ActiveDirectory" or "LDAP").

    ${ldap_config}=  Redfish.Get Properties  ${REDFISH_BASE_URI}AccountService
    [Return]  ${ldap_config["${ldap_type}"]}


Update LDAP Configuration with LDAP User Role And Group
    [Documentation]  Update LDAP configuration update with LDAP user Role and group.
    [Arguments]   ${ldap_type}  ${group_privilege}  ${group_name}

    # Description of argument(s):
    # ldap_type        The LDAP type ("ActiveDirectory" or "LDAP").
    # group_privilege  The group privilege ("Administrator", "Operator", "User" or "Callback").
    # group_name       The group name of user.

    ${local_role_remote_group}=  Create Dictionary  LocalRole=${group_privilege}  RemoteGroup=${group_name}
    ${remote_role_mapping}=  Create List  ${local_role_remote_group}
    ${ldap_data}=  Create Dictionary  RemoteRoleMapping=${remote_role_mapping}
    ${payload}=  Create Dictionary  ${ldap_type}=${ldap_data}
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService  body=&{payload}
    # Provide adequate time for LDAP daemon to restart after the update.
    Sleep  15s


Get LDAP Privilege
    [Documentation]  Get LDAP privilege and return it.

    ${ldap_config}=  Get LDAP Configuration  ${LDAP_TYPE}
    ${num_list_entries}=  Get Length  ${ldap_config["RemoteRoleMapping"]}
    Return From Keyword If  ${num_list_entries} == ${0}  @{EMPTY}

    [Return]  ${ldap_config["RemoteRoleMapping"][0]["LocalRole"]}


Restore LDAP Privilege
    [Documentation]  Restore the LDAP privilege to its original value.

    Return From Keyword If  '${old_ldap_privilege}' == '${EMPTY}'
    # Log back in to restore the original privilege.
    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  ${old_ldap_privilege}  ${GROUP_NAME}
