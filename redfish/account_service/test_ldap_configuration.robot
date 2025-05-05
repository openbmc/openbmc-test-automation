*** Settings ***
Documentation    Test Redfish LDAP user configuration.

Library          ../../lib/gen_robot_valid.py
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/utils.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_network_utils.robot
Resource         ../../lib/bmc_ldap_utils.robot

Suite Setup      Suite Setup Execution
Suite Teardown   LDAP Suite Teardown Execution
Test Teardown    Run Keywords  Redfish.Login  AND  FFDC On Test Case Fail
Test Tags       Ldap_Configuration

*** Variables ***
${old_ldap_privilege}   Administrator
&{old_account_service}  &{EMPTY}
&{old_ldap_config}      &{EMPTY}
${hostname}             ${EMPTY}
${test_ip}              10.6.6.6
${test_mask}            255.255.255.0

** Test Cases **

Verify LDAP Configuration Created
    [Documentation]  Verify that LDAP configuration created.
    [Tags]  Verify_LDAP_Configuration_Created

    Create LDAP Configuration
    # Call 'Get LDAP Configuration' to verify that LDAP configuration exists.
    Get LDAP Configuration  ${LDAP_TYPE}
    Sleep  10s
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Logout


Verify Redfish LDAP Service Disable
    [Documentation]  Verify that LDAP is disabled and that LDAP user cannot
    ...  login.
    [Tags]  Verify_Redfish_LDAP_Service_Disable

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${LDAP_TYPE}': {'ServiceEnabled': ${False}}}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    Sleep  15s
    ${resp}=  Run Keyword And Return Status  Redfish.Login  ${LDAP_USER}
    ...  ${LDAP_USER_PASSWORD}
    Should Be Equal  ${resp}  ${False}
    ...  msg=LDAP user was able to login even though the LDAP service was disabled.
    Redfish.Logout
    Redfish.Login
    # Enabling LDAP so that LDAP user works.
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${LDAP_TYPE}': {'ServiceEnabled': ${True}}}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    Redfish.Logout


Verify LDAP Login With ServiceEnabled
    [Documentation]  Verify that LDAP Login with ServiceEnabled.
    [Tags]  Verify_LDAP_Login_With_ServiceEnabled

    Disable Other LDAP
    # Actual service enablement.
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${LDAP_TYPE}': {'ServiceEnabled': ${True}}}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    Sleep  15s
    # After update, LDAP login.
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Logout


Verify LDAP Login With Correct AuthenticationType
    [Documentation]  Verify that LDAP Login with right AuthenticationType.
    [Tags]  Verify_LDAP_Login_With_Correct_AuthenticationType

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${ldap_type}': {'Authentication': {'AuthenticationType':'UsernameAndPassword'}}}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    Sleep  15s
    # After update, LDAP login.
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Logout


Verify LDAP Config Update With Incorrect AuthenticationType
    [Documentation]  Verify that invalid AuthenticationType is not updated.
    [Tags]  Verify_LDAP_Config_Update_With_Incorrect_AuthenticationType

    ${body}=  Catenate  {'${ldap_type}': {'Authentication': {'AuthenticationType':'KerberosKeytab'}}}

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body=${body}  valid_status_codes=[400]


Verify LDAP Login With Correct LDAP URL
    [Documentation]  Verify LDAP Login with right LDAP URL.
    [Tags]  Verify_LDAP_Login_With_Correct_LDAP_URL

    Config LDAP URL  ${LDAP_SERVER_URI}


Verify LDAP Config Update With Incorrect LDAP URL
    [Documentation]  Verify that LDAP Login fails with invalid LDAP URL.
    [Tags]  Verify_LDAP_Config_Update_With_Incorrect_LDAP_URL
    [Teardown]  Run Keywords  Restore LDAP URL  AND
    ...  FFDC On Test Case Fail

    Config LDAP URL  ldap://1.2.3.4/  ${FALSE}

