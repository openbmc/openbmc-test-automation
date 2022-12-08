#!/usr/bin/env python3

r"""
This module provides valuable argument processing functions like gen_get_options and sprint_args.
"""

import sys
import os
import re
try:
    import psutil
    psutil_imported = True
except ImportError:
    psutil_imported = False
try:
    import __builtin__
except ImportError:
    import builtins as __builtin__
import atexit
import signal
import argparse
import textwrap as textwrap

import gen_print as gp
import gen_valid as gv
import gen_cmd as gc
import gen_misc as gm


class MultilineFormatter(argparse.HelpFormatter):
    def _fill_text(self, text, width, indent):
        r"""
        Split text into formatted lines for every "%%n" encountered in the text and return the result.
        """
        lines = self._whitespace_matcher.sub(' ', text).strip().split('%n')
        formatted_lines = \
            [textwrap.fill(x, width, initial_indent=indent, subsequent_indent=indent) + '\n' for x in lines]
        return ''.join(formatted_lines)


class ArgumentDefaultsHelpMultilineFormatter(MultilineFormatter, argparse.ArgumentDefaultsHelpFormatter):
    pass


default_string = '  The default value is "%(default)s".'
module = sys.modules["__main__"]


def gen_get_options(parser,
                    stock_list=[]):
    r"""
    Parse the command line arguments using the parser object passed and return True/False (i.e. pass/fail).
    However, if gv.exit_on_error is set, simply exit the program on failure.  Also set the following built in
    values:

    __builtin__.quiet      This value is used by the qprint functions.
    __builtin__.test_mode  This value is used by command processing functions.
    __builtin__.debug      This value is used by the dprint functions.
    __builtin__.arg_obj    This value is used by print_program_header, etc.
    __builtin__.parser     This value is used by print_program_header, etc.

    Description of arguments:
    parser                          A parser object.  See argparse module documentation for details.
    stock_list                      The caller can use this parameter to request certain stock parameters
                                    offered by this function.  For example, this function will define a
                                    "quiet" option upon request.  This includes stop help text and parm
                                    checking.  The stock_list is a list of tuples each of which consists of
                                    an arg_name and a default value.  Example: stock_list = [("test_mode",
                                    0), ("quiet", 1), ("debug", 0)]
    """

    # This is a list of stock parms that we support.
    master_stock_list = ["quiet", "test_mode", "debug", "loglevel"]

    # Process stock_list.
    for ix in range(0, len(stock_list)):
        if len(stock_list[ix]) < 1:
            error_message = "Programmer error - stock_list[" + str(ix) +\
                            "] is supposed to be a tuple containing at" +\
                            " least one element which is the name of" +\
                            " the desired stock parameter:\n" +\
                            gp.sprint_var(stock_list)
            return gv.process_error_message(error_message)
        if isinstance(stock_list[ix], tuple):
            arg_name = stock_list[ix][0]
            default = stock_list[ix][1]
        else:
            arg_name = stock_list[ix]
            default = None

        if arg_name not in master_stock_list:
            error_message = "Programmer error - arg_name \"" + arg_name +\
                            "\" not found found in stock list:\n" +\
                            gp.sprint_var(master_stock_list)
            return gv.process_error_message(error_message)

        if arg_name == "quiet":
            if default is None:
                default = 0
            parser.add_argument(
                '--quiet',
                default=default,
                type=int,
                choices=[1, 0],
                help='If this parameter is set to "1", %(prog)s'
                     + ' will print only essential information, i.e. it will'
                     + ' not echo parameters, echo commands, print the total'
                     + ' run time, etc.' + default_string)
        elif arg_name == "test_mode":
            if default is None:
                default = 0
            parser.add_argument(
                '--test_mode',
                default=default,
                type=int,
                choices=[1, 0],
                help='This means that %(prog)s should go through all the'
                     + ' motions but not actually do anything substantial.'
                     + '  This is mainly to be used by the developer of'
                     + ' %(prog)s.' + default_string)
        elif arg_name == "debug":
            if default is None:
                default = 0
            parser.add_argument(
                '--debug',
                default=default,
                type=int,
                choices=[1, 0],
                help='If this parameter is set to "1", %(prog)s will print'
                     + ' additional debug information.  This is mainly to be'
                     + ' used by the developer of %(prog)s.' + default_string)
        elif arg_name == "loglevel":
            if default is None:
                default = "info"
            parser.add_argument(
                '--loglevel',
                default=default,
                type=str,
                choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL',
                         'debug', 'info', 'warning', 'error', 'critical'],
                help='If this parameter is set to "1", %(prog)s will print'
                     + ' additional debug information.  This is mainly to be'
                     + ' used by the developer of %(prog)s.' + default_string)

    arg_obj = parser.parse_args()

    __builtin__.quiet = 0
    __builtin__.test_mode = 0
    __builtin__.debug = 0
    __builtin__.loglevel = 'WARNING'
    for ix in range(0, len(stock_list)):
        if isinstance(stock_list[ix], tuple):
            arg_name = stock_list[ix][0]
            default = stock_list[ix][1]
        else:
            arg_name = stock_list[ix]
            default = None
        if arg_name == "quiet":
            __builtin__.quiet = arg_obj.quiet
        elif arg_name == "test_mode":
            __builtin__.test_mode = arg_obj.test_mode
        elif arg_name == "debug":
            __builtin__.debug = arg_obj.debug
        elif arg_name == "loglevel":
            __builtin__.loglevel = arg_obj.loglevel

    __builtin__.arg_obj = arg_obj
    __builtin__.parser = parser

    # For each command line parameter, create a corresponding global variable and assign it the appropriate
    # value.  For example, if the command line contained "--last_name='Smith', we'll create a global variable
    # named "last_name" with the value "Smith".
    module = sys.modules['__main__']
    for key in arg_obj.__dict__:
        setattr(module, key, getattr(__builtin__.arg_obj, key))

    return True


