#!/usr/bin/env python

r"""
This module provides functions which are useful for running plug-ins from a
robot program.
"""

import sys
import subprocess
from robot.libraries.BuiltIn import BuiltIn
import commands
import os
import tempfile

import gen_print as gp
import gen_robot_print as grp
import gen_misc as gm


###############################################################################
def rvalidate_plug_ins(plug_in_dir_paths,
                       quiet=1):

    r"""
    Call the external validate_plug_ins.py program which validates the plug-in
    dir paths given to it.  Return a list containing a normalized path for
    each plug-in selected.

    Description of arguments:
    plug_in_dir_paths               A colon-separated list of plug-in
                                    directory paths.
    quiet                           If quiet is set to 1, this function will
                                    NOT write status messages to stdout.
    """

    cmd_buf = "validate_plug_ins.py \"" + plug_in_dir_paths + "\""
    if int(quiet) != 1:
        grp.rpissuing(cmd_buf)
    rc, out_buf = commands.getstatusoutput(cmd_buf)
    if rc != 0:
        message = gp.sprint_varx("rc", rc, 1) + out_buf
        grp.rprintn(out_buf, 'STDERR')
        BuiltIn().fail("Validate plug ins call failed.  See stderr text for" +
                       " details.\n")

    plug_in_packages_list = out_buf.split("\n")
    if len(plug_in_packages_list) == 1 and plug_in_packages_list[0] == "":
        return []

    return plug_in_packages_list

###############################################################################


###############################################################################
def rprocess_plug_in_packages(plug_in_packages_list=None,
                              call_point="setup",
                              shell_rc="0x00000000",
                              stop_on_plug_in_failure=1,
                              stop_on_non_zero_rc=0,
                              release_type="obmc",
                              quiet=None,
                              debug=None):

    r"""
    Call the external process_plug_in_packages.py to process the plug-in
    packages.  Return the following:
    rc                              The return code - 0 = PASS, 1 = FAIL.
    shell_rc                        The shell return code returned by
                                    process_plug_in_packages.py.
    failed_plug_in_name             The failed plug in name (if any).

    Description of arguments:
    plug_in_packages_list           A python list of plug-in directory paths.
    shell_rc                        The user may supply a value other than
                                    zero to indicate an acceptable non-zero
                                    return code.  For example, if this value
                                    equals 0x00000200, it means that for each
                                    plug-in call point that runs, a 0x00000200
                                    will not be counted as a failure.
    stop_on_plug_in_failure         If this parameter is set to 1, this
                                    program will stop and return non-zero if
                                    the call point program from any plug-in
                                    directory fails.  Conversely, if it is set
                                    to false, this program will run the call
                                    point program from each and every plug-in
                                    directory regardless of their return
                                    values.  Typical example cases where you'd
                                    want to run all plug-in call points
                                    regardless of success or failure would be
                                    "cleanup" or "ffdc" call points.
    stop_on_non_zero_rc             If this parm is set to 1 and a plug-in
                                    call point program returns a valid
                                    non-zero return code (see "shell_rc" parm
                                    above), this program will stop processing
                                    and return 0 (success).  Since this
                                    constitutes a successful exit, this would
                                    normally be used where the caller wishes
                                    to stop processing if one of the plug-in
                                    directory call point programs returns a
                                    special value indicating that some special
                                    case has been found.  An example might be
                                    in calling some kind of "check_errl" call
                                    point program.  Such a call point program
                                    might return a 2 (i.e. 0x00000200) to
                                    indicate that a given error log entry was
                                    found in an "ignore" list and is therefore
                                    to be ignored.  That being the case, no
                                    other "check_errl" call point program
                                    would need to be called.
    quiet                           If quiet is set to 1, this function will
                                    NOT write status messages to stdout.  This
                                    will default to the global quiet program
                                    parm or to 0.
    debug                           If this parameter is set to 1, this
                                    function will print additional debug
                                    information.  This is mainly to be used by
                                    the developer of this function.  This will
                                    default to the global quiet program parm
                                    or to 0.
    """

    rc = 0

    if plug_in_packages_list is None:
        plug_in_packages_list = BuiltIn().get_variable_value(
                                "${plug_in_packages_list}")

    # If there are no plug-in packages to process, return successfully.
    if len(plug_in_packages_list) == 0:
        return 0, 0, ""

    if quiet is None:
        try:
            quiet = int(BuiltIn().get_variable_value("${quiet}"))
        except TypeError:
            quiet = 0

    if debug is None:
        try:
            debug = int(BuiltIn().get_variable_value("${debug}"))
        except TypeError:
            debug = 0

    # Create string from list.
    plug_in_dir_paths = ':'.join(plug_in_packages_list)

    temp = tempfile.NamedTemporaryFile()
    temp_file_path = temp.name
    temp2 = tempfile.NamedTemporaryFile()
    temp_properties_file_path = temp2.name

    if int(debug) == 1:
        os.environ["PERF_TRACE"] = "1"
        debug_string = " --quiet=0"
    else:
        debug_string = ""

    loc_shell_rc = 0

    sub_cmd_buf = "process_plug_in_packages.py" + debug_string +\
                  " --call_point=" + call_point + " --shell_rc=" +\
                  str(shell_rc) + " --stop_on_plug_in_failure=" +\
                  str(stop_on_plug_in_failure) + " --stop_on_non_zero_rc=" +\
                  str(stop_on_non_zero_rc) + " " + plug_in_dir_paths
    if int(quiet) == 1:
        cmd_buf = sub_cmd_buf + " > " + temp_file_path + " 2>&1"
    else:
        cmd_buf = "my_tee" + debug_string + " " + temp_file_path + " -c '" +\
                  sub_cmd_buf + "'"
        if int(debug) == 1:
            grp.rpissuing(cmd_buf)

    ppc_rc = subprocess.call(cmd_buf, shell=True)

    cmd_buf = "egrep '^[ ]*[^:]+:[ ]*' " + temp_file_path + " > " +\
              temp_properties_file_path
    if int(debug) == 1:
        grp.rpissuing(cmd_buf)
    rc = os.system(cmd_buf)

    properties = gm.my_parm_file(temp_properties_file_path)

    try:
        shell_rc = properties['shell_rc']
    except KeyError:
        shell_rc = 0
    try:
        failed_plug_in_name = properties['failed_plug_in_name']
    except KeyError:
        failed_plug_in_name = ""

    if rc != 0 or ppc_rc != 0:
        grp.rprint_error("Call to process_plug_in_packages failed.\n")
        grp.rprint_varx("rc", rc)
        grp.rprint_varx("ppc_rc", ppc_rc)
        grp.rprint_varx("shell_rc", shell_rc)
        grp.rprint_varx("failed_plug_in_name", failed_plug_in_name)

    return rc, shell_rc, failed_plug_in_name

###############################################################################
