#!/usr/bin/env python

r"""
This module is the python counterpart to obmc_boot_test.
"""

import os
import imp
import time
import glob
import random
import re
try:
    import cPickle as pickle
except ImportError:
    import pickle
import socket

from robot.utils import DotDict
from robot.libraries.BuiltIn import BuiltIn

from boot_data import *
import gen_print as gp
import gen_robot_print as grp
import gen_robot_plug_in as grpi
import gen_robot_valid as grv
import gen_misc as gm
import gen_cmd as gc
import gen_robot_keyword as grk
import state as st
import var_stack as vs

base_path = os.path.dirname(os.path.dirname(
                            imp.find_module("gen_robot_print")[1])) +\
    os.sep
sys.path.append(base_path + "extended/")
import run_keyword as rk

# Setting master_pid correctly influences the behavior of plug-ins like
# DB_Logging
program_pid = os.getpid()
master_pid = os.environ.get('AUTOBOOT_MASTER_PID', program_pid)
pgm_name = re.sub('\\.py$', '', os.path.basename(__file__))

# Set up boot data structures.
boot_table = create_boot_table()
valid_boot_types = create_valid_boot_list(boot_table)

boot_lists = read_boot_lists()
last_ten = []

state = st.return_state_constant('default_state')
cp_setup_called = 0
next_boot = ""
base_tool_dir_path = os.path.normpath(os.environ.get(
    'AUTOBOOT_BASE_TOOL_DIR_PATH', "/tmp")) + os.sep

ffdc_dir_path = os.path.normpath(os.environ.get('FFDC_DIR_PATH', '')) + os.sep
boot_success = 0
status_dir_path = os.environ.get('STATUS_DIR_PATH', "")
if status_dir_path != "":
    status_dir_path = os.path.normpath(status_dir_path) + os.sep
default_power_on = "REST Power On"
default_power_off = "REST Power Off"
boot_count = 0

LOG_LEVEL = BuiltIn().get_variable_value("${LOG_LEVEL}")
ffdc_prefix = ""
boot_start_time = ""
boot_end_time = ""
save_stack = vs.var_stack('save_stack')
main_func_parm_list = ['boot_stack', 'stack_mode', 'quiet']


def process_host(host,
                 host_var_name=""):
    r"""
    Process a host by getting the associated host name and IP address and
    setting them in global variables.

    If the caller does not pass the host_var_name, this function will try to
    figure out the name of the variable used by the caller for the host parm.
    Callers are advised to explicitly specify the host_var_name when calling
    with an exec command.  In such cases, the get_arg_name cannot figure out
    the host variable name.

    This function will then create similar global variable names by
    removing "_host" and appending "_host_name" or "_ip" to the host variable
    name.

    Example:

    If a call is made like this:
    process_host(openbmc_host)

    Global variables openbmc_host_name and openbmc_ip will be set.

    Description of argument(s):
    host           A host name or IP.  The name of the variable used should
                   have a suffix of "_host".
    host_var_name  The name of the variable being used as the host parm.
    """

    if host_var_name == "":
        host_var_name = gp.get_arg_name(0, 1, stack_frame_ix=2)

    host_name_var_name = re.sub("host", "host_name", host_var_name)
    ip_var_name = re.sub("host", "ip", host_var_name)
    cmd_buf = "global " + host_name_var_name + ", " + ip_var_name + " ; " +\
        host_name_var_name + ", " + ip_var_name + " = gm.get_host_name_ip('" +\
        host + "')"
    exec(cmd_buf)


