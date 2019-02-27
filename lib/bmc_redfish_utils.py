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

    def get_redfish_session_info(self):
        r"""
        Returns redfish sessions info dictionary.

        {
            'key': 'yLXotJnrh5nDhXj5lLiH' ,
            'location': '/redfish/v1/SessionService/Sessions/nblYY4wlz0'
        }
        """
        session_dict = {
            "key": self._redfish_._session_key_,
            "location": self._redfish_._session_location_
        }
        return session_dict

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

    def get_properties(self, resource_path):
        r"""
        Returns dictionary of attributes for the resource.

        Description of argument(s):
        resource_path    URI resource absolute path (e.g. "/redfish/v1/Systems/1").
        """

        resp = self._redfish_.get(resource_path)
        return resp.dict

    def get_target_actions(self, resource_path, target_attribute):
        r"""
        Get resource attribute.

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
            # JsonSchemas data are not required in enumeration.
            # Example: '/redfish/v1/JsonSchemas/' and sub resources.
            if 'JsonSchemas' in resource:
                continue
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
