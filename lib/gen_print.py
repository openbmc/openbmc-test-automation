#!/usr/bin/env python

r"""
This module provides many valuable print functions such as sprint_var,
sprint_time, sprint_error, sprint_call_stack.
"""

import sys
import os
import time
import inspect
import re
import grp
import socket
import argparse
try:
    import __builtin__
except ImportError:
    import builtins as __builtin__
import logging
import collections
from wrap_utils import *

try:
    robot_env = 1
    from robot.utils import DotDict
    from robot.utils import NormalizedDict
    from robot.libraries.BuiltIn import BuiltIn
    # Having access to the robot libraries alone does not indicate that we
    # are in a robot environment.  The following try block should confirm that.
    try:
        var_value = BuiltIn().get_variable_value("${SUITE_NAME}", "")
    except BaseException:
        robot_env = 0
except ImportError:
    robot_env = 0

import gen_arg as ga

# Setting these variables for use both inside this module and by programs
# importing this module.
pgm_file_path = sys.argv[0]
pgm_name = os.path.basename(pgm_file_path)
pgm_dir_path = os.path.normpath(re.sub("/" + pgm_name, "", pgm_file_path)) +\
    os.path.sep


# Some functions (e.g. sprint_pgm_header) have need of a program name value
# that looks more like a valid variable name.  Therefore, we'll swap odd
# characters like "." out for underscores.
pgm_name_var_name = pgm_name.replace(".", "_")

# Initialize global values used as defaults by print_time, print_var, etc.
col1_indent = 0

# Calculate default column width for print_var functions based on environment
# variable settings.  The objective is to make the variable values line up
# nicely with the time stamps.
col1_width = 29

NANOSECONDS = os.environ.get('NANOSECONDS', '1')


if NANOSECONDS == "1":
    col1_width = col1_width + 7

SHOW_ELAPSED_TIME = os.environ.get('SHOW_ELAPSED_TIME', '1')

if SHOW_ELAPSED_TIME == "1":
    if NANOSECONDS == "1":
        col1_width = col1_width + 14
    else:
        col1_width = col1_width + 7

# Initialize some time variables used in module functions.
start_time = time.time()
# sprint_time_last_seconds is used to calculate elapsed seconds.
sprint_time_last_seconds = [start_time]
# Define global index for the sprint_time_last_seconds list.
last_seconds_ix = 0


# Since output from the lprint_ functions goes to a different location than
# the output from the print_ functions (e.g. a file vs. the console),
# sprint_time_last_seconds has been created as a list rather than a simple
# integer so that it can store multiple sprint_time_last_seconds values.
# Standard print_ functions defined in this file will use
# sprint_time_last_seconds[0] and the lprint_ functions will use
# sprint_time_last_seconds[1].
def lprint_last_seconds_ix():
    r"""
    Return lprint last_seconds index value to the caller.
    """
    return 1


# The user can set environment variable "GEN_PRINT_DEBUG" to get debug output
# from this module.
gen_print_debug = int(os.environ.get('GEN_PRINT_DEBUG', 0))


def sprint_func_name(stack_frame_ix=None):
    r"""
    Return the function name associated with the indicated stack frame.

    Description of arguments:
    stack_frame_ix                  The index of the stack frame whose
                                    function name should be returned.  If the
                                    caller does not specify a value, this
                                    function will set the value to 1 which is
                                    the index of the caller's stack frame.  If
                                    the caller is the wrapper function
                                    "print_func_name", this function will bump
                                    it up by 1.
    """

    # If user specified no stack_frame_ix, we'll set it to a proper default
    # value.
    if stack_frame_ix is None:
        func_name = sys._getframe().f_code.co_name
        caller_func_name = sys._getframe(1).f_code.co_name
        if func_name[1:] == caller_func_name:
            stack_frame_ix = 2
        else:
            stack_frame_ix = 1

    func_name = sys._getframe(stack_frame_ix).f_code.co_name

    return func_name


def get_line_indent(line):
    r"""
    Return the number of spaces at the beginning of the line.
    """

    return len(line) - len(line.lstrip(' '))


