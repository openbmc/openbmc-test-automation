#!/usr/bin/env python

r"""
This module provides valuable argument processing functions like
gen_get_options and sprint_args.
"""

import os
import gen_print as gp

exit_on_error = False


def set_exit_on_error(value):
    r"""
    Set the exit_on_error value to either True or False.

    If exit_on_error is set, validation functions like valid_value will exit
    the program on error instead of returning False.

    Description of argument(s):
    value                           Value to set global exit_on_error to.
    """

    global exit_on_error
    exit_on_error = value


def get_var_name(var_name):
    r"""
    If var_name has a value, simply return it.  Otherwise, get the variable
    name of the first argument used to call the validation function (e.g.
    valid_value, valid_integer, etc.) and return it.

    This function is designed solely for use by other functions in this file.

    Example:

    A programmer codes this:

    valid_value(last_name)

    Which results in the following call stack:

    valid_value(last_name)
      -> svalid_value(var_value...)
        -> get_var_name(var_name)

    In this example, this function will return "last_name".

    Example:

    err_msg = svalid_value(last_name, var_name="some_other_name")

    Which results in the following call stack:

    svalid_value(var_value, var_name="some_other_name")
      -> get_var_name(var_name)

    In this example, this function will return "some_other_name".

    Description of argument(s):
    var_name                        The name of the variable.
    """

    if var_name != "":
        return var_name
    # Calculate stack_frame_ix.  The validation functions in this file come
    # in pairs.  There is an "s" version of each validation function (e.g.
    # svalid_value) whose job is to return an error message string.  Then
    # there is a wrapper function (e.g. valid_value) that will call the "s"
    # version and print the result if there is an error.  See examples 1 and 2
    # above for illustration.  This function must be cognizant of both
    # scenarios to accurately determine the name of the variable being
    # validated.  Where the "s" function is being called directly, the
    # stack_frame_ix should be set to 3.  Where the wrapper function is being
    # called, the stack_frame_ix should be incremented to 4.
    stack_frame_ix = 3
    parent_func_name = gp.sprint_func_name(2)
    grandparent_func_name = gp.sprint_func_name(3)
    if parent_func_name == "s" + grandparent_func_name:
        stack_frame_ix += 1
    var_name = gp.get_arg_name(0, 1, stack_frame_ix)
    return var_name


def process_error_message(error_message):
    r"""
    Process the error_message as follows:
    - If the error_message is blank, return True.
    - If the error_message contains a value:
        - Print the error_message as part of a full error report.
        - If global exit_on_error is set, then exit the program with a return
          code of 1.
        - If exit_on_error is not set, return False.

    This function is designed solely for use by wrapper functions in this file
    (e.g. "valid_value").

    Description of argument(s):
    error_message                   An error message.
    """

    if error_message == "":
        return True

    gp.print_error_report(error_message)
    if exit_on_error:
        exit(0)
    return False


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
                                    list is not even processed.  If you
                                    specify nothing for both invalid_values
                                    and valid_values, invalid_values will be
                                    set to a default value of [""].
    valid_values                    A list of valid values.  var_value must be
                                    equal to one of these values to be
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

    # Validate this function's arguments.
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
        error_message += "The following variable has an invalid" +\
                         " value:\n" +\
                         gp.sprint_varx(get_var_name(var_name), var_value,
                                        show_blanks) +\
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

    error_message += "The following variable has an invalid value:\n" +\
                     gp.sprint_varx(get_var_name(var_name), var_value,
                                    show_blanks) +\
                     "\nIt must NOT be one of the following values:\n" +\
                     gp.sprint_varx("invalid_values", invalid_values,
                                    show_blanks)
    return error_message


def valid_value(var_value,
                invalid_values=[],
                valid_values=[],
                var_name=""):
    r"""
    Return True if var_value is valid.  Otherwise, print an error message and
    either return False or exit(1) depending on the value of exit_on_error.

    Description of arguments:
    (See description of arguments for svalid_value (above)).
    """

    error_message = svalid_value(var_value, invalid_values, valid_values,
                                 var_name)
    return process_error_message(error_message)


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
        if isinstance(int(str(var_value), 0), int):
            return success_message
    except ValueError:
        pass

    # If we get to this point, the validation has failed.
    show_blanks = 1
    error_message +=\
        "Invalid integer value:\n" +\
        gp.sprint_varx(get_var_name(var_name), var_value, show_blanks)

    return error_message


