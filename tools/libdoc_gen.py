#!/usr/bin/env python


r"""
This module is used to generate the keyword documentation for
test libraries and resource files by using libdoc.py script.
"""

import os
import platform
import subprocess
import sys

python = "python "
file_name ="libdoc.py"


def locate_libdoc():
    r"""

    Execute a command in process to get libdoc.py path.

    """

    # Command to execute in process.
    process = subprocess.Popen('locate libdoc.py', stdout=subprocess.PIPE, shell=True)

    # Capture the command output.
    output = process.communicate()[0].decode('utf-8')

    return output


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


def generate_libdoc(source_filename, destination_filename):
    r"""

    Generate the robot keyword documentation.

    Description of argument(s):
    source_filename       Source file path of test libraries or resource files.
    destination_filename  keyword documentaion file path to be generated.
	
    """

    # Run locate_libdoc function to get libdoc.py file path.
    libdoc_path = locate_libdoc()

    # Run get_python_version function to get current python version.
    get_py_ver = get_python_version()

    # Loop through the file path.
    for item in libdoc_path.split('\n'):

        # Checking python version and file presnet in path.
        if get_py_ver in item and file_name in item:

           # command to execute.
           gen_cmd = python + item + " " + source_filename + " " + destination_filename

           # Execute the command.
           os.system(gen_cmd)


if __name__ == "__main__":

    # variable to hold source path.
    source_filename = ""

    # variable to hold destination path.
    destination_filename = ""

    # variable to hold arguments passed to this module.
    params = sys.argv[1:]

    # Variable assigned with source path.
    source_filename = args[0]

    # variable assigned with destination path.
    destination_filename = args[-1]

    # Run generate_libdoc to generate robot keyword files.
    generate_libdoc(source_filename, destination_filename)
