*** Settings ***
Documentation    Test Redfish LDAP user configuration.
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

** Test Cases **
Verify LDAP Configuration Created
    [Documentation]  Verify LDAP configuration is created.
    [Tags]  Verify_LDAP_Configuration_Created


    ${resp}=  Redfish_Utils.Get Attribute  /redfish/v1/AccountService
    ...  ${LDAP_TYPE}
    Should not be empty  ${resp}  msg=LDAP configuration is not defined


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
Test Setup Execution
    [Documentation]  Do test case setup tasks.
    redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    FFDC On Test Case Fail
    redfish.Logout


Get LDAP Configuration
    [Documentation]  Retrieve LDAP Configuration.
    [Arguments]   ${LDAP_TYPE}
    #  LDAP_TYPE:  it can be either ActiveDirectory or LDAP (openldap).


    ${ldap_config}=  Redfish.Get  /redfish/v1/AccountService
    @{ldap_configuration}=  Get From Dictionary  ${ldap_config.dict}  ${LDAP_TYPE}
    [Return]  @{ldap_configuration}

