#!/usr/bin/env python3

r"""
This module contains functions having to do with redfish path walking.
"""

import json
import subprocess

ERROR_RESPONSE = {
    "404": "Response Error: status_code: 404 -- Not Found",
    "500": "Response Error: status_code: 500 -- Internal Server Error",
}

# Variable to hold enumerated data.
result = {}

# Variable to hold the pending list of resources for which enumeration.
# is yet to be obtained.
pending_enumeration = set()


def execute_redfish_cmd(parms, json_type="json"):
    r"""
    Execute a Redfish command and return the output in the specified JSON
    format.

    This function executes a provided Redfish command using the redfishtool
    and returns the output in the specified JSON format. The function takes
    the parms argument, which is expected to be a qualified string containing
    the redfishtool command line URI and required parameters.

    The function also accepts an optional json_type parameter, which specifies
    the desired JSON format for the output (either "json" or "yaml").

    The function returns the output of the executed command as a string in the
    specified JSON format.

    Parameters:
        parms (str):               A qualified Redfish command line string.
        json_type (str, optional): The desired JSON format for the output.
                                   Defaults to "json".

    Returns:
        str: The output of the executed command as a string in the specified
             JSON format.
    """
    resp = subprocess.run(
        [parms],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=True,
        universal_newlines=True,
    )

    if resp.stderr:
        print("\n\t\tERROR with %s " % parms)
        print("\t\t" + resp.stderr)
        return resp.stderr
    elif json_type == "json":
        json_data = json.loads(resp.stdout)
        return json_data
    else:
        return resp.stdout


def enumerate_request(hostname, username, password, url, return_json="json"):
    r"""
    Perform a GET enumerate request and return available resource paths.

    This function performs a GET enumerate request on the specified URI
    resource and returns the available resource paths.

    The function takes the remote host details (hostname, username, password)
    and the URI resource absolute path as arguments. The function also accepts
    an optional return_json parameter, which specifies whether the result
    should be returned as a JSON string or as a dictionary.

    The function returns the available resource paths as a list of strings.

    Parameters:
        hostname (str):              Name or IP address of the remote host.
        username (str):              User on the remote host with access to
                                     files.
        password (str):              Password for the user on the remote host.
        url (str):                   URI resource absolute path e.g.
                                     /redfish/v1/SessionService/Sessions
        return_json (str, optional): Indicates whether the result should be
                                     returned as a JSON string or as a
                                     dictionary. Defaults to "json".

    Returns:
        list: A list of available resource paths as strings.
    """
    parms = (
        "redfishtool -u "
        + username
        + " -p "
        + password
        + " -r "
        + hostname
        + " -S Always raw GET "
    )

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
            #          '/redfish/v1/Managers/${MANAGER_ID}#/Oem'
            if (
                ("JsonSchemas" in resource)
                or ("SessionService" in resource)
                or ("PostCodes" in resource)
                or ("Registries" in resource)
                or ("#" in resource)
            ):
                continue

            response = execute_redfish_cmd(parms + resource)
            # Enumeration is done for available resources ignoring the
            # ones for which response is not obtained.
            if "Error getting response" in response:
                continue

            walk_nested_dict(response, url=resource)

        enumerated_resources.update(set(resources_to_be_enumerated))
        resources_to_be_enumerated = tuple(
            pending_enumeration - enumerated_resources
        )

    if return_json == "json":
        return json.dumps(
            result, sort_keys=True, indent=4, separators=(",", ": ")
        )
    else:
        return result


def walk_nested_dict(data, url=""):
    r"""
    Parse through the nested dictionary and extract resource ID paths.

    This function traverses a nested dictionary and extracts resource ID paths.
    The function takes the data argument, which is expected to be a nested
    dictionary containing resource information.

    The function also accepts an optional url argument, which specifies the
    resource for which the response is obtained in the data dictionary.

    The function returns a list of resource ID paths as strings.

    Parameters:
        data (dict):         A nested dictionary containing resource
                             information.
        url (str, optional): The resource for which the response is obtained
                             in the data dictionary. Defaults to an empty
                             string.

    Returns:
        list: A list of resource ID paths as strings.
    """
    url = url.rstrip("/")

    for key, value in data.items():
        # Recursion if nested dictionary found.
        if isinstance(value, dict):
            walk_nested_dict(value)
        else:
            # Value contains a list of dictionaries having member data.
            if "Members" == key:
                if isinstance(value, list):
                    for memberDict in value:
                        if isinstance(memberDict, str):
                            pending_enumeration.add(memberDict)
                        else:
                            pending_enumeration.add(memberDict["@odata.id"])

            if "@odata.id" == key:
                value = value.rstrip("/")
                # Data for the given url.
                if value == url:
                    result[url] = data
                # Data still needs to be looked up,
                else:
                    pending_enumeration.add(value)


def get_key_value_nested_dict(data, key):
    r"""
    Parse through the nested dictionary and retrieve the value associated with
    the searched key.

    This function traverses a nested dictionary and retrieves the value
    associated with the searched key. The function takes the data argument,
    which is expected to be a nested dictionary containing resource
    information.

    The function also accepts a key argument, which specifies the key to
    search for in the nested dictionary.

    The function returns the value associated with the searched key as a
    string.

    Parameters:
        data (dict): A nested dictionary containing resource information.
        key (str):   The key to search for in the nested dictionary.

    Returns:
        str: The value associated with the searched key as a string.
    """
    for k, v in data.items():
        if isinstance(v, dict):
            get_key_value_nested_dict(v, key)
