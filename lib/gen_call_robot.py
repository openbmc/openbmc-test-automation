#!/usr/bin/env python3

r"""
This module provides functions which are useful to plug-ins call-point programs that wish to make external
robot program calls.
"""

import importlib.util
import os
import re
import subprocess
import sys
import time

import gen_cmd as gc
import gen_misc as gm
import gen_print as gp
import gen_valid as gv

base_path = (
    os.path.dirname(
        os.path.dirname(importlib.util.find_spec("gen_robot_print").origin)
    )
    + os.sep
)


def init_robot_out_parms(extra_prefix=""):
    r"""
    Initialize robot output parms such as outputdir, output, etc.

    This function will set global values for the following robot output parms.

    outputdir, output, log, report, loglevel, consolecolors, consolemarkers

    This function would typically be called prior to calling create_robot_cmd_string.

    Description of argument(s):
    extra_prefix                    An extra prefix to be appended to the default prefix for output file
                                    names.
    """

    gp.dprint_executing()
    AUTOBOOT_OPENBMC_NICKNAME = gm.get_mod_global("AUTOBOOT_OPENBMC_NICKNAME")

    # Set values for call to create_robot_cmd_string.
    # Environment variable TMP_ROBOT_DIR_PATH can be set by the user to indicate that robot-generated output
    # should initially be written to the specified temporary directory and then moved to the normal output
    # location after completion.
    outputdir = os.environ.get(
        "TMP_ROBOT_DIR_PATH",
        os.environ.get(
            "STATUS_DIR_PATH", os.environ.get("HOME", ".") + "/status"
        ),
    )
    outputdir = gm.add_trailing_slash(outputdir)
    seconds = time.time()
    loc_time = time.localtime(seconds)
    time_string = time.strftime("%y%m%d.%H%M%S", loc_time)
    file_prefix = (
        AUTOBOOT_OPENBMC_NICKNAME + "." + extra_prefix + time_string + "."
    )
    # Environment variable SAVE_STATUS_POLICY governs when robot-generated output files (e.g. the log.html)
    # will be moved from TMP_ROBOT_DIR_PATH to FFDC_DIR_PATH.  Valid values are "ALWAYS", "NEVER" and "FAIL".
    SAVE_STATUS_POLICY = os.environ.get("SAVE_STATUS_POLICY", "ALWAYS")
    if SAVE_STATUS_POLICY == "NEVER":
        output = "NONE"
        log = "NONE"
        report = "NONE"
    else:
        output = file_prefix + "output.xml"
        log = file_prefix + "log.html"
        report = file_prefix + "report.html"
    loglevel = "TRACE"
    consolecolors = "off"
    consolemarkers = "off"

    # Make create_robot_cmd_string values global.
    gm.set_mod_global(outputdir)
    gm.set_mod_global(output)
    gm.set_mod_global(log)
    gm.set_mod_global(report)
    gm.set_mod_global(loglevel)
    gm.set_mod_global(consolecolors)
    gm.set_mod_global(consolemarkers)

    return (
        outputdir,
        output,
        log,
        report,
        loglevel,
        consolecolors,
        consolemarkers,
    )


