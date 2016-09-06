#!/usr/bin/env python

# This module provides many valuable print functions such as sprint_var,
# sprint_time, sprint_error, sprint_call_stack.

import sys
import os
import time
import inspect
import re
import grp
import socket
import argparse

# Setting these variables for use both inside this module and by programs
# importing this module.
pgm_dir_path = sys.argv[0]
pgm_name = os.path.basename(pgm_dir_path)

# Some functions (e.g. sprint_pgm_header) have need of a program name value
# that looks more like a valid variable name.  Therefore, we'll swap odd
# characters like "." out for underscores.
pgm_name_var_name = pgm_name.replace(".", "_")

# Initialize global values used as defaults by print_time, print_var, etc.
col1_indent = 0

# Calculate default column width for print_var functions based on environment
# variable settings.  The objective is to make the variable values line up
# nicely with the time stamps.
col1_width = 29;
if 'NANOSECONDS' in os.environ: NANOSECONDS = os.environ['NANOSECONDS']
else: NANOSECONDS = 0

if ( NANOSECONDS == "1" ): col1_width = col1_width + 7

if 'SHOW_ELAPSED_TIME' in os.environ:
    SHOW_ELAPSED_TIME = os.environ['SHOW_ELAPSED_TIME']
else: SHOW_ELAPSED_TIME = 0

if ( SHOW_ELAPSED_TIME == "1" ):
    if ( NANOSECONDS == "1" ): col1_width = col1_width + 14
    else: col1_width = col1_width + 7

# Initialize some time variables used in module functions.
start_time = time.time()
sprint_time_last_seconds = start_time



################################################################################
def sprint_func_name(stack_frame_ix = None):

    # This function will return the name of the function associated with the
    # indicated stack frame.

    # Description of arguments:
    # stack_frame_ix               The index of the stack frame whose function
    #                              name should be returned.  If the caller does
    #                              not specifiy a value, this function will set
    #                              the value to 1 which is the index of the
    #                              caller's stack frame.  If the caller is the
    #                              wrapper function "print_func_name", this
    #                              function will bump it up by 1.

    # If user specified no stack_frame_ix, we'll set it to a proper default
    # value.
    if stack_frame_ix == None:
        func_name = sys._getframe().f_code.co_name
        caller_func_name = sys._getframe(1).f_code.co_name
        if func_name[1:] == caller_func_name: stack_frame_ix = 2
        else: stack_frame_ix = 1

    func_name = sys._getframe(stack_frame_ix).f_code.co_name

    return func_name

################################################################################



