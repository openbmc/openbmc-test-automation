#!/usr/bin/env python

r"""
This module contains file functions such as file_diff.
"""

import time
import os
import re
from gen_cmd import cmd_fnc_u
robot_env = 1
try:
    from robot.libraries.BuiltIn import BuiltIn
    from robot.libraries import DateTime
except ImportError:
    robot_env = 0


def file_diff(file1_path,
              file2_path,
              diff_file_path,
              skip_string):
    r"""
    Compare the contents of two text files.  The comparison uses the Unix
    'diff' command.  Differences can be selectively ignored by use of
    the skip_string parameter.  The output of diff command is written
    to a user-specified file and is also written (logged) to the console.

    Description of arguments:
    file1_path       File containing text data.
    file2_path       Text file to compare to file1.
    diff_file_path   Text file which will contain the diff output.
    skip_string      To allow for differences which may expected or immaterial,
                     skip_string parameter is a word or a string of comma
                     separated words which specify what should be ignored.
                     For example, "size,speed".  Any line containing the word
                     size or the word speed will be ignored when the diff is
                     performed.  This parameter is optional.

    Returns:
    0 if both files contain the same information or they differ only in
      items specified by the skip_string.
    2 if FILES_DO_NOT_MATCH.
    3 if INPUT_FILE_DOES_NOT_EXIST.
    4 if IO_EXCEPTION_READING_FILE.
    5 if IO_EXCEPTION_WRITING_FILE.
    6 if INPUT_FILE_MALFORMED
    """

    FILES_MATCH = 0
    FILES_DO_NOT_MATCH = 2
    INPUT_FILE_DOES_NOT_EXIST = 3
    IO_EXCEPTION_READING_FILE = 4
    IO_EXCEPTION_WRITING_FILE = 5
    INPUT_FILE_MALFORMED = 6

    # The minimum size in bytes a file must be.
    min_file_byte_size = 1

    now = time.strftime("%Y-%m-%d %H:%M:%S")

    if (not os.path.exists(file1_path) or (not os.path.exists(file2_path))):
        return INPUT_FILE_DOES_NOT_EXIST
    try:
        with open(file1_path, 'r') as file:
            initial = file.readlines()
        with open(file2_path, 'r') as file:
            final = file.readlines()
    except IOError:
        file.close()
        return IO_EXCEPTION_READING_FILE
    except ValueError:
        file.close()
        return INPUT_FILE_MALFORMED
    else:
        file.close()

    # Must have more than a trivial number of bytes.
    if len(initial) < min_file_byte_size:
        return INPUT_FILE_MALFORMED

    if (initial == final):
        try:
            file = open(diff_file_path, 'w')
        except IOError:
            file.close()
        line_to_print = "Specified skip (ignore) string = " + \
            skip_string + "\n\n"
        file.write(line_to_print)
        line_to_print = now + " found no difference between file " + \
            file1_path + " and " + \
            file2_path + "\n"
        file.write(line_to_print)
        file.close()
        return FILES_MATCH

    # Find the differences and write difference report to diff_file_path file
    try:
        file = open(diff_file_path, 'w')
    except IOError:
        file.close()
        return IO_EXCEPTION_WRITING_FILE

    # Form a UNIX diff command and its parameters as a string.  For example,
    # if skip_string="size,capacity",  command = 'diff  -I "size"
    # -I "capacity"  file1_path file2_path'.
    skip_list = filter(None, re.split(r"[ ]*,[ ]*", skip_string))
    ignore_string = ' '.join([("-I " + '"' + x + '"') for x in skip_list])
    command = ' '.join(filter(None, ["diff", ignore_string, file1_path,
                       file2_path]))

    line_to_print = now + "   " + command + "\n"
    file.write(line_to_print)

    # Run the command and get the differences
    rc, out_buf = cmd_fnc_u(command, quiet=0, print_output=0, show_err=0)

    # Write the differences to the specified diff_file and console.
    if robot_env == 1:
        BuiltIn().log_to_console("DIFF:\n" + out_buf)
    else:
        print "DIFF:\n", out_buf

    file.write(out_buf)
    file.close()

    if rc == 0:
        # Any differences found were on the skip_string.
        return FILES_MATCH
    else:
        # We have at least one difference not in the skip_string.
        return FILES_DO_NOT_MATCH
