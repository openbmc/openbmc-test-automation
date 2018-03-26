#!/usr/bin/env python

r"""
Provide useful error log utility keywords.
"""

import gen_print as gp
import sys
import os
import imp
base_path = os.path.dirname(os.path.dirname(
                            imp.find_module("gen_robot_print")[1])) + os.sep
sys.path.append(base_path + "data/")
import variables as var


def print_error_logs(error_logs, key_list=None):
    r"""
    Print the error logs to the console screen.

    This function provides the following benefits:
    - It will specify print_var parms for the caller (e.g. hex=1).
    - It is much easier to call this function than to generate the desired code
      directly from a robot script.

    Description of argument(s):
    error_logs  An error log dictionary such as the one returned by the
                'Get Error Logs' keyword.
    key_list    The list of keys to be printed.  This may be specified as
                either a python list or a space-delimited string.  In the
                latter case, this function will convert it to a python list.
                See the sprint_varx function prolog for additionatl details.

    Example use from a python script:

    ${error_logs}=  Get Error Logs
    Print Error Logs  ${error_logs}  Message Timestamp

    Sample output:

    error_logs:
      [/xyz/openbmc_project/logging/entry/3]:
        [Timestamp]:                                  1521738335735
        [Message]:                                    xyz.openbmc_project.Inventory.Error.Nonfunctional
      [/xyz/openbmc_project/logging/entry/2]:
        [Timestamp]:                                  1521738334637
        [Message]:                                    xyz.openbmc_project.Inventory.Error.Nonfunctional
      [/xyz/openbmc_project/logging/entry/1]:
        [Timestamp]:                                  1521738300696
        [Message]:                                    xyz.openbmc_project.Inventory.Error.Nonfunctional
      [/xyz/openbmc_project/logging/entry/4]:
        [Timestamp]:                                  1521738337915
        [Message]:                                    xyz.openbmc_project.Inventory.Error.Nonfunctional

    Another example call using a robot list:
    ${error_logs}=  Get Error Logs
    ${key_list}=  Create List  Message  Timestamp  Severity
    Print Error Logs  ${error_logs}  ${key_list}
    """

    if key_list is not None:
        if type(key_list) in (str, unicode):
            key_list = key_list.split(" ")
        key_list.insert(0, var.BMC_LOGGING_ENTRY + ".*")

    gp.print_var(error_logs, hex=1, key_list=key_list)
