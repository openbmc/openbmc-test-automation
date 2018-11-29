#!/usr/bin/env python

r"""
BMC redfish class using python based redfish library.
Refer: https://github.com/DMTF/python-redfish-library
"""

import redfish
import json
from robot.libraries.BuiltIn import BuiltIn


class HTTPSBadRequestError(Exception):
    r"""
    BMC redfish generic raised method for error(s).
    """
    pass


class bmc_redfish(object):

    def __init__(self, hostname, username, password, *args, **kwargs):
        r"""
        Establish session connection to host.

        Description of argument(s):
        hostname       The host name or IP address of the server.
        username       The username to be used to connect to the server.
        password       The password to be used to connect to the server.
        args/kwargs    Additional parms which are passed directly
                       to the redfish_client function.
        """

        self._base_url_ = "https://" + hostname
        self._username_ = username
        self._password_ = password
        self._default_prefix_ = "/redfish/v1"
        self.robj = \
            redfish.redfish_client(base_url=self._base_url_,
                                   username=self._username_,
                                   password=self._password_,
                                   default_prefix=self._default_prefix_,
                                   *args, **kwargs)
        self.robj.login(auth=redfish.AuthMethod.SESSION)
        self.session_key = self.robj.get_session_key()
        self.session_loc = self.robj.get_session_location()

    def __enter__(self):
        return self

    def __exit__(self, exception_type, exception_value, traceback):
        self.robj.logout()

    def login_session(self, *args, **kwargs):
        r"""
        Login redfish connection session.
        """
        self.robj.__init__(self._base_url_, self._username_, self._password_)
        self.robj.login(auth=redfish.AuthMethod.SESSION)

    def get_call_request(self, resource_path):
        r"""
        Perform a GET request and return response.

        Description of argument(s):
        resource_path    URI resource relative path (e.g. "Systems/1").
        """
        self._rest_response_ = self.robj.get('/redfish/v1/' + resource_path)
        if self._rest_response_.status != 200:
            raise HTTPSBadRequestError("GET Session location: %s, "
                                       "return code: %d"
                                       % (self.session_loc,
                                          self._rest_response_.status))
        return self._rest_response_

    def post_call_request(self, resource_path, actions, action_type):
        r"""
        Perform a POST request.

        Description of argument(s):
        resource_path    URI resource relative path
                         (e.g. "Systems/1/Actions/ComputerSystem.Reset").
        actions          Member resource action (e.g. "ResetType").
        action_type      Type of operation
                         (e.g. "On", "ForceOff", "GracefulRestart",
                               "GracefulShutdown").
        """
        payload = {actions: action_type}
        self._rest_response_ = self.robj.post('/redfish/v1/' + resource_path,
                                              body=payload)
        if self._rest_response_.status != 200:
            raise HTTPSBadRequestError("POST Session location: %s, "
                                       "return code: %d"
                                       % (self.session_loc,
                                          self._rest_response_.status))
        return self._rest_response_

    def patch_call_request(self, resource_path, actions, action_type):
        r"""
        Perform a POST request.

        Description of argument(s):
        resource_path    URI resource relative path
        actions          Member resource action.
        action_type      Type of operation
        """
        payload = {actions: action_type}
        self._rest_response_ = self.robj.patch('/redfish/v1/' + resource_path,
                                               body=payload)
        if self._rest_response_.status != 200:
            raise HTTPSBadRequestError("PATCH Session location: %s, "
                                       "return code: %d"
                                       % (self.session_loc,
                                          self._rest_response_.status))
        return self._rest_response_

    def put_call_request(self, resource_path, actions, attr_data):
        r"""
        Perform a PUT request.

        Description of argument(s):
        resource_path    URI resource relative path.
        actions          Member resource action.
        attr_data        Value to write.
        """
        payload = {actions: attr_data}
        self._rest_response_ = self.robj.put('/redfish/v1/' + resource_path,
                                             body=payload)
        if self._rest_response_.status != 200:
            raise HTTPSBadRequestError("PUT Session location: %s, "
                                       "return code: %d"
                                       % (self.session_loc,
                                          self._rest_response_.status))
        return self._rest_response_

    def delete_call_request(self, resource_path):
        r"""
        Perform a POST request.

        Description of argument(s):
        resource_path  URI resource absoulute path
                       (e.g. "/redfish/v1/SessionService/Sessions/8d1a9wiiNL").
        """
        self._rest_response_ = self.robj.delete(resource_path)
        if self._rest_response_.status != 200:
            raise HTTPSBadRequestError("Session location: %s, "
                                       "return code: %d"
                                       % (self.session_loc,
                                          self._rest_response_.status))
        return self._rest_response_

    def logout_session(self):
        r"""
        Logout redfish connection session.
        """
        self.robj.logout()

    def list_call_request(self, resource_path):
        r"""
        Perform a GET list request and return available resource paths.

        Description of argument(s):
        resource_path    URI resource relative path (e.g. "Systems/1").
        """

        self._rest_response_ = self.robj.get('/redfish/v1/' + resource_path)

        global resource_list
        resource_list = []
        self.walk_nested_dict(self._rest_response_.dict)

        if not resource_list:
            return uri_path

        for resource in resource_list:
            self._rest_response_ = self.robj.get(resource)
            if self._rest_response_.status != 200:
                continue
            self.walk_nested_dict(self._rest_response_.dict)

        return json.dumps(resource_list, sort_keys=True,
                          indent=4, separators=(',', ': '))

    def enumerate_call_request(self, resource_path):
        r"""
        Perform a GET enumerate request and return available resource paths.

        Description of argument(s):
        resource_path    URI resource relative path (e.g. "Systems/1").
        """

        self._rest_response_ = self.list_call_request(resource_path)

        resource_dict = {}
        for resource in json.loads(self._rest_response_):
            self._rest_response_ = self.robj.get(resource)
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
