#!/usr/bin/env python

r"""
See class prolog below for details.
"""

from redfish_plus import redfish_plus
from robot.libraries.BuiltIn import BuiltIn


class bmc_redfish(redfish_plus):
    r"""
    bmc_redfish is a child class of  redfish_plus that is designed to provide
    benefits specifically for using redfish to communicate with an OpenBMC.

    See the prologs of the methods below for details.
    """

    def login(self, *args, **kwargs):
        r"""
        Assign BMC default values for username, password and auth arguments
        and call parent class login method.

        Description of argument(s):
        args                        See parent class prolog for details.
        kwargs                      See parent class prolog for details.
        """

        args = list(args)
        # Assign default values for username, password, auth where necessary.
        username = args.pop(0) if args else \
            kwargs.pop('username',
                       BuiltIn().get_variable_value("${OPENBMC_USERNAME}"))
        password = args.pop(0) if args else \
            kwargs.pop('password',
                       BuiltIn().get_variable_value("${OPENBMC_PASSWORD}"))
        auth = args.pop(0) if args else kwargs.pop('auth', 'session')

        super(redfish_plus, self).login(username, password, auth,
                                        *args, **kwargs)
