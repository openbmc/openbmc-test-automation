#!/usr/bin/env python3

r"""
Use robot framework API to extract test data from test suites.
Refer to https://robot-framework.readthedocs.io/en/3.0.1/autodoc/robot.parsing.html
"""

import os
import sys

from robot.api import SuiteVisitor, TestSuiteBuilder

sys.path.append(os.path.join(os.path.dirname(__file__), "../lib"))

from gen_arg import *  # NOQA
from gen_print import *  # NOQA
from gen_valid import *  # NOQA

# Set exit_on_error for gen_valid functions.
set_exit_on_error(True)

valid_options = ["name", "tags", "doc", "all"]

parser = argparse.ArgumentParser(
    usage="%(prog)s [OPTIONS]",
    description=(
        ";%(prog)s will print test suite information to stdout. This          "
        "         information consists of any and/or all of the following:    "
        "               the suite name, test case names, tag names and doc"
        " strings.                   Example for generated test case names    "
        "               tests/test_basic_poweron.robot                  "
        " Verify Front And Rear LED At Standby                   Power On Test"
        "                   Check For Application Failures                  "
        " Verify Uptime Average Against Threshold                   Test SSH"
        " And IPMI Connections"
    ),
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    prefix_chars="-+",
)

parser.add_argument(
    "--source_path", "-s", help="The robot test file or directory path."
)

parser.add_argument(
    "--option",
    "-o",
    default="name",
    help="Test case attribute name.  This may be any one of the following:\n"
    + sprint_var(valid_options),
)

# Populate stock_list with options we want.
stock_list = [("test_mode", 0), ("quiet", 0), ("debug", 0)]

class TestPrint(SuiteVisitor):

    def __init__(self, option):
        self.option = option

    def visit_test(self, test):
        r"""
        Print the test data from suite test object from option specified.
        """
        if self.option == "name":
            print(test.name)
        elif self.option == "tags":
            print(test.tags)
        elif self.option == "doc":
            print(test.doc)
        elif self.option == "all":
            print(test.name)
            print(test.tags)
            print(test.doc)

def exit_function(signal_number=0, frame=None):
    r"""
    Execute whenever the program ends normally or with the signals that we
    catch (i.e. TERM, INT).
    """

    dprint_executing()

    dprint_var(signal_number)

    qprint_pgm_footer()


def signal_handler(signal_number, frame):
    r"""
    Handle signals.  Without a function to catch a SIGTERM or SIGINT, the
    program would terminate immediately with return code 143 and without
    calling the exit_function.
    """

    # Our convention is to set up exit_function with atexit.register() so
    # there is no need to explicitly call exit_function from here.

    dprint_executing()

    # Calling exit prevents us from returning to the code that was running
    # when the signal was received.
    exit(0)


def validate_parms():
    r"""
    Validate program parameters, etc.  Return True or False (i.e. pass/fail)
    accordingly.
    """

    valid_path(source_path)

    valid_value(option, valid_values=valid_options)

    gen_post_validation(exit_function, signal_handler)


def parse_test_suites(source_path, option):
    r"""
    Parse the robot files and extract test data output.

    Description of argument(s):
    source_path   The path to a robot file or a directory of robot files.
    option        Test case attribute instances such as "name",
                  "tags" or "doc".
    """
    if os.path.isfile(source_path):
        file_paths = [source_path]
    else:
        file_paths = [
            os.path.join(path, file)
            for (path, dirs, files) in os.walk(source_path)
            for file in files
        ]

    for file_path in file_paths:
        print(file_path)
        if "__init__.robot" in file_path:
            continue
        test_suite_obj = TestSuiteBuilder().build(file_path)
        parse_test_file(test_suite_obj, option)


def parse_test_file(test_suite_obj, option):
    r"""
    Extract test information from test suite object and print it to stdout in
    the following format:

    <Test Case name>
    <Test Tags name>
    <Test Documentation>

    Description of argument(s):
    test_suite_obj    Test data suite object.
    option            Test case attribute instances such as "name",
                      "tags" or "doc".
    """

    test_suite_obj.visit(TestPrint(option))

def main():
    gen_get_options(parser, stock_list)

    validate_parms()

    qprint_pgm_header()

    parse_test_suites(source_path, option)

    return True


# Main
main()