def process_pgm_parms():
    r"""
    Process the program parameters by assigning them all to corresponding
    globals.  Also, set some global values that depend on program parameters.
    """

    # Program parameter processing.
    # Assign all program parms to python variables which are global to this
    # module.

    global parm_list
    parm_list = BuiltIn().get_variable_value("${parm_list}")
    # The following subset of parms should be processed as integers.
    int_list = ['max_num_tests', 'boot_pass', 'boot_fail', 'ffdc_only',
                'boot_fail_threshold', 'delete_errlogs',
                'call_post_stack_plug', 'quiet', 'test_mode', 'debug']
    for parm in parm_list:
        if parm in int_list:
            sub_cmd = "int(BuiltIn().get_variable_value(\"${" + parm +\
                      "}\", \"0\"))"
        else:
            sub_cmd = "BuiltIn().get_variable_value(\"${" + parm + "}\")"
        cmd_buf = "global " + parm + " ; " + parm + " = " + sub_cmd
        gp.dpissuing(cmd_buf)
        exec(cmd_buf)
        if re.match(r".*_host$", parm):
            cmd_buf = "process_host(" + parm + ", '" + parm + "')"
            exec(cmd_buf)
        if re.match(r".*_password$", parm):
            # Register the value of any parm whose name ends in _password.
            # This will cause the print functions to replace passwords with
            # asterisks in the output.
            cmd_buf = "gp.register_passwords(" + parm + ")"
            exec(cmd_buf)

    global ffdc_dir_path_style
    global boot_list
    global boot_stack
    global boot_results_file_path
    global boot_results
    global last_ten
    global ffdc_list_file_path
    global ffdc_report_list_path
    global ffdc_summary_list_path

    if ffdc_dir_path_style == "":
        ffdc_dir_path_style = int(os.environ.get('FFDC_DIR_PATH_STYLE', '0'))

    # Convert these program parms to lists for easier processing..
    boot_list = filter(None, boot_list.split(":"))
    boot_stack = filter(None, boot_stack.split(":"))

    cleanup_boot_results_file()
    boot_results_file_path = create_boot_results_file_path(pgm_name,
                                                           openbmc_nickname,
                                                           master_pid)

    if os.path.isfile(boot_results_file_path):
        # We've been called before in this run so we'll load the saved
        # boot_results and last_ten objects.
        boot_results, last_ten =\
            pickle.load(open(boot_results_file_path, 'rb'))
    else:
        boot_results = boot_results(boot_table, boot_pass, boot_fail)

    ffdc_list_file_path = base_tool_dir_path + openbmc_nickname +\
        "/FFDC_FILE_LIST"
    ffdc_report_list_path = base_tool_dir_path + openbmc_nickname +\
        "/FFDC_REPORT_FILE_LIST"

    ffdc_summary_list_path = base_tool_dir_path + openbmc_nickname +\
        "/FFDC_SUMMARY_FILE_LIST"


def initial_plug_in_setup():
    r"""
    Initialize all plug-in environment variables which do not change for the
    duration of the program.

    """

    global LOG_LEVEL
    BuiltIn().set_log_level("NONE")

    BuiltIn().set_global_variable("${master_pid}", master_pid)
    BuiltIn().set_global_variable("${FFDC_DIR_PATH}", ffdc_dir_path)
    BuiltIn().set_global_variable("${STATUS_DIR_PATH}", status_dir_path)
    BuiltIn().set_global_variable("${BASE_TOOL_DIR_PATH}", base_tool_dir_path)
    BuiltIn().set_global_variable("${FFDC_LIST_FILE_PATH}",
                                  ffdc_list_file_path)
    BuiltIn().set_global_variable("${FFDC_REPORT_LIST_PATH}",
                                  ffdc_report_list_path)
    BuiltIn().set_global_variable("${FFDC_SUMMARY_LIST_PATH}",
                                  ffdc_summary_list_path)

    BuiltIn().set_global_variable("${FFDC_DIR_PATH_STYLE}",
                                  ffdc_dir_path_style)
    BuiltIn().set_global_variable("${FFDC_CHECK}",
                                  ffdc_check)

    # For each program parameter, set the corresponding AUTOBOOT_ environment
    # variable value.  Also, set an AUTOBOOT_ environment variable for every
    # element in additional_values.
    additional_values = ["program_pid", "master_pid", "ffdc_dir_path",
                         "status_dir_path", "base_tool_dir_path",
                         "ffdc_list_file_path", "ffdc_report_list_path",
                         "ffdc_summary_list_path"]

    plug_in_vars = parm_list + additional_values

    for var_name in plug_in_vars:
        var_value = BuiltIn().get_variable_value("${" + var_name + "}")
        var_name = var_name.upper()
        if var_value is None:
            var_value = ""
        os.environ["AUTOBOOT_" + var_name] = str(var_value)

    BuiltIn().set_log_level(LOG_LEVEL)

    # Make sure the ffdc list directory exists.
    ffdc_list_dir_path = os.path.dirname(ffdc_list_file_path) + os.sep
    if not os.path.exists(ffdc_list_dir_path):
        os.makedirs(ffdc_list_dir_path)


