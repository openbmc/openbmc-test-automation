#!/usr/bin/env python

r"""
Define the func_timer class.
"""

import os
import sys
import signal
import multiprocessing

import gen_print as gp
import gen_misc as gm


class func_timer_class:
    r"""
    Define the func timer class.

    A func timer object can be used to run any function with arguments but
    with an additional benefit of being able to specify a time_out value.  If
    the function fails to complete before the timer expires, a ValueError
    exception will be raised along with a detailed error message.

    Example code:

    func_timer = func_timer_class()
    func_timer.run(run_key, "sleep 2", time_out=1)

    In this example, the run_key function is being run by the func_timer
    object with a time_out value of 1 second.  "sleep 2" is a positional parm
    for the run_key function.
    """

    def __init__(self,
                 obj_name='func_timer_class'):

        self.__obj_name = obj_name
        # Save the original SIGALRM handler for later restoration by this
        # class' methods.
        self.__original_sigalrm_handler = signal.getsignal(signal.SIGALRM)
        # Initialize object variables.
        self.__function_timed_out = False
        self.__err_msg = ""
        self.__func = None
        self.__time_out = None
        self.__children = []

    def sprint_obj(self):
        r"""
        sprint the fields of this object.  This would normally be for debug
        purposes.
        """

        buffer = ""
        buffer += self.__class__.__name__ + ":\n"
        indent = 2
        buffer += gp.sprint_varx("original_sigalrm_handler",
                                 self.__original_sigalrm_handler,
                                 loc_col1_indent=indent)
        buffer += gp.sprint_varx("function_timed_out",
                                 self.__function_timed_out,
                                 loc_col1_indent=indent)
        try:
            func_name = self.__func.__name__
        except AttributeError:
            func_name = ""
        buffer += gp.sprint_var(func_name, hex=1, loc_col1_indent=indent)
        buffer += gp.sprint_varx("time_out", self.__time_out,
                                 loc_col1_indent=indent)
        buffer += gp.sprint_varx("err_msg", self.__err_msg, hex=1,
                                 loc_col1_indent=indent)
        buffer += gp.sprint_varx("children", self.__children,
                                 loc_col1_indent=indent)

        return buffer

    def print_obj(self):
        r"""
        print the fields of this object to stdout.  This would normally be for
        debug purposes.
        """

        sys.stdout.write(self.sprint_obj())

    def timed_out(self,
                  signal_number,
                  frame):
        r"""
        Handle an alarm signal generated during the running of the "run"
        object method (defined below).

        signal_number               The signal_number of the signal causing
                                    this method to get invoked.  This should
                                    always be 14 (SIGALRM).
        frame                       The stack frame associated with the
                                    function that times out.
        """

        gp.dprint_executing()

        # Restore the original SIGALRM handler and clear the alarm.
        signal.signal(signal.SIGALRM, self.__original_sigalrm_handler)
        signal.alarm(0)

        new_children = list(set(gm.get_child_pids()) - set(self.__children))
        # Terminate child processes that started after the call to the run
        # method (below).
        for pid in new_children:
            os.kill(pid, signal.SIGTERM)

        self.__function_timed_out = True

        # Compose an error message.
        self.__err_msg = "The " + self.__func.__name__
        self.__err_msg += " function timed out after " + str(self.__time_out)
        self.__err_msg += " seconds.\n"
        if not gp.robot_env:
            self.__err_msg += gp.sprint_call_stack()

        return

    def run(self, func, *args, **kwargs):

        r"""
        Run the indicated function with the given args and kwargs and return
        the value that the function returns.  If the time_out value expires,
        raise a ValueError exception.

        This method passes all of the args and kwargs directly to the child
        function with the following important exception: If kwargs contains a
        'time_out' value, it will be used to set the func timer object's
        time_out value and then the kwargs['time_out'] entry will be removed.
        If the time-out expires before the function finishes running, this
        method will raise a ValueError.

        Example:
        func_timer = func_timer_class()
        func_timer.run(run_key, "sleep 3", time_out=2)

        Example:
        try:
            result = func_timer.run(func1, "parm1", time_out=2)
            print_var(result)
        except ValueError:
            print("The func timed out but we're handling it.")

        Description of argument(s):
        func                        The function object which is to be called.
        args                        The arguments which are to be passed to
                                    the function object.
        kwargs                      The keyword arguments which are to be
                                    passed to the function object.  As noted
                                    above, kwargs['time_out'] will get special
                                    treatment.
        """

        # Store function parms as object parms.
        self.__func = func
        self.__function_timed_out = False

        # Save the original SIGALRM handler for later restoration by this
        # class' methods.
        self.__original_sigalrm_handler = signal.getsignal(signal.SIGALRM)

        # Save the current list of all child processes.
        self.__children = gm.get_child_pids()

        # Get self.__time_out value from kwargs.  If kwargs['time_out'] is
        # not present, self.__time_out will default to None.
        self.__time_out = None
        if len(kwargs) > 0:
            if 'time_out' in kwargs:
                self.__time_out = kwargs['time_out']
                del kwargs['time_out']

        if self.__time_out is not None:
            # Designate a SIGALRM handling function and set the alarm.
            signal.signal(signal.SIGALRM, self.timed_out)
            signal.alarm(self.__time_out)

        try:
            result = func(*args, **kwargs)
        except IOError:
            self.__function_timed_out = True

        if self.__time_out is not None:
            # Restore the original SIGALRM handler and clear the alarm.
            signal.signal(signal.SIGALRM, self.__original_sigalrm_handler)
            signal.alarm(0)

        if self.__function_timed_out:
            raise ValueError(self.__err_msg)

        return result
