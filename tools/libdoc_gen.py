#!/usr/bin/env python

r"""
This module is used to generate the keyword documentation for
test libraries and resource files by using libdoc.py script.
"""

import argparse
import collections
from functools import reduce
import os
import platform
import subprocess
import sys


python = "python "
file_name = "libdoc.py"
locate_file_cmd = 'locate libdoc.py'
arg_list = ['format', 'docformat', 'Source', 'Destination']


def execute_command(command):
    r"""

    Execute command in process and return output, error, 
    return code value.

    Description of argument(s):

    command                    Command to execute.

    """

    # Command to execute in process.
    process = subprocess.Popen(command,
                               stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE,
                               shell=True)

    # Capture the command output.
    stdout_message, stderr_message = process.communicate()
    process_code = process.returncode

    return (stdout_message, stderr_message, process_code)


def locate_libdoc(locate_file_cmd):
    r"""

    Get a Libdoc.py file path.

    Description of argument(s):

    locate_file_cmd            Command to find a libdoc.py file.

    """

    # Command to execute in process.
    output, error, status_code = execute_command(locate_file_cmd)

    if status_code == 0:
        output = [line for line in output.decode('utf-8').split('\n')]
        return output
    else:
        sys.exit()


def get_python_version():
    r"""

    Get current version of python.

    """

    # Get the current version of python.
    python_version = platform.python_version()

    # Split the string by "."  and re-join after excluding one character.
    # Example: '2.7.16' and rejoin by excluding last character like '2.7'.
    python_version = '.'.join(python_version.split('.')[0:2])

    return python_version


def generate_libdoc_cli(libdoc_cmd):
    r"""

    Generate the robot keyword documentation.

    Description of argument(s):

    libdoc_cmd                 formed a command from arguments.

    """

    # Run locate_libdoc function to get libdoc.py file path.
    libdoc_path = locate_libdoc(locate_file_cmd)

    # Run get_python_version function to get current python version.
    get_py_ver = get_python_version()

    # Loop through the file path.
    for path in libdoc_path:

        # Checking python version and file presnet in path.
        if get_py_ver in path and file_name in path:
            # Final command to execute.
            gen_cmd = python + path + " " + libdoc_cmd

            # Command to execute in process.
            output, error, status_code = execute_command(gen_cmd)

            if status_code == 0:
                print("Path of robot keyword file: \n%s" % str(output.decode('utf-8')))
                break
            else:
                sys.exit()


def form_command(args):
    r"""

    Form command from passed arguments

    Description of argument(s):

    args                       Arguments passed to libdoc_gen.py.

    """

    temp_args = list()

    # Parse each element in argument list.
    for item in arg_list:
        # Check for same key in input arguments.
        value = vars(args).get(item, None)
        if "" == value:
            pass
        elif value is None:
            pass
        else:
            # Append to list each arguments.
            if item == 'Source' or item == 'Destination':
                temp_args.append(str(value))
            else:
                temp_args.append(str("--" + item))
                temp_args.append(str(value))

    # Form command by adding all element of list.
    arg_cmd = reduce(lambda x, y: x + " " + y, temp_args)

    return arg_cmd


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Generate keyword \
                                     documentation for test libraries \
                                     and resource files')

    parser.add_argument('-f', "--format", default="",
                        choices=['HTML', 'XML', 'html', 'xml'],
                        help='Set generated output file extension HTML | XML')

    parser.add_argument('-F', "--docformat", default="",
                        choices=['ROBOT', 'HTML', 'TEXT', 'REST',
                                 'robot', 'html', 'text', 'rest'],
                        help='Passing source file format \
                        ROBOT | HTML | TEXT | REST')

    parser.add_argument('Source',
                        help='Define source file format either of  \
                        ROBOT | HTML | TEXT | REST')

    parser.add_argument('Destination',
                        help='Define which file format report gets generated \
                        HTML | XML')

    args = parser.parse_args()

    # Form a command from input arguments.
    libdoc_cmd = form_command(args)

    # Pass the libdoc command to generate keyword documents.
    generate_libdoc_cli(libdoc_cmd)
