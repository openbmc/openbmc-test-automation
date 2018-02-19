#!/usr/bin/env python

r"""
Define variable manipulation functions.
"""

import os
import re

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


def parse_key_value(string,
                    delim=":",
                    strip=" ",
                    to_lower=1,
                    underscores=1):

    r"""
    Parse a key/value string and return as a key/value tuple.

    This function is useful for parsing a line of program output or data that
    is in the following form:
    <key or variable name><delimiter><value>

    An example of a key/value string would be as follows:

    Current Limit State: No Active Power Limit

    In the example shown, the delimiter is ":".  The resulting key would be as
    follows:
    Current Limit State

    Note: If one were to take the default values of to_lower=1 and
    underscores=1, the resulting key would be as follows:
    current_limit_state

    The to_lower and underscores arguments are provided for those who wish to
    have their key names have the look and feel of python variable names.

    The resulting value for the example above would be as follows:
    No Active Power Limit

    Another example:
    name=Mike

    In this case, the delim would be "=", the key is "name" and the value is
    "Mike".

    Description of argument(s):
    string                          The string to be parsed.
    delim                           The delimiter which separates the key from
                                    the value.
    strip                           The characters (if any) to strip from the
                                    beginning and end of both the key and the
                                    value.
    to_lower                        Change the key name to lower case.
    underscores                     Change any blanks found in the key name to
                                    underscores.
    """

    pair = string.split(delim)

    key = pair[0].strip(strip)
    if len(pair) == 0:
        value = ""
    else:
        value = delim.join(pair[1:]).strip(strip)

    if to_lower:
        key = key.lower()
    if underscores:
        key = re.sub(r" ", "_", key)

    return key, value


def key_value_list_to_dict(list,
                           process_indent=0,
                           **args):

    r"""
    Convert a list containing key/value strings to a dictionary and return it.

    See docstring of parse_key_value function for details on key/value strings.

    Example usage:

    For the following value of list:

    list:
      list[0]:          Current Limit State: No Active Power Limit
      list[1]:          Exception actions:   Hard Power Off & Log Event to SEL
      list[2]:          Power Limit:         0 Watts
      list[3]:          Correction time:     0 milliseconds
      list[4]:          Sampling period:     0 seconds

    And the following call in python:

    power_limit = key_value_outbuf_to_dict(list)

    The resulting power_limit directory would look like this:

    power_limit:
      [current_limit_state]:        No Active Power Limit
      [exception_actions]:          Hard Power Off & Log Event to SEL
      [power_limit]:                0 Watts
      [correction_time]:            0 milliseconds
      [sampling_period]:            0 seconds

    Another example containing a sub-list (see process_indent description
    below):

    Provides Device SDRs      : yes
    Additional Device Support :
        Sensor Device
        SEL Device
        FRU Inventory Device
        Chassis Device

    Note that the 2 qualifications for containing a sub-list are met: 1)
    'Additional Device Support' has no value and 2) The entries below it are
    indented.  In this case those entries contain no delimiters (":") so they
    will be processed as a list rather than as a dictionary.  The result would
    be as follows:

    mc_info:
      mc_info[provides_device_sdrs]:            yes
      mc_info[additional_device_support]:
        mc_info[additional_device_support][0]:  Sensor Device
        mc_info[additional_device_support][1]:  SEL Device
        mc_info[additional_device_support][2]:  FRU Inventory Device
        mc_info[additional_device_support][3]:  Chassis Device

    Description of argument(s):
    list                            A list of key/value strings.  (See
                                    docstring of parse_key_value function for
                                    details).
    process_indent                  This indicates that indented
                                    sub-dictionaries and sub-lists are to be
                                    processed as such.  An entry may have a
                                    sub-dict or sub-list if 1) It has no value
                                    other than blank 2) There are entries
                                    below it that are indented.
    **args                          Arguments to be interpreted by
                                    parse_key_value.  (See docstring of
                                    parse_key_value function for details).
    """

    try:
        result_dict = collections.OrderedDict()
    except AttributeError:
        result_dict = DotDict()

    if not process_indent:
        for entry in list:
            key, value = parse_key_value(entry, **args)
            result_dict[key] = value
        return result_dict

    # Process list while paying heed to indentation.
    delim = args.get("delim", ":")
    # Initialize "parent_" indentation level variables.
    parent_indent = len(list[0]) - len(list[0].lstrip())
    sub_list = []
    for entry in list:
        key, value = parse_key_value(entry, **args)

        indent = len(entry) - len(entry.lstrip())

        if indent > parent_indent and parent_value == "":
            # This line is indented compared to the parent entry and the
            # parent entry has no value.
            # Append the entry to sub_list for later processing.
            sub_list.append(str(entry))
            continue

        # Process any outstanding sub_list and add it to
        # result_dict[parent_key].
        if len(sub_list) > 0:
            if any(delim in word for word in sub_list):
                # If delim is found anywhere in the sub_list, we'll process
                # as a sub-dictionary.
                result_dict[parent_key] = key_value_list_to_dict(sub_list,
                                                                 **args)
            else:
                result_dict[parent_key] = map(str.strip, sub_list)
            del sub_list[:]

        result_dict[key] = value

        parent_key = key
        parent_value = value
        parent_indent = indent

    # Any outstanding sub_list to be processed?
    if len(sub_list) > 0:
        if any(delim in word for word in sub_list):
            # If delim is found anywhere in the sub_list, we'll process as a
            # sub-dictionary.
            result_dict[parent_key] = key_value_list_to_dict(sub_list, **args)
        else:
            result_dict[parent_key] = map(str.strip, sub_list)

    return result_dict


