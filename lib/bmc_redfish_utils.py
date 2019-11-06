#!/usr/bin/env python

r"""
BMC redfish utility functions.
"""

import json
from robot.libraries.BuiltIn import BuiltIn
import gen_print as gp


class bmc_redfish_utils(object):

    def __init__(self):
        r"""
        Initialize the bmc_redfish_utils object.
        """
        # Obtain a reference to the global redfish object.
        self._redfish_ = BuiltIn().get_library_instance('redfish')

    def get_redfish_session_info(self):
        r"""
        Returns redfish sessions info dictionary.

        {
            'key': 'yLXotJnrh5nDhXj5lLiH' ,
            'location': '/redfish/v1/SessionService/Sessions/nblYY4wlz0'
        }
        """
        session_dict = {
            "key": self._redfish_.get_session_key(),
            "location": self._redfish_.get_session_location()
        }
        return session_dict

    def get_attribute(self, resource_path, attribute, verify=None):
        r"""
        Get resource attribute.

        Description of argument(s):
        resource_path               URI resource absolute path (e.g.
                                    "/redfish/v1/Systems/1").
        attribute                   Name of the attribute (e.g. 'PowerState').
        """

        resp = self._redfish_.get(resource_path)

        if verify:
            if resp.dict[attribute] == verify:
                return resp.dict[attribute]
            else:
                raise ValueError("Attribute value is not equal")
        elif attribute in resp.dict:
            return resp.dict[attribute]

        return None

    def get_properties(self, resource_path):
        r"""
        Returns dictionary of attributes for the resource.

        Description of argument(s):
        resource_path               URI resource absolute path (e.g.
                                    /redfish/v1/Systems/1").
        """

        resp = self._redfish_.get(resource_path)
        return resp.dict

    def get_target_actions(self, resource_path, target_attribute):
        r"""
        Returns resource target entry of the searched target attribute.

        Description of argument(s):
        resource_path      URI resource absolute path
                           (e.g. "/redfish/v1/Systems/system").
        target_attribute   Name of the attribute (e.g. 'ComputerSystem.Reset').

        Example:
        "Actions": {
        "#ComputerSystem.Reset": {
        "ResetType@Redfish.AllowableValues": [
            "On",
            "ForceOff",
            "GracefulRestart",
            "GracefulShutdown"
        ],
        "target": "/redfish/v1/Systems/system/Actions/ComputerSystem.Reset"
        }
        }
        """

        global target_list
        target_list = []

        resp_dict = self.get_attribute(resource_path, "Actions")
        if resp_dict is None:
            return None

        # Recursively search the "target" key in the nested dictionary.
        # Populate the target_list of target entries.
        self.get_key_value_nested_dict(resp_dict, "target")
        # Return the matching target URL entry.
        for target in target_list:
            # target "/redfish/v1/Systems/system/Actions/ComputerSystem.Reset"
            if target_attribute in target:
                return target

        return None

    def get_member_list(self, resource_path):
        r"""
        Perform a GET list request and return available members entries.

        Description of argument(s):
        resource_path  URI resource absolute path
                       (e.g. "/redfish/v1/SessionService/Sessions").

        "Members": [
            {
             "@odata.id": "/redfish/v1/SessionService/Sessions/Z5HummWPZ7"
            }
            {
             "@odata.id": "/redfish/v1/SessionService/Sessions/46CmQmEL7H"
            }
        ],
        """

        member_list = []
        resp_list_dict = self.get_attribute(resource_path, "Members")
        if resp_list_dict is None:
            return member_list

        for member_id in range(0, len(resp_list_dict)):
            member_list.append(resp_list_dict[member_id]["@odata.id"])

        return member_list

    def list_request(self, resource_path):
        r"""
        Perform a GET list request and return available resource paths.
        Description of argument(s):
        resource_path  URI resource absolute path
                       (e.g. "/redfish/v1/SessionService/Sessions").
        """
        gp.qprint_executing(style=gp.func_line_style_short)
        # Set quiet variable to keep subordinate get() calls quiet.
        quiet = 1
        self.__pending_enumeration = set()
        self._rest_response_ = \
            self._redfish_.get(resource_path,
                               valid_status_codes=[200, 404, 500])

        # Return empty list.
        if self._rest_response_.status != 200:
            return self.__pending_enumeration
        self.walk_nested_dict(self._rest_response_.dict)
        if not self.__pending_enumeration:
            return resource_path
        for resource in self.__pending_enumeration.copy():
            self._rest_response_ = \
                self._redfish_.get(resource,
                                   valid_status_codes=[200, 404, 500])

            if self._rest_response_.status != 200:
                continue
            self.walk_nested_dict(self._rest_response_.dict)
        return list(sorted(self.__pending_enumeration))

    def enumerate_request(self, resource_path, return_json=1,
                          include_dead_resources=False):
        r"""
        Perform a GET enumerate request and return available resource paths.

        Description of argument(s):
        resource_path               URI resource absolute path (e.g.
                                    "/redfish/v1/SessionService/Sessions").
        return_json                 Indicates whether the result should be
                                    returned as a json string or as a
                                    dictionary.
        include_dead_resources      Check and return a list of dead/broken URI
                                    resources.
        """

        gp.qprint_executing(style=gp.func_line_style_short)

        return_json = int(return_json)

        # Set quiet variable to keep subordinate get() calls quiet.
        quiet = 1

        # Variable to hold enumerated data.
        self.__result = {}

        # Variable to hold the pending list of resources for which enumeration.
        # is yet to be obtained.
        self.__pending_enumeration = set()

        self.__pending_enumeration.add(resource_path)

        # Variable having resources for which enumeration is completed.
        enumerated_resources = set()

        if include_dead_resources:
            dead_resources = {}

        resources_to_be_enumerated = (resource_path,)

        while resources_to_be_enumerated:
            for resource in resources_to_be_enumerated:
                # JsonSchemas and SessionService data are not required in enumeration.
                # Example: '/redfish/v1/JsonSchemas/' and sub resources.
                #          '/redfish/v1/SessionService'
                if ('JsonSchemas' in resource) or ('SessionService' in resource):
                    continue

                self._rest_response_ = \
                    self._redfish_.get(resource, valid_status_codes=[200, 404, 500])
                # Enumeration is done for available resources ignoring the
                # ones for which response is not obtained.
                if self._rest_response_.status != 200:
                    if include_dead_resources:
                        try:
                            dead_resources[self._rest_response_.status].append(
                                resource)
                        except KeyError:
                            dead_resources[self._rest_response_.status] = \
                                [resource]
                    continue

                self.walk_nested_dict(self._rest_response_.dict, url=resource)

            enumerated_resources.update(set(resources_to_be_enumerated))
            resources_to_be_enumerated = \
                tuple(self.__pending_enumeration - enumerated_resources)

        if return_json:
            if include_dead_resources:
                return json.dumps(self.__result, sort_keys=True,
                                  indent=4, separators=(',', ': ')), dead_resources
            else:
                return json.dumps(self.__result, sort_keys=True,
                                  indent=4, separators=(',', ': '))
        else:
            if include_dead_resources:
                return self.__result, dead_resources
            else:
                return self.__result

    def walk_nested_dict(self, data, url=''):
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
                self.walk_nested_dict(value)
            else:
                # Value contains a list of dictionaries having member data.
                if 'Members' == key:
                    if isinstance(value, list):
                        for memberDict in value:
                            self.__pending_enumeration.add(memberDict['@odata.id'])
                if '@odata.id' == key:
                    value = value.rstrip('/')
                    # Data for the given url.
                    if value == url:
                        self.__result[url] = data
                    # Data still needs to be looked up,
                    else:
                        self.__pending_enumeration.add(value)

    def get_key_value_nested_dict(self, data, key):
        r"""
        Parse through the nested dictionary and get the searched key value.

        Description of argument(s):
        data    Nested dictionary data from response message.
        key     Search dictionary key element.
        """

        for k, v in data.items():
            if isinstance(v, dict):
                self.get_key_value_nested_dict(v, key)

            if k == key:
                target_list.append(v)