def valid_integer(var_value,
                  var_name=""):
    r"""
    Return True if var_value is a valid integer.  Otherwise, print an error
    message and either return False or exit(1) depending on the value of
    exit_on_error.

    Description of arguments:
    (See description of arguments for svalid_integer (above)).
    """

    error_message = svalid_integer(var_value, var_name)
    return process_error_message(error_message)


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
        error_message += "The following directory does not exist:\n" +\
            gp.sprint_varx(get_var_name(var_name), var_value)

    return error_message


def valid_dir_path(var_value,
                   var_name=""):
    r"""
    Return True if var_value is a valid directory path.  Otherwise, print an
    error message and either return False or exit(1) depending on the value of
    exit_on_error.

    Valid means that the directory path exists.

    Description of arguments:
    (See description of arguments for svalid_dir_path (above)).
    """

    error_message = svalid_dir_path(var_value, var_name)
    return process_error_message(error_message)


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
        error_message += "Invalid file (does not exist):\n" +\
            gp.sprint_varx(get_var_name(var_name), var_value)

    return error_message


def valid_file_path(var_value,
                    var_name=""):
    r"""
    Return True if var_value is a valid file path.  Otherwise, print an error
    message and either return False or exit(1) depending on the value of
    exit_on_error.

    Valid means that the file exists.

    Description of arguments:
    (See description of arguments for svalid_file_path (above)).
    """

    error_message = svalid_file_path(var_value, var_name)
    return process_error_message(error_message)


