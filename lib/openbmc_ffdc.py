#!/usr/bin/env python

r"""
This module is the python counterpart to openbmc_ffdc.robot..
"""

import os

import gen_print as gp
import gen_robot_print as grp
import gen_valid as gv
import gen_robot_keyword as grk
import state as st

from robot.libraries.BuiltIn import BuiltIn


def ffdc(ffdc_dir_path=None,
         ffdc_prefix=None,
         ffdc_function_list=""):
    r"""
    Gather First Failure Data Capture (FFDC).

    This includes:
    - Set global FFDC_TIME.
    - Create FFDC work space directory.
    - Write test info details.
    - Call BMC methods to write/collect FFDC data.

    Description of arguments:
    ffdc_dir_path       The dir path where FFDC data should be put.
    ffdc_prefix         The prefix to be given to each FFDC file name
                        generated.
    ffdc_function_list  A colon-delimited list of all the types of FFDC data
                        you wish to have collected.  A blank value means that
                        all possible kinds of FFDC are to be collected.  See
                        FFDC_METHOD_CALL object in lib/openbmc_ffdc_list.py
                        for possible choices.
    """

    ffdc_file_list = []

    # Check if Ping and SSH connection is alive
    OPENBMC_HOST = BuiltIn().get_variable_value("${OPENBMC_HOST}")

    state = st.get_state(req_states=['ping', 'uptime'])
    gp.qprint_var(state)
    if not int(state['ping']):
        gp.print_error("BMC is not ping-able.  Terminating FFDC collection.\n")
        return ffdc_file_list

    if state['uptime'] == "":
        gp.print_error("BMC is not communicating.  Terminating FFDC" +
                       " collection.\n")
        return ffdc_file_list

    gp.qprint_timen("Collecting FFDC.")

    # Get default values for arguments.
    ffdc_dir_path, ffdc_prefix = set_ffdc_defaults(ffdc_dir_path, ffdc_prefix)
    gp.qprint_var(ffdc_dir_path)
    gp.qprint_var(ffdc_prefix)

    # LOG_PREFIX is used by subordinate functions.
    LOG_PREFIX = ffdc_dir_path + ffdc_prefix
    BuiltIn().set_global_variable("${LOG_PREFIX}", LOG_PREFIX)

    cmd_buf = ["Create Directory", ffdc_dir_path]
    grp.rqpissuing_keyword(cmd_buf)
    status, output = BuiltIn().run_keyword_and_ignore_error(*cmd_buf)
    if status != "PASS":
        error_message = grp.sprint_error_report("Create Directory failed" +
                                                " with the following" +
                                                " error:\n" + output)
        BuiltIn().fail(error_message)

    # FFDC_FILE_PATH is used by Header Message.
    FFDC_FILE_PATH = ffdc_dir_path + ffdc_prefix + "BMC_general.txt"
    BuiltIn().set_global_variable("${FFDC_FILE_PATH}", FFDC_FILE_PATH)

    status, ffdc_file_list = grk.run_key("Header Message")
    status, ffdc_file_sub_list = \
        grk.run_key_u("Call FFDC Methods  ffdc_function_list=" +
                      ffdc_function_list)

    # Combine lists, remove duplicates and sort.
    ffdc_file_list = list(set(ffdc_file_list + ffdc_file_sub_list))
    ffdc_file_list.sort()

    gp.qprint_timen("Finished collecting FFDC.")

    return ffdc_file_list


def set_ffdc_defaults(ffdc_dir_path=None,
                      ffdc_prefix=None):
    r"""
    Set a default value for ffdc_dir_path and ffdc_prefix if they don't
    already have values.  Return both values.

    Description of arguments:
    ffdc_dir_path  The dir path where FFDC data should be put.
    ffdc_prefix    The prefix to be given to each FFDC file name generated.

    NOTE: If global variable ffdc_dir_path_style is set to ${1}, this function
    will create default values in a newer way.  Otherwise, its behavior
    will remain unchanged.
    """

    # Note: Several subordinate functions like 'Get Test Dir and Name' and
    # 'Header Message' expect global variable FFDC_TIME to be set.
    cmd_buf = ["Get Current Time Stamp"]
    grp.rdpissuing_keyword(cmd_buf)
    FFDC_TIME = BuiltIn().run_keyword(*cmd_buf)
    BuiltIn().set_global_variable("${FFDC_TIME}", FFDC_TIME)

    ffdc_dir_path_style = BuiltIn().get_variable_value(
        "${ffdc_dir_path_style}")

    if ffdc_dir_path is None:
        if ffdc_dir_path_style:
            try:
                ffdc_dir_path = os.environ['FFDC_DIR_PATH']
            except KeyError:
                ffdc_dir_path = os.path.dirname(
                    BuiltIn().get_variable_value("${LOG_FILE}")) + "/"
        else:
            FFDC_LOG_PATH = os.getcwd() + "/logs/"
            if FFDC_LOG_PATH is None:
                FFDC_LOG_PATH = ""
            if FFDC_LOG_PATH == "":
                FFDC_LOG_PATH = os.path.dirname(
                    BuiltIn().get_variable_value("${LOG_FILE}")) + "/"
            error_message = gv.svalid_value(FFDC_LOG_PATH,
                                            var_name="FFDC_LOG_PATH")
            if error_message != "":
                error_message = grp.sprint_error_report(error_message)
                BuiltIn().fail(error_message)
            FFDC_LOG_PATH = os.path.normpath(FFDC_LOG_PATH) + os.sep

            cmd_buf = ["Get Test Dir and Name"]
            grp.rpissuing_keyword(cmd_buf)
            suitename, testname = BuiltIn().run_keyword(*cmd_buf)

            ffdc_dir_path = FFDC_LOG_PATH + suitename + "/" + testname + "/"

    # Add trailing slash.
    ffdc_dir_path = os.path.normpath(ffdc_dir_path) + os.sep

    if ffdc_prefix is None:
        FFDC_TIME = BuiltIn().get_variable_value("${FFDC_TIME}")
        if ffdc_prefix is None:
            if ffdc_dir_path_style:
                OPENBMC_HOST = BuiltIn().get_variable_value("${OPENBMC_HOST}")
                OPENBMC_NICKNAME = BuiltIn().get_variable_value(
                    "${OPENBMC_NICKNAME}", default=OPENBMC_HOST)
                ffdc_prefix = OPENBMC_NICKNAME + "." + FFDC_TIME[2:8] + "." +\
                    FFDC_TIME[8:14] + "."
            else:
                ffdc_prefix = FFDC_TIME + "_"

    BuiltIn().set_global_variable("${FFDC_DIR_PATH}", ffdc_dir_path)
    BuiltIn().set_global_variable("${FFDC_PREFIX}", ffdc_prefix)

    return ffdc_dir_path, ffdc_prefix
