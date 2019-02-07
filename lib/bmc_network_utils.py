#!/usr/bin/env python

r"""
Network generic functions.

"""

import ipaddress
from robot.libraries.BuiltIn import BuiltIn

def netmask_prefix_length(netmask):
    r"""
    Return the netmask prefix length.

    Description of argument(s):
    netmask     Netmask value (e.g. "255.255.0.0", "255.255.255.0", "255.252.0.0", etc.)
    """

    # IP address netmask format: '0.0.0.0/255.255.252.0'
    return  ipaddress.ip_network('0.0.0.0/' + netmask).prefixlen

