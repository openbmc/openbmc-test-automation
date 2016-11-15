#!/usr/bin/env python

r"""
This file contains functions useful for printing to stdout from robot programs.
"""

import sys
import re
import os

import gen_print as gp

from robot.libraries.BuiltIn import BuiltIn
from robot.api import logger


try:
    # The user can set environment variable "GEN_ROBOT_PRINT_DEBUG" to get
    # debug output from this module.
    gen_robot_print_debug = os.environ['GEN_ROBOT_PRINT_DEBUG']
except KeyError:
    gen_robot_print_debug = 0


###############################################################################
def set_quiet_default(quiet=None,
                      default=0):

    r"""
    Return a default value for the quiet variable based on its current value,
    the value of global ${QUIET} and default.

    Description of Arguments:
    quiet                           If this is set already, no default value
                                    is chosen.  Otherwise, it will be set to
                                    either the global ${QUIET} robot variable
                                    or to default (below).
    default                         The default value to be used if global
                                    ${QUIET} does not exist.
    """

    if quiet is None:
        # Set default quiet value.
        try:
            quiet = int(BuiltIn().get_variable_value("${quiet}"))
        except TypeError:
            quiet = int(default)
    quiet = int(quiet)

    return quiet

###############################################################################


###############################################################################
def rprint(buffer="",
           stream="STDOUT"):

    r"""
    rprint stands for "Robot Print".  This keyword will print the user's
    buffer to the console.  This keyword does not write a linefeed.  It is the
    responsibility of the caller to include a line feed if desired.  This
    keyword is essentially an alias for "Log to Console  <string>  <stream>".

    Description of arguments:
    buffer                          The value that is to written to stdout.
    """

    BuiltIn().log_to_console(str(buffer), no_newline=True, stream=stream)

###############################################################################


###############################################################################
def rprintn(buffer="",
            stream='STDOUT'):

    r"""
    rprintn stands for "Robot print with linefeed".  This keyword will print
    the user's buffer to the console along with a linefeed.  It is basically
    an abbreviated form of "Log go Console  <string>  <stream>"

    Description of arguments:
    buffer                          The value that is to written to stdout.
    """

    BuiltIn().log_to_console(buffer, no_newline=False, stream=stream)

###############################################################################


###############################################################################
def sprint_vars(*args):

    r"""
    sprint_vars stands for "String Print Vars".  This is a robot redefinition
    of the sprint_vars function in gen_print.py.  Given a list of variable
    names, this keyword will string print each variable name and value such
    that the value lines up in the same column as messages printed with rptime.

    Description of arguments:
    args:
        If the first argument is an integer, it will be interpreted to be the
        "indent" value.
        If the second argument is an integer, it will be interpreted to be the
        "col1_width" value.
        If the third argument is an integer, it will be interpreted to be the
        "hex" value.
        All remaining parms are considered variable names which are to be
        sprinted.
    """

    if len(args) == 0:
        return

    # Create list from args (which is a tuple) so that it can be modified.
    args_list = list(args)

    # See if parm 1 is to be interpreted as "indent".
    try:
        if type(int(args_list[0])) is int:
            indent = int(args_list[0])
            args_list.pop(0)
    except ValueError:
        indent = 0

    # See if parm 2 is to be interpreted as "col1_width".
    try:
        if type(int(args_list[0])) is int:
            loc_col1_width = int(args_list[0])
            args_list.pop(0)
    except ValueError:
        loc_col1_width = gp.col1_width

    # See if parm 2 is to be interpreted as "hex".
    try:
        if type(int(args_list[0])) is int:
            hex = int(args_list[0])
            args_list.pop(0)
    except ValueError:
        hex = 0

    buffer = ""
    for var_name in args_list:
        var_value = BuiltIn().get_variable_value("${" + var_name + "}")
        buffer += gp.sprint_varx(var_name, var_value, hex, indent,
                                 loc_col1_width)

    return buffer

###############################################################################


###############################################################################
def sprint_pgm_header(indent=0):

    r"""
    Sprint a standardized header that robot programs should print at the
    beginning of the run.  The header includes useful information like command
    line, pid, userid, program parameters, etc.  Callers need to have declared
    a global @{parm_list} variable which contains the names of all program
    parameters.
    """

    loc_col1_width = gp.col1_width + indent

    linefeed = 0
    rprintn()
    suite_name = BuiltIn().get_variable_value("${suite_name}")

    buffer = "\n"
    buffer += gp.sindent(gp.sprint_time("Running test suite \"" +
                                        suite_name + "\".\n"),
                         indent)
    buffer += gp.sprint_pgm_header(indent, linefeed)

    # Get value of global parm_list.
    parm_list = BuiltIn().get_variable_value("${parm_list}")

    buffer += sprint_vars(str(indent), str(loc_col1_width), *parm_list)
    buffer += "\n"

    return buffer

###############################################################################