def init_robot_test_base_dir_path():
    r"""
    Initialize and validate the environment variable, ROBOT_TEST_BASE_DIR_PATH and set corresponding global
    variable ROBOT_TEST_RUNNING_FROM_SB.

    If ROBOT_TEST_BASE_DIR_PATH is already set, this function will merely validate it.  This function will
    also set environment variable ROBOT_TEST_RUNNING_FROM_SB when ROBOT_TEST_BASE_DIR_PATH is not pre-set.
    """

    # ROBOT_TEST_BASE_DIR_PATH will be set as follows:
    # This function will determine whether we are running in a user sandbox or from a standard apolloxxx
    # environment.
    # - User sandbox:
    # If there is a <developer's home dir>/git/openbmc-test-automation/, ROBOT_TEST_BASE_DIR_PATH will be
    # set to that path.  Otherwise, we set it to <program dir path>/git/openbmc-test-automation/
    # - Not in user sandbox:
    #   ROBOT_TEST_BASE_DIR_PATH will be set to <program dir path>/git/openbmc-test-automation/

    ROBOT_TEST_BASE_DIR_PATH = os.environ.get("ROBOT_TEST_BASE_DIR_PATH", "")
    ROBOT_TEST_RUNNING_FROM_SB = int(
        os.environ.get("ROBOT_TEST_RUNNING_FROM_SB", "0")
    )
    if ROBOT_TEST_BASE_DIR_PATH == "":
        # ROBOT_TEST_BASE_DIR_PATH was not set by user/caller.
        AUTOIPL_VERSION = os.environ.get("AUTOIPL_VERSION", "")
        if AUTOIPL_VERSION == "":
            ROBOT_TEST_BASE_DIR_PATH = base_path
        else:
            suffix = "git/openbmc-test-automation/"

            # Determine whether we're running out of a developer sandbox or simply out of an apolloxxx/bin
            # path.
            shell_rc, out_buf = gc.shell_cmd(
                "dirname $(which gen_print.py)",
                quiet=(not debug),
                print_output=0,
            )
            executable_base_dir_path = os.path.realpath(out_buf.rstrip()) + "/"
            apollo_dir_path = (
                os.environ["AUTO_BASE_PATH"] + AUTOIPL_VERSION + "/bin/"
            )
            developer_home_dir_path = re.sub(
                "/sandbox.*", "", executable_base_dir_path
            )
            developer_home_dir_path = gm.add_trailing_slash(
                developer_home_dir_path
            )
            gp.dprint_vars(
                executable_base_dir_path,
                developer_home_dir_path,
                apollo_dir_path,
            )

            ROBOT_TEST_RUNNING_FROM_SB = 0
            if executable_base_dir_path != apollo_dir_path:
                ROBOT_TEST_RUNNING_FROM_SB = 1
                gp.dprint_vars(ROBOT_TEST_RUNNING_FROM_SB)
                ROBOT_TEST_BASE_DIR_PATH = developer_home_dir_path + suffix
                if not os.path.isdir(ROBOT_TEST_BASE_DIR_PATH):
                    gp.dprint_timen(
                        "NOTE: Sandbox directory "
                        + ROBOT_TEST_BASE_DIR_PATH
                        + " does not"
                        + " exist."
                    )
                    # Fall back to the apollo dir path.
                    ROBOT_TEST_BASE_DIR_PATH = apollo_dir_path + suffix
            else:
                # Use to the apollo dir path.
                ROBOT_TEST_BASE_DIR_PATH = apollo_dir_path + suffix

    gv.valid_value(ROBOT_TEST_BASE_DIR_PATH)
    gp.dprint_vars(
        ROBOT_TEST_RUNNING_FROM_SB,
        ROBOT_TEST_BASE_DIR_PATH,
    )
    gv.valid_dir_path(ROBOT_TEST_BASE_DIR_PATH)

    ROBOT_TEST_BASE_DIR_PATH = gm.add_trailing_slash(ROBOT_TEST_BASE_DIR_PATH)
    gm.set_mod_global(ROBOT_TEST_BASE_DIR_PATH)
    os.environ["ROBOT_TEST_BASE_DIR_PATH"] = ROBOT_TEST_BASE_DIR_PATH

    gm.set_mod_global(ROBOT_TEST_RUNNING_FROM_SB)
    os.environ["ROBOT_TEST_RUNNING_FROM_SB"] = str(ROBOT_TEST_RUNNING_FROM_SB)


raw_robot_file_search_path = (
    "${ROBOT_TEST_BASE_DIR_PATH}:"
    + "${ROBOT_TEST_BASE_DIR_PATH}tests:${ROBOT_TEST_BASE_DIR_PATH}extended:"
    + "${ROBOT_TEST_BASE_DIR_PATH}scratch:${PATH}"
)


