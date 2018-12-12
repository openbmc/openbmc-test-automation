#!/usr/bin/env python

r"""
This module provides functions which are useful for running plug-ins.
"""

import sys
import os
import glob

import gen_print as gp
import gen_misc as gm

# Some help text that is common to more than one program.
plug_in_dir_paths_help_text = \
    'This is a colon-separated list of plug-in directory paths.  If one' +\
    ' of the entries in the list is a plain directory name (i.e. no' +\
    ' path info), it will be taken to be a native plug-in.  In that case,' +\
    ' %(prog)s will search for the native plug-in in the "plug-ins"' +\
    ' subdirectory of each path in the PATH environment variable until it' +\
    ' is found.  Also, integrated plug-ins will automatically be appended' +\
    ' to your plug_in_dir_paths list.  An integrated plug-in is any plug-in' +\
    ' found using the PATH variable that contains a file named "integrated".'

mch_class_help_text = \
    'The class of machine that we are testing (e.g. "op" = "open power",' +\
    ' "obmc" = "open bmc", etc).'

PATH_LIST = gm.return_path_list()


def get_plug_in_base_paths():
    r"""
    Get plug-in base paths and return them as a list.

    This function searches the PATH_LIST (created from PATH environment
    variable) for any paths that have a "plug_ins" subdirectory.  All such
    paths are considered plug_in_base paths.
    """

    global PATH_LIST

    plug_in_base_path_list = []

    for path in PATH_LIST:
        candidate_plug_in_base_path = path + "plug_ins/"
        if os.path.isdir(candidate_plug_in_base_path):
            plug_in_base_path_list.append(candidate_plug_in_base_path)

    return plug_in_base_path_list


# Define global plug_in_base_path_list and call get_plug_in_base_paths to set
# its value.
plug_in_base_path_list = get_plug_in_base_paths()


def find_plug_in_package(plug_in_name):
    r"""
    Find and return the normalized directory path of the specified plug in.
    This is done by searching the global plug_in_base_path_list.

    Description of arguments:
    plug_in_name                    The unqualified name of the plug-in
                                    package.
    """

    global plug_in_base_path_list
    for plug_in_base_dir_path in plug_in_base_path_list:
        candidate_plug_in_dir_path = os.path.normpath(plug_in_base_dir_path
                                                      + plug_in_name) + \
            os.sep
        if os.path.isdir(candidate_plug_in_dir_path):
            return candidate_plug_in_dir_path

    return ""


def validate_plug_in_package(plug_in_dir_path,
                             mch_class="obmc"):
    r"""
    Validate the plug in package and return the normalized plug-in directory
    path.

    Description of arguments:
    plug_in_dir_path                The "relative" or absolute path to a plug
                                    in package directory.
    mch_class                       The class of machine that we are testing
                                    (e.g. "op" = "open power", "obmc" = "open
                                    bmc", etc).
    """

    gp.dprint_executing()

    if os.path.isabs(plug_in_dir_path):
        # plug_in_dir_path begins with a slash so it is an absolute path.
        candidate_plug_in_dir_path = os.path.normpath(plug_in_dir_path) +\
            os.sep
        if not os.path.isdir(candidate_plug_in_dir_path):
            gp.print_error_report("Plug-in directory path \""
                                  + plug_in_dir_path + "\" does not exist.\n")
            exit(1)
    else:
        # The plug_in_dir_path is actually a simple name (e.g.
        # "OBMC_Sample")...
        candidate_plug_in_dir_path = find_plug_in_package(plug_in_dir_path)
        if candidate_plug_in_dir_path == "":
            global PATH_LIST
            gp.print_error_report("Plug-in directory path \""
                                  + plug_in_dir_path + "\" could not be found"
                                  + " in any of the following directories:\n"
                                  + gp.sprint_var(PATH_LIST))
            exit(1)
    # Make sure that this plug-in supports us...
    supports_file_path = candidate_plug_in_dir_path + "supports_" + mch_class
    if not os.path.exists(supports_file_path):
        gp.print_error_report("The following file path could not be"
                              + " found:\n"
                              + gp.sprint_varx("supports_file_path",
                                               supports_file_path)
                              + "\nThis file is necessary to indicate that"
                              + " the given plug-in supports the class of"
                              + " machine we are testing, namely \""
                              + mch_class + "\".\n")
        exit(1)

    return candidate_plug_in_dir_path


def return_integrated_plug_ins(mch_class="obmc"):
    r"""
    Return a list of integrated plug-ins.  Integrated plug-ins are plug-ins
    which are selected without regard for whether the user has specified them.
    In other words, they are "integrated" into the program suite.  The
    programmer designates a plug-in as integrated by putting a file named
    "integrated" into the plug-in package directory.

    Description of arguments:
    mch_class                       The class of machine that we are testing
                                    (e.g. "op" = "open power", "obmc" = "open
                                    bmc", etc).
    """

    global plug_in_base_path_list

    integrated_plug_ins_list = []

    DEBUG_SKIP_INTEGRATED = int(os.getenv('DEBUG_SKIP_INTEGRATED', '0'))

    if DEBUG_SKIP_INTEGRATED:
        return integrated_plug_ins_list

    for plug_in_base_path in plug_in_base_path_list:
        # Get a list of all plug-in paths that support our mch_class.
        mch_class_candidate_list = glob.glob(plug_in_base_path
                                             + "*/supports_" + mch_class)
        for candidate_path in mch_class_candidate_list:
            integrated_plug_in_dir_path = os.path.dirname(candidate_path) +\
                os.sep
            integrated_file_path = integrated_plug_in_dir_path + "integrated"
            if os.path.exists(integrated_file_path):
                plug_in_name = \
                    os.path.basename(os.path.dirname(candidate_path))
                if plug_in_name not in integrated_plug_ins_list:
                    # If this plug-in has not already been added to the list...
                    integrated_plug_ins_list.append(plug_in_name)

    return integrated_plug_ins_list


def return_plug_in_packages_list(plug_in_dir_paths,
                                 mch_class="obmc"):
    r"""
    Return a list of plug-in packages given the plug_in_dir_paths string.
    This function calls validate_plug_in_package so it will fail if
    plug_in_dir_paths contains any invalid plug-ins.

    Description of arguments:
    plug_in_dir_path                The "relative" or absolute path to a plug
                                    in package directory.
    mch_class                       The class of machine that we are testing
                                    (e.g. "op" = "open power", "obmc" = "open
                                    bmc", etc).
    """

    if plug_in_dir_paths != "":
        plug_in_packages_list = plug_in_dir_paths.split(":")
    else:
        plug_in_packages_list = []

    # Get a list of integrated plug-ins (w/o full path names).
    integrated_plug_ins_list = return_integrated_plug_ins(mch_class)
    # Put both lists together in plug_in_packages_list with no duplicates.
    # NOTE: This won't catch duplicates if the caller specifies the full path
    # name of a native plug-in but that should be rare enough.

    plug_in_packages_list = plug_in_packages_list + integrated_plug_ins_list

    plug_in_packages_list = \
        list(set([validate_plug_in_package(path, mch_class)
                  for path in plug_in_packages_list]))

    return plug_in_packages_list
