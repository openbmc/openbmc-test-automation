#!/usr/bin/env python

r"""
This module provides many valuable functions such as my_parm_file.
"""

# sys and os are needed to get the program dir path and program name.
import sys
import os
import ConfigParser
import StringIO

import gen_print as gp


###############################################################################
def add_trailing_slash(path):

    r"""
    Add a trailing slash to path if it doesn't already have one and return it.

    """

    return os.path.normpath(path) + os.path.sep

###############################################################################


###############################################################################
def set_mod_global(var_value,
                   mod_name="__main__",
                   var_name=None):

    r"""
    Set a global variable for a given module.

    Description of arguments:
    var_value                       The value to set in the variable.
    mod_name                        The name of the module whose variable is
                                    to be set.
    var_name                        The name of the variable to set.  This
                                    defaults to the name of the variable used
                                    for var_value when calling this function.
    """

    try:
        module = sys.modules[mod_name]
    except KeyError:
        gp.print_error_report("Programmer error - The mod_name passed to" +
                              " this function is invalid:\n" +
                              gp.sprint_var(mod_name))
        raise ValueError('Programmer error.')

    if var_name is None:
        var_name = gp.get_arg_name(None, 1, 2)

    setattr(module, var_name, var_value)

###############################################################################


###############################################################################
def my_parm_file(prop_file_path):

    r"""
    Read a properties file, put the keys/values into a dictionary and return
    the dictionary.

    The properties file must have the following format:
    var_name<= or :>var_value
    Comment lines (those beginning with a "#") and blank lines are allowed and
    will be ignored.  Leading and trailing single or double quotes will be
    stripped from the value.  E.g.
    var1="This one"
    Quotes are stripped so the resulting value for var1 is:
    This one

    Description of arguments:
    prop_file_path                  The caller should pass the path to the
                                    properties file.
    """

    # ConfigParser expects at least one section header in the file (or you
    # get ConfigParser.MissingSectionHeaderError).  Properties files don't
    # need those so I'll write a dummy section header.

    string_file = StringIO.StringIO()
    # Write the dummy section header to the string file.
    string_file.write('[dummysection]\n')
    # Write the entire contents of the properties file to the string file.
    string_file.write(open(prop_file_path).read())
    # Rewind the string file.
    string_file.seek(0, os.SEEK_SET)

    # Create the ConfigParser object.
    config_parser = ConfigParser.ConfigParser()
    # Make the property names case-sensitive.
    config_parser.optionxform = str
    # Read the properties from the string file.
    config_parser.readfp(string_file)
    # Return the properties as a dictionary.
    return dict(config_parser.items('dummysection'))

###############################################################################


###############################################################################
def return_path_list():

    r"""
    This function will split the PATH environment variable into a PATH_LIST
    and return it.  Each element in the list will be normalized and have a
    trailing slash added.
    """

    PATH_LIST = os.environ['PATH'].split(":")
    PATH_LIST = [os.path.normpath(path) + os.sep for path in PATH_LIST]

    return PATH_LIST

###############################################################################


###############################################################################
def quote_bash_parm(parm):

    r"""
    Return the bash command line parm with single quotes if they are needed.

    Description of arguments:
    parm                            The string to be quoted.
    """

    # If any of these characters are found in the parm string, then the
    # string should be quoted.  This list is by no means complete and should
    # be expanded as needed by the developer of this function.
    bash_special_chars = set(' $')

    if any((char in bash_special_chars) for char in parm):
        return "'" + parm + "'"

    return parm

###############################################################################