Verify LDAP Configuration Exist
    [Documentation]  Verify that LDAP configuration is available.
    [Tags]  Verify_LDAP_Configuration_Exist

    ${resp}=  Redfish.Get Attribute  ${REDFISH_BASE_URI}AccountService
    ...  ${LDAP_TYPE}  default=${EMPTY}
    Should Not Be Empty  ${resp}  msg=LDAP configuration is not defined.


Verify LDAP User Login
    [Documentation]  Verify that LDAP user able to login into BMC.
    [Tags]  Verify_LDAP_User_Login

    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Logout


Verify LDAP Service Available
    [Documentation]  Verify that LDAP service is available.
    [Tags]  Verify_LDAP_Service_Available

    @{ldap_configuration}=  Get LDAP Configuration  ${LDAP_TYPE}
    Should Contain  ${ldap_configuration}  LDAPService
    ...  msg=LDAPService is not available.


Verify LDAP Login Works After BMC Reboot
    [Documentation]  Verify that LDAP login works after BMC reboot.
    [Tags]  Verify_LDAP_Login_Works_After_BMC_Reboot

    Redfish OBMC Reboot (off)
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Logout


Verify LDAP User With Admin Privilege Able To Do BMC Reboot
    [Documentation]  Verify that LDAP user with administrator privilege able to do BMC reboot.
    [Tags]  Verify_LDAP_User_With_Admin_Privilege_Able_To_Do_BMC_Reboot


    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  ${GROUP_PRIVILEGE}  ${GROUP_NAME}
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    # With LDAP user and with right privilege trying to do BMC reboot.
    Redfish OBMC Reboot (off)
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Logout


Verify LDAP User With Operator Privilege Able To Do Host Poweroff
    [Documentation]  Verify that LDAP user with operator privilege can do host
    ...  power off.
    [Tags]  Verify_LDAP_User_With_Operator_Privilege_Able_To_Do_Host_Poweroff
    [Teardown]  Restore LDAP Privilege

    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  Operator  ${GROUP_NAME}

    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    # Verify that the LDAP user with operator privilege is able to power the system off.
    Redfish.Post  ${REDFISH_POWER_URI}
    ...  body={'ResetType': 'ForceOff'}   valid_status_codes=[200]
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    Redfish.Logout
    Redfish.Login


Verify AccountLockout Attributes Set To Zero By LDAP User
    [Documentation]  Verify that attribute AccountLockoutDuration and
    ...  AccountLockoutThreshold are set to 0 by LDAP user.
    [Teardown]  Run Keywords  Restore AccountLockout Attributes  AND
    ...  FFDC On Test Case Fail
    [Tags]  Verify_AccountLockout_Attributes_Set_To_Zero_By_LDAP_User

    ${old_account_service}=  Redfish.Get Properties
    ...  ${REDFISH_BASE_URI}AccountService
    Rprint Vars  old_account_service

    # Create LDAP user and create session using LDAP user.
    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  Administrator  ${GROUP_NAME}

    # Clear existing Redfish sessions.
    Redfish.Logout

    # Login using LDAP user.
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}

    # Set Account Lockout attributes using LDAP user.
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body=[('AccountLockoutDuration', 0)]
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body=[('AccountLockoutThreshold', 0)]
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]


Verify LDAP User With Read Privilege Able To Check Inventory
    [Documentation]  Verify that LDAP user with read privilege able to
    ...  read firmware inventory.
    [Tags]  Verify_LDAP_User_With_Read_Privilege_Able_To_Check_Inventory
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND  Restore LDAP Privilege
    [Template]  Set Read Privilege And Check Firmware Inventory

    ReadOnly


Verify LDAP User With Read Privilege Should Not Do Host Poweron
    [Documentation]  Verify that LDAP user with read privilege should not be
    ...  allowed to power on the host.
    [Tags]  Verify_LDAP_User_With_Read_Privilege_Should_Not_Do_Host_Poweron
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND  Restore LDAP Privilege
    [Template]  Set Read Privilege And Check Poweron

    ReadOnly