def plug_in_setup():
    r"""
    Initialize all changing plug-in environment variables for use by the
    plug-in programs.
    """

    global LOG_LEVEL
    global test_really_running

    BuiltIn().set_log_level("NONE")

    boot_pass, boot_fail = boot_results.return_total_pass_fail()
    if boot_pass > 1:
        test_really_running = 1
    else:
        test_really_running = 0

    BuiltIn().set_global_variable("${test_really_running}",
                                  test_really_running)
    BuiltIn().set_global_variable("${boot_type_desc}", next_boot)
    BuiltIn().set_global_variable("${boot_pass}", boot_pass)
    BuiltIn().set_global_variable("${boot_fail}", boot_fail)
    BuiltIn().set_global_variable("${boot_success}", boot_success)
    BuiltIn().set_global_variable("${ffdc_prefix}", ffdc_prefix)
    BuiltIn().set_global_variable("${boot_start_time}", boot_start_time)
    BuiltIn().set_global_variable("${boot_end_time}", boot_end_time)

    # For each program parameter, set the corresponding AUTOBOOT_ environment
    # variable value.  Also, set an AUTOBOOT_ environment variable for every
    # element in additional_values.
    additional_values = ["boot_type_desc", "boot_success", "boot_pass",
                         "boot_fail", "test_really_running", "ffdc_prefix",
                         "boot_start_time", "boot_end_time"]

    plug_in_vars = additional_values

    for var_name in plug_in_vars:
        var_value = BuiltIn().get_variable_value("${" + var_name + "}")
        var_name = var_name.upper()
        if var_value is None:
            var_value = ""
        os.environ["AUTOBOOT_" + var_name] = str(var_value)

    if debug:
        shell_rc, out_buf = \
            gc.cmd_fnc_u("printenv | egrep AUTOBOOT_ | sort -u")

    BuiltIn().set_log_level(LOG_LEVEL)


def pre_boot_plug_in_setup():

    # Clear the ffdc_list_file_path file.  Plug-ins may now write to it.
    try:
        os.remove(ffdc_list_file_path)
    except OSError:
        pass

    # Clear the ffdc_report_list_path file.  Plug-ins may now write to it.
    try:
        os.remove(ffdc_report_list_path)
    except OSError:
        pass

    # Clear the ffdc_summary_list_path file.  Plug-ins may now write to it.
    try:
        os.remove(ffdc_summary_list_path)
    except OSError:
        pass

    global ffdc_prefix

    seconds = time.time()
    loc_time = time.localtime(seconds)
    time_string = time.strftime("%y%m%d.%H%M%S.", loc_time)

    ffdc_prefix = openbmc_nickname + "." + time_string


def setup():
    r"""
    Do general program setup tasks.
    """

    global cp_setup_called
    global transitional_boot_selected

    gp.qprintn()

    transitional_boot_selected = False

    robot_pgm_dir_path = os.path.dirname(__file__) + os.sep
    repo_bin_path = robot_pgm_dir_path.replace("/lib/", "/bin/")
    # If we can't find process_plug_in_packages.py, ssh_pw or
    # validate_plug_ins.py, then we don't have our repo bin in PATH.
    shell_rc, out_buf = gc.cmd_fnc_u("which process_plug_in_packages.py"
                                     + " ssh_pw validate_plug_ins.py", quiet=1,
                                     print_output=0, show_err=0)
    if shell_rc != 0:
        os.environ['PATH'] = repo_bin_path + ":" + os.environ.get('PATH', "")
    # Likewise, our repo lib subdir needs to be in sys.path and PYTHONPATH.
    if robot_pgm_dir_path not in sys.path:
        sys.path.append(robot_pgm_dir_path)
        PYTHONPATH = os.environ.get("PYTHONPATH", "")
        if PYTHONPATH == "":
            os.environ['PYTHONPATH'] = robot_pgm_dir_path
        else:
            os.environ['PYTHONPATH'] = robot_pgm_dir_path + ":" + PYTHONPATH

    validate_parms()

    grp.rqprint_pgm_header()

    grk.run_key("Set BMC Power Policy  ALWAYS_POWER_OFF")

    initial_plug_in_setup()

    plug_in_setup()
    rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
        call_point='setup')
    if rc != 0:
        error_message = "Plug-in setup failed.\n"
        grp.rprint_error_report(error_message)
        BuiltIn().fail(error_message)
    # Setting cp_setup_called lets our Teardown know that it needs to call
    # the cleanup plug-in call point.
    cp_setup_called = 1

    # Keyword "FFDC" will fail if TEST_MESSAGE is not set.
    BuiltIn().set_global_variable("${TEST_MESSAGE}", "${EMPTY}")
    # FFDC_LOG_PATH is used by "FFDC" keyword.
    BuiltIn().set_global_variable("${FFDC_LOG_PATH}", ffdc_dir_path)

    # Also printed by FFDC.
    global host_name
    global host_ip
    host = socket.gethostname()
    host_name, host_ip = gm.get_host_name_ip(host)

    gp.dprint_var(boot_table, 1)
    gp.dprint_var(boot_lists)


