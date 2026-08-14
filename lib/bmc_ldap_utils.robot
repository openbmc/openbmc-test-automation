*** Settings ***
Documentation  This module provides general keywords for LDAP.

Library        OperatingSystem
Resource       certificate_utils.robot

*** Keywords ***

Get LDAP Configuration Using Redfish
    [Documentation]  Retrieve LDAP Configuration.
    [Arguments]   ${ldap_type}

    # Description of argument(s):
    # ldap_type  The LDAP type ("ActiveDirectory" or "LDAP").

    ${ldap_config}=  Redfish.Get Properties  ${REDFISH_BASE_URI}AccountService
    RETURN  ${ldap_config["${ldap_type}"]}


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
    IF  ${num_list_entries} == ${0}  RETURN  @{EMPTY}
    ${ldap_group_names}=  Create List
    FOR  ${i}  IN RANGE  ${num_list_entries}
      Append To List  ${ldap_group_names}  ${ldap_config["RemoteRoleMapping"][${i}]["RemoteGroup"]}
    END

    RETURN  ${ldap_group_names}


Create LDAP Configuration
    [Documentation]  Create LDAP configuration.
    [Arguments]  ${ldap_type}=${LDAP_TYPE}  ${ldap_server_uri}=${LDAP_SERVER_URI}
    ...  ${ldap_bind_dn}=${LDAP_BIND_DN}  ${ldap_bind_dn_password}=${LDAP_BIND_DN_PASSWORD}
    ...  ${ldap_base_dn}=${LDAP_BASE_DN}  ${version}=IPv4

    # Description of argument(s):
    # ldap_type              The LDAP type ("ActiveDirectory" or "LDAP").
    # ldap_server_uri        LDAP server uri (e.g. ldap://XX.XX.XX.XX).
    # ldap_bind_dn           The LDAP bind distinguished name.
    # ldap_bind_dn_password  The LDAP bind distinguished name password.
    # ldap_base_dn           The LDAP base distinguished name.
    # version                IP version to use for configuration ("IPv4" or "IPv6").

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

    ${patch}=  Set Variable If  '${version}' == 'IPv4'  Redfish.Patch  RedfishIPv6.Patch

    Run Keyword  ${patch}  ${REDFISH_BASE_URI}AccountService  body=${body}  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]

    Sleep  15s


Update LDAP Configuration With LDAP User Role And Group
    [Documentation]  Update LDAP configuration update with LDAP user Role and group.
    [Arguments]   ${ldap_type}  ${group_privilege}  ${group_name}  ${version}=IPv4

    # Description of argument(s):
    # ldap_type        The LDAP type ("ActiveDirectory" or "LDAP").
    # group_privilege  The group privilege ("Administrator", "Operator", "User" or "Callback").
    # group_name       The group name of user.
    # version          IP version to use for configuration ("IPv4" or "IPv6").

    ${local_role_remote_group}=  Create Dictionary  LocalRole=${group_privilege}  RemoteGroup=${group_name}
    ${remote_role_mapping}=  Create List  ${local_role_remote_group}
    ${ldap_data}=  Create Dictionary  RemoteRoleMapping=${remote_role_mapping}
    ${payload}=  Create Dictionary  ${ldap_type}=${ldap_data}

    ${patch}=  Set Variable If  '${version}' == 'IPv4'  Redfish.Patch  RedfishIPv6.Patch

    Run Keyword  ${patch}  ${REDFISH_BASE_URI}AccountService  body=&{payload}  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]

    # Provide adequate time for LDAP daemon to restart after the update.
    Sleep  15s


Upload LDAP Certificates If Provided
    [Documentation]  Upload CA and client certificates to BMC for secure LDAP (ldaps://).
    ...  Skips upload if LDAP_CA_FILE or LDAP_CLIENT_CERT_FILE variables are empty.

    # Upload CA certificate (required for ldaps:// to verify the LDAP server's TLS cert).
    IF  '${LDAP_CA_FILE}' != '${EMPTY}'
        ${bytes}=  OperatingSystem.Get Binary File  ${LDAP_CA_FILE}
        ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8
        ${already_installed}=  Is Certificate Already Installed
        ...  ${REDFISH_CA_CERTIFICATE_URI}  ${file_data}
        IF  not ${already_installed}
            Install Certificate File On BMC  ${REDFISH_CA_CERTIFICATE_URI}  ok  data=${file_data}
            Log  CA certificate uploaded from: ${LDAP_CA_FILE}
        ELSE
            Log  CA certificate already installed on BMC, skipping upload.
        END
    END

    # Upload LDAP client certificate (optional, for mutual TLS authentication).
    IF  '${LDAP_CLIENT_CERT_FILE}' != '${EMPTY}'
        ${bytes}=  OperatingSystem.Get Binary File  ${LDAP_CLIENT_CERT_FILE}
        ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8
        ${already_installed}=  Is Certificate Already Installed
        ...  ${REDFISH_LDAP_CERTIFICATE_URI}  ${file_data}
        IF  not ${already_installed}
            # Delete existing LDAP client cert if present (only one is allowed).
            ${members}=  Redfish_Utils.Get Member List  ${REDFISH_LDAP_CERTIFICATE_URI}
            FOR  ${member}  IN  @{members}
                Redfish.Delete  ${member}  valid_status_codes=[${HTTP_NO_CONTENT}]
            END
            Install Certificate File On BMC  ${REDFISH_LDAP_CERTIFICATE_URI}  ok  data=${file_data}
            Log  LDAP client certificate uploaded from: ${LDAP_CLIENT_CERT_FILE}
        ELSE
            Log  LDAP client certificate already installed on BMC, skipping upload.
        END
    END


Is Certificate Already Installed
    [Documentation]  Return True if the certificate content is already in the BMC collection.
    [Arguments]  ${collection_uri}  ${cert_content}

    # Description of argument(s):
    # collection_uri  Redfish URI of the certificate collection.
    # cert_content    PEM content of the certificate to check.

    ${members}=  Redfish_Utils.Get Member List  ${collection_uri}
    FOR  ${member}  IN  @{members}
        ${bmc_cert}=  redfish_utils.Get Attribute  ${member}  CertificateString
        ${match}=  Run Keyword And Return Status
        ...  Should Contain  ${cert_content}  ${bmc_cert}
        IF  ${match}  RETURN  ${True}
    END
    RETURN  ${False}