Update LDAP Group Name And Verify Operations
    [Documentation]  Verify that LDAP group name update and able to do right
    ...  operations.
    [Tags]  Update_LDAP_Group_Name_And_Verify_Operations
    [Template]  Update LDAP Config And Verify Set Host Name
    [Teardown]  Restore LDAP Privilege

    # group_name             group_privilege  valid_status_codes
    ${GROUP_NAME}            Administrator    [${HTTP_OK}, ${HTTP_NO_CONTENT}]
    ${GROUP_NAME}            Operator         [${HTTP_OK}, ${HTTP_NO_CONTENT}]
    ${GROUP_NAME}            ReadOnly         [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]
    Invalid_LDAP_Group_Name  Administrator    [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]
    Invalid_LDAP_Group_Name  Operator         [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]
    Invalid_LDAP_Group_Name  ReadOnly         [${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]


Verify LDAP BaseDN Update And LDAP Login
    [Documentation]  Update LDAP BaseDN of LDAP configuration and verify
    ...  that LDAP login works.
    [Tags]  Verify_LDAP_BaseDN_Update_And_LDAP_Login


    ${body}=  Catenate  {'${LDAP_TYPE}': { 'LDAPService': {'SearchSettings':
    ...   {'BaseDistinguishedNames': ['${LDAP_BASE_DN}']}}}}
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService  body=${body}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    Sleep  15s
    Redfish Verify LDAP Login


Verify LDAP BindDN Update And LDAP Login
    [Documentation]  Update LDAP BindDN of LDAP configuration and verify
    ...  that LDAP login works.
    [Tags]  Verify_LDAP_BindDN_Update_And_LDAP_Login

    ${body}=  Catenate  {'${LDAP_TYPE}': { 'Authentication':
    ...   {'AuthenticationType':'UsernameAndPassword', 'Username':
    ...  '${LDAP_BIND_DN}'}}}
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService  body=${body}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    Sleep  15s
    Redfish Verify LDAP Login


Verify LDAP BindDN Password Update And LDAP Login
    [Documentation]  Update LDAP BindDN password of LDAP configuration and
    ...  verify that LDAP login works.
    [Tags]  Verify_LDAP_BindDN_Password_Update_And_LDAP_Login


    ${body}=  Catenate  {'${LDAP_TYPE}': { 'Authentication':
    ...   {'AuthenticationType':'UsernameAndPassword', 'Password':
    ...  '${LDAP_BIND_DN_PASSWORD}'}}}
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService  body=${body}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    Sleep  15s
    Redfish Verify LDAP Login


Verify LDAP Type Update And LDAP Login
    [Documentation]  Update LDAP type of LDAP configuration and verify
    ...  that LDAP login works.
    [Tags]  Verify_LDAP_Type_Update_And_LDAP_Login

    Disable Other LDAP
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${LDAP_TYPE}': {'ServiceEnabled': ${True}}}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    Sleep  15s
    Redfish Verify LDAP Login


Verify LDAP Authorization With Null Privilege
    [Documentation]  Verify the failure of LDAP authorization with empty
    ...  privilege.
    [Tags]  Verify_LDAP_Authorization_With_Null_Privilege
    [Teardown]  Restore LDAP Privilege

    Update LDAP Config And Verify Set Host Name  ${GROUP_NAME}  ${EMPTY}
    ...  [${HTTP_FORBIDDEN}]


Verify LDAP Authorization With Invalid Privilege
    [Documentation]  Verify that LDAP user authorization with wrong privilege
    ...  fails.
    [Tags]  Verify_LDAP_Authorization_With_Invalid_Privilege
    [Teardown]  Restore LDAP Privilege

    Update LDAP Config And Verify Set Host Name  ${GROUP_NAME}
    ...  Invalid_Privilege  [${HTTP_FORBIDDEN}]


Verify LDAP Login With Invalid Data
    [Documentation]  Verify that LDAP login with Invalid LDAP data and
    ...  right LDAP user fails.
    [Tags]  Verify_LDAP_Login_With_Invalid_Data
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Redfish.Login  AND
    ...  Create LDAP Configuration

    Create LDAP Configuration  ${LDAP_TYPE}  Invalid_LDAP_Server_URI
    ...  Invalid_LDAP_BIND_DN  LDAP_BIND_DN_PASSWORD
    ...  Invalid_LDAP_BASE_DN
    Sleep  15s
    Redfish Verify LDAP Login  ${False}


Verify LDAP Config Creation Without BASE DN
    [Documentation]  Verify that LDAP login with LDAP configuration
    ...  created without BASE_DN fails.
    [Tags]  Verify_LDAP_Config_Creation_Without_BASE_DN
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Redfish.Login  AND
    ...  Create LDAP Configuration

    Create LDAP Configuration  ${LDAP_TYPE}  Invalid_LDAP_Server_URI
    ...  Invalid_LDAP_BIND_DN  LDAP_BIND_DN_PASSWORD  ${EMPTY}
    Sleep  15s
    Redfish Verify LDAP Login  ${False}


Verify LDAP Authentication Without Password
    [Documentation]  Verify that LDAP user authentication without LDAP
    ...  user password fails.
    [Tags]  Verify_LDAP_Authentication_Without_Password
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login

    ${status}=  Run Keyword And Return Status  Redfish.Login  ${LDAP_USER}
    Valid Value  status  [${False}]


Verify LDAP Login With Invalid BASE DN
    [Documentation]  Verify that LDAP login with invalid BASE_DN and
    ...  valid LDAP user fails.
    [Tags]  Verify_LDAP_Login_With_Invalid_BASE_DN
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Redfish.Login  AND
    ...  Create LDAP Configuration

    Create LDAP Configuration  ${LDAP_TYPE}  ${LDAP_SERVER_URI}
    ...  ${LDAP_BIND_DN}  ${LDAP_BIND_DN_PASSWORD}  Invalid_LDAP_BASE_DN
    Sleep  15s
    Redfish Verify LDAP Login  ${False}


Verify LDAP Login With Invalid BIND_DN_PASSWORD
    [Documentation]  Verify that LDAP login with invalid BIND_DN_PASSWORD and
    ...  valid LDAP user fails.
    [Tags]  Verify_LDAP_Login_With_Invalid_BIND_DN_PASSWORD
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Redfish.Login  AND
    ...  Create LDAP Configuration

    Create LDAP Configuration  ${LDAP_TYPE}  ${LDAP_SERVER_URI}
    ...  ${LDAP_BIND_DN}  INVALID_LDAP_BIND_DN_PASSWORD  ${LDAP_BASE_DN}
    Sleep  15s
    Redfish Verify LDAP Login  ${False}


Verify LDAP Login With Invalid BASE DN And Invalid BIND DN
    [Documentation]  Verify that LDAP login with invalid BASE_DN and invalid
    ...  BIND_DN and valid LDAP user fails.
    [Tags]  Verify_LDAP_Login_With_Invalid_BASE_DN_And_Invalid_BIND_DN
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Redfish.Login  AND
    ...  Create LDAP Configuration

    Create LDAP Configuration  ${LDAP_TYPE}  ${LDAP_SERVER_URI}
    ...  INVALID_LDAP_BIND_DN  ${LDAP_BIND_DN_PASSWORD}  INVALID_LDAP_BASE_DN
    Sleep  15s
    Redfish Verify LDAP Login  ${False}


Verify Group Name And Group Privilege Able To Modify
    [Documentation]  Verify that LDAP group name and group privilege able to
    ...  modify.
    [Tags]  Verify_Group_Name_And_Group_Privilege_Able_To_Modify
    [Setup]  Update LDAP Configuration with LDAP User Role And Group
    ...  ${LDAP_TYPE}  Operator  ${GROUP_NAME}

    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  Administrator  ${GROUP_NAME}


Verify LDAP Login With Invalid BIND DN
    [Documentation]  Verify that LDAP login with invalid BIND_DN and
    ...  valid LDAP user fails.
    [Tags]  Verify_LDAP_Login_With_Invalid_BIND_DN
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Redfish.Login  AND
    ...  Create LDAP Configuration

    Create LDAP Configuration  ${LDAP_TYPE}  ${LDAP_SERVER_URI}
    ...  Invalid_LDAP_BIND_DN  ${LDAP_BIND_DN_PASSWORD}  ${LDAP_BASE_DN}
    Sleep  15s
    Redfish Verify LDAP Login  ${False}


Verify LDAP Authentication With Invalid LDAP User
    [Documentation]  Verify that LDAP user authentication for user not exist
    ...  in LDAP server and fails.
    [Tags]  Verify_LDAP_Authentication_With_Invalid_LDAP_User
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login

    ${status}=  Run Keyword And Return Status  Redfish.Login  INVALID_LDAP_USER
    ...  ${LDAP_USER_PASSWORD}
    Valid Value  status  [${False}]


Update LDAP User Roles And Verify Host Poweroff Operation
    [Documentation]  Update LDAP user roles and verify host poweroff operation.
    [Tags]  Update_LDAP_User_Roles_And_Verify_Host_Poweroff_Operation
    [Teardown]  Restore LDAP Privilege

    [Template]  Update LDAP User Role And Host Poweroff
    # ldap_type   group_privilege  group_name     valid_status_codes

    # Verify LDAP user with ReadOnly privilege not able to do host poweroff.
    ${LDAP_TYPE}  ReadOnly         ${GROUP_NAME}  ${HTTP_FORBIDDEN}

    # Verify LDAP user with Operator privilege able to do host poweroff.
    ${LDAP_TYPE}  Operator         ${GROUP_NAME}  ${HTTP_OK}

    # Verify LDAP user with Administrator privilege able to do host poweroff.
    ${LDAP_TYPE}  Administrator    ${GROUP_NAME}  ${HTTP_OK}


Update LDAP User Roles And Verify Host Poweron Operation
    [Documentation]  Update LDAP user roles and verify host poweron operation.
    [Tags]  Update_LDAP_User_Roles_And_Verify_Host_Poweron_Operation
    [Teardown]  Restore LDAP Privilege

    [Template]  Update LDAP User Role And Host Poweron
    # ldap_type   group_privilege  group_name     valid_status_codes

    # Verify LDAP user with ReadOnly privilege not able to do host poweron.
    ${LDAP_TYPE}  ReadOnly         ${GROUP_NAME}  ${HTTP_FORBIDDEN}

    # Verify LDAP user with Operator privilege able to do host poweron.
    ${LDAP_TYPE}  Operator         ${GROUP_NAME}  ${HTTP_OK}

    # Verify LDAP user with Administrator privilege able to do host poweron.
    ${LDAP_TYPE}  Administrator    ${GROUP_NAME}  ${HTTP_OK}


Configure IP Address Via Different User Roles And Verify
    [Documentation]  Configure IP address via different user roles and verify.
    [Tags]  Configure_IP_Address_Via_Different_User_Roles_And_Verify
    [Teardown]  Restore LDAP Privilege

    [Template]  Update LDAP User Role And Configure IP Address
    # Verify LDAP user with Administrator privilege is able to configure IP address.
    ${LDAP_TYPE}  Administrator    ${GROUP_NAME}  ${HTTP_OK}

    # Verify LDAP user with ReadOnly privilege is forbidden to configure IP address.
    ${LDAP_TYPE}  ReadOnly         ${GROUP_NAME}  ${HTTP_FORBIDDEN}

    # Verify LDAP user with Operator privilege is able to configure IP address.
    ${LDAP_TYPE}  Operator         ${GROUP_NAME}  ${HTTP_FORBIDDEN}


Delete IP Address Via Different User Roles And Verify
    [Documentation]  Delete IP address via different user roles and verify.
    [Tags]  Delete_IP_Address_Via_Different_User_Roles_And_Verify
    [Teardown]  Run Keywords  Restore LDAP Privilege  AND  FFDC On Test Case Fail

    [Template]  Update LDAP User Role And Delete IP Address
    # Verify LDAP user with Administrator privilege is able to delete IP address.
    ${LDAP_TYPE}  Administrator    ${GROUP_NAME}  ${HTTP_OK}

    # Verify LDAP user with ReadOnly privilege is forbidden to delete IP address.
    ${LDAP_TYPE}  ReadOnly         ${GROUP_NAME}  ${HTTP_FORBIDDEN}

    # Verify LDAP user with Operator privilege is able to delete IP address.
    ${LDAP_TYPE}  Operator         ${GROUP_NAME}  ${HTTP_FORBIDDEN}


Read Network Configuration Via Different User Roles And Verify
    [Documentation]  Read network configuration via different user roles and verify.
    [Tags]  Read_Network_Configuration_Via_Different_User_Roles_And_Verify
    [Teardown]  Restore LDAP Privilege

    [Template]  Update LDAP User Role And Read Network Configuration
    ${LDAP_TYPE}  Administrator  ${GROUP_NAME}  ${HTTP_OK}

    ${LDAP_TYPE}  ReadOnly       ${GROUP_NAME}  ${HTTP_OK}

    ${LDAP_TYPE}  Operator       ${GROUP_NAME}  ${HTTP_OK}

Switch LDAP Type And Verify Login Fails
    [Documentation]  Switch LDAP type and verify login fails.
    [Tags]  Switch_LDAP_Type_And_Verify_Login_Fails

    # Check Login with LDAP Type is working
    Create LDAP Configuration
    Redfish Verify LDAP Login

    # Disable the LDAP Type from OpenLDAP to ActiveDirectory or vice-versa
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${LDAP_TYPE}': {'ServiceEnabled': ${False}}}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]

    # Enable the inverse LDAP type
    Disable Other LDAP  ${True}
    Create LDAP Configuration  ${LDAP_TYPE_1}  ${LDAP_SERVER_URI_1}  ${LDAP_BIND_DN_1}  ${LDAP_BIND_DN_PASSWORD_1}  ${LDAP_BASE_DN_1}
    Redfish.Logout
    Sleep  10s

    # Check if Login works via Inverse LDAP
    Redfish.Login  ${LDAP_USER_1}  ${LDAP_USER_PASSWORD_1}
    Redfish.Logout
    Sleep  10s

    # Login using LDAP type must fail
    Redfish Verify LDAP Login  ${False}
    Redfish.Logout

*** Keywords ***

Redfish Verify LDAP Login
    [Documentation]  LDAP user log into BMC.
    [Arguments]  ${valid_status}=${True}

    # Description of argument(s):
    # valid_status  Expected status of LDAP login ("True" or "False").

    # According to our repo coding rules, Redfish.Login is to be done in Suite
    # Setup and Redfish.Logout is to be done in Suite Teardown.  For any
    # deviation from this rule (such as in this keyword), the deviant code
    # must take steps to restore us to our original logged-in state.

    ${status}=  Run Keyword And Return Status  Redfish.Login  ${LDAP_USER}
    ...  ${LDAP_USER_PASSWORD}
    Valid Value  status  [${valid_status}]
    Redfish.Logout
    Redfish.Login


Update LDAP Config And Verify Set Host Name
    [Documentation]  Update LDAP config and verify by attempting to set host name.
    [Arguments]  ${group_name}  ${group_privilege}=Administrator
    ...  ${valid_status_codes}=[${HTTP_OK}]
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login

    # Description of argument(s):
    # group_name                    The group name of user.
    # group_privilege               The group privilege ("Administrator",
    #                               "Operator", "User" or "Callback").
    # valid_status_codes            Expected return code(s) from patch
    #                               operation (e.g. "200") used to update
    #                               HostName.  See prolog of rest_request
    #                               method in redfish_plus.py for details.
    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  ${group_privilege}  ${group_name}

    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    # Verify that the LDAP user in ${group_name} with the given privilege is
    # allowed to change the hostname.
    Redfish.Patch  ${REDFISH_NW_ETH0_URI}  body={'HostName': '${hostname}'}
    ...  valid_status_codes=${valid_status_codes}

Disable Other LDAP
    [Documentation]  Disable other LDAP configuration.
    [Arguments]  ${service_state}=${False}

    # First disable other LDAP.
    ${inverse_ldap_type}=  Set Variable If  '${LDAP_TYPE}' == 'LDAP'  ActiveDirectory  LDAP
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${inverse_ldap_type}': {'ServiceEnabled': ${service_state}}}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    Sleep  15s


Config LDAP URL
    [Documentation]  Config LDAP URL.
    [Arguments]  ${ldap_server_uri}=${LDAP_SERVER_URI}  ${expected_status}=${TRUE}

    # Description of argument(s):
    # ldap_server_uri LDAP server uri (e.g. "ldap://XX.XX.XX.XX/").

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${ldap_type}': {'ServiceAddresses': ['${ldap_server_uri}']}}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    Sleep  15s
    # After update, LDAP login.
    ${status}=  Run Keyword And Return Status  Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Valid Value  status  [${expected_status}]

    Redfish.Logout
    Redfish.Login


Restore LDAP URL
    [Documentation]  Restore LDAP URL.

    # Restoring the working LDAP server uri.
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body={'${ldap_type}': {'ServiceAddresses': ['${LDAP_SERVER_URI}']}}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    Sleep  15s


Restore AccountLockout Attributes
    [Documentation]  Restore AccountLockout Attributes.

    IF  &{old_account_service} == &{EMPTY}  RETURN
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body=[('AccountLockoutDuration', ${old_account_service['AccountLockoutDuration']})]
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService
    ...  body=[('AccountLockoutThreshold', ${old_account_service['AccountLockoutThreshold']})]
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]

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
    Set Suite Variable  ${old_ldap_privilege}
    Disable Other LDAP
    Create LDAP Configuration
    ${hostname}=  Redfish.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  HostName


