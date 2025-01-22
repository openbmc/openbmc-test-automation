#!/usr/bin/env python3

r"""
See redfish_plus class prolog below for details.
"""

import json

import func_args as fa
import gen_print as gp
import requests
from redfish.rest.v1 import HttpClient
from robot.libraries.BuiltIn import BuiltIn

host = BuiltIn().get_variable_value("${OPENBMC_HOST}")
MTLS_ENABLED = BuiltIn().get_variable_value("${MTLS_ENABLED}")
CERT_DIR_PATH = BuiltIn().get_variable_value("${CERT_DIR_PATH}")
VALID_CERT = BuiltIn().get_variable_value("${VALID_CERT}")


def valid_http_status_code(status, valid_status_codes):
    r"""
    Raise exception if status is not found in the valid_status_codes list.

    Description of argument(s):
    status                          An HTTP status code (e.g. 200, 400, etc.).
    valid_status_codes              A list of status codes that the caller considers acceptable.  If this is
                                    a null list, then any status code is considered acceptable.  Note that
                                    for the convenience of the caller, valid_status_codes may be either a
                                    python list or a string which can be evaluated to become a python list
                                    (e.g. "[200]").
    """

    if type(valid_status_codes) is not list:
        valid_status_codes = eval(valid_status_codes)
    if len(valid_status_codes) == 0:
        return
    if status in valid_status_codes:
        return

    message = "The HTTP status code was not valid:\n"
    message += gp.sprint_vars(status, valid_status_codes)
    raise ValueError(message)


