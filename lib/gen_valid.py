#!/usr/bin/env python

r"""
This module provides valuable argument processing functions like
gen_get_options and sprint_args.
"""

import sys
import os

import gen_print as gp


def svalid_value(var_value,
                 invalid_values=[],
                 valid_values=[],
                 var_name=""):
    r"""
    Return an empty string if var_value is a valid value.  Otherwise, return
    an error string.

    Description of arguments:
    var_value                       The value being validated.
    invalid_values                  A list of invalid values.  If var_value is
                                    equal to any of these, it is invalid.
                                    Note that if you specify anything for
                                    invalid_values (below), the valid_values
                                    list is not even processed.
    valid_values                    A list of invalid values.  var_value must
                                    be equal to one of these values to be
                                    considered valid.
    var_name                        The name of the variable whose value is
                                    passed in var_value.  This parameter is
                                    normally unnecessary as this function can
                                    figure out the var_name.  This is provided
                                    for Robot callers.  In this scenario, we
                                    are unable to get the variable name
                                    ourselves.
    """

    success_message = ""
    error_message = ""
    stack_frame_ix = 3

    len_valid_values = len(valid_values)
    len_invalid_values = len(invalid_values)
    if len_valid_values > 0 and len_invalid_values > 0:
        error_message += "Programmer error - You must provide either an" +\
                         " invalid_values list or a valid_values" +\
                         " list but NOT both.\n" +\
                         gp.sprint_var(invalid_values) +\
                         gp.sprint_var(valid_values)
        return error_message

    show_blanks = 1
    if len_valid_values > 0:
        # Processing the valid_values list.
        if var_value in valid_values:
            return success_message
        if var_name == "":
            var_name = gp.get_arg_name(0, 1, stack_frame_ix)
        error_message += "The following variable has an invalid" +\
                         " value:\n" +\
                         gp.sprint_varx(var_name, var_value, show_blanks) +\
                         "\nIt must be one of the following values:\n" +\
                         gp.sprint_varx("valid_values", valid_values,
                                        show_blanks)
        return error_message

    if len_invalid_values == 0:
        # Assign default value.
        invalid_values = [""]

    # Assertion: We have an invalid_values list.  Processing it now.
    if var_value not in invalid_values:
        return success_message

    if var_name == "":
        var_name = gp.get_arg_name(0, 1, stack_frame_ix)
    error_message += "The following variable has an invalid value:\n" +\
                     gp.sprint_varx(var_name, var_value, show_blanks) +\
                     "\nIt must NOT be one of the following values:\n" +\
                     gp.sprint_varx("invalid_values", invalid_values,
                                    show_blanks)
    return error_message


def valid_value(var_value,
                invalid_values=[],
                valid_values=[],
                var_name=""):
    r"""
    Return True if var_value is a valid value.  Otherwise, return False and
    print an error message to stderr.

    Description of arguments:
    (See description of arguments for svalid_value (above)).
    """

    error_message = svalid_value(var_value, invalid_values, valid_values,
                                 var_name)

    if not error_message == "":
        gp.print_error_report(error_message)
        return False
    return True


def svalid_integer(var_value,
                   var_name=""):
    r"""
    Return an empty string if var_value is a valid integer.  Otherwise, return
    an error string.

    Description of arguments:
    var_value                       The value being validated.
    var_name                        The name of the variable whose value is
                                    passed in var_value.  This parameter is
                                    normally unnecessary as this function can
                                    figure out the var_name.  This is provided
                                    for Robot callers.  In this scenario, we
                                    are unable to get the variable name
                                    ourselves.
    """

    success_message = ""
    error_message = ""
    try:
        if type(int(str(var_value), 0)) is int:
            return success_message
    except ValueError:
        pass

    # If we get to this point, the validation has failed.
    if var_name is "":
        stack_index = 3
        var_name = gp.get_arg_name(0, 1, stack_index)

    show_blanks = 1
    error_message += "Invalid integer value:\n" +\
                     gp.sprint_varx(var_name, var_value, show_blanks)

    return error_message


def valid_integer(var_value,
                  var_name=""):
    r"""
    Return True if var_value is a valid integer.  Otherwise, return False and
    print an error message to stderr.

    Description of arguments:
    (See description of arguments for svalid_value (above)).
    """

    error_message = svalid_integer(var_value, var_name)

    if not error_message == "":
        gp.print_error_report(error_message)
        return False
    return True


def svalid_dir_path(var_value,
                    var_name=""):
    r"""
    Return an empty string if var_value is a valid directory path.  Otherwise,
    return an error string.

    Description of arguments:
    var_value                       The value being validated.
    var_name                        The name of the variable whose value is
                                    passed in var_value.  This parameter is
                                    normally unnecessary as this function can
                                    figure out the var_name.  This is provided
                                    for Robot callers.  In this scenario, we
                                    are unable to get the variable name
                                    ourselves.
    """

    error_message = ""
    if not os.path.isdir(str(var_value)):
        if var_name is "":
            stack_index = 3
            var_name = gp.get_arg_name(0, 1, stack_index)
        error_message += "The following directory does not exist:\n" +\
                         gp.sprint_varx(var_name, var_value)

    return error_message


def valid_dir_path(var_value,
                   var_name=""):
    r"""
    Return True if var_value is a valid integer.  Otherwise, return False and
    print an error message to stderr.

    Description of arguments:
    (See description of arguments for svalid_value (above)).
    """

    error_message = svalid_dir_path(var_value, var_name)

    if not error_message == "":
        gp.print_error_report(error_message)
        return False

    return True


def svalid_file_path(var_value,
                     var_name=""):
    r"""
    Return an empty string if var_value is a valid file path.  Otherwise,
    return an error string.

    Description of arguments:
    var_value                       The value being validated.
    var_name                        The name of the variable whose value is
                                    passed in var_value.  This parameter is
                                    normally unnecessary as this function can
                                    figure out the var_name.  This is provided
                                    for Robot callers.  In this scenario, we
                                    are unable to get the variable name
                                    ourselves.
    """

    error_message = ""
    if not os.path.isfile(str(var_value)):
        if var_name is "":
            stack_index = 3
            var_name = gp.get_arg_name(0, 1, stack_index)
        error_message += "Invalid file (does not exist):\n" +\
                         gp.sprint_varx(var_name, var_value)

    return error_message


def valid_file_path(var_value,
                    var_name=""):
    r"""
    Return True if var_value is a valid integer.  Otherwise, return False and
    print an error message to stderr.

    Description of arguments:
    (See description of arguments for svalid_value (above)).
    """

    error_message = svalid_file_path(var_value, var_name)

    if not error_message == "":
        gp.print_error_report(error_message)
        return False

    return True
