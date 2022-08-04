#!/usr/bin/env python3 -u
import sys
from robot.libraries.BuiltIn import BuiltIn
import imp
import string
import importlib

# Define methods to import platform specific files.

def get_service_restart_policy_services(module_name):

    m = importlib.import_module(module_name)
    service_restart_policy_services = dict.copy(m.SERVICES)

    return service_restart_policy_services
