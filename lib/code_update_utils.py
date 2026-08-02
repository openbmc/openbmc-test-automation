#!/usr/bin/env python3

r"""
This module provides utilities for code updates.
"""

import collections
import json
import os
import re
import sys
import tarfile
import time

import requests
import urllib3
from robot.libraries.BuiltIn import BuiltIn

robot_pgm_dir_path = os.path.dirname(__file__) + os.sep
repo_data_path = re.sub("/lib", "/data", robot_pgm_dir_path)
sys.path.append(repo_data_path)

import bmc_ssh_utils as bsu  # NOQA
import gen_print as gp  # NOQA
import gen_robot_keyword as keyword  # NOQA
import variables as var  # NOQA


def get_bmc_firmware(image_type, sw_dict):
    r"""
    Get the dictionary of image based on image type like either BMC or Host.

    Description of argument(s):
    image_type                     This value is either BMC update or Host update type.
    sw_dict                        This contain dictionary of firmware inventory properties.
    """

    temp_dict = collections.OrderedDict()
    for key, value in sw_dict.items():
        if value["image_type"] == image_type:
            temp_dict[key] = value
        else:
            pass
    return temp_dict


def verify_no_duplicate_image_priorities(image_purpose):
    r"""
    Check that there are no active images with the same purpose and priority.

    Description of argument(s):
    image_purpose                   The purpose that images must have to be
                                    checked for priority duplicates.
    """

    taken_priorities = {}
    _, image_names = keyword.run_key(
        "Get Software Objects  " + "version_type=" + image_purpose
    )

    for image_name in image_names:
        _, image = keyword.run_key("Get Host Software Property  " + image_name)
        if image["Activation"] != var.ACTIVE:
            continue
        image_priority = image["Priority"]
        if image_priority in taken_priorities:
            BuiltIn().fail(
                "Found active images with the same priority.\n"
                + gp.sprint_vars(image, taken_priorities[image_priority])
            )
        taken_priorities[image_priority] = image


def get_non_running_bmc_software_object():
    r"""
    Get the URI to a BMC image from software that is not running on the BMC.
    """

    # Get the version of the image currently running on the BMC.
    _, cur_img_version = keyword.run_key("Get BMC Version")
    # Remove the surrounding double quotes from the version.
    cur_img_version = cur_img_version.replace('"', "")

    _, images = keyword.run_key(
        "Read Properties  " + var.SOFTWARE_VERSION_URI + "enumerate"
    )

    for image_name in images:
        _, image_properties = keyword.run_key(
            "Get Host Software Property  " + image_name
        )
        if (
            "Purpose" in image_properties
            and "Version" in image_properties
            and image_properties["Purpose"] != var.VERSION_PURPOSE_HOST
            and image_properties["Version"] != cur_img_version
        ):
            return image_name
    BuiltIn().fail("Did not find any non-running BMC images.")


def delete_all_pnor_images():
    r"""
    Delete all PNOR images from the BMC.
    """

    keyword.run_key("Initiate Host PowerOff")

    status, images = keyword.run_key(
        "Get Software Objects  " + var.VERSION_PURPOSE_HOST
    )
    for image_name in images:
        keyword.run_key(
            "Delete Image And Verify  "
            + image_name
            + "  "
            + var.VERSION_PURPOSE_HOST
        )


def wait_for_activation_state_change(version_id, initial_state):
    r"""
    Wait for the current activation state of ${version_id} to
    change from the state provided by the calling function.

    REST reads use a 30-second socket timeout.  Up to read_fail_threshold (3)
    consecutive REST failures are tolerated before the test is failed; the
    error counter resets on every successful read.  The polling loop runs up
    to 60 iterations with a 10-second sleep between successful reads and a
    30-second sleep after every failed read.

    Description of argument(s):
    version_id                      The version ID whose state change we are
                                    waiting for.
    initial_state                   The activation state we want to wait for.
    """

    keyword.run_key_u("Open Connection And Log In")
    BuiltIn().log_to_console(
        f"wait_for_activation_state_change start: version_id={version_id} initial_state={initial_state}"
    )
    retry = 0
    num_read_errors = 0
    current_state = initial_state
    read_fail_threshold = 3
    while retry < 60:
        status, software_state = keyword.run_key(
            "Read Properties  "
            + var.SOFTWARE_VERSION_URI
            + str(version_id)
            + "  timeout=30",
            ignore=1,
        )
        if status == "FAIL":
            BuiltIn().log_to_console(
                f"wait_for_activation_state_change REST read failed (error {num_read_errors + 1}/{read_fail_threshold}): {version_id}"
            )
            num_read_errors += 1
            if num_read_errors >= read_fail_threshold:
                message = "Read errors exceeds threshold:\n " + gp.sprint_vars(
                    num_read_errors, read_fail_threshold
                )
                BuiltIn().fail(message)
            time.sleep(30)
            continue
        else:
            current_state = (software_state)["Activation"]
            num_read_errors = 0

        if initial_state == current_state:
            time.sleep(10)
            retry += 1
        else:
            BuiltIn().log_to_console(
                f"wait_for_activation_state_change end: version_id={version_id} current_state={current_state}"
            )
            return
    BuiltIn().log_to_console(
        f"wait_for_activation_state_change end: version_id={version_id} current_state={current_state}"
    )
    BuiltIn().fail(
        f"Timed out waiting for {version_id} to leave {initial_state}"
    )


