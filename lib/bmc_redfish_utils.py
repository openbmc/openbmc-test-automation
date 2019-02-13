#!/usr/bin/env python

r"""
BMC redfish utility functions.
"""

import json
from robot.libraries.BuiltIn import BuiltIn


class bmc_redfish_utils(object):

    def __init__(self):
        r"""
        Initialize the bmc_redfish_utils object.
        """
        # Obtain a reference to the global redfish object.
        self._redfish_ = BuiltIn().get_library_instance('redfish')

    def get_attribute(self, resource_path, attribute):
        r"""
        Get resource attribute.

        Description of argument(s):
        resource_path    URI resource absolute path (e.g. "/redfish/v1/Systems/1").
        attribute        Name of the attribute (e.g. 'PowerState').
        """

        resp = self._redfish_.get(resource_path)
        if attribute in resp.dict:
            return resp.dict[attribute]

        return None

    def list_request(self, resource_path):
        r"""
        Perform a GET list request and return available resource paths.

        Description of argument(s):
        resource_path  URI resource absolute path
                       (e.g. "/redfish/v1/SessionService/Sessions").
        """

        global resource_list
        resource_list = []

        self._rest_response_ = self._redfish_.get(resource_path)

        # Return empty list.
        if self._rest_response_.status != 200:
            return resource_list

        self.walk_nested_dict(self._rest_response_.dict)

        if not resource_list:
            return uri_path

        for resource in resource_list:
            self._rest_response_ = self._redfish_.get(resource)
            if self._rest_response_.status != 200:
                continue
            self.walk_nested_dict(self._rest_response_.dict)

        resource_list.sort()
        return resource_list

    def enumerate_request(self, resource_path):
        r"""
        Perform a GET enumerate request and return available resource paths.

        Description of argument(s):
        resource_path  URI resource absolute path
                       (e.g. "/redfish/v1/SessionService/Sessions").
        """

        url_list = self.list_request(resource_path)

        resource_dict = {}

        # Return empty dict.
        if not url_list:
            return resource_dict

        for resource in url_list:
            self._rest_response_ = self._redfish_.get(resource)
            if self._rest_response_.status != 200:
                continue
            resource_dict[resource] = self._rest_response_.dict

        return json.dumps(resource_dict, sort_keys=True,
                          indent=4, separators=(',', ': '))

    def walk_nested_dict(self, data):
        r"""
        Parse through the nested dictionary and get the resource id paths.

        Description of argument(s):
        data    Nested dictionary data from response message.
        """

        for key, value in data.items():
            if isinstance(value, dict):
                self.walk_nested_dict(value)
            else:
                if 'Members' == key:
                    if isinstance(value, list):
                        for index in value:
                            if index['@odata.id'] not in resource_list:
                                resource_list.append(index['@odata.id'])
                if '@odata.id' == key:
                    if value not in resource_list and not value.endswith('/'):
                        resource_list.append(value)
