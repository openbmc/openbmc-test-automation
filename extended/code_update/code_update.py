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
def delete_all_pnor_images():

    r"""
    Delete all PNOR images from the BMC.
    """

    status, images = keyword.run_key("Read Properties  "
                                     + var.SOFTWARE_VERSION_URI + "enumerate")
    for image_name in images:
        image_id = image_name.split('/')[-1]
        image_purpose = images[image_name]["Purpose"]
        if var.VERSION_PURPOSE_HOST == image_purpose:
            # Delete twice, in case the image is in the /tmp/images directory
            keyword.run_key("Call Method  " + var.SOFTWARE_VERSION_URI
                            + image_id + "  delete  data={\"data\":[]}")
            keyword.run_key("Call Method  " + var.SOFTWARE_VERSION_URI
                            + image_id + "  delete  data={\"data\":[]}")

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
