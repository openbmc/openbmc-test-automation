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

** Test Cases **

Verify LDAP Login With ServiceEnabled
    [Documentation]  Verify LDAP Login with ServiceEnabled.
    [Tags]  Verify_LDAP_Login_With_ServiceEnabled

    # First disable other LDAP.
    ${inverse_ldap_type}=  Set Variable If  '${LDAP_TYPE}' == 'LDAP'  ActiveDirectory  LDAP
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${inverse_ldap_type}': {'ServiceEnabled': ${False}}}
    Sleep  15s
    # Actual service enablement.
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${LDAP_TYPE}': {'ServiceEnabled': ${True}}}
    Sleep  15s
    # After update, LDAP login.
    ${resp}=  Run Keyword And Return Status  Redfish.Login  ${LDAP_USER}
    ...  ${LDAP_USER_PASSWORD}
    Should Be Equal  ${resp}  ${True}  msg=LDAP user not able to login.
    Redfish.Logout
    Redfish.Login


Verify LDAP Login With Correct AuthenticationType
    [Documentation]  Verify LDAP Login with right AuthenticationType.
    [Tags]  Verify_LDAP_Login_With_Correct_AuthenticationType

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${ldap_type}': {'Authentication': {'AuthenticationType':'UsernameAndPassword'}}}
    Sleep  15s
    # After update, LDAP login.
    ${resp}=  Run Keyword And Return Status  Redfish.Login  ${LDAP_USER}
    ...  ${LDAP_USER_PASSWORD}
    Should Be Equal  ${resp}  ${True}  msg=LDAP user not able to login.
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
    [Teardown]  Restore LDAP URL

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

    ${resp}=  Run Keyword And Return Status  Redfish.Login  ${LDAP_USER}
    ...  ${LDAP_USER_PASSWORD}
    Should Be Equal  ${resp}  ${True}  msg=LDAP user is not able to login.
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

    ${ldap_config}=  Redfish.Get Properties  ${REDFISH_BASE_URI}AccountService
    ${new_ldap_privilege}=  Set Variable
    ...  ${ldap_config["LDAP"]["RemoteRoleMapping"][0]["LocalRole"]}
    Should Be Equal  ${new_ldap_privilege}  Operator
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


*** Keywords ***

Config LDAP URL
    [Documentation]  Config LDAP URL.
    [Arguments]  ${ldap_server_uri}=${LDAP_SERVER_URI}

    # Description of argument(s):
    # ldap_server_uri LDAP server uri (e.g. "ldap://XX.XX.XX.XX/")

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${ldap_type}': {'ServiceAddresses': ['${ldap_server_uri}']}}
    Sleep  15s
    # After update, LDAP login.
    ${resp}=  Run Keyword And Return Status  Redfish.Login  ${LDAP_USER}
    ...  ${LDAP_USER_PASSWORD}
    Should Be Equal  ${resp}  ${True}  msg=LDAP user not able to login.
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

    Rvalid Value  LDAP_TYPE  valid_values=["ActiveDirectory", "LDAP"]
    Rvalid Value  LDAP_USER
    Rvalid Value  LDAP_USER_PASSWORD
    Rvalid Value  GROUP_PRIVILEGE
    Rvalid Value  GROUP_NAME
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
    Sleep  10s


Get LDAP Privilege
    [Documentation]  Get LDAP privilege and return it.

    ${ldap_config}=  Get LDAP Configuration  ${LDAP_TYPE}
    [Return]  ${ldap_config["RemoteRoleMapping"][0]["LocalRole"]}


Restore LDAP Privilege
    [Documentation]  Restore the LDAP privilege to its original value.

    Return From Keyword If  '${old_ldap_privilege}' == '${EMPTY}'
    # Log back in to restore the original privilege.
    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  ${old_ldap_privilege}  ${GROUP_NAME}
