#!/usr/bin/env python

r"""
This module provides functions which are useful to plug-in call point programs.
"""

import sys
import os
import re
import collections

import gen_print as gp
import gen_valid as gv
import gen_misc as gm
import gen_cmd as gc
import func_args as fa

PLUG_VAR_PREFIX = os.environ.get("PLUG_VAR_PREFIX", "AUTOBOOT")


def get_plug_in_package_name(case=None):
    r"""
    Return the plug-in package name (e.g. "OS_Console", "DB_Logging").

    Description of argument(s):
    case                            Indicates whether the value returned should be converted to upper or
                                    lower case.  Valid values are "upper", "lower" or None.
    """

    plug_in_package_name = os.path.basename(gp.pgm_dir_path[:-1])
    if case == "upper":
        return plug_in_package_name.upper()
    elif case == "lower":
        return plug_in_package_name.lower()
    else:
        return plug_in_package_name


def return_plug_vars(general=True,
                     custom=True,
                     plug_in_package_name=None):
    r"""
    Return an OrderedDict which is sorted by key and which contains all of the plug-in environment variables.

    Example excerpt of resulting dictionary:

    plug_var_dict:
      [AUTOBOOT_BASE_TOOL_DIR_PATH]:  /tmp/
      [AUTOBOOT_BB_LEVEL]:            <blank>
      [AUTOBOOT_BOOT_FAIL]:           0
      ...

    This function also does the following:
    - Set a default value for environment variable AUTOBOOT_OPENBMC_NICKNAME/AUTOIPL_FSP1_NICKNAME if it is
      not already set.
    - Register PASSWORD variables to prevent their values from being printed.

    Note: The programmer may set a default for any given environment variable by declaring a global variable
    of the same name and setting its value.  For example, let's say the calling program has this global
    declaration:

    PERF_EXERCISERS_TOTAL_TIMEOUT = '180'

    If environment variable PERF_EXERCISERS_TOTAL_TIMEOUT is blank or not set, this function will set it to
    '180'.

    Furthermore, if such a default variable declaration is not a string, this function will preserve that
    non-string type in setting global variables (with the exception of os.environ values which must be
    string).  Example:

    NVDIMM_ENCRYPT = 0

    Description of argument(s):
    general                         Return general plug-in parms (e.g. those beginning with "AUTOBOOT" or
                                    "AUTOGUI").
    custom                          Return custom plug-in parms (i.e. those beginning with the upper case
                                    name of the plug-in package, for example "OBMC_SAMPLE_PARM1").
    plug_in_package_name            The name of the plug-in package for which custom parms are to be
                                    returned.  The default is the current plug in package name.
    """

    regex_list = []
    if not (general or custom):
        return collections.OrderedDict()
    plug_in_package_name = gm.dft(plug_in_package_name, get_plug_in_package_name())
    if general:
        regex_list = [PLUG_VAR_PREFIX, "AUTOGUI"]
    if custom:
        regex_list.append(plug_in_package_name.upper())

    regex = "^(" + "|".join(regex_list) + ")_"

    # Set a default for nickname.
    if os.environ.get("AUTOBOOT_OPENBMC_NICKNAME", "") == "":
        os.environ['AUTOBOOT_OPENBMC_NICKNAME'] = \
            os.environ.get("AUTOBOOT_OPENBMC_HOST", "")

    if os.environ.get("AUTOIPL_FSP1_NICKNAME", "") == "":
        os.environ['AUTOIPL_FSP1_NICKNAME'] = \
            os.environ.get("AUTOIPL_FSP1_NAME", "").split(".")[0]

    # For all variables specified in the parm_def file, we want them to default to "" rather than being unset.
    # Process the parm_def file if it exists.
    parm_def_file_path = os.path.dirname(gp.pgm_dir_path.rstrip("/")) + "/" + plug_in_package_name \
        + "/parm_def"
    if os.path.exists(parm_def_file_path):
        parm_defs = gm.my_parm_file(parm_def_file_path)
    else:
        parm_defs = collections.OrderedDict()
    # Example parm_defs:
    # parm_defs:
    #   parm_defs[rest_fail]:           boolean
    #   parm_defs[command]:             string
    #   parm_defs[esel_stop_file_path]: string

    # Create a list of plug-in environment variables by pre-pending <all caps plug-in package name>_<all
    # caps var name>
    plug_in_parm_names = [plug_in_package_name.upper() + "_" + x for x in
                          map(str.upper, parm_defs.keys())]
    # Example plug_in_parm_names:
    # plug_in_parm_names:
    #  plug_in_parm_names[0]: STOP_REST_FAIL
    #  plug_in_parm_names[1]: STOP_COMMAND
    #  plug_in_parm_names[2]: STOP_ESEL_STOP_FILE_PATH

    # os.environ only accepts string values.  However, if the user defines default values of other types
    # (e.g. int), we wish to preserve the type.
    non_string_defaults = {}
    # Initialize unset plug-in vars.
    for var_name in plug_in_parm_names:
        # If there is a global variable with the same name as the environment variable, use its value as a
        # default.
        default_value = gm.get_mod_global(var_name, "")
        if type(default_value) is not str:
            non_string_defaults[var_name] = type(default_value)
        os.environ[var_name] = os.environ.get(var_name, str(default_value))
        if os.environ[var_name] == "":
            os.environ[var_name] = str(default_value)

    plug_var_dict = \
        collections.OrderedDict(sorted({k: v for (k, v) in
                                        os.environ.items()
                                        if re.match(regex, k)}.items()))
    # Restore the types of any variables where the caller had defined default values.
    for key, value in non_string_defaults.items():
        cmd_buf = "plug_var_dict[key] = " + str(value).split("'")[1] + "(plug_var_dict[key]"
        if value is int:
            # Use int base argument of 0 to allow it to interpret hex strings.
            cmd_buf += ", 0)"
        else:
            cmd_buf += ")"
        exec(cmd_buf) in globals(), locals()
    # Register password values to prevent printing them out.  Any plug var whose name ends in PASSWORD will
    # be registered.
    password_vals = {k: v for (k, v) in plug_var_dict.items()
                     if re.match(r".*_PASSWORD$", k)}.values()
    map(gp.register_passwords, password_vals)

    return plug_var_dict


