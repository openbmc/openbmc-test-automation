#!/usr/bin/env python

r"""
This module is the python counterpart to code_update.robot.
"""

import os
import sys
import re
import string
import tarfile
import time

robot_pgm_dir_path = os.path.dirname(__file__) + os.sep
repo_lib_path = re.sub('/extended/code_update/', '/lib', robot_pgm_dir_path)
repo_data_path = re.sub('/extended/code_update/', '/data', robot_pgm_dir_path)
sys.path.append(repo_lib_path)
sys.path.append(repo_data_path)

import gen_robot_keyword as keyword
import gen_print as gp
import gen_valid as gv
import variables as var
from robot.libraries.BuiltIn import BuiltIn


###############################################################################
def verify_host_boots_to_os_if_available(timeout=5):

    r"""
    Attempt to boot the host if it is off, or reboot the host if it is on,
    make sure it can be pinged, and return it to its previous state.

    Description of argument(s):
    timeout  How long, in minutes, to wait for the host to boot before failing
    """

    os_host = BuiltIn().get_variable_value("${OS_HOST}")
    if os_host:
        status, host_state = keyword.run_key("Get Host State")
        print host_state
        if 'Off' == host_state:
            keyword.run_key("Initiate Host Boot")
            keyword.run_key("Wait For Host To Ping  " + os_host
                            + " ${timeout}=" + str(timeout) + "min")
            keyword.run_key("Initiate Host PowerOff")
        else:
            keyword.run_key("Initiate Host PowerOff")
            keyword.run_key("Initiate Host Boot")
            keyword.run_key("Wait For Host To Ping  " + os_host
                            + " ${timeout}=" + str(timeout) + "min")


###############################################################################


###############################################################################
def wait_for_activation_state_change(version_id, initial_state):

    r"""
    Wait for the current activation state of ${version_id} to
    change from the state provided by the calling function.

    Description of argument(s):
    version_id     The version ID whose state change we are waiting for.
    initial_state  The activation state we want to wait for.
    """

    keyword.run_key_u("Open Connection And Log In")
    retry = 0
    while (retry < 20):
        status, software_state = keyword.run_key("Read Properties  " +
                                    var.SOFTWARE_VERSION_URI + str(version_id))
        current_state = (software_state)["Activation"]
        if (initial_state == current_state):
            time.sleep(60)
            retry += 1
        else:
            return
    return

###############################################################################
