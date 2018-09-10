#!/usr/bin/env python

r"""
This module provides functions which are useful to plug-in call point programs.
"""

import sys
import os
import re
import collections

import gen_print as gp
import gen_misc as gm
import gen_cmd as gc

PLUG_VAR_PREFIX = os.environ.get("PLUG_VAR_PREFIX", "AUTOBOOT")


def get_plug_in_package_name(case=None):
    r"""
    Return the plug-in package name (e.g. "OS_Console", "DB_Logging").

    Description of argument(s):
    case                            Indicates whether the value returned
                                    should be converted to upper or lower
                                    case.  Valid values are "upper", "lower"
                                    or None.
    """

    plug_in_package_name = os.path.basename(gp.pgm_dir_path[:-1])
    if case == "upper":
        return plug_in_package_name.upper()
    elif case == "lower":
        return plug_in_package_name.lower()
    else:
        return plug_in_package_name


def return_plug_vars():
    r"""
    Return an OrderedDict which is sorted by key and which contains all of the
    plug-in environment variables.

    Example excerpt of resulting dictionary:

    plug_var_dict:
      [AUTOBOOT_BASE_TOOL_DIR_PATH]:  /fspmount/
      [AUTOBOOT_BB_LEVEL]:            <blank>
      [AUTOBOOT_BOOT_FAIL]:           0
      ...

    This function also does the following:
    - Set a default value for environment variable
      AUTOBOOT_OPENBMC_NICKNAME/AUTOIPL_FSP1_NICKNAME if it is not already set.
    - Register PASSWORD variables to prevent their values from being printed.

    Note: The programmer may set a default for any given environment variable
    by declaring a global variable of the same name and setting its value.
    For example, let's say the calling program has this global declaration:

    PERF_EXERCISERS_TOTAL_TIMEOUT = '180'

    If environment variable PERF_EXERCISERS_TOTAL_TIMEOUT is blank or not set,
    this function will set it to 180.
    """

    plug_in_package_name = get_plug_in_package_name(case="upper")
    regex = "^(" + PLUG_VAR_PREFIX + "|AUTOGUI|" + plug_in_package_name + ")_"

    # Set a default for nickname.
    if os.environ.get("AUTOBOOT_OPENBMC_NICKNAME", "") == "":
        os.environ['AUTOBOOT_OPENBMC_NICKNAME'] = \
            os.environ.get("AUTOBOOT_OPENBMC_HOST", "")

    if os.environ.get("AUTOIPL_FSP1_NICKNAME", "") == "":
        os.environ['AUTOIPL_FSP1_NICKNAME'] = \
            os.environ.get("AUTOIPL_FSP1_NAME", "").split(".")[0]

    # For all variables specified in the parm_def file, we want them to
    # default to "" rather than being unset.
    # Process the parm_def file if it exists.
    parm_def_file_path = gp.pgm_dir_path + "parm_def"
    if os.path.exists(parm_def_file_path):
        parm_defs = gm.my_parm_file(parm_def_file_path)
    else:
        parm_defs = collections.OrderedDict()
    # Example parm_defs:
    # parm_defs:
    #   parm_defs[rest_fail]:           boolean
    #   parm_defs[command]:             string
    #   parm_defs[esel_stop_file_path]: string

    # Create a list of plug-in environment variables by pre-pending <all caps
    # plug-in package name>_<all caps var name>
    plug_in_parm_names = [plug_in_package_name + "_" + x for x in
                          map(str.upper, parm_defs.keys())]
    # Example plug_in_parm_names:
    # plug_in_parm_names:
    #  plug_in_parm_names[0]: STOP_REST_FAIL
    #  plug_in_parm_names[1]: STOP_COMMAND
    #  plug_in_parm_names[2]: STOP_ESEL_STOP_FILE_PATH

    # Initialize unset plug-in vars.
    for var_name in plug_in_parm_names:
        # If there is a global variable with the same name as the environment
        # variable, use its value as a default.
        default_value = gm.get_mod_global(var_name, "")
        os.environ[var_name] = os.environ.get(var_name, default_value)
        if os.environ[var_name] == "":
            os.environ[var_name] = default_value

    plug_var_dict = \
        collections.OrderedDict(sorted({k: v for (k, v) in
                                        os.environ.items()
                                        if re.match(regex, k)}.items()))

    # Register password values to prevent printing them out.  Any plug var
    # whose name ends in PASSWORD will be registered.
    password_vals = {k: v for (k, v) in plug_var_dict.items()
                     if re.match(r".*_PASSWORD$", k)}.values()
    map(gp.register_passwords, password_vals)

    return plug_var_dict


