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

import gen_robot_keyword as grk
import gen_print as gp
import variables as var
from robot.libraries.BuiltIn import BuiltIn


###############################################################################
def get_activation_state():

    r"""
    Get the current activation state of the ${VERSION_ID}
    """

    grk.run_key_u("Open Connection And Log In")
    versionId = BuiltIn().get_variable_value("${VERSION_ID}")
    status, ret_values =\
        grk.run_key("Read Attribute  " + var.SOFTWARE_VERSION_URI
        + versionId + "  Activation")
    return ret_values

###############################################################################

###############################################################################
def get_requested_activation_state():

    r"""
    Get the current requested activation state of the ${VERSION_ID}
    """

    grk.run_key_u("Open Connection And Log In")
    versionId = BuiltIn().get_variable_value("${VERSION_ID}")
    status, ret_values =\
        grk.run_key("Read Attribute  " + var.SOFTWARE_VERSION_URI
        + "/" + versionId + "  RequestedActivation")
    return ret_values

###############################################################################

###############################################################################
def wait_for_activation_state_change(initial_state):

    r"""
    Wait for the current activation state of ${VERSION_ID} to
    change from the initial_state

    Description of argument(s):
    initial_state  The current state of activation object
    """

    grk.run_key_u("Open Connection And Log In")
    retry = 0
    while (retry < 10):
        current_state = get_activation_state()
        if (initial_state != current_state):
            return
        else:
            time.sleep(30)
            retry += 1

###############################################################################

###############################################################################
def get_pnor_version_manifest():

    r"""
    Read the version object from inside the MANIFEST, which
    will be stored in the images dir under the folder named
    ${VERSION_ID}
    """

    grk.run_key_u("Open Connection And Log In")
    versionId = BuiltIn().get_variable_value("${VERSION_ID}")
    status, ret_values =\
            grk.run_key("Execute Command On BMC  cat "
            + file_path + " | grep \"extended_version=\"")
    return ret_values.split(",")

###############################################################################

###############################################################################
def get_pnor_version():

    r"""
    Reads the current PNOR version and returns it to the calling
    function
    """
 
    grk.run_key_u("Open Connection And Log In")
    status, current_version =\
            grk.run_key("Execute Command On BMC  "
            + "/usr/sbin/pflash -r /dev/stdout -P VERSION")
    return current_version

###############################################################################
