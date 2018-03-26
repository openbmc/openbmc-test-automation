#!/usr/bin/env python

r"""
This module contains utility and wrapper functions useful to robot python
programs.
"""

import re
from robot.libraries.BuiltIn import BuiltIn


def my_import_resource(path):
    r"""
    Import the resource file specified in path.

    Description of arguments:
    path   The path to your resource file.

    This function is a wrapper for BuiltIn().import_resource() and provides
    the following benefits:
    - When you invoke a robot program from a command line, you may specify
      program parameters as follows:

      -v --variable name:values

      For example:

      robot -v parm_x:1 file_x.robot

      When you do "Resource utils_x.robot" in a .robot program, it processes
      "utils_x.robot" BEFORE your command line parms are processed, as one
      might expect.  On the other hand, if one of your python library files
      were to run BuiltIn().import_resource("utils_x.robot"), it will process
      "utils_x.robot" AFTER your program parms are processed.  Let's suppose
      that utils_x.robot contains the following:

      *** Variables ***
      ${parm_x}  ${0}

      If your program is invoked like this:

      robot -v parm_x:3 file_x.robot

      And if your program has a python library file that invokes
      BuiltIn().import_resource("utils_x.robot"), then parm_x will get set to
      ${0}.  In other words, instead of utils_x.robot serving to set a default
      value for parm_x, it actually causes the user's specification of
      "-v parm_x:3" to be overwritten.

      This function will remedy that problem by keeping your -v parms intact.

    - The problems with -v parms mentioned above are also found with variables
      from your file_x.robot "** Variables **" section.  Namely, they may get
      overwritten when import_resource() is used.  This function will likewise
      remedy that problem.

    """

    # Retrieve the values of all current variables into a dictionary.
    pre_var_dict = BuiltIn().get_variables()
    # Do the import.
    BuiltIn().import_resource(path)
    # Once again, retrieve the values of all current variables into a
    # dictionary.
    post_var_dict = BuiltIn().get_variables()

    # If any variable values were changed due to the prior import, set them
    # back to their original values.
    for key, value in post_var_dict.iteritems():
        if key in pre_var_dict:
            if value != pre_var_dict[key]:
                global_var_name = re.sub("[@&]", "$", key)
                BuiltIn().set_global_variable(global_var_name,
                                              pre_var_dict[key])