def get_latest_file(dir_path):
    r"""
    Get the path to the latest uploaded file.

    Description of argument(s):
    dir_path                        Path to the dir from which the name of the
                                    last updated file or folder will be
                                    returned to the calling function.
    """

    stdout, stderr, rc = bsu.bmc_execute_command(
        "cd "
        + dir_path
        + "; stat -c '%Y %n' * |"
        + " sort -k1,1nr | head -n 1"
    )
    return stdout.split(" ")[-1]


def get_version_tar(tar_file_path):
    r"""
    Read the image version from the MANIFEST inside the tarball.

    Description of argument(s):
    tar_file_path                   The path to a tar file that holds the image
                                    version inside the MANIFEST.
    """

    version = ""
    tar = tarfile.open(tar_file_path)
    for member in tar.getmembers():
        BuiltIn().log_to_console(member.name)
        if member.name != "MANIFEST":
            continue
        f = tar.extractfile(member)
        content = f.read()
        if content.find(b"version=") == -1:
            # This tar member does not contain the version.
            continue
        content = content.decode("utf-8", "ignore").split("\n")
        content = [x for x in content if "version=" in x]
        version = content[0].split("=")[-1]
        break
    tar.close()
    return version


def get_image_version(file_path):
    r"""
    Read the file for a version object.

    Description of argument(s):
    file_path                       The path to a file that holds the image
                                    version.
    """

    stdout, stderr, rc = bsu.bmc_execute_command(
        "cat " + file_path + ' | grep "version="', ignore_err=1
    )
    return (stdout.split("\n")[0]).split("=")[-1]


def get_image_purpose(file_path):
    r"""
    Read the purpose field from an image MANIFEST file on the BMC.

    Executes 'cat <file_path> | grep "purpose="' over SSH and returns the
    value portion of the matching line.  Progress is logged to the console
    at entry and exit to aid timing analysis.

    Description of argument(s):
    file_path                       The path to the MANIFEST file that holds
                                    the image purpose
                                    (e.g. "/tmp/images/<id>/MANIFEST").
    """

    BuiltIn().log_to_console(f"get_image_purpose start: {file_path}")
    stdout, stderr, rc = bsu.bmc_execute_command(
        "cat " + file_path + ' | grep "purpose="', ignore_err=1
    )
    purpose = stdout.split("=")[-1]
    BuiltIn().log_to_console(f"get_image_purpose end: {purpose}")
    return purpose


def get_image_path(image_version):
    r"""
    Query the upload image dir for the presence of image matching
    the version that was read from the MANIFEST before uploading
    the image. Based on the purpose verify the activation object
    exists and is either READY or INVALID.

    Description of argument(s):
    image_version                   The version of the image that should match
                                    one of the images in the upload dir.
    """

    stdout, stderr, rc = bsu.bmc_execute_command(
        "ls -d " + var.IMAGE_UPLOAD_DIR_PATH + "*/"
    )

    image_list = stdout.split("\n")
    retry = 0
    while retry < 10:
        for i in range(0, len(image_list)):
            version = get_image_version(image_list[i] + "MANIFEST")
            if version == image_version:
                return image_list[i]
        time.sleep(10)
        retry += 1


