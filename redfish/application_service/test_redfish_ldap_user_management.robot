*** Settings ***
Documentation    Test Redfish LDAP user management.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


** Test Cases **

Verify AccountService Available
    [Documentation]  Verify Redfish AccountService Exist.
    [Tags]  Verify_AccountService_Available

    ${resp} =  redfish.Get  /redfish/v1/AccountService
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
    Should Be Equal As Strings  ${resp.dict["ServiceEnabled"]}  ${True}


Verify LDAP Service Available
    [Documentation]  Verify LDAP service Exist.
    [Tags]  Verify LDAP_Service_Available

    ${resp} =  redfish.Get  /redfish/v1/LDAPService
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
    Should Not Be Empty  ${resp}


Verify LDAP SearchSettings Set
    [Documentation]  Verify LDAP SearchSettings is set.
    [Tags]  Verify LDAP_SearchSettings_Set

    ${resp} =  redfish.Get  /redfish/v1/LDAPSearchSettings
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
    Should Not Be Empty  ${resp}


*** Keywords ***


Test Setup Execution
    [Documentation]  Test setup with Redfish login.

    redfish.Login

Test Teardown Execution
    [Documentation]  To logut Redfish session.

    FFDC On Test Case Fail
    redfish.Logout