def sprint_plug_vars(headers=1):
    r"""
    Sprint the plug-in environment variables (i.e. those that begin with the
    global PLUG_VAR_PREFIX value or those that begin with <plug-in
    package_name>_ in upper case letters.).

    Example excerpt of output:
    AUTOBOOT_BASE_TOOL_DIR_PATH=/fspmount/
    AUTOBOOT_BB_LEVEL=
    AUTOBOOT_BOOT_FAIL=0
    AUTOBOOT_BOOT_FAIL_THRESHOLD=1000000

    Description of argument(s):
    headers                         Print a header and a footer.
    """

    plug_var_dict = return_plug_vars()
    buffer = ""
    if headers:
        buffer += "\n" + gp.sprint_dashes()
    for key, value in plug_var_dict.items():
        buffer += key + "=" + value + "\n"
    if headers:
        buffer += gp.sprint_dashes() + "\n"

    return buffer


def get_plug_vars():
    r"""
    Get all plug-in variables and put them in corresponding global variables.

    This would include all environment variables beginning with either the
    global PLUG_VAR_PREFIX value or with the upper case version of the plug-in
    package name + underscore (e.g. OP_SAMPLE_VAR1 for plug-in OP_Sample).

    The global variables to be set will be both with and without the global
    PLUG_VAR_PREFIX value prefix.  For example, if the environment variable in
    question is AUTOBOOT_OPENBMC_HOST, this function will set global variable
    AUTOBOOT_OPENBMC_HOST and global variable OPENBMC_HOST.
    """

    module = sys.modules['__main__']
    plug_var_dict = return_plug_vars()

    # Get all PLUG_VAR_PREFIX environment variables and put them into globals.
    for key, value in plug_var_dict.items():
        setattr(module, key, value)
        setattr(module, re.sub("^" + PLUG_VAR_PREFIX + "_", "", key), value)


def get_plug_default(var_name,
                     default=None):
    r"""
    Derive and return a default value for the given parm variable.

    Dependencies:
    Global variable PLUG_VAR_PREFIX must be set.

    This function will assign a default by checking the following environment
    variables in the order shown.  The first one that has a value will be used.
    - <upper case package_name>_<var_name>
    - <PLUG_VAR_PREFIX>_OVERRIDE_<var_name>
    - <PLUG_VAR_PREFIX>_<var_name>

    If none of these are found, this function will return the value passed by
    the caller in the "default" parm.

    Example:

    Let's say your plug-in is named "OS_Console" and you call this function as
    follows:

    get_plug_default("quiet", 0)

    The first of these environment variables that is found to be set will be
    used to provide the default value.
    - OS_CONSOLE_QUIET
    - AUTOBOOT_OVERRIDE_QUIET
    - AUTOBOOT_QUIET

    If none of those has a value, 0 (as specified by the caller in this
    example) is returned.

    Let's say the master driver program is named obmc_boot.  obmc_boot program
    is responsible for calling plug-ins.  Let's further suppose that the user
    wishes to run the master program with --debug=0 but wishes to have all
    plug-ins run with --debug=1.  This could be accomplished with the
    following call:
    export AUTOBOOT_OVERRIDE_DEBUG=1 ; obmc_boot --debug=0
    --plug_in_dir_paths=<list of plug ins>

    As another example, let's suppose that the user wishes to have just the
    OS_Console plug-in run with debug and everything else to default to
    debug=0.  This could be accomplished as follows:
    export OS_CONSOLE_DEBUG=1 ; obmc_boot --debug=0 --plug_in_dir_paths=<list
    of plug ins>

    And as one more example, let's say the user wishes to have obmc_boot and
    OS_Console run without debug but have all other plug-ins run with debug:
    export AUTOBOOT_OVERRIDE_DEBUG=1 ; export OS_CONSOLE_DEBUG=0 ; obmc_boot
    --debug=0 --plug_in_dir_paths=<list of plug ins>

    Description of argument(s):
    var_name                        The name of the variable for which a
                                    default value is to be calculated.
    default                         The default value if one cannot be
                                    determined.
    """

    var_name = var_name.upper()
    plug_in_package_name = get_plug_in_package_name(case="upper")

    package_var_name = plug_in_package_name + "_" + var_name
    default_value = os.environ.get(package_var_name, None)
    if default_value is not None:
        # A package-name version of the variable was found so return its value.
        return(default_value)

    plug_var_name = PLUG_VAR_PREFIX + "_OVERRIDE_" + var_name
    default_value = os.environ.get(plug_var_name, None)
    if default_value is not None:
        # A PLUG_VAR_PREFIX version of the variable was found so return its
        # value.
        return default_value

    plug_var_name = PLUG_VAR_PREFIX + "_" + var_name
    default_value = os.environ.get(plug_var_name, None)
    if default_value is not None:
        # A PLUG_VAR_PREFIX version of the variable was found so return its
        # value.
        return default_value

    return default


