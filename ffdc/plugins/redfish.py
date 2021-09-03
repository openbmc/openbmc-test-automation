#!/usr/bin/env python3

r"""
This module contains functions having to do with redfish path walking.
"""

import os
import subprocess
import json

ERROR_RESPONSE = {
    "404": 'Response Error: status_code: 404 -- Not Found',
    "500": 'Response Error: status_code: 500 -- Internal Server Error',
}

# Variable to hold enumerated data.
result = {}

# Variable to hold the pending list of resources for which enumeration.
# is yet to be obtained.
pending_enumeration = set()


def execute_redfish_cmd(parms, json_type="json"):
    r"""
    Run CLI standard redfish tool.

    Description of variable:
    parms_string         Command to execute from the current SHELL.
    quiet                do not print tool error message if True
    """
    resp = subprocess.run([parms],
                          stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE,
                          shell=True,
                          universal_newlines=True)

    if resp.stderr:
        print('\n\t\tERROR with %s ' % parms)
        print('\t\t' + resp.stderr)
        return resp.stderr
    elif json_type == "json":
        json_data = json.loads(resp.stdout)
        return json_data
    else:
        return resp.stdout


def enumerate_request(hostname, username, password, url, return_json="json"):
    r"""
    Perform a GET enumerate request and return available resource paths.

    Description of argument(s):
    url               URI resource absolute path (e.g.
                      "/redfish/v1/SessionService/Sessions").
    return_json       Indicates whether the result should be
                      returned as a json string or as a
                      dictionary.
    """
    parms = 'redfishtool -u ' + username + ' -p ' + password + ' -r ' + \
        hostname + ' -S Always raw GET '

    pending_enumeration.add(url)

    # Variable having resources for which enumeration is completed.
    enumerated_resources = set()

    resources_to_be_enumerated = (url,)

    while resources_to_be_enumerated:
        for resource in resources_to_be_enumerated:
            # JsonSchemas, SessionService or URLs containing # are not
            # required in enumeration.
            # Example: '/redfish/v1/JsonSchemas/' and sub resources.
            #          '/redfish/v1/SessionService'
            #          '/redfish/v1/Managers/bmc#/Oem'
            if ('JsonSchemas' in resource) or ('SessionService' in resource)\
                    or ('PostCodes' in resource) or ('Registries' in resource)\
                    or ('#' in resource):
                continue

            response = execute_redfish_cmd(parms + resource)
            # Enumeration is done for available resources ignoring the
            # ones for which response is not obtained.
            if 'Response Error' in response:
                continue

            walk_nested_dict(response, url=resource)

        enumerated_resources.update(set(resources_to_be_enumerated))
        resources_to_be_enumerated = \
            tuple(pending_enumeration - enumerated_resources)

    if return_json == "json":
        return json.dumps(result, sort_keys=True,
                          indent=4, separators=(',', ': '))
    else:
        return result


def walk_nested_dict(data, url=''):
    r"""
    Parse through the nested dictionary and get the resource id paths.

    Description of argument(s):
    data    Nested dictionary data from response message.
    url     Resource for which the response is obtained in data.
    """
    url = url.rstrip('/')

    for key, value in data.items():

        # Recursion if nested dictionary found.
        if isinstance(value, dict):
            walk_nested_dict(value)
        else:
            # Value contains a list of dictionaries having member data.
            if 'Members' == key:
                if isinstance(value, list):
                    for memberDict in value:
                        if isinstance(memberDict, str):
                            pending_enumeration.add(memberDict)
                        else:
                            pending_enumeration.add(memberDict['@odata.id'])

            if '@odata.id' == key:
                value = value.rstrip('/')
                # Data for the given url.
                if value == url:
                    result[url] = data
                # Data still needs to be looked up,
                else:
                    pending_enumeration.add(value)


def get_key_value_nested_dict(data, key):
    r"""
    Parse through the nested dictionary and get the searched key value.

    Description of argument(s):
    data    Nested dictionary data from response message.
    key     Search dictionary key element.
    """

    for k, v in data.items():
        if isinstance(v, dict):
            get_key_value_nested_dict(v, key)

        if k == key:
            target_list.append(v)
