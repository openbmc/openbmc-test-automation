#!/usr/bin/env python

r"""
This module is the python counterpart to obmc_boot_test.
"""

from tally_sheet import *
import gen_robot_print as grp

import os
import time
import subprocess

from robot.utils import DotDict
from robot.libraries.BuiltIn import BuiltIn
from robot.libraries.OperatingSystem import OperatingSystem

# Create boot_results_fields for use in creating boot_results.
boot_results_fields = DotDict([('total', 0), ('pass', 0), ('fail', 0)])
# Create boot_results which is global to this module.
boot_results = tally_sheet('boot type',
                           boot_results_fields,
                           'boot_test_results')

boot_results.set_sum_fields(['total', 'pass', 'fail'])
boot_results.set_calc_fields(['total=pass+fail'])


###############################################################################
def add_trailing_slash(path):

    r"""
    Add a trailing slash to path if it doesn't already have one and return it.

    """

    return os.path.normpath(path) + os.sep

###############################################################################


###############################################################################
def plug_in_setup():

    r"""
    Initialize all plug-in environment variables for use by the plug-in
    programs.
    """

    boot_pass = int(BuiltIn().get_variable_value("${boot_pass}"))
    if boot_pass > 1:
        test_really_running = 1
    else:
        test_really_running = 0

    BuiltIn().set_global_variable("${test_really_running}",
                                  test_really_running)

    next_boot = BuiltIn().get_variable_value("${next_boot}")
    BuiltIn().set_global_variable("${boot_type_desc}", next_boot)

    # Setting master_pid correctly influences the behavior of plug-ins like
    # DB_Logging
    program_pid = BuiltIn().get_variable_value("${program_pid}")
    try:
        master_pid = OperatingSystem().get_environment_variable(
            "AUTOBOOT_MASTER_PID")
    except RuntimeError:
        master_pid = program_pid
    if master_pid == "":
        master_pid = program_pid

    BuiltIn().set_global_variable("${master_pid}", master_pid)

    seconds = time.time()
    loc_time = time.localtime(seconds)
    time_string = time.strftime("%y%m%d.%H%M%S.", loc_time)

    openbmc_nickname = BuiltIn().get_variable_value("${openbmc_nickname}")
    if openbmc_nickname == "":
        openbmc_host = BuiltIn().get_variable_value("${openbmc_host}")
        ffdc_prefix = openbmc_host
    else:
        ffdc_prefix = openbmc_nickname

    ffdc_prefix += "." + time_string

    ffdc_dir_path = OperatingSystem().get_environment_variable(
        "FFDC_DIR_PATH")
    # Add trailing slash.
    ffdc_dir_path = os.path.normpath(ffdc_dir_path) + os.sep
    BuiltIn().set_global_variable("${FFDC_DIR_PATH}", ffdc_dir_path)

    # For each program parameter, set the corresponding AUTOBOOT_ environment
    # variable value.  Also, set an AUTOBOOT_ environment variable for every
    # element in additional_values.
    additional_values = ["boot_type_desc", "boot_success", "boot_pass",
                         "boot_fail", "test_really_running", "program_pid",
                         "master_pid", "ffdc_prefix", "ffdc_dir_path"]
    BuiltIn().set_global_variable("${ffdc_prefix}", ffdc_prefix)

    parm_list = BuiltIn().get_variable_value("@{parm_list}")

    plug_in_vars = parm_list + additional_values

    for var_name in plug_in_vars:
        var_value = BuiltIn().get_variable_value("${" + var_name + "}")
        var_name = var_name.upper()
        if var_value is None:
            var_value = ""
        OperatingSystem().set_environment_variable(
            "AUTOBOOT_" + var_name, var_value)

    debug = int(BuiltIn().get_variable_value("${debug}"))
    if debug:
        cmd_buf = "printenv | egrep AUTOBOOT_ | sort -u"
        grp.rpissuing(cmd_buf)
        sub_proc = subprocess.Popen(cmd_buf, shell=True,
                                    stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT)
        out_buf, err_buf = sub_proc.communicate()
        shell_rc = sub_proc.returncode
        grp.rprint(out_buf)

###############################################################################


###############################################################################
def create_boot_results_table():

    r"""
    Create our boot_results_table.
    """

    # At some point we'll want to change to reading in our boot types from
    # some external source (e.g. file).

    boot_results.add_row('BMC Power On')
    boot_results.add_row('BMC Power Off')

###############################################################################


###############################################################################
def update_boot_results_table(boot_type,
                              boot_status):

    r"""
    Update our boot_results_table.  This includes:
    - Updating the record for the given boot_type by incrementing the pass or
      fail field.
    - Calling the calc method to have the totals, etc. calculated.
    - Updating global variables boot_pass/boot_fail.
    """

    boot_results.inc_row_field(boot_type, boot_status.lower())
    totals_line = boot_results.calc()

    # The caller of obmc_boot_test can pass boot_pass/boot_fail values because
    # the caller may have already done some testing (e.g. "BMC OOB").  For the
    # sake of DB logging done by plug-ins, we want to include these in our
    # overall totals.
    initial_boot_pass = int(BuiltIn().get_variable_value(
        "${initial_boot_pass}"))
    initial_boot_fail = int(BuiltIn().get_variable_value(
        "${initial_boot_fail}"))

    BuiltIn().set_global_variable("${boot_pass}",
                                  totals_line['pass'] + initial_boot_pass)
    BuiltIn().set_global_variable("${boot_fail}",
                                  totals_line['fail'] + initial_boot_fail)

###############################################################################


###############################################################################
def print_boot_results_table(header_footer="\n"):

    r"""
    Print the formatted boot_resuls_table to the console.
    """

    grp.rprint(header_footer)
    grp.rprint(boot_results.sprint_report())
    grp.rprint(header_footer)

###############################################################################
