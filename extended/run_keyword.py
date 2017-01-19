#!/usr/bin/env python

r"""
This module is the python counterpart to run_keyword.robot.
"""

import gen_robot_print as grp
import gen_robot_valid as grv
from robot.libraries.BuiltIn import BuiltIn
import re


###############################################################################
def main_py():

    r"""
    Do main program processing.
    """

    setup()

    # NOTE: During code review the following question was raised: Rather than
    # supporting multiple keywords and variable assignments, couldn't a user
    # simply call twice by taking the output of the first call and feeding it
    # into the second call?  The answer is that that would not work in all
    # cases.  The following case would be such an example:
    # Let's say the first keyword string is as follows:
    # Create Dictionary  foo=bar
    # You wish to take the output of that call and specify it as a literal
    # value when running the following:
    # Want Dictionary  parm=<literal dictionary specification>
    # The problem is that there is no way to specify a dictionary as a
    # literal in Robot Framework.
    # By having this program support variable assignments and multiple
    # keywords, the user can invoke it with the following keyword string.
    # ${my_dict}=  Create Dictionary  foo=bar ; Want Dictionary  ${my_dict}

    # The user can pass multiple lib/resource paths by separating them with a
    # colon.

    lib_file_path_list = \
        BuiltIn().get_variable_value("${lib_file_path}").split(":")
    # Get rid of empty entry if it exists.
    if lib_file_path_list[0] == "":
        del lib_file_path_list[0]
    for lib_file_path in lib_file_path_list:
        # We don't want global variable getting changed when an import is done
        # so we'll save it and restore it.
        quiet = int(BuiltIn().get_variable_value("${quiet}"))
        if lib_file_path.endswith(".py"):
            grp.rdprint_issuing("import_library(\"" + lib_file_path + "\")")
            BuiltIn().import_library(lib_file_path)
        else:
            grp.rdprint_issuing("import_resource(\"" + lib_file_path + "\")")
            BuiltIn().import_resource(lib_file_path)
        BuiltIn().set_global_variable("${quiet}", quiet)

    # The user can pass multiple keyword strings by separating them with " ; ".
    keyword_list = \
        BuiltIn().get_variable_value("${keyword_string}").split(" ; ")
    for keyword_string in keyword_list:
        cmd_buf = keyword_string.split("  ")
        if re.match(r"\$\{", cmd_buf[0]):
            # This looks like an assignment (e.g. ${var}=  <keyword>).
            # We'll extract the variable name, remove element 0 from
            # cmd_buf and set the global variable with the results
            # after running the keyword.
            var_name = cmd_buf[0].strip("${}=")
            del cmd_buf[0]
        else:
            var_name = ""

        test_mode = int(BuiltIn().get_variable_value("${test_mode}"))
        grp.rqprint_issuing_keyword(cmd_buf, test_mode)
        if test_mode:
            return

        output = BuiltIn().run_keyword(*cmd_buf)

        if var_name != "":
            BuiltIn().set_global_variable("${" + var_name + "}", output)
        else:
            if output is not None:
                grp.rprint_var(output)

###############################################################################


###############################################################################
def setup():

    r"""
    Do general program setup tasks.
    """

    grp.rqprintn()

    validate_parms()

    grp.rqprint_pgm_header()

###############################################################################


###############################################################################
def validate_parms():

    r"""
    Validate all program parameters.
    """

    grv.rvalid_value("keyword_string")

    return True

###############################################################################


###############################################################################
def program_teardown():

    r"""
    Clean up after this program.
    """

    grp.rqprint_pgm_footer()

###############################################################################