LDAP Suite Teardown Execution
    [Documentation]  Restore ldap configuration, delete unused redfish session.

    Restore LDAP Privilege
    Redfish.Logout
    Run Keyword And Ignore Error  Delete All Redfish Sessions


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
    RETURN  ${ldap_config["${ldap_type}"]}


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
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    # Provide adequate time for LDAP daemon to restart after the update.
    Sleep  15s


Get LDAP Privilege
    [Documentation]  Get LDAP privilege and return it.

    ${ldap_config}=  Get LDAP Configuration  ${LDAP_TYPE}
    ${num_list_entries}=  Get Length  ${ldap_config["RemoteRoleMapping"]}
    IF  ${num_list_entries} == ${0}  @{EMPTY}  RETURN

    RETURN  ${ldap_config["RemoteRoleMapping"][0]["LocalRole"]}


Restore LDAP Privilege
    [Documentation]  Restore the LDAP privilege to its original value.

    Redfish.Login
    IF  '${old_ldap_privilege}' == '${EMPTY}' or '${old_ldap_privilege}' == '[]'  RETURN
    # Log back in to restore the original privilege.
    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  ${old_ldap_privilege}  ${GROUP_NAME}

    Sleep  18s

Verify Host Power Status
    [Documentation]  Verify the Host power status and do host power on/off respectively.
    [Arguments]  ${expected_power_status}

    # Description of argument(s):
    # expected_power_status  State of Host e.g. Off or On.

    ${power_status}=  Redfish.Get Attribute  /redfish/v1/Chassis/${CHASSIS_ID}  PowerState
    IF  '${power_status}' == '${expected_power_status}'  RETURN

    IF  '${power_status}' == 'Off'
        Redfish Power On
    ELSE
        Redfish Power Off
    END

