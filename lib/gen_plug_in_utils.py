#!/usr/bin/env python

r"""
This module provides functions which are useful to plug-in call point programs.
"""

import sys
import os
import re
import collections

import gen_print as gp


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
    - Set a default value for environment variable AUTOBOOT_OPENBMC_NICKNAME
    if it is not already set.
    - Register PASSWORD variables to prevent their values from being printed.
    """

    plug_in_package_name = get_plug_in_package_name(case="upper")
    regex = "^(AUTOBOOT|" + plug_in_package_name + ")_"

    # Set a default for nickname.
    if os.environ.get("AUTOBOOT_OPENBMC_NICKNAME", "") == "":
        os.environ['AUTOBOOT_OPENBMC_NICKNAME'] = \
            os.environ.get("AUTOBOOT_OPENBMC_HOST", "")

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
    Sprint the plug-in environment variables (i.e. those that begin with
    AUTOBOOT_ those that begin with <plug-in package_name>_ in upper case
    letters.).

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

    This would include all environment variables beginning with either
    "AUTOBOOT_" or with the upper case version of the plug-in package name +
    underscore (e.g. OP_SAMPLE_VAR1 for plug-in OP_Sample).

    The global variables to be set will be both with and without the
    "AUTOBOOT_" prefix.  For example, if the environment variable in question
    is AUTOBOOT_OPENBMC_HOST, this function will set global variable
    AUTOBOOT_OPENBMC_HOST and global variable OPENBMC_HOST.
    """

    module = sys.modules['__main__']
    plug_var_dict = return_plug_vars()

    # Get all "AUTOBOOT_" environment variables and put them into globals.
    for key, value in plug_var_dict.items():
        setattr(module, key, value)
        setattr(module, re.sub("^AUTOBOOT_", "", key), value)


def get_plug_default(var_name,
                     default=None):

    r"""
    Derive and return a default value for the given parm variable.

    This function will assign a default by checking the following environment
    variables in the order shown.  The first one that has a value will be used.
    - <upper case package_name>_<var_name>
    - AUTOBOOT_OVERRIDE_<var_name>
    - AUTOBOOT_<var_name>

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

    autoboot_var_name = "AUTOBOOT_OVERRIDE_" + var_name
    default_value = os.environ.get(autoboot_var_name, None)
    if default_value is not None:
        # An AUTOBOOT_ version of the variable was found so return its value.
        return default_value

    autoboot_var_name = "AUTOBOOT_" + var_name
    default_value = os.environ.get(autoboot_var_name, None)
    if default_value is not None:
        # An AUTOBOOT_ version of the variable was found so return its value.
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
                                    AUTOBOOT_PLUG_IN_DIR_PATHS environment
                                    variable.
    """

    # Calculate default value for plug_in_dir_paths.
    if plug_in_dir_paths is None:
        plug_in_dir_paths = os.environ.get("AUTOBOOT_PLUG_IN_DIR_PATHS", "")

    error_message = ""

    # Convert plug_in_dir_paths to a list of base names.
    plug_in_dir_paths = \
        filter(None, map(os.path.basename, plug_in_dir_paths.split(":")))

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