def srequired_plug_in(req_plug_in_names,
                      plug_in_dir_paths=None):
    r"""
    Return an empty string if the required plug-ins are found in
    plug_in_dir_paths.  Otherwise, return an error string.

    Example call:
    error_message = srequired_plug_in(req_plug_in_names, plug_in_dir_paths)

    Description of argument(s):
    req_plug_in_names               A list of plug_in names that the caller
                                    requires (e.g. ['OS_Console']).
    plug_in_dir_paths               A string which is a colon-delimited list
                                    of plug-ins specified by the user (e.g.
                                    DB_Logging:FFDC:OS_Console:Perf).  Path
                                    values (e.g. "/home/robot/dir1") will be
                                    stripped from this list to do the
                                    analysis.  Default value is the
                                    <PLUG_VAR_PREFIX>_PLUG_IN_DIR_PATHS
                                    environment variable.
    """

    # Calculate default value for plug_in_dir_paths.
    if plug_in_dir_paths is None:
        plug_in_dir_paths = os.environ.get(PLUG_VAR_PREFIX
                                           + "_PLUG_IN_DIR_PATHS", "")

    error_message = ""

    # Convert plug_in_dir_paths to a list of base names.
    plug_in_dir_paths = \
        list(filter(None, map(os.path.basename, plug_in_dir_paths.split(":"))))

    # Check for each of the user's required plug-ins.
    for plug_in_name in req_plug_in_names:
        if plug_in_name not in plug_in_dir_paths:
            error_message = "The \"" + get_plug_in_package_name() +\
                "\" plug-in cannot run unless the user also selects the \"" +\
                plug_in_name + "\" plug in:\n" +\
                gp.sprint_var(plug_in_dir_paths)

    return error_message


def required_plug_in(req_plug_in_names,
                     plug_in_dir_paths=None):
    r"""
    Return True if each of the plug-ins in req_plug_in_names can be found in
    plug_in_dir_paths  Otherwise, return False and print an error message to
    stderr.

    Example call:
    if not required_plug_in(['OS_Console'], AUTOBOOT_PLUG_IN_DIR_PATHS):
        return False

    Description of argument(s):
    (See Description of arguments for srequired_plug_in (above)).
    """

    error_message = srequired_plug_in(req_plug_in_names, plug_in_dir_paths)
    if not error_message == "":
        gp.print_error_report(error_message)
        return False

    return True


def compose_plug_in_save_dir_path(plug_in_package_name=None):
    r"""
    Create and return a directory path name that is suitable for saving
    plug-in data.

    The name will be comprised of things such as plug_in package name, pid,
    etc. in order to guarantee that it is unique for a given test run.

    Description of argument(s):
    plug_in_package_name            The plug-in package name.  This defaults
                                    to the name of the caller's plug-in
                                    package.  However, the caller can specify
                                    another value in order to retrieve data
                                    saved by another plug-in package.
    """

    plug_in_package_name = gm.dft(plug_in_package_name,
                                  get_plug_in_package_name())

    BASE_TOOL_DIR_PATH = \
        gm.add_trailing_slash(os.environ.get(PLUG_VAR_PREFIX
                                             + "BASE_TOOL_DIR_PATH",
                                             "/fspmount/"))
    NICKNAME = os.environ.get("AUTOBOOT_OPENBMC_NICKNAME", "")
    if NICKNAME == "":
        NICKNAME = os.environ["AUTOIPL_FSP1_NICKNAME"]
    MASTER_PID = os.environ[PLUG_VAR_PREFIX + "_MASTER_PID"]
    return BASE_TOOL_DIR_PATH + os.environ["USER"] + "/" + NICKNAME + "/" +\
        plug_in_package_name + "/" + MASTER_PID + "/"


