#!/usr/bin/env python

r"""
See class prolog below for details.
"""

import sys
import re
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

    def login(self, *args, **kwargs):
        r"""
        Assign BMC default values for username, password and auth arguments
        and call parent class login method.

        Description of argument(s):
        args                        See parent class method prolog for details.
        kwargs                      See parent class method prolog for details.
        """

        if not self.__inited__:
            message = "bmc_redfish.__init__() was never successfully run.\n"
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
        Rprint Vars  1  properties

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
