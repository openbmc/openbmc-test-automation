#!/usr/bin/env python

r"""
Use robot framework API to extract test data from test suites.
Refer https://robot-framework.readthedocs.io/en/3.0.1/autodoc/robot.parsing.html
"""

import sys
import os
import glob
import getopt
from robot.parsing.model import TestData
sys.path.append(os.path.join(os.path.dirname(__file__), "../lib"))

from gen_arg import *
from gen_print import *
from gen_valid import *

parser = argparse.ArgumentParser(
    usage='%(prog)s [OPTIONS]',
    description="%(prog)s uses a robot framework API to extract test data\
    data from robot tests.",
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    prefix_chars='-+')

parser.add_argument(
    '--source',
    '-s',
    help='The robot test file or directory path.')

parser.add_argument(
    '--option',
    '-o',
	default="name",
    help='Test case attribute such as "name", "tags" or "doc"')

# Populate stock_list with options we want.
stock_list = [("test_mode", 0), ("quiet", 0), ("debug", 0)]


def exit_function(signal_number=0,
                  frame=None):
    r"""
    Execute whenever the program ends normally or with the signals that we
    catch (i.e. TERM, INT).
    """

    dprint_executing()

    dprint_var(signal_number)

    qprint_pgm_footer()


def signal_handler(signal_number,
                   frame):
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

    if not (valid_file_path(source) or valid_dir_path(source)):
        return False

    gen_post_validation(exit_function, signal_handler)

    return True


def parse_test_suites(suite_file_path, option):
    r"""
    Parse the robot files and extract test data output.
    folder.

    Description of argument(s):
    suite_file_path   The path to a robot suite file(s).
    option            Test case attribute instances such as "name",
	                  "tags" or "doc".
    """

    if valid_file_path(suite_file_path):
        print suite_file_path
        suite = TestData(parent=None, source=suite_file_path)
        parse_test_file(suite, option)
    else:
        files_path = [ os.path.join(path, file)
                     for (path, dirs, files) in os.walk(suite_file_path)
                     for file in files]
        for file in files_path:
            # Skip special file test suite.
            print file
            if "__init__.robot" in file:
                continue
            suite = TestData(parent=None, source=file)
            parse_test_file(suite, option)


def parse_test_file(suite, option):
    r"""
    Extract test information from test suite object.

    Description of argument(s):
    suite    Test data suite object.
    option   Test case attribute instances such as "name",
	         "tags" or "doc".
    """

    for testcase in suite.testcase_table:
        if option == "name" or option == "all":
            print "Test Case name:", testcase.name
        if option == "tags" or option == "all":
            print "Test Tags name:", testcase.tags
        if option == "doc" or option == "all":
            print "Test Documentation:", testcase.doc


def main():

    if not gen_get_options(parser, stock_list):
        return False

    if not validate_parms():
        return False

    qprint_pgm_header()

    parse_test_suites(source, option)

    return True


# Main

if not main():
    exit(1)