class redfish_plus(HttpClient):
    r"""
    redfish_plus is a wrapper for redfish rest that provides the following benefits vs. using redfish
    directly:

    For rest_request functions (e.g. get, put, post, etc.):
        - Function-call logging to stdout.
        - Automatic valid_status_codes processing (i.e. an exception will be raised if the rest response
          status code is not as expected.
        - Easily used from robot programs.
    """

    ROBOT_LIBRARY_SCOPE = "TEST SUITE"

    def rest_request(self, func, *args, **kwargs):
        r"""
        Perform redfish rest request and return response.

        This function provides the following additional functionality.
        - The calling function's call line is logged to standard out (provided that global variable "quiet"
          is not set).
        - The caller may include a valid_status_codes argument.
        - Callers may include inline python code strings to define arguments.  This predominantly benefits
          robot callers.

          For example, instead of calling like this:
            ${data}=  Create Dictionary  HostName=${hostname}
            Redfish.patch  ${REDFISH_NW_PROTOCOL_URI}  body=&{data}

          Callers may do this:

            Redfish.patch  ${REDFISH_NW_PROTOCOL_URI}
            ...  body=[('HostName', '${hostname}')]

        Description of argument(s):
        func                        A reference to the parent class function which is to be called (e.g. get,
                                    put, etc.).
        args                        This is passed directly to the function referenced by the func argument
                                    (see the documentation for the corresponding redfish HttpClient method
                                    for details).
        kwargs                      This is passed directly to the function referenced by the func argument
                                    (see the documentation for the corresponding redfish HttpClient method
                                    for details) with the following exception:  If kwargs contains a
                                    valid_status_codes key, it will be removed from kwargs and processed by
                                    this function.  This allows the caller to indicate what rest status codes
                                    are acceptable.  The default value is [200].  See the
                                    valid_http_status_code function above for details.

        Example uses:

        From a python program:

        response = bmc_redfish.get("/redfish/v1/Managers/${MANAGER_ID}/EthernetInterfaces", [200, 201])

        If this call to the get method generates a response.status equal to anything other than 200 or 201,
        an exception will be raised.

        From a robot program:

        BMC_Redfish.logout
        ${response}=  BMC_Redfish.Get  /redfish/v1/Managers/${MANAGER_ID}/EthernetInterfaces  valid_status_codes=[401]

        As part of a robot test, the programmer has logged out to verify that the get request will generate a
        status code of 401 (i.e. "Unauthorized").

        Timeout for GET/POST/PATCH/DELETE operations. By default 30 seconds, else user defined value.
        Similarly, Max retry by default 10 attempt for the operation, else user defined value.
        """
        gp.qprint_executing(stack_frame_ix=3, style=gp.func_line_style_short)
        # Convert python string object definitions to objects (mostly useful for robot callers).
        args = fa.args_to_objects(args)
        kwargs = fa.args_to_objects(kwargs)
        timeout = kwargs.pop("timeout", 30)
        self._timeout = timeout
        max_retry = kwargs.pop("max_retry", 10)
        self._max_retry = max_retry
        valid_status_codes = kwargs.pop("valid_status_codes", [200])

        try:
            response = func(*args, **kwargs)
        except Exception as e:
            error_response = type(e).__name__ + " from redfish_plus class"
            BuiltIn().log_to_console(error_response)
            return

        valid_http_status_code(response.status, valid_status_codes)
        return response

    # Define rest function wrappers.
    def get(self, *args, **kwargs):
        if MTLS_ENABLED == "True":
            return self.rest_request(self.get_with_mtls, *args, **kwargs)
        else:
            return self.rest_request(
                super(redfish_plus, self).get, *args, **kwargs
            )

    def head(self, *args, **kwargs):
        if MTLS_ENABLED == "True":
            return self.rest_request(self.head_with_mtls, *args, **kwargs)
        else:
            return self.rest_request(
                super(redfish_plus, self).head, *args, **kwargs
            )

    def post(self, *args, **kwargs):
        if MTLS_ENABLED == "True":
            return self.rest_request(self.post_with_mtls, *args, **kwargs)
        else:
            return self.rest_request(
                super(redfish_plus, self).post, *args, **kwargs
            )

    def put(self, *args, **kwargs):
        if MTLS_ENABLED == "True":
            return self.rest_request(self.put_with_mtls, *args, **kwargs)
        else:
            return self.rest_request(
                super(redfish_plus, self).put, *args, **kwargs
            )

    def patch(self, *args, **kwargs):
        if MTLS_ENABLED == "True":
            return self.rest_request(self.patch_with_mtls, *args, **kwargs)
        else:
            return self.rest_request(
                super(redfish_plus, self).patch, *args, **kwargs
            )

    def delete(self, *args, **kwargs):
        if MTLS_ENABLED == "True":
            return self.rest_request(self.delete_with_mtls, *args, **kwargs)
        else:
            return self.rest_request(
                super(redfish_plus, self).delete, *args, **kwargs
            )

    def __del__(self):
        del self

    def get_with_mtls(self, *args, **kwargs):
        cert_dict = kwargs.pop("certificate", {"certificate_name": VALID_CERT})
        response = requests.get(
            url="https://" + host + args[0],
            cert=CERT_DIR_PATH + "/" + cert_dict["certificate_name"],
            verify=False,
            headers={"Cache-Control": "no-cache"},
        )

        response.status = response.status_code
        if response.status == 200:
            response.dict = json.loads(response.text)

        return response

    def post_with_mtls(self, *args, **kwargs):
        cert_dict = kwargs.pop("certificate", {"certificate_name": VALID_CERT})
        body = kwargs.pop("body", {})
        response = requests.post(
            url="https://" + host + args[0],
            json=body,
            cert=CERT_DIR_PATH + "/" + cert_dict["certificate_name"],
            verify=False,
            headers={"Content-Type": "application/json"},
        )

        response.status = response.status_code

        return response

    def patch_with_mtls(self, *args, **kwargs):
        cert_dict = kwargs.pop("certificate", {"certificate_name": VALID_CERT})
        body = kwargs.pop("body", {})
        response = requests.patch(
            url="https://" + host + args[0],
            json=body,
            cert=CERT_DIR_PATH + "/" + cert_dict["certificate_name"],
            verify=False,
            headers={"Content-Type": "application/json"},
        )

        response.status = response.status_code

        return response

    def delete_with_mtls(self, *args, **kwargs):
        cert_dict = kwargs.pop("certificate", {"certificate_name": VALID_CERT})
        response = requests.delete(
            url="https://" + host + args[0],
            cert=CERT_DIR_PATH + "/" + cert_dict["certificate_name"],
            verify=False,
            headers={"Content-Type": "application/json"},
        )

        response.status = response.status_code

        return response

    def put_with_mtls(self, *args, **kwargs):
        cert_dict = kwargs.pop("certificate", {"certificate_name": VALID_CERT})
        body = kwargs.pop("body", {})
        response = requests.put(
            url="https://" + host + args[0],
            json=body,
            cert=CERT_DIR_PATH + "/" + cert_dict["certificate_name"],
            verify=False,
            headers={"Content-Type": "application/json"},
        )

        response.status = response.status_code

        return response

    def head_with_mtls(self, *args, **kwargs):
        cert_dict = kwargs.pop("certificate", {"certificate_name": VALID_CERT})
        body = kwargs.pop("body", {})
        response = requests.head(
            url="https://" + host + args[0],
            json=body,
            cert=CERT_DIR_PATH + "/" + cert_dict["certificate_name"],
            verify=False,
            headers={"Content-Type": "application/json"},
        )

        response.status = response.status_code

        return response
