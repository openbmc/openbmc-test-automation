*** Settings ***
Documentation   OpenBMC LDAP user management test.

Resource         ../lib/rest_client.robot
Resource         ../lib/openbmc_ffdc.robot
Library          ../lib/bmc_ssh_utils.py

Suite Setup      Suite Setup Execution
 Test Teardown    FFDC On Test Case Fail

*** Variables ****

*** Test Cases ***

Verify LDAP API Available
    [Documentation]  Verify LDAP client service is running and API available.
    [Tags]  Verify_LDAP_API_Available

    ${resp}=  Read Properties  ${BMC_LDAP_URI}
    Should Not Be Empty  ${resp}


Verify LDAP Config Is Created
    [Documentation]  Verify LDAP config is created in BMC.
    [Tags]  Verify_LDAP_Config_Is_Created

    Configure LDAP Server On BMC
    Check LDAP Config File Generated


Verify LDAP Config Is Deleted
    [Documentation]  Verify LDAP config is deleted in BMC.
    [Tags]  Verify_LDAP_Config_Is_Deleted

    Delete LDAP Config
    Check LDAP Config File Deleted


Verify LDAP User Able To Login Using REST
    [Documentation]  Verify LDAP user able to login using REST.
    [Tags]  Verify_LDAP_User_Able_To_Login_Using_REST

    Configure LDAP Server On BMC
    Check LDAP Config File Generated

    # REST Login to BMC with LDAP user and password.
    Initialize OpenBMC  OPENBMC_USER=${LDAP_USER}
    ...  OPENBMC_PASSWORD=${LDAP_USER_PASSWORD}

    ${bmc_user_uris}=  Read Properties  ${BMC_USER_URI}list
    Should Not Be Empty  ${bmc_user_uris}


Verify LDAP User Able to Logout Using REST
    [Documentation]  Verify LDAP user able to logout using REST.
    [Tags]  Verify_LDAP_User_Able_To_Logout_Using_REST

    Configure LDAP Server On BMC
    Check LDAP Config File Generated

    # REST Login to BMC with LDAP user and password.
    Initialize OpenBMC  OPENBMC_USER=${LDAP_USER}
    ...  OPENBMC_PASSWORD=${LDAP_USER_PASSWORD}

    # REST Logout from BMC.
    Log Out OpenBMC


Verify LDAP Secure Mode Is Set
    [Documentation]  Verify LDAP Secure Mode is set using REST.
    [Tags]  Verify_LDAP_Secure_Mode_Is_Set

    ${LDAP_SECURE_MODE} =   Convert To Boolean    ${LDAP_SECURE_MODE}
    ${ldap_mode}=  Create Dictionary  data=${LDAP_SECURE_MODE}
    Write Attribute  ${BMC_LDAP_URI}/config  SecureLDAP  data=${ldap_mode}
    ...  verify=${True}  expected_value=${False}


Verify LDAP Server URI Is Set
    [Documentation]  Verify LDAP Server URI is set using REST.
    [Tags]  Verify_LDAP_Server_URI_Is_Set

    ${ldap_server}=  Create Dictionary  data=${LDAP_SERVER_URI}
    Write Attribute  ${BMC_LDAP_URI}/config  LDAPServerURI  data=${ldap_server}
    ...  verify=${True}  expected_value=${LDAP_SERVER_URI}
    # Example: LDAP URI should be either ldap://<LDAP IP / Hostname> or
    # ldaps://<LDAP IP / Hostname>
    Should Contain  ${LDAP_SERVER_URI}  ldap


Verify LDAP Server BIND DN Is Set
    [Documentation]  Verify LDAP BIND DN is set using REST.
    [Tags]  Verify_LDAP_Server_BIND_DN_Is_Set

    ${ldap_server_binddn}=  Create Dictionary  data=${LDAP_BIND_DN}
    Write Attribute  ${BMC_LDAP_URI}/config  LDAPBindDN  data=${ldap_server_binddn}
    ...  verify=${True}  expected_value=${LDAP_BIND_DN}


