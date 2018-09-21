#!/usr/bin/env python

r"""
This module provides many valuable openbmctool.py functions such as
openbmctool_execute_command.
"""

import gen_cmd as gc
import gen_valid as gv
from robot.libraries.BuiltIn import BuiltIn
import re


def openbmctool_execute_command(command_string,
                                *args,
                                **kwargs):
    r"""
    Run the command string as an argument to the openbmctool.py program and
    return the stdout and the return code.

    This function provides several benefits versus calling shell_cmd directly:
    - This function will obtain the global values for OPENBMC_HOST,
      OPENBMC_USERNAME, etc.
    - This function will compose the openbmctool.py command string which
      includes the caller's command_string.
    - The openbmctool.py produces additional text that clutters the output.
      This function will remove such text.  Example:
        Attempting login...
        <actual output>
        User root has been logged out

    NOTE: If you have pipe symbols in your command_string, they must be
    surrounded by a single space on each side (see example below).

    Example code:
    ${rc}  ${output}=  Openbmctool Execute Command  fru status | head -n 2

    Example output:
    #(CDT) 2018/09/19 15:16:58 - Issuing: set -o pipefail ; openbmctool.py -H hostname -U root -P ********
    ...  fru status | tail -n +1 | egrep -v 'Attempting login|User [^ ]+ hasbeen logged out' | head -n 2
    Component     | Is a FRU  | Present  | Functional  | Has Logs
    cpu0          | Yes       | Yes      | Yes         | No

    Description of arguments:
    command_string                  The command string to be passed to the
                                    openbmctool.py program.
    All remaining arguments are passed directly to shell_cmd.  See the
    shell_cmd prolog for details on allowable arguments.  The caller may code
    them directly as in this example:
    openbmctool_execute_command("my command", quiet=1, max_attempts=2).
    Python will do the work of putting these values into args/kwargs.
    """

    if not gv.valid_value(command_string):
        return "", "", 1

    # Get global BMC variable values.
    openbmc_host = BuiltIn().get_variable_value("${OPENBMC_HOST}", default="")
    openbmc_username = BuiltIn().get_variable_value("${OPENBMC_USERNAME}",
                                                    default="")
    openbmc_password = BuiltIn().get_variable_value("${OPENBMC_PASSWORD}",
                                                    default="")
    if not gv.valid_value(openbmc_host):
        return "", "", 1
    if not gv.valid_value(openbmc_username):
        return "", "", 1
    if not gv.valid_value(openbmc_password):
        return "", "", 1

    # Break the caller's command up into separate piped commands.  For
    # example, the user may have specified "fru status | head -n 2" which
    # would be broken into 2 list elements.
    pipeline = map(str.strip, re.split(r' \| ', str(command_string)))
    # The "tail" command below prevents a "egrep: write error: Broken pipe"
    # error if the user is piping the output to a sub-process.
    # Use "egrep -v" to get rid of editorial output from openbmctool.py.
    pipeline.insert(1, "tail -n +1 | egrep -v 'Attempting login|User [^ ]+ has"
                    " been logged out'")

    command_string = "set -o pipefail ; python3 openbmctool.py -H " + openbmc_host\
        + " -U " + openbmc_username + " -P " + openbmc_password + " "\
        + " | ".join(pipeline)

    return gc.shell_cmd(command_string, *args, **kwargs)