def svalid_path(var_value,
                var_name=""):
    r"""
    Return an empty string if var_value is either a valid file path or
    directory path.  Otherwise, return an error string.

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
    if not (os.path.isfile(str(var_value)) or os.path.isdir(str(var_value))):
        error_message = "Invalid path (file or directory does not exist):\n" +\
            gp.sprint_varx(get_var_name(var_name), var_value)

    return error_message


def valid_path(var_value,
               var_name=""):
    r"""
    Return True if var_value is a valid file path.  Otherwise, print an error
    message and either return False or exit(1) depending on the value of
    exit_on_error.

    Valid means that the file exists.

    Description of arguments:
    (See description of arguments for svalid_path (above)).
    """

    error_message = svalid_path(var_value, var_name)
    return process_error_message(error_message)


def svalid_range(var_value,
                 valid_range=[],
                 var_name=""):
    r"""
    Return an empty string if var_value is within the range.  Otherwise,
    return an error string.

    Description of arguments:
    var_value                       The value being validated.  This value
                                    must be an integer.
    valid_range                     A list comprised of one or two elements
                                    which are the lower and upper ends of a
                                    range.  These values must be integers
                                    except where noted.  Valid specifications
                                    may be of the following forms: [lower,
                                    upper], [lower] or [None, upper].
    var_name                        The name of the variable whose value is
                                    passed in var_value.  This parameter is
                                    normally unnecessary as this function can
                                    figure out the var_name.  This is provided
                                    for Robot callers.  In this scenario, we
                                    are unable to get the variable name
                                    ourselves.
    """

    error_message = ""

    # Validate this function's parms:
    # First, ensure that the value is an integer.
    error_message = svalid_integer(var_value, var_name)
    if not error_message == "":
        return error_message
    var_value = int(var_value)

    len_valid_range = len(valid_range)
    if len_valid_range == 0 or len_valid_range > 2:
        error_message += "Programmer error - For the valid_range parameter," +\
                         " you must provide a list consisting of one or two" +\
                         " elements.\n" +\
                         gp.sprint_var(valid_range)
        return error_message

    if len_valid_range == 1 or valid_range[0] is not None:
        # Make sure lower valid_range value is an integer.
        error_message = svalid_integer(valid_range[0], "valid_range[0]")
        if not error_message == "":
            error_message = "Programmer error:\n" + error_message
            return error_message
    if valid_range[0] is not None:
        valid_range[0] = int(valid_range[0])
    if len_valid_range == 2:
        # Make sure upper valid_range value is an integer.
        error_message = svalid_integer(valid_range[1], "valid_range[1]")
        if not error_message == "":
            error_message = "Programmer error:\n" + error_message
            return error_message
        valid_range[1] = int(valid_range[1])
        if valid_range[0] is not None and valid_range[0] > valid_range[1]:
            error_message = "Programmer error - In the following range, the" +\
                            " lower limit is greater than the upper" +\
                            " limit:\n" + gp.sprint_varx("valid_range",
                                                         valid_range)
            return error_message

    if len_valid_range == 1:
        if var_value < valid_range[0]:
            error_message += "The following variable is not within the" +\
                             " expected range:\n" +\
                             gp.sprint_varx(get_var_name(var_name),
                                            var_value) +\
                             gp.sprint_varx("valid_range",
                                            str(valid_range[0]) + "..")
            return error_message
        return error_message

    if valid_range[0] is None:
        if var_value > valid_range[1]:
            error_message += "The following variable is not within the" +\
                             " expected range:\n" +\
                             gp.sprint_varx(get_var_name(var_name),
                                            var_value) +\
                             gp.sprint_varx("valid_range",
                                            ".." + str(valid_range[1]))
            return error_message

    if var_value < valid_range[0] or var_value > valid_range[1]:
        error_message += "The following variable is not within the expected" +\
                         " range:\n" +\
                         gp.sprint_varx(get_var_name(var_name), var_value) +\
                         gp.sprint_varx("valid_range",
                                        str(valid_range[0]) + ".."
                                        + str(valid_range[1]))
        return error_message

    return error_message


def valid_range(var_value,
                valid_range=[],
                var_name=""):
    r"""
    Return True if var_value is within range.  Otherwise, print an error
    message and either return False or exit(1) depending on the value of
    exit_on_error.

    Description of arguments:
    (See description of arguments for svalid_range (above)).
    """

    error_message = svalid_range(var_value, valid_range, var_name)
    return process_error_message(error_message)


def svalid_list(var_value,
                valid_values=[],
                var_name=""):
    r"""
    Return an empty string if var_value is a valid list.  Otherwise, return an
    error string.

    Description of arguments:
    var_value                       The value (i.e. list) being validated.
    valid_values                    A list of valid values.  Each element in
                                    the var_value list must be equal to one of
                                    these values to be considered valid.
    var_name                        The name of the variable whose value is
                                    passed in var_value.  This parameter is
                                    normally unnecessary as this function can
                                    figure out the var_name.  This is provided
                                    for Robot callers.  In this scenario, we
                                    are unable to get the variable name
                                    ourselves.
    """

    error_message = ""
    if len(var_value) == 0:
        show_blanks = 1
        error_message += "The \"" + get_var_name(var_name)
        error_message += "\" list is empty and is therefore invalid:\n"
        return error_message

    found_error = 0
    display_var_value = list(var_value)
    for ix in range(0, len(var_value)):
        if var_value[ix] not in valid_values:
            found_error = 1
            display_var_value[ix] = var_value[ix] + "*"

    if found_error:
        show_blanks = 1
        error_message += "The list entries marked with \"*\" are not valid:\n"
        error_message += gp.sprint_varx(get_var_name(var_name),
                                        display_var_value, show_blanks)
        error_message += gp.sprint_var(valid_values)
        return error_message

    return ""


def valid_list(var_value,
               valid_values=[],
               var_name=""):
    r"""
    Return True if var_value is a valid list.  Otherwise, print an error
    message and either return False or exit(1) depending on the value of
    exit_on_error.

    Description of arguments:
    (See description of arguments for svalid_list (above)).
    """

    error_message = svalid_list(var_value, valid_values, var_name)
    return process_error_message(error_message)