Verify LDAP Server BASE DN Is Set
    [Documentation]  Verify LDAP BASE DN is set using REST.
    [Tags]  Verify_LDAP_Server_BASE_DN_Is_Set

    ${ldap_server_basedn}=  Create Dictionary  data=${LDAP_BASE_DN}
    Write Attribute  ${BMC_LDAP_URI}/config  LDAPBaseDN  data=${ldap_server_basedn}
    ...  verify=${True}  expected_value=${LDAP_BASE_DN}


Verify LDAP Server Type Is Set
    [Documentation]  Verify LDAP server type is set using REST.
    [Tags]  Verify_LDAP_Server_Type_Is_Set

    ${ldap_type}=  Create Dictionary  data=${LDAP_SERVER_TYPE}
    Write Attribute  ${BMC_LDAP_URI}/config   LDAPType  data=${ldap_type}
    ...  verify=${True}  expected_value=${LDAP_SERVER_TYPE}


Verify LDAP Search Scope Is Set
    [Documentation]  Verify LDAP search scope is set using REST.
    [Tags]  Verify_LDAP_Server_Type_Is_Set

    ${search_scope}=  Create Dictionary  data=${LDAP_SEARCH_SCOPE}
    Write Attribute  ${BMC_LDAP_URI}/config   LDAPSearchScope  data=${search_scope}
    ...  verify=${True}  expected_value=${LDAP_SEARCH_SCOPE}


Verify LDAP Binddn Password Is Set
    [Documentation]  Verify LDAP Binddn password is set using REST.
    [Tags]  Verify_LDAP_Binddn_Password_Is_Set

    ${ldap_binddn_passwd}=  Create Dictionary  data=${LDAP_BIND_DN_PASSWORD}
    Write Attribute  ${BMC_LDAP_URI}/config  LDAPBINDDNpassword  data=${ldap_binddn_passwd}
    ...  verify=${True}  expected_value=${LDAP_BIND_DN_PASSWORD}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Check for LDAP test readiness.

    Should Not Be Empty  ${LDAP_SERVER_URI}
    Should Not Be Empty  ${LDAP_BIND_DN}
    Should Not Be Empty  ${LDAP_BASE_DN}
    Should Not Be Empty  ${LDAP_BIND_DN_PASSWORD}
    Should Not Be Empty  ${LDAP_SEARCH_SCOPE}
    Should Not Be Empty  ${LDAP_SERVER_TYPE}
    Check LDAP Service Running

Check LDAP Service Running
    [Documentation]  Check LDAP service running in BMC.

    BMC Execute Command  systemctl | grep -in ldap


Configure LDAP Server On BMC
    [Documentation]  Configure LDAP Server On BMC.

    ${LDAP_SECURE_MODE} =   Convert To Boolean    ${LDAP_SECURE_MODE}

    @{ldap_parm_list}=  Create List
    ...  ${LDAP_SERVER_URI}  ${LDAP_BIND_DN}
    ...  ${LDAP_BASE_DN}  ${LDAP_BIND_DN_PASSWORD}  ${LDAP_SEARCH_SCOPE}
    ...  ${LDAP_SERVER_TYPE}

    ${data}=  Create Dictionary  data=@{ldap_parm_list}

    ${resp}=  OpenBMC Post Request
    ...  ${BMC_LDAP_URI}/action/CreateConfig  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Check LDAP Config File Generated
    [Documentation]  Check LDAP file nslcd.conf generated.
    [Arguments]  ${ldap_server}=${LDAP_SERVER_URI}

    # Description of argument(s):
    # ldap_server  contains ldap server URI eg. ldap(s)://<LDAP IP>/ 

    ${ldap_server_config}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /etc/nslcd.conf   return_stderr=True

    Should Contain  ${ldap_server_config}  ${ldap_server}
    ...  msg=${ldap_server} is not configured.


Delete LDAP Config
    [Documentation]  Delete LDAP Config from REST.

    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  OpenBMC Post Request
    ...  ${BMC_LDAP_URI}/config/action/delete  data=${data}

    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Check LDAP Config File Deleted
    [Documentation]  Check LDAP file nslcd.conf deleted.

    # LDAP config file is deleted and default /etc/nslcd.conf is restored.
    BMC Execute Command  cat /etc/nslcd.conf | grep -in aix


