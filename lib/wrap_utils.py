#!/usr/bin/env python

r"""
This module provides functions which are useful for writing python wrapper
functions (i.e. in this context, a wrapper function is one whose aim is to
call some other function on the caller's behalf but to provide some additional
functionality over and above what the base function provides).
"""

import sys
import inspect


def create_wrapper_def_and_call(base_func_name,
                                wrap_func_name):
    r"""
    Return a wrapper function definition line and a base function call line.

    This is a utility for helping to create wrapper functions.

    For example, if there existed a function with the following definition
    line:
    def sprint_foo_bar(headers=1):

    And the user wished to write a print_foo_bar wrapper function, they could
    call create_wrapper_def_and_call as follows:

    func_def_line, call_line = create_wrapper_def_and_call("sprint_foo_bar",
                                                           "print_foo_bar")

    They would get the following results:
    func_def_line                   def print_foo_bar(headers=1):
    call_line                       sprint_foo_bar(headers=headers)

    The func_def_line is suitable as the definition line for the wrapper
    function.  The call_line is suitable for use in the new wrapper function
    wherever it wishes to call the base function.  By explicitly specifying
    each parm in the definition and the call line, we allow the caller of the
    wrapper function to refer to any given parm by name rather than having to
    specify parms positionally.

    Description of argument(s):
    base_func_name                  The name of the base function around which
                                    a wrapper is being created.
    wrap_func_name                  The name of the wrapper function being
                                    created.
    """

    # Get caller's module name.  Note: that for the present we've hard-coded
    # the stack_frame_ix value because we expect a call stack to this function
    # to be something like this:
    # caller
    #   create_print_wrapper_funcs
    #     create_func_def_string
    #       create_wrapper_def_and_call
    stack_frame_ix = 3
    frame = inspect.stack()[stack_frame_ix]
    module = inspect.getmodule(frame[0])
    mod_name = module.__name__

    # Get a reference to the base function.
    base_func = getattr(sys.modules[mod_name], base_func_name)
    # Get the argument specification for the base function.
    base_arg_spec = inspect.getargspec(base_func)
    base_arg_list = base_arg_spec[0]
    num_args = len(base_arg_list)
    # Get the variable argument specification for the base function.
    var_args = base_arg_spec[1]
    if var_args is None:
        var_args = []
    else:
        var_args = ["*" + var_args]
    if base_arg_spec[3] is None:
        base_default_list = []
    else:
        base_default_list = list(base_arg_spec[3])
    num_defaults = len(base_default_list)
    num_non_defaults = num_args - num_defaults

    # Create base_arg_default_string which is a reconstruction of the base
    # function's argument list.
    # Example base_arg_default_string:
    # headers, last=2, first=[1]
    # First, create a new list where each entry is of the form "arg=default".
    base_arg_default_list = list(base_arg_list)
    for ix in range(num_non_defaults, len(base_arg_default_list)):
        base_default_ix = ix - num_non_defaults
        if type(base_default_list[base_default_ix]) is str:
            default_string = "'" + base_default_list[base_default_ix] + "'"
            # Convert "\n" to "\\n".
            default_string = default_string.replace("\n", "\\n")
        else:
            default_string = str(base_default_list[base_default_ix])
        base_arg_default_list[ix] += "=" + default_string
    base_arg_default_string = ', '.join(base_arg_default_list + var_args)

    # Create the argument string which can be used to call the base function.
    # Example call_arg_string:
    # headers=headers, last=last, first=first
    call_arg_string = ', '.join([val + "=" + val for val in base_arg_list] +
                                var_args)

    # Compose the result values.
    func_def_line = "def " + wrap_func_name + "(" + base_arg_default_string +\
        "):"
    call_line = base_func_name + "(" + call_arg_string + ")"

    return func_def_line, call_line


def create_func_def_string(base_func_name,
                           wrap_func_name,
                           func_body_template,
                           replace_dict):
    r"""
    Create and return a complete function definition as a string.  The caller
    may run "exec" on the resulting string to create the desired function.

    Description of argument(s):
    base_func_name                  The name of the base function around which
                                    a wrapper is being created.
    wrap_func_name                  The name of the wrapper function being
                                    created.
    func_body_template              A function body in the form of a list.
                                    Each list element represents one line of a
                                    function  This is a template in so far as
                                    text substitions will be done on it to
                                    arrive at a valid function definition.
                                    This template should NOT contain the
                                    function definition line (e.g. "def
                                    func1():").  create_func_def_string will
                                    pre-pend the definition line.  The
                                    template should also contain the text
                                    "<call_line>" which is to be replaced by
                                    text which will call the base function
                                    with appropriate arguments.
    replace_dict                    A dictionary indicating additional text
                                    replacements to be done.  For example, if
                                    the template contains a "<sub1>" (be sure
                                    to include the angle brackets), and the
                                    dictionary contains a key/value pair of
                                    'sub1'/'replace1', then all instances of
                                    "<sub1>" will be replaced by "replace1".
    """

    # Create the initial function definition list as a copy of the template.
    func_def = list(func_body_template)
    # Call create_wrapper_def_and_call to get func_def_line and call_line.
    func_def_line, call_line = create_wrapper_def_and_call(base_func_name,
                                                           wrap_func_name)
    # Insert the func_def_line composed by create_wrapper_def_and_call is the
    # first list entry.
    func_def.insert(0, func_def_line)
    # Make sure the replace_dict has a 'call_line'/call_line pair so that any
    # '<call_line>' text gets replaced as intended.
    replace_dict['call_line'] = call_line

    # Do the replacements.
    for key, value in replace_dict.items():
        func_def = [w.replace("<" + key + ">", value) for w in func_def]

    return '\n'.join(func_def) + "\n"
