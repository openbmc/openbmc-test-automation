#!/usr/bin/env python

r"""
See help text for details (--help or -h option)..

Example properties file content:
quiet=n
test_mode=y
pos=file1 file2 file3

Example call:

prop_call.py --prop_file_name=prop_file my_program

The result is that the following command will be run:
my_program --test_mode=y --quiet=n file1 file2 file3
"""

import sys
import os

save_path_0 = sys.path[0]
del sys.path[0]

from gen_arg import *
from gen_print import *
from gen_valid import *
from gen_misc import *
from gen_cmd import *

# Restore sys.path[0].
sys.path.insert(0, save_path_0)


parser = argparse.ArgumentParser(
    usage='%(prog)s [OPTIONS]',
    description="%(prog)s will call a program using parameters retrieved" +
    " from the given properties file.",
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    prefix_chars='-+')

parser.add_argument(
    '--prop_dir_path',
    default=os.environ.get("PROP_DIR_PATH", os.getcwd()),
    help='The path to the directory that contains the properties file.' +
    '  The default value is environment variable "PROP_DIR_PATH", if' +
    ' set.  Otherwise, it is the current working directory.')

parser.add_argument(
    '--prop_file_name',
    help='The path to a properties file that contains the parameters to' +
    ' pass to the program.  If the properties file has a ".properties"' +
    ' extension, the caller need not specify the extension.  The format' +
    ' of each line in the properties file should be as follows:' +
    ' <parm_name=parm_value>.  Do not quote the parm value.  To specify' +
    ' positional parms, use a parm name of "pos".  For example: pos=this'
    ' value')

parser.add_argument(
    'program_name',
    help='The name of the program to be run.')

# Populate stock_list with options we want.
stock_list = [("test_mode", 0), ("quiet", 1), ("debug", 0)]


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
    Handle signals.  Without a function to catch a SIGTERM or SIGINT, our
    program would terminate immediately with return code 143 and without
    calling our exit_function.
    """

    # Our convention is to set up exit_function with atexit.register() so
    # there is no need to explicitly call exit_function from here.

    dprint_executing()

    # Calling exit prevents us from returning to the code that was running
    # when we received the signal.
    exit(0)


def validate_parms():
    r"""
    Validate program parameters, etc.  Return True or False (i.e. pass/fail)
    accordingly.
    """

    global prop_dir_path
    global prop_file_path

    if not valid_dir_path(prop_dir_path):
        return False
    prop_dir_path = add_trailing_slash(prop_dir_path)

    if not valid_value(prop_file_name):
        return False

    prop_file_path = prop_dir_path + prop_file_name

    # If properties file is not found, try adding ".properties" extension.
    if not os.path.isfile(prop_file_path):
        alt_prop_file_path = prop_file_path + ".properties"
        if os.path.isfile(alt_prop_file_path):
            prop_file_path = alt_prop_file_path

    if not valid_file_path(prop_file_path):
        return False

    if not valid_value(program_name):
        return False

    gen_post_validation(exit_function, signal_handler)

    return True


def main():

    if not gen_get_options(parser, stock_list):
        return False

    if not validate_parms():
        return False

    qprint_pgm_header()

    # Get the parameters from the properties file.
    properties = my_parm_file(prop_file_path)
    # The parms (including program name) need to go into a list.
    parms = [program_name]
    for key, value in properties.items():
        if key == "pos":
            # Process positional parm(s).
            parms.extend(value.split())
        else:
            parms.append("--" + key + "=" + escape_bash_quotes(value))

    # parm_string is only created for display in non-quiet mode.
    parm_string = " ".join(parms[1:])
    cmd_buf = program_name + " " + parm_string
    qprint_issuing(cmd_buf)
    if not test_mode:
        os.execvp(program_name, parms)

    return True


# Main

if not main():
    exit(1)