def validate_parms():
    r"""
    Validate all program parameters.
    """

    process_pgm_parms()

    gp.qprintn()

    global openbmc_model
    grv.rvalid_value("openbmc_host")
    grv.rvalid_value("openbmc_username")
    grv.rvalid_value("openbmc_password")
    if os_host != "":
        grv.rvalid_value("os_username")
        grv.rvalid_value("os_password")

    if pdu_host != "":
        grv.rvalid_value("pdu_username")
        grv.rvalid_value("pdu_password")
        grv.rvalid_integer("pdu_slot_no")
    if openbmc_serial_host != "":
        grv.rvalid_integer("openbmc_serial_port")
    if openbmc_model == "":
        status, ret_values =\
            grk.run_key_u("Get BMC System Model")
        openbmc_model = ret_values
        BuiltIn().set_global_variable("${openbmc_model}", openbmc_model)
    grv.rvalid_value("openbmc_model")
    grv.rvalid_integer("max_num_tests")
    grv.rvalid_integer("boot_pass")
    grv.rvalid_integer("boot_fail")

    plug_in_packages_list = grpi.rvalidate_plug_ins(plug_in_dir_paths)
    BuiltIn().set_global_variable("${plug_in_packages_list}",
                                  plug_in_packages_list)

    grv.rvalid_value("stack_mode", valid_values=['normal', 'skip'])
    if len(boot_list) == 0 and len(boot_stack) == 0 and not ffdc_only:
        error_message = "You must provide either a value for either the" +\
            " boot_list or the boot_stack parm.\n"
        BuiltIn().fail(gp.sprint_error(error_message))

    valid_boot_list(boot_list, valid_boot_types)
    valid_boot_list(boot_stack, valid_boot_types)

    selected_PDU_boots = list(set(boot_list + boot_stack)
                              & set(boot_lists['PDU_reboot']))

    if len(selected_PDU_boots) > 0 and pdu_host == "":
        error_message = "You have selected the following boots which" +\
                        " require a PDU host but no value for pdu_host:\n"
        error_message += gp.sprint_var(selected_PDU_boots)
        error_message += gp.sprint_var(pdu_host, 2)
        BuiltIn().fail(gp.sprint_error(error_message))

    return


def my_get_state():
    r"""
    Get the system state plus a little bit of wrapping.
    """

    global state

    req_states = ['epoch_seconds'] + st.default_req_states

    gp.qprint_timen("Getting system state.")
    if test_mode:
        state['epoch_seconds'] = int(time.time())
    else:
        state = st.get_state(req_states=req_states, quiet=quiet)
    gp.qprint_var(state)


def valid_state():
    r"""
    Verify that our state dictionary contains no blank values.  If we don't get
    valid state data, we cannot continue to work.
    """

    if st.compare_states(state, st.invalid_state_match, 'or'):
        error_message = "The state dictionary contains blank fields which" +\
            " is illegal.\n" + gp.sprint_var(state)
        BuiltIn().fail(gp.sprint_error(error_message))


