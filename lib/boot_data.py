#!/usr/bin/env python

r"""
This module has functions to support various data structures such as the
boot_table, valid_boot_list and boot_results_table.
"""

import os
import tempfile
import json
import glob
from tally_sheet import *

from robot.libraries.BuiltIn import BuiltIn
try:
    from robot.utils import DotDict
except ImportError:
    import collections

import gen_print as gp
import gen_valid as gv
import gen_misc as gm
import gen_cmd as gc
import var_funcs as vf

# The code base directory will be one level up from the directory containing
# this module.
code_base_dir_path = os.path.dirname(os.path.dirname(__file__)) + os.sep


def create_boot_table(file_path=None,
                      os_host=""):
    r"""
    Read the boot table JSON file, convert it to an object and return it.

    Note that if the user is running without a global OS_HOST robot variable
    specified, this function will remove all of the "os_" start and end state
    requirements from the JSON data.

    Description of argument(s):
    file_path                       The path to the boot_table file.  If this
                                    value is not specified, it will be
                                    obtained from the "BOOT_TABLE_PATH"
                                    environment variable, if set.  Otherwise,
                                    it will default to "data/boot_table.json".
                                    If this value is a relative path, this
                                    function will use the code_base_dir_path
                                    as the base directory (see definition
                                    above).
    os_host                         The host name or IP address of the host
                                    associated with the machine being tested.
                                    If the user is running without an OS_HOST
                                    (i.e. if this argument is blank), we
                                    remove os starting and ending state
                                    requirements from the boot entries.
    """
    if file_path is None:
        file_path = os.environ.get('BOOT_TABLE_PATH', 'data/boot_table.json')

    if not file_path.startswith("/"):
        file_path = code_base_dir_path + file_path

    # Pre-process the file by removing blank lines and comment lines.
    temp = tempfile.NamedTemporaryFile()
    temp_file_path = temp.name

    cmd_buf = "egrep -v '^[ ]*$|^[ ]*#' " + file_path + " > " + temp_file_path
    gc.cmd_fnc_u(cmd_buf, quiet=1)

    boot_file = open(temp_file_path)
    boot_table = json.load(boot_file, object_hook=DotDict)

    # If the user is running without an OS_HOST, we remove os starting and
    # ending state requirements from the boot entries.
    if os_host == "":
        for boot in boot_table:
            state_keys = ['start', 'end']
            for state_key in state_keys:
                for sub_state in list(boot_table[boot][state_key]):
                    if sub_state.startswith("os_"):
                        boot_table[boot][state_key].pop(sub_state, None)

    # For every boot_type we should have a corresponding mfg mode boot type.
    enhanced_boot_table = DotDict()
    for key, value in boot_table.items():
        enhanced_boot_table[key] = value
        enhanced_boot_table[key + " (mfg)"] = value

    return enhanced_boot_table
