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


def create_valid_boot_list(boot_table):
    r"""
    Return a list of all of the valid boot types (e.g. ['REST Power On', 'REST
    Power Off', ...]).

    Description of argument(s):
    boot_table                      A boot table such as is returned by the
                                    create_boot_table function.
    """

    return list(boot_table.keys())


def read_boot_lists(dir_path="data/boot_lists/"):
    r"""
    Read the contents of all the boot lists files found in the given boot
    lists directory and return dictionary of the lists.

    Boot lists are simply files containing a boot test name on each line.
    These files are useful for categorizing and organizing boot tests.  For
    example, there may be a "Power_on" list, a "Power_off" list, etc.

    The names of the boot list files will be the keys to the top level
    dictionary.  Each dictionary entry is a list of all the boot tests found
    in the corresponding file.

    Here is an abbreviated look at the resulting boot_lists dictionary.

    boot_lists:
      boot_lists[All]:
        boot_lists[All][0]:                           REST Power On
        boot_lists[All][1]:                           REST Power Off
    ...
      boot_lists[Code_update]:
        boot_lists[Code_update][0]:                   BMC oob hpm
        boot_lists[Code_update][1]:                   BMC ib hpm
    ...

    Description of argument(s):
    dir_path                        The path to the directory containing the
                                    boot list files.  If this value is a
                                    relative path, this function will use the
                                    code_base_dir_path as the base directory
                                    (see definition above).
    """

    if not dir_path.startswith("/"):
        # Dir path is relative.
        dir_path = code_base_dir_path + dir_path

    # Get a list of all file names in the directory.
    boot_file_names = os.listdir(dir_path)

    boot_lists = DotDict()
    for boot_category in boot_file_names:
        file_path = gm.which(dir_path + boot_category)
        boot_list = gm.file_to_list(file_path, newlines=0, comments=0, trim=1)
        boot_lists[boot_category] = boot_list

    return boot_lists


def valid_boot_list(boot_list,
                    valid_boot_types):
    r"""
    Verify that each entry in boot_list is a supported boot test.

    Description of argument(s):
    boot_list                       An array (i.e. list) of boot test types
                                    (e.g. "REST Power On").
    valid_boot_types                A list of valid boot types such as that
                                    returned by create_valid_boot_list.
    """

    for boot_name in boot_list:
        boot_name = boot_name.strip(" ")
        error_message = gv.svalid_value(boot_name,
                                        valid_values=valid_boot_types,
                                        var_name="boot_name")
        if error_message != "":
            BuiltIn().fail(gp.sprint_error(error_message))
