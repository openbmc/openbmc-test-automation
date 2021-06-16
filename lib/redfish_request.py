#!/usr/bin/env python

import requests
import urllib.request
from urllib3.exceptions import InsecureRequestWarning
from getpass import getpass
import sys
import os
import ssl
import json
import random
import secrets
import string

from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn
from robot.api.deco import keyword


class redfish_request(object):

    caverify = False

    @staticmethod
    def generate_oemid():
        r"""
        Generate 10 character unique id.

        e.g. "oMBhLv2Q9e"

        """

        oemid = ''.join(secrets.choice(string.ascii_letters + string.digits) for i in range(10))
        oemid = ''.join(str(i) for i in oemid)

        return oemid

    @staticmethod
    def form_url(url):
        r"""
        Form a comlete path for user url.

        Description of argument(s):
        url                url passed by user e.g. /redfish/v1/Systems/system .
        """

        openbmc_host = BuiltIn().get_variable_value("${OPENBMC_HOST}", default="")
        https_port = BuiltIn().get_variable_value("${HTTPS_PORT}", default="")
        form_url = "https://" + str(openbmc_host) + ":" + str(https_port) + str(url)

        return form_url

    @staticmethod
    def print_console(response):
        r"""
        Print function for console.

        Description of argument(s):
        response            Response from requests.
        """

        logger.console(msg='', newline=True)
        logger.info("Response : [%s]" % response.status_code, also_console=True)
        logger.console(msg='', newline=True)

    def request_login(self, headers, url, credential, timeout=10):
        r"""
        Redfish request to create an session.

        Description of argument(s):
        headers              By default headers is passed as application/json,
                             if user pass the headers then default header is not considered.
        url                  Which path request user needs to be serverd.
        credential           By default admin credential are cosidered by fetching from suit.
                             if user pass the credential  then default credential are not considered.
        timeout              By default timeout is set to 10 ,
                             if user pass the timeout then default timeout value is not considered.
        """

        if headers == "None":
            headers = dict()
            headers['Content-Type'] = 'application/json'

        if "None" == credential['Oem']['OpenBMC'].get('ClientID', ""):
            self.OEMid = redfish_request.generate_oemid()
            credential['Oem']['OpenBMC']['ClientID'] = self.OEMid

        logger.console(msg='', newline=True)
        requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)
        response = redfish_request.request_post_method(self, headers=headers, url=url, data=credential)

        return response

    def request_get(self, headers, url, timeout=10, verify=False):
        r"""
        Redfish get request.

        Description of argument(s):
        headers              By default headers is passed as application/json,
                             if user pass the headers then default header is not considered.
        url                  Which path request user needs to be serverd.
        timeout              By default timeout is set to 10 ,
                             if user pass the timeout then default timeout value is not considered.
        verify               By default verify is set to false,
                             if user pass the verify then default verify value is not considered.
        """

        if headers.get('Content-Type', None) is None:
            headers['Content-Type'] = 'application/json'

        url = redfish_request.form_url(url)
        verify = redfish_request.caverify

        logger.console(msg='', newline=True)
        msg = "Request Method : GET  ,headers = " + json.dumps(headers) + \
              " ,uri = " + str(url) + " ,timeout = " + str(timeout) + " ,verify = " + str(False)
        logger.info(msg, also_console=True)

        response = requests.get(url, headers=headers, timeout=timeout, verify=verify)
        redfish_request.print_console(response)

        return response

    def request_patch(self, headers, url, data=None, timeout=10, verify=False):
        r"""
        Redfish patch request.

        Description of argument(s):
        headers              By default headers is passed as application/json,
                             if user pass the headers then default header is not considered.
        url                  Which path request user needs to be serverd.
        data                 By default data is None,
                             if user pass the data then default data value is not considered.
        timeout              By default timeout is set to 10 ,
                             if user pass the timeout then default timeout value is not considered.
        verify               By default verify is set to false,
                             if user pass the verify then default verify value is not considered.
        """

        if headers.get('Content-Type', None) is None:
            headers['Content-Type'] = 'application/json'

        url = redfish_request.form_url(url)
        verify = redfish_request.caverify

        logger.console(msg='', newline=True)
        msg = "Request Method : PATCH  ,headers = " + json.dumps(headers) + \
              " ,uri = " + str(url) + " ,data = " + json.dumps(data) + " ,timeout = " + str(timeout) + \
              " ,verify = " + str(verify)
        logger.info(msg, also_console=True)

        response = requests.patch(url, headers=headers, data=data, timeout=timeout, verify=verify)
        redfish_request.print_console(response)

        return response

    def request_post(self, headers, url, data=None, timeout=10, verify=False):
        r"""
        Redfish post request.

        Description of argument(s):
        headers              By default headers is passed as application/json,
                             if user pass the headers then default header is not considered.
        url                  Which path request user needs to be serverd.
        data                 By default data is None,
                             if user pass the data then default data value is not considered.
        timeout              By default timeout is set to 10 ,
                             if user pass the timeout then default timeout value is not considered.
        verify               By default verify is set to false,
                             if user pass the verify then default verify value is not considered.
        """

        if headers.get('Content-Type', None) is None:
            headers['Content-Type'] = 'application/json'

        url = redfish_request.form_url(url)
        verify = redfish_request.caverify

        logger.console(msg='', newline=True)
        msg = "Request Method : POST  ,headers = " + json.dumps(headers) + \
              " ,uri = " + str(url) + " ,data = " + json.dumps(data) + " ,timeout = " + str(timeout) + \
              " ,verify = " + str(verify)
        logger.info(msg, also_console=True)

        response = requests.post(url, headers=headers, data=json.dumps(data), timeout=timeout, verify=verify)
        redfish_request.print_console(response)

        return response

    def request_put(self, headers, url, files=None, data=None, timeout=10, verify=False):
        r"""
        Redfish put request.

        Description of argument(s):
        headers              By default headers is passed as application/json,
                             if user pass the headers then default header is not considered.
        url                  Which path request user needs to be serverd.
        files                By default files is None,
                             if user pass the files then default files value is not considered.
        data                 By default data is None,
                             if user pass the data then default data value is not considered.
        timeout              By default timeout is set to 10 ,
                             if user pass the timeout then default timeout value is not considered.
        verify               By default verify is set to false,
                             if user pass the verify then default verify value is not considered.
        """

        if headers.get('Content-Type', None) is None:
            headers['Content-Type'] = 'application/json'

        url = redfish_request.form_url(url)
        verify = redfish_request.caverify

        logger.console(msg='', newline=True)
        msg = "Request Method : PUT  ,headers = " + json.dumps(headers) + \
              " ,uri = " + str(url) + " ,data = " + json.dumps(data) + " ,timeout = " + str(timeout) + \
              " ,verify = " + str(verify)
        logger.info(msg, also_console=True)

        response = requests.put(url, headers=headers, files=files, data=data, timeout=timeout, verify=verify)
        redfish_request.print_console(response)

        return response

    def request_delete(self, headers, url, data=None, timeout=10, verify=False):
        r"""
        Redfish delete request.

        Description of argument(s):
        headers              By default headers is passed as application/json,
                             if user pass the headers then default header is not considered.
        url                  Which path request user needs to be serverd.
        data                 By default data is None,
                             if user pass the data then default data value is not considered.
        timeout              By default timeout is set to 10 ,
                             if user pass the timeout then default timeout value is not considered.
        verify               By default verify is set to false,
                             if user pass the verify then default verify value is not considered.
        """

        if headers.get('Content-Type', None) is None:
            headers['Content-Type'] = 'application/json'

        url = redfish_request.form_url(url)
        verify = redfish_request.caverify

        logger.console(msg='', newline=True)
        msg = "Request Method : DELETE  ,headers = " + json.dumps(headers) + \
              " ,uri = " + str(url) + " ,data = " + json.dumps(data) + " ,timeout = " + str(timeout) + \
              " ,verify = " + str(verify)
        logger.console(msg='', newline=True)

        response = requests.delete(url, headers=headers, data=data, timeout=timeout, verify=verify)
        redfish_request.print_console(response)

        return response

    @staticmethod
    def dict_parse(variable, lookup_dict):
        r"""
        Find a variable in dict.

        Description of argument(s):
        variable              Variable that need to be searched in dict.
        lookup_dict           Disctionay contains variables.
        """

        result = lookup_dict.get(variable, None)
        return result

    @staticmethod
    def get_target_actions(attribute, data):
        r"""
        Get target entry of the searched target attribute.

        Description of argument(s):
        attribute              Pass the attribute needs to be searched.
        data                   Pass the request response.
        """

        lookup_list = ["Actions", "#" + attribute, "target"]
        for lookup_item in lookup_list:
            data = redfish_request.dict_parse(lookup_item, data)
            if data is not None and type(data) is dict():
                continue
        else:
            return data
        return None

    @staticmethod
    def get_attribute(attribute, data):
        r"""
        Get resource attribute.

        Description of argument(s):
        attribute               Pass the attribute needs to be searched.
        data                    Pass the request response.
        """
        value = data.get(attribute, None)
        return value
