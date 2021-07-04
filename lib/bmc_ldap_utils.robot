*** Settings ***
Documentation  This module provides general keywords for LDAP.

*** Keywords ***

Get LDAP Configuration Using Redfish
    [Documentation]  Retrieve LDAP Configuration.
    [Arguments]   ${ldap_type}

    # Description of argument(s):
    # ldap_type  The LDAP type ("ActiveDirectory" or "LDAP").

    ${ldap_config}=  Redfish.Get Properties  ${REDFISH_BASE_URI}AccountService
    [Return]  ${ldap_config["${ldap_type}"]}


Get LDAP Privilege And Group Name Via Redfish
    [Documentation]  Get LDAP groupname via Redfish.

    # Get LDAP configuration via Redfish.
    # Sample output of LDAP configuration:
    # {
    #  'RemoteRoleMapping': [
    #    {
    #     'RemoteGroup': 'openldapgroup',
    #     'LocalRole': 'Administrator'
    #     },
    #   ],
    #  'Authentication':
    #   {
    #    'Username': 'cn=Administrator,dc=ldap,dc=com',
    #    'Password': None,
    #    'AuthenticationType': 'UsernameAndPassword'
    #   },
    #  'LDAPService':
    #    {
    #     'SearchSettings':
    #      {
    #       'BaseDistinguishedNames': ['dc=ldap,dc=com'],
    #       'UsernameAttribute': 'cn',
    #       'GroupsAttribute': 'gidNumber'
    #      }
    #    },
    #  'ServiceEnabled': True,
    #  'Certificates':
    #    {
    #      '@odata.id': u'/redfish/v1/AccountService/LDAP/Certificates'
    #    },
    #  'ServiceAddresses': ['ldap://xx.xx.xx.xx/']
    # }

    ${ldap_config}=  Get LDAP Configuration Using Redfish  ${LDAP_TYPE}
    ${num_list_entries}=  Get Length  ${ldap_config["RemoteRoleMapping"]}
    Return From Keyword If  ${num_list_entries} == ${0}  @{EMPTY}
    ${ldap_group_names}=  Create List
    FOR  ${i}  IN RANGE  ${num_list_entries}
      Append To List  ${ldap_group_names}  ${ldap_config["RemoteRoleMapping"][${i}]["RemoteGroup"]}
    END

    [Return]  ${ldap_group_names}


Create LDAP Configuration
    [Documentation]  Create LDAP configuration.
    [Arguments]  ${ldap_type}=${LDAP_TYPE}  ${ldap_server_uri}=${LDAP_SERVER_URI}
    ...  ${ldap_bind_dn}=${LDAP_BIND_DN}  ${ldap_bind_dn_password}=${LDAP_BIND_DN_PASSWORD}
    ...  ${ldap_base_dn}=${LDAP_BASE_DN}

    # Description of argument(s):
    # ldap_type              The LDAP type ("ActiveDirectory" or "LDAP").
    # ldap_server_uri        LDAP server uri (e.g. ldap://XX.XX.XX.XX).
    # ldap_bind_dn           The LDAP bind distinguished name.
    # ldap_bind_dn_password  The LDAP bind distinguished name password.
    # ldap_base_dn           The LDAP base distinguished name.

    ${body}=  Catenate  {'${ldap_type}':
    ...  {'ServiceEnabled': ${True},
    ...   'ServiceAddresses': ['${ldap_server_uri}'],
    ...   'Authentication':
    ...       {'AuthenticationType': 'UsernameAndPassword',
    ...        'Username':'${ldap_bind_dn}',
    ...        'Password': '${ldap_bind_dn_password}'},
    ...   'LDAPService':
    ...       {'SearchSettings':
    ...           {'BaseDistinguishedNames': ['${ldap_base_dn}']}}}}

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService  body=${body}
    Sleep  15s
