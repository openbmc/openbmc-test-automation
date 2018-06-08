#!/usr/bin/env python

r"""
This module provides utilities for code updates.
"""

import os
import re
import sys
import tarfile
import time

robot_pgm_dir_path = os.path.dirname(__file__) + os.sep
repo_data_path = re.sub('/lib', '/data', robot_pgm_dir_path)
sys.path.append(repo_data_path)

import bmc_ssh_utils as bsu
import gen_robot_keyword as keyword
import gen_print as gp
import variables as var
from robot.libraries.BuiltIn import BuiltIn


def verify_no_duplicate_image_priorities(image_purpose):
    r"""
    Check that there are no active images with the same purpose and priority.

    Description of argument(s):
    image_purpose  The purpose that images must have to be checked for
                   priority duplicates.
    """

    taken_priorities = {}
    _, image_names = keyword.run_key("Get Software Objects  "
                                     + "version_type=" + image_purpose)

    for image_name in image_names:
        _, image = keyword.run_key("Get Host Software Property  " + image_name)
        if image["Activation"] != var.ACTIVE:
            continue
        image_priority = image["Priority"]
        if image_priority in taken_priorities:
            BuiltIn().fail("Found active images with the same priority.\n"
                           + gp.sprint_vars(image, taken_priorities[image_priority]))
        taken_priorities[image_priority] = image


def get_non_running_bmc_software_object():
    r"""
    Get the URI to a BMC image from software that is not running on the BMC.
    """

    # Get the version of the image currently running on the BMC.
    _, cur_img_version = keyword.run_key("Get BMC Version")
    # Remove the surrounding double quotes from the version.
    cur_img_version = cur_img_version.replace('"', '')

    _, images = keyword.run_key("Read Properties  "
                                + var.SOFTWARE_VERSION_URI + "enumerate")

    for image_name in images:
        _, image_properties = keyword.run_key(
            "Get Host Software Property  " + image_name)
        if 'Purpose' in image_properties and 'Version' in image_properties \
                and image_properties['Purpose'] != var.VERSION_PURPOSE_HOST \
                and image_properties['Version'] != cur_img_version:
            return image_name
    BuiltIn().fail("Did not find any non-running BMC images.")


def delete_all_pnor_images():
    r"""
    Delete all PNOR images from the BMC.
    """

    status, images = keyword.run_key("Get Software Objects  "
                                     + var.VERSION_PURPOSE_HOST)
    for image_name in images:
        BuiltIn().log_to_console(image_name)
        # Delete twice, in case the image is in the /tmp/images directory
        keyword.run_key("Call Method  " + image_name
                        + "  delete  data={\"data\":[]}")
        keyword.run_key("Call Method  " + image_name
                        + "  delete  data={\"data\":[]}")


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
    num_read_errors = 0
    read_fail_threshold = 1
    while (retry < 30):
        # TODO: Use retry option in run_key when available.
        status, software_state = keyword.run_key("Read Properties  " +
                                                 var.SOFTWARE_VERSION_URI +
                                                 str(version_id),
                                                 ignore=1)
        if status == 'FAIL':
            num_read_errors += 1
            if num_read_errors > read_fail_threshold:
                message = "Read errors exceeds threshold:\n " \
                    + gp.sprint_vars(num_read_errors, read_fail_threshold)
                BuiltIn().fail(message)
            time.sleep(10)
            continue

        current_state = (software_state)["Activation"]
        if (initial_state == current_state):
            time.sleep(10)
            retry += 1
            num_read_errors = 0
        else:
            return
    return


def get_latest_file(dir_path):
    r"""
    Get the path to the latest uploaded file.

    Description of argument(s):
    dir_path    Path to the dir from which the name of the last
                updated file or folder will be returned to the
                calling function.
    """

    stdout, stderr, rc = \
        bsu.bmc_execute_command("cd " + dir_path +
                                "; stat -c '%Y %n' * |" +
                                " sort -k1,1nr | head -n 1")
    return stdout.split(" ")[-1]


