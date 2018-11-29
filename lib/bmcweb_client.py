#!/usr/bin/env python

r"""
BMC web redfish class to use python redfish library.
Refer: https://github.com/DMTF/python-redfish-library
"""

import redfish
import json
from robot.libraries.BuiltIn import BuiltIn


class bmcweb_client(object):

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
            BuiltIn().fail("session resource: %s, "
                "return code: %d" % (self.session_loc, resp.status))
        return resp

    def post_method(self, resource_path, boot_type):
        r"""
        Perform a POST request.

        Description of Arguments:
        resource_path    URI resource relative path
                         (e.g. "Systems/1/Actions/ComputerSystem.Reset").
        boot_type        Type of boots
                         (e.g. "On", "ForceOff", "GracefulRestart",
                               "GracefulShutdown").
        """
        payload = {"ResetType": boot_type}
        uri_path = '/redfish/v1/' + resource_path
        resp = self.session.post(uri_path, body=payload)
        if resp.status != 200:
            BuiltIn().fail("session resource: %s, "
                "return code: %d" % (self.session_loc, resp.status))
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
            BuiltIn().fail("session resource: %s, "
                "return code: %d" % (self.session_loc, resp.status))
        return resp

    def logout_session(self):
        r"""
        Logout redfish connection session.
        """
        self.session.logout()
