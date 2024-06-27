*** Settings ***
Documentation       Test upload image with invalid images.
...                 This test expects the following bad tarball image files
...                 to exist in the BAD_IMAGES_DIR_PATH/TFTP_SERVER:
...                 bmc_bad_manifest.ubi.mtd.tar
...                 bmc_nokernel_image.ubi.mtd.tar
...                 bmc_invalid_key.ubi.mtd.tar
...                 pnor_bad_manifest.pnor.squashfs.tar
...                 pnor_nokernel_image.pnor.squashfs.tar
...                 pnor_invalid_key.pnor.squashfs.tar

# Refer below document to generate bad firmware images for testing.
# openbmc/openbmc-test-automation/blob/master/docs/code_update.md#generating-bad-firmware-image-for-testing
# Test Parameters:
# OPENBMC_HOST    The BMC host name or IP address.
# OPENBMC_USERNAME    The OS login userid.
# OPENBMC_PASSWORD    The password for the OS login.
# BAD_IMAGES_DIR_PATH    The path to the directory which contains the bad image files.
# TFTP_SERVER    The host name or IP of the TFTP server.
Resource            ../../lib/connection_client.robot
Resource            ../../lib/rest_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/code_update_utils.robot
Library             OperatingSystem
Library             ../../lib/code_update_utils.py
Library             ../../lib/gen_robot_valid.py

Suite Setup         Suite Setup Execution
Suite Teardown      Redfish.Logout
Test Setup          Printn
Test Teardown       Test Teardown Execution

Test Tags           redfish_image_upload


*** Variables ***
${timeout}      20
${QUIET}        ${1}
${image_id}     ${EMPTY}


*** Test Cases ***
Redfish Failure To Upload BMC Image With Bad Manifest
    [Documentation]    Upload a BMC firmware with a bad MANFIEST file.
    [Tags]    redfish_failure_to_upload_bmc_image_with_bad_manifest
    [Template]    Redfish Bad Firmware Update

    # Image File Name
    bmc_bad_manifest.ubi.mtd.tar

Redfish Failure To Upload Empty BMC Image
    [Documentation]    Upload a BMC firmware with no kernel image.
    [Tags]    redfish_failure_to_upload_empty_bmc_image
    [Template]    Redfish Bad Firmware Update

    # Image File Name
    bmc_nokernel_image.ubi.mtd.tar

Redfish Failure To Upload Host Image With Bad Manifest
    [Documentation]    Upload a PNOR firmware with a bad MANIFEST file.
    [Tags]    redfish_failure_to_upload_host_image_with_bad_manifest
    [Template]    Redfish Bad Firmware Update

    # Image File Name
    pnor_bad_manifest.pnor.squashfs.tar

Redfish Failure To Upload Empty Host Image
    [Documentation]    Upload a PNOR firmware with no kernel Image.
    [Tags]    redfish_failure_to_upload_empty_host_image
    [Template]    Redfish Bad Firmware Update

    # Image File Name
    pnor_nokernel_image.pnor.squashfs.tar

Redfish TFTP Failure To Upload BMC Image With Bad Manifest
    [Documentation]    Upload a BMC firmware with a bad MANFIEST file via TFTP.
    [Tags]    redfish_tftp_failure_to_upload_bmc_image_with_bad_manifest
    [Template]    Redfish TFTP Bad Firmware Update

    # Image File Name
    bmc_bad_manifest.ubi.mtd.tar

Redfish TFTP Failure To Upload Empty BMC Image
    [Documentation]    Upload a BMC firmware with no kernel image via TFTP.
    [Tags]    redfish_tftp_failure_to_upload_empty_bmc_image
    [Template]    Redfish TFTP Bad Firmware Update

    # Image File Name
    bmc_nokernel_image.ubi.mtd.tar

Redfish TFTP Failure To Upload Host Image With Bad Manifest
    [Documentation]    Upload a PNOR firmware with a bad MANIFEST file via TFTP.
    [Tags]    redfish_tftp_failure_to_upload_host_image_with_bad_manifest
    [Template]    Redfish TFTP Bad Firmware Update

    # Image File Name
    pnor_bad_manifest.pnor.squashfs.tar

Redfish TFTP Failure To Upload Empty Host Image
    [Documentation]    Upload a PNOR firmware with no kernel Image via TFTP.
    [Tags]    redfish_tftp_failure_to_upload_empty_host_image
    [Template]    Redfish TFTP Bad Firmware Update

    # Image File Name
    pnor_nokernel_image.pnor.squashfs.tar


*** Keywords ***
Suite Setup Execution
    [Documentation]    Do the suite setup.

    Valid Value    OPENBMC_HOST
    Valid Value    OPENBMC_USERNAME
    Valid Value    OPENBMC_PASSWORD
    Valid Value    BAD_IMAGES_DIR_PATH
    Valid Value    TFTP_SERVER
    Redfish.Login
    Redfish Delete All BMC Dumps
    Redfish Purge Event Log

Redfish Bad Firmware Update
    [Documentation]    Redfish firmware update.
    [Arguments]    ${image_file_name}

    # Description of argument(s):
    # image_file_name    The file name of the image.

    Valid Dir Path    BAD_IMAGES_DIR_PATH
    ${image_file_path}=    OperatingSystem.Join Path    ${BAD_IMAGES_DIR_PATH}
    ...    ${image_file_name}
    Valid File Path    image_file_path
    Set ApplyTime    policy=OnReset
    ${image_data}=    OperatingSystem.Get Binary File    ${image_file_path}
    ${resp}=    Upload Image To BMC
    ...    ${REDFISH_BASE_URI}UpdateService
    ...    ${timeout}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_INTERNAL_SERVER_ERROR}]
    ...    data=${image_data}

    IF    ${resp.status_code} == ${HTTP_INTERNAL_SERVER_ERROR}    RETURN

    ${image_id}=    Get Latest Image ID
    Rprint Vars    image_id
    Check Image Update Progress State
    ...    match_state='Updating', 'Disabled'    image_id=${image_id}

Redfish TFTP Bad Firmware Update
    [Documentation]    Redfish bad firmware update via TFTP.
    [Arguments]    ${image_file_name}

    # Description of argument(s):
    # image_file_name    The file name of the image.

    Set ApplyTime    policy=OnReset
    # Download image from TFTP server to BMC.
    Redfish.Post    /redfish/v1/UpdateService/Actions/UpdateService.SimpleUpdate
    ...    body={"TransferProtocol" : "TFTP", "ImageURI" : "${TFTP_SERVER}/${image_file_name}"}
    Sleep    60s
    ${image_version}=    Get Image Version From TFTP Server    ${TFTP_SERVER}    ${image_file_name}
    IF    '${image_version}' == '${EMPTY}'    RETURN
    # Wait for image tar file to download complete.
    ${image_id}=    Wait Until Keyword Succeeds    60 sec    10 sec    Get Latest Image ID
    Rprint Vars    image_id

    Check Image Update Progress State
    ...    match_state='Updating', 'Disabled'    image_id=${image_id}

Test Teardown Execution
    [Documentation]    Do the post test teardown.

    FFDC On Test Case Fail
    IF    '${image_id}'
        Delete Software Object    /xyz/openbmc_project/software/${image_id}
    END
