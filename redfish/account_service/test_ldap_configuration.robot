*** Settings ***
Documentation    Test Redfish LDAP user configuration.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Library          ../../lib/gen_robot_valid.py

Suite Setup      Suite Setup Execution
Suite Teardown   Redfish.Logout
Test Teardown    FFDC On Test Case Fail

Force Tags       LDAP_Test

*** Variables ***
${old_ldap_privilege}  ${EMPTY}

** Test Cases **

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
    redfish.Logout


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


Verify LDAP User With Operator Privilege Able To Do Host Poweron
    [Documentation]  Verify LDAP user with operator privilege able to do host up.
    [Tags]  Verify_LDAP_User_With_Operator_Privilege_Able_To_Do_Host_Poweron
    [Teardown]  Restore LDAP Privilege

    ${old_ldap_privilege}=  Get LDAP Privilege
    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  Operator  ${GROUP_NAME}
    # Provide adequate time for LDAP daemon to restart after the update.
    Sleep  10s

    ${ldap_config}=  Redfish.Get Properties  ${REDFISH_BASE_URI}AccountService
    ${new_ldap_privilege}=  Set Variable
    ...  ${ldap_config["LDAP"]["RemoteRoleMapping"][0]["LocalRole"]}
    Should Be Equal  ${new_ldap_privilege}  Operator
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    # Verify that the LDAP user with operator privilege is able to power the system on.
    Redfish Power On
    Redfish.Logout


*** Keywords ***
Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Rvalid Value  LDAP_TYPE
    Rvalid Value  LDAP_USER
    Rvalid Value  LDAP_USER_PASSWORD
    Rvalid Value  GROUP_PRIVILEGE
    Rvalid Value  GROUP_NAME
    Redfish.Login
    # Call 'Get LDAP Configuration' to verify that LDAP configuration exists.
    Get LDAP Configuration  ${LDAP_TYPE}


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


Get LDAP Privilege
    [Documentation]  Get LDAP privilege and return it.

    ${ldap_config}=  Get LDAP Configuration  ${LDAP_TYPE}
    [Return]  ${ldap_config["RemoteRoleMapping"][0]["LocalRole"]}


Restore LDAP Privilege
    [Documentation]  Restore the LDAP privilege to its original value.

    # Login back to update the original privilege.
    Redfish.Login
    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  ${old_ldap_privilege}  ${GROUP_NAME}
    Redfish.Logout
