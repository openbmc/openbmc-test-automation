*** Settings ***
Documentation    Test Redfish LDAP user configuration.
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Suite Setup      Suite Setup Execution
Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

** Test Cases **
Verify LDAP Configuration Created
    [Documentation]  Verify LDAP configuration is created.
    [Tags]  Verify_LDAP_Configuration_Created

    ${resp}=  Redfish.Get Attribute  ${REDFISH_BASE_URI}AccountService
    ...  ${LDAP_TYPE}  default=${EMPTY}
    Should Not Be Empty  ${resp}  msg=LDAP configuration is not defined.


Verify LDAP User Login
    [Documentation]  Verify LDAP user able to login into BMC.
    [Tags]  Verify_LDAP_User_Login

    ${resp}=  Run Keyword And Return Status  Redfish.Login  ${LDAP_USER}
    ...  ${LDAP_USER_PASSWORD}
    Should Be Equal  ${resp}  ${True}  msg=LDAP user is not able to login.


Verify LDAP Service Available
    [Documentation]  Verify LDAP service is available.
    [Tags]  Verify_LDAP_Service_Available

    @{ldap_configuration}=  Get LDAP Configuration  ${LDAP_TYPE}
    Should Contain  ${ldap_configuration}  LDAPService
    ...  msg=LDAPService is not available.


*** Keywords ***
Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Should Not Be Empty  ${LDAP_TYPE}


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
