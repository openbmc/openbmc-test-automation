#!/usr/bin/env python

r"""
This module contains keyword functions to supplement robot's built in
functions and use in test where generic robot keywords don't support.

"""
import time
from robot.libraries.BuiltIn import BuiltIn
from robot.libraries import DateTime

###############################################################################
def run_until_keyword_fails(retry, retry_interval, name, *args):

    r"""
    Execute a robot keyword repeatedly until it either fails or the timeout
    value is exceeded.
    Note: Opposite of robot keyword "Wait Until Keyword Succeeds".

    Description of argument(s):
    retry              Max timeout time in hour(s).
    retry_interval     Time interval in minute(s) for looping.
    name               Robot keyword to execute.
    args               Robot keyword arguments.
    """

    # Convert the retry time in seconds
    retry_seconds= DateTime.convert_time(retry)
    timeout = time.time() + int(retry_seconds)

    # Convert the interval time in seconds
    interval_seconds=  DateTime.convert_time(retry_interval)
    interval = int(interval_seconds)

    BuiltIn().log(timeout)
    BuiltIn().log(interval)

    while True:
        status= BuiltIn().run_keyword_and_return_status(name, *args)

        # Return if keywords returns as failure.
        if status==False:
            BuiltIn().log("Failed as expected")
            return  False
        # Return if retry timeout as success.
        elif time.time() > timeout > 0:
            BuiltIn().log("Max retry timeout")
            return  True
        time.sleep(interval)
        BuiltIn().log(time.time())

    return  True

###############################################################################