def create_plug_in_save_dir(plug_in_package_name=None):
    r"""
    Create a directory suitable for saving plug-in processing data.  See
    compose_plug_in_save_dir_path for details.

    Description of argument(s):
    plug_in_package_name            See compose_plug_in_save_dir_path for
                                    details.
    """

    plug_in_save_dir_path = compose_plug_in_save_dir_path(plug_in_package_name)
    if os.path.isdir(plug_in_save_dir_path):
        return plug_in_save_dir_path
    gc.shell_cmd("mkdir -p " + plug_in_save_dir_path)
    return plug_in_save_dir_path


def delete_plug_in_save_dir(plug_in_package_name=None):
    r"""
    Delete the plug_in save directory.  See compose_plug_in_save_dir_path for
    details.

    Description of argument(s):
    plug_in_package_name            See compose_plug_in_save_dir_path for
                                    details.
    """

    gc.shell_cmd("rm -rf "
                 + compose_plug_in_save_dir_path(plug_in_package_name))


def save_plug_in_value(value, plug_in_package_name=None):
    r"""
    Save a value in a plug-in save file.  The value may be retrieved later via
    a call to the restore_plug_in_value function.

    This function will figure out the variable name of the value passed and
    use that name in creating the plug-in save file.

    Example call:

    my_var1 = 5
    save_plug_in_value(my_var1)

    In this example, the value "5" would be saved to the "my_var1" file in the
    plug-in save directory.

    Description of argument(s):
    value                           The value to be saved.
    plug_in_package_name            See compose_plug_in_save_dir_path for
                                    details.
    """

    # Get the name of the variable used as argument one to this function.
    var_name = gp.get_arg_name(0, 1, stack_frame_ix=2)
    plug_in_save_dir_path = create_plug_in_save_dir(plug_in_package_name)
    save_file_path = plug_in_save_dir_path + var_name
    gp.qprint_timen("Saving \"" + var_name + "\" value.")
    gc.shell_cmd("echo '" + str(value) + "' > " + save_file_path)


def restore_plug_in_value(default="", plug_in_package_name=None):
    r"""
    Return a value from a plug-in save file.

    The name of the value to be restored will be determined by this function
    based on the lvalue being assigned.  Consider the following example:

    my_var1 = restore_plug_in_value(2)

    In this example, this function would look for the "my_var1" file in the
    plug-in save directory, read its value and return it.  If no such file
    exists, the default value of 2 would be returned.

    Description of argument(s):
    default                         The default value to be returned if there
                                    is no plug-in save file for the value in
                                    question.
    plug_in_package_name            See compose_plug_in_save_dir_path for
                                    details.
    """

    # Get the lvalue from the caller's invocation of this function.
    lvalue = gp.get_arg_name(0, -1, stack_frame_ix=2)
    plug_in_save_dir_path = create_plug_in_save_dir(plug_in_package_name)
    save_file_path = plug_in_save_dir_path + lvalue
    if os.path.isfile(save_file_path):
        gp.qprint_timen("Restoring " + lvalue + " value from "
                        + save_file_path + ".")
        value = gm.file_to_list(save_file_path, newlines=0, comments=0,
                                trim=1)[0]
        if type(default) is bool:
            # Convert from string to bool.
            value = (value == 'True')
        if type(default) is int:
            # Convert from string to int.
            value = int(value)
        gp.qprint_varx(lvalue, value)
        return value
    else:
        gp.qprint_timen("Save file " + save_file_path
                        + " does not exist so returning default value.")
        gp.qprint_var(default)
        return default


# Create print wrapper functions for all sprint functions defined above.
# func_names contains a list of all print functions which should be created
# from their sprint counterparts.
func_names = ['print_plug_vars']

# stderr_func_names is a list of functions whose output should go to stderr
# rather than stdout.
stderr_func_names = []

replace_dict = dict(gp.replace_dict)
replace_dict['mod_qualifier'] = 'gp.'
func_defs = gp.create_print_wrapper_funcs(func_names, stderr_func_names,
                                          replace_dict)
gp.gp_debug_print(func_defs)
exec(func_defs)
