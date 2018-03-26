#!/usr/bin/env python

r"""
This module contains keyword functions to support multiprocessing
execution of keywords where generic robot keywords don't support.

"""

from robot.libraries.BuiltIn import BuiltIn
from multiprocessing import Process, Manager
import os
import gen_print as gp


def execute_keyword(keyword_name, return_dict):
    r"""
    Execute a robot keyword.
    In addition to running the caller's keyword, this function will:
    - Add an entry to the return_dict

    Description of argument(s):
    keyword_name    Keyword name to be executed.
    return_dict     A dictionary consisting of pid/process status for the
                    keys/values. This function will append a new entry to
                    this dictionary.
    """

    pid = os.getpid()
    status = BuiltIn().run_keyword_and_return_status(keyword_name)

    # Build PID:<status> dictionary.
    return_dict[str(pid)] = str(status)


def execute_process(num_process, keyword_name):
    r"""
    Execute a robot keyword via multiprocessing process.

    Description of argument(s):
    num_process         Number of times keyword to be executed.
    keyword_name     Keyword name to be executed.
    """

    manager = Manager()
    return_dict = manager.dict()
    process_list = []

    # Append user-defined times process needed to execute.
    for ix in range(int(num_process)):
        task = Process(target=execute_keyword,
                       args=(keyword_name, return_dict))
        process_list.append(task)
        task.start()

    # Wait for process to complete.
    for task in process_list:
        task.join()

    # Return function return codes.
    return return_dict
