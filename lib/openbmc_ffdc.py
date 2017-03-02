#!/usr/bin/env python

r"""
This module is the python counterpart to openbmc_ffdc.robot..
"""

import os

import gen_robot_print as grp
import gen_valid as gv

from robot.libraries.BuiltIn import BuiltIn


###############################################################################
def ffdc(ffdc_dir_path=None,
         ffdc_prefix=None):

    r"""
    Gather First Failure Data Capture (FFDC).

    This includes:
    - Set global FFDC_TIME.
    - Create FFDC work space directory.
    - Write test info details.
    - Call BMC methods to write/collect FFDC data.

    Description of arguments:
    ffdc_dir_path  The dir path where FFDC data should be put.
    ffdc_prefix    The prefix to be given to each FFDC file name generated.
    """

    # Check if Ping and SSH connection is alive
    OPENBMC_HOST = BuiltIn().get_variable_value("${OPENBMC_HOST}")
    cmd_buf = ["Ping Host", OPENBMC_HOST]
    grp.rpissuing_keyword(cmd_buf)
    status_ping = BuiltIn().run_keyword_and_return_status(*cmd_buf)
    grp.rprint_var(status_ping)
    if status_ping == True:
        status_ssh = \
          BuiltIn().run_keyword_and_return_status("Open Connection And Log In")
        grp.rprint_var(status_ssh)
        if status_ssh != True:
            grp.rprint_error("BMC is not communicating. \
                              Aborting FFDC collection.\n")
            BuiltIn().run_keyword_and_return_status("Close All Connections")
            return

    grp.rprint_timen("Collecting FFDC.")

    # Note: Several subordinate functions like 'Get Test Dir and Name' and
    # 'Header Message' expect global variable FFDC_TIME to be set.
    cmd_buf = ["Get Current Time Stamp"]
    grp.rdpissuing_keyword(cmd_buf)
    FFDC_TIME = BuiltIn().run_keyword(*cmd_buf)
    BuiltIn().set_global_variable("${FFDC_TIME}", FFDC_TIME)

    # Get default values for arguments.
    ffdc_dir_path, ffdc_prefix = set_ffdc_defaults(ffdc_dir_path, ffdc_prefix)
    grp.rprint_var(ffdc_dir_path)
    grp.rprint_var(ffdc_prefix)

    # LOG_PREFIX is used by subordinate functions.
    LOG_PREFIX = ffdc_dir_path + ffdc_prefix
    BuiltIn().set_global_variable("${LOG_PREFIX}", LOG_PREFIX)

    cmd_buf = ["Create Directory", ffdc_dir_path]
    grp.rpissuing_keyword(cmd_buf)
    status, output = BuiltIn().run_keyword_and_ignore_error(*cmd_buf)
    if status != "PASS":
        error_message = grp.sprint_error_report("Create Directory failed" +
                                                " with the following" +
                                                " error:\n" + output)
        BuiltIn().fail(error_message)

    # FFDC_FILE_PATH is used by Header Message.
    FFDC_FILE_PATH = ffdc_dir_path + ffdc_prefix + "BMC_general.txt"
    BuiltIn().set_global_variable("${FFDC_FILE_PATH}", FFDC_FILE_PATH)

    cmd_buf = ["Header Message"]
    grp.rpissuing_keyword(cmd_buf)
    BuiltIn().run_keyword(*cmd_buf)

    cmd_buf = ["Call FFDC Methods"]
    grp.rpissuing_keyword(cmd_buf)
    BuiltIn().run_keyword(*cmd_buf)

    grp.rprint_timen("Finished collecting FFDC.")

###############################################################################


###############################################################################
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
            FFDC_LOG_PATH = BuiltIn().get_variable_value("${FFDC_LOG_PATH}")
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

    return ffdc_dir_path, ffdc_prefix

###############################################################################
