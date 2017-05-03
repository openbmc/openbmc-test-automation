#!/usr/bin/env python

r"""
This module contains functions having to do with keywords to support
test which generic robot keywords doesnt support.

"""

import time
from robot.libraries.BuiltIn import BuiltIn

###############################################################################
def run_until_keyword_fails(retry, interval, keyword, *args):

    r"""
    Executes a robot keyword until it fails.
	Return False if failed or timedout.
    Note: Equivalent of robot keyword "Wait Until Keyword succeeeds".

    Description of arguments:
    max_timeout     Max timeout time in hour(s).
    interval        Time interval in minute(s) for looping.
    keyword         Robot keyword to execute.
    args            Robot keyword arguments.
    """

    timeout = time.time() + 60*60*int(retry)
    interval = 60*int(interval)
    BuiltIn().log(timeout)
    BuiltIn().log(interval)
    while True:
        status= BuiltIn().run_keyword_and_return_status(keyword, *args)
        if time.time() > timeout > 0 or status==False:
            BuiltIn().log("Failed as expected or timedout")
            return  False
        time.sleep(interval)
        BuiltIn().log(time.time())

    return  True

###############################################################################
