#!/usr/bin/env python

# This module provides valuable argument processing functions like
# gen_get_options and sprint_args.

import sys

import gen_print as gp

PASS = 1
FAIL = 0


###############################################################################
def valid_value(var_value,
                invalid_values=[""],
                valid_values=[]):

    r"""
    Return PASS if var_value is a valid value.  Otherwise, return FAIL and
    print an error message to stderr.

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
    """

    len_valid_values = len(valid_values)
    len_invalid_values = len(invalid_values)
    if len_valid_values > 0 and len_invalid_values > 0:
        gp.print_error_report("Programmer error - You must provide either an" +
                              " invalid_values list or a valid_values" +
                              " list but NOT both.")
        return FAIL

    if len_valid_values > 0:
        # Processing the valid_values list.
        if var_value in valid_values:
            return PASS
        var_name = gp.get_arg_name(0, 1, 2)
        gp.print_error_report("The following variable has an invalid" +
                              " value:\n" +
                              gp.sprint_varx(var_name, var_value) +
                              "\nIt must be one of the following values:\n" +
                              gp.sprint_varx("valid_values", valid_values))
        return FAIL

    if len_invalid_values == 0:
        gp.print_error_report("Programmer error - You must provide either an" +
                              " invalid_values list or a valid_values" +
                              " list.  Both are empty.")
        return FAIL

    # Assertion: We have an invalid_values list.  Processing it now.
    if var_value not in invalid_values:
        return PASS

    var_name = gp.get_arg_name(0, 1, 2)
    gp.print_error_report("The following variable has an invalid value:\n" +
                          gp.sprint_varx(var_name, var_value) + "\nIt must" +
                          " NOT be one of the following values:\n" +
                          gp.sprint_varx("invalid_values", invalid_values))
    return FAIL

###############################################################################


###############################################################################
def valid_integer(var_value):

    r"""
    Return PASS if var_value is a valid integer.  Otherwise, return FAIL and
    print an error message to stderr.

    Description of arguments:
    var_value                       The value being validated.
    """

    # This currently allows floats which is not good.

    try:
        if type(int(var_value)) is int:
            return PASS
    except ValueError:
        pass

    # If we get to this point, the validation has failed.

    var_name = gp.get_arg_name(0, 1, 2)
    gp.print_varx("var_name", var_name)

    gp.print_error_report("Invalid integer value:\n" +
                          gp.sprint_varx(var_name, var_value))

    return FAIL

###############################################################################
