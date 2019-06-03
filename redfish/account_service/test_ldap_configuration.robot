*** Settings ***
Documentation    Test Redfish LDAP user configuration.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Suite Setup      Suite Setup Execution
Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

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
    Sleep  180s   # Time given to BMC get rebooted.
    ${resp}=  Run Keyword And Return Status  Redfish.Login  ${LDAP_USER}
    ...  ${LDAP_USER_PASSWORD}
    Should Be Equal  ${resp}  ${True}  msg=LDAP user is not able to login after BMC reboot.
    Redfish.Logout


Verify LDAP User With Admin Privilege Able To Do BMC Reboot
    [Documentation]  Verify LDAP user with administrator privilege able to do BMC reboot.
    [Tags]  Verify_LDAP_User_With_Admin_Privilege_Able_To_Do_BMC_Reboot


    Update LDAP Configuration with LDAP User Role And Group  ${LDAP_TYPE}
    ...  ${GROUP_PRIVILEGE}  ${GROUP_NAME}
    ${resp}=  Run Keyword And Return Status  Redfish.Login  ${LDAP_USER}
    ...  ${LDAP_USER_PASSWORD}
    Should Be Equal  ${resp}  ${True}  msg=LDAP user is not able to login.
    # With LDAP user and with right privilege trying to do BMC reboot.
    Redfish OBMC Reboot (off)
    Sleep  180s    # Time given to BMC get rebooted.
    ${resp}=  Run Keyword And Return Status  Redfish.Login  ${LDAP_USER}
    ...  ${LDAP_USER_PASSWORD}
    Should Be Equal  ${resp}  ${True}  msg=LDAP user is not able to login after BMC reboot.
    Redfish.Logout


*** Keywords ***
Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Should Not Be Empty  ${LDAP_TYPE}
    redfish.Login
    Get LDAP Configuration  ${LDAP_TYPE}
    redfish.Logout


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    FFDC On Test Case Fail
    redfish.Logout


Get LDAP Configuration
    [Documentation]  Retrieve LDAP Configuration.
    [Arguments]   ${ldap_type}

    # Description of argument(s):
    # ldap_type  The LDAP type ("ActiveDirectory" or "LDAP").

    ${ldap_config}=  Redfish.Get Properties  ${REDFISH_BASE_URI}AccountService
    [Return]  ${ldap_config["${ldap_type}"]}


Update LDAP Configuration with LDAP User Role And Group
    [Documentation]  LDAP configuration update with LDAP user Role.
    [Arguments]   ${ldap_type}  ${group_privilege}  ${group_name}

    # Description of argument(s):
    # ldap_type  The LDAP type ("ActiveDirectory" or "LDAP").
    # group_privilege The group privilege either it can be
    #                                 "Administrator/Operator/User/Callback".
    # group_name  The group name of user.

    ${data}=  Create Dictionary  LocalRole=${group_privilege}
    ...  RemoteGroup=${group_name}

    ${payload}=  Create Dictionary  ${ldap_type}=${data}
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService  body=&{payload}

    ${resp}=  Get LDAP Configuration  ${ldap_type}
    Should Be Equal As Strings  ${resp.dict["${ldap_type}"]["RemoteRoleMapping"]["LocalRole"]}
    ...  ${group_privilege}  msg=LDAP group privilege is not matching.

    ${resp}=  Get LDAP Configuration  ${ldap_type}
    Should Be Equal As Strings  ${resp.dict["${ldap_type}"]["RemoteRoleMapping"]["RemoteGroup"]}
    ...  ${group_name}  msg=LDAP group name is not matching.