###############################################################################
def sprint_error_report(error_text="\n"):

    r"""
    Print a standardized error report that robot programs should print on
    failure.  The report includes useful information like error text, command
    line, pid, userid, program parameters, etc.  Callers must have declared a
    @{parm_list} variable which contains the names of all program parameters.
    """

    buffer = ""
    buffer += gp.sprint_dashes(width=120, char="=")
    buffer += gp.sprint_error(error_text)

    indent = 2
    linefeed = 0

    buffer += sprint_pgm_header(indent)

    buffer += gp.sprint_dashes(width=120, char="=")

    return buffer

###############################################################################


###############################################################################
def sprint_issuing_keyword(cmd_buf,
                           test_mode=0):

    r"""
    Return a line indicating a robot command (i.e. keyword + args) that the
    program is about to execute.

    For example, for the following robot code...

    @{cmd_buf}=  Set Variable  Set Environment Variable  VAR1  1
    rdprint_issuing_keyword

    The output would look something like this:

    #(CDT) 2016/10/27 12:04:21 - Issuing: Set Environment Variable  VAR1  1

    Description of args:
    cmd_buf                         A list containing the keyword and
                                    arguments to be run.
    """

    buffer = ""
    cmd_buf_str = '  '.join([str(element) for element in cmd_buf])
    buffer += gp.sprint_issuing(cmd_buf_str, int(test_mode))

    return buffer

###############################################################################


###############################################################################
def sprint_auto_vars(headers=0):

    r"""
    This keyword will string print all of the Automatic Variables described in
    the Robot User's Guide using rprint_vars.

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

###############################################################################


###############################################################################
# In the following section of code, we will dynamically create robot versions
# of print functions for each of the sprint functions defined in the
# gen_print.py module.  So, for example, where we have an sprint_time()
# function defined above that returns the time to the caller in a string, we
# will create a corresponding rprint_time() function that will print that
# string directly to stdout.

# It can be complicated to follow what's being created by the exec statement
# below.  Here is an example of the rprint_time() function that will be
# created (as of the time of this writing):

# def rprint_time(*args):
#   s_func = getattr(gp, "sprint_time")
#   BuiltIn().log_to_console(s_func(*args),
#                            stream='STDIN',
#                            no_newline=True)

# Here are comments describing the lines in the body of the created function.
# Put a reference to the "s" version of this function in s_func.
# Call the "s" version of this function passing it all of our arguments.  Log
# the result to the console.

robot_prefix = "r"
robot_func_names =\
    [
        'print_error_report', 'print_pgm_header',
        'print_issuing_keyword', 'print_vars', 'print_auto_vars'
    ]
func_names = gp.func_names + robot_func_names
for func_name in func_names:
    # The print_var function's job is to figure out the name of arg 1 and
    # then call print_varx.  This is not currently supported for robot
    # programs.  Though it IS supported for python modules.
    if func_name == "print_error" or func_name == "print_error_report":
        output_stream = "STDERR"
    else:
        output_stream = "STDIN"
    if func_name in robot_func_names:
        object_name = "__import__(__name__)"
    else:
        object_name = "gp"
    func_def = \
        [
            "def " + robot_prefix + func_name + "(*args):",
            "  s_func = getattr(" + object_name + ", \"s" + func_name + "\")",
            "  BuiltIn().log_to_console(s_func(*args),"
            " stream='" + output_stream + "',"
            " no_newline=True)"
        ]

    pgm_definition_string = '\n'.join(func_def)
    if gen_robot_print_debug:
        rprintn(pgm_definition_string)
    exec(pgm_definition_string)

    # Now define "q" versions of each print function.  The q functions only
    # print if global robot var "quiet" is 0.  If the global var quiet is not
    # defined, it will be treated as though it were "1", i.e. no printing will
    # be done.
    func_def = \
        [
            "def rq" + func_name + "(*args):",
            "  try:",
            "    quiet = int(BuiltIn().get_variable_value(\"${quiet}\"))",
            "  except TypeError:",
            "    quiet = 1",
            "  if quiet:",
            "    return",
            "  r" + func_name + "(*args)"
        ]

    pgm_definition_string = '\n'.join(func_def)
    if gen_robot_print_debug:
        rprintn(pgm_definition_string)
    exec(pgm_definition_string)

    # Now define "d" versions of each print function.  The d functions only
    # print if global robot var "debug" is 1.
    func_def = \
        [
            "def rd" + func_name + "(*args):",
            "  try:",
            "    debug = int(BuiltIn().get_variable_value(\"${debug}\"))",
            "  except TypeError:",
            "    debug = 0",
            "  if not debug:",
            "    return",
            "  r" + func_name + "(*args)"
        ]

    pgm_definition_string = '\n'.join(func_def)
    if gen_robot_print_debug:
        rprintn(pgm_definition_string)
    exec(pgm_definition_string)

    # Create abbreviated aliases (e.g. rpvarx is an alias for rprint_varx).
    alias = re.sub("print_", "p", func_name)
    cmd_buf = robot_prefix + alias + " = " + robot_prefix + func_name
    if gen_robot_print_debug:
        rprintn(cmd_buf)
    exec(cmd_buf)

# Define an alias.  rpvar is just a special case of rpvars where the args
# list contains only one element.
cmd_buf = "rpvar = rpvars"
if gen_robot_print_debug:
    rprintn(cmd_buf)
exec(cmd_buf)

###############################################################################