def init_robot_file_path(robot_file_path):
    r"""
    Determine full path name for the file path passed in robot_file_path and return it.

    If robot_file_path contains a fully qualified path name, this function will verify that the file exists.
    If robot_file_path contains a relative path, this function will search for the file and set
    robot_file_path so that it contains the absolute path to the robot file.  This function will search for
    the robot file using the raw_robot_file_search_path (defined above).  Note that if
    ROBOT_TEST_BASE_DIR_PATH is not set, this function will call init_robot_test_base_dir_path to set it.

    Description of arguments:
    robot_file_path                 The absolute or relative path to a robot file.
    """

    gv.valid_value(robot_file_path)

    try:
        if ROBOT_TEST_BASE_DIR_PATH is NONE:
            init_robot_test_base_dir_path()
    except NameError:
        init_robot_test_base_dir_path()

    if not re.match(r".*\.(robot|py)$", robot_file_path):
        # No suffix so we'll assign one of "\.robot".
        robot_file_path = robot_file_path + ".robot"

    abs_path = 0
    if robot_file_path[0:1] == "/":
        abs_path = 1

    gp.dprint_vars(abs_path, robot_file_path)

    if not abs_path:
        cmd_buf = 'echo -n "' + raw_robot_file_search_path + '"'
        shell_rc, out_buf = gc.shell_cmd(
            cmd_buf, quiet=(not debug), print_output=0
        )
        robot_file_search_paths = out_buf
        gp.dprint_var(robot_file_search_paths)
        robot_file_search_paths_list = robot_file_search_paths.split(":")
        for search_path in robot_file_search_paths_list:
            search_path = gm.add_trailing_slash(search_path)
            candidate_file_path = search_path + robot_file_path
            gp.dprint_var(candidate_file_path)
            if os.path.isfile(candidate_file_path):
                gp.dprint_timen("Found full path to " + robot_file_path + ".")
                robot_file_path = candidate_file_path
                break

    gp.dprint_var(robot_file_path)
    gv.valid_file_path(robot_file_path)

    return robot_file_path


def get_robot_parm_names():
    r"""
    Return a list containing all of the long parm names (e.g. --outputdir) supported by the robot program.
    Double dashes are not included in the names returned.
    """

    cmd_buf = (
        "robot -h | egrep "
        + "'^([ ]\\-[a-zA-Z0-9])?[ ]+--[a-zA-Z0-9]+[ ]+' | sed -re"
        + " s'/.*\\-\\-//g' -e s'/ .*//g' | sort -u"
    )
    shell_rc, out_buf = gc.shell_cmd(cmd_buf, quiet=1, print_output=0)

    return out_buf.split("\n")


def create_robot_cmd_string(robot_file_path, *parms):
    r"""
    Create a robot command string and return it.  On failure, return an empty string.

    Description of arguments:
    robot_file_path                 The path to the robot file to be run.
    parms                           The list of parms to be included in the command string.  The name of each
                                    variable in this list must be the same as the name of the corresponding
                                    parm.  This function figures out that name.  This function is also able
                                    to distinguish robot parms (e.g. --outputdir) from robot program parms
                                    (all other parms which will be passed as "-v PARM_NAME:parm_value")..

    Example:

    The following call to this function...
    cmd_buf = create_robot_cmd_string("tools/start_sol_console.robot", OPENBMC_HOST, quiet, test_mode, debug,
    outputdir, output, log, report)

    Would return a string something like this.
    robot -v OPENBMC_HOST:beye6 -v quiet:0 -v test_mode:1 -v debug:1
    --outputdir=/gsa/ausgsa/projects/a/status --output=beye6.OS_Console.output.xml
    --log=beye6.OS_Console.log.html --report=beye6.OS_Console.report.html tools/start_sol_console.robot
    """

    robot_file_path = init_robot_file_path(robot_file_path)

    robot_parm_names = get_robot_parm_names()

    robot_parm_list = []

    stack_frame = 2
    ix = 2
    for arg in parms:
        parm = arg
        parm = gm.quote_bash_parm(gm.escape_bash_quotes(str(parm)))
        var_name = gp.get_arg_name(None, ix, stack_frame)
        if var_name in robot_parm_names:
            p_string = "--" + var_name + "=" + str(parm)
            robot_parm_list.append(p_string)
        else:
            p_string = "-v " + var_name + ":" + str(parm)
            robot_parm_list.append(p_string)
        ix += 1

    robot_cmd_buf = (
        "robot " + " ".join(robot_parm_list) + " " + robot_file_path
    )

    return robot_cmd_buf


# Global variables to aid in cleanup after running robot_cmd_fnc.
gcr_last_robot_cmd_buf = ""
gcr_last_robot_rc = 0


