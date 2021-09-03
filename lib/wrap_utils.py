#!/usr/bin/env python3

r"""
This module provides functions which are useful for writing python wrapper functions (i.e. in this context, a
wrapper function is one whose aim is to call some other function on the caller's behalf but to provide some
additional functionality over and above what the base function provides).
"""


def create_func_def_string(base_func_name,
                           wrap_func_name,
                           func_body_template,
                           replace_dict):
    r"""
    Create and return a complete function definition as a string.  The caller may run "exec" on the resulting
    string to create the desired function.

    Description of argument(s):
    base_func_name                  The name of the base function around which a wrapper is being created.
    wrap_func_name                  The name of the wrapper function being created.
    func_body_template              A function body in the form of a list.  Each list element represents one
                                    line of a function  This is a template in so far as text substitutions
                                    will be done on it to arrive at a valid function definition.  This
                                    template should NOT contain the function definition line (e.g. "def
                                    func1():").  create_func_def_string will pre-pend the definition line.
                                    The template should also contain the text "<call_line>" which is to be
                                    replaced by text which will call the base function with appropriate
                                    arguments.
    replace_dict                    A dictionary indicating additional text replacements to be done.  For
                                    example, if the template contains a "<sub1>" (be sure to include the
                                    angle brackets), and the dictionary contains a key/value pair of
                                    'sub1'/'replace1', then all instances of "<sub1>" will be replaced by
                                    "replace1".
    """

    # Create the initial function definition list as a copy of the template.
    func_def = list(func_body_template)
    func_def_line = "def " + wrap_func_name + "(*args, **kwargs):"
    call_line = base_func_name + "(*args, **kwargs)"
    # Insert the func_def_line composed by create_wrapper_def_and_call is the first list entry.
    func_def.insert(0, func_def_line)
    # Make sure the replace_dict has a 'call_line'/call_line pair so that any '<call_line>' text gets
    # replaced as intended.
    replace_dict['call_line'] = call_line

    # Do the replacements.
    for key, value in replace_dict.items():
        func_def = [w.replace("<" + key + ">", value) for w in func_def]

    return '\n'.join(func_def) + "\n"
