#!/usr/bin/env python

r"""
BMC redfish utility functions.
"""

from robot.libraries.BuiltIn import BuiltIn


class bmc_redfish_utils(object):

    def __init__(self):
        r"""
        Initialize the bmc_redfish_utils object.
	    """
        # Obtain a reference to the global redfish object.
        self._redfish_ = BuiltIn().get_library_instance('redfish')

    def get_attribute(self, resource_path, attribute):
        r"""
        Get resource attribute.

        Description of argument(s):
        resource_path    URI resource relative path.
        attribute        Name of the attribute (e.g. 'PowerState').
        """
        resp = self._redfish_.get(resource_path)
        return resp.dict[attribute]