def select_boot():
    r"""
    Select a boot test to be run based on our current state and return the
    chosen boot type.

    Description of arguments:
    state  The state of the machine.
    """

    global transitional_boot_selected
    global boot_stack

    gp.qprint_timen("Selecting a boot test.")

    if transitional_boot_selected and not boot_success:
        prior_boot = next_boot
        boot_candidate = boot_stack.pop()
        gp.qprint_timen("The prior '" + next_boot + "' was chosen to"
                        + " transition to a valid state for '" + boot_candidate
                        + "' which was at the top of the boot_stack.  Since"
                        + " the '" + next_boot + "' failed, the '"
                        + boot_candidate + "' has been removed from the stack"
                        + " to avoid and endless failure loop.")
        if len(boot_stack) == 0:
            return ""

    my_get_state()
    valid_state()

    transitional_boot_selected = False
    stack_popped = 0
    if len(boot_stack) > 0:
        stack_popped = 1
        gp.qprint_dashes()
        gp.qprint_var(boot_stack)
        gp.qprint_dashes()
        skip_boot_printed = 0
        while len(boot_stack) > 0:
            boot_candidate = boot_stack.pop()
            if stack_mode == 'normal':
                break
            else:
                if st.compare_states(state, boot_table[boot_candidate]['end']):
                    if not skip_boot_printed:
                        gp.qprint_var(stack_mode)
                        gp.qprintn()
                        gp.qprint_timen("Skipping the following boot tests"
                                        + " which are unnecessary since their"
                                        + " required end states match the"
                                        + " current machine state:")
                        skip_boot_printed = 1
                    gp.qprint_var(boot_candidate)
                    boot_candidate = ""
        if boot_candidate == "":
            gp.qprint_dashes()
            gp.qprint_var(boot_stack)
            gp.qprint_dashes()
            return boot_candidate
        if st.compare_states(state, boot_table[boot_candidate]['start']):
            gp.qprint_timen("The machine state is valid for a '"
                            + boot_candidate + "' boot test.")
            gp.qprint_dashes()
            gp.qprint_var(boot_stack)
            gp.qprint_dashes()
            return boot_candidate
        else:
            gp.qprint_timen("The machine state does not match the required"
                            + " starting state for a '" + boot_candidate
                            + "' boot test:")
            gp.qprint_varx("boot_table[" + boot_candidate + "][start]",
                           boot_table[boot_candidate]['start'], 1)
            boot_stack.append(boot_candidate)
            transitional_boot_selected = True
            popped_boot = boot_candidate

    # Loop through your list selecting a boot_candidates
    boot_candidates = []
    for boot_candidate in boot_list:
        if st.compare_states(state, boot_table[boot_candidate]['start']):
            if stack_popped:
                if st.compare_states(boot_table[boot_candidate]['end'],
                                     boot_table[popped_boot]['start']):
                    boot_candidates.append(boot_candidate)
            else:
                boot_candidates.append(boot_candidate)

    if len(boot_candidates) == 0:
        gp.qprint_timen("The user's boot list contained no boot tests"
                        + " which are valid for the current machine state.")
        boot_candidate = default_power_on
        if not st.compare_states(state, boot_table[default_power_on]['start']):
            boot_candidate = default_power_off
        boot_candidates.append(boot_candidate)
        gp.qprint_timen("Using default '" + boot_candidate
                        + "' boot type to transition to valid state.")

    gp.dprint_var(boot_candidates)

    # Randomly select a boot from the candidate list.
    boot = random.choice(boot_candidates)

    return boot


def print_last_boots():
    r"""
    Print the last ten boots done with their time stamps.
    """

    # indent 0, 90 chars wide, linefeed, char is "="
    gp.qprint_dashes(0, 90)
    gp.qprintn("Last 10 boots:\n")

    for boot_entry in last_ten:
        grp.rqprint(boot_entry)
    gp.qprint_dashes(0, 90)