# get_arg_name is not a print function per se.  I have included it in this
# module because it is used by sprint_var which is found in this module.
def get_arg_name(var,
                 arg_num=1,
                 stack_frame_ix=1):
    r"""
    Return the "name" of an argument passed to a function.  This could be a
    literal or a variable name.

    Description of arguments:
    var                             The variable whose name you want returned.
    arg_num                         The arg number whose name is to be
                                    returned.  To illustrate how arg_num is
                                    processed, suppose that a programmer codes
                                    this line: "rc, outbuf = my_func(var1,
                                    var2)" and suppose that my_func has this
                                    line of code: "result = gp.get_arg_name(0,
                                    arg_num, 2)".  If arg_num is positive, the
                                    indicated argument is returned.  For
                                    example, if arg_num is 1, "var1" would be
                                    returned, If arg_num is 2, "var2" would be
                                    returned.  If arg_num exceeds the number
                                    of arguments, get_arg_name will simply
                                    return a complete list of the arguments.
                                    If arg_num is 0, get_arg_name will return
                                    the name of the target function as
                                    specified in the calling line ("my_func"
                                    in this case).  To clarify, if the caller
                                    of the target function uses an alias
                                    function name, the alias name would be
                                    returned.  If arg_num is negative, an
                                    lvalue variable name is returned.
                                    Continuing with the given example, if
                                    arg_num is -2 the 2nd parm to the left of
                                    the "=" ("rc" in this case) should be
                                    returned.  If arg_num is -1, the 1st parm
                                    to the left of the "=" ("out_buf" in this
                                    case) should be returned.  If arg_num is
                                    less than -2, an entire dictionary is
                                    returned.  The keys to the dictionary for
                                    this example would be -2 and -1.
    stack_frame_ix                  The stack frame index of the target
                                    function.  This value must be 1 or
                                    greater.  1 would indicate get_arg_name's
                                    stack frame.  2 would be the caller of
                                    get_arg_name's stack frame, etc.

    Example 1:

    my_var = "mike"
    var_name = get_arg_name(my_var)

    In this example, var_name will receive the value "my_var".

    Example 2:

    def test1(var):
        # Getting the var name of the first arg to this function, test1.
        # Note, in this case, it doesn't matter what you pass as the first arg
        # to get_arg_name since it is the caller's variable name that matters.
        dummy = 1
        arg_num = 1
        stack_frame = 2
        var_name = get_arg_name(dummy, arg_num, stack_frame)

    # Mainline...

    another_var = "whatever"
    test1(another_var)

    In this example, var_name will be set to "another_var".

    """

    # Note: I wish to avoid recursion so I refrain from calling any function
    # that calls this function (i.e. sprint_var, valid_value, etc.).

    # The user can set environment variable "GET_ARG_NAME_DEBUG" to get debug
    # output from this function.
    local_debug = int(os.environ.get('GET_ARG_NAME_DEBUG', 0))
    # In addition to GET_ARG_NAME_DEBUG, the user can set environment
    # variable "GET_ARG_NAME_SHOW_SOURCE" to have this function include source
    # code in the debug output.
    local_debug_show_source = int(
        os.environ.get('GET_ARG_NAME_SHOW_SOURCE', 0))

    if stack_frame_ix < 1:
        print_error("Programmer error - Variable \"stack_frame_ix\" has an"
                    + " invalid value of \"" + str(stack_frame_ix) + "\".  The"
                    + " value must be an integer that is greater than or equal"
                    + " to 1.\n")
        return

    if local_debug:
        debug_indent = 2
        print("")
        print_dashes(0, 120)
        print(sprint_func_name() + "() parms:")
        print_varx("var", var, 0, debug_indent)
        print_varx("arg_num", arg_num, 0, debug_indent)
        print_varx("stack_frame_ix", stack_frame_ix, 0, debug_indent)
        print("")
        print_call_stack(debug_indent, 2)

    for count in range(0, 2):
        try:
            frame, filename, cur_line_no, function_name, lines, index = \
                inspect.stack()[stack_frame_ix]
        except IndexError:
            print_error("Programmer error - The caller has asked for"
                        + " information about the stack frame at index \""
                        + str(stack_frame_ix) + "\".  However, the stack"
                        + " only contains " + str(len(inspect.stack()))
                        + " entries.  Therefore the stack frame index is out"
                        + " of range.\n")
            return
        if filename != "<string>":
            break
        # filename of "<string>" may mean that the function in question was
        # defined dynamically and therefore its code stack is inaccessible.
        # This may happen with functions like "rqprint_var".  In this case,
        # we'll increment the stack_frame_ix and try again.
        stack_frame_ix += 1
        if local_debug:
            print("Adjusted stack_frame_ix...")
            print_varx("stack_frame_ix", stack_frame_ix, 0, debug_indent)

    real_called_func_name = sprint_func_name(stack_frame_ix)

    module = inspect.getmodule(frame)

    # Though I would expect inspect.getsourcelines(frame) to get all module
    # source lines if the frame is "<module>", it doesn't do that.  Therefore,
    # for this special case, I will do inspect.getsourcelines(module).
    if function_name == "<module>":
        source_lines, source_line_num =\
            inspect.getsourcelines(module)
        line_ix = cur_line_no - source_line_num - 1
    else:
        source_lines, source_line_num =\
            inspect.getsourcelines(frame)
        line_ix = cur_line_no - source_line_num

    if local_debug:
        print("\n  Variables retrieved from inspect.stack() function:")
        print_varx("frame", frame, 0, debug_indent + 2)
        print_varx("filename", filename, 0, debug_indent + 2)
        print_varx("cur_line_no", cur_line_no, 0, debug_indent + 2)
        print_varx("function_name", function_name, 0, debug_indent + 2)
        print_varx("lines", lines, 0, debug_indent + 2)
        print_varx("index", index, 0, debug_indent + 2)
        print_varx("source_line_num", source_line_num, 0, debug_indent)
        print_varx("line_ix", line_ix, 0, debug_indent)
        if local_debug_show_source:
            print_varx("source_lines", source_lines, 0, debug_indent)
        print_varx("real_called_func_name", real_called_func_name, 0,
                   debug_indent)

    # Get a list of all functions defined for the module.  Note that this
    # doesn't work consistently when _run_exitfuncs is at the top of the stack
    # (i.e. if we're running an exit function).  I've coded a work-around
    # below for this deficiency.
    all_functions = inspect.getmembers(module, inspect.isfunction)

    # Get called_func_id by searching for our function in the list of all
    # functions.
    called_func_id = None
    for func_name, function in all_functions:
        if func_name == real_called_func_name:
            called_func_id = id(function)
            break
    # NOTE: The only time I've found that called_func_id can't be found is
    # when we're running from an exit function.

    # Look for other functions in module with matching id.
    aliases = set([real_called_func_name])
    for func_name, function in all_functions:
        if func_name == real_called_func_name:
            continue
        func_id = id(function)
        if func_id == called_func_id:
            aliases.add(func_name)

    # In most cases, my general purpose code above will find all aliases.
    # However, for the odd case (i.e. running from exit function), I've added
    # code to handle pvar, qpvar, dpvar, etc. aliases explicitly since they
    # are defined in this module and used frequently.
    # pvar is an alias for print_var.
    aliases.add(re.sub("print_var", "pvar", real_called_func_name))

    # The call to the function could be encased in a recast (e.g.
    # int(func_name())).
    recast_regex = "([^ ]+\\([ ]*)?"
    import_name_regex = "([a-zA-Z0-9_]+\\.)?"
    func_name_regex = recast_regex + import_name_regex + "(" +\
        '|'.join(aliases) + ")"
    pre_args_regex = ".*" + func_name_regex + "[ ]*\\("

    # Search backward through source lines looking for the calling function
    # name.
    found = False
    for start_line_ix in range(line_ix, 0, -1):
        # Skip comment lines.
        if re.match(r"[ ]*#", source_lines[start_line_ix]):
            continue
        if re.match(pre_args_regex, source_lines[start_line_ix]):
            found = True
            break
    if not found:
        print_error("Programmer error - Could not find the source line with"
                    + " a reference to function \"" + real_called_func_name
                    + "\".\n")
        return

    # Search forward through the source lines looking for a line whose
    # indentation is the same or less than the start line.  The end of our
    # composite line should be the line preceding that line.
    start_indent = get_line_indent(source_lines[start_line_ix])
    end_line_ix = line_ix
    for end_line_ix in range(line_ix + 1, len(source_lines)):
        if source_lines[end_line_ix].strip() == "":
            continue
        line_indent = get_line_indent(source_lines[end_line_ix])
        if line_indent <= start_indent:
            end_line_ix -= 1
            break
    if start_line_ix != 0:
        # Check to see whether the start line is a continuation of the prior
        # line?
        line_indent = get_line_indent(source_lines[start_line_ix - 1])
        if line_indent < start_indent:
            start_line_ix -= 1
            # Remove the backslash (continuation char).
            source_lines[start_line_ix] = re.sub(r"[ ]*\\([\r\n]$)",
                                                 " \\1",
                                                 source_lines[start_line_ix])

    # Join the start line through the end line into a composite line.
    composite_line = ''.join(map(str.strip,
                                 source_lines[start_line_ix:end_line_ix + 1]))
    # Insert one space after first "=" if there isn't one already.
    composite_line = re.sub("=[ ]*([^ ])", "= \\1", composite_line, 1)

    lvalue_regex = "[ ]*=[ ]+" + func_name_regex + ".*"
    lvalue_string = re.sub(lvalue_regex, "", composite_line)
    if lvalue_string == composite_line:
        # i.e. the regex did not match so there are no lvalues.
        lvalue_string = ""
    lvalues_list = list(filter(None, map(str.strip, lvalue_string.split(","))))
    try:
        lvalues = collections.OrderedDict()
    except AttributeError:
        # A non-ordered dict doesn't look as nice when printed but it will do.
        lvalues = {}
    ix = len(lvalues_list) * -1
    for lvalue in lvalues_list:
        lvalues[ix] = lvalue
        ix += 1
    lvalue_prefix_regex = "(.*=[ ]+)?"
    called_func_name_regex = lvalue_prefix_regex + func_name_regex +\
        "[ ]*\\(.*"
    called_func_name = re.sub(called_func_name_regex, "\\4", composite_line)
    arg_list_etc = "(" + re.sub(pre_args_regex, "", composite_line)
    if local_debug:
        print_varx("aliases", aliases, 0, debug_indent)
        print_varx("import_name_regex", import_name_regex, 0, debug_indent)
        print_varx("func_name_regex", func_name_regex, 0, debug_indent)
        print_varx("pre_args_regex", pre_args_regex, 0, debug_indent)
        print_varx("start_line_ix", start_line_ix, 0, debug_indent)
        print_varx("end_line_ix", end_line_ix, 0, debug_indent)
        print_varx("composite_line", composite_line, 0, debug_indent)
        print_varx("lvalue_regex", lvalue_regex, 0, debug_indent)
        print_varx("lvalue_string", lvalue_string, 0, debug_indent)
        print_varx("lvalues", lvalues, 0, debug_indent)
        print_varx("called_func_name_regex", called_func_name_regex, 0,
                   debug_indent)
        print_varx("called_func_name", called_func_name, 0, debug_indent)
        print_varx("arg_list_etc", arg_list_etc, 0, debug_indent)

    # Parse arg list...
    # Initialize...
    nest_level = -1
    arg_ix = 0
    args_list = [""]
    for ix in range(0, len(arg_list_etc)):
        char = arg_list_etc[ix]
        # Set the nest_level based on whether we've encounted a parenthesis.
        if char == "(":
            nest_level += 1
            if nest_level == 0:
                continue
        elif char == ")":
            nest_level -= 1
            if nest_level < 0:
                break

        # If we reach a comma at base nest level, we are done processing an
        # argument so we increment arg_ix and initialize a new args_list entry.
        if char == "," and nest_level == 0:
            arg_ix += 1
            args_list.append("")
            continue

        # For any other character, we append it it to the current arg list
        # entry.
        args_list[arg_ix] += char

    # Trim whitespace from each list entry.
    args_list = [arg.strip() for arg in args_list]

    if arg_num < 0:
        if abs(arg_num) > len(lvalues):
            argument = lvalues
        else:
            argument = lvalues[arg_num]
    elif arg_num == 0:
        argument = called_func_name
    else:
        if arg_num > len(args_list):
            argument = args_list
        else:
            argument = args_list[arg_num - 1]

    if local_debug:
        print_varx("args_list", args_list, 0, debug_indent)
        print_varx("argument", argument, 0, debug_indent)
        print_dashes(0, 120)

    return argument


