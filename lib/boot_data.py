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
import gen_robot_print as grp
import gen_valid as gv
import gen_misc as gm
import gen_cmd as gc
import var_funcs as vf

# The code base directory will be one level up from the directory containing
# this module.
code_base_dir_path = os.path.dirname(os.path.dirname(__file__)) + os.sep


def create_boot_table(file_path=None):
    r"""
    Read the boot table JSON file, convert it to an object and return it.

    Note that if the user is running without a global OS_HOST robot variable
    specified, this function will remove all of the "os_" start and end state
    requirements from the JSON data.

    Description of arguments:
    file_path  The path to the boot_table file.  If this value is not
               specified, it will be obtained from the "BOOT_TABLE_PATH"
               environment variable, if set.  Otherwise, it will default to
               "data/boot_table.json".  If this value is a relative path,
               this function will use the code_base_dir_path as the base
               directory (see definition above).
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
    os_host = BuiltIn().get_variable_value("${OS_HOST}", default="")
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
    Return a list of all of the valid boot types (e.g. ['BMC Power On',
    'BMC Power Off', ....]

    Description of arguments:
    boot_table  A boot table such as is returned by the create_boot_table
    function.
    """

    return list(boot_table.keys())


def read_boot_lists(dir_path="data/boot_lists/"):
    r"""
    Read the contents of all the boot lists files found in the given boot lists
    directory and return dictionary of the lists.

    Boot lists are simply files containing a boot test name on each line.
    These files are useful for categorizing and organizing boot tests.  For
    example, there may be a "Power_on" list, a "Power_off" list, etc.

    The names of the boot list files will be the keys to the top level
    dictionary.  Each dictionary entry is a list of all the boot tests found
    in the corresponding file.

    Here is an abbreviated look at the resulting boot_lists dictionary.

    boot_lists:
      boot_lists[All]:
        boot_lists[All][0]:                           BMC Power On
        boot_lists[All][1]:                           BMC Power Off
    ...
      boot_lists[Code_update]:
        boot_lists[Code_update][0]:                   BMC oob hpm
        boot_lists[Code_update][1]:                   BMC ib hpm
    ...

    Description of arguments:
    dir_path  The path to the directory containing the boot list files.  If
              this value is a relative path, this function will use the
              code_base_dir_path as the base directory (see definition above).
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

    Description of arguments:
    boot_list         An array (i.e. list) of boot test types
                      (e.g. "BMC Power On").
    valid_boot_types  A list of valid boot types such as that returned by
                      create_valid_boot_list.
    """

    for boot_name in boot_list:
        boot_name = boot_name.strip(" ")
        error_message = gv.svalid_value(boot_name,
                                        valid_values=valid_boot_types,
                                        var_name="boot_name")
        if error_message != "":
            BuiltIn().fail(gp.sprint_error(error_message))


