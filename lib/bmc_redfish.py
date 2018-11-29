#!/usr/bin/env python

r"""
BMC redfish class using python based redfish library.
Refer: https://github.com/DMTF/python-redfish-library
"""

import redfish
import json


class HTTPSBadRequestError(Exception):
    r"""
    BMC redfish generic raised method for error(s).
    """
    pass


class bmc_redfish(object):

    def __init__(self, bmc_host, bmc_username, bmc_password):
        r"""
        Establish session connection to host.

        Description of Arguments:
        bmc_host       BMC DNS name or IP address.
        bmc_username   The username to be used to login to the BMC.
        bmc_password   The password to be used to login to the BMC.
        """

        self.base_url = "https://" + bmc_host
        self.bmc_username = bmc_username
        self.bmc_password = bmc_password
        self.default_prefix = "/redfish/v1"
        self.login_session(bmc_host, bmc_username, bmc_password)

    def login_session(self, bmc_host, bmc_username, bmc_password):
        r"""
        Login redfish connection session.

        Description of Arguments:
        bmc_host       BMC DNS name or IP address.
        bmc_username   The username to be used to login to the BMC.
        bmc_password   The password to be used to login to the BMC.
        """
        self.session = \
            redfish.redfish_client(base_url=self.base_url,
                                   username=self.bmc_username,
                                   password=self.bmc_password,
                                   default_prefix=self.default_prefix)
        self.session.login(auth=redfish.AuthMethod.SESSION)
        self.session_key = self.session.get_session_key()
        self.session_loc = self.session.get_session_location()

    def get_method(self, resource_path):
        r"""
        Perform a GET request and return response.

        Description of Arguments:
        resource_path    URI resource relative path (e.g. "Systems/1").
        """
        uri_path = '/redfish/v1/' + resource_path
        resp = self.session.get(uri_path)
        if resp.status != 200:
            raise HTTPSBadRequestError("GET Session location: %s, "
                                       "return code: %d"
                                       % (self.session_loc, resp.status))
        return resp

    def post_method(self, resource_path, actions, action_type):
        r"""
        Perform a POST request.

        Description of Arguments:
        resource_path    URI resource relative path
                         (e.g. "Systems/1/Actions/ComputerSystem.Reset").
        actions          Member resource action (e.g. "ResetType").
        action_type      Type of operation
                         (e.g. "On", "ForceOff", "GracefulRestart",
                               "GracefulShutdown").
        """
        payload = {actions: action_type}
        uri_path = '/redfish/v1/' + resource_path
        resp = self.session.post(uri_path, body=payload)
        if resp.status != 200:
            raise HTTPSBadRequestError("POST Session location: %s, "
                                       "return code: %d"
                                       % (self.session_loc, resp.status))
        return resp

    def patch_method(self, resource_path, actions, action_type):
        r"""
        Perform a POST request.

        Description of Arguments:
        resource_path    URI resource relative path
        actions          Member resource action.
        action_type      Type of operation
        """
        payload = {actions: action_type}
        uri_path = '/redfish/v1/' + resource_path
        resp = self.session.patch(uri_path, body=payload)
        if resp.status != 200:
            raise HTTPSBadRequestError("PATCH Session location: %s, "
                                       "return code: %d"
                                       % (self.session_loc, resp.status))
        return resp

    def put_method(self, resource_path, actions, attr_data):
        r"""
        Perform a PUT request.

        Description of Arguments:
        resource_path    URI resource relative path.
        actions          Member resource action.
        attr_data        Value to write.
        """
        payload = {actions: attr_data}
        uri_path = '/redfish/v1/' + resource_path
        resp = self.session.put(uri_path, body=payload)
        if resp.status != 200:
            raise HTTPSBadRequestError("PUT Session location: %s, "
                                       "return code: %d"
                                       % (self.session_loc, resp.status))
        return resp

    def delete_method(self, resource_path):
        r"""
        Perform a POST request.

        Description of Arguments:
        resource_path  URI resource absoulute path
                       (e.g. "/redfish/v1/SessionService/Sessions/8d1a9wiiNL").
        """
        resp = self.session.delete(uri_path)
        if resp.status != 200:
            raise HTTPSBadRequestError("Session location: %s, "
                                       "return code: %d"
                                       % (self.session_loc, resp.status))
        return resp

    def logout_session(self):
        r"""
        Logout redfish connection session.
        """
        self.session.logout()

    def list_method(self, resource_path):
        r"""
        Perform a GET list request and return available resource paths.

        Description of Arguments:
        resource_path    URI resource relative path (e.g. "Systems/1").
        """

        uri_path = '/redfish/v1/' + resource_path
        resp = self.session.get(uri_path)

        global resource_list
        resource_list = []
        self.walk_nested_dict(resp.dict)

        if not resource_list:
            return uri_path

        for resource in resource_list:
            resp = self.session.get(resource)
            if resp.status != 200:
                continue
            self.walk_nested_dict(resp.dict)

        return json.dumps(resource_list, sort_keys=True,
                          indent=4, separators=(',', ': '))

    def enumerate_method(self, resource_path):
        r"""
        Perform a GET enumerate request and return available resource paths.

        Description of Arguments:
        resource_path    URI resource relative path (e.g. "Systems/1").
        """

        resp = self.list_method(resource_path)

        resource_dict = {}
        for resource in json.loads(resp):
            resp = self.session.get(resource)
            if resp.status != 200:
                continue
            resource_dict[resource] = resp.dict

        return json.dumps(resource_dict, sort_keys=True,
                          indent=4, separators=(',', ': '))

    def walk_nested_dict(self, data):
        r"""
        Parse through the nested dictionary and get the resource id paths.

        Description of Arguments:
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
                    if value not in resource_list:
                        resource_list.append(value)