def sprint_time(buffer=""):
    r"""
    Return the time in the following format.

    Example:

    The following python code...

    sys.stdout.write(sprint_time())
    sys.stdout.write("Hi.\n")

    Will result in the following type of output:

    #(CDT) 2016/07/08 15:25:35 - Hi.

    Example:

    The following python code...

    sys.stdout.write(sprint_time("Hi.\n"))

    Will result in the following type of output:

    #(CDT) 2016/08/03 17:12:05 - Hi.

    The following environment variables will affect the formatting as
    described:
    NANOSECONDS                     This will cause the time stamps to be
                                    precise to the microsecond (Yes, it
                                    probably should have been named
                                    MICROSECONDS but the convention was set
                                    long ago so we're sticking with it).
                                    Example of the output when environment
                                    variable NANOSECONDS=1.

    #(CDT) 2016/08/03 17:16:25.510469 - Hi.

    SHOW_ELAPSED_TIME               This will cause the elapsed time to be
                                    included in the output.  This is the
                                    amount of time that has elapsed since the
                                    last time this function was called.  The
                                    precision of the elapsed time field is
                                    also affected by the value of the
                                    NANOSECONDS environment variable.  Example
                                    of the output when environment variable
                                    NANOSECONDS=0 and SHOW_ELAPSED_TIME=1.

    #(CDT) 2016/08/03 17:17:40 -    0 - Hi.

    Example of the output when environment variable NANOSECONDS=1 and
    SHOW_ELAPSED_TIME=1.

    #(CDT) 2016/08/03 17:18:47.317339 -    0.000046 - Hi.

    Description of arguments.
    buffer                          This will be appended to the formatted
                                    time string.
    """

    global NANOSECONDS
    global SHOW_ELAPSED_TIME
    global sprint_time_last_seconds
    global last_seconds_ix

    seconds = time.time()
    loc_time = time.localtime(seconds)
    nanoseconds = "%0.6f" % seconds
    pos = nanoseconds.find(".")
    nanoseconds = nanoseconds[pos:]

    time_string = time.strftime("#(%Z) %Y/%m/%d %H:%M:%S", loc_time)
    if NANOSECONDS == "1":
        time_string = time_string + nanoseconds

    if SHOW_ELAPSED_TIME == "1":
        cur_time_seconds = seconds
        math_string = "%9.9f" % cur_time_seconds + " - " + "%9.9f" % \
            sprint_time_last_seconds[last_seconds_ix]
        elapsed_seconds = eval(math_string)
        if NANOSECONDS == "1":
            elapsed_seconds = "%11.6f" % elapsed_seconds
        else:
            elapsed_seconds = "%4i" % elapsed_seconds
        sprint_time_last_seconds[last_seconds_ix] = cur_time_seconds
        time_string = time_string + " - " + elapsed_seconds

    return time_string + " - " + buffer


def sprint_timen(buffer=""):
    r"""
    Append a line feed to the buffer, pass it to sprint_time and return the
    result.
    """

    return sprint_time(buffer + "\n")


def sprint_error(buffer=""):
    r"""
    Return a standardized error string.  This includes:
      - A time stamp
      - The "**ERROR**" string
      - The caller's buffer string.

    Example:

    The following python code...

    print(sprint_error("Oops.\n"))

    Will result in the following type of output:

    #(CDT) 2016/08/03 17:12:05 - **ERROR** Oops.

    Description of arguments.
    buffer                          This will be appended to the formatted
                                    error string.
    """

    return sprint_time() + "**ERROR** " + buffer


# Implement "constants" with functions.
def digit_length_in_bits():
    r"""
    Return the digit length in bits.
    """

    return 4


def word_length_in_digits():
    r"""
    Return the word length in digits.
    """

    return 8