def set_pgm_arg(var_value,
                var_name=None):
    r"""
    Set the value of the arg_obj.__dict__ entry named in var_name with the var_value provided.  Also, set
    corresponding global variable.

    Description of arguments:
    var_value                       The value to set in the variable.
    var_name                        The name of the variable to set.  This defaults to the name of the
                                    variable used for var_value when calling this function.
    """

    if var_name is None:
        var_name = gp.get_arg_name(None, 1, 2)

    arg_obj.__dict__[var_name] = var_value
    module = sys.modules['__main__']
    setattr(module, var_name, var_value)
    if var_name == "quiet":
        __builtin__.quiet = var_value
    elif var_name == "debug":
        __builtin__.debug = var_value
    elif var_name == "test_mode":
        __builtin__.test_mode = var_value


def sprint_args(arg_obj,
                indent=0):
    r"""
    sprint_var all of the arguments found in arg_obj and return the result as a string.

    Description of arguments:
    arg_obj                         An argument object such as is returned by the argparse parse_args()
                                    method.
    indent                          The number of spaces to indent each line of output.
    """

    col1_width = gp.dft_col1_width + indent

    buffer = ""
    for key in arg_obj.__dict__:
        buffer += gp.sprint_varx(key, getattr(arg_obj, key), 0, indent,
                                 col1_width)
    return buffer


def sync_args():
    r"""
    Synchronize the argument values to match their corresponding global variable values.

    The user's validate_parms() function may manipulate global variables that correspond to program
    arguments.  After validate_parms() is called, sync_args is called to set the altered values back into the
    arg_obj.  This will ensure that the print-out of program arguments reflects the updated values.

    Example:

    def validate_parms():

        # Set a default value for dir_path argument.
        dir_path = gm.add_trailing_slash(gm.dft(dir_path, os.getcwd()))
    """
    module = sys.modules['__main__']
    for key in arg_obj.__dict__:
        arg_obj.__dict__[key] = getattr(module, key)


term_options = None


def set_term_options(**kwargs):
    r"""
    Set the global term_options.

    If the global term_options is not None, gen_exit_function() will call terminate_descendants().

    Description of arguments():
    kwargs                          Supported keyword options follow:
        term_requests               Requests to terminate specified descendants of this program.  The
                                    following values for term_requests are supported:
            children                Terminate the direct children of this program.
            descendants             Terminate all descendants of this program.
            <dictionary>            A dictionary with support for the following keys:
                pgm_names           A list of program names which will be used to identify which descendant
                                    processes should be terminated.
    """

    global term_options
    # Validation:
    arg_names = list(kwargs.keys())
    gv.valid_list(arg_names, ['term_requests'])
    if type(kwargs['term_requests']) is dict:
        keys = list(kwargs['term_requests'].keys())
        gv.valid_list(keys, ['pgm_names'])
    else:
        gv.valid_value(kwargs['term_requests'], ['children', 'descendants'])
    term_options = kwargs


