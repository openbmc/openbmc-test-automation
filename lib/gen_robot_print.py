#!/usr/bin/env python

# This file contains functions useful for printing to stdout from robot
# programs.

import sys
import re
import gen_print as gp
from robot.libraries.BuiltIn import BuiltIn
from robot.api import logger



################################################################################
# In the following section of code, we will dynamically create robot versions
# of print functions for each of the sprint functions defined in the
# gen_print.py module.  So, for example, where we have an sprint_time() function
# defined above that returns the time to the caller in a string, we will create
# a corresponding rprint_time() function that will print that string directly to
# stdout.

# It can be complicated to follow what's being creaed by the exec statement
# below.  Here is an example of the rprint_time() function that will be created
# (as of the time of this writing):

# def rprint_time(*args):
#   s_func = getattr(gp, "sprint_time")
#   BuiltIn().log_to_console(s_func(*args), stream = 'STDIN', no_newline = True)

# Here are comments describing the lines in the body of the created function.
# Put a reference to the "s" version of this function in s_func.
# Call the "s" version of this function passing it all of our arguments.  Write
# the result to stdout.

robot_prefix = "r"
for func_name in gp.func_names:
    # The print_var function's job is to figure out the name of arg 1 and then
    # call print_varx.  This is not currently supported for robot programs.
    if func_name == "print_var": continue
    if func_name == "print_error": output_stream = "STDERR"
    else: output_stream = "STDIN"
    func_def = \
        [
            "def " + robot_prefix + func_name + "(*args):",
            "  s_func = getattr(gp, \"s" + func_name + "\")",
            "  BuiltIn().log_to_console(s_func(*args),"
            " stream = '" + output_stream + "',"
            " no_newline = True)"
        ]

    pgm_definition_string = '\n'.join(func_def)
    # Uncomment these 2 lines to help debug errors in this code.
    # BuiltIn().log_to_console(gp.sprint_var(func_def), no_newline = True)
    # BuiltIn().log_to_console(pgm_definition_string, no_newline = False)
    exec(pgm_definition_string)

    # Create abbreviated aliases (e.g. rpvarx is an alias for rprint_varx).
    alias = re.sub("print_", "p", func_name)
    exec(robot_prefix + alias + " = " + robot_prefix + func_name)


################################################################################



################################################################################
def rprint (buffer = ""):

    # rprint stands for "Robot Print".  This keyword will print the user's
    # buffer to the console.  This keyword does not write a linefeed.  It is the
    # responsibility of the caller to include a line feed if desired.  This
    # keyword is essentially an alias for "Log to Console  <string>
    # no_newline=True".

    # Description of arguments:
    # buffer                       The value that is to written to stdout.

    BuiltIn().log_to_console(buffer, no_newline = True)

################################################################################



################################################################################
def rprintn (buffer = ""):

    # rprintn stands for "Robot print with linefeed".  This keyword will print
    # the user's buffer to the console along with a linefeed.  It is basically
    # an abbreviated form of "Log go Console  <string>"

    # Description of arguments:
    # buffer                       The value that is to written to stdout.

    BuiltIn().log_to_console(buffer, no_newline = False)

################################################################################



################################################################################
def rprint_auto_vars(headers = 0):

    # This keyword will print all of the Automatic Variables described in the
    # Robot User's Guide using rpvars.

    # NOTE: Not all automatic variables are guaranteed to exist.

    # Description of arguments:
    # headers                      This indicates that a header and footer will
    #                              be printed.

    if int(headers) == 1:
        BuiltIn().log_to_console(gp.sprint_dashes(), no_newline = True)
        BuiltIn().log_to_console("Automatic Variables:", no_newline = False)

    rpvars("TEST_NAME", "TEST_TAGS", "TEST_DOCUMENTATION", "TEST_STATUS",
         "TEST_DOCUMENTATION", "TEST_STATUS", "TEST_MESSAGE", "PREV_TEST_NAME",
         "PREV_TEST_STATUS", "PREV_TEST_MESSAGE", "SUITE_NAME", "SUITE_SOURCE",
         "SUITE_DOCUMENTATION", "SUITE_METADATA", "SUITE_STATUS",
         "SUITE_MESSAGE", "KEYWORD_STATUS", "KEYWORD_MESSAGE", "LOG_LEVEL",
         "OUTPUT_FILE", "LOG_FILE", "REPORT_FILE", "DEBUG_FILE", "OUTPUT_DIR")

    if int(headers) == 1:
        BuiltIn().log_to_console(gp.sprint_dashes(), no_newline = True)

################################################################################



################################################################################
def rpvars(*var_names):

    # rpvars stands for "Robot Print Vars".  Given a list of variable names,
    # this keyword will print each variable name and value such that the value
    # lines up in the same column as messages printed with rptime.

    # NOTE: This function should NOT be called for local variables.  It is
    # incapable of obtaining their values.

    # NOTE: I intend to add code to allow the last several parms to be
    # recognized as hex, indent, etc. and passed on to rpvarx function.  See the
    # sprint_var() function in gen_print.py for details.

    # Description of arguments:
    # var_names                    A list of the names of variables to be
    #                              printed.

    for var_name in var_names:
        var_value = BuiltIn().get_variable_value("${" + var_name + "}")
        rpvarx(var_name, var_value)

################################################################################



# Define an alias.  rpvar is just a special case of rpvars where the var_names
# list contains only one element.
rpvar = rpvars