def bit_length(number):
    r"""
    Return the bit length of the number.

    Description of argument(s):
    number                          The number to be analyzed.
    """

    if number < 0:
        # Convert negative numbers to positive and subtract one.  The
        # following example illustrates the reason for this:
        # Consider a single nibble whose signed values can range from -8 to 7
        # (0x8 to 0x7).  A value of 0x7 equals 0b0111.  Therefore, its length
        # in bits is 3.  Since the negative bit (i.e. 0b1000) is not set, the
        # value 7 clearly will fit in one nibble.  With -8 = 0x8 = 0b1000, you
        # have the smallest negative value that will fit.  Note that it
        # requires 3 bits of 0.  So by converting a number value of -8 to a
        # working_number of 7, this function can accurately calculate the
        # number of bits and therefore nibbles required to represent the
        # number in print.
        working_number = abs(number) - 1
    else:
        working_number = number

    # Handle the special case of the number 0.
    if working_number == 0:
        return 0

    return len(bin(working_number)) - 2


def get_req_num_hex_digits(number):
    r"""
    Return the required number of hex digits required to display the given
    number.

    The returned value will always be rounded up to the nearest multiple of 8.

    Description of argument(s):
    number                          The number to be analyzed.
    """

    if number < 0:
        # Convert negative numbers to positive and subtract one.  The
        # following example illustrates the reason for this:
        # Consider a single nibble whose signed values can range from -8 to 7
        # (0x8 to 0x7).  A value of 0x7 equals 0b0111.  Therefore, its length
        # in bits is 3.  Since the negative bit (i.e. 0b1000) is not set, the
        # value 7 clearly will fit in one nibble.  With -8 = 0x8 = 0b1000, you
        # have the smallest negative value that will fit.  Note that it
        # requires 3 bits of 0.  So by converting a number value of -8 to a
        # working_number of 7, this function can accurately calculate the
        # number of bits and therefore nibbles required to represent the
        # number in print.
        working_number = abs(number) - 1
    else:
        working_number = number

    # Handle the special case of the number 0.
    if working_number == 0:
        return word_length_in_digits()

    num_length_in_bits = bit_length(working_number)
    num_hex_digits, remainder = divmod(num_length_in_bits,
                                       digit_length_in_bits())
    if remainder > 0:
        # Example: the number 7 requires 3 bits.  The divmod above produces,
        # 0 with remainder of 3.  So because we have a remainder, we increment
        # num_hex_digits from 0 to 1.
        num_hex_digits += 1

    # Check to see whether the negative bit is set.  This is the left-most
    # bit in the highest order digit.
    negative_mask = 2 ** (num_hex_digits * 4 - 1)
    if working_number & negative_mask:
        # If a number that is intended to be positive has its negative bit
        # on, an additional digit will be required to represent it correctly
        # in print.
        num_hex_digits += 1

    num_words, remainder = divmod(num_hex_digits, word_length_in_digits())
    if remainder > 0 or num_words == 0:
        num_words += 1

    # Round up to the next word length in digits.
    return num_words * word_length_in_digits()


def dft_num_hex_digits():
    r"""
    Return the default number of hex digits to be used to represent a hex
    number in print.

    The value returned is a function of sys.maxsize.
    """

    global _gen_print_dft_num_hex_digits_
    try:
        return _gen_print_dft_num_hex_digits_
    except NameError:
        _gen_print_dft_num_hex_digits_ = get_req_num_hex_digits(sys.maxsize)
        return _gen_print_dft_num_hex_digits_


def sprint_varx(var_name,
                var_value,
                hex=0,
                loc_col1_indent=col1_indent,
                loc_col1_width=col1_width,
                trailing_char="\n",
                key_list=None):
    r"""
    Print the var name/value passed to it.  If the caller lets loc_col1_width
    default, the printing lines up nicely with output generated by the
    print_time functions.

    Note that the sprint_var function (defined below) can be used to call this
    function so that the programmer does not need to pass the var_name.
    sprint_var will figure out the var_name.  The sprint_var function is the
    one that would normally be used by the general user.

    For example, the following python code:

    first_name = "Mike"
    print_time("Doing this...\n")
    print_varx("first_name", first_name)
    print_time("Doing that...\n")

    Will generate output like this:

    #(CDT) 2016/08/10 17:34:42.847374 -    0.001285 - Doing this...
    first_name:                                       Mike
    #(CDT) 2016/08/10 17:34:42.847510 -    0.000136 - Doing that...

    This function recognizes several complex types of data such as dict, list
    or tuple.

    For example, the following python code:

    my_dict = dict(one=1, two=2, three=3)
    print_var(my_dict)

    Will generate the following output:

    my_dict:
      my_dict[three]:                                 3
      my_dict[two]:                                   2
      my_dict[one]:                                   1

    Description of arguments.
    var_name                        The name of the variable to be printed.
    var_value                       The value of the variable to be printed.
    hex                             This indicates that the value should be
                                    printed in hex format.  It is the user's
                                    responsibility to ensure that a var_value
                                    contains a valid hex number.  For string
                                    var_values, this will be interpreted as
                                    show_blanks which means that blank values
                                    will be printed as "<blank>".  For dict
                                    var_values, this will be interpreted as
                                    terse format where keys are not repeated
                                    in the output.
    loc_col1_indent                 The number of spaces to indent the output.
    loc_col1_width                  The width of the output column containing
                                    the variable name.  The default value of
                                    this is adjusted so that the var_value
                                    lines up with text printed via the
                                    print_time function.
    trailing_char                   The character to be used at the end of the
                                    returned string.  The default value is a
                                    line feed.
    key_list                        A list of which dictionary keys should be
                                    printed.  All others keys will be skipped.
                                    Each value in key_list will be regarded
                                    as a regular expression and it will be
                                    regarded as anchored to the beginning and
                                    ends of the dictionary key being
                                    referenced.  For example if key_list is
                                    ["one", "two"], the resulting regex used
                                    will be "^one|two$", i.e. only keys "one"
                                    and "two" from the var_value dictionary
                                    will be printed.  As another example, if
                                    the caller were to specify a key_list of
                                    ["one.*"], then only dictionary keys whose
                                    names begin with "one" will be printed.
                                    Note: This argument pertains only to
                                    var_values which are dictionaries.
    """

    # Determine the type
    try:
        int_types = (int, long)
    except NameError:
        int_types = (int,)
    try:
        string_types = (str, unicode)
    except NameError:
        string_types = (str,)
    simple_types = int_types + string_types + (float, bool)
    if type(var_value) in simple_types \
       or var_value is None:
        # The data type is simple in the sense that it has no subordinate
        # parts.
        # Adjust loc_col1_width.
        loc_col1_width = loc_col1_width - loc_col1_indent
        # See if the user wants the output in hex format.
        if hex:
            if type(var_value) not in int_types:
                value_format = "%s"
                if var_value == "":
                    var_value = "<blank>"
            else:
                num_hex_digits = max(dft_num_hex_digits(),
                                     get_req_num_hex_digits(var_value))
                # Convert a negative number to its positive twos complement
                # for proper printing.  For example, instead of printing -1 as
                # "0x-000000000000001" it will be printed as
                # "0xffffffffffffffff".
                var_value = var_value & (2 ** (num_hex_digits * 4) - 1)
                value_format = "0x%0" + str(num_hex_digits) + "x"
        else:
            value_format = "%s"
        format_string = "%" + str(loc_col1_indent) + "s%-" \
            + str(loc_col1_width) + "s" + value_format + trailing_char
        if value_format == "0x%08x":
            return format_string % ("", str(var_name) + ":",
                                    var_value & 0xffffffff)
        else:
            return format_string % ("", str(var_name) + ":", var_value)
    elif isinstance(var_value, type):
        return sprint_varx(var_name, str(var_value).split("'")[1], hex,
                           loc_col1_indent, loc_col1_width, trailing_char,
                           key_list)
    else:
        # The data type is complex in the sense that it has subordinate parts.
        format_string = "%" + str(loc_col1_indent) + "s%s\n"
        buffer = format_string % ("", var_name + ":")
        loc_col1_indent += 2
        try:
            length = len(var_value)
        except TypeError:
            length = 0
        ix = 0
        loc_trailing_char = "\n"
        type_is_dict = 0
        if isinstance(var_value, dict):
            type_is_dict = 1
        try:
            if isinstance(var_value, collections.OrderedDict):
                type_is_dict = 1
        except AttributeError:
            pass
        try:
            if isinstance(var_value, DotDict):
                type_is_dict = 1
        except NameError:
            pass
        try:
            if isinstance(var_value, NormalizedDict):
                type_is_dict = 1
        except NameError:
            pass
        if type_is_dict:
            for key, value in var_value.items():
                if key_list is not None:
                    key_list_regex = "^" + "|".join(key_list) + "$"
                    if not re.match(key_list_regex, key):
                        continue
                ix += 1
                if ix == length:
                    loc_trailing_char = trailing_char
                if hex:
                    # Since hex is being used as a format type, we want it
                    # turned off when processing integer dictionary values so
                    # it is not interpreted as a hex indicator.
                    loc_hex = not (isinstance(value, int))
                    buffer += sprint_varx("[" + key + "]", value,
                                          loc_hex, loc_col1_indent,
                                          loc_col1_width,
                                          loc_trailing_char,
                                          key_list)
                else:
                    buffer += sprint_varx(var_name + "[" + str(key) + "]",
                                          value, hex, loc_col1_indent,
                                          loc_col1_width, loc_trailing_char,
                                          key_list)
        elif type(var_value) in (list, tuple, set):
            for key, value in enumerate(var_value):
                ix += 1
                if ix == length:
                    loc_trailing_char = trailing_char
                buffer += sprint_varx(var_name + "[" + str(key) + "]", value,
                                      hex, loc_col1_indent, loc_col1_width,
                                      loc_trailing_char, key_list)
        elif isinstance(var_value, argparse.Namespace):
            for key in var_value.__dict__:
                ix += 1
                if ix == length:
                    loc_trailing_char = trailing_char
                cmd_buf = "buffer += sprint_varx(var_name + \".\" + str(key)" \
                          + ", var_value." + key + ", hex, loc_col1_indent," \
                          + " loc_col1_width, loc_trailing_char, key_list)"
                exec(cmd_buf)
        else:
            var_type = type(var_value).__name__
            func_name = sys._getframe().f_code.co_name
            var_value = "<" + var_type + " type not supported by " + \
                        func_name + "()>"
            value_format = "%s"
            loc_col1_indent -= 2
            # Adjust loc_col1_width.
            loc_col1_width = loc_col1_width - loc_col1_indent
            format_string = "%" + str(loc_col1_indent) + "s%-" \
                + str(loc_col1_width) + "s" + value_format + trailing_char
            return format_string % ("", str(var_name) + ":", var_value)

        return buffer

    return ""


