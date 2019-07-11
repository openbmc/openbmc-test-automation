#!/usr/bin/env python

r"""
This module is used to generate the keyword documentation for
test libraries and resource files by using libdoc.py script.
"""


import sys
import os
from functools import reduce

# Remove the python library path to restore with local project path later
save_path_0 = sys.path[0]
del sys.path[0]
sys.path.append(os.path.join(os.path.dirname(__file__), "../lib"))

from gen_arg import *
from gen_cmd import *
from gen_print import *
from gen_valid import *

# Restore sys.path[0].
sys.path.insert(0, save_path_0)


this_program = sys.argv[0]
info = " For more information:  " + this_program + '  -h'
if len(sys.argv) == 1:
    print (info)
    sys.exit(1)


python_name = "python "
locate_file_cmd = 'locate libdoc.py | grep -v pyc'
ignore_err = 1
arg_list = ['format', 'docformat', 'source', 'destination']
libdoc_file_name = 'libdoc.py'


parser = argparse.ArgumentParser(
    usage=info,
    description="%(prog)s uses a libdoc.py file provided by robot framework,\
    to generate the keyword documentation for test libraries and resource files.",
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    prefix_chars='-+')

parser.add_argument(
    '-f','--format',
    choices=['HTML', 'XML', 'html', 'xml'],
    default='',
    help='Set generated output file extension HTML | XML')

parser.add_argument(
    '-F','--docformat',
    choices=['ROBOT', 'HTML', 'TEXT', 'REST',\
             'robot', 'html', 'text', 'rest'],
    default='',
    help='Mention source file format ROBOT | HTML | TEXT | REST')

parser.add_argument(
    'source',
    default='',
    help='Path of source file')

parser.add_argument(
    'destination',
    default='',
    help='Path to generate the keyword documentation')


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
    Validate program parameters, etc. Return True or False.
    """

    if not valid_file_path(source):
        return False

    if not valid_dir_path(os.path.dirname(destination) + "//"):
        return False

    gen_post_validation(exit_function, signal_handler)

    return True


def form_command(format, docformat, source, destination):
    r"""
    Form a command using passed arguments.

    Description of argument(s):
    format                     Format of source file.
    docformat                  Format for doc file to be generated.
    source                     Path of source file.
    destination                Path to generate keyword documentation file.
    """

    # Intialize empyt list
    temp_args = list()
    args_value = list()

    args_value = [format, docformat, source, destination]

    # Loop over key , valye on aguments key value.
    for arg_key, arg_value in zip(arg_list, args_value):
        if "" == arg_value:
            pass
        else:
            if arg_key == 'source' or arg_key == 'destination':
                temp_args.append(str(arg_value))
            else:
                temp_args.append(str("--" + arg_key))
                temp_args.append(str(arg_value))

    # Form command by adding all element of list.
    arg_cmd = reduce(lambda x, y: x + " " + y, temp_args)

    return arg_cmd


def get_libdoc_file_path(locate_file_cmd):
    r""""
    Get a Libdoc.py file path.
    Description of argument(s):

    locate_file_cmd            Command to find a libdoc.py file.
    """

    # Run command to locate libdoc
    rc, output = shell_cmd(locate_file_cmd)

    # Chekcing return code,
    # if above shell_cmd is executed successfully
    if not ignore_err is rc:
        # Spliting the string by new line
        output = [line for line in output.split('\n')]
        return output
    else:
        sys.exit(1)


def generate_libdoc_cli(form_cmd_output):
    r"""
    Generate the keyword documentaion.

    Description of argument(s):
    form_cmd_output            Commad to generate keyword documentation.
    """

    # Run get_libdoc_file_path function to get libdoc.py file path.
    libdoc_file_path = get_libdoc_file_path(locate_file_cmd)

    python_version = sys.version.split()[0]

    # Split the string by "."  and re-join after excluding one character.
    # Example: '2.7.16' and rejoin by excluding last character like '2.7'.
    python_version = '.'.join(python_version.split('.')[0:2])

    # Looping over libdoc path
    for path in libdoc_file_path:
        # Checking current python version and libdoc file name in path
        if python_version in path and libdoc_file_name in path:
            # Final command to get executed
            gen_cmd = python_name + path + " " + form_cmd_output
            # Run command to generate keyword documentation file
            rc, output = shell_cmd(gen_cmd)
            # Chekcing return code,
            # if above shell_cmd is executed successfully
            if not ignore_err is rc:
                print("\nPath of robot keyword file: \n%s" % str(output))
                break
            else:
                sys.exit(1)


def main():

    if not gen_get_options(parser, stock_list):
        return False

    if not validate_parms():
        return False

    qprint_pgm_header()

    form_cmd_output = form_command(format, docformat, source, destination)

    generate_libdoc_cli(form_cmd_output)


# Main

if not main():
    sys.exit(1)