def print_defect_report(ffdc_file_list):
    r"""
    Print a defect report.

    Description of argument(s):
    ffdc_file_list  A list of files which were collected by our ffdc functions.
    """

    # Making deliberate choice to NOT run plug_in_setup().  We don't want
    # ffdc_prefix updated.
    rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
        call_point='ffdc_report', stop_on_plug_in_failure=0)

    # Get additional header data which may have been created by ffdc plug-ins.
    # Also, delete the individual header files to cleanup.
    cmd_buf = "file_list=$(cat " + ffdc_report_list_path + " 2>/dev/null)" +\
              " ; [ ! -z \"${file_list}\" ] && cat ${file_list}" +\
              " 2>/dev/null ; rm -rf ${file_list} 2>/dev/null || :"
    shell_rc, more_header_info = gc.cmd_fnc_u(cmd_buf, print_output=0,
                                              show_err=0)

    # Get additional summary data which may have been created by ffdc plug-ins.
    # Also, delete the individual header files to cleanup.
    cmd_buf = "file_list=$(cat " + ffdc_summary_list_path + " 2>/dev/null)" +\
              " ; [ ! -z \"${file_list}\" ] && cat ${file_list}" +\
              " 2>/dev/null ; rm -rf ${file_list} 2>/dev/null || :"
    shell_rc, ffdc_summary_info = gc.cmd_fnc_u(cmd_buf, print_output=0,
                                               show_err=0)

    # ffdc_list_file_path contains a list of any ffdc files created by plug-
    # ins, etc.  Read that data into a list.
    try:
        plug_in_ffdc_list = \
            open(ffdc_list_file_path, 'r').read().rstrip("\n").split("\n")
        plug_in_ffdc_list = filter(None, plug_in_ffdc_list)
    except IOError:
        plug_in_ffdc_list = []

    # Combine the files from plug_in_ffdc_list with the ffdc_file_list passed
    # in.  Eliminate duplicates and sort the list.
    ffdc_file_list = sorted(set(ffdc_file_list + plug_in_ffdc_list))

    if status_file_path != "":
        ffdc_file_list.insert(0, status_file_path)

    # Convert the list to a printable list.
    printable_ffdc_file_list = "\n".join(ffdc_file_list)

    # Open ffdc_file_list for writing.  We will write a complete list of
    # FFDC files to it for possible use by plug-ins like cp_stop_check.
    ffdc_list_file = open(ffdc_list_file_path, 'w')
    ffdc_list_file.write(printable_ffdc_file_list + "\n")
    ffdc_list_file.close()

    indent = 0
    width = 90
    linefeed = 1
    char = "="

    gp.qprintn()
    gp.qprint_dashes(indent, width, linefeed, char)
    gp.qprintn("Copy this data to the defect:\n")

    if len(more_header_info) > 0:
        gp.qprintn(more_header_info)
    gp.qpvars(host_name, host_ip, openbmc_nickname, openbmc_host,
              openbmc_host_name, openbmc_ip, openbmc_username,
              openbmc_password, os_host, os_host_name, os_ip, os_username,
              os_password, pdu_host, pdu_host_name, pdu_ip, pdu_username,
              pdu_password, pdu_slot_no, openbmc_serial_host,
              openbmc_serial_host_name, openbmc_serial_ip, openbmc_serial_port)

    gp.qprintn()
    print_last_boots()
    gp.qprintn()
    gp.qprint_var(state)
    gp.qprintn()
    gp.qprintn("FFDC data files:")
    gp.qprintn(printable_ffdc_file_list)
    gp.qprintn()

    if len(ffdc_summary_info) > 0:
        gp.qprintn(ffdc_summary_info)

    gp.qprint_dashes(indent, width, linefeed, char)


def my_ffdc():
    r"""
    Collect FFDC data.
    """

    global state

    plug_in_setup()
    rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
        call_point='ffdc', stop_on_plug_in_failure=0)

    AUTOBOOT_FFDC_PREFIX = os.environ['AUTOBOOT_FFDC_PREFIX']
    status, ffdc_file_list = grk.run_key_u("FFDC  ffdc_prefix="
                                           + AUTOBOOT_FFDC_PREFIX
                                           + "  ffdc_function_list="
                                           + ffdc_function_list, ignore=1)
    if status != 'PASS':
        gp.qprint_error("Call to ffdc failed.\n")

    my_get_state()

    print_defect_report(ffdc_file_list)


def print_test_start_message(boot_keyword):
    r"""
    Print a message indicating what boot test is about to run.

    Description of arguments:
    boot_keyword  The name of the boot which is to be run
                  (e.g. "BMC Power On").
    """

    global last_ten
    global boot_start_time

    doing_msg = gp.sprint_timen("Doing \"" + boot_keyword + "\".")

    # Set boot_start_time for use by plug-ins.
    boot_start_time = doing_msg[1:33]
    gp.qprint_var(boot_start_time)

    gp.qprint(doing_msg)

    last_ten.append(doing_msg)

    if len(last_ten) > 10:
        del last_ten[0]