Update LDAP User Role And Host Poweroff
    [Documentation]  Update LDAP user role and do host poweroff.
    [Arguments]  ${ldap_type}  ${group_privilege}  ${group_name}  ${valid_status_code}
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login

    # Description of argument(s):
    # ldap_type          The LDAP type ("ActiveDirectory" or "LDAP").
    # group_privilege    The group privilege ("Administrator", "Operator" or "ReadOnly").
    # group_name         The group name of user.
    # valid_status_code  The expected valid status code.

    # check Host state and do the power on/off if needed.
    Verify Host Power Status  On

    Update LDAP Configuration with LDAP User Role And Group  ${ldap_type}
    ...  ${group_privilege}  ${group_name}

    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}

    Redfish.Post  ${REDFISH_POWER_URI}
    ...  body={'ResetType': 'ForceOff'}   valid_status_codes=[${valid_status_code}]

    IF  ${valid_status_code} == ${HTTP_FORBIDDEN}  RETURN
    Wait Until Keyword Succeeds  1 min  10 sec  Verify Host Power State  Off


Update LDAP User Role And Host Poweron
    [Documentation]  Update LDAP user role and do host poweron.
    [Arguments]  ${ldap_type}  ${group_privilege}  ${group_name}  ${valid_status_code}
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login

    # Description of argument(s):
    # ldap_type          The LDAP type ("ActiveDirectory" or "LDAP").
    # group_privilege    The group privilege ("Administrator", "Operator" or "ReadOnly").
    # group_name         The group name of user.
    # valid_status_code  The expected valid status code.

    # check Host state and do the power on/off if needed.
    Verify Host Power Status  Off

    Update LDAP Configuration with LDAP User Role And Group  ${ldap_type}
    ...  ${group_privilege}  ${group_name}

    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}

    Redfish.Post  ${REDFISH_POWER_URI}
    ...  body={'ResetType': 'On'}   valid_status_codes=[${valid_status_code}]

    IF  ${valid_status_code} == ${HTTP_FORBIDDEN}  RETURN
    Verify Host Is Up