if psutil_imported:
    def match_process_by_pgm_name(process, pgm_name):
        r"""
        Return True or False to indicate whether the process matches the program name.

        Description of argument(s):
        process                     A psutil process object such as the one returned by psutil.Process().
        pgm_name                    The name of a program to look for in the cmdline field of the process
                                    object.
        """

        # This function will examine elements 0 and 1 of the cmdline field of the process object.  The
        # following examples will illustrate the reasons for this:

        # Example 1: Suppose a process was started like this:

        # shell_cmd('python_pgm_template --quiet=0', fork=1)

        # And then this function is called as follows:

        # match_process_by_pgm_name(process, "python_pgm_template")

        # The process object might contain the following for its cmdline field:

        # cmdline:
        #   [0]:                       /usr/bin/python
        #   [1]:                       /my_path/python_pgm_template
        #   [2]:                       --quiet=0

        # Because "python_pgm_template" is a python program, the python interpreter (e.g. "/usr/bin/python")
        # will appear in entry 0 of cmdline and the python_pgm_template will appear in entry 1 (with a
        # qualifying dir path).

        # Example 2: Suppose a process was started like this:

        # shell_cmd('sleep 5', fork=1)

        # And then this function is called as follows:

        # match_process_by_pgm_name(process, "sleep")

        # The process object might contain the following for its cmdline field:

        # cmdline:
        #   [0]:                       sleep
        #   [1]:                       5

        # Because "sleep" is a compiled executable, it will appear in entry 0.

        optional_dir_path_regex = "(.*/)?"
        cmdline = process.as_dict()['cmdline']
        return re.match(optional_dir_path_regex + pgm_name + '( |$)', cmdline[0]) \
            or re.match(optional_dir_path_regex + pgm_name + '( |$)', cmdline[1])

    def select_processes_by_pgm_name(processes, pgm_name):
        r"""
        Select the processes that match pgm_name and return the result as a list of process objects.

        Description of argument(s):
        processes                   A list of psutil process objects such as the one returned by
                                    psutil.Process().
        pgm_name                    The name of a program to look for in the cmdline field of each process
                                    object.
        """

        return [process for process in processes if match_process_by_pgm_name(process, pgm_name)]

    def sprint_process_report(pids):
        r"""
        Create a process report for the given pids and return it as a string.

        Description of argument(s):
        pids                        A list of process IDs for processes to be included in the report.
        """
        report = "\n"
        cmd_buf = "echo ; ps wwo user,pgrp,pid,ppid,lstart,cmd --forest " + ' '.join(pids)
        report += gp.sprint_issuing(cmd_buf)
        rc, outbuf = gc.shell_cmd(cmd_buf, quiet=1)
        report += outbuf + "\n"

        return report

    def get_descendant_info(process=psutil.Process()):
        r"""
        Get info about the descendants of the given process and return as a tuple of descendants,
        descendant_pids and process_report.

        descendants will be a list of process objects.  descendant_pids will be a list of pids (in str form)
        and process_report will be a report produced by a call to sprint_process_report().

        Description of argument(s):
        process                     A psutil process object such as the one returned by psutil.Process().
        """
        descendants = process.children(recursive=True)
        descendant_pids = [str(process.pid) for process in descendants]
        if descendants:
            process_report = sprint_process_report([str(process.pid)] + descendant_pids)
        else:
            process_report = ""
        return descendants, descendant_pids, process_report

    def terminate_descendants():
        r"""
        Terminate descendants of the current process according to the requirements layed out in global
        term_options variable.

        Note: If term_options is not null, gen_exit_function() will automatically call this function.

        When this function gets called, descendant processes may be running and may be printing to the same
        stdout stream being used by this process.  If this function writes directly to stdout, its output can
        be interspersed with any output generated by descendant processes.  This makes it very difficult to
        interpret the output.  In order solve this problem, the activity of this process will be logged to a
        temporary file.  After descendant processes have been terminated successfully, the temporary file
        will be printed to stdout and then deleted.  However, if this function should fail to complete (i.e.
        get hung waiting for descendants to terminate gracefully), the temporary file will not be deleted and
        can be used by the developer for debugging.  If no descendant processes are found, this function will
        return before creating the temporary file.

        Note that a general principal being observed here is that each process is responsible for the
        children it produces.
        """

        message = "\n" + gp.sprint_dashes(width=120) \
            + gp.sprint_executing() + "\n"

        current_process = psutil.Process()

        descendants, descendant_pids, process_report = get_descendant_info(current_process)
        if not descendants:
            # If there are no descendants, then we have nothing to do.
            return

        terminate_descendants_temp_file_path = gm.create_temp_file_path()
        gp.print_vars(terminate_descendants_temp_file_path)

        message += gp.sprint_varx("pgm_name", gp.pgm_name) \
            + gp.sprint_vars(term_options) \
            + process_report

        # Process the termination requests:
        if term_options['term_requests'] == 'children':
            term_processes = current_process.children(recursive=False)
            term_pids = [str(process.pid) for process in term_processes]
        elif term_options['term_requests'] == 'descendants':
            term_processes = descendants
            term_pids = descendant_pids
        else:
            # Process term requests by pgm_names.
            term_processes = []
            for pgm_name in term_options['term_requests']['pgm_names']:
                term_processes.extend(select_processes_by_pgm_name(descendants, pgm_name))
            term_pids = [str(process.pid) for process in term_processes]

        message += gp.sprint_timen("Processes to be terminated:") \
            + gp.sprint_var(term_pids)
        for process in term_processes:
            process.terminate()
        message += gp.sprint_timen("Waiting on the following pids: " + ' '.join(descendant_pids))
        gm.append_file(terminate_descendants_temp_file_path, message)
        psutil.wait_procs(descendants)

        # Checking after the fact to see whether any descendant processes are still alive.  If so, a process
        # report showing this will be included in the output.
        descendants, descendant_pids, process_report = get_descendant_info(current_process)
        if descendants:
            message = "\n" + gp.sprint_timen("Not all of the processes terminated:") \
                + process_report
            gm.append_file(terminate_descendants_temp_file_path, message)

        message = gp.sprint_dashes(width=120)
        gm.append_file(terminate_descendants_temp_file_path, message)
        gp.print_file(terminate_descendants_temp_file_path)
        os.remove(terminate_descendants_temp_file_path)


