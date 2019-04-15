#!/usr/bin/env python

r"""
Redfish LDAP json structure initialization.
"""
import json

json_ldap = '{"LDAP": {"ServiceEnabled": 0,\
              "ServiceAddresses": ["ldap://X.XXX.XXX.XX/"], "Authentication":{\
                "AuthenticationType": "UsernameAndPassword",\
                "Username": "uid=xxxxxx,dc=ldap,dc=com",\
                "Password": "xxxxxxxx"},\
              "LDAPService": \
              {"SearchSettings": \
                  {"BaseDistinguishedNames": ["dc=ldap,dc=com"]}}}}'

try:
    decoded_json_ldap = json.loads(json_ldap)
    # Printing of JSON formatted string
    print json.dumps(decoded_json_ldap)

except (ValueError, KeyError, TypeError):
    print "JSON Format Error"
