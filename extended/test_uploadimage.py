#!/usr/bin/env python

r"""
This module is the python counterpart to test_uploadimage.robot.
"""

import os
import sys
import re
import string
import tarfile
import time

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
def get_latest_file(dir_path):

    r"""
    Get the path to the latest uploaded file.

    Description of argument(s):
    dir_path    Path to the dir from which the name of the last
                updated file or folder will be returned to the
                calling function.
    """

    grk.run_key_u("Open Connection And Log In")
    status, ret_values =\
            grk.run_key("Execute Command On BMC  cd " + dir_path
            + "; stat -c '%Y %n' * | sort -k1,1nr | head -n 1", ignore=1)
    return ret_values.split(" ")[-1]

###############################################################################


###############################################################################
def get_version_tar(tar_file_path):

    r"""
    Read the image version from the MANIFEST inside the tarball.

    Description of argument(s):
    tar_file_path    The path to a tar file that holds the image
                     version inside the MANIFEST.
    """

    tar = tarfile.open(tar_file_path)
    for member in tar.getmembers():
        f=tar.extractfile(member)
        content=f.read()
        if "version=" in content:
            content = content.split("\n")
            content = [x for x in content if "version=" in x]
            version = content[0].split("=")[-1]
            break
    tar.close()
    return version

###############################################################################


###############################################################################
def get_image_version(file_path):

    r"""
    Read the file for a version object.

    Description of argument(s):
    file_path    The path to a file that holds the image version.
    """

    grk.run_key_u("Open Connection And Log In")
    status, ret_values =\
            grk.run_key("Execute Command On BMC  cat "
            + file_path + " | grep \"version=\"", ignore=1)
    return (ret_values.split("\n")[0]).split("=")[-1]

###############################################################################


###############################################################################
def get_image_purpose(file_path):

    r"""
    Read the file for a purpose object.

    Description of argument(s):
    file_path    The path to a file that holds the image purpose.
    """

    grk.run_key_u("Open Connection And Log In")
    status, ret_values =\
            grk.run_key("Execute Command On BMC  cat "
            + file_path + " | grep \"purpose=\"", ignore=1)
    return ret_values.split("=")[-1]

###############################################################################


###############################################################################
def get_image_path(image_version):

    r"""
    Query the upload image dir for the presence of image matching
    the version that was read from the MANIFEST before uploading
    the image. Based on the purpose verify the activation object
    exists and is either READY or INVALID.

    Description of argument(s):
    image_version    The version of the image that should match one
                     of the images in the upload dir.
    """

    upload_dir = BuiltIn().get_variable_value("${upload_dir_path}")
    grk.run_key_u("Open Connection And Log In")
    status, image_list =\
            grk.run_key("Execute Command On BMC  ls -d " + upload_dir
            + "*/")

    image_list = image_list.split("\n")
    retry = 0
    while (retry < 10):
        for i in range(0, len(image_list)):
            version = get_image_version(image_list[i] + "MANIFEST")
            if (version == image_version):
                return image_list[i]
        time.sleep(10)
        retry += 1

###############################################################################


###############################################################################
def verify_image_upload():

    r"""
    Verify the image was uploaded correctly and that it created
    a valid d-bus object
    """

    image_version = BuiltIn().get_variable_value("${image_version}")
    image_path = get_image_path(image_version)
    image_version_id = image_path.split("/")[-2]
    BuiltIn().set_global_variable("${version_id}", image_version_id)

    grk.run_key_u("Open Connection And Log In")
    image_purpose = get_image_purpose(image_path + "MANIFEST")
    if (image_purpose == var.VERSION_PURPOSE_BMC or
        image_purpose == var.VERSION_PURPOSE_HOST):
        uri = var.SOFTWARE_VERSION_URI + image_version_id
        status, ret_values =\
        grk.run_key("Read Attribute  " + uri + "  Activation")

        if ((ret_values == var.READY) or (ret_values == var.INVALID)
            or (ret_values == var.ACTIVE)):
            return True
        else:
            gp.print_var(ret_values)
            return False
    else:
        gp.print_var(image_purpose)
        return False

###############################################################################


###############################################################################
def verify_image_not_in_bmc_uploads_dir(image_version):

    r"""
    Check that an image with the given version is not unpacked inside of the
    BMCs image uploads directory. If no image is found, retry every 30 seconds
    for 3 minutes in case the BMC takes time unpacking the image.

    Description of argument(s):
    image_version  The version of the image to look for on the BMC.
    """

    grk.run_key('Open Connection And Log In')
    upload_dir_path = BuiltIn().get_variable_value("${UPLOAD_DIR_PATH}")
    for i in range(6):
        stat, grep_res = grk.run_key('Execute Command On BMC  '
                + 'ls ' + upload_dir_path + '*/MANIFEST 2>/dev/null '
                + '| xargs grep -rl "version=' + image_version + '"')
        image_dir = os.path.dirname(grep_res.split('\n')[0])
        if '' != image_dir:
            grk.run_key('Execute Command On BMC  rm -rf ' + image_dir)
            BuiltIn().fail('Found invalid BMC Image: ' + image_dir)
        time.sleep(30)

###############################################################################
