#!/usr/bin/env python

r"""
Redfish class to use python redfish library.
Refer: https://github.com/DMTF/python-redfish-library
"""

import redfish
import json

class redfish_client(object):

    def __init__(self, host_ip, username, password):
        r"""
        initialize redfish client connection to host.
        """
        self.base_url = "https://" + host_ip
        self.username = username
        self.password = password
        self.default_prefix = "/redfish/v1"

        self.robj = redfish.redfish_client(base_url=self.base_url,
                                           username=self.username,
                                           password=self.password,
                                           default_prefix=self.default_prefix)
        #self.robj.login(auth="session")
        self.robj.login(auth=redfish.AuthMethod.SESSION)
        self.session_key = self.robj.get_session_key()

    def get_method(self, resource_path):
        r"""
        Get the resource and return response msg.
        """
        uri_path = '/redfish/v1/' + resource_path
        response = self.robj.get(uri_path)
        return response

    def post_method(self, resource_path, typeBoot):
        r"""
        Perform a POST request.
        """
        payload = {"ResetType":typeBoot}
        uri_path = '/redfish/v1/' + resource_path
        response = self.robj.post(uri_path, body=payload)
        return response

    def logout_session(self):
        r"""
        Logout redfish session.
        """
        self.robj.logout()
