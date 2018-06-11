#!/usr/bin/env python

r"""
This module provides valuable argument processing functions like
gen_get_options and sprint_args.
"""

import sys
import __builtin__
import atexit
import signal
import argparse

import gen_print as gp
import gen_valid as gv

default_string = '  The default value is "%(default)s".'


def gen_get_options(parser,
                    stock_list=[]):
    r"""
    Parse the command line arguments using the parser object passed and return
    True/False (i.e. pass/fail).  However, if gv.exit_on_error is set, simply
    exit the program on failure.  Also set the following built in values:

    __builtin__.quiet      This value is used by the qprint functions.
    __builtin__.test_mode  This value is used by command processing functions.
    __builtin__.debug      This value is used by the dprint functions.
    __builtin__.arg_obj    This value is used by print_program_header, etc.
    __builtin__.parser     This value is used by print_program_header, etc.

    Description of arguments:
    parser                          A parser object.  See argparse module
                                    documentation for details.
    stock_list                      The caller can use this parameter to
                                    request certain stock parameters offered
                                    by this function.  For example, this
                                    function will define a "quiet" option upon
                                    request.  This includes stop help text and
                                    parm checking.  The stock_list is a list
                                    of tuples each of which consists of an
                                    arg_name and a default value.  Example:
                                    stock_list = [("test_mode", 0), ("quiet",
                                    1), ("debug", 0)]
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
                help='If this parameter is set to "1", %(prog)s' +
                     ' will print only essential information, i.e. it will' +
                     ' not echo parameters, echo commands, print the total' +
                     ' run time, etc.' + default_string)
        elif arg_name == "test_mode":
            if default is None:
                default = 0
            parser.add_argument(
                '--test_mode',
                default=default,
                type=int,
                choices=[1, 0],
                help='This means that %(prog)s should go through all the' +
                     ' motions but not actually do anything substantial.' +
                     '  This is mainly to be used by the developer of' +
                     ' %(prog)s.' + default_string)
        elif arg_name == "debug":
            if default is None:
                default = 0
            parser.add_argument(
                '--debug',
                default=default,
                type=int,
                choices=[1, 0],
                help='If this parameter is set to "1", %(prog)s will print' +
                     ' additional debug information.  This is mainly to be' +
                     ' used by the developer of %(prog)s.' + default_string)
        elif arg_name == "loglevel":
            if default is None:
                default = "info"
            parser.add_argument(
                '--loglevel',
                default=default,
                type=str,
                choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL',
                         'debug', 'info', 'warning', 'error', 'critical'],
                help='If this parameter is set to "1", %(prog)s will print' +
                     ' additional debug information.  This is mainly to be' +
                     ' used by the developer of %(prog)s.' + default_string)

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

    # For each command line parameter, create a corresponding global variable
    # and assign it the appropriate value.  For example, if the command line
    # contained "--last_name='Smith', we'll create a global variable named
    # "last_name" with the value "Smith".
    module = sys.modules['__main__']
    for key in arg_obj.__dict__:
        setattr(module, key, getattr(__builtin__.arg_obj, key))

    return True


def set_pgm_arg(var_value,
                var_name=None):
    r"""
    Set the value of the arg_obj.__dict__ entry named in var_name with the
    var_value provided.  Also, set corresponding global variable.

    Description of arguments:
    var_value                       The value to set in the variable.
    var_name                        The name of the variable to set.  This
                                    defaults to the name of the variable used
                                    for var_value when calling this function.
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
    sprint_var all of the arguments found in arg_obj and return the result as
    a string.

    Description of arguments:
    arg_obj                         An argument object such as is returned by
                                    the argparse parse_args() method.
    indent                          The number of spaces to indent each line
                                    of output.
    """

    loc_col1_width = gp.col1_width + indent

    buffer = ""

    for key in arg_obj.__dict__:
        buffer += gp.sprint_varx(key, getattr(arg_obj, key), 0, indent,
                                 loc_col1_width)

    return buffer


def gen_post_validation(exit_function=None,
                        signal_handler=None):
    r"""
    Do generic post-validation processing.  By "post", we mean that this is to
    be called from a validation function after the caller has done any
    validation desired.  If the calling program passes exit_function and
    signal_handler parms, this function will register them.  In other words,
    it will make the signal_handler functions get called for SIGINT and
    SIGTERM and will make the exit_function function run prior to the
    termination of the program.

    Description of arguments:
    exit_function                   A function object pointing to the caller's
                                    exit function.
    signal_handler                  A function object pointing to the caller's
                                    signal_handler function.
    """

    if exit_function is not None:
        atexit.register(exit_function)
    if signal_handler is not None:
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
