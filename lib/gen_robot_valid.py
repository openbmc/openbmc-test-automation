#!/usr/bin/env python

r"""
This file contains functions useful for validating variables in robot.
"""

import gen_robot_print as grp
import gen_valid as gv
import gen_print as gp

from robot.libraries.BuiltIn import BuiltIn
from robot.api import logger


def rvalid_value(var_name,
                 invalid_values=[],
                 valid_values=[]):
    r"""
    Validate a robot value.

    This function is the robot wrapper for gen_robot_print.svalid_value.

    Description of arguments:
    var_name                        The name of the variable whose value is to
                                    be validated.
    invalid_values                  A list of invalid values.  If var_value is
                                    equal to any of these, it is invalid.
                                    Note that if you specify anything for
                                    invalid_values (below), the valid_values
                                    list is not even processed.
    valid_values                    A list of invalid values.  var_value must
                                    be equal to one of these values to be
                                    considered valid.

    Examples of robot calls and corresponding output:

    Robot code...
    rvalid_value                    MY_PARM

    Output...
    #(CDT) 2016/11/02 10:04:20 - **ERROR** Variable "MY_PARM" not found (i.e.
    #it's undefined).

    or if it is defined but blank:

    Output...
    #(CDT) 2016/11/02 10:14:24 - **ERROR** The following variable has an
    #invalid value:
    MY_PARM:

    It must NOT be one of the following values:
    invalid_values:
      invalid_values[0]:         <blank>

    Robot code...
    ${invalid_values}=  Create List  one  two  three
    ${MY_PARM}=  Set Variable  one
    rvalid_value                    MY_PARM  invalid_values=${invalid_values}

    Output...
    #(CDT) 2016/11/02 10:20:05 - **ERROR** The following variable has an
    #invalid value:
    MY_PARM:                     one

    It must NOT be one of the following values:
    invalid_values:
        invalid_values[0]:       one
        invalid_values[1]:       two
        invalid_values[2]:       three

    """

    # Note: get_variable_value() seems to have no trouble with local variables.
    var_value = BuiltIn().get_variable_value("${" + var_name + "}")

    if var_value is None:
        var_value = ""
        error_message = "Variable \"" + var_name +\
                        "\" not found (i.e. it's undefined).\n"
    else:
        error_message = gv.svalid_value(var_value, invalid_values,
                                        valid_values, var_name)
    if not error_message == "":
        error_message = grp.sprint_error_report(error_message)
        BuiltIn().fail(error_message)


def rvalid_integer(var_name):
    r"""
    Validate a robot integer.

    This function is the robot wrapper for gen_robot_print.svalid_integer.

    Description of arguments:
    var_name                        The name of the variable whose value is to
                                    be validated.

    Examples of robot calls and corresponding output:

    Robot code...
    Rvalid Integer  MY_PARM

    Output...
    #(CDT) 2016/11/02 10:44:43 - **ERROR** Variable "MY_PARM" not found (i.e.
    #it's undefined).

    or if it is defined but blank:

    Output...
    #(CDT) 2016/11/02 10:45:37 - **ERROR** Invalid integer value:
    MY_PARM:                     <blank>

    Robot code...
    ${MY_PARM}=  Set Variable  HELLO
    Rvalid Integer  MY_PARM

    Output...
    #(CDT) 2016/11/02 10:46:18 - **ERROR** Invalid integer value:
    MY_PARM:                     HELLO

    """

    # Note: get_variable_value() seems to have no trouble with local variables.
    var_value = BuiltIn().get_variable_value("${" + var_name + "}")

    if var_value is None:
        var_value = ""
        error_message = "Variable \"" + var_name +\
                        "\" not found (i.e. it's undefined).\n"
    else:
        error_message = gv.svalid_integer(var_value, var_name)
    if not error_message == "":
        error_message = grp.sprint_error_report(error_message)
        BuiltIn().fail(error_message)


def rvalid_range(var_name,
                 range):
    r"""
    Validate that a robot integer is within the given range

    This function is the robot wrapper for gen_robot_print.svalid_range.

    Description of arguments:
    var_name                        The name of the variable whose value is to
                                    be validated.
    range                           A list comprised of one or two elements
                                    which are the lower and upper ends of a
                                    range.  These values must be integers
                                    except where noted  Valid specifications
                                    may be of the following forms: [lower,
                                    upper], [lower] or [None, upper].  The
                                    caller may also specify this value as a
                                    string which will then be converted to a
                                    list in the aforementioned format:
                                    lower..upper, lower.. or ..upper.

    Examples of robot calls and corresponding output:

    Robot code...
    Rvalid Range  MY_PARM  5..9

    Output...
    #(CDT) 2018/05/09 11:45:00.166344 -    0.004252 - **ERROR** The following
    #variable is not within the expected range:
    MY_PARM:                                          4
    valid_range:                                      5..9
    """

    var_value = BuiltIn().get_variable_value("${" + var_name + "}")

    if var_value is None:
        var_value = ""
        error_message = "Variable \"" + var_name +\
                        "\" not found (i.e. it's undefined).\n"
    else:
        if type(range) is unicode:
            range = range.split("..")
        if range[0] == "":
            range[0] = None
        range = [x for x in range if x]
        error_message = gv.svalid_range(var_value, range, var_name)
    if not error_message == "":
        error_message = grp.sprint_error_report(error_message)
        BuiltIn().fail(error_message)