def sprint_plug_vars(headers=1, **kwargs):
    r"""
    Sprint the plug-in environment variables (i.e. those that begin with the global PLUG_VAR_PREFIX value or
    those that begin with <plug-in package_name>_ in upper case letters.).

    Example excerpt of output:
    AUTOBOOT_BASE_TOOL_DIR_PATH=/tmp/
    AUTOBOOT_BB_LEVEL=
    AUTOBOOT_BOOT_FAIL=0
    AUTOBOOT_BOOT_FAIL_THRESHOLD=1000000

    Description of argument(s):
    headers                         Print a header and a footer.
    kwargs                          These are passed directly to return_plug_vars.  See return_plug_vars doc
                                    string for details.
    """
    plug_var_dict = return_plug_vars(**kwargs)
    buffer = ""
    if headers:
        buffer += "\n" + gp.sprint_dashes()
    for key, value in plug_var_dict.items():
        buffer += gp.sprint_varx(key, value)
    if headers:
        buffer += gp.sprint_dashes() + "\n"

    return buffer


def print_plug_in_header():
    r"""
    Print plug-in header.

    When debug is set, print all plug_prefix variables (e.g. AUTOBOOT_OPENBMC_HOST, etc.) and all plug-in
    environment variables (e.g. OBMC_SAMPLE_PARM1) with surrounding dashed lines.  When debug is not set,
    print only the plug-in environment variables (e.g. OBMC_SAMPLE_PARM1) with no surrounding dashed lines.

    NOTE: plug-in environment variables means any variable defined in the <plug-in dir>/parm_def file plus
    any environment variables whose names begin with the upper-case plug-in package name.
    """

    dprint_plug_vars()
    if not debug:
        qprint_plug_vars(headers=0, general=False, custom=True)