def sprint_var(var_value,
               hex=0,
               loc_col1_indent=col1_indent,
               loc_col1_width=col1_width,
               trailing_char="\n",
               key_list=None):
    r"""
    Figure out the name of the first argument for you and then call
    sprint_varx with it.  Therefore, the following 2 calls are equivalent:
    sprint_varx("var1", var1)
    sprint_var(var1)
    """

    # Get the name of the first variable passed to this function.
    stack_frame = 2
    caller_func_name = sprint_func_name(2)
    if caller_func_name.endswith("print_var"):
        stack_frame += 1
    var_name = get_arg_name(None, 1, stack_frame)
    return sprint_varx(var_name, var_value=var_value, hex=hex,
                       loc_col1_indent=loc_col1_indent,
                       loc_col1_width=loc_col1_width,
                       trailing_char=trailing_char,
                       key_list=key_list)


def sprint_vars(*args):
    r"""
    Sprint the values of one or more variables.

    Description of args:
    args:
        If the first argument is an integer, it will be interpreted to be the
        "indent" value.
        If the second argument is an integer, it will be interpreted to be the
        "col1_width" value.
        If the third argument is an integer, it will be interpreted to be the
        "hex" value.
        All remaining parms are considered variable names which are to be
        sprinted.
    """

    if len(args) == 0:
        return

    # Get the name of the first variable passed to this function.
    stack_frame = 2
    caller_func_name = sprint_func_name(2)
    if caller_func_name.endswith("print_vars"):
        stack_frame += 1

    parm_num = 1

    # Create list from args (which is a tuple) so that it can be modified.
    args_list = list(args)

    var_name = get_arg_name(None, parm_num, stack_frame)
    # See if parm 1 is to be interpreted as "indent".
    try:
        if isinstance(int(var_name), int):
            indent = int(var_name)
            args_list.pop(0)
            parm_num += 1
    except ValueError:
        indent = 0

    var_name = get_arg_name(None, parm_num, stack_frame)
    # See if parm 1 is to be interpreted as "col1_width".
    try:
        if isinstance(int(var_name), int):
            loc_col1_width = int(var_name)
            args_list.pop(0)
            parm_num += 1
    except ValueError:
        loc_col1_width = col1_width

    var_name = get_arg_name(None, parm_num, stack_frame)
    # See if parm 1 is to be interpreted as "hex".
    try:
        if isinstance(int(var_name), int):
            hex = int(var_name)
            args_list.pop(0)
            parm_num += 1
    except ValueError:
        hex = 0

    buffer = ""
    for var_value in args_list:
        var_name = get_arg_name(None, parm_num, stack_frame)
        buffer += sprint_varx(var_name, var_value, hex, indent, loc_col1_width)
        parm_num += 1

    return buffer


def sprint_dashes(indent=col1_indent,
                  width=80,
                  line_feed=1,
                  char="-"):
    r"""
    Return a string of dashes to the caller.

    Description of arguments:
    indent                          The number of characters to indent the
                                    output.
    width                           The width of the string of dashes.
    line_feed                       Indicates whether the output should end
                                    with a line feed.
    char                            The character to be repeated in the output
                                    string.
    """

    width = int(width)
    buffer = " " * int(indent) + char * width
    if line_feed:
        buffer += "\n"

    return buffer