class boot_results:

    r"""
    This class defines a boot_results table.
    """

    def __init__(self,
                 boot_table,
                 boot_pass=0,
                 boot_fail=0,
                 obj_name='boot_results'):
        r"""
        Initialize the boot results object.

        Description of arguments:
        boot_table  Boot table object (see definition above).  The boot table
                    contains all of the valid boot test types.  It can be
                    created with the create_boot_table function.
        boot_pass   An initial boot_pass value.  This program may be called
                    as part of a larger test suite.  As such there may already
                    have been some successful boot tests that we need to
                    keep track of.
        boot_fail   An initial boot_fail value.  This program may be called
                    as part of a larger test suite.  As such there may already
                    have been some unsuccessful boot tests that we need to
                    keep track of.
        obj_name    The name of this object.
        """

        # Store the method parms as class data.
        self.__obj_name = obj_name
        self.__initial_boot_pass = boot_pass
        self.__initial_boot_fail = boot_fail

        # Create boot_results_fields for use in creating boot_results table.
        boot_results_fields = DotDict([('total', 0), ('pass', 0), ('fail', 0)])
        # Create boot_results table.
        self.__boot_results = tally_sheet('boot type',
                                          boot_results_fields,
                                          'boot_test_results')
        self.__boot_results.set_sum_fields(['total', 'pass', 'fail'])
        self.__boot_results.set_calc_fields(['total=pass+fail'])
        # Create one row in the result table for each kind of boot test
        # in the boot_table (i.e. for all supported boot tests).
        for boot_name in list(boot_table.keys()):
            self.__boot_results.add_row(boot_name)

    def return_total_pass_fail(self):
        r"""
        Return the total boot_pass and boot_fail values.  This information is
        comprised of the pass/fail values from the table plus the initial
        pass/fail values.
        """

        totals_line = self.__boot_results.calc()
        return totals_line['pass'] + self.__initial_boot_pass,\
            totals_line['fail'] + self.__initial_boot_fail

    def update(self,
               boot_type,
               boot_status):
        r"""
        Update our boot_results_table.  This includes:
        - Updating the record for the given boot_type by incrementing the pass
          or fail field.
        - Calling the calc method to have the totals calculated.

        Description of arguments:
        boot_type    The type of boot test just done (e.g. "BMC Power On").
        boot_status  The status of the boot just done.  This should be equal to
                     either "pass" or "fail" (case-insensitive).
        """

        self.__boot_results.inc_row_field(boot_type, boot_status.lower())
        self.__boot_results.calc()

    def sprint_report(self,
                      header_footer="\n"):
        r"""
        String-print the formatted boot_resuls_table and return them.

        Description of arguments:
        header_footer  This indicates whether a header and footer are to be
                       included in the report.
        """

        buffer = ""

        buffer += gp.sprint(header_footer)
        buffer += self.__boot_results.sprint_report()
        buffer += gp.sprint(header_footer)

        return buffer

    def print_report(self,
                     header_footer="\n"):
        r"""
        Print the formatted boot_resuls_table to the console.

        See sprint_report for details.
        """

        grp.rqprint(self.sprint_report(header_footer))

    def sprint_obj(self):
        r"""
        sprint the fields of this object.  This would normally be for debug
        purposes only.
        """

        buffer = ""

        buffer += "class name: " + self.__class__.__name__ + "\n"
        buffer += gp.sprint_var(self.__obj_name)
        buffer += self.__boot_results.sprint_obj()
        buffer += gp.sprint_var(self.__initial_boot_pass)
        buffer += gp.sprint_var(self.__initial_boot_fail)

        return buffer

    def print_obj(self):
        r"""
        Print the fields of this object to stdout.  This would normally be for
        debug purposes.
        """

        grp.rprint(self.sprint_obj())


def create_boot_results_file_path(pgm_name,
                                  openbmc_nickname,
                                  master_pid):
    r"""
    Create a file path to be used to store a boot_results object.

    Description of argument(s):
    pgm_name          The name of the program.  This will form part of the
                      resulting file name.
    openbmc_nickname  The name of the system.  This could be a nickname, a
                      hostname, an IP, etc.  This will form part of the
                      resulting file name.
    master_pid        The master process id which will form part of the file
                      name.
    """

    USER = os.environ.get("USER", "")
    dir_path = "/tmp/" + USER + "/"
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)

    file_name_dict = vf.create_var_dict(pgm_name, openbmc_nickname, master_pid)
    return vf.create_file_path(file_name_dict, dir_path=dir_path,
                               file_suffix=":boot_results")


def cleanup_boot_results_file():
    r"""
    Delete all boot results files whose corresponding pids are no longer
    active.
    """

    # Use create_boot_results_file_path to create a globex to find all of the
    # existing boot results files.
    globex = create_boot_results_file_path("*", "*", "*")
    file_list = sorted(glob.glob(globex))
    for file_path in file_list:
        # Use parse_file_path to extract info from the file path.
        file_dict = vf.parse_file_path(file_path)
        if gm.pid_active(file_dict['master_pid']):
            gp.qprint_timen("Preserving " + file_path + ".")
        else:
            gc.cmd_fnc("rm -f " + file_path)