def get_plug_vars(mod_name="__main__", **kwargs):
    r"""
    Get all plug-in variables and put them in corresponding global variables.

    This would include all environment variables beginning with either the global PLUG_VAR_PREFIX value or
    with the upper case version of the plug-in package name + underscore (e.g. OP_SAMPLE_VAR1 for plug-in
    OP_Sample).

    The global variables to be set will be both with and without the global PLUG_VAR_PREFIX value prefix.
    For example, if the environment variable in question is AUTOBOOT_OPENBMC_HOST, this function will set
    global variable AUTOBOOT_OPENBMC_HOST and global variable OPENBMC_HOST.

    Description of argument(s):
    mod_name                        The name of the module whose global plug-in variables should be retrieved.
    kwargs                          These are passed directly to return_plug_vars.  See return_plug_vars's
                                    prolog for details.
    """

    module = sys.modules[mod_name]
    plug_var_dict = return_plug_vars(**kwargs)

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

    This function will assign a default by checking the following environment variables in the order shown.
    The first one that has a value will be used.
    - <upper case package_name>_<var_name>
    - <PLUG_VAR_PREFIX>_OVERRIDE_<var_name>
    - <PLUG_VAR_PREFIX>_<var_name>

    If none of these are found, this function will return the value passed by the caller in the "default"
    parm.

    Example:

    Let's say your plug-in is named "OS_Console" and you call this function as follows:

    get_plug_default("quiet", 0)

    The first of these environment variables that is found to be set will be used to provide the default
    value.
    - OS_CONSOLE_QUIET
    - AUTOBOOT_OVERRIDE_QUIET
    - AUTOBOOT_QUIET

    If none of those has a value, 0 (as specified by the caller in this example) is returned.

    Let's say the master driver program is named obmc_boot.  obmc_boot program is responsible for calling
    plug-ins.  Let's further suppose that the user wishes to run the master program with --debug=0 but wishes
    to have all plug-ins run with --debug=1.  This could be accomplished with the following call:
    export AUTOBOOT_OVERRIDE_DEBUG=1 ; obmc_boot --debug=0 --plug_in_dir_paths=<list of plug ins>

    As another example, let's suppose that the user wishes to have just the OS_Console plug-in run with debug
    and everything else to default to debug=0.  This could be accomplished as follows:
    export OS_CONSOLE_DEBUG=1 ; obmc_boot --debug=0 --plug_in_dir_paths=<list of plug ins>

    And as one more example, let's say the user wishes to have obmc_boot and OS_Console run without debug but
    have all other plug-ins run with debug:
    export AUTOBOOT_OVERRIDE_DEBUG=1 ; export OS_CONSOLE_DEBUG=0 ; obmc_boot --debug=0
    --plug_in_dir_paths=<list of plug ins>

    Description of argument(s):
    var_name                        The name of the variable for which a default value is to be calculated.
    default                         The default value if one cannot be determined.
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
        # A PLUG_VAR_PREFIX version of the variable was found so return its value.
        return default_value

    plug_var_name = PLUG_VAR_PREFIX + "_" + var_name
    default_value = os.environ.get(plug_var_name, None)
    if default_value is not None:
        # A PLUG_VAR_PREFIX version of the variable was found so return its value.
        return default_value

    return default


def required_plug_in(required_plug_in_names,
                     plug_in_dir_paths=None):
    r"""
    Determine whether the required_plug_in_names are in plug_in_dir_paths, construct an error_message and
    call gv.process_error_message(error_message).

    In addition, for each plug-in in required_plug_in_names, set the global plug-in variables.  This is
    useful for callers who then want to validate certain values from other plug-ins.

    Example call:
    required_plug_in(required_plug_in_names)

    Description of argument(s):
    required_plug_in_names          A list of plug_in names that the caller requires (e.g. ['OS_Console']).
    plug_in_dir_paths               A string which is a colon-delimited list of plug-ins specified by the
                                    user (e.g. DB_Logging:FFDC:OS_Console:Perf).  Path values (e.g.
                                    "/home/robot/dir1") will be stripped from this list to do the analysis.
                                    Default value is the AUTOGUI_PLUG_IN_DIR_PATHS or
                                    <PLUG_VAR_PREFIX>_PLUG_IN_DIR_PATHS environment variable.
    """

    # Calculate default value for plug_in_dir_paths.
    plug_in_dir_paths = gm.dft(plug_in_dir_paths,
                               os.environ.get('AUTOGUI_PLUG_IN_DIR_PATHS',
                                              os.environ.get(PLUG_VAR_PREFIX + "_PLUG_IN_DIR_PATHS", "")))

    # Convert plug_in_dir_paths to a list of base names.
    plug_in_dir_paths = \
        list(filter(None, map(os.path.basename, plug_in_dir_paths.split(":"))))

    error_message = gv.valid_list(plug_in_dir_paths, required_values=required_plug_in_names)
    if error_message:
        return gv.process_error_message(error_message)

    for plug_in_package_name in required_plug_in_names:
        get_plug_vars(general=False, plug_in_package_name=plug_in_package_name)


