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