# get_arg_name is not a print function per se.  I have included it in this
# module because it is used by sprint_var which is found in this module.
################################################################################
def get_arg_name(var,
                 arg_num = 1,
                 stack_frame_ix = 1):

    # This function will return the "name" of an argument passed to a function.
    # This could be a literal or a variable name.

    # Description of arguements:
    # var                          The variable whose name you want returned.
    # arg_num                      The arg number (1 through n) whose name you
    #                              wish to have returned.  This value should not
    #                              exceed the number of arguments allowed by the
    #                              target function.
    # stack_frame_ix               The stack frame index of the target function.
    #                              This value must be 1 or greater.  1 would
    #                              indicate get_arg_name's stack frame.  2 would
    #                              be the caller of get_arg_name's stack frame,
    #                              etc.

    # Example 1:
    #
    # my_var = "mike"
    # var_name = get_arg_name(my_var)
    #
    # In this example, var_name will receive the value "my_var".
    #
    # Example 2:
    #
    # def test1(var):
    #   # Getting the var name of the first arg to this function, test1.  Note,
    #   # in this case, it doesn't matter what you pass as the first arg to
    #   # get_arg_name since it is the caller's variable name that matters.
    #   dummy = 1
    #   arg_num = 1
    #   stack_frame = 2
    #   var_name = get_arg_name(dummy, arg_num, stack_frame)
    #
    # Mainline
    #
    # another_var = "whatever"
    # test1(another_var)
    #
    # In this example, var_name will be set to "another_var".

    # Note: I wish to avoid recursion so I refrain from calling any function
    # that calls this function (i.e. sprint_var, valid_value, etc.).

    try:
    # The user can set environment variable "GET_ARG_NAME_DEBUG" to get debug
    # output from this function.
        local_debug = os.environ['GET_ARG_NAME_DEBUG']
    except KeyError:
        local_debug = 0

    if arg_num < 1:
        print_error("Programmer error - Variable \"arg_num\" has an invalid"
            + " value of \"" + str(arg_num) + "\".  The value must be an"
            + " integer that is greater than 0.\n")
        # What is the best way to handle errors?  Raise exception?  I'll
        # revisit later.
        return
    if stack_frame_ix < 1:
        print_error("Programmer error - Variable \"stack_frame_ix\" has an"
            + " invalid value of \"" + str(stack_frame_ix) + "\".  The value"
            + " must be an integer that is greater than or equal to 1.\n")
        return

    if local_debug:
        debug_indent = 2
        print(sprint_func_name() + "() parms:")
        print_varx("var", var, 0, debug_indent)
        print_varx("arg_num", arg_num, 0, debug_indent)
        print_varx("stack_frame_ix", stack_frame_ix, 0, debug_indent)

    try:
        frame, filename, cur_line_no, function_name, lines, index = \
            inspect.stack()[stack_frame_ix]
    except IndexError:
        print_error("Programmer error - The caller has asked for information"
            + " about the stack frame at index \"" + str(stack_frame_ix)
            + "\".  However, the stack only contains "
            + str(len(inspect.stack())) + " entries.  Therefore the stack frame"
            + " index is out of range.\n" )
        return

    if local_debug:
        print("\nVariables retrieved from inspect.stack() function:")
        print_varx("frame", frame, 0, debug_indent)
        print_varx("filename", filename, 0, debug_indent)
        print_varx("cur_line_no", cur_line_no, 0, debug_indent)
        print_varx("function_name", function_name, 0, debug_indent)
        print_varx("lines", lines, 0, debug_indent)
        print_varx("index", index, 0, debug_indent)

    composite_line = lines[0].strip()

    called_func_name = sprint_func_name(stack_frame_ix)
    # 2016/09/01 Mike Walsh (xzy0065) - I added code to handle pvar alias.
    # pvar is an alias for print_var.  However, when it is used,
    # sprint_func_name() returns the non-alias version, i.e. "print_var".
    # Adjusting for that here.
    substring = composite_line[0:4]
    if substring == "pvar": called_func_name = "pvar"
    arg_list_etc = re.sub(".*" + called_func_name, "", composite_line)
    if local_debug:
        print_varx("called_func_name", called_func_name, 0, debug_indent)
        print_varx("composite_line", composite_line, 0, debug_indent)
        print_varx("arg_list_etc", arg_list_etc, 0, debug_indent)

    # Parse arg list...
    # Initialize...
    nest_level = -1
    arg_ix = 0
    args_arr = [""]
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
        # argument so we increment arg_ix and initialize a new args_arr entry.
        if char == "," and nest_level == 0:
            arg_ix += 1
            args_arr.append("")
            continue

        # For any other character, we append it it to the current arg array
        # entry.
        args_arr[arg_ix] += char

    # Trim whitespace from each list entry.
    args_arr = [arg.strip() for arg in args_arr]

    if arg_num > len(args_arr):
        print_error("Programmer error - The caller has asked for the name of"
        + " argument number \"" + str(arg_num) + "\" but there were only \""
        + str(len(args_arr)) + "\" args used:\n" + sprint_varx("args_arr",
        args_arr))
        return

    argument = args_arr[arg_num - 1]

    if local_debug:
        print_varx("args_arr", args_arr, 0, debug_indent)
        print_varx("argument", argument, 0, debug_indent)

    return argument

################################################################################



