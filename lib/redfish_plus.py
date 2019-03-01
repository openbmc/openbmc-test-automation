#!/usr/bin/env python

r"""
See redfish_plus class prolog below for details.
"""

from redfish.rest.v1 import HttpClient
import gen_print as gp


def valid_http_status_code(status, valid_status_codes):
    r"""
    Raise exception if status is not found in the valid_status_codes list.

    Description of argument(s):
    status                          An HTTP status code (e.g. 200, 400, etc.).
    valid_status_codes              A list of status codes that the caller
                                    considers acceptable.  If this is a null
                                    list, then any status code is considered
                                    acceptable.  Note that for the convenience
                                    of the caller, valid_status_codes may be
                                    either a python list or a string which can
                                    be evaluated to become a python list (e.g.
                                    "[200]").
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
    redfish_plus is a wrapper for redfish rest that provides the following
    benefits vs. using redfish directly:

    For rest_request functions (e.g. get, put, post, etc.):
        - Function logging to stdout.
        - Automatic valid_status_codes processing (i.e. an exception will be
          raised if the rest response status code is not as expected.
        - It can be easily used from robot programs.
    """

    ROBOT_LIBRARY_SCOPE = 'GLOBAL'

    def rest_request(self, func, *args, **kwargs):
        r"""
        """
        gp.qprint_executing(stack_frame_ix=3, style=gp.func_line_style_short)
        valid_status_codes = kwargs.pop('valid_status_codes', [200])
        response = func(*args, **kwargs)
        valid_http_status_code(response.status, valid_status_codes)
        return response

    # Define rest function wrappers.
    def get(self, *args, **kwargs):
        return self.rest_request(super(redfish_plus, self).get, *args,
                                 **kwargs)

    def head(self, *args, **kwargs):
        return self.rest_request(super(redfish_plus, self).head, *args,
                                 **kwargs)

    def post(self, *args, **kwargs):
        return self.rest_request(super(redfish_plus, self).post, *args,
                                 **kwargs)

    def put(self, *args, **kwargs):
        return self.rest_request(super(redfish_plus, self).put, *args,
                                 **kwargs)

    def patch(self, *args, **kwargs):
        return self.rest_request(super(redfish_plus, self).patch, *args,
                                 **kwargs)

    def delete(self, *args, **kwargs):
        return self.rest_request(super(redfish_plus, self).delete, *args,
                                 **kwargs)