def process_robot_output_files(robot_cmd_buf=None, robot_rc=None, gzip=None):
    r"""
    Process robot output files which can involve several operations:
    - If the files are in a temporary location, using SAVE_STATUS_POLICY to decide whether to move them to a
      permanent location or to delete them.
    - Gzipping them.

    Description of argument(s):
    robot_cmd_buf                   The complete command string used to invoke robot.
    robot_rc                        The return code from running the robot command string.
    gzip                            Indicates whether robot-generated output should be gzipped.
    """

    robot_cmd_buf = gm.dft(robot_cmd_buf, gcr_last_robot_cmd_buf)
    robot_rc = gm.dft(robot_rc, gcr_last_robot_rc)
    gzip = gm.dft(gzip, int(os.environ.get("GZIP_ROBOT", "1")))

    if robot_cmd_buf == "":
        # This can legitimately occur if this function is called from an exit_function without the program
        # having ever run robot_cmd_fnc.
        return

    SAVE_STATUS_POLICY = os.environ.get("SAVE_STATUS_POLICY", "ALWAYS")
    gp.qprint_vars(SAVE_STATUS_POLICY)

    # When SAVE_STATUS_POLICY is "NEVER" robot output files don't even get generated.
    if SAVE_STATUS_POLICY == "NEVER":
        return

    # Compose file_list based on robot command buffer passed in.
    robot_cmd_buf_dict = gc.parse_command_string(robot_cmd_buf)
    outputdir = robot_cmd_buf_dict["outputdir"]
    outputdir = gm.add_trailing_slash(outputdir)
    file_list = (
        outputdir
        + robot_cmd_buf_dict["output"]
        + " "
        + outputdir
        + robot_cmd_buf_dict["log"]
        + " "
        + outputdir
        + robot_cmd_buf_dict["report"]
    )

    # Double checking that files are present.
    shell_rc, out_buf = gc.shell_cmd(
        "ls -1 " + file_list + " 2>/dev/null", show_err=0
    )
    file_list = re.sub("\n", " ", out_buf.rstrip("\n"))

    if file_list == "":
        gp.qprint_timen(
            "No robot output files were found in " + outputdir + "."
        )
        return
    gp.qprint_var(robot_rc, gp.hexa())
    if SAVE_STATUS_POLICY == "FAIL" and robot_rc == 0:
        gp.qprint_timen(
            "The call to robot produced no failures."
            + "  Deleting robot output files."
        )
        gc.shell_cmd("rm -rf " + file_list)
        return

    if gzip:
        gc.shell_cmd("gzip -f " + file_list)
        # Update the values in file_list.
        file_list = re.sub(" ", ".gz ", file_list) + ".gz"

    # It TMP_ROBOT_DIR_PATH is set, it means the caller wanted the robot output initially directed to
    # TMP_ROBOT_DIR_PATH but later moved to FFDC_DIR_PATH.  Otherwise, we're done.

    if os.environ.get("TMP_ROBOT_DIR_PATH", "") == "":
        return

    # We're directing these to the FFDC dir path so that they'll be subjected to FFDC cleanup.
    target_dir_path = os.environ.get(
        "FFDC_DIR_PATH", os.environ.get("HOME", ".") + "/ffdc"
    )
    target_dir_path = gm.add_trailing_slash(target_dir_path)

    targ_file_list = [
        re.sub(".*/", target_dir_path, x) for x in file_list.split(" ")
    ]

    gc.shell_cmd(
        "mv " + file_list + " " + target_dir_path + " >/dev/null", time_out=600
    )

    gp.qprint_timen("New robot log file locations:")
    gp.qprintn("\n".join(targ_file_list))


