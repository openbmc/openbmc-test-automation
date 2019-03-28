#!/usr/bin/env python

r"""
This file contains functions useful for printing to stdout from robot programs.
"""

import re
import os

import gen_print as gp
import wrap_utils as wu

from robot.libraries.BuiltIn import BuiltIn

gen_robot_print_debug = int(os.environ.get('GEN_ROBOT_PRINT_DEBUG', '0'))


def sprint_vars(*args):
    r"""
    Sprint the values of one or more variables to the console.

    This is a robot re=definition of the sprint_vars function in gen_print.py.
    Given a list of variable names, this keyword will string print each
    variable name and value such that each value lines up in the same column
    as messages printed with sprint_time().

    Description of arguments:
    args:
        If the first argument is an integer, it will be interpreted to be the
        "hex" value.
        If the second argument is an integer, it will be interpreted to be the
        "indent" value.
        If the third argument is an integer, it will be interpreted to be the
        "col1_width" value.
        All remaining parms are considered variable names which are to be
        sprinted.
    """

    if len(args) == 0:
        return

    # Create list from args (which is a tuple) so that it can be modified.
    args_list = list(args)

    # See if parm 1 is to be interpreted as "hex".
    try:
        if isinstance(int(args_list[0]), int):
            hex = int(args_list[0])
            args_list.pop(0)
    except ValueError:
        hex = 0

    # See if parm 2 is to be interpreted as "indent".
    try:
        if isinstance(int(args_list[0]), int):
            indent = int(args_list[0])
            args_list.pop(0)
    except ValueError:
        indent = 0

    # See if parm 3 is to be interpreted as "col1_width".
    try:
        if isinstance(int(args_list[0]), int):
            loc_col1_width = int(args_list[0])
            args_list.pop(0)
    except ValueError:
        loc_col1_width = gp.col1_width

    buffer = ""
    for var_name in args_list:
        var_value = BuiltIn().get_variable_value("${" + str(var_name) + "}")
        buffer += gp.sprint_varx(var_name, var_value, hex, indent,
                                 loc_col1_width)

    return buffer


def sprint_auto_vars(headers=0):
    r"""
    String print all of the Automatic Variables described in the Robot User's
    Guide using sprint_vars.

    NOTE: Not all automatic variables are guaranteed to exist.

    Description of arguments:
    headers                         This indicates that a header and footer
                                    should be printed.
    """

    buffer = ""
    if int(headers) == 1:
        buffer += gp.sprint_dashes()
        buffer += "Automatic Variables:"

    buffer += \
        sprint_vars(
            "TEST_NAME", "TEST_TAGS", "TEST_DOCUMENTATION", "TEST_STATUS",
            "TEST_DOCUMENTATION", "TEST_STATUS", "TEST_MESSAGE",
            "PREV_TEST_NAME", "PREV_TEST_STATUS", "PREV_TEST_MESSAGE",
            "SUITE_NAME", "SUITE_SOURCE", "SUITE_DOCUMENTATION",
            "SUITE_METADATA", "SUITE_STATUS", "SUITE_MESSAGE",
            "KEYWORD_STATUS", "KEYWORD_MESSAGE", "LOG_LEVEL", "OUTPUT_FILE",
            "LOG_FILE", "REPORT_FILE", "DEBUG_FILE", "OUTPUT_DIR")

    if int(headers) == 1:
        buffer += gp.sprint_dashes()

    return buffer


def gp_debug_print(buffer):
    r"""
    Print the buffer value only if gen_print_debug is set.

    This function is intended for use only by other functions in this module.

    Description of arguments:
    buffer                          The string to be printed.
    """

    if not gen_robot_print_debug:
        return

    gp.gp_print(buffer)


# In the following section of code, we will dynamically create print versions
# for several of the sprint functions defined above.  So, for example, where
# we have an sprint_vars() function defined above that returns formatted
# variable print outs in a string, we will create a corresponding print_vars()
# function that will print that string directly to stdout.

# It can be complicated to follow what's being created below.  Here is an
# example of the rprint_vars() function that will be created:

# def rprint_vars(*args):
#     gp.gp_print(gp.replace_passwords(sprint_vars(*args)), stream='stdout')

replace_dict = {'output_stream': 'stdout', 'mod_qualifier': 'gp.'}

gp_debug_print("gp.robot_env: " + str(gp.robot_env) + "\n")

# func_names contains a list of all print functions which should be created
# from their sprint counterparts.
func_names = [
    'print_vars', 'print_auto_vars'
]

# stderr_func_names is a list of functions whose output should go to stderr
# rather than stdout.
stderr_func_names = []

func_defs = gp.create_print_wrapper_funcs(func_names, stderr_func_names,
                                          replace_dict, "r")
gp_debug_print(func_defs)
exec(func_defs)

# Define an alias.  rpvar is just a special case of rpvars where the args
# list contains only one element.
cmd_buf = "rpvar = rpvars"
gp_debug_print("\n" + cmd_buf + "\n")
exec(cmd_buf)
