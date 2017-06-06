#!/usr/bin/env python

r"""
This module contains keyword functions to support multiprocessing
execution of keywords where generic robot keywords don't support.

"""

from robot.libraries.BuiltIn import BuiltIn
from multiprocessing import Process, Manager
import os
###############################################################################


def execute_keyword(func_name, return_dict):
    r"""
    Execute a robot keyword.

    Description of argument(s):
    func_name          Keyword name to be executed.
    return_dict        Dictionary of return codes.
    """

    pid_buff = "Function: " + str(func_name) + "\t Process ID: " \
               + str(os.getpid())
    BuiltIn().log_to_console(pid_buff)
    output = BuiltIn().run_keyword(func_name)

    # Build PID:<output> dictionary.
    return_dict[str(os.getpid())] = str(output)
###############################################################################


def execute_jobs(num_jobs, func_name):
    r"""
    Execute a robot keyword via multiprocessing process.

    Description of argument(s):
    num_jobs      Number of times keyword to be executed.
    func_name     Keyword name to be executed.
    """

    manager = Manager()
    return_dict = manager.dict()
    jobs_list = []

    # Append user-defined times job needs to execute.
    for i in range(int(num_jobs)):
        job = Process(target=execute_keyword, args=(func_name, return_dict))
        jobs_list.append(job)
        job.start()

    # Wait for process to complete.
    for job in jobs_list:
        job.join()

    # Return function return codes.
    return return_dict
###############################################################################
