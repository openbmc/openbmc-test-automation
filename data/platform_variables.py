#!/usr/bin/env python3 -u

r"""
 Define methods to import platform specific files.
"""

import importlib
import string
import sys

from robot.libraries.BuiltIn import BuiltIn


def get_service_restart_policy_services(module_name):
    r"""
    Gets the service list that gives in the respective platform specific file.
    """
    m = importlib.import_module(module_name)
    service_restart_policy_services = dict.copy(m.SERVICES)

    return service_restart_policy_services