def key_value_outbuf_to_dict(out_buf,
                             **args):

    r"""
    Convert a buffer with a key/value string on each line to a dictionary and
    return it.

    Each line in the out_buf should end with a \n.

    See docstring of parse_key_value function for details on key/value strings.

    Example usage:

    For the following value of out_buf:

    Current Limit State: No Active Power Limit
    Exception actions:   Hard Power Off & Log Event to SEL
    Power Limit:         0 Watts
    Correction time:     0 milliseconds
    Sampling period:     0 seconds

    And the following call in python:

    power_limit = key_value_outbuf_to_dict(out_buf)

    The resulting power_limit directory would look like this:

    power_limit:
      [current_limit_state]:        No Active Power Limit
      [exception_actions]:          Hard Power Off & Log Event to SEL
      [power_limit]:                0 Watts
      [correction_time]:            0 milliseconds
      [sampling_period]:            0 seconds

    Description of argument(s):
    out_buf                         A buffer with a key/value string on each
                                    line. (See docstring of parse_key_value
                                    function for details).
    **args                          Arguments to be interpreted by
                                    parse_key_value.  (See docstring of
                                    parse_key_value function for details).
    """

    # Create key_var_list and remove null entries.
    key_var_list = list(filter(None, out_buf.split("\n")))
    return key_value_list_to_dict(key_var_list, **args)


def list_to_report(report_list,
                   to_lower=1):

    r"""
    Convert a list containing report text lines to a report "object" and
    return it.

    The first entry in report_list must be a header line consisting of column
    names delimited by white space.  No column name may contain white space.
    The remaining report_list entries should contain tabular data which
    corresponds to the column names.

    A report object is a list where each entry is a dictionary whose keys are
    the field names from the first entry in report_list.

    Example:
    Given the following report_list as input:

    rl:
      rl[0]: Filesystem           1K-blocks      Used Available Use% Mounted on
      rl[1]: dev                     247120         0    247120   0% /dev
      rl[2]: tmpfs                   248408     79792    168616  32% /run

    This function will return a list of dictionaries as shown below:

    df_report:
      df_report[0]:
        [filesystem]:                  dev
        [1k-blocks]:                   247120
        [used]:                        0
        [available]:                   247120
        [use%]:                        0%
        [mounted]:                     /dev
      df_report[1]:
        [filesystem]:                  dev
        [1k-blocks]:                   247120
        [used]:                        0
        [available]:                   247120
        [use%]:                        0%
        [mounted]:                     /dev

    Notice that because "Mounted on" contains a space, "on" would be
    considered the 7th field.  In this case, there is never any data in field
    7 so things work out nicely.  A caller could do some pre-processing if
    desired (e.g. change "Mounted on" to "Mounted_on").

    Description of argument(s):
    report_list                     A list where each entry is one line of
                                    output from a report.  The first entry
                                    must be a header line which contains
                                    column names.  Column names may not
                                    contain spaces.
    to_lower                        Change the resulting key names to lower
                                    case.
    """

    # Process header line.
    header_line = report_list[0]
    if to_lower:
        header_line = header_line.lower()
    columns = header_line.split()

    report_obj = []
    for report_line in report_list[1:]:
        line = report_list[1].split()
        try:
            line_dict = collections.OrderedDict(zip(columns, line))
        except AttributeError:
            line_dict = DotDict(zip(columns, line))
        report_obj.append(line_dict)

    return report_obj


def outbuf_to_report(out_buf,
                     **args):

    r"""
    Convert a text buffer containing report lines to a report "object" and
    return it.

    Refer to list_to_report (above) for more details.

    Example:

    Given the following out_buf:

    Filesystem           1K-blocks      Used Available Use% Mounted on
    dev                  247120         0    247120   0% /dev
    tmpfs                248408     79792    168616  32% /run

    This function will return a list of dictionaries as shown below:

    df_report:
      df_report[0]:
        [filesystem]:                  dev
        [1k-blocks]:                   247120
        [used]:                        0
        [available]:                   247120
        [use%]:                        0%
        [mounted]:                     /dev
      df_report[1]:
        [filesystem]:                  dev
        [1k-blocks]:                   247120
        [used]:                        0
        [available]:                   247120
        [use%]:                        0%
        [mounted]:                     /dev

    Other possible uses:
    - Process the output of a ps command.
    - Process the output of an ls command (the caller would need to supply
    column names)

    Description of argument(s):
    out_buf                         A text report  The first line must be a
                                    header line which contains column names.
                                    Column names may not contain spaces.
    **args                          Arguments to be interpreted by
                                    list_to_report.  (See docstring of
                                    list_to_report function for details).
    """

    report_list = filter(None, out_buf.split("\n"))
    return list_to_report(report_list, **args)
