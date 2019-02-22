*** Settings ***
Documentation    Test Redfish LDAP user configuration.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


** Test Cases **

Verify LDAP Service Available
    [Documentation]  Verify LDAP service is available.
    [Tags]  Verify_LDAP_Service_Available

    Check Redfish URL Exist  /redfish/v1/LDAPService


Verify LDAP SearchSettings Set
    [Documentation]  Verify LDAP search settings is set.
    [Tags]  Verify_LDAP_SearchSettings_Set

    Check Redfish URL Exist  /redfish/v1/LDAPSearchSettings


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    redfish.Logout


Check Redfish URL Exist
    [Documentation]  Verify given redfish URL exist.
    [Arguments]   ${redfish_url}

    # Description of argument(s):
    # redfish_url redfish url.

    ${resp} =  redfish.Get  ${redfish_url}
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
