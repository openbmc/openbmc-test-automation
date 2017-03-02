#!/usr/bin/env python

r"""
This module is the python counterpart to obmc_boot_test.
"""

import os
import imp
import time
import glob
import random
import cPickle as pickle

from robot.utils import DotDict
from robot.libraries.BuiltIn import BuiltIn

from boot_data import *
import gen_robot_print as grp
import gen_robot_plug_in as grpi
import gen_robot_valid as grv
import gen_misc as gm
import gen_cmd as gc
import state as st

base_path = os.path.dirname(os.path.dirname(
                            imp.find_module("gen_robot_print")[1])) + os.sep
sys.path.append(base_path + "extended/")
import run_keyword as rk

# Program parameter processing.
# Assign all program parms to python variables which are global to this module.
parm_list = BuiltIn().get_variable_value("${parm_list}")
int_list = ['max_num_tests', 'boot_pass', 'boot_fail', 'quiet', 'test_mode',
            'debug']
for parm in parm_list:
    if parm in int_list:
        sub_cmd = "int(BuiltIn().get_variable_value(\"${" + parm +\
                  "}\", \"0\"))"
    else:
        sub_cmd = "BuiltIn().get_variable_value(\"${" + parm + "}\")"
    cmd_buf = parm + " = " + sub_cmd
    exec(cmd_buf)

if ffdc_dir_path_style == "":
    ffdc_dir_path_style = int(os.environ.get('FFDC_DIR_PATH_STYLE', '0'))

# Set up boot data structures.
boot_table = create_boot_table()
valid_boot_types = create_valid_boot_list(boot_table)

boot_results_file_path = "/tmp/" + openbmc_nickname + "_boot_results"
if (boot_pass > 0 or boot_fail > 0) and \
   os.path.isfile(boot_results_file_path):
    # We've been called before in this run so we'll load the saved
    # boot_results object.
    boot_results = pickle.load(open(boot_results_file_path, 'rb'))
else:
    boot_results = boot_results(boot_table, boot_pass, boot_fail)

boot_lists = read_boot_lists()
last_ten = []
# Convert these program parms to more useable lists.
boot_list = filter(None, boot_list.split(":"))
boot_stack = filter(None, boot_stack.split(":"))

state = st.return_default_state()
cp_setup_called = 0
next_boot = ""
base_tool_dir_path = os.path.normpath(os.environ.get(
    'AUTOBOOT_BASE_TOOL_DIR_PATH', "/tmp")) + os.sep
ffdc_dir_path = os.path.normpath(os.environ.get('FFDC_DIR_PATH', '')) + os.sep
ffdc_list_file_path = base_tool_dir_path + openbmc_nickname + "/FFDC_FILE_LIST"
boot_success = 0
# Setting master_pid correctly influences the behavior of plug-ins like
# DB_Logging
program_pid = os.getpid()
master_pid = os.environ.get('AUTOBOOT_MASTER_PID', program_pid)
status_dir_path = os.environ.get('STATUS_DIR_PATH', "")
if status_dir_path != "":
    status_dir_path = os.path.normpath(status_dir_path) + os.sep
default_power_on = "BMC Power On"
default_power_off = "BMC Power Off"
boot_count = 0


