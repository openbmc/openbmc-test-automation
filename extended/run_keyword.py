#!/usr/bin/env python

r"""
This module is the python counterpart to run_keyword.py.
"""

import gen_print as gp
import gen_robot_print as grp
import gen_robot_valid as grv

from robot.libraries.BuiltIn import BuiltIn


###############################################################################
def main_py():

    r"""
    Do main program processing.
    """

    setup()

    keyword_string = BuiltIn().get_variable_value("${keyword_string}")
    lib_file_path = BuiltIn().get_variable_value("${lib_file_path}")

    cmd_buf = keyword_string.split("  ")

    if lib_file_path != "":
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

    error_message = grp.sprint_error_report("Keyword \"" + cmd_buf[0] +
                                            "\" does not exist.\n")
    BuiltIn().keyword_should_exist(cmd_buf[0], msg=error_message)

    grp.rqprint_issuing_keyword(cmd_buf)
    status, output = BuiltIn().run_keyword_and_ignore_error(*cmd_buf)
    if status != "PASS":
        error_message = grp.sprint_error_report("\"" + cmd_buf[0] +
                                                "\" failed with the" +
                                                " following error:\n" + output)
        if not quiet:
            grp.rprint(error_message, 'STDERR')
        BuiltIn().fail(error_message)

    if output is not None:
        grp.rprint(output)

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