################################################################################
def sprint_time(buffer = ""):

    # This function will return the time in the following format.
    #
    # Example:
    #
    # The following python code...
    #
    # sys.stdout.write(sprint_time()) ; sys.stdout.write("Hi.\n")
    #
    # Will result in the following type of output.
    #
    # #(CDT) 2016/07/08 15:25:35 - Hi.

    # Example:
    # The following python code...
    #
    # sys.stdout.write(sprint_time("Hi.\n"))
    #
    # Will result in the following type of output.
    #
    # #(CDT) 2016/08/03 17:12:05 - Hi.

    # The following environment variables will affect the formatting as
    # described:
    # NANOSECONDS                  This will cause the time stamps to be precise
    #                              to the microsecond (Yes, it probably should
    #                              have been named MICROSECONDS but the
    #                              convention was set long ago so we're sticking
    #                              with it).  Example of the output when
    #                              environment variable NANOSECONDS=1.
    #
    # #(CDT) 2016/08/03 17:16:25.510469 - Hi.
    #

    # SHOW_ELAPSED_TIME            This will cause the elapsed time to be
    #                              included in the output.  This is the amount
    #                              of time that has elapsed since the last time
    #                              this function was called.  The precision of
    #                              the elapsed time field is also affected by
    #                              the value of the NANOSECONDS environment
    #                              variable.  Example of the output when
    #                              environment variable NANOSECONDS=0 and
    #                              SHOW_ELAPSED_TIME=1.
    #
    # #(CDT) 2016/08/03 17:17:40 -    0 - Hi.
    #
    # Example of the output when environment variable NANOSECONDS=1 and
    # SHOW_ELAPSED_TIME=1.
    #
    # #(CDT) 2016/08/03 17:18:47.317339 -    0.000046 - Hi.
    #

    # Description of arguments.
    # buffer                       This will be appended to the formatted time
    #                              string.

    global NANOSECONDS
    global SHOW_ELAPSED_TIME
    global sprint_time_last_seconds

    seconds = time.time()
    loc_time = time.localtime(seconds)
    nanoseconds = "%0.6f" % seconds
    pos = nanoseconds.find(".")
    nanoseconds = nanoseconds[pos:]

    time_string = time.strftime("#(%Z) %Y/%m/%d %H:%M:%S", loc_time)
    if ( NANOSECONDS == "1" ):
        time_string = time_string + nanoseconds

    if ( SHOW_ELAPSED_TIME == "1" ):
        cur_time_seconds = seconds
        math_string = "%9.9f" % cur_time_seconds + " - " + "%9.9f" % \
            sprint_time_last_seconds
        elapsed_seconds = eval(math_string)
        if ( NANOSECONDS == "1" ):
            elapsed_seconds = "%11.6f" % elapsed_seconds
        else:
            elapsed_seconds = "%4i" % elapsed_seconds
        sprint_time_last_seconds = cur_time_seconds;
        time_string = time_string + " - " + elapsed_seconds

    return time_string + " - " + buffer

################################################################################



################################################################################
def sprint_timen(buffer = ""):

    # This function appends a line feed to the buffer, passes it to sprint_time
    # and returns the result.

    return sprint_time(buffer + "\n")

################################################################################



################################################################################
def sprint_error(buffer = ""):

    # This function will return a standardized error string.  This includes:
    # - A time stamp
    # - The "**ERROR**" string
    # - The caller's buffer string.

    # Description of arguments.
    # buffer                       This will be appended to the formatted error
    #                              string.

    return sprint_time() + "**ERROR** " + buffer;

################################################################################



