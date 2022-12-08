#!/usr/bin/env python3

r"""
This file contains functions useful for printing to stdout from robot programs.
"""

import re
import os

import gen_print as gp
import func_args as fa

from robot.libraries.BuiltIn import BuiltIn

gen_robot_print_debug = int(os.environ.get('GEN_ROBOT_PRINT_DEBUG', '0'))


def sprint_vars(*args, **kwargs):
    r"""
    Sprint the values of one or more variables to the console.

    This is a robot re-definition of the sprint_vars function in gen_print.py.  Given a list of variable
    names, this keyword will string print each variable name and value such that each value lines up in the
    same column as messages printed with sprint_time().

    Description of argument(s):
    args                            The names of the variables to be printed (e.g. var1 rather than ${var1}).
    kwargs                          See sprint_varx in gen_print.py for descriptions of all other arguments.
    """

    if 'fmt' in kwargs:
        # Find format option names in kwargs['fmt'] and wrap them with "gp." and "()" to make them into
        # function calls.  For example, verbose would be converted to "gp.verbose()".  This allows the user
        # to simply specify "fmt=verbose" (vs. fmt=gp.verbose()).
        # Note "terse" has been explicitly added for backward compatibility.  Once the repo has been purged
        # of its use, this code can return to its original form.
        regex = "(" + "|".join(gp.valid_fmts()) + "|terse)"
        kwargs['fmt'] = \
            re.sub(regex, "gp.\\1()", kwargs['fmt'])
    kwargs = fa.args_to_objects(kwargs)
    buffer = ""
    for var_name in args:
        var_value = BuiltIn().get_variable_value("${" + str(var_name) + "}")
        buffer += gp.sprint_varx(var_name, var_value, **kwargs)

    return buffer


def sprint_auto_vars(headers=0):
    r"""
    String print all of the Automatic Variables described in the Robot User's Guide using sprint_vars.

    NOTE: Not all automatic variables are guaranteed to exist.

    Description of argument(s):
    headers                         This indicates that a header and footer should be printed.
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
    Print the buffer value only if gen_robot_print_debug is set.

    This function is intended for use only by other functions in this module.

    Description of argument(s):
    buffer                          The string to be printed.
    """

    if not gen_robot_print_debug:
        return
    gp.gp_print(buffer)


# In the following section of code, we will dynamically create print versions for several of the sprint
# functions defined above.  For example, where we have an sprint_vars() function defined above that returns
# formatted variable print outs in a string, we will create a corresponding rprint_vars() function that will
# print that string directly to stdout.

# It can be complicated to follow what's being created below.  Here is an example of the rprint_vars()
# function that will be created:

# def rprint_vars(*args, **kwargs):
#     gp.gp_print(gp.replace_passwords(sprint_vars(*args, **kwargs)), stream='stdout')

# For sprint_vars (defined above), the following functions will be created:

# rprint_vars                       Robot Print Vars
# rqprint_vars                      Robot Print Vars if ${quiet} is set to ${0}.
# rdprint_vars                      Robot Print Vars if ${debug} is set to ${1}.
# rlprint_vars                      Robot Print Vars to the log instead of to the console.

# Abbreviated names are created for all of the preceding function names:
# rpvars
# rqpvars
# rdpvars
# rlpvars

# Users are encouraged to only use the abbreviated forms for development but to then ultimately switch to
# full names.
# Rprint Vars (instead of Rpvars)

replace_dict = {'output_stream': 'stdout', 'mod_qualifier': 'gp.'}

gp_debug_print("gp.robot_env: " + str(gp.robot_env) + "\n")

# func_names contains a list of all rprint functions which should be created from their sprint counterparts.
func_names = [
    'print_vars', 'print_auto_vars'
]

# stderr_func_names is a list of functions whose output should go to stderr rather than stdout.
stderr_func_names = []

func_defs = gp.create_print_wrapper_funcs(func_names, stderr_func_names,
                                          replace_dict, "r")
gp_debug_print(func_defs)
exec(func_defs)

# Define an alias.  rpvar is just a special case of rpvars where the args list contains only one element.
cmd_buf = "rpvar = rpvars"
gp_debug_print("\n" + cmd_buf + "\n")
exec(cmd_buf)
