#!/usr/bin/env python

r"""
This module provides argument manipulation functions like pop_arg.
"""

import gen_print as gp


def pop_arg(default, *args, **kwargs):
    r"""
    Pop a named argument from the args/kwargs and return a tuple consisting of
    the argument value, the modified args and the modified kwargs.

    The name of the argument is determined automatically by this function by
    examining the source code which calls it (see examples below).  If no
    suitable argument can be found, the default value passed to this function
    will be returned as the argument value.  This function is useful for
    wrapper functions that wish to process arguments in some way before
    calling subordinate function.

    Examples:

    Given this code:

    def func1(*args, **kwargs):

        last_name, args, kwargs = pop_arg('Doe', *args, **kwargs)
        some_function(last_name.capitalize(), *args, **kwargs)

    Consider this call to func1:

    func1('Johnson', ssn='111-11-1111')

    The pop_arg in func1 would return the following:

        'Johnson', [], {'ssn': "111-11-1111"}

    Notice that the 'args' value returned is an empty list. Since last_name
    was assumed to be the first positional argument, it was popped from args.

    Now consider this call to func1:

    func1(last_name='Johnson', ssn='111-11-1111')

    The pop_arg in func1 would return the same last_name value as in the
    previous example.  The only difference being that the last_name value was
    popped from kwargs rather than from args.

    Description of argument(s):
    default                         The value to return if the named argument
                                    is not present in args/kwargs.
    args                            The positional arguments passed to the
                                    calling function.
    kwargs                          The keyword arguments passed to the
                                    calling function.
    """

    # Retrieve the argument name by examining the source code.
    arg_name = gp.get_arg_name(None, arg_num=-3, stack_frame_ix=2)
    if arg_name in kwargs:
        arg_value = kwargs.pop(arg_name)
    else:
        # Convert args from a tuple to a list.
        args = list(args)
        if args:
            arg_value = args.pop(0)
        else:
            arg_value = default

    return arg_value, args, kwargs
