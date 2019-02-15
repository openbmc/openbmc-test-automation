*** Settings ***
Documentation    Test Redfish LDAP user management.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


** Test Cases **

Verify LDAP Service Available
    [Documentation]  Verify LDAP service is available.
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
    [Documentation]  Do test case setup tasks.

    redfish.Login

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    redfish.Logout