################################################################################
def sprint_varx(var_name,
                var_value,
                hex = 0,
                loc_col1_indent = col1_indent,
                loc_col1_width = col1_width):

    # This function will print the var name/value passed to it.  If the caller
    # uses lets loc_col1_width default, the printing lines up nicely with output
    # generated by the print_time functions.

    # Note that the sprint_var function (defined below) can be used to call
    # this function so that the programmer does not need to pass the var_name.
    # sprint_var will figure out the var_name.  The sprint_var function is the
    # one that would normally be used by the general user.

    # For example, the following python code:
    #
    # first_name = "Mike"
    # print_time("Doing this...\n")
    # print_varx("first_name", first_name)
    # print_time("Doing that...\n")
    #
    # Will generate output like this:
    #
    # #(CDT) 2016/08/10 17:34:42.847374 -    0.001285 - Doing this...
    # first_name:                                       Mike
    # #(CDT) 2016/08/10 17:34:42.847510 -    0.000136 - Doing that...
    #
    # This function recognizes several complex types of data such as dict, list
    # or tuple.
    #
    # For example, the following python code:
    #
    # my_dict = dict(one=1, two=2, three=3)
    # print_var(my_dict)
    #
    # Will generate the following output:
    #
    # my_dict:
    #   my_dict[three]:                                 3
    #   my_dict[two]:                                   2
    #   my_dict[one]:                                   1


    # Description of arguments.
    # var_name                     The name of the variable to be printed.
    # var_value                    The value of the variable to be printed.
    # hex                          This indicates that the value should be
    #                              printed in hex format.  It is the user's
    #                              responsibility to ensure that a var_value
    #                              contains a valid hex number.
    # loc_col1_indent              The number of spaces to indent the output.
    # loc_col1_width               The width of the output column containing the
    #                              variable name.  The default value of this is
    #                              adjusted so that the var_value lines up with
    #                              text printed via the print_time function.

    # Adjust loc_col1_width.
    loc_col1_width = loc_col1_width - loc_col1_indent

    # Determine the type
    if type(var_value) in (int, float, bool, str, unicode) or var_value is None:
        # The data type is simple in the sense that it has no subordinate parts.
        # See if the user wants the output in hex format.
        if hex:
            value_format = "0x%08x"
        else:
            value_format = "%s";
        format_string = "%" + str(loc_col1_indent) + "s%-" \
            + str(loc_col1_width) + "s" + value_format + "\n"
        return format_string % ("", var_name + ":", var_value)
    else:
        # The data type is complex in the sense that it has subordinate parts.
        format_string = "%" + str(loc_col1_indent) + "s%s\n"
        buffer = format_string % ("", var_name + ":")
        loc_col1_indent += 2
        if type(var_value) is dict:
            for key, value in var_value.iteritems():
                buffer += sprint_varx(var_name + "[" + key + "]", value, hex,
                                      loc_col1_indent)
        elif type(var_value) in (list, tuple):
            for key, value in enumerate(var_value):
                buffer += sprint_varx(var_name + "[" + str(key) + "]", value,
                                      hex, loc_col1_indent)
        elif type(var_value) is argparse.Namespace:
            for key in var_value.__dict__:
                cmd_buf = "buffer += sprint_varx(var_name + \".\" + str(key)," \
          + " var_value." + key + ", hex, loc_col1_indent)"
                #issuing(cmd_buf)
                exec(cmd_buf)
        else:
            var_type = type(var_value).__name__
            func_name = sys._getframe().f_code.co_name
            var_value = "<" + var_type + " type not supported by " + func_name \
                + "()>"
            value_format = "%s"
            loc_col1_indent -= 2
            format_string = "%" + str(loc_col1_indent) + "s%-" \
                + str(loc_col1_width) + "s" + value_format + "\n"
            return format_string % ("", var_name + ":", var_value)
        return buffer

    return ""

################################################################################



################################################################################
def sprint_var(*args):

    # This function figures out the name of the first argument for you and then
    # calls sprint_varx with it.  Therefore, the following 2 calls are
    # equivalent;
    # sprint_var("var1", var1);
    # sprint_varm(var1);

    # Get the name of the first variable passed to this function.
    stack_frame = 2
    calling_func_name = sprint_func_name(2)
    if calling_func_name == "print_var":
        stack_frame += 1
    var_name = get_arg_name(None, 1, stack_frame)
    return sprint_varx(var_name, *args)

