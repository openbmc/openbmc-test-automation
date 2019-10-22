#!/usr/bin/env python

r"""
This module provides validation functions like valid_value(), valid_integer(), etc. for robot programs.
"""

import re
import gen_print as gp
import gen_valid as gv
import func_args as fa

from robot.libraries.BuiltIn import BuiltIn


def valid_var_name(var_name):
    r"""
    Validate the robot variable name and return its value.

    If the variable is undefined, this function will print an error message and call BuiltIn().fail().

    Description of arguments():
    var_name                        The name of the robot variable (e.g. "var1").  Do not include "${}" (e.g.
                                    "${var1}".  Just provide the simple name of the variable.
    """

    # Note: get_variable_value() seems to have no trouble with local variables.
    var_value = BuiltIn().get_variable_value("${" + var_name + "}")
    if var_value is None:
        var_value = "<undefined>"
        error_message = gv.valid_value(var_value, invalid_values=[var_value],
                                       var_name=var_name)
        BuiltIn().fail(error_message)

    return var_value


def valid_init(var_name, *args, **kwargs):
    r"""
    Do initialization for variable validation and return var_name, args and kwargs.

    This function is to be called by all of the various validation functions in this module.

    This function is designed solely for use by other functions in this file.

    Description of argument(s):
    var_name                        The name of the variable to be validated.
    args                            The positional arguments to be passed to a validation function.
    kwargs                          The keyword arguments to be passed to a validation function.
    """

    var_value = valid_var_name(var_name)
    # Convert python string object definitions to objects (useful for robot callers).
    args = fa.args_to_objects(args)
    kwargs = fa.args_to_objects(kwargs)
    return var_value, args, kwargs


def process_error_message(error_message):
    r"""
    Process an error message.

    If error_message is non-blank, fail.  Otherwise, do nothing.

    This function is designed solely for use by other functions in this file.

    Description of argument(s):
    error_message                   The error message to be processed.
    """

    if error_message:
        error_message = gp.sprint_error_report(error_message)
        BuiltIn().fail(error_message)


# The docstring header will be pre-pended to each validation function's existing docstring.
docstring_header = \
    r"""
    Fail if the variable named by var_name is invalid.
    """


def customize_doc_string(doc_string):
    r"""
    Customize a gen_valid function docstring and return the result.

    This function is designed solely for use by other functions in this file.

    The caller should pass a docstring from a gen_valid.py validation function.  This docstring will be
    changed to make a suitable docstring for this module's corresponding validation function.

    For example:

    Let's suppose that gen_valid.py has a function called "valid_value()".  This module could make the
    following call to essentially copy gen_valid's "valid_value()" function, modify it and then assign it to
    the local version of the valid_value() function.

    valid.__doc__ = customize_doc_string(gv.valid.__doc__)

    Description of argument(s):
    doc_string                      The docstring to be customized.
    """

    doc_string = docstring_header + doc_string
    doc_string = doc_string.split("\n")

    start_ix = 0
    # Find the "var_value" line.
    start_ix = next((index for index, value in
                     enumerate(doc_string[start_ix:], start_ix)
                     if re.match("[ ]+var_value  ", value)), None)
    # Replace the "var_value" line with our "var_name" line.
    doc_string[start_ix] = "    var_name                        " \
        + "The name of the variable to be validated."

    return "\n".join(doc_string)


# All of the following functions are robot wrappers for the equivalent functions defined in gen_valid.py.
# Note that the only difference between any two of these locally defined functions is the function name and
# the gv.<function name> which they call.  Also, note that the docstring for each is created by modifying the
# docstring from the supporting gen_valid.py function.

def valid_type(var_name, *args, **kwargs):

    var_value, args, kwargs = valid_init(var_name, *args, **kwargs)
    error_message = \
        gv.valid_type(var_value, *args, var_name=var_name, **kwargs)
    process_error_message(error_message)


def valid_value(var_name, *args, **kwargs):

    var_value, args, kwargs = valid_init(var_name, *args, **kwargs)
    error_message = \
        gv.valid_value(var_value, *args, var_name=var_name, **kwargs)
    process_error_message(error_message)


def valid_range(var_name, *args, **kwargs):

    var_value, args, kwargs = valid_init(var_name, *args, **kwargs)
    error_message = \
        gv.valid_range(var_value, *args, var_name=var_name, **kwargs)
    process_error_message(error_message)


def valid_integer(var_name, *args, **kwargs):

    var_value, args, kwargs = valid_init(var_name, *args, **kwargs)
    error_message = \
        gv.valid_integer(var_value, *args, var_name=var_name, **kwargs)
    process_error_message(error_message)


def valid_float(var_name, *args, **kwargs):

    var_value, args, kwargs = valid_init(var_name, *args, **kwargs)
    error_message = \
        gv.valid_float(var_value, *args, var_name=var_name, **kwargs)
    process_error_message(error_message)


def valid_date_time(var_name, *args, **kwargs):

    var_value, args, kwargs = valid_init(var_name, *args, **kwargs)
    error_message = \
        gv.valid_date_time(var_value, *args, var_name=var_name, **kwargs)
    process_error_message(error_message)


def valid_dir_path(var_name, *args, **kwargs):

    var_value, args, kwargs = valid_init(var_name, *args, **kwargs)
    error_message = \
        gv.valid_dir_path(var_value, *args, var_name=var_name, **kwargs)
    process_error_message(error_message)


def valid_file_path(var_name, *args, **kwargs):

    var_value, args, kwargs = valid_init(var_name, *args, **kwargs)
    error_message = \
        gv.valid_file_path(var_value, *args, var_name=var_name, **kwargs)
    process_error_message(error_message)


def valid_path(var_name, *args, **kwargs):

    var_value, args, kwargs = valid_init(var_name, *args, **kwargs)
    error_message = \
        gv.valid_path(var_value, *args, var_name=var_name, **kwargs)
    process_error_message(error_message)


def valid_list(var_name, *args, **kwargs):

    var_value, args, kwargs = valid_init(var_name, *args, **kwargs)
    error_message = \
        gv.valid_list(var_value, *args, var_name=var_name, **kwargs)
    process_error_message(error_message)


def valid_dict(var_name, *args, **kwargs):

    var_value, args, kwargs = valid_init(var_name, *args, **kwargs)
    error_message = \
        gv.valid_dict(var_value, *args, var_name=var_name, **kwargs)
    process_error_message(error_message)


def valid_program(var_name, *args, **kwargs):

    var_value, args, kwargs = valid_init(var_name, *args, **kwargs)
    error_message = \
        gv.valid_program(var_value, *args, var_name=var_name, **kwargs)
    process_error_message(error_message)


def valid_length(var_name, *args, **kwargs):

    var_value, args, kwargs = valid_init(var_name, *args, **kwargs)
    error_message = \
        gv.valid_length(var_value, *args, var_name=var_name, **kwargs)
    process_error_message(error_message)


# Modify the validation function docstrings by calling customize_doc_string for each function in the
# func_names list.
func_names = [
    "valid_type", "valid_value", "valid_range", "valid_integer",
    "valid_dir_path", "valid_file_path", "valid_path", "valid_list",
    "valid_dict", "valid_program", "valid_length", "valid_float",
    "valid_date_time"
]

for func_name in func_names:
    cmd_buf = func_name \
        + ".__doc__ = customize_doc_string(gv.raw_doc_strings['" \
        + func_name + "'])"
    exec(cmd_buf)
