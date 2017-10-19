#!/usr/bin/env python

r"""
This file contains functions which are useful for processing BMC dumps.
"""

import gen_print as gp
import bmc_ssh_utils as bsu
import var_funcs as vf
from robot.libraries.BuiltIn import BuiltIn
import sys
import os
import imp
base_path = os.path.dirname(os.path.dirname(
                            imp.find_module("gen_robot_print")[1])) + os.sep
sys.path.append(base_path + "data/")
import variables as var


def get_dump_dict(quiet=None):

    r"""
    Get dump information and return as an ordered dictionary where the keys
    are the dump IDs and the values are the full path names of the dumps.

    Example robot program call:

    ${dump_dict}=  Get Dump Dict
    Rpvars                          1  dump_dict

    Example output:

    dump_dict:
      [1]: /var/lib/phosphor-debug-collector/dumps/1/obmcdump_1_1508255216.tar.xz
      [2]: /var/lib/phosphor-debug-collector/dumps/2/obmcdump_2_1508255245.tar.xz
      [3]: /var/lib/phosphor-debug-collector/dumps/3/obmcdump_3_1508255267.tar.xz
      [4]: /var/lib/phosphor-debug-collector/dumps/4/obmcdump_4_1508255283.tar.xz

    Description of argument(s):
    quiet                           If quiet is set to 1, this function will
                                    NOT write status messages to stdout.
    """

    quiet = int(gp.get_var_value(quiet, 1))
    cmd_buf = "dump_dir_path=" + var.DUMP_DIR_PATH  + " ; " \
              + "for dump_id in $(ls ${dump_dir_path} | sort -n) ; " \
              + "do echo -n $dump_id: ; ls ${dump_dir_path}${dump_id}/* ; done"
    output, stderr, rc = bsu.bmc_execute_command(cmd_buf, quiet=quiet)

    return vf.key_value_outbuf_to_dict(output)


def valid_dump(dump_id,
               dump_dict=None,
               quiet=None):

    r"""
    Verify that dump_id is a valid.  If it is not valid, issue robot failure
    message.

    A dump is valid if the indicated dump_id refers to an existing dump with a
    valid associated dump file.

    Description of argument(s):
    dump_id                         A dump ID (e.g. "1", "2", etc.)
    dump_dict                       A dump dictionary such as the one returned
                                    by get_dump_dict.  If this value is None,
                                    this function will call get_dump_dict on
                                    the caller's behalf.
    quiet                           If quiet is set to 1, this function will
                                    NOT write status messages to stdout.
    """

    if dump_dict is None:
        dump_dict = get_dump_dict(quiet=quiet)

    if dump_id not in dump_dict:
        message = "The specified dump ID was not found among the existing" \
            + " dumps:\n"
        message += gp.sprint_var(dump_id)
        message += gp.sprint_var(dump_dict)
        BuiltIn().fail(gp.sprint_error(message))

    if not dump_dict[dump_id].endswith("tar.xz"):
        message = "There is no \"tar.xz\" file associated with the given" \
            + " dump_id:\n"
        message += gp.sprint_var(dump_id)
        dump_file_path = dump_dict[dump_id]
        message += gp.sprint_var(dump_file_path)
        BuiltIn().fail(gp.sprint_error(message))
