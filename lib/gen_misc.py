#!/usr/bin/env python

r"""
This module provides many valuable functions such as my_parm_file.
"""

# sys and os are needed to get the program dir path and program name.
import sys
import os
import ConfigParser
import StringIO

# python puts the program's directory path in sys.path[0].  In other words,
# the user ordinarily has no way to override python's choice of a module from
# its own dir.  We want to have that ability in our environment.  However, we
# don't want to break any established python modules that depend on this
# behavior.  So, we'll save the value from sys.path[0], delete it, import our
# modules and then restore sys.path to its original value.

save_path_0 = sys.path[0]
del sys.path[0]

import gen_print as gp

# Restore sys.path[0].
sys.path.insert(0, save_path_0)


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
