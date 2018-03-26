#!/usr/bin/env python

r"""
Define the var_stack class.
"""

import sys
import collections

try:
    from robot.utils import DotDict
except ImportError:
    pass

import gen_print as gp


class var_stack:

    r"""
    Define the variable stack class.

    An object of this class can be used to push variable name/variable value
    pairs which may be popped off the stack at a later time.  The most obvious
    use for this is for saving variables that are to be restored later.

    Example code:

    save_stack = var_stack('save_stack')
    var1 = "johnson"
    save_stack.push(var1)
    var1 = "smith"
    ...
    var1 = save_stack.pop('var1')
    # var1 has now been restored to the value "johnson".


    Example use:

    var1 = "mike"
    save_stack.push(var1)
    var1 = "james"
    save_stack.push(var1)
    save_stack.print_obj()

    # The print-out of the object would then look like this:

    save_stack:
      stack_dict:
        [var1]:
          [var1][0]:  mike
          [var1][1]:  james

    # Continuing with this code...

    var1 = save_stack.pop('var1')
    save_stack.print_obj()

    # The print-out of the object would then look like this:

    save_stack:
      stack_dict:
        [var1]:
          [var1][0]:  mike
    """

    def __init__(self,
                 obj_name='var_stack'):
        r"""
        Initialize a new object of this class type.

        Description of argument(s):
        obj_name                    The name of the object.  This is useful
                                    for printing out the object.
        """

        self.__obj_name = obj_name
        # Create a stack dictionary.
        try:
            self.__stack_dict = collections.OrderedDict()
        except AttributeError:
            self.__stack_dict = DotDict()

    def sprint_obj(self):
        r"""
        sprint the fields of this object.  This would normally be for debug
        purposes.
        """

        buffer = ""

        buffer += self.__obj_name + ":\n"
        indent = 2
        buffer += gp.sprint_varx('stack_dict', self.__stack_dict, 1, indent)

        return buffer

    def print_obj(self):
        r"""
        print the fields of this object to stdout.  This would normally be for
        debug purposes.
        """

        sys.stdout.write(self.sprint_obj())

    def push(self,
             var_value,
             var_name=""):
        r"""
        push the var_name/var_value pair onto the stack.

        Description of argument(s):
        var_value                   The value being pushed.
        var_name                    The name of the variable containing the
                                    value to be pushed.  This parameter is
                                    normally unnecessary as this function can
                                    figure out the var_name.  This is provided
                                    for Robot callers.  In this scenario, we
                                    are unable to get the variable name
                                    ourselves.
        """

        if var_name == "":
            # The caller has not passed a var_name so we will try to figure
            # it out.
            stack_frame_ix = 2
            var_name = gp.get_arg_name(0, 1, stack_frame_ix)
        if var_name in self.__stack_dict:
            self.__stack_dict[var_name].append(var_value)
        else:
            self.__stack_dict[var_name] = [var_value]

    def pop(self,
            var_name=""):
        r"""
        Pop the value for the given var_name from the stack and return it.

        Description of argument(s):
        var_name                    The name of the variable whose value is to
                                    be popped.
        """

        return self.__stack_dict[var_name].pop()