def sindent(text="",
            indent=0):
    r"""
    Pre-pend the specified number of characters to the text string (i.e.
    indent it) and return it.

    Description of arguments:
    text                            The string to be indented.
    indent                          The number of characters to indent the
                                    string.
    """

    format_string = "%" + str(indent) + "s%s"
    buffer = format_string % ("", text)

    return buffer


def sprint_call_stack(indent=0,
                      stack_frame_ix=0):
    r"""
    Return a call stack report for the given point in the program with line
    numbers, function names and function parameters and arguments.

    Sample output:

    -------------------------------------------------------------------------
    Python function call stack

    Line # Function name and arguments
    ------ ------------------------------------------------------------------
       424 sprint_call_stack ()
         4 print_call_stack ()
        31 func1 (last_name = 'walsh', first_name = 'mikey')
        59 /tmp/scr5.py
    -------------------------------------------------------------------------

    Description of arguments:
    indent                          The number of characters to indent each
                                    line of output.
    stack_frame_ix                  The index of the first stack frame which
                                    is to be returned.
    """

    buffer = ""
    buffer += sprint_dashes(indent)
    buffer += sindent("Python function call stack\n\n", indent)
    buffer += sindent("Line # Function name and arguments\n", indent)
    buffer += sprint_dashes(indent, 6, 0) + " " + sprint_dashes(0, 73)

    # Grab the current program stack.
    current_stack = inspect.stack()

    # Process each frame in turn.
    format_string = "%6s %s\n"
    ix = 0
    for stack_frame in current_stack:
        if ix < stack_frame_ix:
            ix += 1
            continue
        # I want the line number shown to be the line where you find the line
        # shown.
        try:
            line_num = str(current_stack[ix + 1][2])
        except IndexError:
            line_num = ""
        func_name = str(stack_frame[3])
        if func_name == "?":
            # "?" is the name used when code is not in a function.
            func_name = "(none)"

        if func_name == "<module>":
            # If the func_name is the "main" program, we simply get the
            # command line call string.
            func_and_args = ' '.join(sys.argv)
        else:
            # Get the program arguments.
            arg_vals = inspect.getargvalues(stack_frame[0])
            function_parms = arg_vals[0]
            frame_locals = arg_vals[3]

            args_list = []
            for arg_name in function_parms:
                # Get the arg value from frame locals.
                arg_value = frame_locals[arg_name]
                args_list.append(arg_name + " = " + repr(arg_value))
            args_str = "(" + ', '.join(map(str, args_list)) + ")"

            # Now we need to print this in a nicely-wrapped way.
            func_and_args = func_name + " " + args_str

        buffer += sindent(format_string % (line_num, func_and_args), indent)
        ix += 1

    buffer += sprint_dashes(indent)

    return buffer


def sprint_executing(stack_frame_ix=None):
    r"""
    Print a line indicating what function is executing and with what parameter
    values.  This is useful for debugging.

    Sample output:

    #(CDT) 2016/08/25 17:54:27 - Executing: func1 (x = 1)

    Description of arguments:
    stack_frame_ix                  The index of the stack frame whose
                                    function info should be returned.  If the
                                    caller does not specify a value, this
                                    function will set the value to 1 which is
                                    the index of the caller's stack frame.  If
                                    the caller is the wrapper function
                                    "print_executing", this function will bump
                                    it up by 1.
    """

    # If user wants default stack_frame_ix.
    if stack_frame_ix is None:
        func_name = sys._getframe().f_code.co_name
        caller_func_name = sys._getframe(1).f_code.co_name
        if caller_func_name.endswith(func_name[1:]):
            stack_frame_ix = 2
        else:
            stack_frame_ix = 1

    stack_frame = inspect.stack()[stack_frame_ix]

    func_name = str(stack_frame[3])
    if func_name == "?":
        # "?" is the name used when code is not in a function.
        func_name = "(none)"

    if func_name == "<module>":
        # If the func_name is the "main" program, we simply get the command
        # line call string.
        func_and_args = ' '.join(sys.argv)
    else:
        # Get the program arguments.
        arg_vals = inspect.getargvalues(stack_frame[0])
        function_parms = arg_vals[0]
        frame_locals = arg_vals[3]

        args_list = []
        for arg_name in function_parms:
            # Get the arg value from frame locals.
            arg_value = frame_locals[arg_name]
            args_list.append(arg_name + " = " + repr(arg_value))
        args_str = "(" + ', '.join(map(str, args_list)) + ")"

        # Now we need to print this in a nicely-wrapped way.
        func_and_args = func_name + " " + args_str

    return sprint_time() + "Executing: " + func_and_args + "\n"


def sprint_pgm_header(indent=0,
                      linefeed=1):
    r"""
    Return a standardized header that programs should print at the beginning
    of the run.  It includes useful information like command line, pid,
    userid, program parameters, etc.

    Description of arguments:
    indent                          The number of characters to indent each
                                    line of output.
    linefeed                        Indicates whether a line feed be included
                                    at the beginning and end of the report.
    """

    loc_col1_width = col1_width + indent

    buffer = ""
    if linefeed:
        buffer = "\n"

    if robot_env:
        suite_name = BuiltIn().get_variable_value("${suite_name}")
        buffer += sindent(sprint_time("Running test suite \"" + suite_name
                                      + "\".\n"), indent)

    buffer += sindent(sprint_time() + "Running " + pgm_name + ".\n", indent)
    buffer += sindent(sprint_time() + "Program parameter values, etc.:\n\n",
                      indent)
    buffer += sprint_varx("command_line", ' '.join(sys.argv), 0, indent,
                          loc_col1_width)
    # We want the output to show a customized name for the pid and pgid but
    # we want it to look like a valid variable name.  Therefore, we'll use
    # pgm_name_var_name which was set when this module was imported.
    buffer += sprint_varx(pgm_name_var_name + "_pid", os.getpid(), 0, indent,
                          loc_col1_width)
    buffer += sprint_varx(pgm_name_var_name + "_pgid", os.getpgrp(), 0, indent,
                          loc_col1_width)
    userid_num = str(os.geteuid())
    try:
        username = os.getlogin()
    except OSError:
        if userid_num == "0":
            username = "root"
        else:
            username = "?"
    buffer += sprint_varx("uid", userid_num + " (" + username
                          + ")", 0, indent, loc_col1_width)
    buffer += sprint_varx("gid", str(os.getgid()) + " ("
                          + str(grp.getgrgid(os.getgid()).gr_name) + ")", 0,
                          indent, loc_col1_width)
    buffer += sprint_varx("host_name", socket.gethostname(), 0, indent,
                          loc_col1_width)
    try:
        DISPLAY = os.environ['DISPLAY']
    except KeyError:
        DISPLAY = ""
    buffer += sprint_varx("DISPLAY", DISPLAY, 0, indent,
                          loc_col1_width)
    # I want to add code to print caller's parms.

    # __builtin__.arg_obj is created by the get_arg module function,
    # gen_get_options.
    try:
        buffer += ga.sprint_args(__builtin__.arg_obj, indent)
    except AttributeError:
        pass

    if robot_env:
        # Get value of global parm_list.
        parm_list = BuiltIn().get_variable_value("${parm_list}")

        for parm in parm_list:
            parm_value = BuiltIn().get_variable_value("${" + parm + "}")
            buffer += sprint_varx(parm, parm_value, 0, indent, loc_col1_width)

        # Setting global program_pid.
        BuiltIn().set_global_variable("${program_pid}", os.getpid())

    if linefeed:
        buffer += "\n"

    return buffer


