#!/usr/bin/env python

r"""
Define variable manipulation functions.
"""

import os

try:
    from robot.utils import DotDict
except ImportError:
    pass

import collections

import gen_print as gp
import gen_misc as gm


def create_var_dict(*args):

    r"""
    Create a dictionary whose keys/values are the arg names/arg values passed
    to it and return it to the caller.

    Note: The resulting dictionary will be ordered.

    Description of argument(s):
    *args  An unlimited number of arguments to be processed.

    Example use:

    first_name = 'Steve'
    last_name = 'Smith'
    var_dict = create_var_dict(first_name, last_name)

    gp.print_var(var_dict)

    The print-out of the resulting var dictionary is:
    var_dict:
      var_dict[first_name]:                           Steve
      var_dict[last_name]:                            Smith
    """

    try:
        result_dict = collections.OrderedDict()
    except AttributeError:
        result_dict = DotDict()

    arg_num = 1
    for arg in args:
        arg_name = gp.get_arg_name(None, arg_num, stack_frame_ix=2)
        result_dict[arg_name] = arg
        arg_num += 1

    return result_dict


default_record_delim = ':'
default_key_val_delim = '.'


def join_dict(dict,
              record_delim=default_record_delim,
              key_val_delim=default_key_val_delim):

    r"""
    Join a dictionary's keys and values into a string and return the string.

    Description of argument(s):
    dict                            The dictionary whose keys and values are
                                    to be joined.
    record_delim                    The delimiter to be used to separate
                                    dictionary pairs in the resulting string.
    key_val_delim                   The delimiter to be used to separate keys
                                    from values in the resulting string.

    Example use:

    gp.print_var(var_dict)
    str1 = join_dict(var_dict)
    gp.pvar(str1)

    Program output.
    var_dict:
      var_dict[first_name]:                           Steve
      var_dict[last_name]:                            Smith
    str1:
    first_name.Steve:last_name.Smith
    """

    format_str = '%s' + key_val_delim + '%s'
    return record_delim.join([format_str % (key, value) for (key, value) in
                             dict.items()])


def split_to_dict(string,
                  record_delim=default_record_delim,
                  key_val_delim=default_key_val_delim):

    r"""
    Split a string into a dictionary and return it.

    This function is the complement to join_dict.

    Description of argument(s):
    string                          The string to be split into a dictionary.
                                    The string must have the proper delimiters
                                    in it.  A string created by join_dict
                                    would qualify.
    record_delim                    The delimiter to be used to separate
                                    dictionary pairs in the input string.
    key_val_delim                   The delimiter to be used to separate
                                    keys/values in the input string.

    Example use:

    gp.print_var(str1)
    new_dict = split_to_dict(str1)
    gp.print_var(new_dict)


    Program output.
    str1:
    first_name.Steve:last_name.Smith
    new_dict:
      new_dict[first_name]:                           Steve
      new_dict[last_name]:                            Smith
    """

    try:
        result_dict = collections.OrderedDict()
    except AttributeError:
        result_dict = DotDict()

    raw_keys_values = string.split(record_delim)
    for key_value in raw_keys_values:
        key_value_list = key_value.split(key_val_delim)
        try:
            result_dict[key_value_list[0]] = key_value_list[1]
        except IndexError:
            result_dict[key_value_list[0]] = ""

    return result_dict


def create_file_path(file_name_dict,
                     dir_path="/tmp/",
                     file_suffix=""):

    r"""
    Create a file path using the given parameters and return it.

    Description of argument(s):
    file_name_dict                  A dictionary with keys/values which are to
                                    appear as part of the file name.
    dir_path                        The dir_path that is to appear as part of
                                    the file name.
    file_suffix                     A suffix to be included as part of the
                                    file name.
    """

    dir_path = gm.add_trailing_slash(dir_path)
    return dir_path + join_dict(file_name_dict) + file_suffix


def parse_file_path(file_path):

    r"""
    Parse a file path created by create_file_path and return the result as a
    dictionary.

    This function is the complement to create_file_path.

    Description of argument(s):
    file_path                       The file_path.

    Example use:
    gp.pvar(boot_results_file_path)
    file_path_data = parse_file_path(boot_results_file_path)
    gp.pvar(file_path_data)

    Program output.

    boot_results_file_path:
    /tmp/pgm_name.obmc_boot_test:openbmc_nickname.beye6:master_pid.2039:boot_re
    sults
    file_path_data:
      file_path_data[dir_path]:                       /tmp/
      file_path_data[pgm_name]:                       obmc_boot_test
      file_path_data[openbmc_nickname]:               beye6
      file_path_data[master_pid]:                     2039
      file_path_data[boot_results]:
    """

    try:
        result_dict = collections.OrderedDict()
    except AttributeError:
        result_dict = DotDict()

    dir_path = os.path.dirname(file_path) + os.sep
    file_path = os.path.basename(file_path)

    result_dict['dir_path'] = dir_path

    result_dict.update(split_to_dict(file_path))

    return result_dict