def run_boot(boot):
    r"""
    Run the specified boot.

    Description of arguments:
    boot  The name of the boot test to be performed.
    """

    global state

    print_test_start_message(boot)

    plug_in_setup()
    rc, shell_rc, failed_plug_in_name = \
        grpi.rprocess_plug_in_packages(call_point="pre_boot")
    if rc != 0:
        error_message = "Plug-in failed with non-zero return code.\n" +\
            gp.sprint_var(rc, 1)
        BuiltIn().fail(gp.sprint_error(error_message))

    if test_mode:
        # In test mode, we'll pretend the boot worked by assigning its
        # required end state to the default state value.
        state = st.strip_anchor_state(boot_table[boot]['end'])
    else:
        # Assertion:  We trust that the state data was made fresh by the
        # caller.

        gp.qprintn()

        if boot_table[boot]['method_type'] == "keyword":
            rk.my_run_keywords(boot_table[boot].get('lib_file_path', ''),
                               boot_table[boot]['method'],
                               quiet=quiet)

        if boot_table[boot]['bmc_reboot']:
            st.wait_for_comm_cycle(int(state['epoch_seconds']))
            plug_in_setup()
            rc, shell_rc, failed_plug_in_name = \
                grpi.rprocess_plug_in_packages(call_point="post_reboot")
            if rc != 0:
                error_message = "Plug-in failed with non-zero return code.\n"
                error_message += gp.sprint_var(rc, 1)
                BuiltIn().fail(gp.sprint_error(error_message))
        else:
            match_state = st.anchor_state(state)
            del match_state['epoch_seconds']
            # Wait for the state to change in any way.
            st.wait_state(match_state, wait_time=state_change_timeout,
                          interval="10 seconds", invert=1)

        gp.qprintn()
        if boot_table[boot]['end']['chassis'] == "Off":
            boot_timeout = power_off_timeout
        else:
            boot_timeout = power_on_timeout
        st.wait_state(boot_table[boot]['end'], wait_time=boot_timeout,
                      interval="10 seconds")

    plug_in_setup()
    rc, shell_rc, failed_plug_in_name = \
        grpi.rprocess_plug_in_packages(call_point="post_boot")
    if rc != 0:
        error_message = "Plug-in failed with non-zero return code.\n" +\
            gp.sprint_var(rc, 1)
        BuiltIn().fail(gp.sprint_error(error_message))


def test_loop_body():
    r"""
    The main loop body for the loop in main_py.

    Description of arguments:
    boot_count  The iteration number (starts at 1).
    """

    global boot_count
    global state
    global next_boot
    global boot_success
    global boot_end_time

    gp.qprintn()

    next_boot = select_boot()
    if next_boot == "":
        return True

    boot_count += 1
    gp.qprint_timen("Starting boot " + str(boot_count) + ".")

    pre_boot_plug_in_setup()

    cmd_buf = ["run_boot", next_boot]
    boot_status, msg = BuiltIn().run_keyword_and_ignore_error(*cmd_buf)
    if boot_status == "FAIL":
        gp.qprint(msg)

    gp.qprintn()
    if boot_status == "PASS":
        boot_success = 1
        completion_msg = gp.sprint_timen("BOOT_SUCCESS: \"" + next_boot
                                         + "\" succeeded.")
    else:
        boot_success = 0
        completion_msg = gp.sprint_timen("BOOT_FAILED: \"" + next_boot
                                         + "\" failed.")

    # Set boot_end_time for use by plug-ins.
    boot_end_time = completion_msg[1:33]
    gp.qprint_var(boot_end_time)

    gp.qprint(completion_msg)

    boot_results.update(next_boot, boot_status)

    plug_in_setup()
    # NOTE: A post_test_case call point failure is NOT counted as a boot
    # failure.
    rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
        call_point='post_test_case', stop_on_plug_in_failure=0)

    plug_in_setup()
    rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
        call_point='ffdc_check', shell_rc=0x00000200,
        stop_on_plug_in_failure=1, stop_on_non_zero_rc=1)
    if boot_status != "PASS" or ffdc_check == "All" or shell_rc == 0x00000200:
        status, ret_values = grk.run_key_u("my_ffdc", ignore=1)
        if status != 'PASS':
            gp.qprint_error("Call to my_ffdc failed.\n")

    if delete_errlogs:
        # We need to purge error logs between boots or they build up.
        grk.run_key("Delete Error logs", ignore=1)

    boot_results.print_report()
    gp.qprint_timen("Finished boot " + str(boot_count) + ".")

    plug_in_setup()
    rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
        call_point='stop_check', shell_rc=0x00000200, stop_on_non_zero_rc=1)
    if shell_rc == 0x00000200:
        message = "Stopping as requested by user.\n"
        gp.print_time(message)
        BuiltIn().fail(message)

    # This should help prevent ConnectionErrors.
    grk.run_key_u("Close All Connections")

    return True


def obmc_boot_test_teardown():
    r"""
    Clean up after the Main keyword.
    """

    if cp_setup_called:
        plug_in_setup()
        rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
            call_point='cleanup', stop_on_plug_in_failure=0)

    if 'boot_results_file_path' in globals():
        # Save boot_results and last_ten objects to a file in case they are
        # needed again.
        gp.qprint_timen("Saving boot_results to the following path.")
        gp.qprint_var(boot_results_file_path)
        pickle.dump((boot_results, last_ten),
                    open(boot_results_file_path, 'wb'),
                    pickle.HIGHEST_PROTOCOL)

    global save_stack
    # Restore any global values saved on the save_stack.
    for parm_name in main_func_parm_list:
        # Get the parm_value if it was saved on the stack.
        try:
            parm_value = save_stack.pop(parm_name)
        except BaseException:
            # If it was not saved, no further action is required.
            continue

        # Restore the saved value.
        cmd_buf = "BuiltIn().set_global_variable(\"${" + parm_name +\
            "}\", parm_value)"
        gp.dpissuing(cmd_buf)
        exec(cmd_buf)

    gp.dprintn(save_stack.sprint_obj())