def sprint_error_report(error_text="\n",
                        indent=2,
                        format=None):
    r"""
    Return a string with a standardized report which includes the caller's
    error text, the call stack and the program header.

    Description of args:
    error_text                      The error text to be included in the
                                    report.  The caller should include any
                                    needed linefeeds.
    indent                          The number of characters to indent each
                                    line of output.
    format                          Long or short format.  Long includes
                                    extras like lines of dashes, call stack,
                                    etc.
    """

    # Process input.
    indent = int(indent)
    if format is None:
        if robot_env:
            format = 'short'
        else:
            format = 'long'
    error_text = error_text.rstrip('\n') + '\n'

    if format == 'short':
        return sprint_error(error_text)

    buffer = ""
    buffer += sprint_dashes(width=120, char="=")
    buffer += sprint_error(error_text)
    buffer += "\n"
    # Calling sprint_call_stack with stack_frame_ix of 0 causes it to show
    # itself and this function in the call stack.  This is not helpful to a
    # debugger and is therefore clutter.  We will adjust the stack_frame_ix to
    # hide that information.
    stack_frame_ix = 1
    caller_func_name = sprint_func_name(2)
    if caller_func_name.endswith("print_error_report"):
        stack_frame_ix += 1
    if not robot_env:
        buffer += sprint_call_stack(indent, stack_frame_ix)
    buffer += sprint_pgm_header(indent)
    buffer += sprint_dashes(width=120, char="=")

    return buffer


def sprint_issuing(cmd_buf,
                   test_mode=0):
    r"""
    Return a line indicating a command that the program is about to execute.

    Sample output for a cmd_buf of "ls"

    #(CDT) 2016/08/25 17:57:36 - Issuing: ls

    Description of args:
    cmd_buf                         The command to be executed by caller.
    test_mode                       With test_mode set, your output will look
                                    like this:

    #(CDT) 2016/08/25 17:57:36 - (test_mode) Issuing: ls

    """

    buffer = sprint_time()
    if test_mode:
        buffer += "(test_mode) "
    buffer += "Issuing: " + cmd_buf + "\n"

    return buffer


def sprint_pgm_footer():
    r"""
    Return a standardized footer that programs should print at the end of the
    program run.  It includes useful information like total run time, etc.
    """

    buffer = "\n" + sprint_time() + "Finished running " + pgm_name + ".\n\n"

    total_time = time.time() - start_time
    total_time_string = "%0.6f" % total_time

    buffer += sprint_varx(pgm_name_var_name + "_runtime", total_time_string)
    buffer += "\n"

    return buffer


def sprint(buffer=""):
    r"""
    Simply return the user's buffer.  This function is used by the qprint and
    dprint functions defined dynamically below, i.e. it would not normally be
    called for general use.

    Description of arguments.
    buffer                          This will be returned to the caller.
    """

    try:
        return str(buffer)
    except UnicodeEncodeError:
        return buffer


def sprintn(buffer=""):
    r"""
    Simply return the user's buffer with a line feed.  This function is used
    by the qprint and dprint functions defined dynamically below, i.e. it
    would not normally be called for general use.

    Description of arguments.
    buffer                          This will be returned to the caller.
    """

    try:
        buffer = str(buffer) + "\n"
    except UnicodeEncodeError:
        buffer = buffer + "\n"

    return buffer


def gp_print(buffer,
             stream='stdout'):
    r"""
    Print the buffer using either sys.stdout.write or BuiltIn().log_to_console
    depending on whether we are running in a robot environment.

    This function is intended for use only by other functions in this module.

    Description of arguments:
    buffer                          The string to be printed.
    stream                          Either "stdout" or "stderr".
    """

    if robot_env:
        BuiltIn().log_to_console(buffer, stream=stream, no_newline=True)
    else:
        if stream == "stdout":
            sys.stdout.write(buffer)
            sys.stdout.flush()
        else:
            sys.stderr.write(buffer)
            sys.stderr.flush()


def gp_log(buffer):
    r"""
    Log the buffer using either python logging or BuiltIn().log depending on
    whether we are running in a robot environment.

    This function is intended for use only by other functions in this module.

    Description of arguments:
    buffer                          The string to be logged.
    """

    if robot_env:
        BuiltIn().log(buffer)
    else:
        logging.warning(buffer)


def gp_debug_print(buffer):
    r"""
    Print with gp_print only if gen_print_debug is set.

    This function is intended for use only by other functions in this module.

    Description of arguments:
    buffer                          The string to be printed.
    """

    if not gen_print_debug:
        return

    gp_print(buffer)


def get_var_value(var_value=None,
                  default=1,
                  var_name=None):
    r"""
    Return either var_value, the corresponding global value or default.

    If var_value is not None, it will simply be returned.

    If var_value is None, this function will return the corresponding global
    value of the variable in question.

    Note: For global values, if we are in a robot environment,
    get_variable_value will be used.  Otherwise, the __builtin__ version of
    the variable is returned (which are set by gen_arg.py functions).

    If there is no global value associated with the variable, default is
    returned.

    This function is useful for other functions in setting default values for
    parameters.

    Example use:

    def my_func(quiet=None):

      quiet = int(get_var_value(quiet, 0))

    Example calls to my_func():

    In the following example, the caller is explicitly asking to have quiet be
    set to 1.

    my_func(quiet=1)

    In the following example, quiet will be set to the global value of quiet,
    if defined, or to 0 (the default).

    my_func()

    Description of arguments:
    var_value                       The value to be returned (if not equal to
                                    None).
    default                         The value that is returned if var_value is
                                    None and there is no corresponding global
                                    value defined.
    var_name                        The name of the variable whose value is to
                                    be returned.  Under most circumstances,
                                    this value need not be provided.  This
                                    function can figure out the name of the
                                    variable passed as var_value.  One
                                    exception to this would be if this
                                    function is called directly from a .robot
                                    file.
    """

    if var_value is not None:
        return var_value

    if var_name is None:
        var_name = get_arg_name(None, 1, 2)

    if robot_env:
        var_value = BuiltIn().get_variable_value("${" + var_name + "}",
                                                 default)
    else:
        var_value = getattr(__builtin__, var_name, default)

    return var_value