def gen_exit_function():
    r"""
    Execute whenever the program ends normally or with the signals that we catch (i.e. TERM, INT).
    """

    # ignore_err influences the way shell_cmd processes errors.  Since we're doing exit processing, we don't
    # want to stop the program due to a shell_cmd failure.
    ignore_err = 1

    if psutil_imported and term_options:
        terminate_descendants()

    # Call the main module's exit_function if it is defined.
    exit_function = getattr(module, "exit_function", None)
    if exit_function:
        exit_function()

    gp.qprint_pgm_footer()


def gen_signal_handler(signal_number,
                       frame):
    r"""
    Handle signals.  Without a function to catch a SIGTERM or SIGINT, the program would terminate immediately
    with return code 143 and without calling the exit_function.
    """

    # The convention is to set up exit_function with atexit.register() so there is no need to explicitly
    # call exit_function from here.

    gp.qprint_executing()

    # Calling exit prevents control from returning to the code that was running when the signal was received.
    exit(0)


def gen_post_validation(exit_function=None,
                        signal_handler=None):
    r"""
    Do generic post-validation processing.  By "post", we mean that this is to be called from a validation
    function after the caller has done any validation desired.  If the calling program passes exit_function
    and signal_handler parms, this function will register them.  In other words, it will make the
    signal_handler functions get called for SIGINT and SIGTERM and will make the exit_function function run
    prior to the termination of the program.

    Description of arguments:
    exit_function                   A function object pointing to the caller's exit function.  This defaults
                                    to this module's gen_exit_function.
    signal_handler                  A function object pointing to the caller's signal_handler function.  This
                                    defaults to this module's gen_signal_handler.
    """

    # Get defaults.
    exit_function = exit_function or gen_exit_function
    signal_handler = signal_handler or gen_signal_handler

    atexit.register(exit_function)
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)


def gen_setup():
    r"""
    Do general setup for a program.
    """

    # Set exit_on_error for gen_valid functions.
    gv.set_exit_on_error(True)

    # Get main module variable values.
    parser = getattr(module, "parser")
    stock_list = getattr(module, "stock_list")
    validate_parms = getattr(module, "validate_parms", None)

    gen_get_options(parser, stock_list)

    if validate_parms:
        validate_parms()
        sync_args()
    gen_post_validation()

    gp.qprint_pgm_header()
