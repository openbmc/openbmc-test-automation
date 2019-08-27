*** Settings ***
Documentation         Test upload image with invalid images.
...                   This test expects the following bad tarball image files
...                   to exist in the
...                   BAD_IMAGES_DIR_PATH:
...                             bmc_bad_manifest.ubi.mtd.tar,
...                             bmc_nokernel_image.ubi.mtd.tar,
...                             bmc_invalid_key.ubi.mtd.tar,
...                             pnor_bad_manifest.pnor.squashfs.tar,
...                             pnor_nokernel_image.pnor.squashfs.tar,
...                             pnor_invalid_key.pnor.squashfs.tar.

# Test Parameters:
# OPENBMC_HOST         The BMC host name or IP address.
# OPENBMC_USERNAME     The OS login userid.
# OPENBMC_PASSWORD     The password for the OS login.
# BAD_IMAGES_DIR_PATH  The path to the directory which contains the bad image files.

Resource               ../../lib/connection_client.robot
Resource               ../../lib/rest_client.robot
Resource               ../../lib/openbmc_ffdc.robot
Resource               ../../lib/bmc_redfish_resource.robot
Resource               ../../lib/code_update_utils.robot
Library                OperatingSystem
Library                ../../lib/code_update_utils.py
Library                ../../lib/gen_robot_valid.py

Suite Setup            Suite Setup Execution
Suite Teardown         Redfish.Logout
Test Setup             Printn

Force Tags  Upload_Test

*** Variables ***
${timeout}             20
${QUIET}               ${1}


*** Test Cases ***

Redfish Upload BMC Image With Bad Manifest
    [Documentation]  Upload a BMC firmware with a bad MANFIEST file.
    [Tags]  Redfish_Upload_BMC_Image_With_Bad_Manifest
    [Template]  Redfish Bad Firmware Update

    # Image File Name
    bmc_bad_manifest.ubi.mtd.tar


Redfish Upload BMC Image With No Image
    [Documentation]  Upload a BMC firmware with no kernel image.
    [Tags]  Redfish_Upload_BMC_Image_With_No_Image
    [Template]  Redfish Bad Firmware Update

    # Image File Name
    bmc_nokernel_image.ubi.mtd.tar


Redfish Upload Host Image With Bad Manifest
    [Documentation]  Upload a PNOR firmware with a bad MANIFEST file.
    [Tags]  Redfish_Upload_Host_Image_With_Bad_Manifest
    [Template]  Redfish Bad Firmware Update

    # Image File Name
    pnor_bad_manifest.pnor.squashfs.tar


Redfish Upload Host Image With No Image
    [Documentation]  Upload a PNOR firmware with no kernel Image.
    [Tags]  Redfish_Upload_Host_Image_With_No_Image
    [Template]  Redfish Bad Firmware Update

    # Image File Name
    pnor_nokernel_image.pnor.squashfs.tar


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    Valid Dir Path  BAD_IMAGES_DIR_PATH
    Delete All BMC Dump
    Redfish Purge Event Log


Redfish Bad Firmware Update
    [Documentation]  Redfish firmware update.
    [Arguments]  ${image_file_name}

    # Description of argument(s):
    # image_file_name  The path to the image tarball.

    ${image_file_path}=  OperatingSystem.Join Path  ${BAD_IMAGES_DIR_PATH}
    ...  ${image_file_name}
    Valid File Path  image_file_path
    Set ApplyTime  policy=OnReset
    ${image_data}=  OperatingSystem.Get Binary File  ${image_file_path}
    ${status_code}=  Upload Image To BMC
    ...  ${REDFISH_BASE_URI}UpdateService
    ...  ${timeout}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_INTERNAL_SERVER_ERROR}]
    ...  data=${image_data}

    Pass Execution If  ${status_code} == ${HTTP_INTERNAL_SERVER_ERROR}
    ...  Firmware update failed as expected.

    ${image_id}=  Get Latest Image ID
    Rprint Vars  image_id
    Check Image Update Progress State
    ...  match_state='Updating', 'Disabled'  image_id=${image_id}

    Pass Execution if  ${status_code} == ${HTTP_OK}
    ...  Firmware update failed as expected.


Teardown
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Run Keyword If  ${image_id}
    ...  Delete Software Object  /xyz/openbmc_project/software/${image_id}

