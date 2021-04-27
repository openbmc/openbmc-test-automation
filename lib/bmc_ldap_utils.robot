*** Keywords ***

Get LDAP Configuration Using Redfish
    [Documentation]  Retrieve LDAP Configuration.
    [Arguments]   ${ldap_type}

    # Description of argument(s):
    # ldap_type  The LDAP type ("ActiveDirectory" or "LDAP").

    ${ldap_config}=  Redfish.Get Properties  ${REDFISH_BASE_URI}AccountService
    [Return]  ${ldap_config["${ldap_type}"]}


Get LDAP Privilege And Group Name Via Redfish
    [Documentation]  Get LDAP groupname via redfish.

    # Get LDAP configuration via redfish.
    ${ldap_config}=  Get LDAP Configuration Using Redfish  ${LDAP_TYPE}
    ${num_list_entries}=  Get Length  ${ldap_config["RemoteRoleMapping"]}
    Return From Keyword If  ${num_list_entries} == ${0}  @{EMPTY}
    ${ldap_group_names}=  Create List
    FOR  ${i}  IN RANGE  ${num_list_entries}
      Append To List  ${ldap_group_names}  ${ldap_config["RemoteRoleMapping"][${i}]["RemoteGroup"]}
    END

    [Return]  ${ldap_group_names}

