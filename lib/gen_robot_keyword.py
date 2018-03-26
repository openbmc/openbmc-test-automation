#!/usr/bin/env python

r"""
This module provides robot keyword execution functions such as run_key..
"""

import gen_print as gp
from robot.libraries.BuiltIn import BuiltIn


def run_key(keyword_buf,
            quiet=None,
            test_mode=None,
            ignore=0):
    r"""
    Run the given keyword, return the status and the keyword return values.

    The advantage of using this function verses having robot simply run your
    keyword is the handling of parameters like quiet, test_mode and ignore.

    Description of arguments:
    keyword_buf                     The keyword string to be run.
    quiet                           Indicates whether this function should run
                                    the pissuing function to print 'Issuing:
                                    <keyword string>' to stdout.
    test_mode                       If test_mode is set, this function will
                                    not actually run the command.  If quiet is
                                    0, it will print a message indicating what
                                    it would have run (e.g. "Issuing:
                                    (test_mode) your command").
    ignore                          Ignore errors from running keyword.  If
                                    this is 0, this function will fail with
                                    whatever error occurred when running the
                                    keyword.

    Example usage from a robot script:

    ${status}  ${ret_values}=  Run Key  My Keyword \ Arg1 \ Arg2

    Note that to get robot to pass your command + args as a single string to
    this function, you must escape extra spaces with a backslash.

    Also note that ret_values is a python list:
    ret_values:
      ret_values[0]:    value1
      ret_values[1]:    value2
    """

    # Set these vars to default values if they are None.
    quiet = int(gp.get_var_value(quiet, 0))
    test_mode = int(gp.get_var_value(test_mode, 0))
    ignore = int(ignore)

    # Convert the keyword_buf into a list split wherever 2 or more spaces are
    # found.
    keyword_list = keyword_buf.split('  ')
    # Strip spaces from each argument to make the output look clean and
    # uniform.
    keyword_list = [item.strip(' ') for item in keyword_list]

    if not quiet:
        # Join the list back into keyword_buf for the sake of output.
        keyword_buf = '  '.join(keyword_list)
        gp.pissuing(keyword_buf, test_mode)

    if test_mode:
        return 'PASS', ""

    try:
        status, ret_values = \
            BuiltIn().run_keyword_and_ignore_error(*keyword_list)
    except Exception as my_assertion_error:
        status = "FAIL"
        ret_values = my_assertion_error.args[0]

    if not (status == 'PASS' or ignore):
        # Output the error message to stderr.
        BuiltIn().log_to_console(ret_values, stream='STDERR')
        # Fail with the given error message.
        BuiltIn().fail(ret_values)

    return status, ret_values


def run_key_u(keyword_buf,
              quiet=None,
              ignore=0):
    r"""
    Run keyword unconditionally (i.e. without regard to global test_mode
    setting).

    This function will simply call the run_key function passing on all of the
    callers parameters except test_mode which will be hard-coded to 0.  See
    run_key (above) for details.

    See the proglog of "run_key" function above for description of arguments.
    """

    return run_key(keyword_buf, test_mode=0, quiet=quiet, ignore=ignore)
