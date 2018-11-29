*** Settings ***
Documentation   OpenBMC user management keywords.

Resource         ../lib/rest_client.robot
Resource         ../lib/utils.robot
Library          SSHLibrary


*** Variables ****

*** Keywords ***

Create Group And Privilege
    [Documentation]  Create group and privilege for users.
    [Arguments]  ${user_group}  ${user_privilege}

    # Description of argument(s):
    # user_group  User group.
    # user_privilege  User privilege like priv-admin, priv-user.

    @{ldap_parm_list}=  Create List  ${user_group}  ${user_privilege}

    ${data}=  Create Dictionary  data=@{ldap_parm_list}

    ${resp}=  OpenBMC Post Request
    ...  ${BMC_USER_URI}ldap/action/Create  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ...  msg=Updating the new root password failed. RC=${resp.status_code}.


Create Privilege
    [Documentation]  Create privilege as priv-admin.
    [Arguments]  ${user_privilege}

    Create Group And Privilege  ${GROUP_NAME}  ${user_privilege}
    ${bmc_user_uris}=  Read Properties  ${BMC_USER_URI}ldap/enumerate
    # Sample output:
    # "data": {
    #  "/xyz/openbmc_project/user/ldap/13": {
    #  "GroupName": "redfish",
    #  "Privilege": "priv-admin"
    # },
    # "/xyz/openbmc_project/user/ldap/15": {
    #  "GroupName": "openldapgroup",
    #  "Privilege": "priv-admin"
    # },
    # "/xyz/openbmc_project/user/ldap/config": {
    #  "LDAPBaseDN": "dc=ldap,dc=com",
    #  "LDAPBindDN": "cn=Administrator,dc=ldap,dc=com",
    #  "LDAPSearchScope": "xyz.openbmc_project.User.Ldap.Config.SearchScope.sub",
    #  "LDAPServerURI": "ldaps://fspldaptest.in.ibm.com/",
    #  "LDAPType": "xyz.openbmc_project.User.Ldap.Config.Type.OpenLdap"
    # }
    #}

    ${bmc_user_uris}=  Convert To String  ${bmc_user_uris}
    Should Contain  ${bmc_user_uris}  ${user_privilege}
    ...  msg=Could not create ${user_privilege} privilege.


Suite Setup Execution
    [Documentation]  Do the initial suite setup.

    # Validating external user parameters.
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
    [Arguments]  ${ldap_server_uri}=${LDAP_SERVER_URI}

    # Description of argument(s):
    # ldap_server_uri  The LDAP server uri (e.g. "ldap://x.x.x.x/" for non-secured or ""ldaps://x.x.x.x/"" for secured).

    ${ldap_server_config}=  Read Properties  ${BMC_USER_URI}ldap/enumerate
    ${ldap_server_config}=  Convert To String  ${ldap_server_config}
    Should Contain  ${ldap_server_config}  ${ldap_server_uri}
    ...  msg=${ldap_server_uri} is not configured.


Delete LDAP Config
    [Documentation]  Delete LDAP Config via REST.

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


Get LDAP Entries
    [Documentation]  Get LDAP entries and return the object list.

    ${ldap_entry_list}=  Create List
    ${resp}=  OpenBMC Get Request  ${BMC_USER_URI}ldap/enumerate  quiet=${1}
    Return From Keyword If  ${resp.status_code} == ${HTTP_NOT_FOUND}
    ${jsondata}=  To JSON  ${resp.content}

    :FOR  ${entry}  IN  @{jsondata["data"]}
    \  Continue For Loop If  '${entry.rsplit('/', 1)[1]}' == 'callout'
    \  Append To List  ${ldap_entry_list}  ${entry}

    # LDAP entries list.
    # ['/xyz/openbmc_project/user/ldap/1',
    #  '/xyz/openbmc_project/user/ldap/2']
    [Return]  ${ldap_entry_list}


Defined LDAP Group Entry Should Exist
    [Documentation]  Find the matching group and return the entry id.
    [Arguments]  ${user_group}

    # Description of argument(s):
    # user_group(s)   contain LDAP user group string. Example: "Domain Admins"

    @{ldap_entries}=  Get LDAP Entries

    :FOR  ${ldap_entry}  IN  @{ldap_entries}
    \  ${resp}=  Read Properties  ${ldap_entry}
    \  ${status}=  Run Keyword And Return Status
    ...  Should Be Equal As Strings  ${user_group}  ${resp["GroupName"]}
    \  Return From Keyword If  ${status} == ${TRUE}  ${ldap_entry}

    Fail  No ${user_group} LDAP user group entry found.

Delete Defined LDAP Group And Privilege
    [Documentation]  Delete LDAP group and its privilege.
    [Arguments]  ${user_group}
    # user_group(s)   contain LDAP user group string. Example: "Domain Admins"

    # Description of argument(s):

    ${ldap_entry_id}=   Defined LDAP Group Entry Should Exist  ${user_group}
    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  OpenBMC Post Request  ${ldap_entry_id}/action/delete  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