def test_teardown():
    r"""
    Clean up after this test case.
    """

    gp.qprintn()
    cmd_buf = ["Print Error",
               "A keyword timeout occurred ending this program.\n"]
    BuiltIn().run_keyword_if_timeout_occurred(*cmd_buf)

    grp.rqprint_pgm_footer()


def post_stack():

    if not call_post_stack_plug:
        # The caller does not wish to have post_stack plug-in processing done.
        return

    global boot_success

    # NOTE: A post_stack call-point failure is NOT counted as a boot failure.
    pre_boot_plug_in_setup()
    # For the purposes of the following plug-ins, mark the "boot" as a success.
    boot_success = 1
    plug_in_setup()
    rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
        call_point='post_stack', stop_on_plug_in_failure=0)

    plug_in_setup()
    if rc == 0:
        rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
            call_point='ffdc_check', shell_rc=0x00000200,
            stop_on_plug_in_failure=1, stop_on_non_zero_rc=1)
    if rc != 0 or shell_rc == 0x00000200:
        status, ret_values = grk.run_key_u("my_ffdc", ignore=1)
        if status != 'PASS':
            gp.qprint_error("Call to my_ffdc failed.\n")

    plug_in_setup()
    rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
        call_point='stop_check', shell_rc=0x00000200, stop_on_non_zero_rc=1)
    if shell_rc == 0x00000200:
        message = "Stopping as requested by user.\n"
        gp.print_time(message)
        BuiltIn().fail(message)


def obmc_boot_test_py(loc_boot_stack=None,
                      loc_stack_mode=None,
                      loc_quiet=None):
    r"""
    Do main program processing.
    """

    global save_stack

    # Process function parms.
    for parm_name in main_func_parm_list:
        # Get parm's value.
        cmd_buf = "parm_value = loc_" + parm_name
        exec(cmd_buf)
        gp.dpvar(parm_name)
        gp.dpvar(parm_value)

        if parm_value is None:
            # Parm was not specified by the calling function so set it to its
            # corresponding global value.
            cmd_buf = "loc_" + parm_name + " = BuiltIn().get_variable_value" +\
                "(\"${" + parm_name + "}\")"
            gp.dpissuing(cmd_buf)
            exec(cmd_buf)
        else:
            # Save the global value on a stack.
            cmd_buf = "save_stack.push(BuiltIn().get_variable_value(\"${" +\
                parm_name + "}\"), \"" + parm_name + "\")"
            gp.dpissuing(cmd_buf)
            exec(cmd_buf)

            # Set the global value to the passed value.
            cmd_buf = "BuiltIn().set_global_variable(\"${" + parm_name +\
                "}\", loc_" + parm_name + ")"
            gp.dpissuing(cmd_buf)
            exec(cmd_buf)

    gp.dprintn(save_stack.sprint_obj())

    setup()

    init_boot_pass, init_boot_fail = boot_results.return_total_pass_fail()

    if ffdc_only:
        gp.qprint_timen("Caller requested ffdc_only.")
        pre_boot_plug_in_setup()
        grk.run_key_u("my_ffdc")
        return

    # Process caller's boot_stack.
    while (len(boot_stack) > 0):
        test_loop_body()

    gp.qprint_timen("Finished processing stack.")

    post_stack()

    # Process caller's boot_list.
    if len(boot_list) > 0:
        for ix in range(1, max_num_tests + 1):
            test_loop_body()

    gp.qprint_timen("Completed all requested boot tests.")

    boot_pass, boot_fail = boot_results.return_total_pass_fail()
    new_fail = boot_fail - init_boot_fail
    if new_fail > boot_fail_threshold:
        error_message = "Boot failures exceed the boot failure" +\
                        " threshold:\n" +\
                        gp.sprint_var(new_fail) +\
                        gp.sprint_var(boot_fail_threshold)
        BuiltIn().fail(gp.sprint_error(error_message))