################################################################################



################################################################################
def sprint_dashes(loc_col1_indent = col1_indent,
                  col_width = 80,
                  line_feed = 1):

    # This function will return a string of dashes + a line feed to the caller.

    # Description of arguements:
    # loc_col1_indent	The number of characters to indent the output.
    # col_width		The width of the string of dashes.
    # line_feed                    Indicates whether the output should contain a
    #                              line feed.

    col_width = int(col_width)
    buffer = " "*int(loc_col1_indent) + "-"*col_width
    if line_feed: buffer += "\n"

    return buffer

################################################################################



################################################################################
def sprint_call_stack():

    # This function returns the full call stack for the given point in the
    # program, with arguments and line numbers and nice formatting.

    # Sample output:
    #
    # --------------------------------------------------------------------------
    # Python function call stack
    # 
    # Line # Function name and arguments
    # ------ -------------------------------------------------------------------
    #    424 sprint_call_stack ()
    #      4 print_call_stack ()
    #     31 func1 (last_name = 'walsh', first_name = 'mikey')
    #     59 /tmp/scr5.py
    # --------------------------------------------------------------------------

    buffer = ""

    buffer += sprint_dashes()
    buffer += "Python function call stack\n\n"
    buffer += "Line # Function name and arguments\n"
    buffer += sprint_dashes(0, 6, 0) + " " + sprint_dashes(0, 73)

    # Grab the current program stack.
    current_stack = inspect.stack()

    # Process each frame in turn.
    format_string = "%6s %s\n"
    for stack_frame in current_stack:
        lineno = str(stack_frame[2])
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

            args_arr = []
            for arg_name in function_parms:
                # Get the arg value from frame locals.
                arg_value = frame_locals[arg_name]
                args_arr.append(arg_name + " = " + repr(arg_value))
            args_str = "(" + ', '.join(map(str, args_arr)) + ")"

            # Now we need to print this in a nicely-wrapped way.
            func_and_args = func_name + " " + args_str

        buffer += format_string % (lineno, func_and_args)

    buffer += sprint_dashes()

    return buffer

################################################################################



################################################################################
def sprint_executing(stack_frame_ix = None):

    # This function will print a line indicating what function is executing and
    # with what parameter values.  It is useful for debugging.

    # Sample output:
    #
    # #(CDT) 2016/08/25 17:54:27 - Executing: func1 (x = 1)

    # Description of arguments:
    # stack_frame_ix               The index of the stack frame whose function
    #                              info should be returned.  If the caller does
    #                              not specifiy a value, this function will set
    #                              the value to 1 which is the index of the
    #                              caller's stack frame.  If the caller is the
    #                              wrapper function "print_executing", this
    #                              function will bump it up by 1.

    # If user wants default stack_frame_ix.
    if stack_frame_ix == None:
        func_name = sys._getframe().f_code.co_name
        caller_func_name = sys._getframe(1).f_code.co_name
        if func_name[1:] == caller_func_name: stack_frame_ix = 2
        else: stack_frame_ix = 1

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

        args_arr = []
        for arg_name in function_parms:
            # Get the arg value from frame locals.
            arg_value = frame_locals[arg_name]
            args_arr.append(arg_name + " = " + repr(arg_value))
        args_str = "(" + ', '.join(map(str, args_arr)) + ")"

        # Now we need to print this in a nicely-wrapped way.
        func_and_args = func_name + " " + args_str

    return sprint_time() + "Executing: " + func_and_args + "\n"

################################################################################



