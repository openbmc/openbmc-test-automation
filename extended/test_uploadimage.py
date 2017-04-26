#!/usr/bin/env python

r"""
This module is the python counterpart to test_uploadimage.robot.
"""

import os
import sys
import re

robot_pgm_dir_path = os.path.dirname(__file__) + os.sep
repo_lib_path = re.sub('/extended/', '/lib', robot_pgm_dir_path)
repo_data_path = re.sub('/extended/', '/data', robot_pgm_dir_path)
sys.path.append(repo_lib_path)
sys.path.append(repo_data_path)

import gen_robot_keyword as grk
import gen_print as gp
import variables as var
from robot.libraries.BuiltIn import BuiltIn

###############################################################################
def get_latest_file(dirpath):

    r"""
    Gets the path to the latest uploaded file.
    """

    grk.run_key_u("Open Connection And Log In")
    status, ret_values =\
            grk.run_key("Execute Command On BMC  cd " + dirpath
            + "; stat -c '%Y %n' * | sort -k1,1nr | head -n 1", ignore=1)
    return ret_values
###############################################################################

###############################################################################
def verify_upload_activation_state(imagepath):

    r"""
    Read the MANIFEST from the path to find the image purpose.
    Based on the purpose verify the activation object exists and
    is either READY or INVALID.
    """

    versionId = imagepath.rsplit("/")[-1]
    grk.run_key_u("Open Connection And Log In")
    status, ret_values =\
            grk.run_key("Execute Command On BMC  cat "
            + imagepath + "/MANIFEST")
    versionPurpose = (ret_values.split("\n")[0]).split("=")[-1]

    if (versionPurpose == "bmc"):
        uri = var.SOFTWARE_VERSION_URI + "/" + versionId
    else:
        return False

    status, ret_values =\
        grk.run_key("Read Attribute  " + uri + "  Activation")

    if ((ret_values == var.READY) or (ret_values == var.INVALID)):
        return True
    else:
        return False
###############################################################################