def compose_plug_in_save_dir_path(plug_in_package_name=None):
    r"""
    Create and return a directory path name that is suitable for saving plug-in data.

    The name will be comprised of things such as plug_in package name, pid, etc. in order to guarantee that
    it is unique for a given test run.

    Description of argument(s):
    plug_in_package_name            The plug-in package name.  This defaults to the name of the caller's
                                    plug-in package.  However, the caller can specify another value in order
                                    to retrieve data saved by another plug-in package.
    """

    plug_in_package_name = gm.dft(plug_in_package_name,
                                  get_plug_in_package_name())

    BASE_TOOL_DIR_PATH = \
        gm.add_trailing_slash(os.environ.get(PLUG_VAR_PREFIX
                                             + "_BASE_TOOL_DIR_PATH",
                                             "/tmp/"))
    NICKNAME = os.environ.get("AUTOBOOT_OPENBMC_NICKNAME", "")
    if NICKNAME == "":
        NICKNAME = os.environ["AUTOIPL_FSP1_NICKNAME"]
    MASTER_PID = os.environ[PLUG_VAR_PREFIX + "_MASTER_PID"]
    gp.dprint_vars(BASE_TOOL_DIR_PATH, NICKNAME, plug_in_package_name, MASTER_PID)
    return BASE_TOOL_DIR_PATH + gm.username() + "/" + NICKNAME + "/" +\
        plug_in_package_name + "/" + str(MASTER_PID) + "/"


def create_plug_in_save_dir(plug_in_package_name=None):
    r"""
    Create a directory suitable for saving plug-in processing data and return its path name.

    See compose_plug_in_save_dir_path for details.

    Description of argument(s):
    plug_in_package_name            See compose_plug_in_save_dir_path for details.
    """

    plug_in_save_dir_path = compose_plug_in_save_dir_path(plug_in_package_name)
    if os.path.isdir(plug_in_save_dir_path):
        return plug_in_save_dir_path
    gc.shell_cmd("mkdir -p " + plug_in_save_dir_path)
    return plug_in_save_dir_path


def delete_plug_in_save_dir(plug_in_package_name=None):
    r"""
    Delete the plug_in save directory.  See compose_plug_in_save_dir_path for details.

    Description of argument(s):
    plug_in_package_name            See compose_plug_in_save_dir_path for details.
    """

    gc.shell_cmd("rm -rf "
                 + compose_plug_in_save_dir_path(plug_in_package_name))


def save_plug_in_value(var_value=None, plug_in_package_name=None, **kwargs):
    r"""
    Save a value in a plug-in save file.  The value may be retrieved later via a call to the
    restore_plug_in_value function.

    This function will figure out the variable name corresponding to the value passed and use that name in
    creating the plug-in save file.

    The caller may pass the value as a simple variable or as a keyword=value (see examples below).

    Example 1:

    my_var1 = 5
    save_plug_in_value(my_var1)

    In this example, the value "5" would be saved to the "my_var1" file in the plug-in save directory.

    Example 2:

    save_plug_in_value(my_var1=5)

    In this example, the value "5" would be saved to the "my_var1" file in the plug-in save directory.

    Description of argument(s):
    var_value                       The value to be saved.
    plug_in_package_name            See compose_plug_in_save_dir_path for details.
    kwargs                          The first entry may contain a var_name/var_value.  Other entries are
                                    ignored.
    """

    if var_value is None:
        var_name = next(iter(kwargs))
        var_value = kwargs[var_name]
    else:
        # Get the name of the variable used as argument one to this function.
        var_name = gp.get_arg_name(0, 1, stack_frame_ix=2)
    plug_in_save_dir_path = create_plug_in_save_dir(plug_in_package_name)
    save_file_path = plug_in_save_dir_path + var_name
    gp.qprint_timen("Saving \"" + var_name + "\" value.")
    gp.qprint_varx(var_name, var_value)
    gc.shell_cmd("echo '" + str(var_value) + "' > " + save_file_path)