################################################################################
def sprint_pgm_header():

    # This function returns a standardized header that programs should print at
    # the beginning of the run.  It includes useful information like command
    # line, pid, userid, program parameters, etc.

    buffer = "\n"
    buffer += sprint_time() + "Running " + pgm_name + ".\n"
    buffer += sprint_time() + "Program parameter values, etc.:\n\n"
    buffer += sprint_varx("command_line", ' '.join(sys.argv))
    # We want the output to show a customized name for the pid and pgid but we
    # want it to look like a valid variable name.  Therefore, we'll use
    # pgm_name_var_name which was set when this module was imported.
    buffer += sprint_varx(pgm_name_var_name + "_pid", os.getpid())
    buffer += sprint_varx(pgm_name_var_name + "_pgid", os.getpgrp())
    buffer += sprint_varx("uid", str(os.geteuid()) + " (" + os.getlogin() + ")")
    buffer += sprint_varx("gid",
        str(os.getgid()) + " (" + str(grp.getgrgid(os.getgid()).gr_name) + ")")
    buffer += sprint_varx("host_name", socket.gethostname())
    buffer += sprint_varx("DISPLAY", os.environ['DISPLAY'])
    # I want to add code to print caller's parms.

    buffer += "\n"

    return buffer

################################################################################



################################################################################
def sissuing(cmd_buf):

    # This function returns a line indicating a command that the program is
    # about to execute.

    # Sample output for a cmd_buf of "ls"
    #
    # #(CDT) 2016/08/25 17:57:36 - Issuing: ls

    buffer = sprint_time() + "Issuing: " + cmd_buf + "\n"

    return buffer

################################################################################



################################################################################
def sprint_pgm_footer():

    # This function returns a standardized footer that programs should print at
    # the end of the program run.  It includes useful information like total run
    # time, etc.

    buffer = "\n" + sprint_time() + "Finished running " + pgm_name + ".\n\n"

    total_time = time.time() - start_time
    total_time_string = "%0.6f" % total_time

    buffer += sprint_varx(pgm_name_var_name + "runtime", total_time_string)

    return buffer

################################################################################




################################################################################
# In the following section of code, we will dynamically create print versions
# for each of the sprint functions defined above.  So, for example, where we
# have an sprint_time() function defined above that returns the time to the
# caller in a string, we will create a corresponding print_time() function that
# will print that string directly to stdout.

# It can be complicated to follow what's being creaed by the exec statement
# below.  Here is an example of the print_time() function that will be created:

# def print_time(*args):
#   s_funcname = "s" + sys._getframe().f_code.co_name
#   s_func = getattr(sys.modules[__name__], s_funcname)
#   sys.stdout.write(s_func(*args))

# Here are comments describing the 3 lines in the body of the created function.
# Calculate the "s" version of this function name (e.g. if this function name
# is print_time, we want s_funcname to be "sprint_time".
# Put a reference to the "s" version of this function in s_func.
# Call the "s" version of this function passing it all of our arguments.  Write
# the result to stdout.

# func_names contains a list of all print functions which should be created
# from their sprint counterparts.
func_names = ['print_time', 'print_timen', 'print_error', 'print_varx',
              'print_var', 'print_dashes', 'print_call_stack',
              'print_func_name', 'print_executing', 'print_pgm_header',
              'issuing', 'print_pgm_footer']

for func_name in func_names:
    # Create abbreviated aliases (e.g. spvar is an alias for sprint_var).
    alias = re.sub("print_", "p", func_name)
    exec("s" + alias + " = s" + func_name)

for func_name in func_names:
    if func_name == "print_error": output_stream = "stderr"
    else: output_stream = "stdout"
    func_def = \
        [
            "def " + func_name + "(*args):",
            "  s_func_name = \"s\" + sys._getframe().f_code.co_name",
            "  s_func = getattr(sys.modules[__name__], s_func_name)",
            "  sys." + output_stream + ".write(s_func(*args))",
            "  sys." + output_stream + ".flush()"
        ]
    #print(sprint_var(func_def))
    pgm_definition_string = '\n'.join(func_def)
    #print(pgm_definition_string)
    exec(pgm_definition_string)

    # Create abbreviated aliases (e.g. pvar is an alias for print_var).
    alias = re.sub("print_", "p", func_name)
    exec(alias + " = " + func_name)

################################################################################




