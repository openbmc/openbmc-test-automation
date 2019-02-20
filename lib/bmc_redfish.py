#!/usr/bin/env python

r"""
Using python based redfish library.
Refer: https://github.com/DMTF/python-redfish-library
"""

import redfish
from robot.libraries.BuiltIn import BuiltIn


class HTTPSBadRequestError(Exception):
    r"""
    BMC redfish generic raised method for error(s).
    """
    pass


class bmc_redfish(object):

    ROBOT_LIBRARY_SCOPE = "TEST SUITE"
    ROBOT_EXIT_ON_FAILURE = True

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

    def __enter__(self):
        return self

    def __del__(self):
        del self

    def login(self, *args, **kwargs):
        r"""
        Call the corresponding RestClientBase method and return the result.

        Description of argument(s):
        args/kwargs     These are passed directly to the corresponding
                        RestClientBase method.
        """

        for arg in args:
            hostname = self._base_url_.strip("https://")
            # Class object constructor reinitialized.
            self.__init__(hostname=hostname,
                          username=arg['username'],
                          password=arg['password'])

        self._robj_ = redfish.redfish_client(base_url=self._base_url_,
                                             username=self._username_,
                                             password=self._password_,
                                             default_prefix=self._default_prefix_)
        self._robj_.login(auth=redfish.AuthMethod.SESSION)
        self._session_key_ = self._robj_.get_session_key()
        self._session_location_ = self._robj_.get_session_location()

    def set_session_key(self, session_key):
        r"""
        Update the session key instance.
        """
        self._robj_.set_session_key(session_key)

    def get(self, resource_path, *args, **kwargs):
        r"""
        Perform a GET request and return response.

        Description of argument(s):
        resource_path    URI resource absolute path (e.g. "/redfish/v1/Systems/1").
        args/kwargs      These are passed directly to the corresponding
                         RestClientBase method.
        """
        self._rest_response_ = self._robj_.get(resource_path, *args, **kwargs)
        return self._rest_response_

    def post(self, resource_path, *args, **kwargs):
        r"""
        Perform a POST request.

        Description of argument(s):
        resource_path    URI resource relative path
                         (e.g. "Systems/1/Actions/ComputerSystem.Reset").
        args/kwargs      These are passed directly to the corresponding
                         RestClientBase method.
        """
        self._rest_response_ = self._robj_.post('/redfish/v1/' + resource_path,
                                                *args, **kwargs)
        return self._rest_response_

    def patch(self, resource_path, *args, **kwargs):
        r"""
        Perform a POST request.

        Description of argument(s):
        resource_path    URI resource relative path
        args/kwargs      These are passed directly to the corresponding
                         RestClientBase method.
        """
        self._rest_response_ = self._robj_.patch('/redfish/v1/' + resource_path,
                                                 *args, **kwargs)
        return self._rest_response_

    def put(self, resource_path, actions, attr_data):
        r"""
        Perform a PUT request.

        Description of argument(s):
        resource_path    URI resource relative path.
        args/kwargs      These are passed directly to the corresponding
                         RestClientBase method.
        """
        self._rest_response_ = self._robj_.put('/redfish/v1/' + resource_path,
                                               *args, **kwargs)
        return self._rest_response_

    def delete(self, resource_path):
        r"""
        Perform a DELETE request.

        Description of argument(s):
        resource_path  URI resource absolute path
                       (e.g. "/redfish/v1/SessionService/Sessions/8d1a9wiiNL").
        """
        self._rest_response_ = self._robj_.delete(resource_path)
        return self._rest_response_

    def logout(self):
        r"""
        Logout redfish connection session.
        """
        self._robj_.logout()