###############################################################################
def plug_in_setup():

    r"""
    Initialize all plug-in environment variables for use by the plug-in
    programs.
    """

    boot_pass, boot_fail = boot_results.return_total_pass_fail()
    if boot_pass > 1:
        test_really_running = 1
    else:
        test_really_running = 0

    seconds = time.time()
    loc_time = time.localtime(seconds)
    time_string = time.strftime("%y%m%d.%H%M%S.", loc_time)

    ffdc_prefix = openbmc_nickname + "." + time_string

    BuiltIn().set_global_variable("${test_really_running}",
                                  test_really_running)
    BuiltIn().set_global_variable("${boot_type_desc}", next_boot)
    BuiltIn().set_global_variable("${master_pid}", master_pid)
    BuiltIn().set_global_variable("${FFDC_DIR_PATH}", ffdc_dir_path)
    BuiltIn().set_global_variable("${STATUS_DIR_PATH}", status_dir_path)
    BuiltIn().set_global_variable("${BASE_TOOL_DIR_PATH}", base_tool_dir_path)
    BuiltIn().set_global_variable("${FFDC_LIST_FILE_PATH}",
                                  ffdc_list_file_path)
    BuiltIn().set_global_variable("${FFDC_DIR_PATH_STYLE}",
                                  ffdc_dir_path_style)
    BuiltIn().set_global_variable("${FFDC_CHECK}",
                                  ffdc_check)
    BuiltIn().set_global_variable("${boot_pass}", boot_pass)
    BuiltIn().set_global_variable("${boot_fail}", boot_fail)
    BuiltIn().set_global_variable("${boot_success}", boot_success)
    BuiltIn().set_global_variable("${ffdc_prefix}", ffdc_prefix)

    # For each program parameter, set the corresponding AUTOBOOT_ environment
    # variable value.  Also, set an AUTOBOOT_ environment variable for every
    # element in additional_values.
    additional_values = ["boot_type_desc", "boot_success", "boot_pass",
                         "boot_fail", "test_really_running", "program_pid",
                         "master_pid", "ffdc_prefix", "ffdc_dir_path",
                         "status_dir_path", "base_tool_dir_path",
                         "ffdc_list_file_path"]

    plug_in_vars = parm_list + additional_values

    for var_name in plug_in_vars:
        var_value = BuiltIn().get_variable_value("${" + var_name + "}")
        var_name = var_name.upper()
        if var_value is None:
            var_value = ""
        os.environ["AUTOBOOT_" + var_name] = str(var_value)

    if debug:
        shell_rc, out_buf = \
            gc.cmd_fnc_u("printenv | egrep AUTOBOOT_ | sort -u")

###############################################################################


###############################################################################
def setup():

    r"""
    Do general program setup tasks.
    """

    global cp_setup_called

    grp.rqprintn()

    validate_parms()

    grp.rqprint_pgm_header()

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

    grp.rdprint_var(boot_table, 1)
    grp.rdprint_var(boot_lists)

###############################################################################


###############################################################################
def validate_parms():

    r"""
    Validate all program parameters.
    """

    grp.rqprintn()

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
    grv.rvalid_integer("max_num_tests")
    grv.rvalid_value("openbmc_model")
    grv.rvalid_integer("boot_pass")
    grv.rvalid_integer("boot_fail")

    plug_in_packages_list = grpi.rvalidate_plug_ins(plug_in_dir_paths)
    BuiltIn().set_global_variable("${plug_in_packages_list}",
                                  plug_in_packages_list)

    if len(boot_list) == 0 and len(boot_stack) == 0:
        error_message = "You must provide either a value for either the" +\
            " boot_list or the boot_stack parm.\n"
        BuiltIn().fail(gp.sprint_error(error_message))

    valid_boot_list(boot_list, valid_boot_types)
    valid_boot_list(boot_stack, valid_boot_types)

    return

###############################################################################


###############################################################################
def my_get_state():

    r"""
    Get the system state plus a little bit of wrapping.
    """

    global state

    req_states = ['epoch_seconds'] + st.default_req_states

    grp.rqprint_timen("Getting system state.")
    if test_mode:
        state['epoch_seconds'] = int(time.time())
    else:
        state = st.get_state(req_states=req_states, quiet=0)
    grp.rprint_var(state)

###############################################################################