def get_version_tar(tar_file_path):
    r"""
    Read the image version from the MANIFEST inside the tarball.

    Description of argument(s):
    tar_file_path    The path to a tar file that holds the image
                     version inside the MANIFEST.
    """

    tar = tarfile.open(tar_file_path)
    for member in tar.getmembers():
        f = tar.extractfile(member)
        content = f.read()
        if "version=" in content:
            content = content.split("\n")
            content = [x for x in content if "version=" in x]
            version = content[0].split("=")[-1]
            break
    tar.close()
    return version


def get_image_version(file_path):
    r"""
    Read the file for a version object.

    Description of argument(s):
    file_path    The path to a file that holds the image version.
    """

    stdout, stderr, rc = \
        bsu.bmc_execute_command("cat "  + file_path +
                                " | grep \"version=\"", ignore_err=1)
    return (stdout.split("\n")[0]).split("=")[-1]


def get_image_purpose(file_path):
    r"""
    Read the file for a purpose object.

    Description of argument(s):
    file_path    The path to a file that holds the image purpose.
    """

    stdout, stderr, rc = \
        bsu.bmc_execute_command("cat " + file_path +
                                " | grep \"purpose=\"", ignore_err=1)
    return stdout.split("=")[-1]


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

    stdout, stderr, rc = \
        bsu.bmc_execute_command("ls -d " + var.IMAGE_UPLOAD_DIR_PATH +
                                "*/")

    image_list = stdout.split("\n")
    retry = 0
    while (retry < 10):
        for i in range(0, len(image_list)):
            version = get_image_version(image_list[i] + "MANIFEST")
            if (version == image_version):
                return image_list[i]
        time.sleep(10)
        retry += 1


def verify_image_upload(image_version,
                        timeout=3):
    r"""
    Verify the image was uploaded correctly and that it created
    a valid d-bus object. If the first check for the image
    fails, try again until we reach the timeout.

    Description of argument(s):
    image_version  The version from the image's manifest file
                   (e.g. "v2.2-253-g00050f1").
    timeout        How long, in minutes, to keep trying to find the
                   image on the BMC. Default is 3 minutes.
    """

    image_path = get_image_path(image_version)
    image_version_id = image_path.split("/")[-2]

    keyword.run_key_u("Open Connection And Log In")
    image_purpose = get_image_purpose(image_path + "MANIFEST")
    if (image_purpose == var.VERSION_PURPOSE_BMC or
            image_purpose == var.VERSION_PURPOSE_HOST):
        uri = var.SOFTWARE_VERSION_URI + image_version_id
        ret_values = ""
        for itr in range(timeout * 2):
            status, ret_values = \
                keyword.run_key("Read Attribute  " + uri + "  Activation")

            if ((ret_values == var.READY) or (ret_values == var.INVALID)
                    or (ret_values == var.ACTIVE)):
                return True, image_version_id
            else:
                time.sleep(30)

        # If we exit the for loop, the timeout has been reached
        gp.print_var(ret_values)
        return False, None
    else:
        gp.print_var(image_purpose)
        return False, None


def verify_image_not_in_bmc_uploads_dir(image_version, timeout=3):
    r"""
    Check that an image with the given version is not unpacked inside of the
    BMCs image uploads directory. If no image is found, retry every 30 seconds
    until the given timeout is hit, in case the BMC takes time
    unpacking the image.

    Description of argument(s):
    image_version  The version of the image to look for on the BMC.
    timeout        How long, in minutes, to try to find an image on the BMC.
                   Default is 3 minutes.
    """

    for i in range(timeout * 2):
        stdout, stderr, rc = \
        bsu.bmc_execute_command('ls ' + var.IMAGE_UPLOAD_DIR_PATH +
                                '*/MANIFEST 2>/dev/null ' +
                                '| xargs grep -rl "version=' +
                                image_version + '"')
        image_dir = os.path.dirname(stdout.split('\n')[0])
        if '' != image_dir:
            bsu.bmc_execute_command('rm -rf ' + image_dir)
            BuiltIn().fail('Found invalid BMC Image: ' + image_dir)
        time.sleep(30)