def verify_image_upload(image_version, timeout=3):
    r"""
    Verify the image was uploaded correctly and that it created a valid
    d-bus object with an Activation state of READY, ACTIVE, or INVALID.

    The check is attempted up to (timeout * 2) times with a 30-second sleep
    between iterations.  On each iteration the Activation attribute is read
    via REST (timeout=30s, errors ignored).

    A separate REST-failure counter (rest_fail_limit=6) tracks consecutive
    connectivity errors independently of the state-check iteration budget.
    This ensures that transient REST failures during the D-Bus object
    registration window do not exhaust the state-check retry budget.

    A fresh REST login is forced before the polling loop begins because the
    session established before the tarball upload may have been dropped by
    the BMC during the (potentially long) upload operation.

    Description of argument(s):
    image_version                   The version string from the image's
                                    MANIFEST file (e.g. "v2.2-253-g00050f1").
    timeout                         How long, in minutes, to keep retrying
                                    state-check iterations.  Each minute
                                    covers 2 iterations at 30s sleep.
                                    Default is 3 minutes (6 attempts).
    """

    BuiltIn().log_to_console(f"verify_image_upload start: {image_version}")
    image_path = get_image_path(image_version)
    image_version_id = image_path.split("/")[-2]

    keyword.run_key_u("Open Connection And Log In")
    image_purpose = get_image_purpose(image_path + "MANIFEST")
    if (
        image_purpose == var.VERSION_PURPOSE_BMC
        or image_purpose == var.VERSION_PURPOSE_HOST
    ):
        # D-Bus object path matches the REST URI for phosphor-version-software-manager.
        uri = var.SOFTWARE_VERSION_URI + image_version_id
        ret_values = ""

        # Force a fresh REST login before polling begins.  The session that
        # was active before the tarball upload may have been dropped by the
        # BMC during the upload (e.g. the REST server restarted after
        # writing flash), causing "Non-existing index or alias 'openbmc'"
        # on the very first Read Attribute call.
        BuiltIn().run_keyword("Initialize OpenBMC", "force_login=${True}")

        # REST-failure counter is independent of the state-check budget so
        # that transient connectivity errors do not exhaust the iterations
        # that are needed to observe the Activation state change.
        rest_fail_count = 0
        rest_fail_limit = 6
        for _ in range(timeout * 2):
            status, ret_values = keyword.run_key(
                "Read Attribute  " + uri + "  Activation  timeout=30",
                ignore=1,
            )

            if status != "PASS":
                rest_fail_count += 1
                BuiltIn().log_to_console(
                    f"verify_image_upload REST read failed"
                    f" ({rest_fail_count}/{rest_fail_limit}),"
                    f" retrying: {image_version_id}"
                )
                if rest_fail_count >= rest_fail_limit:
                    BuiltIn().log_to_console(
                        f"verify_image_upload end: REST failure limit reached"
                        f" for {image_version_id}"
                    )
                    gp.print_var(ret_values)
                    return False, None
                # Re-establish the session before the next attempt.
                BuiltIn().run_keyword("Initialize OpenBMC", "force_login=${True}")
                time.sleep(30)
                continue

            # Successful read resets the REST-failure counter.
            rest_fail_count = 0

            if (
                (ret_values == var.READY)
                or (ret_values == var.INVALID)
                or (ret_values == var.ACTIVE)
            ):
                BuiltIn().log_to_console(
                    f"verify_image_upload end: {image_version_id} activation={ret_values}"
                )
                return True, image_version_id
            else:
                time.sleep(30)

        # If we exit the for loop, the state-check timeout has been reached.
        gp.print_var(ret_values)
        BuiltIn().log_to_console(
            f"verify_image_upload end: failed activation={ret_values}"
        )
        return False, None
    else:
        gp.print_var(image_purpose)
        BuiltIn().log_to_console(
            f"verify_image_upload end: invalid purpose={image_purpose}"
        )
        return False, None


def verify_image_not_in_bmc_uploads_dir(image_version, timeout=3):
    r"""
    Check that an image with the given version is not unpacked inside of the
    BMCs image uploads directory. If no image is found, retry every 30 seconds
    until the given timeout is hit, in case the BMC takes time
    unpacking the image.

    Description of argument(s):
    image_version                   The version of the image to look for on
                                    the BMC.
    timeout                         How long, in minutes, to try to find an
                                    image on the BMC. Default is 3 minutes.
    """

    for i in range(timeout * 2):
        stdout, stderr, rc = bsu.bmc_execute_command(
            "ls "
            + var.IMAGE_UPLOAD_DIR_PATH
            + "*/MANIFEST 2>/dev/null "
            + '| xargs grep -rl "version='
            + image_version
            + '"'
        )
        image_dir = os.path.dirname(stdout.split("\n")[0])
        if "" != image_dir:
            bsu.bmc_execute_command("rm -rf " + image_dir)
            BuiltIn().fail("Found invalid BMC Image: " + image_dir)
        time.sleep(30)


def upload_multipart_image_to_bmc(uri, image_file_path, target, timeout=240):
    r"""
    Upload firmware image to BMC via multipart/form-data POST request.
    Required for the update-multipart endpoint which expects
    UpdateParameters (JSON) and UpdateFile (binary) as multipart fields.

    Description of argument(s):
    uri               The URI path for the multipart upload endpoint
                      (e.g. "/redfish/v1/UpdateService/update-multipart").
    image_file_path   The path to the firmware image tarball.
    target            The target firmware inventory URI
                      (e.g. "/redfish/v1/UpdateService/FirmwareInventory/bios_active").
    timeout           Timeout in seconds for the upload request.
    """

    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    openbmc_host = BuiltIn().get_variable_value("${OPENBMC_HOST}")
    https_port = BuiltIn().get_variable_value("${HTTPS_PORT}", "443")

    # Get auth token from the Redfish library instance (imported as alias "Redfish").
    redfish_lib = BuiltIn().get_library_instance("redfish")
    session_key = redfish_lib.get_session_key()

    url = "https://{}:{}{}".format(openbmc_host, https_port, uri)
    update_params = json.dumps({"Targets": [target]})
    file_name = os.path.basename(image_file_path)

    with open(image_file_path, "rb") as f:
        image_data = f.read()

    files = [
        ("UpdateParameters", (None, update_params, "application/json")),
        ("UpdateFile", (file_name, image_data, "application/octet-stream")),
    ]

    headers = {
        "X-Auth-Token": session_key,
        "Accept": "application/json",
    }

    response = requests.post(
        url,
        files=files,
        headers=headers,
        verify=False,
        timeout=timeout,
    )

    if response.status_code not in [200, 202]:
        response.raise_for_status()

    return response.json()
