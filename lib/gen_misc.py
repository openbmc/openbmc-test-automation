#!/usr/bin/env python

# This module provides many valuable functions such as create_temp_file_name
# and my_parm_file.

# sys and os are needed to get the program dir path and program name.
import sys
import os
import re
import random
import inspect
import gen_print as gp



global_clean_up_file_list = []
################################################################################
def create_temp_file_name(file_suffix = "",
                          add_to_clean_up_file_list = 1,
                          delimiter = ":",
                          hidden = 0):

    # This function will compose a temporary file path and return it.  The
    # benefit of using this function are as follows:
    # - It will create a name that:
    # - Can easily be identitified by system administrators and developers
    # who must cleanup after programs that fail to do so.
    #   - Is unique (it will contain some randomly generated numbers).
    # - It will attempt to create the containing directory.
    # - It will optionally add the file path to global_clean_up_file_list.
    # This allows the user to keep track of temporary files and clean them up
    # upon program termination.

    # The general format of the path name will be:
    # /tmp/<userid>/<pgm name>:<func name>:<line>:<pid>:<random #>:<suffix>
    #
    # Example:
    # /tmp/csptest/test_gen_print.py:module:line_84:pid_13470:67113146:

    # Description of arguments:
    # file_suffix                  A suffix to be included in the file path.
    # add_to_clean_up_file_list    Indicates that the file name should be put
    #                              into the global_clean_up_file_list.
    # delimiter                    The delimiter which will separate the various
    #                              components of the generated name.
    # hidden                       Indicates that the file name should begin
    #                              with a period "." (which in linux and unix
    #                              means that it is "hidden").

    temp_dir_path = "/tmp/" + os.environ["USER"] + "/"

    try: os.mkdir(temp_dir_path)
    except OSError: pass

    frame, filename, line_number, function_name, lines, index = \
        inspect.stack()[1]

    func_name = gp.sprint_func_name(2).strip("<>")

    temp_file_name = gp.pgm_name + delimiter + func_name + delimiter + "line_" \
        + str(line_number) + delimiter + "pid_" + str(os.getpid()) + delimiter \
        + str(random.randint(1, 10000)) + str(random.randint(1, 10000)) \
        + delimiter + file_suffix

    temp_file_path = temp_dir_path + temp_file_name

    if add_to_clean_up_file_list:
        global_clean_up_file_list.append(temp_file_path)

    return temp_file_path

################################################################################



################################################################################
def my_parm_file(prop_file_path):

    # This function will read a properties file and put the keys/values into a
    # dictionary and return it.

    # The properties file must have the following format:
    # var_name<= or :>var_value
    # Comment lines (those beginning with a "#") and blank lines are allowed
    # and will be ignored.  Leading and trailing single or double quotes will be
    # stripped from the value.  E.g.
    # var1="This one"
    # Quotes are stripped so the resulting value for var1 is:
    # This one

    # prop_file_path	The caller should pass the path to the properties file.

    comment_regex = '^[ ]*#|^[ ]*$'
    comment_regex_obj = re.compile(comment_regex)

    split_var_regex = '[=:]'
    split_var_regex_obj = re.compile(split_var_regex)

    max_split = 1
    parms = {}
    with open(prop_file_path) as parms_file:
        for line in parms_file:
            line = line.strip("\n")
            print(line)
            # Skip comment and blank lines.
            if comment_regex_obj.match(line): continue
            var_name, var_value = split_var_regex_obj.split(line, max_split)
            # The var_name may have been indented in the file so we'll strip
            # spaces.
            var_name = var_name.strip(" ")
            # Strip spaces from var value.
            var_value = var_value.strip(" ")
            if var_value != "":
                # If the string is bounded by 2 single quotes or 2 double
                # quotes...
                if var_value[0] == "'" and var_value[-1] == "'":
                    var_value = var_value.strip("'")
                elif var_value[0] == "\"" and var_value[-1] == "\"":
                    var_value = var_value.strip("\"")
            parms[var_name] = var_value

    parms_file.close()
    return parms

################################################################################