def restore_plug_in_value(*args, **kwargs):
    r"""
    Return a value from a plug-in save file.

    The args/kwargs are interpreted differently depending on how this function is called.

    Mode 1 - The output of this function is assigned to a variable:

    Example:

    my_var1 = restore_plug_in_value(2)

    In this mode, the lvalue ("my_var1" in this example) will serve as the name of the value to be restored.

    Mode 2 - The output of this function is NOT assigned to a variable:

    Example:

    if restore_plug_in_value('my_var1', 2):
        do_something()

    In this mode, the caller must explicitly provide the name of the value being restored.

    The args/kwargs are interpreted as follows:

    Description of argument(s):
    var_name                        The name of the value to be restored. Only relevant in mode 1 (see
                                    example above).
    default                         The default value to be returned if there is no plug-in save file for the
                                    value in question.
    plug_in_package_name            See compose_plug_in_save_dir_path for details.
    """
    # Process args.
    lvalue = gp.get_arg_name(0, -1, stack_frame_ix=2)
    if lvalue:
        var_name = lvalue
    else:
        var_name, args, kwargs = fa.pop_arg("", *args, **kwargs)
    default, args, kwargs = fa.pop_arg("", *args, **kwargs)
    plug_in_package_name, args, kwargs = fa.pop_arg(None, *args, **kwargs)
    if args or kwargs:
        error_message = "Programmer error - Too many arguments passed for this function."
        raise ValueError(error_message)
    plug_in_save_dir_path = create_plug_in_save_dir(plug_in_package_name)
    save_file_path = plug_in_save_dir_path + var_name
    if os.path.isfile(save_file_path):
        gp.qprint_timen("Restoring " + var_name + " value from " + save_file_path + ".")
        var_value = gm.file_to_list(save_file_path, newlines=0, comments=0, trim=1)[0]
        if type(default) is bool:
            # Convert from string to bool.
            var_value = (var_value == 'True')
        if type(default) is int:
            # Convert from string to int.
            var_value = int(var_value)
    else:
        var_value = default
        gp.qprint_timen("Save file " + save_file_path + " does not exist so returning default value.")

    gp.qprint_varx(var_name, var_value)
    return var_value


def exit_not_master():
    r"""
    Exit the program with return code zero if this program was NOT called by the master program.

    There are cases where plug-ins are called by a multi-layered stack:

    master_wrapper
        obmc_boot_test.py
            Example_plug_in/cp_setup

    In a scenario like this, Example_plug_in/cp_setup may be called once directly by master_wrapper (the
    master) and and then called again directly by obmc_boot_test.py (the child).  Some plug-in programs may
    wish to avoid doing any processing on the second such call.  This function will achieve that purpose.

    This function will print a standard message to stdout prior to exiting.
    """

    AUTOBOOT_MASTER_PID = gm.get_mod_global("AUTOBOOT_MASTER_PID")
    AUTOBOOT_PROGRAM_PID = gm.get_mod_global("AUTOBOOT_PROGRAM_PID")

    if AUTOBOOT_MASTER_PID != AUTOBOOT_PROGRAM_PID:
        message = get_plug_in_package_name() + "/" + gp.pgm_name + " is not" \
            + " being called by the master program in the stack so no action" \
            + " will be taken."
        gp.qprint_timen(message)
        gp.qprint_vars(AUTOBOOT_MASTER_PID, AUTOBOOT_PROGRAM_PID)
        exit(0)


def stop_test_rc():
    r"""
    Return the constant stop test return code value.

    When a plug-in call point program returns this value, it indicates that master program should stop
    running.
    """

    return 0x00000002


def dump_ffdc_rc():
    r"""
    Return the constant dump FFDC return code value.

    When a plug-in call point program returns this value, it indicates that FFDC data should be collected.
    """

    return 0x00000002


# Create print wrapper functions for all sprint functions defined above.
# func_names contains a list of all print functions which should be created from their sprint counterparts.
func_names = ['print_plug_vars']

# stderr_func_names is a list of functions whose output should go to stderr rather than stdout.
stderr_func_names = []

replace_dict = dict(gp.replace_dict)
replace_dict['mod_qualifier'] = 'gp.'
func_defs = gp.create_print_wrapper_funcs(func_names, stderr_func_names,
                                          replace_dict)
gp.gp_debug_print(func_defs)
exec(func_defs)