###############################################################################
def select_boot():

    r"""
    Select a boot test to be run based on our current state and return the
    chosen boot type.

    Description of arguments:
    state  The state of the machine.
    """

    global boot_stack

    grp.rprint_timen("Selecting a boot test.")

    my_get_state()

    stack_popped = 0
    if len(boot_stack) > 0:
        stack_popped = 1
        grp.rprint_dashes()
        grp.rprint_var(boot_stack)
        grp.rprint_dashes()
        boot_candidate = boot_stack.pop()
        if st.compare_states(state, boot_table[boot_candidate]['start']):
            grp.rprint_timen("The machine state is valid for a '" +
                             boot_candidate + "' boot test.")
            grp.rprint_dashes()
            grp.rprint_var(boot_stack)
            grp.rprint_dashes()
            return boot_candidate
        else:
            grp.rprint_timen("The machine state is not valid for a '" +
                             boot_candidate + "' boot test.")
            boot_stack.append(boot_candidate)
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
        grp.rprint_timen("The user's boot list contained no boot tests" +
                         " which are valid for the current machine state.")
        boot_candidate = default_power_on
        if not st.compare_states(state, boot_table[default_power_on]['start']):
            boot_candidate = default_power_off
        boot_candidates.append(boot_candidate)
        grp.rprint_timen("Using default '" + boot_candidate +
                         "' boot type to transtion to valid state.")

    grp.rdprint_var(boot_candidates)

    # Randomly select a boot from the candidate list.
    boot = random.choice(boot_candidates)

    return boot

###############################################################################


###############################################################################
def print_last_boots():

    r"""
    Print the last ten boots done with their time stamps.
    """

    # indent 0, 90 chars wide, linefeed, char is "="
    grp.rqprint_dashes(0, 90)
    grp.rqprintn("Last 10 boots:\n")

    for boot_entry in last_ten:
        grp.rqprint(boot_entry)
    grp.rqprint_dashes(0, 90)

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

    grp.rqpvars(*parm_list)

    grp.rqprintn()

    print_last_boots()
    grp.rqprintn()
    grp.rqpvar(state)

    # At some point I'd like to have the 'Call FFDC Methods' return a list
    # of files it has collected.  In that case, the following "ls" command
    # would no longer be needed.  For now, however, glob shows the files
    # named in FFDC_LIST_FILE_PATH so I will refrain from printing those
    # out (so we don't see duplicates in the list).

    LOG_PREFIX = BuiltIn().get_variable_value("${LOG_PREFIX}")

    output = '\n'.join(glob.glob(LOG_PREFIX + '*'))
    try:
        ffdc_list = open(ffdc_list_file_path, 'r')
    except IOError:
        ffdc_list = ""

    grp.rqprintn()
    grp.rqprintn("FFDC data files:")
    if status_file_path != "":
        grp.rqprintn(status_file_path)

    grp.rqprintn(output)
    # grp.rqprintn(ffdc_list)
    grp.rqprintn()

    grp.rqprint_dashes(0, 90, 1, "=")

###############################################################################


###############################################################################
def my_ffdc():

    r"""
    Collect FFDC data.
    """

    global state

    plug_in_setup()
    rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
        call_point='ffdc', stop_on_plug_in_failure=1)

    AUTOBOOT_FFDC_PREFIX = os.environ['AUTOBOOT_FFDC_PREFIX']

    # FFDC_LOG_PATH is used by "FFDC" keyword.
    BuiltIn().set_global_variable("${FFDC_LOG_PATH}", ffdc_dir_path)

    cmd_buf = ["FFDC", "ffdc_prefix=" + AUTOBOOT_FFDC_PREFIX]
    grp.rpissuing_keyword(cmd_buf)
    BuiltIn().run_keyword(*cmd_buf)

    my_get_state()

    print_defect_report()

###############################################################################


###############################################################################
def print_test_start_message(boot_keyword):

    r"""
    Print a message indicating what boot test is about to run.

    Description of arguments:
    boot_keyword  The name of the boot which is to be run
                  (e.g. "BMC Power On").
    """

    global last_ten

    doing_msg = gp.sprint_timen("Doing \"" + boot_keyword + "\".")
    grp.rqprint(doing_msg)

    last_ten.append(doing_msg)

    if len(last_ten) > 10:
        del last_ten[0]

###############################################################################