def robot_cmd_fnc(
    robot_cmd_buf,
    robot_jail=os.environ.get("ROBOT_JAIL", ""),
    quiet=None,
    test_mode=0,
):
    r"""
    Run the robot command string.

    This function will set the various PATH variables correctly so that you are running the proper version of
    all imported files, etc.

    Description of argument(s):
    robot_cmd_buf                   The complete robot command string.
    robot_jail                      Indicates that this is to run in "robot jail" meaning without visibility
                                    to any apolloxxx import files, programs, etc.
    test_mode                       If test_mode is set, this function will not actually run the command.
    """

    quiet = int(gm.dft(quiet, gp.get_stack_var("quiet", 0)))
    gv.valid_value(robot_cmd_buf)

    # Set global variables to aid in cleanup with process_robot_output_files.
    global gcr_last_robot_cmd_buf
    global gcr_last_robot_rc
    gcr_last_robot_cmd_buf = robot_cmd_buf

    # Get globals set by init_robot_test_base_dir_path().
    module = sys.modules["__main__"]
    try:
        ROBOT_TEST_BASE_DIR_PATH = getattr(module, "ROBOT_TEST_BASE_DIR_PATH")
    except NameError:
        init_robot_test_base_dir_path()
        ROBOT_TEST_BASE_DIR_PATH = getattr(module, "ROBOT_TEST_BASE_DIR_PATH")

    ROBOT_TEST_RUNNING_FROM_SB = gm.get_mod_global(
        "ROBOT_TEST_RUNNING_FROM_SB"
    )

    if robot_jail == "":
        if ROBOT_TEST_RUNNING_FROM_SB:
            robot_jail = 0
        else:
            robot_jail = 1

    robot_jail = int(robot_jail)
    ROBOT_JAIL = os.environ.get("ROBOT_JAIL", "")
    gp.dprint_vars(
        ROBOT_TEST_BASE_DIR_PATH,
        ROBOT_TEST_RUNNING_FROM_SB,
        ROBOT_JAIL,
        robot_jail,
    )

    # Save PATH and PYTHONPATH to be restored later.
    os.environ["SAVED_PYTHONPATH"] = os.environ.get("PYTHONPATH", "")
    os.environ["SAVED_PATH"] = os.environ.get("PATH", "")

    if robot_jail:
        # Make sure required programs like python and robot can be found in the new restricted PATH.
        required_programs = "python robot"
        # It is expected that there will be a "python" program in the tool base bin path which is really a
        # link to select_version.  Ditto for "robot".  Call each with the --print_only option to get the
        # paths to the "real" programs.
        cmd_buf = (
            "for program in "
            + required_programs
            + " ; do dirname $(${program} --print_only) ; done 2>/dev/null"
        )
        rc, out_buf = gc.shell_cmd(cmd_buf, quiet=1, print_output=0)
        PYTHONPATH = ROBOT_TEST_BASE_DIR_PATH + "lib"
        NEW_PATH_LIST = [ROBOT_TEST_BASE_DIR_PATH + "bin"]
        NEW_PATH_LIST.extend(list(set(out_buf.rstrip("\n").split("\n"))))
        NEW_PATH_LIST.extend(
            [
                "/usr/local/sbin",
                "/usr/local/bin",
                "/usr/sbin",
                "/usr/bin",
                "/sbin",
                "/bin",
            ]
        )
        PATH = ":".join(NEW_PATH_LIST)
    else:
        PYTHONPATH = (
            os.environ.get("PYTHONPATH", "")
            + ":"
            + ROBOT_TEST_BASE_DIR_PATH
            + "lib"
        )
        PATH = (
            os.environ.get("PATH", "") + ":" + ROBOT_TEST_BASE_DIR_PATH + "bin"
        )

    os.environ["PYTHONPATH"] = PYTHONPATH
    os.environ["PATH"] = PATH
    gp.dprint_vars(PATH, PYTHONPATH)

    os.environ["FFDC_DIR_PATH_STYLE"] = os.environ.get(
        "FFDC_DIR_PATH_STYLE", "1"
    )
    gp.qpissuing(robot_cmd_buf, test_mode)
    if test_mode:
        os.environ["PATH"] = os.environ.get("SAVED_PATH", "")
        os.environ["PYTHONPATH"] = os.environ.get("SAVED_PYTHONPATH", "")
        return True

    if quiet:
        DEVNULL = open(os.devnull, "wb")
        stdout = DEVNULL
    else:
        stdout = None
    sub_proc = subprocess.Popen(robot_cmd_buf, stdout=stdout, shell=True)
    sub_proc.communicate()
    shell_rc = sub_proc.returncode
    os.environ["PATH"] = os.environ.get("SAVED_PATH", "")
    os.environ["PYTHONPATH"] = os.environ.get("SAVED_PYTHONPATH", "")
    gcr_last_robot_rc = shell_rc
    process_robot_output_files()
    if shell_rc != 0:
        gp.print_var(shell_rc, gp.hexa())
        return False

    return True
