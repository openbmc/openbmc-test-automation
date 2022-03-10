*** Settings ***
Documentation  This module provides general keywords for AD.

*** Keywords ***

Get AD Configuration Using Redfish
    [Documentation]  Retrieve AD Configuration.
    [Arguments]   ${ad_type}

    # Description of argument(s):
    # ad_type  The AD type ("ActiveDirectory" or "AD").

    ${ad_config}=  Redfish.Get Properties  ${REDFISH_BASE_URI}AccountService
    [Return]  ${ad_config["${ad_type}"]}


Get AD Privilege And Group Name Via Redfish
    [Documentation]  Get AD groupname via Redfish.

    # Get AD configuration via Redfish.
    # Sample output of AD configuration:
    # {
    #  'RemoteRoleMapping': [
    #    {
    #     'RemoteGroup': 'openadgroup',
    #     'LocalRole': 'Administrator'
    #     },
    #   ],
    #  'Authentication':
    #   {
    #    'Username': 'cn=Administrator,dc=ad,dc=com',
    #    'Password': None,
    #    'AuthenticationType': 'UsernameAndPassword'
    #   },
    #  'ADService':
    #    {
    #     'SearchSettings':
    #      {
    #       'BaseDistinguishedNames': ['dc=ad,dc=com'],
    #       'UsernameAttribute': 'cn',
    #       'GroupsAttribute': 'gidNumber'
    #      }
    #    },
    #  'ServiceEnabled': True,
    #  'Certificates':
    #    {
    #      '@odata.id': u'/redfish/v1/AccountService/AD/Certificates'
    #    },
    #  'ServiceAddresses': ['ad://xx.xx.xx.xx/']
    # }

    ${ad_config}=  Get AD Configuration Using Redfish  ${AD_TYPE}
    ${num_list_entries}=  Get Length  ${ad_config["RemoteRoleMapping"]}
    Return From Keyword If  ${num_list_entries} == ${0}  @{EMPTY}
    ${ad_group_names}=  Create List
    FOR  ${i}  IN RANGE  ${num_list_entries}
      Append To List  ${ad_group_names}  ${ad_config["RemoteRoleMapping"][${i}]["RemoteGroup"]}
    END

    [Return]  ${ad_group_names}


Create AD Configuration
    [Documentation]  Create AD configuration.
    [Arguments]  ${ad_type}=${AD_TYPE}  ${ad_server_uri}=${AD_SERVER_URI}
    ...  ${ad_bind_dn}=${AD_BIND_DN}  ${ad_bind_dn_password}=${AD_BIND_DN_PASSWORD}
    ...  ${ad_base_dn}=${AD_BASE_DN}  ${ad_group_privilege}=${AD_GROUP_PRIVILEGE}
    ...  ${ad_group_name}=${AD_GROUP_NAME}

    # Description of argument(s):
    # ad_type              The AD type ("ActiveDirectory" or "AD").
    # ad_server_uri        AD server uri (e.g. ad://XX.XX.XX.XX).
    # ad_bind_dn           The AD bind distinguished name.
    # ad_bind_dn_password  The AD bind distinguished name password.
    # ad_base_dn           The AD base distinguished name.

    ${body}=  Catenate  {'${ad_type}':
    ...   {'Authentication':
    ...       {'AuthenticationType': 'UsernameAndPassword',
    ...        'Username':'${ad_bind_dn}',
    ...        'Password': '${ad_bind_dn_password}'},
    ...   'LDAPService':
    ...       {'SearchSettings':
    ...           {'BaseDistinguishedNames': ['${ad_base_dn}']}},
    ...   'RemoteRoleMapping':
    ...       [{'LocalRole':'${ad_group_privilege}',
    ...        'RemoteGroup':'${AD_GROUP_NAME}'}],
    ...   'ServiceAddresses': ['${ad_server_uri}'],
    ...   'ServiceEnabled': ${True}}}

    Redfish.Patch  ${REDFISH_BASE_URI}AccountService  body=${body}
    Sleep  15s
    # The following commands needs to be given in bmc console in order to check group id
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  ${bmc_console_ad_adding_group_cmd}