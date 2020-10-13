#!/usr/bin/env python

r"""
See class prolog below for details.
"""

import sys
import re
import json
from redfish_plus import redfish_plus
from robot.libraries.BuiltIn import BuiltIn

import func_args as fa
import gen_print as gp


class bmc_redfish(redfish_plus):
    r"""
    bmc_redfish is a child class of redfish_plus that is designed to provide
    benefits specifically for using redfish to communicate with an OpenBMC.

    See the prologs of the methods below for details.
    """

    def __init__(self, *args, **kwargs):
        r"""
        Do BMC-related redfish initialization.

        Presently, older versions of BMC code may not support redfish
        requests.  This can lead to unsightly error text being printed out for
        programs that may use lib/bmc_redfish_resource.robot even though they
        don't necessarily intend to make redfish requests.

        This class method will make an attempt to tolerate this situation.  At
        some future point, when all BMCs can be expected to support redfish,
        this class method may be considered for deletion.  If it is deleted,
        the self.__inited__ test code in the login() class method below should
        likewise be deleted.
        """
        self.__inited__ = False
        try:
            super(bmc_redfish, self).__init__(*args, **kwargs)
            self.__inited__ = True
        except ValueError as get_exception:
            except_type, except_value, except_traceback = sys.exc_info()
            regex = r"The HTTP status code was not valid:[\r\n]+status:[ ]+502"
            result = re.match(regex, str(except_value), flags=re.MULTILINE)
            if not result:
                gp.lprint_var(except_type)
                gp.lprint_varx("except_value", str(except_value))
                raise(get_exception)
        BuiltIn().set_global_variable("${REDFISH_SUPPORTED}", self.__inited__)
        BuiltIn().set_global_variable("${REDFISH_REST_SUPPORTED}", True)

    def login(self, *args, **kwargs):
        r"""
        Assign BMC default values for username, password and auth arguments
        and call parent class login method.

        Description of argument(s):
        args                        See parent class method prolog for details.
        kwargs                      See parent class method prolog for details.
        """

        if not self.__inited__:
            message = "bmc_redfish.__init__() was never successfully run.  It "
            message += "is likely that the target BMC firmware code level "
            message += "does not support redfish.\n"
            raise ValueError(message)
        # Assign default values for username, password, auth where necessary.
        openbmc_username = BuiltIn().get_variable_value("${OPENBMC_USERNAME}")
        openbmc_password = BuiltIn().get_variable_value("${OPENBMC_PASSWORD}")
        username, args, kwargs = fa.pop_arg(openbmc_username, *args, **kwargs)
        password, args, kwargs = fa.pop_arg(openbmc_password, *args, **kwargs)
        auth, args, kwargs = fa.pop_arg('session', *args, **kwargs)

        super(bmc_redfish, self).login(username, password, auth,
                                       *args, **kwargs)

    def get_properties(self, *args, **kwargs):
        r"""
        Return dictionary of attributes for a given path.

        The difference between calling this function and calling get()
        directly is that this function returns ONLY the dictionary portion of
        the response object.

        Example robot code:

        ${properties}=  Get Properties  /redfish/v1/Systems/system/
        Rprint Vars  properties

        Output:

        properties:
          [PowerState]:      Off
          [Processors]:
            [@odata.id]:     /redfish/v1/Systems/system/Processors
          [SerialNumber]:    1234567
          ...

        Description of argument(s):
        args                        See parent class get() prolog for details.
        kwargs                      See parent class get() prolog for details.
        """

        resp = self.get(*args, **kwargs)
        return resp.dict if hasattr(resp, 'dict') else {}

    def get_attribute(self, path, attribute, default=None, *args, **kwargs):
        r"""
        Get and return the named attribute from the properties for a given
        path.

        This method has the following advantages over calling get_properties
        directly:
        - The caller can specify a default value to be returned if the
          attribute does not exist.

        Example robot code:

        ${attribute}=  Get Attribute  /redfish/v1/AccountService
        ...  MaxPasswordLength  default=600
        Rprint Vars  attribute

        Output:

        attribute:           31

        Description of argument(s):
        path                        The path (e.g.
                                    "/redfish/v1/AccountService").
        attribute                   The name of the attribute to be retrieved
                                    (e.g. "MaxPasswordLength").
        default                     The default value to be returned if the
                                    attribute does not exist (e.g. "").
        args                        See parent class get() prolog for details.
        kwargs                      See parent class get() prolog for details.
        """

        return self.get_properties(path, *args, **kwargs).get(attribute,
                                                              default)

    def get_session_info(self):
        r"""
        Get and return session info as a tuple consisting of session_key and
        session_location.
        """

        return self.get_session_key(), self.get_session_location()

    def enumerate(self, resource_path, return_json=1, include_dead_resources=False):
        r"""
        Perform a GET enumerate request and return available resource paths.

        Description of argument(s):
        resource_path               URI resource absolute path (e.g. "/redfish/v1/SessionService/Sessions").
        return_json                 Indicates whether the result should be returned as a json string or as a
                                    dictionary.
        include_dead_resources      Check and return a list of dead/broken URI resources.
        """

        gp.qprint_executing(style=gp.func_line_style_short)
        # Set quiet variable to keep subordinate get() calls quiet.
        quiet = 1

        self.__result = {}
        # Variable to hold the pending list of resources for which enumeration is yet to be obtained.
        self.__pending_enumeration = set()
        self.__pending_enumeration.add(resource_path)

        # Variable having resources for which enumeration is completed.
        enumerated_resources = set()
        dead_resources = {}
        resources_to_be_enumerated = (resource_path,)
        while resources_to_be_enumerated:
            for resource in resources_to_be_enumerated:
                # JsonSchemas, SessionService or URLs containing # are not required in enumeration.
                # Example: '/redfish/v1/JsonSchemas/' and sub resources.
                #          '/redfish/v1/SessionService'
                #          '/redfish/v1/Managers/bmc#/Oem'
                if ('JsonSchemas' in resource) or ('SessionService' in resource) or ('#' in resource):
                    continue

                self._rest_response_ = self.get(resource, valid_status_codes=[200, 404, 500])
                # Enumeration is done for available resources ignoring the ones for which response is not
                # obtained.
                if self._rest_response_.status != 200:
                    if include_dead_resources:
                        try:
                            dead_resources[self._rest_response_.status].append(resource)
                        except KeyError:
                            dead_resources[self._rest_response_.status] = [resource]
                    continue
                self.walk_nested_dict(self._rest_response_.dict, url=resource)

            enumerated_resources.update(set(resources_to_be_enumerated))
            resources_to_be_enumerated = tuple(self.__pending_enumeration - enumerated_resources)

        if return_json:
            if include_dead_resources:
                return json.dumps(self.__result, sort_keys=True,
                                  indent=4, separators=(',', ': ')), dead_resources
            else:
                return json.dumps(self.__result, sort_keys=True,
                                  indent=4, separators=(',', ': '))
        else:
            if include_dead_resources:
                return self.__result, dead_resources
            else:
                return self.__result

    def walk_nested_dict(self, data, url=''):
        r"""
        Parse through the nested dictionary and get the resource id paths.

        Description of argument(s):
        data                        Nested dictionary data from response message.
        url                         Resource for which the response is obtained in data.
        """
        url = url.rstrip('/')

        for key, value in data.items():

            # Recursion if nested dictionary found.
            if isinstance(value, dict):
                self.walk_nested_dict(value)
            else:
                # Value contains a list of dictionaries having member data.
                if 'Members' == key:
                    if isinstance(value, list):
                        for memberDict in value:
                            self.__pending_enumeration.add(memberDict['@odata.id'])
                if '@odata.id' == key:
                    value = value.rstrip('/')
                    # Data for the given url.
                    if value == url:
                        self.__result[url] = data
                    # Data still needs to be looked up,
                    else:
                        self.__pending_enumeration.add(value)
