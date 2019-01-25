*** Settings ***
Documentation    Test Redfish LDAP user management.

Resource         ../lib/redfish_client.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


** Test Cases **

Verify AccountService Available
    [Documentation]  Verify Redfish AccountService Exist.
    [Tags]  Verify_AccountService_Available

    ${resp} =  Redfish Get Request
    ...  AccountService  xauth_token=${test_auth_token}
    Should Be Equal As Strings  ${resp["ServiceEnabled"]}  True


Verify LDAP Service Available
    [Documentation]  Verify LDAP service Exist.
    [Tags]  Verify LDAP_Service_Available

    ${resp} =  Redfish Get Request
    ...  LDAPService  xauth_token=${test_auth_token}
    Log to Console  ${resp}
    Should Not Be Empty  ${resp}


Verify LDAP SearchSettings Set
    [Documentation]  Verify LDAP SearchSettings is set.
    [Tags]  Verify LDAP_SearchSettings_Set

    ${resp} =  Redfish Get Request
    ...  LDAPSearchSettings  xauth_token=${test_auth_token}
    Should Not Be Empty  ${resp}


*** Keywords ***


Test Setup Execution
    [Documentation]  Test setup with Redfish login.

    ${session_id}  ${auth_token} =  Redfish Login Request
    Set Test Variable  ${test_session_id}  ${session_id}
    Set Test Variable  ${test_auth_token}  ${auth_token}


Test Teardown Execution
    [Documentation]  To delete Redfish session.

    ${session_uri} =
    ...  Catenate  SEPARATOR=  ${REDFISH_SESSION_URI}  ${test_session_id}

    Redfish Delete Request  ${session_uri}  ${test_auth_token}
