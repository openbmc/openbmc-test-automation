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
import variables as var
from robot.libraries.BuiltIn import BuiltIn


###############################################################################
def get_activation_state(version_id):

    r"""
    Get the current activation state of the ${version_id}.

    Description of argument(s):
    version_id  The version ID whose activation state we want to determine.
    """

    keyword.run_key_u("Open Connection And Log In")
    status, ret_values =\
        keyword.run_key("Read Attribute  " + var.SOFTWARE_VERSION_URI
        + version_id + "  Activation")
    return ret_values

###############################################################################


###############################################################################
def get_requested_activation_state(version_id):

    r"""
    Get the current requested activation state of the input version.

    Description of argument(s):
    version_id  The version ID whose requested activation state we want.
    """

    keyword.run_key_u("Open Connection And Log In")
    status, ret_values =\
        keyword.run_key("Read Attribute  " + var.SOFTWARE_VERSION_URI
        + "/" + version_id + "  RequestedActivation")
    return ret_values

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
        current_state = get_activation_state(version_id)
        if (initial_state != current_state):
            return True
        else:
            time.sleep(30)
            retry += 1
    return False

###############################################################################


###############################################################################
def get_pnor_version(file_path):

    r"""
    Returns the PNOR version.

    The pnor version is obtained by reading the manifest from
    the folder inside the upload dir.
    Example:
    version=open-power-witherspoon-v1.16-53-gfb396b3-dirty

    Description of argument(s):
    file_path  The location of the manifest file.
    """

    keyword.run_key_u("Open Connection And Log In")
    status, ret_values =\
            keyword.run_key("Execute Command On BMC  cat "
            + file_path + " | grep \"extended_version=\"")
    return ret_values.split(",")

###############################################################################