def get_stack_var(var_name,
                  default="",
                  init_stack_ix=2):
    r"""
    Starting with the caller's stack level, search upward in the call stack,
    for a variable named var_name and return its value.  If the variable
    cannot be found, return default.

    Example code:

    def func12():
        my_loc_var1 = get_stack_var('my_var1', "default value")

    def func11():
        my_var1 = 11
        func12()

    In this example, get_stack_var will find the value of my_var1 in func11's
    stack and will therefore return the value 11.  Therefore, my_loc_var1
    would get set to 11.

    Description of argument(s):
    var_name                        The name of the variable to be searched
                                    for.
    default                         The value to return if the the variable
                                    cannot be found.
    init_stack_ix                   The initial stack index from which to
                                    begin the search.  0 would be the index of
                                    this func1tion ("get_stack_var"), 1 would
                                    be the index of the function calling this
                                    function, etc.
    """

    return next((frame[0].f_locals[var_name]
                 for frame in inspect.stack()[init_stack_ix:]
                 if var_name in frame[0].f_locals), default)


# hidden_text is a list of passwords which are to be replaced with asterisks
# by print functions defined in this module.
hidden_text = []
# password_regex is created based on the contents of hidden_text.
password_regex = ""


def register_passwords(*args):
    r"""
    Register one or more passwords which are to be hidden in output produced
    by the print functions in this module.

    Note:  Blank password values are NOT registered.  They are simply ignored.

    Description of argument(s):
    args                            One or more password values.  If a given
                                    password value is already registered, this
                                    function will simply do nothing.
    """

    global hidden_text
    global password_regex

    for password in args:
        if password == "":
            break
        if password in hidden_text:
            break

        # Place the password into the hidden_text list.
        hidden_text.append(password)
        # Create a corresponding password regular expression.  Escape regex
        # special characters too.
        password_regex = '(' +\
            '|'.join([re.escape(x) for x in hidden_text]) + ')'


def replace_passwords(buffer):
    r"""
    Return the buffer but with all registered passwords replaced by a string
    of asterisks.


    Description of argument(s):
    buffer                          The string to be returned but with
                                    passwords replaced.
    """

    global password_regex

    if int(os.environ.get("DEBUG_SHOW_PASSWORDS", "0")):
        return buffer

    if password_regex == "":
        # No passwords to replace.
        return buffer

    return re.sub(password_regex, "********", buffer)


def create_print_wrapper_funcs(func_names,
                               stderr_func_names,
                               replace_dict):
    r"""
    Generate code for print wrapper functions and return the generated code as
    a string.

    To illustrate, suppose there is a "print_foo_bar" function in the
    func_names list.
    This function will...
    - Expect that there is an sprint_foo_bar function already in existence.
    - Create a print_foo_bar function which calls sprint_foo_bar and prints
      the result.
    - Create a qprint_foo_bar function which calls upon sprint_foo_bar only if
      global value quiet is 0.
    - Create a dprint_foo_bar function which calls upon sprint_foo_bar only if
      global value debug is 1.

    Also, code will be generated to define aliases for each function as well.
    Each alias will be created by replacing "print_" in the function name with
    "p"  For example, the alias for print_foo_bar will be pfoo_bar.

    Description of argument(s):
    func_names                      A list of functions for which print
                                    wrapper function code is to be generated.
    stderr_func_names               A list of functions whose generated code
                                    should print to stderr rather than to
                                    stdout.
    replace_dict                    Please see the create_func_def_string
                                    function in wrap_utils.py for details on
                                    this parameter.  This parameter will be
                                    passed directly to create_func_def_string.
    """

    buffer = ""

    for func_name in func_names:
        if func_name in stderr_func_names:
            replace_dict['output_stream'] = "stderr"
        else:
            replace_dict['output_stream'] = "stdout"

        s_func_name = "s" + func_name
        q_func_name = "q" + func_name
        d_func_name = "d" + func_name

        # We don't want to try to redefine the "print" function, thus the
        # following if statement.
        if func_name != "print":
            func_def = create_func_def_string(s_func_name, func_name,
                                              print_func_template,
                                              replace_dict)
            buffer += func_def

        func_def = create_func_def_string(s_func_name, "q" + func_name,
                                          qprint_func_template, replace_dict)
        buffer += func_def

        func_def = create_func_def_string(s_func_name, "d" + func_name,
                                          dprint_func_template, replace_dict)
        buffer += func_def

        func_def = create_func_def_string(s_func_name, "l" + func_name,
                                          lprint_func_template, replace_dict)
        buffer += func_def

        # Create abbreviated aliases (e.g. spvar is an alias for sprint_var).
        alias = re.sub("print_", "p", func_name)
        alias = re.sub("print", "p", alias)
        prefixes = ["", "s", "q", "d", "l"]
        for prefix in prefixes:
            if alias == "p":
                continue
            func_def = prefix + alias + " = " + prefix + func_name
            buffer += func_def + "\n"

    return buffer


# In the following section of code, we will dynamically create print versions
# for each of the sprint functions defined above.  So, for example, where we
# have an sprint_time() function defined above that returns the time to the
# caller in a string, we will create a corresponding print_time() function
# that will print that string directly to stdout.

# It can be complicated to follow what's being created by below.  Here is an
# example of the print_time() function that will be created:

# def print_time(buffer=''):
#     sys.stdout.write(replace_passwords(sprint_time(buffer=buffer)))
#     sys.stdout.flush()

# Templates for the various print wrapper functions.
print_func_template = \
    [
        "    <mod_qualifier>gp_print(<mod_qualifier>replace_passwords("
        + "<call_line>), stream='<output_stream>')"
    ]

qprint_func_template = \
    [
        "    if int(<mod_qualifier>get_var_value(None, 0, \"quiet\")): return"
    ] + print_func_template

dprint_func_template = \
    [
        "    if not int(<mod_qualifier>get_var_value(None, 0, \"debug\")):"
        + " return"
    ] + print_func_template

lprint_func_template = \
    [
        "    global sprint_time_last_seconds",
        "    global last_seconds_ix",
        "    if len(sprint_time_last_seconds) <= lprint_last_seconds_ix():",
        "        sprint_time_last_seconds.append(start_time)",
        "    save_last_seconds_ix = last_seconds_ix",
        "    last_seconds_ix = lprint_last_seconds_ix()",
        "    gp_log(<mod_qualifier>replace_passwords(<call_line>))",
        "    last_seconds_ix = save_last_seconds_ix",
    ]

replace_dict = {'output_stream': 'stdout', 'mod_qualifier': ''}


gp_debug_print("robot_env: " + str(robot_env))

# func_names contains a list of all print functions which should be created
# from their sprint counterparts.
func_names = ['print_time', 'print_timen', 'print_error', 'print_varx',
              'print_var', 'print_vars', 'print_dashes', 'indent',
              'print_call_stack', 'print_func_name', 'print_executing',
              'print_pgm_header', 'print_issuing', 'print_pgm_footer',
              'print_error_report', 'print', 'printn']

# stderr_func_names is a list of functions whose output should go to stderr
# rather than stdout.
stderr_func_names = ['print_error', 'print_error_report']


func_defs = create_print_wrapper_funcs(func_names, stderr_func_names,
                                       replace_dict)
gp_debug_print(func_defs)
exec(func_defs)
