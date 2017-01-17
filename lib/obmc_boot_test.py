#!/usr/bin/env python

r"""
This module is the python counterpart to obmc_boot_test.
"""

from tally_sheet import *
import gen_robot_print as grp
import gen_robot_plug_in as grpi
import state as st

import os
import time
import subprocess
import glob

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
    openbmc_host = BuiltIn().get_variable_value("${openbmc_host}")
    if openbmc_nickname == "":
        openbmc_nickname = openbmc_host
    ffdc_prefix = openbmc_nickname

    ffdc_prefix += "." + time_string

    try:
        ffdc_dir_path = os.environ['FFDC_DIR_PATH']
        # Add trailing slash.
        ffdc_dir_path = os.path.normpath(ffdc_dir_path) + os.sep
    except KeyError:
        ffdc_dir_path = ""
    BuiltIn().set_global_variable("${FFDC_DIR_PATH}", ffdc_dir_path)

    status_dir_path = os.environ.get('STATUS_DIR_PATH', "")
    if status_dir_path != "":
        # Add trailing slash.
        status_dir_path = os.path.normpath(status_dir_path) + os.sep
    BuiltIn().set_global_variable("${STATUS_DIR_PATH}", status_dir_path)

    base_tool_dir_path = os.environ.get('AUTOBOOT_BASE_TOOL_DIR_PATH', "/tmp")
    base_tool_dir_path = os.path.normpath(base_tool_dir_path) + os.sep
    BuiltIn().set_global_variable("${BASE_TOOL_DIR_PATH}", base_tool_dir_path)

    ffdc_list_file_path = base_tool_dir_path + openbmc_nickname +\
        "/FFDC_FILE_LIST"

    BuiltIn().set_global_variable("${FFDC_LIST_FILE_PATH}",
                                  ffdc_list_file_path)

    # For each program parameter, set the corresponding AUTOBOOT_ environment
    # variable value.  Also, set an AUTOBOOT_ environment variable for every
    # element in additional_values.
    additional_values = ["boot_type_desc", "boot_success", "boot_pass",
                         "boot_fail", "test_really_running", "program_pid",
                         "master_pid", "ffdc_prefix", "ffdc_dir_path",
                         "status_dir_path", "base_tool_dir_path",
                         "ffdc_list_file_path"]
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

    Description of arguments:
    boot_type    The type of boot just done (e.g. "BMC Power On").
    boot_status  The status of the boot just done.  This should be equal to
                 either "pass" or "fail" (case-insensitive).
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

    grp.rqprint(header_footer)
    grp.rqprint(boot_results.sprint_report())
    grp.rqprint(header_footer)

###############################################################################


###############################################################################
def select_boot(state):

    r"""
    Select a boot test to be run based on our current state and return the
    chosen boot type.

    Description of arguments:
    state  The state of the machine, which will include the power state..
    """

    if 'chassis' in state:
        # New style state.
        if state['chassis'] == 'Off':
            boot = 'BMC Power On'
        else:
            boot = 'BMC Power Off'
    else:
        # Old style state.
        if state['power'] == 0:
            boot = 'BMC Power On'
        else:
            boot = 'BMC Power Off'

    return boot

###############################################################################


###############################################################################
def my_ffdc():

    r"""
    Collect FFDC data.
    """

    plug_in_setup()
    rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
        call_point='ffdc', stop_on_plug_in_failure=1)

    AUTOBOOT_FFDC_PREFIX = os.environ['AUTOBOOT_FFDC_PREFIX']

    # FFDC_LOG_PATH is used by "FFDC" keyword.
    FFDC_DIR_PATH = BuiltIn().get_variable_value("${FFDC_DIR_PATH}")
    BuiltIn().set_global_variable("${FFDC_LOG_PATH}",
                                  FFDC_DIR_PATH)

    cmd_buf = ["FFDC", "ffdc_prefix=" + AUTOBOOT_FFDC_PREFIX]
    grp.rpissuing_keyword(cmd_buf)
    BuiltIn().run_keyword(*cmd_buf)

    state = st.get_state()
    BuiltIn().set_global_variable("${state}",
                                  state)

    cmd_buf = ["Print Defect Report"]
    grp.rpissuing_keyword(cmd_buf)
    BuiltIn().run_keyword(*cmd_buf)

###############################################################################


###############################################################################
def print_last_boots():

    r"""
    Print the last ten boots done with their time stamps.
    """

    # indent 0, 90 chars wide, linefeed, char is "="
    grp.rqprint_dashes(0, 90)
    grp.rqprintn("Last 10 boots:\n")
    last_ten = BuiltIn().get_variable_value("${LAST_TEN}")

    for boot_entry in last_ten:
        grp.rqprint(boot_entry)
    grp.rqprint_dashes(0, 90)

###############################################################################


###############################################################################
def print_test_start_message(boot_keyword):

    r"""
    Print a message indicating what boot test is about to run.

    Description of arguments:
    boot_keyword  The name of the boot which is to be run
                  (e.g. "BMC Power On").
    """

    doing_msg = gp.sprint_timen("Doing \"" + boot_keyword + "\".")
    grp.rqprint(doing_msg)

    last_ten = BuiltIn().get_variable_value("${LAST_TEN}")
    last_ten.append(doing_msg)

    if len(last_ten) > 10:
        del last_ten[0]

###############################################################################


###############################################################################
def print_defect_report():

    r"""
    Print a defect report.
    """

    grp.rqprintn()
    # indent=0, width=90, linefeed=1, char="="
    grp.rqprint_dashes(0, 90, 1, "=")
    grp.rqprintn("Copy this data to the defect:\n")

    parm_list = BuiltIn().get_variable_value("${parm_list}")

    grp.rqpvars(*parm_list)

    grp.rqprintn()

    print_last_boots()
    grp.rqprintn()
    state = BuiltIn().get_variable_value("${state}")
    grp.rqpvar(state)

    # At some point I'd like to have the 'Call FFDC Methods' return a list
    # of files it has collected.  In that case, the following "ls" command
    # would no longer be needed.  For now, however, glob shows the files
    # named in FFDC_LIST_FILE_PATH so I will refrain from printing those
    # out (so we don't see duplicates in the list).

    LOG_PREFIX = BuiltIn().get_variable_value("${LOG_PREFIX}")

    output = '\n'.join(glob.glob(LOG_PREFIX + '*'))

    FFDC_LIST_FILE_PATH = \
        BuiltIn().get_variable_value("${FFDC_LIST_FILE_PATH}")

    try:
        ffdc_list = open(FFDC_LIST_FILE_PATH, 'r')
    except IOError:
        ffdc_list = ""

    status_file_path = BuiltIn().get_variable_value("${status_file_path}")

    grp.rqprintn()
    grp.rqprintn("FFDC data files:")
    if status_file_path != "":
        grp.rqprintn(status_file_path)

    grp.rqprintn(output)
    # grp.rqprintn(ffdc_list)
    grp.rqprintn()

    grp.rqprint_dashes(0, 90, 1, "=")

###############################################################################
