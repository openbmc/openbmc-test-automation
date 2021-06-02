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
    def GenerateOEMId():

        temp_oemid = ''.join(secrets.choice(string.ascii_letters + string.digits) for i in range(10))
        oemid = ''.join(str(i) for i in temp_oemid)

        return oemid

    @staticmethod
    def form_url(url):

        openbmc_host = BuiltIn().get_variable_value("${OPENBMC_HOST}", default="")
        https_port = BuiltIn().get_variable_value("${HTTPS_PORT}", default="443")
        form_url = "https://" + str(openbmc_host) + ":" + str(https_port) + str(url)

        return  form_url


    @staticmethod
    def print_console(response):

        logger.console(msg='', newline=True)
        logger.info("Response : [%s]" % response.status_code, also_console=True)
        logger.console(msg='', newline=True)


    def RequestLoginMethod(self, headers, url, credential, timeout=10):

        if headers == "None":
            headers = dict()
            headers['Content-Type'] = 'application/json'

        if "None" == credential['Oem']['OpenBMC'].get('ClientID', ""):
            self.OEMid = redfish_request.GenerateOEMId()
            credential['Oem']['OpenBMC']['ClientID'] = self.OEMid

        logger.console(msg='', newline=True)
        requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)
        response = redfish_request.RequestPostMethod(self, headers=headers, url=url, data=credential)

        return  response


    def RequestGetMethod(self, headers, url, timeout=10, verify=False):

        if headers.get('Content-Type', None) is None:
            headers['Content-Type'] = 'application/json'

        url = redfish_request.form_url(url)
        verify = redfish_request.caverify

        logger.console(msg='', newline=True)
        msg = "Request Method : GET  ,headers = " + json.dumps(headers) + " ,uri = " + str(url) +  " ,timeout = " + str(timeout) + " ,verify = " + str(False)
        logger.info(msg, also_console=True)

        response = requests.get(url, headers=headers, timeout=timeout, verify=verify)
        redfish_request.print_console(response)

        return  response

    def RequestPatchMethod(self, headers, url, data=None, timeout=10, verify=False):

        if headers.get('Content-Type', None) is None:
            headers['Content-Type'] = 'application/json'

        url = redfish_request.form_url(url)
        verify = redfish_request.caverify

        logger.console(msg='', newline=True)
        msg = "Request Method : PATCH  ,headers = " + json.dumps(headers) + " ,uri = " + str(url) + " ,data = " + json.dumps(data) + " ,timeout = " + str(timeout) + " ,verify = " + str(verify)
        logger.info(msg, also_console=True)

        response = requests.patch(url, headers=headers, data=data, timeout=timeout, verify=verify)
        redfish_request.print_console(response)

        return  response


    def RequestPostMethod(self, headers, url, data=None, timeout=10):

        if headers.get('Content-Type', None) is None:
            headers['Content-Type'] = 'application/json'


        url = redfish_request.form_url(url)
        verify = redfish_request.caverify

        logger.console(msg='', newline=True)
        msg = "Request Method : POST  ,headers = " + json.dumps(headers) + " ,uri = " + str(url) + " ,data = " + json.dumps(data) + " ,timeout = " + str(timeout) + " ,verify = " + str(verify)
        logger.info(msg, also_console=True)

        response = requests.post(url, headers=headers, data=json.dumps(data), timeout=timeout, verify=verify)
        redfish_request.print_console(response)

        return  response


    def RequestPutMethod(self, headers, url, files=None ,data=None, timeout=10):

        if headers.get('Content-Type', None) is None:
            headers['Content-Type'] = 'application/json'

        url = redfish_request.form_url(url)
        verify = redfish_request.caverify

        logger.console(msg='', newline=True)
        msg = "Request Method : PUT  ,headers = " + json.dumps(headers) + " ,uri = " + str(url) + " ,data = " + json.dumps(data) + " ,timeout = " + str(timeout) + " ,verify = " + str(verify)
        logger.info(msg, also_console=True)

        response = requests.put(url, headers=headers, files=files, data=data, timeout=timeout, verify=verify)
        redfish_request.print_console(response)

        return  response


    def RequestDeleteMethod(self, headers, url, data=None, timeout=10):

        if headers.get('Content-Type', None) is None:
            headers['Content-Type'] = 'application/json'

        url = redfish_request.form_url(url)
        verify = redfish_request.caverify

        logger.console(msg='', newline=True)
        msg = "Request Method : DELETE  ,headers = " + json.dumps(headers) + " ,uri = " + str(url) + " ,data = " + json.dumps(data) + " ,timeout = " + str(timeout) + " ,verify = " + str(verify)
        logger.console(msg='', newline=True)

        response = requests.delete(url, headers=headers, data=data, timeout=timeout, verify=verify)
        redfish_request.print_console(response)

        return  response


    @staticmethod
    def DictParse(variable, lookup_dict):
        result = lookup_dict.get(variable, None)
        return result


    @staticmethod
    def GetTargetActions(attribute, uri, data):
        lookup_list = ["Actions", "#" + attribute, "target"]
        for lookup_item in lookup_list:
            data = redfish_request.DictParse(lookup_item, data)
            if data is not None and type(data) is dict():
                continue
        else:
            return data
        return None


    @staticmethod
    def GetAttribute(attribute, data):
        value = data.get(attribute, None)
        return value

