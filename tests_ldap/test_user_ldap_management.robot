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
    Should Be Empty  ${resp}


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
    Sleep  60s

    # REST Login to BMC with LDAP user and password.
    Initialize OpenBMC  60  1  ${LDAP_USER}  ${LDAP_USER_PASSWORD}

    ${bmc_user_uris}=  Read Properties  ${BMC_USER_URI}list
    Should Not Be Empty  ${bmc_user_uris}


Verify LDAP User Able to Logout Using REST
    [Documentation]  Verify LDAP user able to logout using REST.
    [Tags]  Verify_LDAP_User_Able_To_Logout_Using_REST

    Configure LDAP Server On BMC
    Sleep  60s
    Check LDAP Config File Generated
    Sleep  60s

    # REST Login to BMC with LDAP user and password.
    Initialize OpenBMC  60  1  ${LDAP_USER}  ${LDAP_USER_PASSWORD}

    # REST Logout from BMC.
    Log Out OpenBMC


Verify LDAP Server URI Is Set
    [Documentation]  Verify LDAP Server URI is set using REST.
    [Tags]  Verify_LDAP_Server_URI_Is_Set

    # Example: LDAP URI should be either ldap://<LDAP IP / Hostname> or
    # ldaps://<LDAP IP / Hostname>
    Should Contain  ${LDAP_SERVER_URI}  ldap
    ${ldap_server}=  Create Dictionary  data=${LDAP_SERVER_URI}
    Write Attribute  ${BMC_LDAP_URI}/config  LDAPServerURI  data=${ldap_server}
    ...  verify=${True}  expected_value=${LDAP_SERVER_URI}


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


Verify LDAP Server Type Is Set As Active Directory
    [Documentation]  Verify LDAP server type is set as "Active Directory"
    ...   using REST.
    [Tags]  Verify_LDAP_Server_Type_Is_Set_As_Active_Directory
    [Template]  Modify LDAP Server Type

     # Server type as ActiveDirectory
     xyz.openbmc_project.User.Ldap.Config.Type.ActiveDirectory


Verify LDAP Server Type Is Set As Open LDAP
    [Documentation]  Verify LDAP server type is set as "OpenLDAP"
    ...   using REST.
    [Tags]  Verify_LDAP_Server_Type_Is_Set_As_Open_LDAP
    [Template]  Modify LDAP Server Type

     # Server type as OpenLdap
     xyz.openbmc_project.User.Ldap.Config.Type.OpenLdap


Verify LDAP Search Scope Is Set As One
    [Documentation]  Verify LDAP search scope is set as "one" using REST.
    [Tags]  Verify_LDAP_Search_Scope_Is_Set_As_One
    [Template]  Modify LDAP Search Scope

     # Search Scope as one
     xyz.openbmc_project.User.Ldap.Config.SearchScope.one


Verify LDAP Search Scope Is Set As Base
    [Documentation]  Verify LDAP search scope is set as "base" using REST.
    [Tags]  Verify_LDAP_Search_Scope_Is_Set_As_Base
    [Template]  Modify LDAP Search Scope

     # Search Scope as base
     xyz.openbmc_project.User.Ldap.Config.SearchScope.base

Verify LDAP Search Scope Is Set As Sub
    [Documentation]  Verify LDAP search scope is set as "sub" using REST.
    [Tags]  Verify_LDAP_Search_Scope_Is_Set_As_Sub
    [Template]  Modify LDAP Search Scope

     # Search Scope as sub
     xyz.openbmc_project.User.Ldap.Config.SearchScope.sub


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
    [Documentation]  Check LDAP service running in BMC.

    BMC Execute Command  systemctl | grep -in ldap


Configure LDAP Server On BMC
    [Documentation]  Configure LDAP Server On BMC.

    ${LDAP_SECURE_MODE}=  Convert To Boolean  ${LDAP_SECURE_MODE}

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
    # Non-Secured ldap_server  Contains ldap server URI eg. (e.g. "ldap://x.x.x.x/").
    # Secured ldap_server  Contains ldap server URI eg. (e.g. "ldaps://x.x.x.x/").

    ${ldap_server_config}=  Read Properties  ${BMC_USER_URI}ldap/enumerate
    ${ldap_server_config}=  Convert To String  ${ldap_server_config}
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

    ${ldap_server_config}=  Read Properties  ${BMC_USER_URI}ldap/enumerate
    ${ldap_server_config}=  Convert To String  ${ldap_server_config}

    Should Not Contain  ${ldap_server_config}  ${LDAP_SERVER_URI}
    ...  msg=${ldap_server_config} is not configured.



Modify LDAP Search Scope
    [Documentation]  Modify LDAP search scope parameter in LDAP config.
    [Arguments]  ${search_scope}=${LDAP_SEARCH_SCOPE}

    # Description of argument(s):
    # search_scope  Contains ldap search scope (e.g. "xyz.openbmc_project.User.Ldap.Config.SearchScope.one").

    ${search_scope_dict}=  Create Dictionary  data=${search_scope}
    Write Attribute  ${BMC_LDAP_URI}/config   LDAPSearchScope  data=${search_scope_dict}
    ...  verify=${True}  expected_value=${search_scope}


Modify LDAP Server Type
    [Documentation]  Modify LDAP server type parameter in LDAP config.
    [Arguments]  ${ldap_type}=${LDAP_SERVER_TYPE}

    # Description of argument(s):
    # ldap_type Contains ldap server type (e.g. "xyz.openbmc_project.User.Ldap.Config.Type.ActiveDirectory").

    ${ldap_type_dict}=  Create Dictionary  data=${ldap_type}
    Write Attribute  ${BMC_LDAP_URI}/config   LDAPType  data=${ldap_type_dict}
    ...  verify=${True}  expected_value=${ldap_type}


