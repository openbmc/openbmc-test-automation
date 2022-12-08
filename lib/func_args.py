#!/usr/bin/env python3

r"""
This module provides argument manipulation functions like pop_arg.
"""

import gen_print as gp
import collections


def pop_arg(pop_arg_default=None, *args, **kwargs):
    r"""
    Pop a named argument from the args/kwargs and return a tuple consisting of the argument value, the
    modified args and the modified kwargs.

    The name of the argument is determined automatically by this function by examining the source code which
    calls it (see examples below).  If no suitable argument can be found, the default value passed to this
    function will be returned as the argument value.  This function is useful for wrapper functions that wish
    to process arguments in some way before calling subordinate function.

    Examples:

    Given this code:

    def func1(*args, **kwargs):

        last_name, args, kwargs = pop_arg('Doe', *args, **kwargs)
        some_function(last_name.capitalize(), *args, **kwargs)

    Consider this call to func1:

    func1('Johnson', ssn='111-11-1111')

    The pop_arg in func1 would return the following:

        'Johnson', [], {'ssn': "111-11-1111"}

    Notice that the 'args' value returned is an empty list. Since last_name was assumed to be the first
    positional argument, it was popped from args.

    Now consider this call to func1:

    func1(last_name='Johnson', ssn='111-11-1111')

    The pop_arg in func1 would return the same last_name value as in the previous example.  The only
    difference being that the last_name value was popped from kwargs rather than from args.

    Description of argument(s):
    pop_arg_default                 The value to return if the named argument is not present in args/kwargs.
    args                            The positional arguments passed to the calling function.
    kwargs                          The keyword arguments passed to the calling function.
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
            arg_value = pop_arg_default

    return arg_value, args, kwargs


def source_to_object(value):
    r"""
    Evaluate string value as python source code and return the resulting object.

    If value is NOT a string or can not be interpreted as a python source object definition, simply return
    value.

    The idea is to convert python object definition source code (e.g. for lists, dictionaries, tuples, etc.)
    into an object.

    Example:

    Note that this first example is a special case in that it is a short-cut for specifying a
    collections.OrderedDict.

    result = source_to_object("[('one', 1), ('two', 2), ('three', 3)]")

    The result is a collections.OrderedDict object:

    result:
      [one]:                     1
      [two]:                     2
      [three]:                   3

    This is a short-cut for the long form shown here:

    result = source_to_object("collections.OrderedDict([
        ('one', 1),
        ('two', 2),
        ('three', 3)])")

    Also note that support for this special-case short-cut precludes the possibility of interpreting such a
    string as a list of tuples.

    Example:

    In this example, the result will be a list:

    result = source_to_object("[1, 2, 3]")

    result:
      result[0]:                 1
      result[1]:                 2
      result[2]:                 3

    Example:

    In this example, the value passed to this function is not a string, so it is simply returned.

    result = source_to_object(1)

    More examples:
    result = source_to_object("dict(one=1, two=2, three=3)")
    result = source_to_object("{'one':1, 'two':2, 'three':3}")
    result = source_to_object(True)
    etc.

    Description of argument(s):
    value                           If value is a string, it will be evaluated as a python statement.  If the
                                    statement is valid, the resulting object will be returned.  In all other
                                    cases, the value will simply be returned.
    """

    if type(value) not in gp.get_string_types():
        return value

    # Strip white space prior to attempting to interpret the string as python code.
    value = value.strip()

    # Try special case of collections.OrderedDict which accepts a list of tuple pairs.
    if value.startswith("[("):
        try:
            return eval("collections.OrderedDict(" + value + ")")
        except (TypeError, NameError, ValueError):
            pass

    try:
        return eval(value)
    except (NameError, SyntaxError):
        pass

    return value


def args_to_objects(args):
    r"""
    Run source_to_object() on each element in args and return the result.

    Description of argument(s):
    args                            A type of dictionary, list, set, tuple or simple object whose elements
                                    are to be converted via a call to source_to_object().
    """

    type_of_dict = gp.is_dict(args)
    if type_of_dict:
        if type_of_dict == gp.dict_type():
            return {k: source_to_object(v) for (k, v) in args.items()}
        elif type_of_dict == gp.ordered_dict_type():
            return collections.OrderedDict((k, v) for (k, v) in args.items())
        elif type_of_dict == gp.dot_dict_type():
            return DotDict((k, v) for (k, v) in args.items())
        elif type_of_dict == gp.normalized_dict_type():
            return NormalizedDict((k, v) for (k, v) in args.items())
    # Assume args is list, tuple or set.
    if type(args) in (list, set):
        return [source_to_object(arg) for arg in args]
    elif type(args) is tuple:
        return tuple([source_to_object(arg) for arg in args])

    return source_to_object(args)