Update LDAP User Role And Configure IP Address
    [Documentation]  Update LDAP user role and configure IP address.
    [Arguments]  ${ldap_type}  ${group_privilege}  ${group_name}  ${valid_status_code}=${HTTP_OK}
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login  AND  Delete IP Address  ${test_ip}

    # Description of argument(s):
    # ldap_type          The LDAP type ("ActiveDirectory" or "LDAP").
    # group_privilege    The group privilege ("Administrator", "Operator" or "ReadOnly").
    # group_name         The group name of user.
    # valid_status_code  The expected valid status code.

    Update LDAP Configuration with LDAP User Role And Group  ${ldap_type}
    ...  ${group_privilege}  ${group_name}

    Redfish.Logout

    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}

    ${test_gateway}=  Get BMC Default Gateway

    Add IP Address  ${test_ip}  ${test_mask}  ${test_gateway}  ${valid_status_code}


Update LDAP User Role And Delete IP Address
    [Documentation]  Update LDAP user role and delete IP address.
    [Arguments]  ${ldap_type}  ${group_privilege}  ${group_name}  ${valid_status_code}=${HTTP_OK}
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login  AND  Delete IP Address  ${test_ip}

    # Description of argument(s):
    # ldap_type          The LDAP type ("ActiveDirectory" or "LDAP").
    # group_privilege    The group privilege ("Administrator", "Operator" or "ReadOnly").
    # group_name         The group name of user.
    # valid_status_code  The expected valid status code.

    ${test_gateway}=  Get BMC Default Gateway

    # Configure IP address before deleting via LDAP user roles.
    Add IP Address  ${test_ip}  ${test_mask}  ${test_gateway}

    Update LDAP Configuration with LDAP User Role And Group  ${ldap_type}
    ...  ${group_privilege}  ${group_name}

    Redfish.Logout

    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}

    Delete IP Address  ${test_ip}  ${valid_status_code}


Update LDAP User Role And Read Network Configuration
    [Documentation]  Update LDAP user role and read network configuration.
    [Arguments]  ${ldap_type}  ${group_privilege}  ${group_name}  ${valid_status_code}=${HTTP_OK}
    [Teardown]  Run Keywords  Redfish.Logout  AND  Redfish.Login

    # Description of argument(s):
    # ldap_type          The LDAP type ("ActiveDirectory" or "LDAP").
    # group_privilege    The group privilege ("Administrator", "Operator" or "ReadOnly").
    # group_name         The group name of user.
    # valid_status_code  The expected valid status code.

    Update LDAP Configuration with LDAP User Role And Group  ${ldap_type}
    ...  ${group_privilege}  ${group_name}

    Redfish.Logout

    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Redfish.Get  ${REDFISH_NW_ETH0_URI}  valid_status_codes=[${valid_status_code}]