###############################################################################
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

        grp.rprintn()

        if boot_table[boot]['method_type'] == "keyword":
            rk.my_run_keywords(boot_table[boot].get('lib_file_path', ''),
                               boot_table[boot]['method'])

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
                          interval="3 seconds", invert=1)

        grp.rprintn()
        if boot_table[boot]['end']['chassis'] == "Off":
            boot_timeout = power_off_timeout
        else:
            boot_timeout = power_on_timeout
        st.wait_state(boot_table[boot]['end'], wait_time=boot_timeout,
                      interval="3 seconds")

    plug_in_setup()
    rc, shell_rc, failed_plug_in_name = \
        grpi.rprocess_plug_in_packages(call_point="post_boot")
    if rc != 0:
        error_message = "Plug-in failed with non-zero return code.\n" +\
            gp.sprint_var(rc, 1)
        BuiltIn().fail(gp.sprint_error(error_message))

###############################################################################


###############################################################################
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

    grp.rqprintn()

    boot_count += 1

    next_boot = select_boot()

    grp.rqprint_timen("Starting boot " + str(boot_count) + ".")

    # Clear the ffdc_list_file_path file.  Plug-ins may now write to it.
    try:
        os.remove(ffdc_list_file_path)
    except OSError:
        pass

    cmd_buf = ["run_boot", next_boot]
    boot_status, msg = BuiltIn().run_keyword_and_ignore_error(*cmd_buf)
    if boot_status == "FAIL":
        grp.rprint(msg)

    grp.rqprintn()
    if boot_status == "PASS":
        boot_success = 1
        grp.rqprint_timen("BOOT_SUCCESS: \"" + next_boot + "\" succeeded.")
    else:
        boot_success = 0
        grp.rqprint_timen("BOOT_FAILED: \"" + next_boot + "\" failed.")

    boot_results.update(next_boot, boot_status)

    plug_in_setup()
    # NOTE: A post_test_case call point failure is NOT counted as a boot
    # failure.
    rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
        call_point='post_test_case', stop_on_plug_in_failure=1)

    plug_in_setup()
    rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
        call_point='ffdc_check', shell_rc=0x00000200,
        stop_on_plug_in_failure=1, stop_on_non_zero_rc=1)
    if boot_status != "PASS" or ffdc_check == "All" or shell_rc == 0x00000200:
        cmd_buf = ["my_ffdc"]
        grp.rpissuing_keyword(cmd_buf)
        BuiltIn().run_keyword_and_continue_on_failure(*cmd_buf)

    plug_in_setup()
    rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
        call_point='stop_check')
    if rc != 0:
        error_message = "Stopping as requested by user.\n"
        grp.rprint_error_report(error_message)
        BuiltIn().fail(error_message)

    boot_results.print_report()
    grp.rqprint_timen("Finished boot " + str(boot_count) + ".")

    return True

###############################################################################


###############################################################################
def program_teardown():

    r"""
    Clean up after this program.
    """

    if cp_setup_called:
        plug_in_setup()
        rc, shell_rc, failed_plug_in_name = grpi.rprocess_plug_in_packages(
            call_point='cleanup', stop_on_plug_in_failure=1)

    # Save boot_results object to a file in case it is needed again.
    grp.rprint_timen("Saving boot_results to the following path.")
    grp.rprint_var(boot_results_file_path)
    pickle.dump(boot_results, open(boot_results_file_path, 'wb'),
                pickle.HIGHEST_PROTOCOL)

###############################################################################


###############################################################################
def main_py():

    r"""
    Do main program processing.
    """

    setup()

    # Process caller's boot_stack.
    while (len(boot_stack) > 0):
        test_loop_body()

    grp.rprint_timen("Finished processing stack.")

    # Process caller's boot_list.
    if len(boot_list) > 0:
        for ix in range(1, max_num_tests + 1):
            test_loop_body()

    grp.rqprint_timen("Completed all requested boot tests.")

###############################################################################
