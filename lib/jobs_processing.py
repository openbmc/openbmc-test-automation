#!/usr/bin/env python

r"""
This module contains keyword functions to support multiprocessing
execution of keywords where generic robot keywords don't support.

"""

from robot.libraries.BuiltIn import BuiltIn
from multiprocessing import Process, Manager
import os


###############################################################################
def execute_keyword(keyword_name, return_dict):
    r"""
    Execute a robot keyword.
    In addition to running the caller's keyword, this function will:
    - Print the function name and process id to the console
    - Add an entry to the return_dict

    Description of argument(s):
    keyword_name    Keyword name to be executed.
    return_dict     A dictionary consisting of pid/process output for the
	                keys/values. This function will append a new entry to
                    this dictionary.
    """

    pid_buff = "Function: " + str(keyword_name) + "\t Process ID: " \
               + str(os.getpid())
    BuiltIn().log_to_console(pid_buff)
    output = BuiltIn().run_keyword(keyword_name)

    # Build PID:<output> dictionary.
    return_dict[str(os.getpid())] = str(output)

###############################################################################


def execute_jobs(num_jobs, keyword_name):
    r"""
    Execute a robot keyword via multiprocessing jobs.

    Description of argument(s):
    num_jobs         Number of times keyword to be executed.
    keyword_name     Keyword name to be executed.
    """

    manager = Manager()
    return_dict = manager.dict()
    jobs_list = []

    # Append user-defined times job needs to execute.
    for ix in range(int(num_jobs)):
        job = Process(target=execute_keyword, args=(keyword_name, return_dict))
        jobs_list.append(job)
        job.start()

    # Wait for process to complete.
    for job in jobs_list:
        job.join()

    # Return function return codes.
    return return_dict

###############################################################################
